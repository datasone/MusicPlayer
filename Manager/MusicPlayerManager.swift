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
    
    fileprivate(set) var currentPlayer: MusicPlayer?
    
    public init() {
        musicPlayers = []
    }
}

// MARK: - Public Manager Methods

public extension MusicPlayerManager {
    
    /// The player names that added to the manager.
    public var allPlayerNames: [MusicPlayerName] {
        var playerNames = [MusicPlayerName]()
        for player in musicPlayers {
            playerNames.append(player.name)
        }
        return playerNames
    }
    
    /// Return the player with selected name if exists.
    public func existMusicPlayer(with name: MusicPlayerName) -> MusicPlayer? {
        for player in musicPlayers {
            if player.name == name {
                return player
            }
        }
        return nil
    }
    
    /// Add a music player to the manager.
    ///
    /// - Parameter name: The name of the music player you wanna add.
    public func add(musicPlayer name: MusicPlayerName) {
        for player in musicPlayers {
            guard player.name != name else { return }
        }
        guard let player = MusicPlayerFactory.musicPlayer(name: name) else { return }
        player.delegate = self
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

// MARK: - MusicPlayerDelegate

extension MusicPlayerManager: MusicPlayerDelegate {
    
    public func player(_ player: MusicPlayer, didChangeTrack track: MusicTrack, atPosition position: TimeInterval) {
        guard shouldHandleEvent(with: player) else { return }
        delegate?.manager(self, trackingPlayer: player.name, didChangeTrack: track, atPosition: position)
    }
    
    public func player(_ player: MusicPlayer, playbackStateChanged playbackState: MusicPlaybackState, atPosition postion: TimeInterval) {
        guard shouldHandleEvent(with: player) else { return }
        
        switch playbackState {
        case .paused, .stopped:
            currentPlayer = nil
        default:
            break
        }
    }
    
    public func playerDidQuit(_ player: MusicPlayer) {
        guard shouldHandleEvent(with: player) else { return }
        delegate?.manager(self, trackingPlayerDidQuit: player.name)
        currentPlayer = nil
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
