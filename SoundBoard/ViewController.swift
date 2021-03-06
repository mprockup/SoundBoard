//
//  ViewController.swift
//  SoundBoard
//
//  Created by Matthew Prockup on 8/14/15.
//  Copyright (c) 2015 Matthew Prockup. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {

/////////////////////
// MARK: Setup
/////////////////////
    
    //Size of soundboard
    let rows:CGFloat = 4
    let cols:CGFloat = 4
    
    let textCellIdentifier = "TextCell"
    
    //popover for loading files
    var popOver:UIPopoverController!
    
    @IBOutlet weak var miniIcon: UIImageView!
    //popover for help menu
    var helpPopOver:UIPopoverController!
    
    //array for filepaths
    var fullPaths:NSMutableArray = [];
    
    //array for audio file names
    var fileNames:NSMutableArray=[];
    
    //list of all button keys
    var itemKeys:[String] = []
    
    // for use in callback of popover when loading samples
    var editingKey:String = ""
    
    // check if we are in edit mode
    var isEditMode = false
    
    //Device is muted
    var muted:Bool = false
    var muteValue:Float = 1.0 //not muted
    
    //help button
    @IBOutlet weak var helpButton: UIButton!
    var helpView:UIButton!
    
    //dictionary of button related objects for easy retrieval
    var samplesDict = [String:AVAudioPlayer]()          //dictionary of audio sample buffers
    var soundboardButtons = [String:UIButton]()         //buttons
    var soundboardSliders = [String:UISlider]()         //sampler volumes
    var isLooping = [String:Bool]()                     //Check if sample is looping
    var soundboardProgress = [String:UIProgressView]()  //Show Prog
    var typeSwitches = [String:UISwitch]()              //switches for stop/reint type
    var closeButtons = [String:UIButton]()              //buttons to remove sound
    
    //other UI elements
    var editSwitch:UISwitch = UISwitch()                //edit mode switche
    var muteButton:UIButton = UIButton()                //mute button
    var masterVolumeSlider:UISlider = UISlider()        //master volume slider
    
    
    //Values for VU meters
    var timer = NSTimer()
    var meterLeds1:[UIView] = []
    var meterLeds2:[UIView] = []
    var numLeds = 20
    let distortedRange = 0.8
    let warningRange = 0.6
    let ledOffAlpha:CGFloat = 0.3
    let min_dB:CGFloat = -30
    
/////////////////////
//MARK: View Setup
/////////////////////
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //prevent sleep
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        
        miniIcon.layer.cornerRadius = 10
        
        //Start AudioSession
        do{
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        }catch{
            print("Audio Shits Fucked")
        }
        
        //transfer audio from resources to documents folder
        transferAudio()
        
        //Make all UI Buttons
        makeButtons()
        
        //Create edit switch
        makeEditSwitch()
        
        //Create Mute button
        makeMuteButton()
        
        //Create VU meters
        makeVUMeters()
        
        //Create Main Volume slider
        makeMasterVolumeSlider()
        
        //hide button options
        hideSampleOptions(true)
        
        //set background to blue
        self.view.backgroundColor = FlatUIColor.midnightblueColor()
        
        //start timer for meter monitoring
        timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "updateContinousAnimations", userInfo: nil, repeats: true)
        
        //Create help overlay
        makeHelpView()
        
        //load last saved preset
        loadPreset()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
