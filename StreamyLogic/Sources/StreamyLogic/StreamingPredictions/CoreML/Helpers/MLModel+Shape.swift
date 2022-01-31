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

    func featureNames() -> (input: Set<String>, output: Set<String>, inputVectorKeys: [String]) {
        let input = Set(modelDescription.inputDescriptionsByName.keys)
        let output = Set(modelDescription.outputDescriptionsByName.keys)
        let inputVector = (modelDescription.metadata[.creatorDefinedKey] as? [String: String])?["features"]?.components(separatedBy: ",") ?? []
        return (input,output,inputVector)
    }
}
