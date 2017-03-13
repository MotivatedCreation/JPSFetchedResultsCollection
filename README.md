### JPSFetchedResultsCollection
A **NSFetchedResulterController** collection that can be used to fetch multiple entity types. With this collection, you can still take advantage of the benefits that each individual **NSFetchedResultsController** offers such as, sections, caching, etc. In essence, the collection acts as a wrapper for multiple **NSFetchedResultsControllers** and provides a familiar API to obtain information about the fetched data. **JPSFetchedResultsCollection** does the aforementioned through the use of object composition.

### Theoretical Structure
If you think of the container as a tree, the collection is the root node. The immediate children of the root node are the **NSFetchedResultsControllers**. The children of the **NSFetchedResultsControllers** are their sections and the children of the sections are the rows. However, the **NSFetchedResultsController** level is treated as transparent. This means that all of the sections in each **NSFetchedResultsController** are **assumed** to be in the same **NSFetchedResultsController**. Therefore, the sections are **assumed** or **masked** to be indexed consecutively. On the other hand, empty **NSFetchedResultsControllers** are treated as sections and are indexed.

## Basic Usage

#### 1. Instantiate a JPSFetchedResultsCollection

```
let fetchRequest = <# NSManagedObject #>.fetchRequest()
fetchRequest.sortDescriptors = [<# NSSortDescriptor #>]
fetchRequest.predicate = <# NSPredicate #>
    
let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: <# NSManagedObjectContext #>, sectionNameKeyPath: <# sectionNameKeyPath #>, cacheName: <# cacheName #>)

let collection = JPSFetchedResultsCollection(with: [fetchedResultsController])
collection.delegate = self
```

#### 2. Fetch the NSManagedObjects

```
collection.performFetch()
```

#### 3. Respond to changes

```
func collectionWillChangeContent(_ collection: JPSFetchedResultsCollection) {
    self.tableView.beginUpdates()
}
    
func collection(_ collection: JPSFetchedResultsCollection, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?)
{
    switch (type)
    {
    case .insert:
        self.tableView.insertRows(at: [newIndexPath!], with: .automatic)
            
    case .delete:
        self.tableView.deleteRows(at: [indexPath!], with: .automatic)
            
    case .update:
        self.tableView.reloadRows(at: [indexPath!], with: .automatic)
            
    default:
        self.tableView.reloadData()
    }
}
    
func collection(_ collection: JPSFetchedResultsCollection, didChange section: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType)
{
    switch (type)
    {
    case .insert:
        self.tableView.insertSections([sectionIndex], with: .automatic)
            
    case .delete:
        self.tableView.deleteSections([sectionIndex], with: .automatic)
            
    case .update:
        self.tableView.reloadSections([sectionIndex], with: .automatic)
            
    default:
        self.tableView.reloadData()
    }
}
    
func collectionDidChangeContent(_ collection: JPSFetchedResultsCollection) {
    self.tableView.endUpdates()
}
```
