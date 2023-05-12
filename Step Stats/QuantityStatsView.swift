//
//  QuantityStatsView.swift
//  Step Stats
//
//  Created by Michael Bryant on 5/11/23.
//

import SwiftUI

class AnimationManager: ObservableObject {
    @Published var animatedValue: Double = 0
    @Published var isFinished: Bool = false
    private var animationTimer: Timer?
    
    func startAnimation(from initialValue: Double, to finalValue: Double, duration: TimeInterval) {
        let totalSteps = Int(duration * 30) // 30 steps per second
        let animationStep = (finalValue - initialValue) / Double(totalSteps)
        let timeInterval = duration / Double(totalSteps)
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            self.animatedValue += animationStep
            
            if self.animatedValue >= finalValue {
                self.animatedValue = finalValue
                self.isFinished = true
                timer.invalidate()
            }
        }
    }
    
    func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

struct QuantityStatsView: View {
    var statName: String = "Steps"
    var valueString: String = "5,424,324"
    
    @StateObject private var animationManager = AnimationManager()
    
    private var doubleValue: Double {
        return Double(valueString.filter { $0.isNumber }) ?? 0
    }
    
    private let fileName = "example.txt" // Replace with the name of your file
    private let fileType = "txt" // Replace with the type of your file
    
    var body: some View {
        VStack {
            Text(statName)
                .font(.title)
                .padding(.top, 20)
            Text("\(animationManager.animatedValue, specifier: "%.0f")")
                .font(.title)
                .onAppear {
                    animationManager.startAnimation(from: 0, to: doubleValue, duration: 2.0)
                }
            if animationManager.isFinished {
                if let fileURL = Bundle.main.url(forResource: fileName, withExtension: fileType) {
                    if let fileContents = try? String(contentsOf: fileURL) {
                        Text(fileContents)
                            .font(.title)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .onDisappear {
            animationManager.stopAnimation()
        }
    }
}



struct QuantityStatsView_Previews: PreviewProvider {
    static var previews: some View {
        QuantityStatsView()
    }
}
