# JPSFetchedResultsContainer
A NSFetchedResulterController container that can be used to fetch multiple entity types. With this container, you can still take advantage of the benefits that each individual NSFetchedResultsController offers such as, sections, caching, etc. In essence, the contains acts as a wrapper for multiple NSFetchedResultsControllers and provides a familiar API to obtain information.

# Theoretical Structure
If you think of the container as a tree, the container is the root node. The immediate children of the root node are the NSFetchedResultsControllers. The children of the NSFetchedResultsControllers are their sections and the children of the sections are the rows. However, the NSFetchedResultsController level is treated as transparent. This means that all of the sections in each NSFetchedResultsController are treated as being in the same NSFetchedResultsController. Therefore, the sections are **assumed** to be indexed consecutively.

# Usage

**NOTE: The order of the NSFetchedResultsControllers in the array passed in to the constructor determines the order of the sections. The same goes for the NSFetchRequests.**

### Allocating a Container
```let fetchedResultsContainer = JPSFetchedResultsContainer(fetchedResultsControllers: [...], managedObjectContext: context)
fetchedResultsController.delegate = self;```

**OR**

`let fetchedResultsContainer = JPSFetchedResultsContainer(fetchRequests: [...], managedObjectContext: context)`<br />
`fetchedResultsController.delegate = self;`

### Delegate
`func containerWillChangeContent(container: JPSFetchedResultsContainer)`

`func containerDidChangeContent(container: JPSFetchedResultsContainer)`

`func container(container: JPSFetchedResultsContainer, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)`

`func container(container: JPSFetchedResultsContainer, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)`

### Empty Sections
`NSFetchedResultsController.empty()`

### Fetching
`fetchedResultsContainer.performFetch()`

### Obtaining objects
`let indexPath = NSIndexPath(...)` <br />
`fetchedResultsContainer.objectAtIndexPath(indexPath)`

`let managedObject = ...` <br />
`fetchedResultsContainer.indexPathForObject(managedObject)`

### Obtaining Number of Objects per Section
`let section = 0` <br />
`fetchedResultsContainer.numberOfObjectsInSection(section)`

### Changing FetchedResultsControllers

`let index = 0` <br />
`let withFetchedResultsController = ...` <br />
`fetchedResultsContainer.replaceFetchedResultsControllerAtIndex(index, withFetchedResultsController: withFetchedResultsController)`

**OR**

`let aFetchedResultsController = ...` <br />
`let withFetchedResultsController = ...` <br />
`fetchedResultsContainer.replaceFetchedResultsControllerAtIndex(aFetchedResultsController, withFetchedResultsController: withFetchedResultsController)`
