program Console;

{$MODE DELPHI}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Horse,
  Horse.Logger, // It's necessary to use the unit
  Horse.Logger.Provider.LogFile, // It's necessary to use the unit
  SysUtils;

var
  LLogFileConfig: THorseLoggerLogFileConfig;

procedure GetPing(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  Res.Send('Pong');
end;

procedure OnListen(Horse: THorse);
begin
  Writeln(Format('Server is runing on %s:%d', [Horse.Host, Horse.Port]));
end;

begin
  LLogFileConfig := THorseLoggerLogFileConfig.New
    .SetLogFormat('${request_clientip} [${time}] ${response_status}')
    .SetDir('D:\Servidores\Log');

  // You can also specify the log format and the path where it will be saved:
  THorseLoggerManager.RegisterProvider(THorseLoggerProviderLogFile.New(LLogFileConfig));

  // Here you will define the provider that will be used.
  // THorseLoggerManager.RegisterProvider(THorseLoggerProviderLogFile.New());

  // It's necessary to add the middleware in the Horse:
  THorse.Use(THorseLoggerManager.HorseCallback);

  THorse.Get('/ping', GetPing);

  THorse.Listen(9000, OnListen);
end.
