unit Horse.Logger.Provider.LogFile;

{$IFDEF FPC}
  {$MODE DELPHI}
{$ENDIF}

interface

uses
{$IFDEF FPC}
  Classes,
{$ELSE}
  System.Classes,
  {$IFDEF LINUX}
    {$DEFINE USE_PATH_MAX}
  {$ELSE}
    Winapi.Windows,
  {$ENDIF}

  {$IFDEF USE_PATH_MAX}
    {$DEFINE MAX_PATH := Posix.Unistd.PATH_MAX}
  {$ENDIF}
{$ENDIF}
  Horse.Logger;

type
  THorseLoggerLogFileConfig = class
  private
    FLogFormat: string;
    FDir: string;
    FLogName: string;
  public
    constructor Create;
    function SetLogFormat(const ALogFormat: string): THorseLoggerLogFileConfig;
    function SetDir(const ADir: string): THorseLoggerLogFileConfig;
    function SetLogName(const ALogName: string): THorseLoggerLogFileConfig;
    function GetLogFormat(out ALogFormat: string): THorseLoggerLogFileConfig;
    function GetDir(out ADir: string): THorseLoggerLogFileConfig;
    function GetLogName(out ALogName: string): THorseLoggerLogFileConfig;
    class function New: THorseLoggerLogFileConfig;
  end;

  THorseLoggerProviderLogFileManager = class(THorseLoggerThread)
  private
    FConfig: THorseLoggerLogFileConfig;
  protected
    procedure DispatchLogCache; override;
  public
    destructor Destroy; override;
    function SetConfig(AConfig: THorseLoggerLogFileConfig): THorseLoggerProviderLogFileManager;
  end;

  THorseLoggerProviderLogFile = class(TInterfacedObject, IHorseLoggerProvider)
  private
    FHorseLoggerProviderLogFileManager: THorseLoggerProviderLogFileManager;
  public
    constructor Create(const AConfig: THorseLoggerLogFileConfig = nil);
    destructor Destroy; override;
    procedure DoReceiveLogCache(ALogCache: THorseLoggerCache);
    class function New(const AConfig: THorseLoggerLogFileConfig = nil): IHorseLoggerProvider;
  end;

implementation

uses
{$IFDEF FPC}
  SysUtils, fpJSON, SyncObjs;
{$ELSE}
  System.SysUtils, System.IOUtils, System.JSON, System.SyncObjs, System.Types;
{$ENDIF}

{ THorseLoggerProviderLogFile }

const
  DEFAULT_HORSE_LOG_FORMAT =
    '${request_clientip} [${time}] ${request_user_agent}' +
    ' "${request_method} ${request_path_info} ${request_version}"' +
    ' ${response_status} ${response_content_length}';

constructor THorseLoggerProviderLogFile.Create(const AConfig: THorseLoggerLogFileConfig = nil);
begin
  FHorseLoggerProviderLogFileManager := THorseLoggerProviderLogFileManager.Create(True);
  FHorseLoggerProviderLogFileManager.SetConfig(AConfig);
  FHorseLoggerProviderLogFileManager.FreeOnTerminate := False;
  FHorseLoggerProviderLogFileManager.Start;
end;

destructor THorseLoggerProviderLogFile.Destroy;
begin
  FHorseLoggerProviderLogFileManager.Terminate;
  FHorseLoggerProviderLogFileManager.GetEvent.SetEvent;
  FHorseLoggerProviderLogFileManager.WaitFor;
  FHorseLoggerProviderLogFileManager.Free;
  inherited;
end;

procedure THorseLoggerProviderLogFile.DoReceiveLogCache(ALogCache: THorseLoggerCache);
var
  I: Integer;
begin
  for I := 0 to Pred(ALogCache.Count) do
    FHorseLoggerProviderLogFileManager.NewLog(THorseLoggerLog(ALogCache.Items[0].Clone));
end;

class function THorseLoggerProviderLogFile.New(const AConfig: THorseLoggerLogFileConfig = nil): IHorseLoggerProvider;
begin
  Result := THorseLoggerProviderLogFile.Create(AConfig);
end;

{ TTHorseLoggerProviderLogFileThread }

destructor THorseLoggerProviderLogFileManager.Destroy;
begin
  FreeAndNil(FConfig);
  inherited;
end;

procedure THorseLoggerProviderLogFileManager.DispatchLogCache;
var
  I, Z: Integer;
  LLogCache: THorseLoggerCache;
  LLog: THorseLoggerLog;
  LParams: TArray<string>;
  LValue: {$IFDEF FPC}THorseLoggerLogItemString{$ELSE}string{$ENDIF};
  LLogStr, LFilename, LLogName: string;
  LTextFile: TextFile;
