//
//  WidgetSetupViewController+UITextFieldDelegate.swift
//  Modulite
//
//  Created by André Wozniack on 02/11/24.
//

import UIKit

// MARK: - UITextFieldDelegate
extension WidgetSetupViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        if string.rangeOfCharacter(from: CharacterSet.newlines) != nil {
            return false
        }
        
        let currentText = textField.text ?? ""
                
        guard let textRange = Range(range, in: currentText) else {
            return false
        }
        
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)
        
        if updatedText.count > 24 {
            return false
        }
        
        didMakeChangesToWidget = true
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
