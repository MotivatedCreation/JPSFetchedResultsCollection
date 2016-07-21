//
//  JPSFetchedResultsContainer.swift
//
//  Created by Jonathan Sullivan on 7/12/16.

import UIKit


// MARK: JPSEmptyFetchedResultsSectionInfo

@objc class JPSEmptyFetchedResultsSectionInfo: NSObject, NSFetchedResultsSectionInfo
{
    // MARK: Public Mutable Members
    
    var name = ""
    var indexTitle: String?
    
    // MARK: Public Read Only Members
    
    var numberOfObjects: Int
    {
        get {
            return 0
        }
    }
    
    var objects: [AnyObject]?
    {
        get {
            return nil
        }
    }
}

// MARK: JPSEmptyFetchedResultsController

@objc class JPSEmptyFetchedResultsController: NSFetchedResultsController
{
    // MARK: Public Mutable Members
    
    let emptySection = JPSEmptyFetchedResultsSectionInfo()
    
    // MARK: Public Read Only Members
    
    override var sections: [NSFetchedResultsSectionInfo]?
    {
        get {
            return [self.emptySection]
        }
    }
}

// MARK: JPSFetchedResultsControllerDelegate

@objc protocol JPSFetchedResultsControllerDelegate
{
    func containerWillChangeContent(container: JPSFetchedResultsContainer)
    func containerDidChangeContent(container: JPSFetchedResultsContainer)
    func container(container: JPSFetchedResultsContainer, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)
    func container(container: JPSFetchedResultsContainer, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
}

// MARK: JPSFetchedResultsController

@objc class JPSFetchedResultsContainer: NSObject
{
    // MARK: Private Mutable Members
    
    private var fetchedResultsControllers = [NSFetchedResultsController]()
    
    // MARK: Public Mutable Members
    
    var delegate: JPSFetchedResultsControllerDelegate?
    
    // MARK: Public Read Only Members
    
    var fetchedObjects: [AnyObject]
    {
        get
        {
            var theFetchedObjects = [AnyObject]()
            
            for fetchedResultsController in self.fetchedResultsControllers
            {
                if let fetchedObjects = fetchedResultsController.fetchedObjects {
                    theFetchedObjects.append(fetchedObjects)
                }
            }
            
            return theFetchedObjects
        }
    }
    
    var sections: [NSFetchedResultsSectionInfo]
    {
        get
        {
            var theSections = [NSFetchedResultsSectionInfo]()
            
            for fetchedResultsController in self.fetchedResultsControllers
            {
                if let sections = fetchedResultsController.sections {
                    theSections.appendContentsOf(sections)
                }
            }
            
            return theSections
        }
    }
    
    // MARK: Life Cycle Methods
    
    init(fetchRequests: [NSFetchRequest], managedObjectContext context: NSManagedObjectContext)
    {
        super.init()
        
        for fetchRequest in fetchRequests
        {
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController.delegate = self
            self.fetchedResultsControllers.append(fetchedResultsController)
        }
    }
    
    init(fetchedResultsControllers: [NSFetchedResultsController])
    {
        super.init()
        
        for fetchedResultsController in fetchedResultsControllers
        {
            fetchedResultsController.delegate = self
            self.fetchedResultsControllers.append(fetchedResultsController)
        }
    }

    // MARK: Private Functions
    
