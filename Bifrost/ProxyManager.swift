//
//  ProxyManager.swift
//  Bifrost
//
//  Created by Tung Dao on 7/1/2019.
//  Copyright © 2019 Tung Dao. All rights reserved.
//

import Foundation

class ProcessManager {

    var tasks: Dictionary<String, Process> = [:]

    func startProxy(host: String, port: Int) {
        // TODO: port available check
    }
}

class SSHForwardProxyProcess: Process {
    var host = ""
    var port = 0

    convenience init(host: String, port: Int) {
        self.init()
        self.host = host
        self.port = port
        launchPath = "/usr/bin/ssh"
    }

    override func run() throws {
        arguments = [
            // "-F", Path("~/.ssh/config").absolute().string,
            "-vvv", "-CN",
            "-L", String(format: "%d:127.0.0.1:%d", port, port),
            host
        ]
        try super.run()
    }
}

class SSHSock5Process: SSHForwardProxyProcess {
    override func run() throws {
        arguments = [
            // "-F", Path("~/.ssh/config").absolute().string,
            "-vvv", "-CN",
            "-D", String(format: "%d"),
            host
        ]
        try super.run()
    }
}

class KubernetesProxyManager: Process {
    var namespace = ""
    var pod = ""
    var port = 0

    convenience init(pod: String, port: Int) {
        self.init()
        self.pod = pod
        self.port = port
        launchPath = "/usr/local/bin/kubectl"
    }

    override func run() throws {
        arguments = [
            "port-forward", pod, String(format: "%d:%d", port, port),
            "--namespace", namespace
        ]
        try super.run()
    }

    static var available: [String] {
        get {
            let process = Process()
            process.launchPath = "/usr/local/bin/kubectl"
//            guard try? process.run()
//                return []
//                else { return [] }
            return []
        }
    }
}
