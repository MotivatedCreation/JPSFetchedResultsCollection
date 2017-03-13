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

@objc(JPSFetchedResultsCollectionDelegate)
protocol JPSFetchedResultsCollectionDelegate
{
    @objc optional func collectionWillChangeContent(_ collection: JPSFetchedResultsCollection)
    @objc optional func collectionDidChangeContent(_ collection: JPSFetchedResultsCollection)
    @objc optional func collection(_ collection: JPSFetchedResultsCollection, didChange section: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    @objc optional func collection(_ collection: JPSFetchedResultsCollection, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
}

// MARK: JPSFetchedResultsController

@objc(JPSFetchedResultsCollection)
class JPSFetchedResultsCollection: NSObject
{
    // MARK: Read Only Members
    
    internal(set) var emptyFetchedResultsControllerIndexes: NSIndexSet?
    internal(set) var fetchedResultsControllers = [NSFetchedResultsController<NSFetchRequestResult>]()
    
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
    
    var fetchRequests: [NSFetchRequest<NSFetchRequestResult>]
    {
        get
        {
            var fetchRequests = [NSFetchRequest<NSFetchRequestResult>]()
            
            for fetchedResultsController in self.fetchedResultsControllers {
                fetchRequests.append(fetchedResultsController.fetchRequest)
            }
            
            return fetchRequests
        }
    }
    
    var managedObjectContexts: [NSManagedObjectContext]
    {
        get
        {
            var managedObjectContexts = [NSManagedObjectContext]()
            
            for fetchedResultsController in self.fetchedResultsControllers {
                managedObjectContexts.append(fetchedResultsController.managedObjectContext)
            }
            
            return managedObjectContexts
        }
    }
    
    var sectionNameKeyPaths: [String]?
    {
        get
        {
            var sectionNameKeyPaths: [String]?
            
            for fetchedResultsController in self.fetchedResultsControllers
            {
                if let sectionNameKeyPath = fetchedResultsController.sectionNameKeyPath
                {
                    if sectionNameKeyPaths == nil {
                        sectionNameKeyPaths = [String]()
                    }
                    
                    sectionNameKeyPaths!.append(sectionNameKeyPath)
                }
            }
            
            return sectionNameKeyPaths
        }
    }
    
    var cacheNames: [String]?
    {
        get
        {
            var cacheNames: [String]?
            
            for fetchedResultsController in self.fetchedResultsControllers
            {
                if let cacheName = fetchedResultsController.cacheName
                {
                    if cacheNames == nil {
                        cacheNames = [String]()
                    }
                    
                    cacheNames!.append(cacheName)
                }
            }
            
            return cacheNames
        }
    }
    
    var sectionIndexTitles: [String]
    {
        get
        {
            var sectionIndexTitles = [String]()
            
            for fetchedResutlsController in self.fetchedResultsControllers {
                sectionIndexTitles.append(contentsOf: fetchedResutlsController.sectionIndexTitles)
            }
            
            return sectionIndexTitles
        }
    }
    
    // MARK: Life Cycle Methods
    
    required init(with fetchedResultsControllers: [NSFetchedResultsController<NSFetchRequestResult>], emptySectionIndexes: NSIndexSet?)
    {
        super.init()
        
        self.emptyFetchedResultsControllerIndexes = emptySectionIndexes
        
        var indexOfCurrentNonEmptyFetchedResultsController = 0
        let totalSections = (fetchedResultsControllers.count + (emptySectionIndexes?.count ?? 0))
        
        for index in 0...(totalSections - 1)
        {
            var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
            
            if (self.emptyFetchedResultsControllerIndexes?.contains(index) ?? false) {
                fetchedResultsController = JPSEmptyFetchedResultsController()
            }
            else {
                fetchedResultsController = fetchedResultsControllers[indexOfCurrentNonEmptyFetchedResultsController]
                fetchedResultsController.delegate = self
                
                indexOfCurrentNonEmptyFetchedResultsController += 1
            }
            
            self.fetchedResultsControllers.append(fetchedResultsController)
        }
    }
    
    convenience init(with fetchRequests: [NSFetchRequest<NSFetchRequestResult>], emptySectionIndexes: NSIndexSet?, managedObjectContext context: NSManagedObjectContext)
    {
        var fetchedResultsControllers = [NSFetchedResultsController<NSFetchRequestResult>]()
        
        for fetchRequest in fetchRequests
        {
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsControllers.append(fetchedResultsController)
        }
        
        self.init(with: fetchedResultsControllers, emptySectionIndexes: emptySectionIndexes)
    }

    // MARK: Factory Methods
    
    class func collection(with fetchedResultsControllers: [NSFetchedResultsController<NSFetchRequestResult>], emptySectionIndexes: NSIndexSet?) -> JPSFetchedResultsCollection
    {
        let collection = JPSFetchedResultsCollection(with: fetchedResultsControllers, emptySectionIndexes: emptySectionIndexes)
        
        return collection
    }
    
    class func collection(with fetchRequests: [NSFetchRequest<NSFetchRequestResult>], emptySectionIndexes: NSIndexSet?, managedObjectContext context: NSManagedObjectContext) -> JPSFetchedResultsCollection
    {
        let collection = JPSFetchedResultsCollection(with: fetchRequests, emptySectionIndexes: emptySectionIndexes, managedObjectContext: context)
        
        return collection
    }
    
    // MARK: Private Functions
    
    internal func numberOfSections(before fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>) -> Int
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
    
    internal func unmaskedSectionIndex(for sectionIndexMask: Int, in fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>) -> Int
    {
        let numberOfSectionsInFetchedResultsController = fetchedResultsController.sections!.count
        let section = (sectionIndexMask % numberOfSectionsInFetchedResultsController)
        
        return section
    }
    
    internal func masked(sectionIndex: Int, for fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>) -> Int
    {
        let maskedSectionIndex = (self.numberOfSections(before: fetchedResultsController) + sectionIndex)
        
        return maskedSectionIndex
    }
    
    internal func masked(indexPath: IndexPath, for fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>) -> IndexPath
    {
        let sectionCount = self.numberOfSections(before: fetchedResultsController)
        
        let maskedSectionIndex = (sectionCount + indexPath.section)
        let maskedIndexPath = IndexPath(row: indexPath.row, section: maskedSectionIndex)
        
        return maskedIndexPath
    }
    
    // MARK: Public Methods
    
    func performFetch() throws
    {
        for fetchedResultsController in self.fetchedResultsControllers
        {
            if (fetchedResultsController.isKind(of: JPSEmptyFetchedResultsController.self)) { continue }
            
            try fetchedResultsController.performFetch()
        }
    }
    
    // MARK: Fetched Results Controller Methods
    
    func fetchedResultsController(for sectionIndex: Int) -> NSFetchedResultsController<NSFetchRequestResult>?
    {
        var totalSections = 0
        
        var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
        
        for aFetchedResultsController in self.fetchedResultsControllers
        {
            if let count = aFetchedResultsController.sections?.count
            {
                totalSections += count
                
                if (sectionIndex < totalSections)
                {
                    fetchedResultsController = aFetchedResultsController
                    
                    break
                }
            }
        }
        
        return fetchedResultsController
    }
    
    // MARK: Section Methods
    
    func numberOfObjects(in sectionIndex: Int) -> Int
    {
        let fetchedResultsController = self.fetchedResultsController(for: sectionIndex)
        let unmaskedSectionIndex = self.unmaskedSectionIndex(for: sectionIndex, in: fetchedResultsController!)
        
        return fetchedResultsController!.sections![unmaskedSectionIndex].numberOfObjects
    }
    
    func section(forSectionIndexTitle title: String, at sectionIndex: Int) -> Int
    {
        let fetchedResultsController = self.fetchedResultsController(for: sectionIndex)
        let unmaskedSectionIndex = self.unmaskedSectionIndex(for: sectionIndex, in: fetchedResultsController!)
        
        return fetchedResultsController!.section(forSectionIndexTitle: title, at: unmaskedSectionIndex)
    }
    
    func sectionIndexTitle(forSectionName sectionName: String) -> String?
    {
        var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
        
        for aFetchedResultsController in self.fetchedResultsControllers
        {
            let doesContainSectionName = aFetchedResultsController.sections?.contains(where: {
                (section: NSFetchedResultsSectionInfo) -> Bool in
                
                return (section.name == sectionName)
            })
            
            if (doesContainSectionName ?? false)
            {
                fetchedResultsController = aFetchedResultsController
                
                break
            }
        }
        
        return fetchedResultsController?.sectionIndexTitle(forSectionName: sectionName)
    }
    
    // MARK: NSFetchRequestResult Methods
    
    func indexPath(for object: NSManagedObject) -> IndexPath?
    {
        var indexPath: IndexPath?
        
        for fetchedResultsController in self.fetchedResultsControllers
        {
            if (fetchedResultsController.isKind(of: JPSEmptyFetchedResultsController.self)) { continue }
            
            if object.entity.name == fetchedResultsController.fetchRequest.entityName
            {
                indexPath = fetchedResultsController.indexPath(forObject: object)
                
                break
            }
        }
        
        return indexPath
    }
    
    func object(at indexPath: IndexPath) -> AnyObject
    {
        let fetchedResultsController = self.fetchedResultsController(for: indexPath.section)
        
        let unmaskedSectionIndex = self.unmaskedSectionIndex(for: indexPath.section, in: fetchedResultsController!)
        let unmaskedIndexPath = IndexPath(row: indexPath.row, section: unmaskedSectionIndex)
        
        return fetchedResultsController!.object(at: unmaskedIndexPath)
    }
}

// MARK: NSMutableCopying

extension JPSFetchedResultsCollection: NSMutableCopying
{
    func mutableCopy(with zone: NSZone? = nil) -> Any
    {
        let mutableCopy = JPSMutableFetchedResultsCollection(with: self.fetchedResultsControllers, emptySectionIndexes: self.emptyFetchedResultsControllerIndexes)
        
        return mutableCopy
    }
}

// MARK: NSFetchedResultsControllerDelegate Methods

extension JPSFetchedResultsCollection: NSFetchedResultsControllerDelegate
{
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.delegate?.collectionWillChangeContent?(self)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.delegate?.collectionDidChangeContent?(self)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
    {
        let maskedSectionIndex = self.masked(sectionIndex: sectionIndex, for: controller)
        self.delegate?.collection?(self, didChange: sectionInfo, atSectionIndex: maskedSectionIndex, for: type)
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
        
        self.delegate?.collection?(self, didChange: anObject as AnyObject, at: maskedIndexPath, for: type, newIndexPath: maskedNewIndexPath)
    }
}
