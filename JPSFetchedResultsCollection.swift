//
//  JPSFetchedResultsCollection.swift
//
//  Created by Jonathan Sullivan on 7/12/16.

import UIKit


// MARK: JPSEmptyFetchedResultsSectionInfo

private class JPSEmptyFetchedResultsSectionInfo: NSObject, NSFetchedResultsSectionInfo
{
    // MARK: Public Mutable Members
    
    var name = ""
    var indexTitle: String?
    
    // MARK: Public Read Only Members
    
    var numberOfObjects: Int {
        get { return 0 }
    }
    
    var objects: [Any]? {
        get { return nil }
    }
}

// MARK: JPSEmptyFetchedResultsController

private class JPSEmptyFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>
{
    // MARK: Public Mutable Members
    
    let emptySection = JPSEmptyFetchedResultsSectionInfo()
    
    // MARK: Public Read Only Members
    
    override var sections: [NSFetchedResultsSectionInfo]? {
        get { return [self.emptySection] }
    }
}

// MARK: JPSFetchedResultsCollectionDelegate

@objc protocol JPSFetchedResultsCollectionDelegate
{
    func containerWillChangeContent(_ container: JPSFetchedResultsCollection)
    func containerDidChangeContent(_ container: JPSFetchedResultsCollection)
    func container(_ container: JPSFetchedResultsCollection, didChange section: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    func container(_ container: JPSFetchedResultsCollection, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
}

// MARK: JPSFetchedResultsController

@objc class JPSFetchedResultsCollection: NSObject
{
    // MARK: Private Mutable Members
    
    private var emptyFetchedResultsControllerIndexes: [NSNumber]?
    
    // MARK: Read Only Members
    
    private(set) var fetchedResultsControllers = [NSFetchedResultsController<NSFetchRequestResult>]()
    
    // MARK: Public Mutable Members
    
    weak var delegate: JPSFetchedResultsCollectionDelegate?
    
    // MARK: Public Read Only Members
    
    var fetchedObjects: [AnyObject]
    {
        get
        {
            var fetchedObjects = [NSFetchRequestResult]()
            
            for fetchedResultsController in self.fetchedResultsControllers
            {
                if let theFetchedObjects = fetchedResultsController.fetchedObjects {
                    fetchedObjects += theFetchedObjects
                }
            }
            
            return fetchedObjects
        }
    }
    
    var sections: [NSFetchedResultsSectionInfo]
    {
        get
        {
            var sections = [NSFetchedResultsSectionInfo]()
            
            for fetchedResultsController in self.fetchedResultsControllers
            {
                if let theSections = fetchedResultsController.sections {
                    sections.append(contentsOf: theSections)
                }
            }
            
            return sections
        }
    }
    
    // MARK: Life Cycle Methods
    
    convenience init(fetchRequests: [NSFetchRequest<NSFetchRequestResult>], emptySectionIndexes: [NSNumber], managedObjectContext context: NSManagedObjectContext)
    {
        var fetchedResultsControllers = [NSFetchedResultsController<NSFetchRequestResult>]()
        
        for fetchRequest in fetchRequests
        {
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsControllers.append(fetchedResultsController)
        }
        
        self.init(fetchedResultsControllers: fetchedResultsControllers, emptySectionIndexes: emptySectionIndexes)
    }
    
    required init(fetchedResultsControllers: [NSFetchedResultsController<NSFetchRequestResult>], emptySectionIndexes: [NSNumber]?)
    {
        self.emptyFetchedResultsControllerIndexes = emptySectionIndexes
        
        super.init()
        
        var indexOfCurrentNonEmptyFetchedResultsController = 0
        let totalSections = (fetchedResultsControllers.count + (emptySectionIndexes?.count ?? 0))
        
        for index in 0...(totalSections - 1)
        {
            var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
            
            if (self.emptyFetchedResultsControllerIndexes?.contains(NSNumber(value: index)) ?? false) {
                fetchedResultsController = JPSEmptyFetchedResultsController()
            }
            else {
                fetchedResultsController = fetchedResultsControllers[indexOfCurrentNonEmptyFetchedResultsController]
                indexOfCurrentNonEmptyFetchedResultsController += 1;
            }
            
            fetchedResultsController.delegate = self
            self.fetchedResultsControllers.append(fetchedResultsController)
        }
    }

    // MARK: Private Functions
    
    fileprivate func fetchedResultsController(for section: UInt) -> NSFetchedResultsController<NSFetchRequestResult>?
    {
        var totalSections: UInt = 0
        
        var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?

        for aFetchedResultsController in self.fetchedResultsControllers
        {
            if let count = aFetchedResultsController.sections?.count
            {
                totalSections += UInt(count)
                
                if (section < totalSections)
                {
                    fetchedResultsController = aFetchedResultsController
                    
                    break
                }
            }
        }
        
        return fetchedResultsController
    }
    
    fileprivate func numberOfSections(before fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>) -> Int
    {
        var totalSections = 0
        
        for aFetchedResultsController in self.fetchedResultsControllers
        {
            if (aFetchedResultsController.isEqual(fetchedResultsController)) { break }
            
            if let count = aFetchedResultsController.sections?.count {
                totalSections += count
            }
        }
        
        return totalSections
    }
    
    fileprivate func section(for sectionMask: UInt, in fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>) -> Int
    {
        let numberOfSectionsInFetchedResultsController = UInt(fetchedResultsController.sections!.count)
        let section = (sectionMask % numberOfSectionsInFetchedResultsController)
        
        return Int(section)
    }
    
    fileprivate func masked(indexPath: IndexPath, for fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>) -> IndexPath
    {
        let sectionCount = self.numberOfSections(before: fetchedResultsController)
        
        let maskedSection = (sectionCount + (indexPath as NSIndexPath).section)
        let maskedIndexPath = IndexPath(row: (indexPath as NSIndexPath).row, section: maskedSection)
        
        return maskedIndexPath
    }
    
    // MARK: Public Functions
    
    func performFetch() throws
    {
        for fetchedResultsController in self.fetchedResultsControllers
        {
            if (fetchedResultsController.isKind(of: JPSEmptyFetchedResultsController.self)) { continue }
            
            try fetchedResultsController.performFetch()
        }
    }
    
    func indexPath(for object: NSManagedObject) -> IndexPath?
    {
        var indexPath: IndexPath?
        
        for (_, fetchedResultsController) in self.fetchedResultsControllers.enumerated()
        {
            if (fetchedResultsController.isKind(of: JPSEmptyFetchedResultsController.self)) { continue }
            
            if let anIndexPath = fetchedResultsController.indexPath(forObject: object)
            {
                indexPath = anIndexPath
                
                break
            }
        }
        
        return indexPath
    }
    
    func object(at indexPath: IndexPath) -> AnyObject
    {
        let fetchedResultsController = self.fetchedResultsController(for: UInt((indexPath as NSIndexPath).section))
        
        guard let _ = fetchedResultsController else
        {
            NSException(name: NSExceptionName(rawValue: "Out of Bounds"), reason: "[\(#file) \(#function) (\(#line))] Invalid indexPath.", userInfo: nil).raise()
            
            return 0 as AnyObject
        }
        
        let actualSection = self.section(for: UInt((indexPath as NSIndexPath).section), in: fetchedResultsController!)
        let maskedIndexPath = IndexPath(row: (indexPath as NSIndexPath).row, section: actualSection)
        
        return fetchedResultsController!.object(at: maskedIndexPath)
    }
    
    func numberOfObjects(in section: UInt) -> Int
    {
        let fetchedResultsController = self.fetchedResultsController(for: section)
        
        guard let _ = fetchedResultsController else
        {
            NSException(name: NSExceptionName(rawValue: "Out of Bounds"), reason: "[\(#file) \(#function) (\(#line))] Invalid section.", userInfo: nil).raise()
            
            return 0
        }
        
        let actualSection = self.section(for: section, in: fetchedResultsController!)
        
        return fetchedResultsController!.sections![actualSection].numberOfObjects
    }
    
    func index(of fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>) -> Int
    {
        let index = self.fetchedResultsControllers.index(of: fetchedResultsController)
        
        guard let _ = index else
        {
            NSException(name: NSExceptionName(rawValue: "Invalid fetchedResultsController"), reason: "[\(#file) \(#function) (\(#line))] The fetchedResultsController does not exist.", userInfo: nil).raise()
            
            return 0
        }
        
        return index!
    }
    
    func fetchedResultsController(at index: UInt) -> NSFetchedResultsController<NSFetchRequestResult>?
    {
        if (index >= UInt(self.fetchedResultsControllers.count))
        {
            NSException(name: NSExceptionName(rawValue: "Out of Bounds"), reason: "[\(#file) \(#function) (\(#line))] Invalid index.", userInfo: nil).raise()
            
            return nil
        }
        
        return fetchedResultsControllers[Int(index)]
    }
    
    func insert(fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>, at index: Int)
    {
        fetchedResultsController.delegate = self
        self.fetchedResultsControllers.insert(fetchedResultsController, at: index)
    }
    
    func insert(fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>) {
        self.insert(fetchedResultsController: fetchedResultsController, at: self.fetchedResultsControllers.count)
    }
    
    func replaceFetchedResultsController(at index: Int, with newFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>)
    {
        if (index >= self.fetchedResultsControllers.count) {
            NSException(name: NSExceptionName(rawValue: "Out of Bounds"), reason: "[\(#file) \(#function) (line: \(#line))] Invalid index.", userInfo: nil).raise()
        }
        
        newFetchedResultsController.delegate = self
        self.fetchedResultsControllers[index] = newFetchedResultsController
    }
    
    func replace(fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>, with newFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>)
    {
        let index = self.index(of: fetchedResultsController)
        self.replaceFetchedResultsController(at: index, with: newFetchedResultsController)
    }
    
    func removeFetchedResultsController(at index: Int) {
        self.fetchedResultsControllers.remove(at: index)
    }
    
    func remove(fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>)
    {
        let index = self.index(of: fetchedResultsController)
        self.removeFetchedResultsController(at: index)
    }
}


// MARK: NSFetchedResultsControllerDelegate Methods

extension JPSFetchedResultsCollection: NSFetchedResultsControllerDelegate
{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.delegate?.containerWillChangeContent(self)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.delegate?.containerDidChangeContent(self)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    {
        let maskedSection = (self.numberOfSections(before: controller) + sectionIndex)
        
        self.delegate?.container(self, didChange: sectionInfo, atSectionIndex: maskedSection, for: type)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        var maskedIndexPath: IndexPath?
        
        if let _ = indexPath {
            maskedIndexPath = self.masked(indexPath: indexPath!, for: controller)
        }
        
        var maskedNewIndexPath: IndexPath?
        
        if let _ = newIndexPath {
            maskedNewIndexPath = self.masked(indexPath: newIndexPath!, for: controller)
        }
        
        self.delegate?.container(self, didChange: anObject as AnyObject, at: maskedIndexPath, for: type, newIndexPath: maskedNewIndexPath)
    }
}
