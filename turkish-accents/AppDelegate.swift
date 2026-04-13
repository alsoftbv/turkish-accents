import Cocoa
import InputMethodKit

// NSApplication subclass that wires its delegate manually so the Info.plist
// NSPrincipalClass path can instantiate the app without a Main.storyboard.
final class NSManualApplication: NSApplication {
    private let appDelegate = AppDelegate()

    override init() {
        super.init()
        self.delegate = appDelegate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    var server: IMKServer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String
        server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier)
    }
}
