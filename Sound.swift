import AVFoundation
var player: AVAudioPlayer?

func playSound(sound: String) {
    guard let path = Bundle.main.path(forResource: sound, ofType:"wav") else {
        return }
    let url = URL(fileURLWithPath: path)
    do {
        player = try AVAudioPlayer(contentsOf: url)
        player?.play()
        
    } catch let error {
        print(error.localizedDescription)
    }
}
