import Cocoa
import WebKit

// Serves local HTML/CSS/JS files over a custom "app://" scheme so that
// localStorage and other web APIs work correctly (they're blocked on file://).
final class LocalFileSchemeHandler: NSObject, WKURLSchemeHandler, @unchecked Sendable {
    func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }

        var fileName = url.lastPathComponent
        if fileName.isEmpty || fileName == "localhost" {
            fileName = "index.html"
        }

        let nameNoExt = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension

        guard let filePath = Bundle.main.path(forResource: nameNoExt, ofType: ext.isEmpty ? nil : ext),
              let data = FileManager.default.contents(atPath: filePath) else {
            let resp = HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: nil)!
            urlSchemeTask.didReceive(resp)
            urlSchemeTask.didReceive(Data())
            urlSchemeTask.didFinish()
            return
        }

        let mime: String
        switch ext.lowercased() {
        case "html": mime = "text/html; charset=utf-8"
        case "css":  mime = "text/css"
        case "js":   mime = "application/javascript"
        case "json": mime = "application/json"
        case "svg":  mime = "image/svg+xml"
        default:     mime = "application/octet-stream"
        }

        let resp = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                   headerFields: ["Content-Type": mime, "Content-Length": "\(data.count)"])!
        urlSchemeTask.didReceive(resp)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {}
}

// Note: AppKit calls delegate methods on the main thread; @MainActor not needed here.
final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenuBar()

        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(LocalFileSchemeHandler(), forURLScheme: "app")

        // Enable Web Inspector
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs

        let windowRect = NSRect(x: 0, y: 0, width: 1280, height: 820)
        window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Mortgage Playbook"
        window.minSize = NSSize(width: 960, height: 660)
        window.setFrameAutosaveName("MortgagePlaybookWindow")

        webView = WKWebView(frame: windowRect, configuration: config)
        webView.autoresizingMask = [.width, .height]
        window.contentView = webView
        window.center()

        let startURL = URL(string: "app://localhost/index.html")!
        webView.load(URLRequest(url: startURL))

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func buildMenuBar() {
        let mainMenu = NSMenu()

        // ── App menu ─────────────────────────────────────────────────────
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "About Mortgage Playbook",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                        keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Mortgage Playbook",
                        action: #selector(NSApplication.terminate(_:)),
                        keyEquivalent: "q")

        // ── View menu ─────────────────────────────────────────────────────
        let viewItem = NSMenuItem()
        mainMenu.addItem(viewItem)
        let viewMenu = NSMenu(title: "View")
        viewItem.submenu = viewMenu
        let reloadItem = NSMenuItem(title: "Reload", action: #selector(reload), keyEquivalent: "r")
        reloadItem.target = self
        viewMenu.addItem(reloadItem)

        NSApp.mainMenu = mainMenu
    }

    @objc func reload() { webView.reload() }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
