import SwiftUI
import ARKit
import SceneKit
import AVFoundation

// MARK: - Coordinator Class
class SceneCoordinator: NSObject, ObservableObject, ARSCNViewDelegate {
    var modelNode: SCNNode?

    func makeModelStandUp() {
        guard let node = modelNode else { return }

        let standAction = SCNAction.rotateTo(
            x: 0,
            y: 0,
            z: 0,
            duration: 1.0,
            usesShortestUnitArc: true
        )
        node.runAction(standAction)
    }
}

// MARK: - AR View Container
struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var coordinator: SceneCoordinator

    func makeCoordinator() -> SceneCoordinator {
        return coordinator
    }

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView()
        sceneView.autoenablesDefaultLighting = true
        sceneView.showsStatistics = true
        sceneView.debugOptions = [.showFeaturePoints, .showWorldOrigin]
        sceneView.delegate = context.coordinator

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        sceneView.session.run(config)

        // Load USDZ model
        if let scene = try? SCNScene(named: "Male.usdz") {
            let node = scene.rootNode.clone()
            node.scale = SCNVector3(0.1, 0.2, 0.1)
            node.position = SCNVector3(0, -0.1, -1.0) // 1 meter in front
            node.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0) // Lying down, face up
            sceneView.scene.rootNode.addChildNode(node)
            context.coordinator.modelNode = node
            print("✅ Model added to scene")
        } else {
            print("❌ Failed to load Male.usdz")
        }

        return sceneView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {}
}

// MARK: - TTS Manager
class SpeechManager {
    static let shared = SpeechManager()
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}

// MARK: - Main ContentView
struct ContentView: View {
    @StateObject private var coordinator = SceneCoordinator()
    @State private var currentStepIndex = 0

    let steps = [
        "Check if the person is responsive.",
        "Call emergency services immediately.",
        "Begin chest compressions at a rate of 100 to 120 per minute.",
        "After 30 compressions, give 2 rescue breaths.",
        "Continue the cycle until help arrives."
    ]

    var body: some View {
        ZStack(alignment: .top) {
            ARViewContainer(coordinator: coordinator)
                .edgesIgnoringSafeArea(.all)

            VStack {
                // CPR instruction label
                Text(steps[currentStepIndex])
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.85))
                    .cornerRadius(12)
                    .padding([.top, .horizontal])

                Spacer()

                // Buttons
                HStack {
                    Spacer()

                    Button(action: {
                        if currentStepIndex < steps.count - 1 {
                            currentStepIndex += 1
                            SpeechManager.shared.speak(steps[currentStepIndex])
                        }
                    }) {
                        Text("Next Step")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }

                    Button(action: {
                        coordinator.makeModelStandUp()
                    }) {
                        Text("Complete")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }

                    .padding(.leading, 8)
                    .padding(.trailing)
                }
                .padding(.bottom)
            }
        }
        .onAppear {
            SpeechManager.shared.speak(steps[currentStepIndex])
        }
    }
}
