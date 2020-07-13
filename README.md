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

## Running on Catalina

```
./websocket
Text received: aaaaaaaaaaaaaaaaa
```

## Running on Big Sur

```
./websocket
Error when receiving: Error Domain=NSPOSIXErrorDomain Code=57 "Socket is not connected" UserInfo={NSErrorFailingURLStringKey=https://echo.websocket.org/, NSErrorFailingURLKey=https://echo.websocket.org/}
Closed: 1002 with reason: nil
```

## `tcpdump` of both paths

Comparison of a `tcpdump` for the handshake on Big Sur vs. Catalina
shows that on Big Sur, support for compression was added, but likely
this bug was introduced. This dump was running against a local websocket
echo server.


### Catalina handshake

```
Frame 5: 357 bytes on wire (2856 bits), 357 bytes captured (2856 bits)
Null/Loopback
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
Transmission Control Protocol, Src Port: 54218, Dst Port: 8080, Seq: 1, Ack: 1, Len: 301
Hypertext Transfer Protocol
    GET / HTTP/1.1\r\n
    Host: 127.0.0.1:8080\r\n
    Sec-WebSocket-Key: HRJXSVBy2tRHk5Ol9tFS3Q==\r\n
    Sec-WebSocket-Version: 13\r\n
    Upgrade: websocket\r\n
    Accept: */*\r\n
    Accept-Language: en-us\r\n
    User-Agent: websocket (unknown version) CFNetwork/1126 Darwin/19.5.0 (x86_64)\r\n
    Accept-Encoding: gzip, deflate\r\n
    Connection: Upgrade\r\n
    \r\n
    [Full request URI: http://127.0.0.1:8080/]
    [HTTP request 1/1]
    [Response in frame: 7]
```

As can be seen here, there's no request for compression here for the
websocket, so it is not enabled and also not sent in the next websocket
frame.

```
Frame 9: 79 bytes on wire (632 bits), 79 bytes captured (632 bits)
Null/Loopback
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
Transmission Control Protocol, Src Port: 54218, Dst Port: 8080, Seq: 302, Ack: 167, Len: 23
WebSocket
    1... .... = Fin: True
    .000 .... = Reserved: 0x0
    .... 0001 = Opcode: Text (1)
    1... .... = Mask: True
    .001 0001 = Payload length: 17
    Masking-Key: a489e900
    Masked payload
    Payload
Line-based text data (1 lines)
    aaaaaaaaaaaaaaaaa
```

The dump here shows that none of the reserved bits are set, not the
first bit either that normally indicates compression.

### Big Sur handshake
