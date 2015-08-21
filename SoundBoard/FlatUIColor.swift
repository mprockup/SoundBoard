//
//  FlatUIColor.swift
//
//  Created by Matthew Prockup on 8/6/15.
//  Copyright (c) 2015 Matthew Prockup. All rights reserved.
//

import Foundation
import UIKit

//  Translated from FlatUIColor.m
//  Created by Matthew Prockup on 5/20/14.
//  Copyright (c) 2014 Matthew Prockup. All rights reserved.
//

class FlatUIColor{
    
    class func turquoiseColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#1abc9c",alpha:alpha)
    }
    
    class func greenseaColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#16a085",alpha:alpha)
    }
    
    class func emerlandColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#2ecc71",alpha:alpha)
    }
    
    class func nephritisColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#27ae60",alpha:alpha)
    }
    
    class func peterriverColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#3498db",alpha:alpha)
    }
    
    class func belizeholeColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#2980b9",alpha:alpha)
    }
    
    class func amethystColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#9b59b6",alpha:alpha)
    }
    
    class func wisteriaColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#8e44ad",alpha:alpha)
    }
    
    class func wetasphaltColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#34495e",alpha:alpha)
    }
    
    class func midnightblueColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#2c3e50",alpha:alpha)
    }
    
    class func sunflowerColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#f1c40f",alpha:alpha)
    }
    
    class func orangeColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#f39c12",alpha:alpha)
    }
    
    class func carrotColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#e67e22",alpha:alpha)
    }
    
    class func pumpkinColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#d35400",alpha:alpha)
    }
    
    class func alizarinColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#e74c3c",alpha:alpha)
    }
    
    class func pomegranateColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#c0392b",alpha:alpha)
    }
    
    class func cloudsColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#ecf0f1",alpha:alpha)
    }
    
    class func silverColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#bdc3c7",alpha:alpha)
    }
    
    class func concreteColor(alpha:CGFloat=1.0)->UIColor{
        return colorFromHexString("#95a5a6",alpha:alpha)
    }
    
    class func asbestosColor(alpha:CGFloat = 1.0)->UIColor{
        return colorFromHexString("#7f8c8d",alpha:alpha)
    }
    class func fnwDarkColor(alpha:CGFloat = 1.0)->UIColor{
        return colorFromHexString("#2a2a64",alpha:alpha)
    }
    
    
    class func getAllColors()->[UIColor]{
        var colors:[UIColor] = [turquoiseColor(),
            greenseaColor(),
            emerlandColor(),
            nephritisColor(),
            peterriverColor(),
            belizeholeColor(),
            amethystColor(),
            wisteriaColor(),
            wetasphaltColor(),
            midnightblueColor(),
            sunflowerColor(),
            orangeColor(),
            carrotColor(),
            pumpkinColor(),
            alizarinColor(),
            pomegranateColor(),
            cloudsColor(),
            silverColor(),
            concreteColor(),
            asbestosColor()]
        
        return colors;
    }
    
    
    
    class func colorFromHexString(hexStr:String, alpha:CGFloat = 1.0) -> UIColor {
        // Check for hash and remove the hash
        
        var hex = hexStr
        if hex.hasPrefix("#") {
            hex = hex.substringFromIndex(advance(hex.startIndex, 1))
        }
        
        if (hex.rangeOfString("(^[0-9A-Fa-f]{6}$)|(^[0-9A-Fa-f]{3}$)", options: .RegularExpressionSearch) != nil) {
            
            // Deal with 3 character Hex strings
            if count(hex) == 3 {
                let redHex   = hex.substringToIndex(advance(hex.startIndex, 1))
                let greenHex = hex.substringWithRange(Range<String.Index>(start: advance(hex.startIndex, 1), end: advance(hex.startIndex, 2)))
                let blueHex  = hex.substringFromIndex(advance(hex.startIndex, 2))
                
                hex = redHex + redHex + greenHex + greenHex + blueHex + blueHex
            }
            
            let redHex = hex.substringToIndex(advance(hex.startIndex, 2))
            let greenHex = hex.substringWithRange(Range<String.Index>(start: advance(hex.startIndex, 2), end: advance(hex.startIndex, 4)))
            let blueHex = hex.substringWithRange(Range<String.Index>(start: advance(hex.startIndex, 4), end: advance(hex.startIndex, 6)))
            
            var redInt:   CUnsignedInt = 0
            var greenInt: CUnsignedInt = 0
            var blueInt:  CUnsignedInt = 0
            
            NSScanner(string: redHex).scanHexInt(&redInt)
            NSScanner(string: greenHex).scanHexInt(&greenInt)
            NSScanner(string: blueHex).scanHexInt(&blueInt)
            
            return UIColor(red: CGFloat(redInt) / 255.0, green: CGFloat(greenInt) / 255.0, blue: CGFloat(blueInt) / 255.0, alpha:alpha)
        }
        else{
            return UIColor.clearColor()
        }
    }
}
