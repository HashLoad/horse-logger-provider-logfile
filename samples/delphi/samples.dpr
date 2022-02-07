program samples;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  Horse,
  Horse.Logger, // It's necessary to use the unit
  Horse.Logger.Provider.LogFile, // It's necessary to use the unit
  System.SysUtils;

var
  LLogFileConfig: THorseLoggerLogFileConfig;

begin
  LLogFileConfig := THorseLoggerLogFileConfig.New
    .SetLogFormat('${request_clientip} [${time}] ${response_status}')
    .SetDir('D:\Servidores\Log');

  // You can also specify the log format and the path where it will be saved:
  // THorseLoggerManager.RegisterProvider(THorseLoggerProviderLogFile.New(LLogFileConfig));

  // Here you will define the provider that will be used.
  THorseLoggerManager.RegisterProvider(THorseLoggerProviderLogFile.New());

  // It's necessary to add the middleware in the Horse:
  THorse.Use(THorseLoggerManager.HorseCallback);

  THorse.Get('/ping',
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    begin
      Res.Send('{"nome":"Vinicius"}').ContentType('application/json');
    end);

  THorse.Listen(9000);
end.
