//
//  MusicPlayerManager.swift
//
//  This file is part of LyricsX
//  Copyright (C) 2017  Xander Deng
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
#if canImport(AppKit)
import AppKit
#endif

public class MusicPlayerManager: MusicPlayerDelegate {
    
    public weak var delegate: MusicPlayerManagerDelegate?
    
    public private(set) var players: [MusicPlayer]
    public private(set) weak var player: MusicPlayer?
    
    public var manualUpdateInterval = 1.0 {
        didSet {
            let d = _timer.fireDate
            _timer.invalidate()
            _timer = Timer.scheduledTimer(timeInterval: manualUpdateInterval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
            _timer.fireDate = d
            _timer.tolerance = manualUpdateInterval / 10
        }
    }
    
    private var _timer: Timer!
    
    public init(players: [MusicPlayer]) {
        self.players = players
        players.forEach { $0.delegate = self }
        _ = selectNewPlayer()
        _timer = Timer.scheduledTimer(timeInterval: manualUpdateInterval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        _timer.tolerance = 0.1
    }
    
    @objc func update() {
        // TODO: running state change delegate
        for p in players {
            if type(of: p).needsUpdateIfNotSelected || p === player {
                p.updatePlayerState()
            }
        }
    }
    
    // MARK: - MusicPlayerDelegate
    
    public func currentTrackChanged(track: MusicTrack?, from player: MusicPlayer) {
        guard self.player === player else {
            _ = selectNewPlayer()
            return
        }
        delegate?.currentTrackChanged(track: track)
    }
    
    public func playbackStateChanged(state: MusicPlaybackState, from player: MusicPlayer) {
        guard self.player === player else {
            if self.player?.playbackState.isPlaying != true, state == .playing {
                self.player = player
                delegate?.currentPlayerChanged(player: player)
            }
            return
        }
        if !selectNewPlayer() {
            delegate?.playbackStateChanged(state: state)
        }
    }
    
    public func playerPositionMutated(position: TimeInterval, from player: MusicPlayer) {
        guard self.player === player else {
            return
        }
        delegate?.playerPositionMutated(position: position)
        _timer.fireDate = Date().addingTimeInterval(0.2)
    }
    
    // MARK: - Mac
    
    #if os(macOS)
    
    private var workspaceObservation: [NSObjectProtocol] = []
    
    public var preferredPlayerName: MusicPlayerName? {
        didSet {
            guard oldValue != preferredPlayerName else { return }
            _ = selectNewPlayer()
        }
    }
    
    public convenience init() {
        let players = MusicPlayerName.allCases.compactMap { $0.cls.init() }
        self.init(players: players)
        addObserver()
    }
    
    deinit {
        workspaceObservation.forEach(NSWorkspace.shared.notificationCenter.removeObserver)
    }
    
    func selectNewPlayer() -> Bool {
        var newPlayer: MusicPlayer?
        if let name = preferredPlayerName {
            newPlayer = players.first { type(of: $0) == name.cls }
        } else if player?.playbackState == .playing {
            newPlayer = player
        } else if let playing = players.first(where: { $0.playbackState == .playing }) {
            newPlayer = playing
        } else if player?.isRunning == true {
            newPlayer = player
        } else {
            newPlayer = players.first { $0.isRunning }
        }
        if newPlayer !== player {
            player = newPlayer
            delegate?.currentPlayerChanged(player: player)
            return true
        } else {
            return false
        }
    }
    
    func addObserver() {
        let workspaceNC = NSWorkspace.shared.notificationCenter
        let callback: (Notification) -> Void = { [unowned self] n in
            guard let userInfo = n.userInfo, let player = self.player else { return }
            if userInfo["NSApplicationBundleIdentifier"] as? String == type(of: player).name.bundleID {
                switch n.name {
                case NSWorkspace.didTerminateApplicationNotification:
                    self.delegate?.runningStateChanged(isRunning: false)
                case NSWorkspace.didLaunchApplicationNotification:
                    self.delegate?.runningStateChanged(isRunning: true)
                default: break
                }
            }
        }
        workspaceObservation += [
            workspaceNC.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: nil, using: callback),
            workspaceNC.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: nil, using: callback),
        ]
    }
    
    #elseif os(iOS)
    
    func selectNewPlayer() -> Bool {
        var newPlayer: MusicPlayer?
        let defaultPlayerName = MusicPlayerName.appleMusic
        
        if player?.playbackState == .playing {
            newPlayer = player
        } else if let playing = players.first(where: { $0.playbackState == .playing }) {
            newPlayer = playing
        } else if player == nil {
            player = players.first { type(of: $0).name == defaultPlayerName }
        } else {
            newPlayer = player
        }
        
        if newPlayer !== player {
            player = newPlayer
            delegate?.currentPlayerChanged(player: player)
            return true
        } else {
            return false
        }
    }
    
    #endif
}
