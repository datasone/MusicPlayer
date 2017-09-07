//
//  MusicPlayerManager.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/9/3.
//

import Foundation

public class MusicPlayerManager {
    
    public weak var delegate: MusicPlayerManagerDelegate?
    
    fileprivate var musicPlayers: [MusicPlayer]
    
    fileprivate var currentPlayer: MusicPlayer?
    
    public init() {
        musicPlayers = []
    }
}

// MARK: - Public Manager Methods

public extension MusicPlayerManager {
    
    /// The player name that manager currently tracking.
    public var currentPlayerName: MusicPlayerName? {
        return currentPlayer?.name
    }
    
    /// The player names that added to the manager.
    public var allPlayerNames: [MusicPlayerName] {
        var playerNames = [MusicPlayerName]()
        for player in musicPlayers {
            playerNames.append(player.name)
        }
        return playerNames
    }
    
    /// Activate music player with name. If not exists, you can add it to the manager if needed.
    public func activate(player name: MusicPlayerName, addPlayerIfNeeded: Bool) {
        var player = existMusicPlayer(with: name)
        if player == nil && addPlayerIfNeeded {
            guard let p = MusicPlayerFactory.musicPlayer(name: name) else { return }
            player = p
        } else {
            return
        }
        player?.activate()
    }
    
    /// Add a music player to the manager.
    ///
    /// - Parameter name: The name of the music player you wanna add.
    public func add(musicPlayer name: MusicPlayerName) {
        for player in musicPlayers {
            guard player.name != name else { return }
        }
        guard let player = MusicPlayerFactory.musicPlayer(name: name) else { return }
        player.startPlayerTracking()
        musicPlayers.append(player)
    }
    
    /// Add music players to the manager.
    ///
    /// - Parameter names: The names of the music player you wanna add.
    public func add(musicPlayers names: [MusicPlayerName]) {
        for name in names {
            add(musicPlayer: name)
        }
    }
    
    /// Remove a music player from the manager.
    ///
    /// - Parameter name: The name of the music player you wanna remove.
    public func remove(musicPlayer name: MusicPlayerName) {
        for index in 0 ..< musicPlayers.count {
            let player = musicPlayers[index]
            guard player.name == name else { continue }
            player.stopPlayerTracking()
            musicPlayers.remove(at: index)
            return
        }
    }
    
    /// Remove music players from the manager.
    ///
    /// - Parameter names: The names of the music player you wanna remove.
    public func remove(musicPlayers names: [MusicPlayerName]) {
        for name in names {
            remove(musicPlayer: name)
        }
    }
}

// MARK: - Public Playback Methods

extension MusicPlayerManager: PlaybackControl {
    
    public var playbackState: MusicPlaybackState {
        guard currentPlayer != nil else { return .notRunning }
        return currentPlayer!.playbackState
    }
    
    public var repeatMode: MusicRepeatMode? {
        get {
            return currentPlayer?.repeatMode
        }
        set {
            currentPlayer?.repeatMode = newValue
        }
    }
    
    public var shuffleMode: MusicShuffleMode? {
        get {
            return currentPlayer?.shuffleMode
        }
        set {
            currentPlayer?.shuffleMode = newValue
        }
    }
    
    public var playerPosition: TimeInterval {
        get {
            guard currentPlayer != nil else { return 0 }
            return currentPlayer!.playerPosition
        }
        set {
            currentPlayer?.playerPosition = newValue
        }
    }
    
    public func play() {
        currentPlayer?.play()
    }
    
    public func pause() {
        currentPlayer?.pause()
    }
    
    public func stop() {
        currentPlayer?.stop()
    }
    
    public func playNext() {
        currentPlayer?.playNext()
    }
    
    public func playPrevious() {
        currentPlayer?.playPrevious()
    }
}

// MARK: - MusicPlayerDelegate

extension MusicPlayerManager: MusicPlayerDelegate {
    
    func player(_ player: MusicPlayer, didChangeTrack track: MusicTrack, atPosition position: TimeInterval) {
        guard shouldHandleEvent(with: player) else { return }
        delegate?.manager(self, trackingPlayer: player.name, didChangeTrack: track, atPosition: position)
    }
    
    func playerPlaying(_ player: MusicPlayer, atPosition postion: TimeInterval) {
        guard shouldHandleEvent(with: player) else { return }
        delegate?.manager(self, trackingPlayerPlaying: player.name, atPosition: postion)
    }
    
    func playerDidPaused(_ player: MusicPlayer) {
        guard shouldHandleEvent(with: player) else { return }
        delegate?.manager(self, trackingPlayerDidPaused: player.name)
        currentPlayer = nil
    }
    
    func playerDidStopped(_ player: MusicPlayer) {
        guard shouldHandleEvent(with: player) else { return }
        delegate?.manager(self, trackingPlayerDidStopped: player.name)
        currentPlayer = nil
    }
    
    func player(_ player: MusicPlayer, didFastForwardAtPosition position: TimeInterval) {
        guard shouldHandleEvent(with: player) else { return }
        delegate?.manager(self, trackingPlayer: player.name, didFastForwardAtPosition: position)
    }
    
    func player(_ player: MusicPlayer, didRewindAtPosition position: TimeInterval) {
        guard shouldHandleEvent(with: player) else { return }
        delegate?.manager(self, trackingPlayer: player.name, didRewindAtPosition: position)
    }
    
    func playerDidQuit(_ player: MusicPlayer) {
        guard shouldHandleEvent(with: player) else { return }
        delegate?.manager(self, trackingPlayerDidQuit: player.name)
        currentPlayer = nil
    }
}

// MARK: - Private Mehtods

fileprivate extension MusicPlayerManager {
    
    fileprivate func existMusicPlayer(with name: MusicPlayerName) -> MusicPlayer? {
        for player in musicPlayers {
            if player.name == name {
                return player
            }
        }
        return nil
    }
    
    fileprivate func shouldHandleEvent(with player: MusicPlayer) -> Bool {
        if currentPlayer == nil {
            currentPlayer = player
            delegate?.manager(self, trackingPlayerDidChange: player.name)
            return true
        } else if (currentPlayer!.name == player.name) {
            return true
        } else {
            return false
        }
    }
    
}
