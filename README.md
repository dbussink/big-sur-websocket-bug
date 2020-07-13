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

```
Frame 5: 398 bytes on wire (3184 bits), 398 bytes captured (3184 bits)
Null/Loopback
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
Transmission Control Protocol, Src Port: 51637, Dst Port: 8080, Seq: 1, Ack: 1, Len: 342
Hypertext Transfer Protocol
    GET / HTTP/1.1\r\n
    Host: 127.0.0.1:8080\r\n
    User-Agent: websocket (unknown version) CFNetwork/1179.0.1 Darwin/20.0.0\r\n
    Sec-WebSocket-Key: q+Ui0vA7MRW++Zu8xT/fbw==\r\n
    Sec-WebSocket-Version: 13\r\n
    Upgrade: websocket\r\n
    Accept: */*\r\n
    Sec-WebSocket-Extensions: permessage-deflate\r\n
    Accept-Language: en-us\r\n
    Accept-Encoding: gzip, deflate\r\n
    Connection: Upgrade\r\n
    \r\n
    [Full request URI: http://127.0.0.1:8080/]
    [HTTP request 1/1]
    [Response in frame: 7]
```

As can be seen here, compression is requested with the
`permessage-deflate` extension. The reply doesn't include this so it
should not be negotiated.

```
Frame 7: 222 bytes on wire (1776 bits), 222 bytes captured (1776 bits)
Null/Loopback
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
Transmission Control Protocol, Src Port: 8080, Dst Port: 51637, Seq: 1, Ack: 343, Len: 166
Hypertext Transfer Protocol
    HTTP/1.1 101 Switching Protocols\r\n
    Connection: Upgrade\r\n
    Sec-Websocket-Accept: VEQfl+TavglIvUsut3Hc+SqUeSg=\r\n
    Upgrade: websocket\r\n
    Date: Mon, 13 Jul 2020 09:09:01 GMT\r\n
    \r\n
    [HTTP response 1/1]
    [Time since request: 0.000136000 seconds]
    [Request in frame: 5]
    [Request URI: http://127.0.0.1:8080/]
```

But then if one looks at the first frame being sent over the websocket,
it does have compression bits enabled.

```
Frame 9: 68 bytes on wire (544 bits), 68 bytes captured (544 bits)
Null/Loopback
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
Transmission Control Protocol, Src Port: 51637, Dst Port: 8080, Seq: 343, Ack: 167, Len: 12
WebSocket
    1... .... = Fin: True
    .100 .... = Reserved: 0x4
    .... 0001 = Opcode: Text (1)
    1... .... = Mask: True
    .000 0110 = Payload length: 6
    Masking-Key: 68304418
    Masked payload
    Payload
Line-based text data (1 lines)
    JLD\003\000\000
```

What can be seen here is that the first reserved bit is set that for
compression signals that the compression for this message is enabled.
This is incorrect here, since in the original handshake it was not
negotiated.

It also shows that Wireshark (used to analyse the `pcap` files) doesn't
automatically decompress and show the message, as it's invalid state for
the connection and the text data contains the compressed bytes.

### Conclusion

Big Sur seems to add per message compression for websockets but there
are bugs in the implementation that cause it to generate invalid data.
Catalina doesn't have this problem as compression is not supported
there.