//////////////////////////////////////////
//MARK: Make View Components
//////////////////////////////////////////
    
    var width:CGFloat = 0
    var height:CGFloat = 0
    //Make all sample buttons
    func makeButtons(){
        
        width = self.view.frame.width/cols - 40.0
        height = self.view.frame.height/rows - 35.0
        
        var tagCnt = 0
        for r in 0..<Int(rows){
            let y = (height + 10) * CGFloat(r) + 30
            for c in 0..<Int(cols){
                let x = (width + 10) * CGFloat(c) + 20
                let tempButton:UIButton = UIButton(frame: CGRectMake(x, y, width, height))
                tempButton.backgroundColor = FlatUIColor.belizeholeColor(0.3)
                tempButton.addTarget(self, action: "soundButtonPressed:", forControlEvents: UIControlEvents.TouchDown)
                
                tempButton.addTarget(self, action: "soundButtonReleased:", forControlEvents: UIControlEvents.TouchUpInside)
                tempButton.addTarget(self, action: "soundButtonReleased:", forControlEvents: UIControlEvents.TouchUpOutside)
                
                let longTouchGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer()
                longTouchGesture.addTarget(self, action: "soundButtonHeld:")
                tempButton.addGestureRecognizer(longTouchGesture)
                

                tempButton.tag = tagCnt
                tempButton.layer.cornerRadius = 10
                let tempKey = "\(r)\(c)"
                itemKeys.append(tempKey)
                soundboardButtons[tempKey] = tempButton
                self.view.addSubview(soundboardButtons[tempKey]!)
                
                let tempSlider:UISlider = UISlider(frame: CGRectMake(x + 10, y + height-40, width-20, 30))
                tempSlider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.TouchUpInside)
                tempSlider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.TouchUpOutside)
                tempSlider.minimumValue = 0.001
                tempSlider.maximumValue = 1.2
                tempSlider.tag = tagCnt
                tempSlider.minimumTrackTintColor = FlatUIColor.peterriverColor()
                soundboardSliders[tempKey] = tempSlider
                self.view.addSubview(soundboardSliders[tempKey]!)
                
                let tempProgress:UIProgressView = UIProgressView(frame: CGRectMake(x + 10, y + height - 50, width-20, 30))
                tempProgress.tag = tagCnt
                tempProgress.hidden = true
                tempProgress.trackTintColor = UIColor.clearColor()
                soundboardProgress[tempKey] = tempProgress
                self.view.addSubview(soundboardProgress[tempKey]!)
                
                
                let tempSwitch:UISwitch = UISwitch()
                tempSwitch.frame = CGRectMake(x + width/2 - tempSwitch.frame.width/2, y + 30, width-20, 30)
                tempSwitch.tag = tagCnt
                tempSwitch.onTintColor = FlatUIColor.emerlandColor()
                typeSwitches[tempKey] = tempSwitch
                self.view.addSubview(typeSwitches[tempKey]!)
                
                
                let tempCloseButton:UIButton = UIButton(frame: CGRectMake(x + width-30, y + 10, 20, 20))
                tempCloseButton.tag = tagCnt
                tempCloseButton.backgroundColor = FlatUIColor.alizarinColor()
                tempCloseButton.layer.cornerRadius = 10
                tempCloseButton.addTarget(self, action: "closeButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
                closeButtons[tempKey] = tempCloseButton
                self.view.addSubview(closeButtons[tempKey]!)
                
                isLooping[tempKey] = false
                
                tagCnt++
            }
        }
    }
    
    //Create Mute Button
    func makeMuteButton(){
        muteButton = UIButton(frame: CGRectMake(1024-90, 30, 70, 70))
        muteButton.layer.cornerRadius = 10
        muteButton.backgroundColor = FlatUIColor.pomegranateColor(0.3)
        muteButton.setTitleColor(FlatUIColor.cloudsColor(0.3), forState: UIControlState.Normal)
        muteButton.setTitle("mute", forState: UIControlState.Normal)
        muteButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        muteButton.addTarget(self, action: "mutePressed:", forControlEvents: UIControlEvents.TouchDown)
        self.view.addSubview(muteButton)
    }
    
    func makeMasterVolumeSlider(){
        masterVolumeSlider.frame = CGRectMake(1024/2 + 200, 768/2 + 10, 1024/2, 30)
        masterVolumeSlider.minimumValue = 0.001
        masterVolumeSlider.maximumValue = 1.2
        masterVolumeSlider.tag = 1000
        masterVolumeSlider.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        masterVolumeSlider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.TouchUpInside)
        masterVolumeSlider.addTarget(self, action: "sliderChanged:", forControlEvents: UIControlEvents.TouchUpOutside)
        masterVolumeSlider.minimumTrackTintColor = FlatUIColor.peterriverColor()
        self.view.addSubview(masterVolumeSlider)
    }
    
    func makeEditSwitch(){
        editSwitch = UISwitch(frame: CGRectMake(1024-80, self.view.frame.height-60, 70, 40))
        editSwitch.on = false
        editSwitch.addTarget(self, action: "editSwitchChanged:", forControlEvents: UIControlEvents.ValueChanged)
        editSwitch.onTintColor = FlatUIColor.emerlandColor()
        self.view.addSubview(editSwitch)
    }
    
    //Create the VUMeters view
    var meter:UIView!
    func makeVUMeters(){
        let distortedNum = Double(numLeds) * distortedRange
        let warningNum = Double(numLeds) * warningRange
        
        //Make it match volume Slider
        let x:CGFloat = 1024/2 + 200
        let y:CGFloat = 768/2 + 10 - 10
        let w:CGFloat = 1024/2
        let h:CGFloat = 50
        let rect = CGRectMake(x,y,w,h)
        meter = UIView(frame: rect)
        
        //create leds
        for i in 0..<numLeds{
            let rect1 = CGRectMake(CGFloat(i) * w/CGFloat(numLeds), 0, h/3.0, h/3.0)
            let rect2 = CGRectMake(CGFloat(i) * w/CGFloat(numLeds), h/3.0 * 2.0, h/3.0, h/3.0)
            
            let meterLed1:UIView = UIView(frame: rect1)
            meterLed1.backgroundColor = UIColor.blackColor()
            meterLed1.layer.cornerRadius = h/3/2
            meterLed1.alpha = ledOffAlpha
            
            let meterLed2:UIView = UIView(frame: rect2)
            meterLed2.backgroundColor = UIColor.blackColor()
            meterLed2.layer.cornerRadius = h/3/2
            meterLed2.alpha = ledOffAlpha
            
            if(i > Int(distortedNum)) {
                meterLed1.backgroundColor = FlatUIColor.alizarinColor()
                meterLed2.backgroundColor = FlatUIColor.alizarinColor()
            }
            else if (i > Int(warningNum)){
                meterLed1.backgroundColor = FlatUIColor.sunflowerColor()
                meterLed2.backgroundColor = FlatUIColor.sunflowerColor()
            }
            else{
                meterLed1.backgroundColor = FlatUIColor.emerlandColor()
                meterLed2.backgroundColor = FlatUIColor.emerlandColor()
            }
            
            meter.addSubview(meterLed1)
            meter.addSubview(meterLed2)
            meterLeds1.append(meterLed1)
            meterLeds2.append(meterLed2)
        }
        meter.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        meter.backgroundColor = UIColor.clearColor()
        self.view.addSubview(meter)
    }
    
    func makeHelpView(){
        helpButton.setTitleColor(FlatUIColor.cloudsColor(0.7), forState: UIControlState.Normal)
        helpButton.layer.cornerRadius = 10
        helpButton.backgroundColor = FlatUIColor.pomegranateColor(0.6)
        helpView = UIButton(frame: CGRectMake(0, 0, self.view.frame.width-100, self.view.frame.height))
        helpView.backgroundColor = FlatUIColor.midnightblueColor()
        helpView.addTarget(self, action: "removeHelp:", forControlEvents: UIControlEvents.TouchDown)
        
        var x = (width + 10) * CGFloat(0) + 20
        var y = (height + 10) * CGFloat(0) + 30
        let performanceLabel = UILabel(frame: CGRectMake(x, y, width*3, height/2))
        performanceLabel.textColor = UIColor.whiteColor()
        performanceLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 46)
        performanceLabel.textAlignment = NSTextAlignment.Left
        performanceLabel.text = "Performance Mode"
        helpView.addSubview(performanceLabel)
        
        x = (width + 10) * CGFloat(3) + 20
        y = (height + 10) * CGFloat(0) + 30
        let muteLabel = UILabel(frame: CGRectMake(x, y, width, height/2))
        muteLabel.textColor = UIColor.whiteColor()
        muteLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 24)
        muteLabel.textAlignment = NSTextAlignment.Right
        muteLabel.text = "Mute all sound."
        helpView.addSubview(muteLabel)
        
        x = (width + 10) * CGFloat(3) + 20
        y = (height + 10) * CGFloat(4) + 15
        let editModeLabel = UILabel(frame: CGRectMake(x, y, width, height/2))
        editModeLabel.textColor = UIColor.whiteColor()
        editModeLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 24)
        editModeLabel.textAlignment = NSTextAlignment.Right
        editModeLabel.text = "Edit Mode"
        helpView.addSubview(editModeLabel)
        
        x = (width + 10) * CGFloat(3) + 20
        y = (height + 10) * CGFloat(3) + 30
        let masterVolLabel = UILabel(frame: CGRectMake(x, y, width, height/2))
        masterVolLabel.textColor = UIColor.whiteColor()
        masterVolLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 24)
        masterVolLabel.textAlignment = NSTextAlignment.Right
        masterVolLabel.text = "Master Volume"
        helpView.addSubview(masterVolLabel)
        
        
        x = (width + 10) * CGFloat(0) + 20
        y = (height + 10) * CGFloat(0.5) + 30
        let emptyLabel = UILabel(frame: CGRectMake(x, y, width, height/2))
        emptyLabel.textColor = UIColor.whiteColor()
        emptyLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 24)
        emptyLabel.textAlignment = NSTextAlignment.Center
        emptyLabel.text = "Empty Button"
        helpView.addSubview(emptyLabel)
        
        x = (width + 10) * CGFloat(0) + 20
        y = (height + 10) * CGFloat(1) + 30
        let sampleEmptyButton:UIButton = UIButton(frame: CGRectMake(x, y, width, height))
        sampleEmptyButton.backgroundColor = FlatUIColor.belizeholeColor(0.3)
        sampleEmptyButton.layer.cornerRadius = 10
        helpView.addSubview(sampleEmptyButton)
        
        
        x = (width + 10) * CGFloat(1) + 20
        y = (height + 10) * CGFloat(0.5) + 30
        let loadedLabel = UILabel(frame: CGRectMake(x, y, width, height/2))
        loadedLabel.textColor = UIColor.whiteColor()
        loadedLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 24)
        loadedLabel.textAlignment = NSTextAlignment.Center
        loadedLabel.text = "Sample Loaded"
        helpView.addSubview(loadedLabel)
        
        x = (width + 10) * CGFloat(1) + 20
        y = (height + 10) * CGFloat(1) + 30
        let sampleLoadedButton:UIButton = UIButton(frame: CGRectMake(x, y, width, height))
        sampleLoadedButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        sampleLoadedButton.backgroundColor = FlatUIColor.nephritisColor(0.3)
        sampleLoadedButton.layer.cornerRadius = 10
        sampleLoadedButton.setTitle("Sample.wav", forState: UIControlState.Normal)
        helpView.addSubview(sampleLoadedButton)

        x = (width + 10) * CGFloat(2) + 20
        y = (height + 10) * CGFloat(0.5) + 30
        let playLabel = UILabel(frame: CGRectMake(x, y, width, height/2))
        playLabel.textColor = UIColor.whiteColor()
        playLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 24)
        playLabel.textAlignment = NSTextAlignment.Center
        playLabel.text = "Tap to play."
        helpView.addSubview(playLabel)
        
        x = (width + 10) * CGFloat(2) + 20
        y = (height + 10) * CGFloat(1) + 30
        let tapToPlayButton:UIButton = UIButton(frame: CGRectMake(x, y, width, height))
        tapToPlayButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        tapToPlayButton.backgroundColor = FlatUIColor.nephritisColor()
        tapToPlayButton.layer.cornerRadius = 10
        tapToPlayButton.setTitle("Sample.wav", forState: UIControlState.Normal)
        helpView.addSubview(tapToPlayButton)

        x = (width + 10) * CGFloat(3) + 20
        y = (height + 10) * CGFloat(0.5) + 30
        let loopLabel = UILabel(frame: CGRectMake(x, y, width, height/2))
        loopLabel.textColor = UIColor.whiteColor()
        loopLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 24)
        loopLabel.textAlignment = NSTextAlignment.Center
        loopLabel.text = "Long tap to loop."
        helpView.addSubview(loopLabel)
        
        x = (width + 10) * CGFloat(3) + 20
        y = (height + 10) * CGFloat(1) + 30
        let tapHoldToLoopButton:UIButton = UIButton(frame: CGRectMake(x, y, width, height))
        tapHoldToLoopButton.backgroundColor = FlatUIColor.sunflowerColor()
        tapHoldToLoopButton.layer.cornerRadius = 10
        tapHoldToLoopButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        tapHoldToLoopButton.setTitle("Loop.wav", forState: UIControlState.Normal)
        helpView.addSubview(tapHoldToLoopButton)
        
        x = (width + 10) * CGFloat(0) + 20
        y = (height + 10) * CGFloat(2) + 30
        let editLabel = UILabel(frame: CGRectMake(x, y, width*2, height/2))
        editLabel.textColor = UIColor.whiteColor()
        editLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 46)
        editLabel.textAlignment = NSTextAlignment.Left
        editLabel.text = "Edit Mode"
        helpView.addSubview(editLabel)
        
        let vertShift:CGFloat = 50
        x = (width + 10) * CGFloat(0) + 20
        y = (height + 10) * CGFloat(3) + 30 - vertShift
        let editButton:UIButton = UIButton(frame: CGRectMake(x, y, width, height))
        editButton.backgroundColor = FlatUIColor.nephritisColor(0.3)
        editButton.layer.cornerRadius = 10
        editButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        editButton.setTitle("Sample.wav", forState: UIControlState.Normal)
        helpView.addSubview(editButton)
        let tempSlider:UISlider = UISlider(frame: CGRectMake(x + 10, y + height-40, width-20, 30))
        tempSlider.minimumValue = 0.001
        tempSlider.maximumValue = 1.2
        tempSlider.value = 0.6
        tempSlider.minimumTrackTintColor = FlatUIColor.peterriverColor()
        helpView.addSubview(tempSlider)
        let tempSwitch:UISwitch = UISwitch()
        tempSwitch.frame = CGRectMake(x + width/2 - tempSwitch.frame.width/2, y + 30, width-20, 30)
        tempSwitch.onTintColor = FlatUIColor.emerlandColor()
        helpView.addSubview(tempSwitch)
        let tempCloseButton:UIButton = UIButton(frame: CGRectMake(x + width-30, y + 10, 20, 20))
        tempCloseButton.backgroundColor = FlatUIColor.alizarinColor()
        tempCloseButton.layer.cornerRadius = 10
        helpView.addSubview(tempCloseButton)
        
        
        x = (width + 10) * CGFloat(1) + 20
        y = (height + 10) * CGFloat(2.6) + 30 - vertShift
        let clearLabel = UILabel(frame: CGRectMake(x, y, width, height/2))
        clearLabel.textColor = FlatUIColor.alizarinColor()
        clearLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 24)
        clearLabel.textAlignment = NSTextAlignment.Left
        clearLabel.text = "Clear Sample"
        helpView.addSubview(clearLabel)
        
        x = (width + 10) * CGFloat(0) + 20
        y = (height + 10) * CGFloat(3.85) + 30 - vertShift
        let volumeLabel = UILabel(frame: CGRectMake(x, y, width, height/2))
        volumeLabel.textColor = FlatUIColor.peterriverColor()
        volumeLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 24)
        volumeLabel.textAlignment = NSTextAlignment.Center
        volumeLabel.text = "Adjust Volume"
        helpView.addSubview(volumeLabel)
        
        x = (width + 10) * CGFloat(1) + 20
        y = (height + 10) * CGFloat(3) + 30 - vertShift
        let stopModeLabel = UILabel(frame: CGRectMake(x, y, width, height))
        stopModeLabel.textColor = FlatUIColor.emerlandColor()
        stopModeLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 24)
        stopModeLabel.textAlignment = NSTextAlignment.Left
        stopModeLabel.text = "Switch for kill mode.\nOFF: Retrigger samples. Wait for loops finish.\nON: Stop sample."
        stopModeLabel.numberOfLines = 5
        helpView.addSubview(stopModeLabel)
        
        x = (width + 10) * CGFloat(0) + 20
        y = (height + 10) * CGFloat(2.6) + 30 - vertShift
        let editLoadLabel = UILabel(frame: CGRectMake(x, y, width, height/2))
        editLoadLabel.textColor = UIColor.whiteColor()
        editLoadLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 24)
        editLoadLabel.textAlignment = NSTextAlignment.Left
        editLoadLabel.text = "Tap pad to load."
        helpView.addSubview(editLoadLabel)
        
        
        x = (width + 10) * CGFloat(2) + 60
        y = (height + 10) * CGFloat(2) + 30
        let addSamplesLabel = UILabel(frame: CGRectMake(x, y, width*2, height/2))
        addSamplesLabel.textColor = UIColor.whiteColor()
        addSamplesLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 46)
        addSamplesLabel.textAlignment = NSTextAlignment.Left
        addSamplesLabel.text = "Add Files"
        helpView.addSubview(addSamplesLabel)
        
        
        x = (width + 10) * CGFloat(2) + 60
        y = (height + 10) * CGFloat(2.4) + 40
        let addSamplesLabel2 = UILabel(frame: CGRectMake(x, y, width, height*1.5+10))
        addSamplesLabel2.textColor = UIColor.whiteColor()
        addSamplesLabel2.font = UIFont(name: "HelveticaNeue-Thin", size: 16)
        addSamplesLabel2.textAlignment = NSTextAlignment.Left
        addSamplesLabel2.text = "Plug the iPad into the computer and open iTunes.\n\nClick the iPad icon on the top and select 'Apps' on the left.\n\nScroll down to 'File Sharing' and select 'EasySampler'. Drag any audio file you wish.\n\nThey will appear in the list of files to add once you restart the app."
        addSamplesLabel2.numberOfLines = 12
        helpView.addSubview(addSamplesLabel2)
        

        let helpCloseFrame = CGRectMake(self.view.frame.width/2-helpButton.frame.width/2, self.view.frame.height-65, helpButton.frame.width, helpButton.frame.height)
        let helpButton2:UIButton = UIButton(frame:helpCloseFrame)
        helpButton2.setTitleColor(FlatUIColor.cloudsColor(0.7), forState: UIControlState.Normal)
        helpButton2.layer.cornerRadius = 10
        helpButton2.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        helpButton2.backgroundColor = FlatUIColor.pomegranateColor(0.6)
        helpButton2.setTitle("Exit", forState: UIControlState.Normal)
        helpButton2.addTarget(self, action: "removeHelp:", forControlEvents: UIControlEvents.TouchDown)
        helpView.addSubview(helpButton2)
        
        
        x = (width + 10) * CGFloat(0) + 20
        y = (height + 10) * CGFloat(4) + 15 + 10
        let signLabel = UITextView(frame: CGRectMake(x, y, width*2, height/3))
        signLabel.textColor = UIColor.whiteColor()
        signLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 15)
        signLabel.textAlignment = NSTextAlignment.Left
        signLabel.text = "Copyright © 2016 Matthew Prockup. All rights reserved.\nLearn More: www.mattprockup.com"
        signLabel.editable = false
        signLabel.dataDetectorTypes = UIDataDetectorTypes.All
        signLabel.backgroundColor = UIColor.clearColor()
        helpView.addSubview(signLabel)
    }

    
