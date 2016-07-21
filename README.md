# JPSFetchedResultsContainer
A NSFetchedResulterController container that can be used to fetch multiple entity types. With this container, you can still take advantage of the benefits that each individual NSFetchedResultsController offers such as, sections, caching, etc. In essence, the contains acts as a wrapper for multiple NSFetchedResultsControllers and provides a familiar API to obtain information. JPSFetchedResultsContainer does the aforementioned through the use of object composition.

# Theoretical Structure
If you think of the container as a tree, the container is the root node. The immediate children of the root node are the NSFetchedResultsControllers. The children of the NSFetchedResultsControllers are their sections and the children of the sections are the rows. However, the NSFetchedResultsController level is treated as transparent. This means that all of the sections in each NSFetchedResultsController are **assumed** to be in the same NSFetchedResultsController. Therefore, the sections are **assumed** to be indexed consecutively. On the other hand, empty NSFetchedResultsControllers are treated as sections and are indexed.

# Usage

### Allocating a Container
Allocate an instance of the JPSFetchedResultsContainer using either NSFetchedResultsControllers or NSFetchRequests. The order of the NSFetchedResultsControllers or NSFetchRequests in the array determines the order of the entity sections.

```
let fetchedResultsContainer = JPSFetchedResultsContainer(fetchedResultsControllers: [...], managedObjectContext: context)
fetchedResultsController.delegate = self
```

**OR**

```
let fetchedResultsContainer = JPSFetchedResultsContainer(fetchRequests: [...], managedObjectContext: context)
fetchedResultsController.delegate = self
```
--

### Delegate
Assign a delegate to monitor changes to the JPSFetchedResultsContainer. Thus, allowing you to change your view accordingly.
```
func containerWillChangeContent(container: JPSFetchedResultsContainer)

func containerDidChangeContent(container: JPSFetchedResultsContainer)

func container(container: JPSFetchedResultsContainer, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType)

func container(container: JPSFetchedResultsContainer, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
```
--
### Empty Sections
Create empty sections by adding a JPSEmptyFetchedResultsController to the array passed in to the constructor. JPSEmptyFetchedResultsController contains a custom object called JPSEmptyFetchedResultsSectionInfo that conforms to NSFetchedResultsSectionInfo. This way you can give the empty section a name, indexTitle, etc.
```
let emptyFetchedResultsController = JPSEmptyFetchedResultsController()
emptyFetchedResultsController.emptySection.name = "Empty Section"
emptyFetchedResultsController.emptySection.indexTitle = "Empty Index Title"
```
--
### Fetching
Fetch objects from Core Data the same way as a NSFetchedResultsController.
```
fetchedResultsContainer.performFetch()
```
--
### Obtaining objects
Obtain objects from a section the same way as a NSFetchedResultsController.
```
let indexPath = NSIndexPath(...)
fetchedResultsContainer.objectAtIndexPath(indexPath)
```

**OR**

```
let managedObject = ...
fetchedResultsContainer.indexPathForObject(managedObject)
```
--
### Obtaining Number of Objects per Section
```
let section = 0
fetchedResultsContainer.numberOfObjectsInSection(section)
```

**OR**

```
let section = 0
fetchedResultsContainer.sections[section].numberOfObjects
```
--
### Managing FetchedResultsControllers

#### Obtaining FetchedResultsControllers
```
let aFetchedResultsController = ...
let index = fetchedResultsContainer.indexOfFetchedResultsController(aFetchedResultsController)
```

**OR**

```
let index = 0
let aFetchedResultsController = fetchedResultsContainer.fetchedResultsControllerAtIndex(index)
```

#### Inserting FetchedResultsControllers

```
let index = 0
let aFetchedResultsController = ...
fetchedResultsContainer.insertFetchedResultsControllerAtIndex(aFetchedResultsController, atIndex: index)
```

#### Replacing FetchedResultsControllers
Replace NSFetchedResultsControllers when you want to change specific or all sections for an entity.
```
let index = 0
let withFetchedResultsController = ...
fetchedResultsContainer.replaceFetchedResultsControllerAtIndex(index, withFetchedResultsController: withFetchedResultsController)
fetchedResultsContainer.performFetch()
```

**OR**

```
let aFetchedResultsController = ...
let withFetchedResultsController = ...
fetchedResultsContainer.replaceFetchedResultsController(aFetchedResultsController, withFetchedResultsController: withFetchedResultsController)
fetchedResultsContainer.performFetch()
```

#### Removing FetchedResultsControllers
Remove NSFetchedResultsControllers when you want to remove specific or all sections for an entity.
```
let aFetchedResultsController = ...
fetchedResultsContainer.removeFetchedResultsController(aFetchedResultsController)
```

**OR**

```
let index = 0
fetchedResultsContainer.removeFetchedResultsControllerAtIndex(index)
```
