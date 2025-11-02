---
title: How to Add a New Repository
tags:
  - how-to
  - repository
  - data-layer
  - room
created: 2025-11-01
---

# How to Add a New Repository

Step-by-step guide to creating a new repository for data access.

---

## Overview

This guide covers creating a complete repository with:
- Repository interface
- Room DAO
- Repository implementation
- Testing

**Time:** ~45-90 minutes
**Difficulty:** Intermediate

---

## Step 1: Create the Entity

```kotlin
// File: data/model/MyEntity.kt
@Entity(tableName = "my_entities")
data class MyEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val value: Int,
    val createdAt: Long = System.currentTimeMillis()
)
```

---

## Step 2: Create the DAO

```kotlin
// File: data/dao/MyEntityDao.kt
@Dao
interface MyEntityDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: MyEntity): Long

    @Query("SELECT * FROM my_entities WHERE id = :id")
    suspend fun getById(id: Long): MyEntity?

    @Query("SELECT * FROM my_entities ORDER BY createdAt DESC")
    suspend fun getAll(): List<MyEntity>

    @Query("SELECT * FROM my_entities ORDER BY createdAt DESC")
    fun observeAll(): Flow<List<MyEntity>>

    @Update
    suspend fun update(entity: MyEntity)

    @Delete
    suspend fun delete(entity: MyEntity)
}
```

---

## Step 3: Add DAO to Database

```kotlin
// File: data/database/AppDatabase.kt
@Database(
    entities = [
        Round::class,
        EndScore::class,
        MyEntity::class  // Add new entity
    ],
    version = 28  // Increment version
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun roundDao(): RoundDao
    abstract fun endScoreDao(): EndScoreDao
    abstract fun myEntityDao(): MyEntityDao  // Add DAO method
}
```

---

## Step 4: Create Repository Interface

```kotlin
// File: data/repository/MyEntityRepository.kt
interface MyEntityRepository {
    suspend fun create(entity: MyEntity): Result<Long>
    suspend fun getById(id: Long): Result<MyEntity?>
    suspend fun getAll(): Result<List<MyEntity>>
    fun observeAll(): Flow<List<MyEntity>>
    suspend fun update(entity: MyEntity): Result<Unit>
    suspend fun delete(id: Long): Result<Unit>
}
```

---

## Step 5: Implement Repository

```kotlin
// File: data/repository/impl/MyEntityRepositoryImpl.kt
class MyEntityRepositoryImpl(
    private val dao: MyEntityDao
) : MyEntityRepository {

    override suspend fun create(entity: MyEntity): Result<Long> = try {
        val id = dao.insert(entity)
        Result.success(id)
    } catch (e: Exception) {
        LogConfig.e(TAG, "Failed to create entity", e)
        Result.failure(e)
    }

    override suspend fun getById(id: Long): Result<MyEntity?> = try {
        val entity = dao.getById(id)
        Result.success(entity)
    } catch (e: Exception) {
        LogConfig.e(TAG, "Failed to get entity", e)
        Result.failure(e)
    }

    override suspend fun getAll(): Result<List<MyEntity>> = try {
        val entities = dao.getAll()
        Result.success(entities)
    } catch (e: Exception) {
        LogConfig.e(TAG, "Failed to get all entities", e)
        Result.failure(e)
    }

    override fun observeAll(): Flow<List<MyEntity>> =
        dao.observeAll()
            .catch { e ->
                LogConfig.e(TAG, "Flow error", e)
                emit(emptyList())
            }

    override suspend fun update(entity: MyEntity): Result<Unit> = try {
        dao.update(entity)
        Result.success(Unit)
    } catch (e: Exception) {
        LogConfig.e(TAG, "Failed to update entity", e)
        Result.failure(e)
    }

    override suspend fun delete(id: Long): Result<Unit> = try {
        val entity = dao.getById(id)
        if (entity != null) {
            dao.delete(entity)
            Result.success(Unit)
        } else {
            Result.failure(EntityNotFoundException(id))
        }
    } catch (e: Exception) {
        LogConfig.e(TAG, "Failed to delete entity", e)
        Result.failure(e)
    }

    companion object {
        private const val TAG = "MyEntityRepository"
    }
}
```

---

## Step 6: Create Database Migration

```kotlin
// File: data/database/migrations/Migration_27_28.kt
val MIGRATION_27_28 = object : Migration(27, 28) {
    override fun migrate(database: SupportSQLiteDatabase) {
        database.execSQL("""
            CREATE TABLE IF NOT EXISTS my_entities (
                id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                name TEXT NOT NULL,
                value INTEGER NOT NULL,
                createdAt INTEGER NOT NULL
            )
        """.trimIndent())

        database.execSQL("""
            CREATE INDEX IF NOT EXISTS index_my_entities_createdAt
            ON my_entities(createdAt)
        """.trimIndent())
    }
}

// Add to database builder
Room.databaseBuilder(context, AppDatabase::class.java, "app_database")
    .addMigrations(
        // ... existing migrations
        MIGRATION_27_28
    )
    .build()
```