//////////////////////////////////////////
//MARK: Edit View Components
//////////////////////////////////////////
    
    //Show hide all options for each sampler
    func hideSampleOptions(hidden:Bool){
        hideSliders(hidden)
        hideSwitches(hidden)
        hideCloseButtons(hidden)
    }
    
    func hideSliders(hidden:Bool){
        for ( _ , value) in  soundboardSliders {
            value.hidden = hidden
        }
    }
    
    func hideSwitches(hidden:Bool){
        for ( _ , value) in  typeSwitches {
            value.hidden = hidden
        }
    }
    
    func hideCloseButtons(hidden:Bool){
        for ( _ , value) in  closeButtons {
            value.hidden = hidden
        }
    }
    
    func setLoopingColor(key:String){
        soundboardButtons[key]?.backgroundColor = FlatUIColor.sunflowerColor(0.7);
    }
    
    func setStandardColor(key:String){
        soundboardButtons[key]?.backgroundColor = FlatUIColor.nephritisColor(0.3);
    }
    
/////////////////////
//MARK: Respond to Events
/////////////////////
    
    // Mute button pressed callback
    func mutePressed(sender:UIButton){
        if muted{
            muted = false
            muteButton.backgroundColor = FlatUIColor.pomegranateColor(0.3)
            muteButton.setTitleColor(FlatUIColor.cloudsColor(0.3), forState: UIControlState.Normal)
            muteValue = 1
            updateAllVolumes()
        }
        else{
            muted = true
            muteButton.backgroundColor = FlatUIColor.pomegranateColor(1.0)
            muteButton.setTitleColor(FlatUIColor.cloudsColor(1.0), forState: UIControlState.Normal)
            muteValue = 0
            updateAllVolumes()
        }
    }
    
    //Edit swich chaned callback
    func editSwitchChanged(sender:UISwitch){
        if sender.on{
            isEditMode = true
            hideSampleOptions(false)
        }
        else{
            isEditMode = false
            hideSampleOptions(true)
            savePreset()
        }
    }
    
    //slider was touched callback
    //Master Slider
    func sliderChanged(sender:UISlider){
        
        if(sender.tag==1000){
            updateAllVolumes()
        }
        else{ //Other sliders
            let key:String = itemKeys[sender.tag]
            if samplesDict[key] != nil {
                samplesDict[key]?.volume = (soundboardSliders[key]?.value)! * masterVolumeSlider.value * muteValue
            }
        }
        savePreset()
    }
    
    func updateAllVolumes(){
        for (k,_) in samplesDict{
            samplesDict[k]?.volume = (soundboardSliders[k]?.value)! * masterVolumeSlider.value * muteValue
        }
    }
    
    
    //respond to a pressed button
    func soundButtonPressed(sender:UIButton){
        let key:String = itemKeys[sender.tag]
        
        if(isEditMode){
            editingKey = key
            //create load file popover
            let popW:CGFloat = 250;
            let popH:CGFloat = 400;
            let popOverContent:UIViewController = UIViewController()
            let popOverView:UIView = UIView()
            popOverView.backgroundColor = FlatUIColor.wetasphaltColor()
            let tableViewFiles:UITableView = UITableView(frame: CGRectMake(0,0,popW,popH))
            tableViewFiles.backgroundColor = FlatUIColor.wetasphaltColor()
            tableViewFiles.rowHeight = 40
        
            popOverView.addSubview(tableViewFiles)
            
            popOverContent.view = popOverView
            popOverContent.preferredContentSize = CGSizeMake(popW, popH)
            self.popOver = UIPopoverController(contentViewController: popOverContent)
            
            tableViewFiles.delegate = self
            tableViewFiles.dataSource = self
            
            let tempFrame = CGRectMake(sender.frame.origin.x + sender.frame.width/2, sender.frame.origin.y+sender.frame.height/2, 1, 1)
            
            self.popOver.presentPopoverFromRect(tempFrame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
        }
        else{
            
            if(isLooping[key] == true){
                samplesDict[key]?.numberOfLoops = 0
                isLooping[key] = false
                setStandardColor(key)
                if (typeSwitches[key]!.on == true) && (samplesDict[key]?.playing == true){
                    samplesDict[key]?.stop()
                }
            }
            else{
                
                if (typeSwitches[key]!.on == true) && (samplesDict[key]?.playing == true){
                    samplesDict[key]?.stop()
                }
                else{
                    print("Play Pressed: \(sender.titleLabel?.text as String!), KEY: \(key), VOLUME: \(soundboardSliders[key]!.value as Float)")
                    self.play(key)
                }
                
            }
        }
        
        
    }
    
    func soundButtonReleased(sender:UIButton){
        
        let senderTag:Int = sender.tag
        let senderKey = itemKeys[senderTag]
        if isLooping[senderKey] == false{
            samplesDict[senderKey]?.numberOfLoops = 0
        }
    }
    
    func soundButtonHeld(sender:UILongPressGestureRecognizer){
        if isEditMode==false{
            if sender.state == UIGestureRecognizerState.Began{
                let senderTag:Int = sender.view!.tag
                let senderKey = itemKeys[senderTag]
                print("registered long press. Sender Key: \(senderTag)  Tag: \(senderKey)" )
                if samplesDict[senderKey] != nil{
                    samplesDict[senderKey]?.numberOfLoops = -1
                    isLooping[senderKey] = true
                    setLoopingColor(senderKey)
                }
            }
            else{
                print("ended long press")
            }
        }
    }
    
    func closeButtonPressed(sender:UIButton){
        let senderTag:Int = sender.tag
        let key = itemKeys[senderTag]
        samplesDict.removeValueForKey(key)
        soundboardButtons[key]?.backgroundColor = FlatUIColor.belizeholeColor(0.3)
        soundboardButtons[key]?.setTitle("", forState: UIControlState.Normal)
        savePreset()
    }
    
    
    
    //show help overlay
    @IBAction func helpPressed(sender: AnyObject) {
        self.view.addSubview(helpView)
    }
    
    //make help go away
    func removeHelp(sender: AnyObject){
        helpView.removeFromSuperview()
    }
    
/////////////////////
//MARK: Audio File Loading and Playback
/////////////////////
    
    //load an audio file to respond to a keypress
    func loadFile(key:String,filePathToLoad:String){
        let intKey:Int = Int(key)!
        let keyR:CGFloat = CGFloat(Int(intKey/10))
        let keyC:CGFloat = CGFloat(intKey%10)
        
        if (keyR < rows) && (keyC < cols){
            
            print("Loading: R:\(keyR) C:\(keyC) with \(filePathToLoad)")
            //create audio path url
            let audioURL:NSURL = NSURL(fileURLWithPath: filePathToLoad)
            
            //create audio player and load file
            var audioPlayer = AVAudioPlayer()
            do{
                try audioPlayer = AVAudioPlayer(contentsOfURL: audioURL)
            }catch{
                print("audio player load file error")
            }
            audioPlayer.meteringEnabled = true
            audioPlayer.prepareToPlay()
            
            //load into samples dictionary
            samplesDict[key] = audioPlayer
            
            //put filename on preview button
            var fileNameComponents = filePathToLoad.componentsSeparatedByString("/")
            self.soundboardButtons[key]?.setTitle(fileNameComponents[fileNameComponents.count - 1], forState: UIControlState.Normal)
            self.soundboardButtons[key]?.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 20)
            soundboardButtons[key]?.backgroundColor = FlatUIColor.nephritisColor(0.3)

        }
        else{
            print("Ignoring OutOfRange: R:\(keyR) C:\(keyC) for \(filePathToLoad)")
        }
        
        
    }

    func transferAudio(){
        //copy audio from resources into docs folder so theres something there from the start
        let documentsPath:String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString as String
        let snareFile:String = NSBundle.mainBundle().pathForResource("Snare", ofType: "wav")!
        let kickFile:String = NSBundle.mainBundle().pathForResource("Kick", ofType: "wav")!
        let hihatFile:String = NSBundle.mainBundle().pathForResource("HiHat", ofType: "wav")!
        let crashFile:String = NSBundle.mainBundle().pathForResource("Crash", ofType: "wav")!
        
        do{
            try NSFileManager.defaultManager().copyItemAtPath(snareFile, toPath: (documentsPath as String + "/Snare.wav"))
            try NSFileManager.defaultManager().copyItemAtPath(kickFile, toPath:(documentsPath as String + "/Kick.wav"))
            try NSFileManager.defaultManager().copyItemAtPath(hihatFile, toPath: (documentsPath as String + "/HiHat.wav"))
            try NSFileManager.defaultManager().copyItemAtPath(crashFile, toPath: (documentsPath as String + "/Crash.wav"))
        }catch{
            print("Error copying files")
        }
        
        //get List of wave files in docs dir to display in popover
        var directoryContent:[String] = []
        do{
            directoryContent = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(documentsPath as String)
        }catch{
            print("Error getting directory content")
        }
        var cnt = 0
        for var i = 0; i < directoryContent.count; ++i {
            
            let fp = "\(documentsPath)/\((directoryContent )[i])"
            let filename = "\((directoryContent as [String])[i])"
            let components:NSArray = filename.componentsSeparatedByString(".")
            let suffix:String = components[components.count-1] as! String
            
            //make sure its an audio file supported
            if suffix == "wav" || suffix=="mp3" || suffix=="aiff" || suffix=="m4a"{
                ++cnt
                print("\(cnt) : \(documentsPath)/\((directoryContent as [String])[i])")
                fullPaths.addObject(fp)
                fileNames.addObject(filename)
            }
        }
        
    }

    //Play back a sound at a volume
    func play(key:String, volume:Float=(-1.0)){
        //check if sample is loaded
        
        if samplesDict[key] != nil {
            if volume == -1.0{
                if muted{
                    samplesDict[key]!.volume = 0
                }
                else{
                    samplesDict[key]?.volume=(soundboardSliders[key]?.value)! * masterVolumeSlider.value
                }
            }
            else{
                if muted{
                    samplesDict[key]!.volume = 0
                }
                else{
                    samplesDict[key]?.volume=volume                }
                
            }
            
            //reset to time 0 and play sample
            samplesDict[key]?.currentTime=0
            
            samplesDict[key]?.numberOfLoops = -1
            samplesDict[key]?.play()
            
            soundboardButtons[key]?.backgroundColor = UIColor.greenColor()
            soundboardButtons[key]?.backgroundColor = FlatUIColor.nephritisColor(1.0)
            UIView.animateWithDuration(1.0, delay: 0.0, options: [UIViewAnimationOptions.CurveLinear, UIViewAnimationOptions.AllowUserInteraction], animations: {
                self.soundboardButtons[key]?.backgroundColor = FlatUIColor.nephritisColor(0.3)
                }, completion: { finished in
                    
            })
        }
    }
    
