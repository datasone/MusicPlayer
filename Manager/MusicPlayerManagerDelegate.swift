//
//  MusicPlayerManagerDelegate.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/9/4.
//

import Foundation

public protocol MusicPlayerManagerDelegate: class {
    
    /// Tells the delegate the manager's tracking player has changed track.
    ///
    /// - Parameters:
    ///   - manager: The manager to handle all players.
    ///   - name: Name of the music player.
    ///   - track: The track the player change to.
    ///   - position: The player's current playing position.
    func manager(_ manager: MusicPlayerManager, trackingPlayer name: MusicPlayerName, didChangeTrack track: MusicTrack, atPosition position: TimeInterval)
    
    
    /// Tells the delegate the manager's tracking player is playing. This event will trigger every 0.5 section when playing.
    ///
    /// - Parameters:
    ///   - manager: The manager to handle all players.
    ///   - name: Name of the music player.
    ///   - position: The player's current playing position.
    func manager(_ manager: MusicPlayerManager, trackingPlayerPlaying name: MusicPlayerName, atPosition postion: TimeInterval)
    
    
    /// Tells the delegate the manager's tracking player has paused.
    ///
    /// - Parameters:
    ///   - manager: The manager to handle all players.
    ///   - name: Name of the music player.
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidPaused name: MusicPlayerName)
    
    
    /// Tells the delegate the manager's tracking player has stopped.
    ///
    /// - Parameters:
    ///   - manager: The manager to handle all players.
    ///   - name: Name of the music player.
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidStopped name: MusicPlayerName)
    
    
    /// Tells the delegate the manager's tracking player is fast forwarding.
    ///
    /// - Parameters:
    ///   - manager: The manager to handle all players.
    ///   - name: Name of the music player.
    ///   - position: The player's current playing position.
    func manager(_ manager: MusicPlayerManager, trackingPlayer name: MusicPlayerName, didFastForwardAtPosition position: TimeInterval)
    
    
    /// Tells the delegate the manager's tracking player is rewinding.
    ///
    /// - Parameters:
    ///   - manager: The manager to handle all players.
    ///   - name: Name of the music player.
    ///   - position: The player's current playing position.
    func manager(_ manager: MusicPlayerManager, trackingPlayer name: MusicPlayerName, didRewindAtPosition position: TimeInterval)
    
    
    /// Tells the delegate the manager's tracking player has quitted.
    ///
    /// - Parameters:
    ///   - manager: The manager to handle all players.
    ///   - name: Name of the music player.
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidQuit name: MusicPlayerName)
    
    
    /// Tells the delegate the manager has changed its tracking player.
    ///
    /// - Parameters:
    ///   - manager: The manager to handle all players.
    ///   - name: Name of the new music player.
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidChange name: MusicPlayerName)
    
}
