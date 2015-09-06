//
//  Speech.siwft.swift
//  Dictater
//
//  Created by Kyle Carson on 9/4/15.
//  Copyright © 2015 Kyle Carson. All rights reserved.
//

import Foundation
import Cocoa

class Speech
{
	static var sharedSpeech : Speech =
	{
		return Speech()
	}()
	
	private var text = ""
	
	var vocalization : Vocalization?
	
	func speak(text : String)
	{
		self.text = text
		self.speak(fromIndex: 0)
	}
	
	enum Boundary : Int
	{
		case Sentence = 1
		case Paragraph = 100
		
		var name : String {
			if self == .Sentence
			{
				return "Sentence"
			} else {
				return "Paragraph"
			}
		}
		
		var enumerationOption : NSStringEnumerationOptions
		{
			if self == .Sentence
			{
				return .BySentences
			} else {
				return .ByParagraphs
			}
		}
	}
	
	static let ProgressChangedNotification = "Speech.ProgressChangedNotification"
	
	var progress : NSProgress
	{
		let progress = NSProgress()
		if let range = self.range
		{
			progress.totalUnitCount = Int64(text.characters.count)
			progress.completedUnitCount = Int64(range.location)
		}
		return progress
	}
	
	var range : NSRange?
	{
		get {
			
			if let vocalization = vocalization,
			let currentRange = vocalization.currentRange
			{
				return NSRange(
					location: currentRange.location + self.skipOffset,
					length: currentRange.length
				)
			} else {
				return nil
			}
		}
	}
	private var skipOffset : Int = 0
	
	
	@objc func progressDidChange()
	{
		NSNotificationCenter.defaultCenter().postNotificationName(Speech.ProgressChangedNotification, object: self)
	}
	
	private func speak(fromIndex index: Int)
	{
		if let vocalization = self.vocalization
		{
			vocalization.pause()
			self.vocalization = nil
		}
		
		var effectiveIndex = index
		
		if (effectiveIndex < 0)
		{
			effectiveIndex = 0
		}
		
		let vocalization : Vocalization
		let nsstring = NSString(string: self.text).substringFromIndex(effectiveIndex)
		
		vocalization = Vocalization( String(nsstring) )
		
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "progressDidChange", name: Vocalization.ProgressChangedNotification, object: vocalization)
		
		self.vocalization = vocalization
		self.skipOffset = index
		
		vocalization.start()
	}
	
	func playPause()
	{
		if let vocalization = vocalization
		{
			if vocalization.isSpeaking
			{
				self.pause()
			} else {
				self.play()
			}
		}
	}
	
	func pause()
	{
		if let vocalization = vocalization
		{
			if vocalization.isSpeaking
			{
				vocalization.pause()
			}
		}
	}
	
	func play()
	{
		if let vocalization = vocalization
		{
			if !vocalization.isSpeaking
			{
				if vocalization.didFinish
				{
					self.speak(fromIndex: 0)
				} else {
					vocalization.continueSpeaking()
				}
			}
		}
		
	}
	
	
	func skip(by boundary: Speech.Boundary, forward: Bool = true)
	{
		var options = boundary.enumerationOption
		let currentLocation = self.range?.location ?? 0
		
		if let vocalization = self.vocalization
		where forward && vocalization.didFinish
		{
			return
		}
		
		let range : NSRange
		var index : Int?
		var skip : Bool = true
		
		if forward
		{
			range = NSRange(location: currentLocation, length: self.text.characters.count - currentLocation)
		} else {
			options.unionInPlace(.Reverse)
			
			range = NSRange(location: 0, length: currentLocation)
		}
			
		NSString(string: self.text).enumerateSubstringsInRange(range, options: options, usingBlock: { (substring, substringRange, enclosingRange, stop) -> Void in
			guard let substring = substring
			where substring.characters.count > 0 else {
				return
			}
			
			if let _ = index
			{
				return
			}
			
			if skip
			{
				skip = false
				return
			}
			
			index = substringRange.location
		})
		
		if index == nil
		{
			if forward
			{
				index = self.text.characters.count - 1
			} else {
				index = 0
			}
		}
		
		if let index = index
		{
			self.speak(fromIndex: index)
		}
		
	}

	
}