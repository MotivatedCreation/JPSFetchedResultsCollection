//
//  JPSFetchedResultsContainer.swift
//
//  Created by Jonathan Sullivan on 7/12/16.

import UIKit


// MARK: NSFetchedResultsController Extension

private var isEmptyAssociatedKey = 0

extension NSFetchedResultsController
{
    private var isEmpty: Bool?
    {
        get {
            return objc_getAssociatedObject(self, &isEmptyAssociatedKey) as? Bool
        }
        
        set {
            objc_setAssociatedObject(self, &isEmptyAssociatedKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }

    class func empty() -> NSFetchedResultsController
    {
        let fetchedResultsController = NSFetchedResultsController()
        fetchedResultsController.isEmpty = true
        
        return fetchedResultsController
    }
}

@objc class JPSFechedResultsContainerEmptySectionInfo: NSObject, NSFetchedResultsSectionInfo
{
    var name = "EmptySection"
    var indexTitle: String? = "EmptySection"
    
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
    private var fetchedResultsControllers = [NSFetchedResultsController]()
    
    var delegate: JPSFetchedResultsControllerDelegate?
    
    var fetchedObjects: [AnyObject]
    {
        get
        {
            var theFetchedObjects = [AnyObject]()
            
            for fetchedResultsController in self.fetchedResultsControllers
            {
                guard let fetchedObjects = fetchedResultsController.fetchedObjects else {
                    continue
                }
                
                theFetchedObjects.append(fetchedObjects)
            }
            
            return theFetchedObjects
        }
    }
    
    var sections: [NSFetchedResultsSectionInfo]
    {
        get {
            var theSections = [NSFetchedResultsSectionInfo]()
            
            for aFetchedResultsController in self.fetchedResultsControllers
            {
                if (aFetchedResultsController.isEmpty == true)
                {
                    let emtpySectionInfo = JPSFechedResultsContainerEmptySectionInfo()
                    theSections.append(emtpySectionInfo)
                    
                    continue
                }
                
                if let sections = aFetchedResultsController.sections {
                    theSections.appendContentsOf(sections)
                }
            }
            
            return theSections
        }
    }
    
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
    
    init(fetchedResultsControllers: [NSFetchedResultsController], managedObjectContext context: NSManagedObjectContext)
    {
        super.init()
        
        for fetchedResultsController in fetchedResultsControllers
        {
            fetchedResultsController.delegate = self
            self.fetchedResultsControllers.append(fetchedResultsController)
        }
    }

    private func fetchedResultsControllerForSection(section: UInt) -> NSFetchedResultsController?
    {
        var totalSections: UInt = 0
        
        var fetchedResultsController: NSFetchedResultsController?
        
        for aFetchedResultsController in self.fetchedResultsControllers
        {
            if (aFetchedResultsController.isEmpty == true)
            {
                totalSections += 1
                
                continue
            }
            
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
            
            if (aFetchedResultsController.isEmpty == true)
            {
                totalSections += 1
                
                continue
            }
            
            if let count = aFetchedResultsController.sections?.count {
                totalSections += count
            }
        }
        
        return totalSections
    }
    
    func performFetch() throws
    {
        for fetchedResultsController in self.fetchedResultsControllers
        {
            if (fetchedResultsController.isEmpty == true) { continue }
            
            try fetchedResultsController.performFetch()
        }
    }
    
    func objectAtIndexPath(indexPath: NSIndexPath) -> AnyObject
    {
        let fetchedResultsController = self.fetchedResultsControllerForSection(UInt(indexPath.section))
        
        guard let _ = fetchedResultsController else
        {
            NSException(name: "Out of Bounds", reason: "[\(#file) \(#function) (\(#line))] Invalid indexPath.", userInfo: nil).raise()
            
            return 0
        }
        
        let numberOfSectionsForFetchedResultsController = fetchedResultsController!.sections!.count
        let sectionIndex = (indexPath.section % numberOfSectionsForFetchedResultsController)
        let modifiedIndexPath = NSIndexPath(forRow: indexPath.row, inSection: sectionIndex)
        
        return fetchedResultsController!.objectAtIndexPath(modifiedIndexPath)
    }
    
    func indexPathForObject(object: AnyObject) -> NSIndexPath?
    {
        var indexPath: NSIndexPath?
        
        for fetchedResultsController in self.fetchedResultsControllers
        {
            if (fetchedResultsController.isEmpty == true) { continue }
            
            if let anIndexPath = fetchedResultsController.indexPathForObject(object)
            {
                indexPath = anIndexPath
                
                break
            }
        }
        
        return indexPath
    }
    
    func numberOfObjectsInSection(index: UInt) -> Int
    {
        let fetchedResultsController = self.fetchedResultsControllerForSection(index)
        
        guard let _ = fetchedResultsController else {
            return 0
        }
        
        let numberOfSectionsForFetchedResultsController = UInt(fetchedResultsController!.sections!.count)
        let sectionIndex = Int(index % numberOfSectionsForFetchedResultsController)
        
        return fetchedResultsController!.sections![sectionIndex].numberOfObjects
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
