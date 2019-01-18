//
//  AppDelegate.swift
//  Bifrost
//
//  Created by Tung Dao on 4/1/2019.
//  Copyright © 2019 Tung Dao. All rights reserved.
//

import Cocoa
import PathKit

class GatewayMenuItem: NSMenuItem {
    let port: Int

    init(service: String, port: Int, action: Selector?, keyEquivalent: String) {
        self.port = port
        super.init(title: service, action: action, keyEquivalent: keyEquivalent)
    }

    func buildProcess(host: String) -> Process {
        let process = Process()
        process.launchPath = "/usr/bin/ssh"
        process.arguments = [
            // "-F", Path("~/.ssh/config").absolute().string,
            "-vvv", "-CN",
            "-L", String(format: "%d:127.0.0.1:%d", port, port),
            host
        ]
        return process
    }

    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let hostMenu = NSMenu()

    var host: String? = nil

    var tasks: Dictionary<String, Process> = [:]

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name("StatusBarButtonImage"))
        }

        buildMenuItems()

        loadHostList().forEach { host in
            hostMenu.addItem(NSMenuItem(
                title: host,
                action: #selector(AppDelegate.setHost(_:)),
                keyEquivalent: ""
            ))
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        tasks.forEach { _, process in
            if process.isRunning {
                process.terminate()
                process.waitUntilExit()
            }
        }
    }

    func loadHostList() -> [String] {
        do {
            let lines: String = try Path("~/.ssh/config").absolute().read()
            return lines.split(separator: "\n").filter { line in
                return line.starts(with: "Host ")
            }.map { line in
                return String(line[line.index(line.startIndex, offsetBy: 5)...])
            }
        } catch {
            print("Error error: \(error).", to: &standardError)
        }

        return []
    }

    func buildMenuItems() {
        let menu = NSMenu()

        let hostMenuItem = NSMenuItem(title: "Host", action: nil, keyEquivalent: "")
        hostMenuItem.submenu = hostMenu
        menu.addItem(hostMenuItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(GatewayMenuItem(service: "Sock5", port: 1080, action: #selector(AppDelegate.toggleProxy(_:)), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(GatewayMenuItem(service: "Docker", port: 2375, action: #selector(AppDelegate.toggleProxy(_:)), keyEquivalent: ""))
        menu.addItem(GatewayMenuItem(service: "Kubernetes API", port: 6443, action: #selector(AppDelegate.toggleProxy(_:)), keyEquivalent: ""))
        menu.addItem(GatewayMenuItem(service: "Kubernetes Dashboard", port: 8443, action: #selector(AppDelegate.toggleProxy(_:)), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(GatewayMenuItem(service: "Prometheus", port: 9090, action: #selector(AppDelegate.toggleProxy(_:)), keyEquivalent: ""))

//        menu.addItem(GatewayMenuItem(service: "PostgreSQL", port: 5432, action: #selector(AppDelegate.toggleProxy(_:)), keyEquivalent: ""))
//        menu.addItem(GatewayMenuItem(service: "MySQL", port: 3306, action: #selector(AppDelegate.toggleProxy(_:)), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "TODO: Kubernetes Pods", action: #selector(AppDelegate.toggleProxy(_:)), keyEquivalent: ""))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "TODO: Show output window", action: #selector(AppDelegate.toggleProxy(_:)), keyEquivalent: ""))

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc func setHost(_ sender: Any?) {
        if let item = sender as? NSMenuItem {
            host = item.title
            hostMenu.items.forEach { i in
                i.state = .off
            }
            item.state = .on
        }
    }

    @objc func toggleProxy(_ sender: Any?) {
        if let item = sender as? GatewayMenuItem {
            if item.state == .on, let process = tasks[item.title] {
                process.terminate()
                tasks.removeValue(forKey: item.title)
                item.state = .off
                return
            }

            if item.state == .off {
                tasks[item.title] = item.buildProcess(host: host!)
                do {
                    try tasks[item.title]!.run()
                } catch {
                    // TODO: handle error correctly
                    print("Error error: \(error).", to: &standardError)
                }
                item.state = .on
                return
            }
        }
    }
}

var standardError = FileHandle.standardError

extension FileHandle : TextOutputStream {
    public func write(_ string: String) {
        guard let data = string.data(using: .utf8) else { return }
        self.write(data)
    }
}
