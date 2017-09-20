//
//  TimerDispatcher.swift
//  MusicPlayer
//
//  Created by Michael Row on 2017/9/18.
//

import Foundation

class TimerDispatcher {
    
    static let shared = TimerDispatcher()
    
    private var callbackDict: [HashClass : (TimeInterval) -> Void]
    
    private var precisionDict: [HashClass : TimeInterval]
    
    private var timer: Timer?
    
    private init() {
        callbackDict = [:]
        precisionDict = [:]
    }
    
    // MARK: - Public Methods
    
    /// Register player for periodically callback with promised precision.
    ///
    /// - Warning: This method is based on Timer, so it's not a real-time mechanism. And the interval of
    ///   internal timer is equal and less than the precision needed. Note that if the main runloop is busy,
    ///   it would delay or just skip. The dispatcher would maintain strong reference to the player and closure
    ///   before you unregistering from it.
    ///
    /// - Parameters:
    ///   - player: Selected player.
    ///   - timerPrecision: Timer precision needed.
    func register<T>(player: T, timerPrecision: TimeInterval, callback: @escaping (TimeInterval) -> Void) where T: MusicPlayer, T: HashClass {        
        timer?.invalidate()
        callbackDict[player] = callback
        precisionDict[player] = timerPrecision
        fireTimer()
    }
    
    /// Unregister player for periodically callback
    ///
    /// - Parameter player: Selected player.
    func unregister<T>(player: T) where T: MusicPlayer, T: HashClass {
        guard callbackDict.keys.contains(player) else { return }
        
        timer?.invalidate()
        callbackDict.removeValue(forKey: player)
        precisionDict.removeValue(forKey: player)
        fireTimer()
    }
    
    // MARK: - Private Methods
    
    private func fireTimer() {
        guard precisionDict.count > 0 else { return }
        
        // get the min time interval
        let allPrecision = precisionDict.values
        var minPrecision = allPrecision.first!
        for precision in allPrecision {
            minPrecision = min(minPrecision, precision)
        }
        
        // start timer
        timer?.invalidate()
        timer = Timer(timeInterval: minPrecision, target: self, selector: #selector(notifyAllObservers(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .commonModes)
    }
    
    @objc private func notifyAllObservers(_ timer: Timer) {
        let precision = timer.timeInterval
        for callback in callbackDict.values {
            callback(precision)
        }
    }
    
}