/////////////////////
//MARK: Presets
/////////////////////

    //Save presets "key:soundfile.type\nkey2:soundfile2.type "
    func savePreset(){
        var saveStr:String = ""
        for (key, value) in samplesDict {
            
            var switchString:String = "OFF"
            if typeSwitches[key]!.on == true{
                switchString = "ON"
            }
            var filePath = ("\((value as AVAudioPlayer).url!.path as String!)").componentsSeparatedByString("/")
            let fileName = filePath[filePath.count - 1]
            saveStr += "\(key):\(fileName):\(soundboardSliders[key]!.value as Float):\(switchString)\n"
        }
        
        saveStr += "MAIN:\(masterVolumeSlider.value as Float)\n"
        
        print(saveStr)
        
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        do{
           try saveStr.writeToFile((documentsPath as String) + "/" + "savedPreset.txt", atomically: true, encoding: NSUTF8StringEncoding)
        }catch{
            print("Error Saving Presets")
        }
        
    }

    //load presets
    func loadPreset(){
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        let filePathString:String = (documentsPath as String) + "/" + "savedPreset.txt"
        let checkValidation = NSFileManager.defaultManager()
        if (checkValidation.fileExistsAtPath(filePathString)){
            var loadStr:String = ""
            do{
                loadStr = try String(contentsOfFile:filePathString , encoding: NSUTF8StringEncoding)
            }catch{
                print("Error Loading Presets file")
            }
            
            print("LOADING: \n\(loadStr)")
            let filesList = loadStr.componentsSeparatedByString("\n")
            for f in filesList{
                if f != "" {
                    var fileComponents = (f as String).componentsSeparatedByString(":")
                    let key:String = fileComponents[0]
                    if key == "MAIN"{
                        let volume:Float = (fileComponents[1] as NSString).floatValue
                        self.masterVolumeSlider.value = volume
                    }
                    else{
                        var fileName:String = fileComponents[1]
                        let volume:Float = (fileComponents[2] as NSString).floatValue
                        
                        fileName = (documentsPath as String) + "/" + fileName
                        self.loadFile(key, filePathToLoad: fileName)
                        self.soundboardSliders[key]?.value = volume as Float
                        
                        if fileComponents.count > 3{
                            let switchString:String = fileComponents[3]
                            if switchString == "ON"{
                                self.typeSwitches[key]!.on = true
                            }
                            else{
                                self.typeSwitches[key]!.on = false
                            }
                        }
                        else{
                            self.typeSwitches[key]!.on = false
                        }
                    }
                }
            }
        }
    }
    
