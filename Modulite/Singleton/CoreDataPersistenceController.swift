//
//  CoreDataPersistenceController.swift
//  Modulite
//
//  Created by Gustavo Munhoz Correa on 02/09/24.
//

import CoreData
import UIKit

struct CoreDataPersistenceController {
    
    // MARK: - Properties
    static let shared = CoreDataPersistenceController()
    
    static var preview: CoreDataPersistenceController = {
        let result = CoreDataPersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        do {
            try viewContext.save()
        } catch {
            let error = error as NSError
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
        
        return result
    }()
    
    let container: NSPersistentContainer
    
    // MARK: - Setup methods
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "WidgetData")
        
        guard let appGroupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.dev.mnhz.modu.lite.shared"
        ) else {
            fatalError("Could not find App Group Container")
        }
        
        let storeURL = appGroupURL.appendingPathComponent("WidgetData.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        
        if inMemory {
            description.url = URL(filePath: "/dev/null")
        }
        
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error as? NSError {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.name = "viewContext"
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
        container.viewContext.shouldDeleteInaccessibleFaults = true
    }
    
    func executeInitialSetup() {
        let apps = fetchApps()
        
        if apps.isEmpty {
            populateAppsAtFirstExecution()
        }
    }
}

// MARK: - AppInfo
extension CoreDataPersistenceController {
    
    func fetchApps(predicate: NSPredicate? = nil) -> [AppInfo] {
        let request = AppInfo.nameSortedFetchRequest()
        request.predicate = predicate
        do {
            let apps = try container.viewContext.fetch(request)
            return apps
        } catch {
            print("Error fetching apps: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchAppInfo(named name: String, urlScheme: String) -> AppInfo? {
        let predicate = NSPredicate(format: "name == %@ AND urlScheme == %@", name, urlScheme)
        let apps = CoreDataPersistenceController.shared.fetchApps(predicate: predicate)
        return apps.first
    }
    
    private func populateAppsAtFirstExecution() {
        guard let url = Bundle.main.url(forResource: "apps", withExtension: "json") else {
            fatalError("Failed to find apps.json")
        }
        
        do {
            let data = try Data(contentsOf: url)
            let appsData = try JSONDecoder().decode([AppInfoData].self, from: data)
            
            appsData.forEach { data in
                AppInfo.createFromData(data, using: container.viewContext)
            }
            
            print("Populated apps with \(appsData.count) items.")
        } catch {
            print("Failed to populate appInfo table with error \(error.localizedDescription)")
        }
    }
}

// MARK: - Widget persistence
extension CoreDataPersistenceController {
    func fetchWidgets(predicate: NSPredicate? = nil) -> [PersistableWidgetConfiguration] {
        let request = PersistableWidgetConfiguration.basicFetchRequest()
        request.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            return try container.viewContext.fetch(request)
            
        } catch {
            print("Error fetching widgets: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteWidget(withId id: UUID) {
        let context = container.viewContext
        let request = PersistableWidgetConfiguration.basicFetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            guard let widget = try context.fetch(request).first else {
                print("Widget with id \(id) not found.")
                return
            }
            
            context.delete(widget)
            
            try context.save()
            
            FileManagerImagePersistenceController.shared.deleteWidgetAndModules(widgetId: id)
            print("Widget with id \(id) deleted successfully from CoreData.")
            
        } catch {
            print("Error deleting widget from CoreData: \(error.localizedDescription)")
        }
    }
    
    @discardableResult
    func registerWidget(
        _ config: ModuliteWidgetConfiguration,
        widgetImage: UIImage
    ) -> PersistableWidgetConfiguration {
        let widgetConfig = PersistableWidgetConfiguration.createFromWidgetConfiguration(
            config,
            widgetImage: widgetImage,
            using: container.viewContext
        )
        
        return widgetConfig
    }
}