---

## Step 7: Add Dependency Injection

```kotlin
// File: di/RepositoryModule.kt
@Module
@InstallIn(SingletonComponent::class)
object RepositoryModule {

    @Provides
    @Singleton
    fun provideMyEntityRepository(
        database: AppDatabase
    ): MyEntityRepository {
        return MyEntityRepositoryImpl(
            dao = database.myEntityDao()
        )
    }
}
```

---

## Step 8: Write Tests

### DAO Test

```kotlin
// File: androidTest/data/dao/MyEntityDaoTest.kt
@RunWith(AndroidJUnit4::class)
class MyEntityDaoTest {
    private lateinit var database: AppDatabase
    private lateinit var dao: MyEntityDao

    @Before
    fun setup() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = Room.inMemoryDatabaseBuilder(context, AppDatabase::class.java)
            .build()
        dao = database.myEntityDao()
    }

    @After
    fun teardown() {
        database.close()
    }

    @Test
    fun insertAndRetrieve() = runTest {
        // Arrange
        val entity = MyEntity(name = "Test", value = 42)

        // Act
        val id = dao.insert(entity)
        val retrieved = dao.getById(id)

        // Assert
        assertNotNull(retrieved)
        assertEquals("Test", retrieved?.name)
        assertEquals(42, retrieved?.value)
    }

    @Test
    fun observeEmitsUpdates() = runTest {
        val emissions = mutableListOf<List<MyEntity>>()

        val job = launch {
            dao.observeAll().collect {
                emissions.add(it)
            }
        }

        dao.insert(MyEntity(name = "Entity 1", value = 1))
        dao.insert(MyEntity(name = "Entity 2", value = 2))

        advanceUntilIdle()
        job.cancel()

        // Should have 3 emissions: initial empty + 2 inserts
        assertEquals(3, emissions.size)
        assertEquals(2, emissions.last().size)
    }
}
```

### Repository Test

```kotlin
// File: test/data/repository/MyEntityRepositoryTest.kt
class MyEntityRepositoryTest {
    private lateinit var repository: MyEntityRepository
    private lateinit var mockDao: MyEntityDao

    @Before
    fun setup() {
        mockDao = mockk()
        repository = MyEntityRepositoryImpl(mockDao)
    }

    @Test
    fun `create returns success with id`() = runTest {
        // Arrange
        val entity = MyEntity(name = "Test", value = 42)
        coEvery { mockDao.insert(entity) } returns 1L

        // Act
        val result = repository.create(entity)

        // Assert
        assertTrue(result.isSuccess)
        assertEquals(1L, result.getOrNull())
        coVerify { mockDao.insert(entity) }
    }

    @Test
    fun `create returns failure on exception`() = runTest {
        // Arrange
        val entity = MyEntity(name = "Test", value = 42)
        coEvery { mockDao.insert(entity) } throws SQLException("Database error")

        // Act
        val result = repository.create(entity)

        // Assert
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() is SQLException)
    }
}
```

---

## Step 9: Usage Example

```kotlin
class MyViewModel(
    private val repository: MyEntityRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(MyUiState())
    val uiState: StateFlow<MyUiState> = _uiState.asStateFlow()

    init {
        loadEntities()
    }

    private fun loadEntities() {
        viewModelScope.launch {
            repository.observeAll().collect { entities ->
                _uiState.update { it.copy(entities = entities) }
            }
        }
    }

    fun createEntity(name: String, value: Int) {
        viewModelScope.launch {
            val entity = MyEntity(name = name, value = value)
            repository.create(entity)
                .onSuccess {
                    // Success handling
                }
                .onFailure { error ->
                    _uiState.update {
                        it.copy(error = error.message)
                    }
                }
        }
    }
}
```

---

## Best Practices

1. **Use Result<T>**: Wrap return values in Result for consistent error handling
2. **Suspend functions**: Use suspend for database operations
3. **Flow for observation**: Use Flow for reactive data streams
4. **Index frequently queried columns**: Add database indexes
5. **Transaction support**: Use @Transaction for multi-step operations
6. **Error logging**: Log errors with context
7. **Test coverage**: Write DAO and repository tests

---

## Common Issues

### Issue: Database migration fails
**Solution:** Test migrations with `Room.databaseBuilder().fallbackToDestructiveMigration()` during development

### Issue: Flow not emitting updates
**Solution:** Ensure DAO query has `Flow<T>` return type

### Issue: Foreign key constraint failures
**Solution:** Define foreign keys in @Entity annotation and enable with `database.setForeignKeyConstraintsEnabled(true)`

---

## Related Documentation

- [[../technical-reference/api/repositories/index|Repositories API Reference]]
- [[../technical-reference/api/daos/index|DAOs API Reference]]
- [[add-database-entity|How to Add a Database Entity]]
- [[database-migration|How to Create a Database Migration]]

---

**Last Updated:** 2025-11-01