//////////////////////////////////////////
//MARK: Load Sound TableView Setup
//////////////////////////////////////////
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fileNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .Default, reuseIdentifier: "UITableViewCell")
            
        //make cell text the name of the file
        cell.textLabel?.text = self.fileNames.objectAtIndex(indexPath.row) as? String
        
        //make the cell match the UI design
        cell.textLabel?.textColor = FlatUIColor.cloudsColor()
        cell.backgroundColor = FlatUIColor.wetasphaltColor()
        cell.textLabel?.font = UIFont(name: "Melno", size: CGFloat(22))
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Selected: \(indexPath.row)")
        
       // load the file selected to a key row
            print("File Selected: \(fileNames.objectAtIndex(indexPath.row))")
            popOver.dismissPopoverAnimated(true)
            loadFile(editingKey, filePathToLoad: fullPaths.objectAtIndex(indexPath.row) as! String)
    }
    
    func updateContinousAnimations(){
        meterUpdate()
        progressUpdate()
    }
    
    func meterUpdate(){
        var ch1Vals:[Float] = []
        var ch2Vals:[Float] = []
        for (key, value) in  samplesDict {
            value.updateMeters()
            let numCh = value.numberOfChannels
            
            //Add them to list and remove dB
            if numCh>1{
                ch1Vals.append(powf(10,value.averagePowerForChannel(0)/10.0)*soundboardSliders[key]!.value)
                ch2Vals.append(powf(10,value.averagePowerForChannel(1)/10.0)*soundboardSliders[key]!.value)
            }
            else{
                ch1Vals.append(powf(10,value.averagePowerForChannel(0)/10.0)*soundboardSliders[key]!.value)
                ch2Vals.append(powf(10,value.averagePowerForChannel(0)/10.0)*soundboardSliders[key]!.value)
            }
        }
        
        var ch1Tot:Float = 0
        var ch2Tot:Float = 0
        for i in 0..<ch1Vals.count{
            ch1Tot += ch1Vals[i]
            ch2Tot += ch2Vals[i]
        }
        
        ch1Tot = 10.0 * log10(ch1Tot*masterVolumeSlider.value)
        ch2Tot = 10.0 * log10(ch2Tot*masterVolumeSlider.value)
        showMeters(ch1Tot, ch2: ch2Tot)
    }
    
    //show meter reading in view
    func showMeters(ch1:Float,ch2:Float){
        for light in meterLeds1{
            light.alpha = ledOffAlpha
        }
        for light in meterLeds2{
            light.alpha = ledOffAlpha
        }
        
        //loop throgh normalized linear input, stop if it is out of bounds
        var meter1Pos = getMeterPos(ch1)
        var meter2Pos = getMeterPos(ch2)
        if(meter1Pos>0){
            if(meter1Pos > meterLeds1.count - 1){
                meter1Pos = meterLeds1.count - 1
            }
            for i in 0...meter1Pos{
                meterLeds1[i].alpha = 1.0
            }
        }
        
        if(meter2Pos>0){
            if(meter2Pos > meterLeds2.count - 1){
                meter2Pos = meterLeds2.count - 1
            }
        
            for i in 0...meter2Pos{
                meterLeds2[i].alpha = 1.0
            }
        }
    }
    
    func getMeterPos(db:Float)->Int{
        if db > -1000{
            let distortedNum = CGFloat(numLeds) * CGFloat(distortedRange)
            let quantSpace:CGFloat = -min_dB/distortedNum
            return Int(round((-min_dB + CGFloat(db))/quantSpace))
        }
        else{
            return 0;
        }
    }
    
    //Update Progress Meters
    func progressUpdate(){
        for (k,v) in samplesDict{
            if(v.playing){
                soundboardProgress[k]?.hidden = false
                soundboardProgress[k]?.progress = Float(v.currentTime/v.duration)
                if isLooping[k]==true{
                    soundboardProgress[k]?.progressTintColor = FlatUIColor.sunflowerColor()
                }
                else{
                    soundboardProgress[k]?.progressTintColor = FlatUIColor.emerlandColor()
                }
            }
            else{
                soundboardProgress[k]?.hidden=true;
            }
        }
    }
}