    private func fetchedResultsControllerForSection(section: UInt) -> NSFetchedResultsController?
    {
        var totalSections: UInt = 0
        
        var fetchedResultsController: NSFetchedResultsController?
        
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
    
    private func numberOfSectionsBeforeFetchedResultsController(fetchedResultsController: NSFetchedResultsController) -> Int
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
    
    private func sectionMaskForSection(section: UInt, inFetchedResultsController: NSFetchedResultsController) -> Int
    {
        let numberOfSectionsForFetchedResultsController = UInt(inFetchedResultsController.sections!.count)
        let sectionMask = (section % numberOfSectionsForFetchedResultsController)
        
        return Int(sectionMask)
    }
    
    // MARK: Public Functions
    
    func performFetch() throws
    {
        for fetchedResultsController in self.fetchedResultsControllers
        {
            if (fetchedResultsController.isKindOfClass(JPSEmptyFetchedResultsController.self)) { continue }
            
            try fetchedResultsController.performFetch()
        }
    }
    
    func indexPathForObject(object: AnyObject) -> NSIndexPath?
    {
        var indexPath: NSIndexPath?
        
        for fetchedResultsController in self.fetchedResultsControllers
        {
            if (fetchedResultsController.isKindOfClass(JPSEmptyFetchedResultsController.self)) { continue }
            
            if let anIndexPath = fetchedResultsController.indexPathForObject(object)
            {
                indexPath = anIndexPath
                
                break
            }
        }
        
        return indexPath
    }
    
    func objectAtIndexPath(indexPath: NSIndexPath) -> AnyObject
    {
        let fetchedResultsController = self.fetchedResultsControllerForSection(UInt(indexPath.section))
        
        guard let _ = fetchedResultsController else
        {
            NSException(name: "Out of Bounds", reason: "[\(#file) \(#function) (\(#line))] Invalid indexPath.", userInfo: nil).raise()
            
            return 0
        }
        
        let sectionMask = self.sectionMaskForSection(UInt(indexPath.section), inFetchedResultsController: fetchedResultsController!)
        let modifiedIndexPath = NSIndexPath(forRow: indexPath.row, inSection: sectionMask)
        
        return fetchedResultsController!.objectAtIndexPath(modifiedIndexPath)
    }
    
    func numberOfObjectsInSection(section: UInt) -> Int
    {
        let fetchedResultsController = self.fetchedResultsControllerForSection(section)
        
        guard let _ = fetchedResultsController else {
            
            NSException(name: "Out of Bounds", reason: "[\(#file) \(#function) (\(#line))] Invalid section.", userInfo: nil).raise()
            
            return 0
        }
        
        let sectionMask = self.sectionMaskForSection(section, inFetchedResultsController: fetchedResultsController!)
        
        return fetchedResultsController!.sections![sectionMask].numberOfObjects
    }
    
    func replaceFetchedResultsControllerAtIndex(index: Int, withFetchedResultsController: NSFetchedResultsController)
    {
        withFetchedResultsController.delegate = self
        
        self.fetchedResultsControllers[index] = withFetchedResultsController
    }
    
    func replaceFetchedResultsController(fetchedResultsController: NSFetchedResultsController, withFetchedResultsController: NSFetchedResultsController)
    {
        let indexOfFetchedResultsController = self.fetchedResultsControllers.indexOf(fetchedResultsController)
        
        guard let _ = indexOfFetchedResultsController else {
            return
        }
        
        self.replaceFetchedResultsControllerAtIndex(indexOfFetchedResultsController!, withFetchedResultsController: withFetchedResultsController)
    }
}


// MARK: NSFetchedResultsControllerDelegate Methods

extension JPSFetchedResultsContainer: NSFetchedResultsControllerDelegate
{
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.delegate?.containerWillChangeContent(self)
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.delegate?.containerDidChangeContent(self)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)
    {
        let modifiedSectionIndex = self.numberOfSectionsBeforeFetchedResultsController(controller) + sectionIndex
        
        self.delegate?.container(self, didChangeSection: sectionInfo, atIndex: modifiedSectionIndex, forChangeType: type)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        let sectionCount = self.numberOfSectionsBeforeFetchedResultsController(controller)
        
        var modifiedSection: Int?
        var modifiedIndexPath: NSIndexPath?
        
        if let _ = indexPath {
            modifiedSection = sectionCount + indexPath!.section
            modifiedIndexPath = NSIndexPath(forRow: indexPath!.row, inSection: modifiedSection!)
        }
        
        var modifiedNewSection: Int?
        var modifiedNewIndexPath: NSIndexPath?
        
        if let _ = newIndexPath {
            modifiedNewSection = sectionCount + newIndexPath!.section
            modifiedNewIndexPath = NSIndexPath(forRow: newIndexPath!.row, inSection: modifiedNewSection!)
        }
        
        self.delegate?.container(self, didChangeObject: anObject, atIndexPath: modifiedIndexPath, forChangeType: type, newIndexPath: modifiedNewIndexPath)
    }
}
