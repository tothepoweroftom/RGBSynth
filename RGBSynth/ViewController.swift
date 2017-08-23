import UIKit
import CoreImage
import GPUImage
import AVFoundation
import AudioKit

class ViewController: UIViewController {
    @IBOutlet weak var renderView: RenderView!
    
    
    var camera:Camera!
    var histogram: Histogram!
    var histogramDisplay: HistogramDisplay!
    var rawOutput: RawDataOutput!
    var toon: SaturationAdjustment!
    var blur: Pixellate!
    
    var red = 0
    var green = 0
    var blue = 0
    
    var rD = 0.0
    var gD = 0.0
    var bD = 0.0
    
    var oscillator = AKFMOscillatorBank()
    var bitCrush: AKBitCrusher!
    var reverb: AKCostelloReverb!
    var delay: AKDelay!
    var mixer: AKMixer!
    var isPlaying = false
    var conv: AKConvolution!
    var conv2: AKConvolution!
    var vol: AKMixer!
    var convMixer: AKDryWetMixer!
    var pitch: AKPitchShifter!
    var pitch2: AKPitchShifter!
    var pitch3: AKPitchShifter!
    var pitchMixer: AKMixer!
    var pitchDWMixer: AKDryWetMixer!
    var fileURL: URL!
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.navigationBar.barTintColor = UIColor.black
        self.navigationController?.navigationBar.tintColor = UIColor.black
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.yellow]
        
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let urlpath = Bundle.main.path(forResource: "metalgate", ofType: ".wav")
        fileURL = URL(fileURLWithPath: urlpath!)
        histogram = Histogram(type: .rgb)
        histogramDisplay = HistogramDisplay()
        histogram.downsamplingFactor = 12
        blur = Pixellate()
        blur.fractionalWidthOfAPixel = 0.25
        do {
            try AKSettings.setSession(category: .playback)

        } catch {
            
        }
        
        bitCrush = AKBitCrusher(oscillator)
        pitch = AKPitchShifter(bitCrush, shift: 7.0, windowSize: 1024, crossfade: 512)
        pitch2 = AKPitchShifter(bitCrush, shift: -12.0, windowSize: 1024, crossfade: 512)
        pitch3 = AKPitchShifter(bitCrush, shift: -5.0, windowSize: 1024, crossfade: 512)
        pitchMixer = AKMixer(pitch, pitch2, pitch3)
        pitchDWMixer = AKDryWetMixer(bitCrush, pitchMixer, balance: 0.5)
        delay = AKDelay(pitchDWMixer)
        delay.dryWetMix = 0.4
        reverb = AKCostelloReverb(delay)
        reverb.presetLowRingingLongTailCostelloReverb()
        
        mixer = AKMixer(reverb)
        mixer.volume = 0.5
        
        
        
        
        AudioKit.output = mixer
        AudioKit.start()
        
        //        setupUI()
        
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateData), userInfo: nil, repeats: true)
        Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(playNote), userInfo: nil, repeats: true)
        
        rawOutput = RawDataOutput()
        rawOutput.dataAvailableCallback = { buffer in
            
            
            
            if buffer.isEmpty == false {
                for i in stride(from: 0, to: buffer.count-4, by: 4) {
                    self.red += Int(buffer[i])
                    self.green += Int(buffer[i+1])
                    self.blue += Int(buffer[i+2])
                    
                    
                }
                
                
                self.rD = Double(self.red/(buffer.count/4))
                self.gD = Double(self.green/(buffer.count/4))
                self.bD = Double(self.blue/(buffer.count/4))
                
                
            }
            
            
            
        }
        
        do {
            camera = try Camera(sessionPreset:AVCaptureSessionPreset640x480)
            camera.runBenchmark = true
            camera.delegate = self
            camera --> histogram
            camera --> blur --> renderView
            histogram --> rawOutput
            
            camera.startCapture()
        } catch {
            fatalError("Could not initialize rendering pipeline: \(error)")
        }
    }
    
    func updateData(){
        if isPlaying {
            let pitch = map(Double(self.red), min: 0.0, max: 70000.0, toMin: 30.0, toMax: 5000.0)
            print(pitch)
            bitCrush.sampleRate = pitch
            
            let car = map(Double(self.green), min: 0.0, max: 70000.0, toMin: 1.0, toMax: 25.0)
            oscillator.carrierMultiplier = car
            
            let del = map(Double(self.blue), min: 0.0, max: 70000.0, toMin: 0.1, toMax: 1.0)
            oscillator.detuningMultiplier = del
            
            let vol = map(Double(blue+red+green), min: 1000.0, max: 1000000.0, toMin: 0.1, toMax: 0.5)
            mixer.volume = vol
            
            
            
            print("R: \(self.red), G: \(self.green), B: \(self.blue)" )
            
            
            self.red = 0
            self.blue = 0
            self.green = 0
        }
    }
    
    func playNote(){
        if isPlaying {
            let col = checkPredomColor()
            
            switch col {
            case 1:
                oscillator.play(noteNumber: 30, velocity: 120)
            case 2:
                oscillator.play(noteNumber: 33, velocity: 120)
            case 3:
                oscillator.play(noteNumber: 37, velocity: 120)
            default:
                oscillator.play(noteNumber: 23, velocity: 120)
                
            }
        }
    }
    
    func checkPredomColor() -> Int{
        var col = 0
        
        if (red > green && red > blue) {
            col = 1
        }
        if (green > red && green > blue) {
            col = 2
        }
        if (blue > green && blue > red) {
            col = 3
        }
        
        return col
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    @IBAction func didSwitch(_ sender: UISwitch) {
        //        shouldDetectFaces = sender.isOn
    }
    
    
    @IBAction func capture(_ sender: AnyObject) {
        print("Capture")
        do {
            let documentsDir = try FileManager.default.url(for:.documentDirectory, in:.userDomainMask, appropriateFor:nil, create:true)
        } catch {
            print("Couldn't save image: \(error)")
        }
    }
    
    
    @IBAction func pitchShifter(_ sender: UISlider) {
        pitchDWMixer.balance = Double(sender.value)
    }
    
    
    @IBAction func convolutionS(_ sender: UISlider) {
        reverb.feedback = Double(sender.value - 0.1)
    }
    
    
    @IBAction func OnOFF(_ sender: UISwitch) {
        if sender.isOn {
            mixer.volume = 0.5
            isPlaying = true
            
        } else {
            mixer.volume = 0.0
            isPlaying = false
            
        }
    }
    
}

extension ViewController: CameraDelegate {
    func didCaptureBuffer(_ sampleBuffer: CMSampleBuffer) {
        
    }
    
    
}

extension ViewController: AKKeyboardDelegate {
    func setupUI() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let adsrView = AKADSRView() { att, dec, sus, rel in
            self.oscillator.attackDuration = att
            self.oscillator.decayDuration = dec
            self.oscillator.sustainLevel = sus
            self.oscillator.releaseDuration = rel
        }
        
        stackView.addArrangedSubview(adsrView)
        let keyboardView = AKKeyboardView()
        keyboardView.delegate = self
        
        stackView.addArrangedSubview(keyboardView)
        
        view.addSubview(stackView)
        
        stackView.widthAnchor.constraint(equalToConstant: view.frame.width).isActive = true
        stackView.heightAnchor.constraint(equalToConstant: view.frame.height).isActive = true
        
        stackView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        stackView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }
    
    func noteOn(note: MIDINoteNumber) {
        oscillator.play(noteNumber: note, velocity: 64)
    }
    
    func noteOff(note: MIDINoteNumber) {
        oscillator.stop(noteNumber: note)
    }
}
