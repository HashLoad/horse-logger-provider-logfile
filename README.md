# horse-logger-provider-logfile
<b>horse-logger-provider-logfile</b> is an official <a href="https://github.com/HashLoad/horse-logger">horse-logger</a> middleware provider to save the logs of an API developed using the <a href="https://github.com/HashLoad/horse">Horse</a> framework, in a physical file. We created a channel on Telegram for questions and support:<br><br>
<a href="https://t.me/hashload">
  <img src="https://img.shields.io/badge/telegram-join%20channel-7289DA?style=flat-square">
</a>

## ⭕ Prerequisites
[**horse-logger**](https://github.com/HashLoad/horse-logger) - Official middleware for logging in APIs developed with the Horse framework.<br>
[**horse-utils-clientip**](https://github.com/dliocode/horse-utils-clientip) - Capture the client's IP.

*Obs: If you use Boss (dependency manager for Delphi), the jhonson will be installed automatically when installing horse-logger-provider-logfile.*

## ⚙️ Installation
Installation is done using the [`boss install`](https://github.com/HashLoad/boss) command:
``` sh
$ boss install horse-logger-provider-logfile
```
If you choose to install manually, simply add the following folders to your project, in *Project > Options > Resource Compiler > Directories and Conditionals > Include file search path*
```
../horse-logger-provider-logfile/src
```

## ✔️ Compatibility
This middleware is compatible with projects developed in:
- [X] Delphi
- [X] Lazarus

## 🔠 Formatting
You can format the log output:

Default: `${request_clientip} [${time}] ${request_user_agent} "${request_method} ${request_path_info} ${request_version}" ${response_status} ${response_content_length}`

Possible values: `time`,`time_short`,`execution_time`,`request_clientip`,`request_method`,`request_version`,`request_url`,`request_query`,`request_path_info`,`request_path_translated`,`request_cookie`,`request_accept`,`request_from`,`request_host`,`request_referer`,`request_user_agent`,`request_connection`,`request_derived_from`,`request_remote_addr`,`request_remote_host`,`request_script_name`,`request_server_port`,`request_remote_ip`,`request_internal_path_info`,`request_raw_path_info`,`request_cache_control`,`request_script_name`,`request_authorization`,`request_content_encoding`,`request_content_type`,`request_content_length`,`request_content_version`,`request_content`,`response_version`,`response_reason`,`response_server`,`response_realm`,`response_allow`,`response_location`,`response_log_message`,`response_title`,`response_content_encoding`,`response_content_type`,`response_content_length`,`response_content_version`,`response_content`,`response_status`

## ⚡️ Quickstart Delphi
```delphi
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
      Res.Send('pong');
    end);

  THorse.Listen(9000);
end;
```

## ⚡️ Quickstart Lazarus
```delphi
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

  THorse.Get('/ping');

  THorse.Listen(9000, OnListen);
end.
```

## 📝 Output samples
Using default log formatting, the output will look something like this:
```
0:0:0:0:0:0:0:1 [06/outubro/2021 10:34:53.949] PostmanRuntime/7.28.4 "GET /ping HTTP/1.1" 200 4
0:0:0:0:0:0:0:1 [06/outubro/2021 10:34:55.842] PostmanRuntime/7.28.4 "GET /ping HTTP/1.1" 200 4
0:0:0:0:0:0:0:1 [06/outubro/2021 10:34:56.887] PostmanRuntime/7.28.4 "GET /ping HTTP/1.1" 200 4
0:0:0:0:0:0:0:1 [06/outubro/2021 10:35:24.458] PostmanRuntime/7.28.4 "GET /ping HTTP/1.1" 200 4
0:0:0:0:0:0:0:1 [06/outubro/2021 10:35:31.638] PostmanRuntime/7.28.4 "GET /ping HTTP/1.1" 200 4
0:0:0:0:0:0:0:1 [06/outubro/2021 10:35:32.685] PostmanRuntime/7.28.4 "GET /ping HTTP/1.1" 200 4
0:0:0:0:0:0:0:1 [06/outubro/2021 10:35:33.590] PostmanRuntime/7.28.4 "GET /ping HTTP/1.1" 200 4
```

## ⚠️ License
`horse-logger-provider-logfile` is free and open-source middleware licensed under the [MIT License](https://github.com/HashLoad/horse-logger-provider-logfile/blob/master/LICENSE).
