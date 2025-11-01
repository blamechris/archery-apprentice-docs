---
tags:
  - code-graph
  - viewmodels
  - equipment
  - state-management
created: 2025-10-08
related:
  - "[[Architecture-Overview]]"
  - "[[Equipment-Repositories]]"
  - "[[Key-Patterns]]"
---

# Equipment ViewModels

Equipment ViewModels manage the state and business logic for equipment component forms and lists. All follow the same architectural pattern for consistency.

**Location**: `app/src/main/java/com/archeryapprentice/ui/equipment/viewModels/`

---

## Architecture Pattern

All equipment ViewModels follow this structure:

```kotlin
class ComponentViewModel(private val repository: ComponentRepository) : ViewModel() {
    // 1. Observable state for list
    private val _items = MutableStateFlow<List<Component>>(emptyList())
    val items: StateFlow<List<Component>> = _items.asStateFlow()
    
    // 2. Input state for forms
    private val _inputState = MutableStateFlow(ComponentInputState())
    val inputState: StateFlow<ComponentInputState> = _inputState.asStateFlow()
    
    // 3. CRUD operations
    init { loadItems() }
    suspend fun saveComponent(): SaveResult
    fun deleteComponent(component: Component)
    fun loadComponentForEdit(id: Long)
    fun clearInputs()
    
    // 4. Field update methods
    fun updateBrand(value: String)
    fun updateModel(value: String)
    // ... other fields
}
```

---

## Component ViewModels

### ArrowViewModel

