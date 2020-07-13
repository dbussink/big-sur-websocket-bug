import Foundation


func randomString(length: Int) -> String {
  let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
  return String((0..<length).map{ _ in letters.randomElement()! })
}

class CloseDelegate: NSObject, URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        var rsn = "nil"
        if (reason != nil) {
            rsn = String(data: reason!, encoding: .utf8)!
        }
        print("Closed: \(closeCode.rawValue) with reason: \(rsn)")
        exit(EXIT_FAILURE)
    }
}

let session = URLSession(configuration: .default, delegate: CloseDelegate(), delegateQueue: OperationQueue())

// Point at a websocket echo service
let task = session.webSocketTask(with: URL(string: "wss://echo.websocket.org")!)


// Send a message that triggers compression heuristics. It seems like a small non
// repetitive message doesn't error out, but anything that's more repetative or
// larger will trigger compression.
let textMessage = URLSessionWebSocketTask.Message.string(randomString(length: 1024))

// Send the message that the echo server will send back.
task.send(textMessage) { error in
  if let error = error {
    print("WebSocket couldn’t send message because: \(error)")
  }
}

// Receive message back from echo server.
task.receive { result in
    switch result {
    case .success(let message):
        switch message {
        case .data(let data):
            print("Data received: \(data)")
        case .string(let text):
            print("Text received: \(text)")
        default:
            print("Invalid response: \(message)")
            exit(EXIT_FAILURE)
        }
        exit(EXIT_SUCCESS)
    case .failure(let error):
        print("Error when receiving: \(error)")
    }
}

task.resume()
dispatchMain()
