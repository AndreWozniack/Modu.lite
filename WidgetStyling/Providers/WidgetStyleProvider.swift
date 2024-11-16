//
//  WidgetStyleProvider.swift
//  WidgetStyling
//
//  Created by Gustavo Munhoz Correa on 06/11/24.
//

import Foundation

public class WidgetStyleProvider {
    
    // MARK: - Properties
    private(set) var styles: [WidgetStyle] = []
    
    enum ProviderError: Swift.Error {
        case directoryNotFound
    }
    
    // MARK: - Initializer
    public init() throws {
        try loadStyles()
    }
    
    // MARK: - Methods
    public func setPurchasedStyles(_ styleIds: Set<String>) {
        styles = styles.map {
            $0.updateIsPurchased(
                to: styleIds.contains($0.identifier)
            )
            return $0
        }
    }
    
    private func loadStyles() throws {
        let bundle = Bundle(for: Self.self)
        
        guard let resourceURL = bundle.resourceURL else {
            throw ProviderError.directoryNotFound
        }
        
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: resourceURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )
        
        let jsonFileURLs = fileURLs.filter { $0.pathExtension.lowercased() == "json" }
        
        for fileURL in jsonFileURLs {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let styleData = try decoder.decode(WidgetStyleData.self, from: data)
            let style = try LoadedWidgetStyle(from: styleData)
            
            styles.append(style)
        }
    }
    
    public func getModuleStyle(by identifier: String) -> ModuleStyle? {
        let allModules = styles.flatMap { style -> [ModuleStyle] in
            var modules: [ModuleStyle] = []
            modules.append(contentsOf: style.moduleConfiguration.mainModules)
            modules.append(contentsOf: style.moduleConfiguration.auxModules)
            modules.append(style.moduleConfiguration.mainEmptyModule)
            modules.append(style.moduleConfiguration.auxEmptyModule)
            return modules
        }
                
        return allModules.first(where: { $0.identifier == identifier })
    }
    
    public func getStyle(by identifier: String) -> WidgetStyle? {
        styles.first(where: { $0.identifier == identifier })
    }
    
    public func getAllStyles() -> [WidgetStyle] { styles }
}
