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
{$ENDIF}
  Horse.Logger;

type
  THorseLoggerLogFileConfig = class
  private
    FLogFormat: string;
    FDir: string;
  public
    constructor Create;
    function SetLogFormat(const ALogFormat: string): THorseLoggerLogFileConfig;
    function SetDir(const ADir: string): THorseLoggerLogFileConfig;
    function GetLogFormat(out ALogFormat: string): THorseLoggerLogFileConfig;
    function GetDir(out ADir: string): THorseLoggerLogFileConfig;
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
  System.SysUtils, System.IOUtils, System.JSON, System.SyncObjs;
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
  LLogStr, LFilename: string;
  LTextFile: TextFile;
begin
  if FConfig = nil then
    FConfig := THorseLoggerLogFileConfig.New;
  FConfig.GetLogFormat(LLogStr).GetDir(LFilename);
  {$IFDEF FPC}
  LFilename := ConcatPaths([LFilename, 'access_' + FormatDateTime('yyyy-mm-dd', Now()) + '.log']);
  {$ELSE}
  LFilename := TPath.Combine(LFilename, 'access_' + FormatDateTime('yyyy-mm-dd', Now()) + '.log');
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
  Result := Self;
  FConfig := AConfig;
end;

{ THorseLoggerConfig }

constructor THorseLoggerLogFileConfig.Create;
begin
  FLogFormat := DEFAULT_HORSE_LOG_FORMAT;
  FDir := ExtractFileDir(ParamStr(0));
end;

function THorseLoggerLogFileConfig.GetDir(out ADir: string): THorseLoggerLogFileConfig;
begin
  Result := Self;
  ADir := FDir;
end;

function THorseLoggerLogFileConfig.GetLogFormat(out ALogFormat: string): THorseLoggerLogFileConfig;
begin
  Result := Self;
  ALogFormat := FLogFormat;
end;

class function THorseLoggerLogFileConfig.New: THorseLoggerLogFileConfig;
begin
  Result := THorseLoggerLogFileConfig.Create;
end;

function THorseLoggerLogFileConfig.SetDir(const ADir: string): THorseLoggerLogFileConfig;
begin
  Result := Self;
  if not DirectoryExists(ADir) then
    CreateDir(ADir);
  FDir := ADir;
end;

function THorseLoggerLogFileConfig.SetLogFormat(const ALogFormat: string): THorseLoggerLogFileConfig;
begin
  Result := Self;
  FLogFormat := ALogFormat;
end;

end.
