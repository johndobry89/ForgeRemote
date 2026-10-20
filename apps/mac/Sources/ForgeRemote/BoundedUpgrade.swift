import Vapor
import NIOHTTP1
import NIOWebSocket

/// Vapor's convenience upgrader defaults to unlimited fragment aggregation.
/// Set both wire-frame and aggregate-message bounds before installing callbacks.
struct BoundedUpgrade: Upgrader {
    let onUpgrade: @Sendable (WebSocket) -> Void
    func applyUpgrade(req: Request, res: Response) -> HTTPServerProtocolUpgrader {
        NIOWebSocketServerUpgrader(maxFrameSize: 4096, automaticErrorHandling: true, shouldUpgrade: { channel,_ in
            channel.eventLoop.makeSucceededFuture(HTTPHeaders())
        }, upgradePipelineHandler: { channel,_ in
            var config = WebSocket.Configuration()
            config.maxAccumulatedFrameSize = 4096
            config.maxAccumulatedFrameCount = 4
            config.minNonFinalFragmentSize = 1
            return WebSocket.server(on: channel, config: config, onUpgrade: onUpgrade)
        })
    }
}
