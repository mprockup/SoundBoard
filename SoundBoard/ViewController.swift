//
//  ViewController.swift
//  SoundBoard
//
//  Created by Matthew Prockup on 8/14/15.
//  Copyright (c) 2015 Matthew Prockup. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {

    
    let textCellIdentifier = "TextCell"
    
    //popover for loading files
    var popOver:UIPopoverController!
    
    //popover for help menu
    var helpPopOver:UIPopoverController!
    
    //array for filepaths
    var fullPaths:NSMutableArray = [];
    
    //array for audio file names
    var fileNames:NSMutableArray=[];
    
    
    //dictionary of audio sample buffers for easy retrieval
    var samplesDict = [String:AVAudioPlayer]()
    
    
    var itemKeys:[String] = []
    
    var editingKey:String = ""
    
    //dict of soundboardButtons based keyed on key events
    var soundboardButtons = [String:UIButton]()
    var soundboardSliders = [String:UISlider]()
    var editSwitch:UISwitch = UISwitch()
    var masterVolumeSlider:UISlider = UISlider()
    var isEditMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //Start AudioSession
        AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, error: nil)
        AVAudioSession.sharedInstance().setActive(true, error: nil)
        transferAudio()
        makeButtons()
        
        editSwitch = UISwitch(frame: CGRectMake(1024-80, self.view.frame.height-60, 60, 40))
        editSwitch.on = false
        editSwitch.addTarget(self, action: "editSwitchChanged:", forControlEvents: UIControlEvents.ValueChanged)
        self.view.addSubview(editSwitch)
        
        masterVolumeSlider.frame = CGRectMake(1024/2 + 200, 768/2, 1024/2, 30)
        masterVolumeSlider.transform = CGAffineTransformMakeRotation(CGFloat(-M_PI_2))
        self.view.addSubview(masterVolumeSlider)
        
        
        
        hideSliders(true)
        
        
        self.view.backgroundColor = FlatUIColor.midnightblueColor()
        
        loadPreset()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func makeButtons(){
        var rows:CGFloat = 3
        var cols:CGFloat = 4
        
        var width = self.view.frame.width/cols - 40.0
        var height = self.view.frame.height/rows - 40.0
        var tagCnt = 0
        for r in 0..<Int(rows){
            var y = (height + 10) * CGFloat(r) + 30
            for c in 0..<Int(cols){
                var x = (width + 10) * CGFloat(c) + 20
                var tempButton:UIButton = UIButton(frame: CGRectMake(x, y, width, height))
                tempButton.backgroundColor = FlatUIColor.belizeholeColor(alpha: 0.3)
                tempButton.addTarget(self, action: "soundButtonPressed:", forControlEvents: UIControlEvents.TouchDown)
                tempButton.tag = tagCnt
                tempButton.layer.cornerRadius = 10
                let tempKey = "\(r)\(c)"
                itemKeys.append(tempKey)
                soundboardButtons[tempKey] = tempButton
                
                self.view.addSubview(soundboardButtons[tempKey]!)
                
                var tempSlider:UISlider = UISlider(frame: CGRectMake(x + 10, y + height-40, width-20, 30))
                soundboardSliders[tempKey] = tempSlider
                self.view.addSubview(soundboardSliders[tempKey]!)
                
                tagCnt++
            }
        }
        
        //make slider
        
        
    }
    
    
    func editSwitchChanged(sender:UISwitch){
        if sender.on{
            isEditMode = true
            hideSliders(false)
            
        }
        else{
            isEditMode = false
            hideSliders(true)
            
        }
    }
    
    func hideSliders(hidden:Bool){
        for (key, value) in  soundboardSliders {
            value.hidden = hidden
        }
    }
    
    func soundButtonPressed(sender:UIButton){
        var key:String = itemKeys[sender.tag]
        if(isEditMode){
            
            editingKey = key
            //create load file popover
            var popW:CGFloat = 250;
            var popH:CGFloat = 400;
            var popOverContent:UIViewController = UIViewController()
            var popOverView:UIView = UIView()
            popOverView.backgroundColor = FlatUIColor.asbestosColor()
            var tableViewFiles:UITableView = UITableView(frame: CGRectMake(0,0,popW,popH))
            tableViewFiles.backgroundColor = FlatUIColor.asbestosColor()
            tableViewFiles.rowHeight = 40
        
            
            popOverView.addSubview(tableViewFiles)
            
            
            
            popOverContent.view = popOverView
            popOverContent.preferredContentSize = CGSizeMake(popW, popH)
            self.popOver = UIPopoverController(contentViewController: popOverContent)
            
//            popOverView.layer.borderColor = FlatUIColor.peterriverColor().CGColor
//            popOverView.layer.borderWidth = 1.0
            
            tableViewFiles.delegate = self
            tableViewFiles.dataSource = self
            
            var tempFrame = CGRectMake(sender.frame.origin.x + sender.frame.width/2, sender.frame.origin.y+sender.frame.height/2, 1, 1)
            
            self.popOver.presentPopoverFromRect(tempFrame, inView: self.view, permittedArrowDirections: UIPopoverArrowDirection.Any, animated: true)
        }
        else{
            println("Play Pressed: \(sender.titleLabel?.text as String!), KEY: \(key), VOLUME: \(soundboardSliders[key]?.value)")
            self.play(key, volume: soundboardSliders[key]!.value * masterVolumeSlider.value)
        }
        
        
    }

    
    //MARK: Audio Playback
    
    //load an audio file to respond to a keypress
    func loadFile(key:String,filePathToLoad:String){
        
        //create audio path url
        var audioURL:NSURL = NSURL(fileURLWithPath: filePathToLoad)!
        
        //create audio player and load file
        var audioPlayer = AVAudioPlayer()
        var error:NSError?
        audioPlayer = AVAudioPlayer(contentsOfURL: audioURL, error: &error)
        audioPlayer.prepareToPlay()
        
        //load into samples dictionary
        samplesDict[key] = audioPlayer
        
        //put filename on preview button
        var fileNameComponents = filePathToLoad.componentsSeparatedByString("/")
        self.soundboardButtons[key]?.setTitle(fileNameComponents[fileNameComponents.count - 1], forState: UIControlState.Normal)
        self.soundboardButtons[key]?.titleLabel?.font = UIFont(name: "Helvetica-Light", size: 20)
        soundboardButtons[key]?.backgroundColor = FlatUIColor.emerlandColor(alpha: 0.3)
        
        savePreset()
    }

    
    func play(key:String, volume:Float=1.0){
        
        //check if sample is loaded
        if samplesDict[key] != nil {
            //reset to time 0 and play sample
            samplesDict[key]?.currentTime=0
            samplesDict[key]?.volume=volume
            samplesDict[key]?.play()
            
            soundboardButtons[key]?.backgroundColor = UIColor.greenColor()
            soundboardButtons[key]?.backgroundColor = FlatUIColor.emerlandColor(alpha: 1.0)
            UIView.animateWithDuration(samplesDict[key]!.duration, delay: 0.0, options: .CurveEaseOut | .AllowUserInteraction, animations: {
                     soundboardButtons[key]?.backgroundColor = FlatUIColor.emerlandColor(alpha: 0.3)
                }, completion: { finished in
                    
            })
        }
        
    }

    
    
    //MARK: Presets
    //Save presets "key:soundfile.type\nkey2:soundfile2.type "
    func savePreset(){
        var saveStr:String = ""
        for (key, value) in samplesDict {
            var filePath = ("\((value as AVAudioPlayer).url.path as String!)").componentsSeparatedByString("/")
            var fileName = filePath[filePath.count - 1]
            saveStr += "\(key):\(fileName):\(soundboardSliders[key]!.value as Float)\n"
        }
        
        saveStr += "MAIN:\(masterVolumeSlider.value as Float)\n"
        
        println(saveStr)
        
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
        saveStr.writeToFile((documentsPath as String) + "/" + "savedPreset.txt", atomically: true, encoding: NSUTF8StringEncoding, error: nil)
    }

    
    
    //load presets
    func loadPreset(){
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
        let loadStr:String = String(contentsOfFile: (documentsPath as String) + "/" + "savedPreset.txt", encoding: NSUTF8StringEncoding, error: nil)!
        
        var filesList = loadStr.componentsSeparatedByString("\n")
        for f in filesList{
            
            if f != "" {
                var fileComponents = (f as String).componentsSeparatedByString(":")
                
                var key:String = fileComponents[0]
                
                if key == "MAIN"{
                    var volume:Float = (fileComponents[1] as NSString).floatValue
                    self.masterVolumeSlider.value = volume
                }
                else{
                    var fileName:String = fileComponents[1]
                    var volume:Float = (fileComponents[2] as NSString).floatValue
                    fileName = (documentsPath as String) + "/" + fileName
                    self.loadFile(key, filePathToLoad: fileName)
                    self.soundboardSliders[key]?.value = volume
                    
                }
                
                
                
            }
        }
    }
    
    
    //MARK: Table Setup
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.fileNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .Default, reuseIdentifier: "UITableViewCell")
        
            
        //make cell text the name of the file
        cell.textLabel?.text = self.fileNames.objectAtIndex(indexPath.row) as? String
        
        //make the cell match the UI design
        cell.textLabel?.textColor = FlatUIColor.cloudsColor()
        cell.backgroundColor = FlatUIColor.asbestosColor()
        cell.textLabel?.font = UIFont(name: "Melno", size: CGFloat(22))
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("Selected: \(indexPath.row)")
        
       // load the file selected to a key row
            println("File Selected: \(fileNames.objectAtIndex(indexPath.row))")
            popOver.dismissPopoverAnimated(true)
            loadFile(editingKey, filePathToLoad: fullPaths.objectAtIndex(indexPath.row) as! String)
    }

    func transferAudio(){
        //copy audio examples from resources into docs folder so theres something there from the start
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as! NSString
        var snareFile = NSBundle.mainBundle().pathForResource("Snare", ofType: "wav")
        var kickFile = NSBundle.mainBundle().pathForResource("Kick", ofType: "wav")
        var hihatFile = NSBundle.mainBundle().pathForResource("HiHat", ofType: "wav")
        var crashFile = NSBundle.mainBundle().pathForResource("Crash", ofType: "wav")
        
        var error:NSError?
        NSFileManager.defaultManager().copyItemAtPath(snareFile!, toPath: (documentsPath as String + "/Snare.wav"), error: &error)
        NSFileManager.defaultManager().copyItemAtPath(kickFile!, toPath:(documentsPath as String + "/Kick.wav"), error: &error)
        NSFileManager.defaultManager().copyItemAtPath(hihatFile!, toPath: (documentsPath as String + "/HiHat.wav"), error: &error)
        NSFileManager.defaultManager().copyItemAtPath(crashFile!, toPath: (documentsPath as String + "/Crash.wav"), error: &error)
        
        //get List of wave files in docs dir to display in popover
        var directoryContent = NSFileManager.defaultManager().contentsOfDirectoryAtPath(documentsPath as String, error: nil)
        var cnt = 0
        for var i = 0; i < directoryContent?.count; ++i {
            
            var fp = "\(documentsPath)/\((directoryContent as! [String])[i])"
            var filename = "\((directoryContent as! [String])[i])"
            var components:NSArray = filename.componentsSeparatedByString(".")
            var suffix:String = components[components.count-1] as! String
            
            //make sure its an audio file supported
            if suffix == "wav" || suffix=="mp3" || suffix=="aiff" || suffix=="m4a"{
                ++cnt
                println("\(cnt) : \(documentsPath)/\((directoryContent as! [String])[i])")
                fullPaths.addObject(fp)
                fileNames.addObject(filename)
            }
        }

    }


}

