import SwiftUI
import StreamyLogic

struct ChooseModelVM<O: ObservableObject, Sensor: MenuOption> {
    let sensorChoice:   ReferenceWritableKeyPath<O, Sensor>
    let modelChoice:    ReferenceWritableKeyPath<O, String>
    let modelChoices:   KeyPath<O, [String]>
    let sensorChoices:  KeyPath<O, [Sensor]>
    let predictor:      KeyPath<O, PredictUseCase>
    let isLoading:      KeyPath<O, Bool>
    let error:          ReferenceWritableKeyPath<O, CoreMLError?>
    let onAppear:       () -> Void
    let loadModel:      () -> Void
}

struct PredictViewModel<O: ObservableObject> {
    let instruction: KeyPath<O, String>
    let outputs:     KeyPath<O, [String]>
    let prediction:  KeyPath<O, String>
    let predictions: KeyPath<O, [(String, Double)]>

    let frameRate:      KeyPath<O, String>
    let predictionRate: KeyPath<O, String>
    let error:          ReferenceWritableKeyPath<O, CoreMLError?>
    let onAppear:  () -> Void
}

// MARK: - Choices

struct PredictView<Object: ObservableObject, Sensor: MenuOption>: View {

    init(_ observable: Observed<Object, ChooseModelVM<Object, Sensor>>) {
        _state = .init(wrappedValue: observable.object)
        self.vm = observable.vm
    }

    @StateObject private var state: Object
    private let vm: ChooseModelVM<Object, Sensor>

    var body: some View {
        VStack(alignment: .leading, spacing: .verticalSpacing / 2) {
            setup
            Divider()
            CoreMLClassifierModelOutputView(.observe(state[keyPath: vm.predictor]))
        }
        .screenPadding()
        .navigationTitle("Predict")
        .onAppear(perform: vm.onAppear)
        .animation(.easeOut, value: state[keyPath: vm.modelChoice])
        .alert(
            isPresented: $state[dynamicMember: vm.error].isPresented(),
            error: state[keyPath: vm.error],
            actions: { Button("Ok") {} }
        )
    }

    @ViewBuilder private var setup: some View {
        HStack {
            MenuOptionPicker(
                state: state,
                choice: vm.sensorChoice,
                choices: vm.sensorChoices,
                label: "Sensor Stream"
            ).fixedSize()
            Spacer()
            tips
        }

        HStack(spacing: 20) {

            Picker("CoreML Model", selection: $state[dynamicMember: vm.modelChoice]) {
                ForEach(state[keyPath: vm.modelChoices], id: \.self) { choice in
                    Text(choice).id(choice)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()

            Spacer()

            CircularBusyIndicator()
                .opacity(state[keyPath: vm.isLoading] ? 1 : 0)
                .animation(.easeOut, value: state[keyPath: vm.isLoading])

            Button("Start", action: vm.loadModel)
                .keyboardShortcut(.defaultAction)
        }
    }

    @State private var showTips = false
    private var tips: some View {
        Text("Tips")
            .popover(isPresented: $showTips) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Tips").font(.title2)

                        Text("Releasing the button resets model state to zero.")
                            .leftAlignWrap()
                        Text("Add your CoreML models to the `StreamyLogic` package.")
                            .leftAlignWrap()
                        Text("Sensors you stream must map into `Array<Float>` whose order matches your CoreML Model's training input. See `SensorStreamForCoreML.swift`.")
                            .leftAlignWrap()
                        Text("Actual and modeled data rate (e.g., 50 vs 100 hz) should be similar.")
                            .leftAlignWrap()
                        Text("On macOS, Streamy has a Data Wrangling menu to quickly process CSVs.")
                            .leftAlignWrap()
                    }
                }
                .padding()
                .frame(maxWidth: 250, maxHeight: 350, alignment: .top)
                .fixedSize()
            }
            .onHover { _ in showTips = true }
    }
}

// MARK: - Model Output

struct CoreMLClassifierModelOutputView<Object: ObservableObject>: View {

    init(_ observable: Observed<Object, PredictViewModel<Object>>) {
        self.state = observable.object
        self.vm = observable.vm
    }

    @ObservedObject private var state: Object
    private let vm: PredictViewModel<Object>

    var body: some View {
        VStack(alignment: .center, spacing: .verticalSpacing) {

            Text(state[keyPath: vm.instruction])
                .font(.title3)

            VStack(alignment: .leading) {
                ForEach(state[keyPath: vm.predictions], id: \.0)  { row in
                    PredictionDetail(
                        prediction: row.0,
                        rating: row.1,
                        isTopChoice: state[keyPath: vm.prediction] == row.0
                    )
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))

            Divider()
            details
        }
        .onAppear(perform: vm.onAppear)
        .frame(maxWidth: .infinity, maxHeight:  .infinity)
        .animation(.easeIn, value: state[keyPath: vm.prediction])
        .animation(.easeIn, value: state[keyPath: vm.predictions].map(\.0))
        .alert(
            isPresented: $state[dynamicMember: vm.error].isPresented(),
            error: state[keyPath: vm.error],
            actions: { Button("Ok") {} }
        )
    }

    private var details: some View {
        VStack(alignment: .center) {
            outputs
            HStack {
                streamingRate
                predictionRate
            }
        }
    }

    private var outputs: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("Classes")
                .foregroundColor(.secondary)
                .font(.caption)

            Text(state[keyPath: vm.outputs].joined(separator: ""))
                .font(.caption.bold())
        }
    }

    private var streamingRate: some View {
        HStack {
            Text("Streaming").foregroundColor(.secondary)
            Text(state[keyPath: vm.frameRate]).bold()
        }.font(.caption)
    }

    private var predictionRate: some View {
        HStack {
            Text("Predictions").foregroundColor(.secondary)
            Text(state[keyPath: vm.predictionRate]).bold()
        }.font(.caption)
    }
}

struct PredictionDetail: View {

    var (prediction, rating): (String, Double)
    var isTopChoice: Bool

    var body: some View {
        HStack(spacing: 25) {
            Text(prediction)
                .font(isTopChoice ? .body.bold() : .body)
                .frame(minWidth: 50)
                .foregroundColor(isTopChoice ? .accentColor : nil)

            ProgressView("", value: rating, total: 1)
                .frame(width: 50)
                .animation(.easeOut(duration: 0.1), value: rating)
        }
        .foregroundColor(.secondary)
    }
}

extension View {

    func leftAlignWrap() -> some View {
        self
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
    }
}
