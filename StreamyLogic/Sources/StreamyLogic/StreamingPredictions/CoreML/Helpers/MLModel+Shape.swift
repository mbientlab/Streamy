import Foundation
import CoreML

extension MLModel {

    func getShape(stateInKey: String = "stateIn")
    -> (lstmStateSize: Int, predictionWindow: Int, inputs: Set<String>)? {

        guard let stateIn          = modelDescription.inputDescriptionsByName[stateInKey],
              let randomInput      = modelDescription.inputDescriptionsByName.first(where: { $0.key != "stateIn" })?.value,
              let lstmStateSize    = stateIn.multiArrayConstraint?.shape.first as? Double,
              let predictionWindow = randomInput.multiArrayConstraint?.shape.first as? Double
        else { return nil }
        let inputs = Set(modelDescription.inputDescriptionsByName.keys).subtracting([stateInKey])
        return (Int(lstmStateSize), Int(predictionWindow), inputs)
    }

    func featureNames() -> (input: Set<String>, output: Set<String>) {
        (Set(modelDescription.inputDescriptionsByName.keys),
         Set(modelDescription.outputDescriptionsByName.keys))
    }
}
