//
//  MusicPlayerManagerDelegate.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/9/4.
//

import Foundation

public protocol MusicPlayerManagerDelegate: class {
    
    func manager(_ manager: MusicPlayerManager, trackingPlayer name: MusicPlayerName, didChangeTrack track: MusicTrack, atPosition position: TimeInterval)
    
    
    func manager(_ manager: MusicPlayerManager, trackingPlayerPlaying name: MusicPlayerName, atPosition postion: TimeInterval)
    
    
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidPaused name: MusicPlayerName)
    
    
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidStopped name: MusicPlayerName)
    
    
    func manager(_ manager: MusicPlayerManager, trackingPlayer name: MusicPlayerName, didFastForwardAtPosition position: TimeInterval)
    
    
    func manager(_ manager: MusicPlayerManager, trackingPlayer name: MusicPlayerName, didRewindAtPosition position: TimeInterval)
    
    
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidQuit name: MusicPlayerName)
    
    
    func manager(_ manager: MusicPlayerManager, trackingPlayerDidChange name: MusicPlayerName)
    
}
