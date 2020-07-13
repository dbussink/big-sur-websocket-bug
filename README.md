# big-sur-websocket-bug

This repository showcases a bug in the MacOS Big Sur (and likely also
iOS 14) beta (at least until beta 2).

The problem here is that the native websocket implementation will also
enable compression even if no compression was negotiated during the
initial websocket handshake.

To run this, use the following commands.

```
swiftc websocket.swift
./websocket
```

See the code for more details on when this bug gets triggered.

## Running on Big Sur

```
./websocket
Error when receiving: Error Domain=NSPOSIXErrorDomain Code=57 "Socket is not connected" UserInfo={NSErrorFailingURLStringKey=https://echo.websocket.org/, NSErrorFailingURLKey=https://echo.websocket.org/}
Closed: 1002 with reason: nil
```

## Running on Catalina

```
./websocket
Text received: aaaaaaaaaaaaaaaaa
```