**File**: `componentViewModels/ArrowViewModel.kt`
**Repository**: [[Equipment-Repositories#ArrowRepository]]

#### State Management
```kotlin
data class ArrowInputState(
    val brand: String = "",
    val model: String = "",
    val length: String = "",
    val weight: String = "",
    val diameter: String = "",
    val spine: String = "",
    val quantity: String = "1",
    val identifier: String = "",
    val pointName: String = "",
    val pointWeight: String = "",
    val nockName: String = "",
    val nockWeight: String = "",
    val notes: String = "",
    val isEditing: Boolean = false,
    val editingId: Long = 0
)
```

#### Key Methods
- `suspend fun saveArrow(): SaveResult` - Save/update arrow
- `fun deleteArrow(arrow: Arrow)` - Delete arrow
- `fun loadArrowForEdit(id: Long)` - Load for editing
- `fun toArrow(state: ArrowInputState): Arrow` - Convert state to entity

#### Field Updates
- `updateBrand(value: String)`
- `updateModel(value: String)`
- `updateLength(value: String)`
- `updateWeight(value: String)`
- `updateDiameter(value: String)`
- `updateSpine(value: String)`
- `updateQuantity(value: String)`
- `updateIdentifier(value: String)`
- `updatePointName(value: String)`
- `updatePointWeight(value: String)`
- `updateNockName(value: String)`
- `updateNockWeight(value: String)`
- `updateNotes(value: String)`

#### Validation
```kotlin
fun isValid(state: ArrowInputState): Boolean {
    return state.brand.isNotBlank() && state.model.isNotBlank()
}

fun getValidationError(): String? = when {
    brand.isBlank() -> "Brand is required"
    model.isBlank() -> "Model is required"
    else -> null
}
```

**Pattern**: [[Key-Patterns#SaveResult-Pattern]]

---

### StabilizerViewModel

**File**: `componentViewModels/StabilizerViewModel.kt`
**Repository**: [[Equipment-Repositories#StabilizerRepository]]

#### State Management
```kotlin
data class StabilizerInputState(
    val brand: String = "",
    val model: String = "",
    val length: String = "",
    val weight: String = "",
    val straightness: String = "5",  // 1-10 scale
    val notes: String = "",
    val isEditing: Boolean = false,
    val editingId: Long = 0
)
```

#### Key Methods
- `suspend fun saveStabilizer(): SaveResult` - Save/update stabilizer
- `fun deleteStabilizer(stabilizer: Stabilizer)` - Delete stabilizer
- `fun loadStabilizerForEdit(id: Long)` - Load for editing
- `fun toStabilizer(state: StabilizerInputState): Stabilizer` - Convert state to entity

#### Field Updates
- `updateBrand(value: String)`
- `updateModel(value: String)`
- `updateLength(value: String)`
- `updateWeight(value: String)`
- `updateStraightness(value: String)` - **Special**: Constrained to 1-10 range
- `updateNotes(value: String)`

#### Special Logic
```kotlin
fun updateStraightness(value: String) {
    val straightnessVal = value.toIntOrNull() ?: 5
    val constrainedValue = straightnessVal.coerceIn(1, 10).toString()
    _inputState.value = _inputState.value.copy(straightness = constrainedValue)
}
```

---

### Other Component ViewModels

All following ViewModels use the same pattern as above with component-specific fields:

#### SightViewModel
**File**: `componentViewModels/SightViewModel.kt`
**Repository**: [[Equipment-Repositories#SightRepository]]
- Manages sight equipment (brand, model, type, adjustments)

#### RiserViewModel
**File**: `componentViewModels/RiserViewModel.kt`
**Repository**: [[Equipment-Repositories#RiserRepository]]
- Manages riser equipment (brand, model, material, weight, length)

#### LimbsViewModel
**File**: `componentViewModels/LimbsViewModel.kt`
**Repository**: [[Equipment-Repositories#LimbsRepository]]
- Manages limb equipment (brand, model, poundage, material)

#### BowStringViewModel
**File**: `componentViewModels/BowStringViewModel.kt`
**Repository**: [[Equipment-Repositories#BowStringRepository]]
- Manages bow string equipment (brand, model, material, strands, length)

#### PlungerViewModel
**File**: `componentViewModels/PlungerViewModel.kt`
**Repository**: [[Equipment-Repositories#PlungerRepository]]
- Manages plunger equipment (brand, model, tension, adjustability)

#### RestViewModel
**File**: `componentViewModels/RestViewModel.kt`
**Repository**: [[Equipment-Repositories#RestRepository]]
- Manages arrow rest equipment (brand, model, type)

#### AccessoryViewModel
**File**: `componentViewModels/AccessoryViewModel.kt`
**Repository**: [[Equipment-Repositories#AccessoryRepository]]
- Manages accessory equipment (brand, model, type, purpose)

#### WeightViewModel
**File**: `componentViewModels/WeightViewModel.kt`
**Repository**: [[Equipment-Repositories#WeightRepository]]
- Manages weight equipment (brand, model, weight, location)

---

## Setup ViewModels

### BowSetupViewModel

**File**: `componentViewModels/BowSetupViewModel.kt`
**Repository**: [[Equipment-Repositories#BowSetupRepository]]

**Purpose**: Coordinates entire bow setup (combination of all components)

#### State Management
```kotlin
data class BowSetupInputState(
    val name: String = "",
    val riserId: Long? = null,
    val limbsId: Long? = null,
    val stringId: Long? = null,
    val sightId: Long? = null,
    val stabilizerIds: List<Long> = emptyList(),
    val arrowId: Long? = null,
    val plungerId: Long? = null,
    val restId: Long? = null,
    val accessoryIds: List<Long> = emptyList(),
    val notes: String = "",
    val isEditing: Boolean = false,
    val editingId: Long = 0
)
```

#### Key Methods
- `suspend fun saveBowSetup(): SaveResult` - Save complete setup
- `fun loadBowSetupForEdit(id: Long)` - Load setup with all components
- `fun deleteBowSetup(setup: BowSetup)` - Delete setup
- Component selection methods for each component type

#### Dependencies
- Uses **all** equipment repositories to fetch component options
- Coordinates multiple component selections into single setup

---

### EquipmentListViewModel

**File**: `EquipmentListViewModel.kt`
**Purpose**: Display and manage equipment inventory across all types

#### Key Methods
- `loadAllEquipment()` - Load all equipment types
- `filterByType(type: EquipmentType)` - Filter display
- `searchEquipment(query: String)` - Search functionality
- `sortEquipment(sortBy: SortCriteria)` - Sorting

#### Coordinates Multiple Repositories
```kotlin
class EquipmentListViewModel @Inject constructor(
    private val arrowRepository: ArrowRepository,
    private val stabilizerRepository: StabilizerRepository,
    private val sightRepository: SightRepository,
    // ... all other repositories
) : ViewModel()
```

---

## Common Patterns

### 1. StateFlow Pattern

All ViewModels expose state using **StateFlow** for reactive UI:

```kotlin
// Private mutable state
private val _items = MutableStateFlow<List<Component>>(emptyList())

// Public immutable state
val items: StateFlow<List<Component>> = _items.asStateFlow()

// UI observes state
val items by viewModel.items.collectAsState()
```

**Learn More**: [[Key-Patterns#StateFlow-Pattern]]

---

### 2. SaveResult Pattern

All save operations return `SaveResult` for consistent error handling:

```kotlin
suspend fun saveComponent(): SaveResult {
    val state = _inputState.value
    if (!state.isValid()) {
        return SaveResult.ValidationError(
            state.getValidationError() ?: "Invalid input"
        )
    }
    return try {
        val component = toComponent(state)
        if (state.isEditing) {
            repository.updateComponent(component)
        } else {
            repository.insertComponent(component)
        }
        clearInputs()
        loadComponents()
        SaveResult.Success
    } catch (e: Exception) {
        SaveResult.Error("Failed to save: ${e.message}")
    }
}
```

**Learn More**: [[Key-Patterns#SaveResult-Pattern]]

---

### 3. Input State Pattern

Each ViewModel has a dedicated `InputState` data class:

```kotlin
data class ComponentInputState(
    val field1: String = "",
    val field2: String = "",
    val isEditing: Boolean = false,
    val editingId: Long = 0
) {
    fun isValid(): Boolean = /* validation logic */
    fun getValidationError(): String? = /* error message */
}
```

**Benefits**:
- Immutable state updates (copy)
- Built-in validation
- Clear separation of concerns
- Easy to test

---

### 4. Field Update Methods

All ViewModels provide granular field update methods:

```kotlin
fun updateBrand(value: String) {
    _inputState.value = _inputState.value.copy(brand = value)
}

fun updateModel(value: String) {
    _inputState.value = _inputState.value.copy(model = value)
}
```

**Benefits**:
- Type-safe updates
- Single responsibility
- Easy to bind to UI components
- Testable

---

## Repository Dependencies

Each ViewModel depends on exactly one repository (except setup ViewModels):

```
ArrowViewModel → ArrowRepository → ArrowDao → Database
StabilizerViewModel → StabilizerRepository → StabilizerDao → Database
SightViewModel → SightRepository → SightDao → Database
... etc
```

**Learn More**: [[Equipment-Repositories]]

---

## Testing

Equipment ViewModels are tested with:

1. **Unit Tests**: Mock repository, test state management
2. **Integration Tests**: Real repository + in-memory database
3. **UI Tests**: Compose test harness for screens

**Example Test Structure**:
```kotlin
class ArrowViewModelTest {
    @Test
    fun `saveArrow validates input`() { ... }
    
    @Test
    fun `saveArrow calls repository on success`() { ... }
    
    @Test
    fun `deleteArrow removes from list`() { ... }
}
```

---

## Usage Example

```kotlin
@Composable
fun ArrowInputScreen(
    viewModel: ArrowViewModel = hiltViewModel()
) {
    val inputState by viewModel.inputState.collectAsState()
    val arrows by viewModel.arrows.collectAsState()
    
    Column {
        // Input fields
        OutlinedTextField(
            value = inputState.brand,
            onValueChange = viewModel::updateBrand,
            label = { Text("Brand") }
        )
        
        OutlinedTextField(
            value = inputState.model,
            onValueChange = viewModel::updateModel,
            label = { Text("Model") }
        )
        
        // Save button
        Button(
            onClick = {
                scope.launch {
                    when (val result = viewModel.saveArrow()) {
                        is SaveResult.Success -> { /* Success */ }
                        is SaveResult.Error -> { /* Show error */ }
                        is SaveResult.ValidationError -> { /* Show validation */ }
                    }
                }
            }
        ) {
            Text("Save Arrow")
        }
        
        // List of arrows
        LazyColumn {
            items(arrows) { arrow ->
                ArrowListItem(
                    arrow = arrow,
                    onEdit = { viewModel.loadArrowForEdit(arrow.id) },
                    onDelete = { viewModel.deleteArrow(arrow) }
                )
            }
        }
    }
}
```

---

## Summary

**Total Equipment ViewModels**: 13
- **Component ViewModels**: 10 (Arrow, Stabilizer, Sight, Riser, Limbs, String, Plunger, Rest, Accessory, Weight)
- **Setup ViewModels**: 2 (BowSetup, EquipmentList)
- **Support ViewModels**: 1 (EquipmentStats)

**Common Patterns**:
- ✅ StateFlow for reactive state
- ✅ SaveResult for error handling
- ✅ InputState for form management
- ✅ Repository pattern for data access
- ✅ Hilt dependency injection

**Learn More**:
- [[Equipment-Repositories]] - Repository layer
- [[Key-Patterns]] - Common patterns
- [[Architecture-Overview]] - Overall architecture
- [[Scoring-ViewModels]] - Scoring ViewModels
- [[Tournament-ViewModels]] - Tournament ViewModels

---

**Last Updated**: October 8, 2025
**File Locations**: `app/src/main/java/com/archeryapprentice/ui/equipment/viewModels/`
**Pattern Status**: ✅ Consistent across all equipment ViewModels
