import SwiftUI
import StreamyLogic

struct ChooseModelVM<O: ObservableObject> {
    let choice:    ReferenceWritableKeyPath<O, String>
    let choices:   KeyPath<O, [String]>
    let predictor: KeyPath<O, PredictUseCase>
    let isLoading: KeyPath<O, Bool>
    let error:     ReferenceWritableKeyPath<O, CoreMLError?>
    let onAppear:  () -> Void
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

struct PredictView<Object: ObservableObject>: View {

    init(_ observable: Observed<Object, ChooseModelVM<Object>>) {
        _state = .init(wrappedValue: observable.object)
        self.vm = observable.vm
    }

    @StateObject private var state: Object
    private let vm: ChooseModelVM<Object>

    var body: some View {
        VStack(alignment: .leading, spacing: .verticalSpacing / 2) {
            menu
            Divider()
            CoreMLClassifierModelOutputView(.observe(state[keyPath: vm.predictor]))
        }
        .screenPadding()
        .navigationTitle("Predict")
        .onAppear(perform: vm.onAppear)
        .animation(.easeOut, value: state[keyPath: vm.choice])
        .alert(
            isPresented: $state[dynamicMember: vm.error].isPresented(),
            error: state[keyPath: vm.error],
            actions: { Button("Ok") {} }
        )
    }

    private var menu: some View {
        HStack {
            Spacer()
            if state[keyPath: vm.isLoading] {
                CircularBusyIndicator()
            }
            Picker("Choose Model", selection: $state[dynamicMember: vm.choice]) {
                ForEach(state[keyPath: vm.choices], id: \.self) { choice in
                    Text(choice).id(choice)
                }
            }
        }
        .animation(.easeOut, value: state[keyPath: vm.isLoading])
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
