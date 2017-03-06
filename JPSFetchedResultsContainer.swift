//
//  JPSFetchedResultsContainer.swift
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

private class JPSEmptyFetchedResultsController: NSFetchedResultsController<NSManagedObject>
{
    // MARK: Public Mutable Members
    
    let emptySection = JPSEmptyFetchedResultsSectionInfo()
    
    // MARK: Public Read Only Members
    
    override var sections: [NSFetchedResultsSectionInfo]? {
        get { return [self.emptySection] }
    }
}

// MARK: JPSFetchedResultsContainerDelegate

@objc protocol JPSFetchedResultsContainerDelegate
{
    func containerWillChangeContent(_ container: JPSFetchedResultsContainer)
    func containerDidChangeContent(_ container: JPSFetchedResultsContainer)
    func container(_ container: JPSFetchedResultsContainer, didChange section: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    func container(_ container: JPSFetchedResultsContainer, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
}

// MARK: JPSFetchedResultsController

@objc class JPSFetchedResultsContainer: NSObject
{
    // MARK: Private Mutable Members
    
    private var emptyFetchedResultsControllerIndexes: [NSNumber]?
    
    // MARK: Read Only Members
    
    private(set) var fetchedResultsControllers = [NSFetchedResultsController<NSManagedObject>]()
    
    // MARK: Public Mutable Members
    
    weak var delegate: JPSFetchedResultsContainerDelegate?
    
    // MARK: Public Read Only Members
    
    var fetchedObjects: [AnyObject]
    {
        get
        {
            var fetchedObjects = [NSManagedObject]()
            
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
    
    convenience init(fetchRequests: [NSFetchRequest<NSManagedObject>], emptySectionIndexes: [NSNumber], managedObjectContext context: NSManagedObjectContext)
    {
        var fetchedResultsControllers = [NSFetchedResultsController<NSManagedObject>]()
        
        for fetchRequest in fetchRequests
        {
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsControllers.append(fetchedResultsController)
        }
        
        self.init(fetchedResultsControllers: fetchedResultsControllers, emptySectionIndexes: emptySectionIndexes)
    }
    
    required init(fetchedResultsControllers: [NSFetchedResultsController<NSManagedObject>], emptySectionIndexes: [NSNumber]?)
    {
        self.emptyFetchedResultsControllerIndexes = emptySectionIndexes
        
        super.init()
        
        var indexOfCurrentNonEmptyFetchedResultsController = 0
        let totalSections = (fetchedResultsControllers.count + (emptySectionIndexes?.count ?? 0))
        
        for index in 0...(totalSections - 1)
        {
            var fetchedResultsController: NSFetchedResultsController<NSManagedObject>!
            
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
    
    fileprivate func fetchedResultsControllerForSection(_ section: UInt) -> NSFetchedResultsController<NSManagedObject>?
    {
        var totalSections: UInt = 0
        
        var fetchedResultsController: NSFetchedResultsController<NSManagedObject>?

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
    
    fileprivate func numberOfSectionsBeforeFetchedResultsController(_ fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>) -> Int
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
    
    fileprivate func sectionForSectionMask(_ section: UInt, inFetchedResultsController: NSFetchedResultsController<NSManagedObject>) -> Int
    {
        let numberOfSectionsInFetchedResultsController = UInt(inFetchedResultsController.sections!.count)
        let section = (section % numberOfSectionsInFetchedResultsController)
        
        return Int(section)
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
    
    func indexPathForObject(_ object: NSManagedObject) -> IndexPath?
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
        let fetchedResultsController = self.fetchedResultsControllerForSection(UInt((indexPath as NSIndexPath).section))
        
        guard let _ = fetchedResultsController else
        {
            NSException(name: NSExceptionName(rawValue: "Out of Bounds"), reason: "[\(#file) \(#function) (\(#line))] Invalid indexPath.", userInfo: nil).raise()
            
            return 0 as AnyObject
        }
        
        let actualSection = self.sectionForSectionMask(UInt((indexPath as NSIndexPath).section), inFetchedResultsController: fetchedResultsController!)
        let maskedIndexPath = IndexPath(row: (indexPath as NSIndexPath).row, section: actualSection)
        
        return fetchedResultsController!.object(at: maskedIndexPath)
    }
    
    func numberOfObjectsInSection(_ section: UInt) -> Int
    {
        let fetchedResultsController = self.fetchedResultsControllerForSection(section)
        
        guard let _ = fetchedResultsController else
        {
            NSException(name: NSExceptionName(rawValue: "Out of Bounds"), reason: "[\(#file) \(#function) (\(#line))] Invalid section.", userInfo: nil).raise()
            
            return 0
        }
        
        let actualSection = self.sectionForSectionMask(section, inFetchedResultsController: fetchedResultsController!)
        
        return fetchedResultsController!.sections![actualSection].numberOfObjects
    }
    
    func indexOfFetchedResultsController(_ fetchedResultsController: NSFetchedResultsController<NSManagedObject>) -> Int
    {
        let index = self.fetchedResultsControllers.index(of: fetchedResultsController)
        
        guard let _ = index else
        {
            NSException(name: NSExceptionName(rawValue: "Invalid fetchedResultsController"), reason: "[\(#file) \(#function) (\(#line))] The fetchedResultsController does not exist.", userInfo: nil).raise()
            
            return 0
        }
        
        return index!
    }
    
    func fetchedResultsControllerAtIndex(_ index: UInt) -> NSFetchedResultsController<NSManagedObject>?
    {
        if (index >= UInt(self.fetchedResultsControllers.count))
        {
            NSException(name: NSExceptionName(rawValue: "Out of Bounds"), reason: "[\(#file) \(#function) (\(#line))] Invalid index.", userInfo: nil).raise()
            
            return nil
        }
        
        return fetchedResultsControllers[Int(index)]
    }
    
    func insertFetchedResultsControllerAtIndex(_ fetchedResultsController: NSFetchedResultsController<NSManagedObject>, atIndex: Int)
    {
        fetchedResultsController.delegate = self
        self.fetchedResultsControllers.insert(fetchedResultsController, at: atIndex)
    }
    
    func replaceFetchedResultsControllerAtIndex(_ index: Int, withFetchedResultsController: NSFetchedResultsController<NSManagedObject>)
    {
        if (index >= self.fetchedResultsControllers.count) {
            NSException(name: NSExceptionName(rawValue: "Out of Bounds"), reason: "[\(#file) \(#function) (line: \(#line))] Invalid index.", userInfo: nil).raise()
        }
        
        withFetchedResultsController.delegate = self
        self.fetchedResultsControllers[index] = withFetchedResultsController
    }
    
    func replaceFetchedResultsController(_ fetchedResultsController: NSFetchedResultsController<NSManagedObject>, withFetchedResultsController: NSFetchedResultsController<NSManagedObject>)
    {
        let index = self.indexOfFetchedResultsController(fetchedResultsController)
        self.replaceFetchedResultsControllerAtIndex(index, withFetchedResultsController: withFetchedResultsController)
    }
    
    func removeFetchedResultsControllerAtIndex(_ index: Int) {
        self.fetchedResultsControllers.remove(at: index)
    }
    
    func removeFetchedResultsController(_ fetchedResultsController: NSFetchedResultsController<NSManagedObject>)
    {
        let index = self.indexOfFetchedResultsController(fetchedResultsController)
        self.removeFetchedResultsControllerAtIndex(index)
    }
}


// MARK: NSFetchedResultsControllerDelegate Methods

extension JPSFetchedResultsContainer: NSFetchedResultsControllerDelegate
{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.delegate?.containerWillChangeContent(self)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.delegate?.containerDidChangeContent(self)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    {
        let maskedSection = self.numberOfSectionsBeforeFetchedResultsController(controller) + sectionIndex
        
        self.delegate?.container(self, didChange: sectionInfo, atSectionIndex: maskedSection, for: type)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
    {
        let sectionCount = self.numberOfSectionsBeforeFetchedResultsController(controller)
        
        var maskedSection: Int?
        var maskedIndexPath: IndexPath?
        
        if let _ = indexPath {
            maskedSection = (sectionCount + (indexPath! as NSIndexPath).section)
            maskedIndexPath = IndexPath(row: (indexPath! as NSIndexPath).row, section: maskedSection!)
        }
        
        var maskedNewSection: Int?
        var maskedNewIndexPath: IndexPath?
        
        if let _ = newIndexPath {
            maskedNewSection = (sectionCount + (newIndexPath! as NSIndexPath).section)
            maskedNewIndexPath = IndexPath(row: (newIndexPath! as NSIndexPath).row, section: maskedNewSection!)
        }
        
        self.delegate?.container(self, didChange: anObject as AnyObject, at: maskedIndexPath, for: type, newIndexPath: maskedNewIndexPath)
    }
}
