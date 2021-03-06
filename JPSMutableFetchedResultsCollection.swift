//
//  JPSMutableFetchedResultsCollection.swift
//  Just Bucket
//
//  Created by Jonathan Sullivan on 3/10/17.
//  Copyright © 2017 Jonathan Sullivan. All rights reserved.
//

import Foundation

@objc(JPSMutableFetchedResultsCollection)
class JPSMutableFetchedResultsCollection: JPSFetchedResultsCollection
{
    // MARK: NSFetchedResultsController Methods
    
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
        newFetchedResultsController.delegate = self
        self.fetchedResultsControllers[index] = newFetchedResultsController
    }
    
    func replace(fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>, with newFetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>)
    {
        let index = self.fetchedResultsControllers.index(of: fetchedResultsController)
        self.replaceFetchedResultsController(at: index!, with: newFetchedResultsController)
    }
    
    func removeFetchedResultsController(at index: Int) {
        self.fetchedResultsControllers.remove(at: index)
    }
    
    func remove(fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>)
    {
        let index = self.fetchedResultsControllers.index(of: fetchedResultsController)
        self.removeFetchedResultsController(at: index!)
    }
    
    // MARK: -
}
