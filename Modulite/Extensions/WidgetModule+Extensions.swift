//
//  WidgetModule+Extensions.swift
//  Modulite
//
//  Created by Gustavo Munhoz Correa on 07/11/24.
//

import UIKit
import WidgetStyling

extension WidgetModule {
    func createCompleteImage() -> UIImage {
        let cell = WidgetModuleCell()
        cell.setup(with: self)
        cell.frame = CGRect(
            origin: .zero,
            size: CGSize(width: 108, height: 170)
        )
        
        cell.layoutIfNeeded()
        
        return cell.asImage()
    }
}

extension WidgetModule {
    convenience init?(persisted: PersistableModuleConfiguration) {
        let provider = try? WidgetStyleProvider()
        
        guard let moduleStyle = provider?.getModuleStyle(
            by: persisted.selectedStyleKey
        ) else { return nil }
        
        self.init(
            style: moduleStyle,
            position: Int(persisted.index),
            appName: persisted.appName,
            urlScheme: persisted.urlScheme,
            color: persisted.selectedColor ?? .clear
        )
    }
}