begin
  if FConfig = nil then
    FConfig := THorseLoggerLogFileConfig.New;
  FConfig.GetLogFormat(LLogStr).GetDir(LFilename);
  FConfig.GetLogFormat(LLogStr).GetLogName(LLogName);

  if (LFilename <> EmptyStr) and (not DirectoryExists(LFilename)) then
    ForceDirectories(LFilename);
  {$IFDEF FPC}
  LFilename := ConcatPaths([LFilename, LLogName + '_' + FormatDateTime('yyyy-mm-dd', Now()) + '.log']);
  {$ELSE}
  LFilename := TPath.Combine(LFilename, LLogName + '_' + FormatDateTime('yyyy-mm-dd', Now()) + '.log');
  {$ENDIF}
  LLogCache := ExtractLogCache;
  try
    if LLogCache.Count = 0 then
      Exit;
    AssignFile(LTextFile, LFilename);
    if (FileExists(LFilename)) then
      Append(LTextFile)
    else
      Rewrite(LTextFile);
    try
      for I := 0 to Pred(LLogCache.Count) do
      begin
        LLog := LLogCache.Items[I] as THorseLoggerLog;
        LParams := THorseLoggerUtils.GetFormatParams(FConfig.FLogFormat);
        for Z := Low(LParams) to High(LParams) do
        begin
          {$IFDEF FPC}
          if LLog.Find(LParams[Z], LValue) then
            LLogStr := LLogStr.Replace('${' + LParams[Z] + '}', LValue.AsString);
          {$ELSE}
          if LLog.TryGetValue<string>(LParams[Z], LValue) then
            LLogStr := LLogStr.Replace('${' + LParams[Z] + '}', LValue);
          {$ENDIF}
        end;
      end;
      WriteLn(LTextFile, LLogStr);
    finally
      CloseFile(LTextFile);
    end;
  finally
    LLogCache.Free;
  end;
end;

function THorseLoggerProviderLogFileManager.SetConfig(AConfig: THorseLoggerLogFileConfig): THorseLoggerProviderLogFileManager;
begin
  FConfig := AConfig;
  Result := Self;
end;

{ THorseLoggerConfig }

{$IFDEF LINUX}
function GetModuleFileName(Module: HINST; lpFilename: PChar; nSize: DWORD): DWORD; stdcall;
var
  LPath: string;
begin
  LPath := GetEnvironmentVariable('_');
  if Integer(nSize) <= Length(LPath) then
    Result := 0
  else
  begin
    StrPCopy(lpFilename, LPath);
    Result := Length(LPath);
  end;
end;
{$ENDIF}

constructor THorseLoggerLogFileConfig.Create;
{$IFNDEF FPC}
const
  INVALID_PATH = '\\?\';
var
  LPath: array[0..MAX_PATH - 1] of Char;
{$ENDIF}
begin
  FLogFormat := DEFAULT_HORSE_LOG_FORMAT;
  {$IFDEF FPC}
  FDir := ExtractFileDir(ParamStr(0));
  FLogName := 'access';
  {$ELSE}
  SetString(FDir, LPath, GetModuleFileName(HInstance, LPath, SizeOf(LPath)));
  FDir := FDir.Replace(INVALID_PATH, EmptyStr);
  FLogName := 'access_' + ExtractFileName(FDir).Replace(ExtractFileExt(FDir), EmptyStr);
  FDir := ExtractFilePath(FDir) ;
  {$ENDIF}
  FDir := FDir + '\logs';
end;

function THorseLoggerLogFileConfig.GetDir(out ADir: string): THorseLoggerLogFileConfig;
begin
  ADir := FDir;
  Result := Self;
end;

function THorseLoggerLogFileConfig.GetLogFormat(out ALogFormat: string): THorseLoggerLogFileConfig;
begin
  ALogFormat := FLogFormat;
  Result := Self;
end;

function THorseLoggerLogFileConfig.GetLogName(out ALogName: string): THorseLoggerLogFileConfig;
begin
  ALogName := FLogName;
  Result := Self;
end;

class function THorseLoggerLogFileConfig.New: THorseLoggerLogFileConfig;
begin
  Result := THorseLoggerLogFileConfig.Create;
end;

function THorseLoggerLogFileConfig.SetDir(const ADir: string): THorseLoggerLogFileConfig;
begin
  FDir := ADir;
  Result := Self;
end;

function THorseLoggerLogFileConfig.SetLogFormat(const ALogFormat: string): THorseLoggerLogFileConfig;
begin
  FLogFormat := ALogFormat;
  Result := Self;
end;

function THorseLoggerLogFileConfig.SetLogName(const ALogName: string): THorseLoggerLogFileConfig;
begin
  FLogName := ALogName;
  Result := Self;
end;

end.
