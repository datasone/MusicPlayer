//
//  MusicPlayerDelegate.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/9/2.
//

import Foundation

protocol MusicPlayerDelegate: class {
    
    /// Tells the delegate the playing track has been changed.
    ///
    /// - Parameters:
    ///   - player: The player which triggers this event.
    ///   - track: The track which is played by the player.
    func player(_ player: MusicPlayer, didChangeTrack track: MusicTrack, atPosition position: TimeInterval)
    
    
    /// Tells the delegate the player is playing.
    ///
    /// - Parameters:
    ///   - player: The player which triggers this event.
    ///   - position: Player position.
    func playerPlaying(_ player: MusicPlayer, atPosition postion: TimeInterval)
    
    
    /// Tells the delegate the player has paused.
    ///
    /// - Parameter player: The player which triggers this event.
    func playerDidPaused(_ player: MusicPlayer)
    
    
    /// Tells the delegate the player has stopped.
    ///
    /// - Parameter player: The player which triggers this event.
    func playerDidStopped(_ player: MusicPlayer)
    
    
    /// Tells the delegate the player has fast forwarded.
    ///
    /// - Parameters:
    ///   - player: The player which triggers this event.
    ///   - position: Player position.
    func player(_ player: MusicPlayer, didFastForwardAtPosition position: TimeInterval)
    
    
    /// Tells the delegate the player has rewinded.
    ///
    /// - Parameters:
    ///   - player: The player which triggers this event.
    ///   - position: Player position.
    func player(_ player: MusicPlayer, didRewindAtPosition position: TimeInterval)
    
    
    /// Tells the delegate the player has quitted.
    ///
    /// - Parameter player: The player which triggers this event.
    func playerDidQuit(_ player: MusicPlayer)
        
}
