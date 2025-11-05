---
title: "Testing Examples"
description: "Comprehensive test code examples and testing strategies from Archery Apprentice"
category: "technical-reference"
audience: "developers"
status: "active"
tags:
  - code-examples
  - testing
  - unit-tests
  - integration-tests
  - mocking
---

[Home](/) > [Technical Reference](../../) > [Code Examples](../) > Testing Examples

---

# Testing Examples

This page provides comprehensive testing examples from the Archery Apprentice codebase, demonstrating testing strategies for ViewModels, Repositories, Services, Compose UI components, and integration scenarios. All examples use MockK for mocking and follow the Given-When-Then test structure.

**Key Testing Libraries:**
- **JUnit 4** - Test framework
- **MockK** - Mocking framework for Kotlin
- **Kotlin Coroutines Test** - Testing coroutines with test dispatchers
- **Robolectric** - Android framework testing without devices
- **Compose UI Test** - Testing Compose UI components

---

## Table of Contents

1. [ViewModel Testing Patterns](#viewmodel-testing-patterns)
   - [Complete ViewModel Test Setup](#complete-viewmodel-test-setup)
   - [StateFlow Testing](#stateflow-testing)
   - [Error Handling Tests](#error-handling-tests)
   - [Loading State Tests](#loading-state-tests)
   - [Validation Testing](#validation-testing)
2. [Repository Testing Patterns](#repository-testing-patterns)
   - [Firebase Repository Testing](#firebase-repository-testing)
   - [Mock Repository Testing](#mock-repository-testing)
   - [Contract Testing](#contract-testing)
3. [Service Testing Patterns](#service-testing-patterns)
4. [Compose UI Testing Patterns](#compose-ui-testing-patterns)
5. [Integration Testing Patterns](#integration-testing-patterns)
6. [Test Fixtures and Builders](#test-fixtures-and-builders)
7. [Testing Best Practices](#testing-best-practices)

---

## ViewModel Testing Patterns

ViewModels are the primary logic layer in MVVM architecture. Testing them ensures business logic, state management, and user interactions work correctly without launching the full Android UI.

### Complete ViewModel Test Setup

**File:** `app/src/test/java/com/archeryapprentice/ui/authentication/AuthenticationViewModelTest.kt`

This is the gold standard for ViewModel testing in Archery Apprentice. It demonstrates:
- Test dispatcher setup/teardown
- MockK for dependency injection
- StateFlow testing with `MutableStateFlow`
- Comprehensive test coverage

```kotlin
@ExperimentalCoroutinesApi
@RunWith(RobolectricTestRunner::class)
class AuthenticationViewModelTest {

    private lateinit var viewModel: AuthenticationViewModel
    private lateinit var mockAuthRepository: AuthenticationRepository
    private lateinit var mockAccountLinkingService: AccountLinkingService
    private lateinit var userFlow: MutableStateFlow<User?>
    private lateinit var context: Context

    // UnconfinedTestDispatcher executes coroutines immediately
    private val testDispatcher = UnconfinedTestDispatcher()

    private val testUser = User(
        id = "test123",
        email = "test@example.com",
        displayName = "Test User",
        photoUrl = null
    )

    @Before
    fun setup() {
        // Replace Main dispatcher for coroutines
        Dispatchers.setMain(testDispatcher)

        // Get Android context from Robolectric
        context = ApplicationProvider.getApplicationContext()

        // Create mock repository with controllable StateFlow
        userFlow = MutableStateFlow(null)
        mockAuthRepository = mockk()
        mockAccountLinkingService = mockk()

        // Setup default repository behavior
        every { mockAuthRepository.currentUser() } returns userFlow

        // Create ViewModel with mocked dependencies
        viewModel = AuthenticationViewModel(mockAuthRepository, mockAccountLinkingService)
    }

    @After
    fun tearDown() {
        // Clean up dispatcher override
        Dispatchers.resetMain()

        // Clean up static mocks (if any)
        unmockkStatic(com.google.firebase.auth.GoogleAuthProvider::class)
    }
}
```

**Key Setup Principles:**

1. **Test Dispatcher Management**
   - Use `UnconfinedTestDispatcher` for synchronous coroutine execution
   - Set with `Dispatchers.setMain()` before each test
   - Reset with `Dispatchers.resetMain()` after each test
   - This ensures `viewModelScope.launch` blocks execute immediately

2. **Mock StateFlow Dependencies**
   - Use `MutableStateFlow` to control repository emissions
   - Allows tests to simulate state changes over time
   - Example: `userFlow.value = testUser` triggers ViewModel reactions

3. **Robolectric for Android Dependencies**
   - Use `@RunWith(RobolectricTestRunner::class)` for Android context
   - Get context with `ApplicationProvider.getApplicationContext()`
   - Required for ViewModels that use Android framework classes

---

### StateFlow Testing

**Testing StateFlow Emissions:**

```kotlin
@Test
fun `authenticationState reflects Authenticated when user exists`() = runTest(testDispatcher) {
    // Given - User is signed in
    // (No setup needed, userFlow starts as null from @Before)

    // When - User signs in
    userFlow.value = testUser
    testDispatcher.scheduler.advanceUntilIdle()

    // Then - ViewModel state should reflect authenticated user
    val state = viewModel.authenticationState.first()
    assertTrue("State should be Authenticated", state is AuthenticationState.Authenticated)
    assertEquals(testUser, (state as AuthenticationState.Authenticated).user)
}

@Test
fun `authenticationState reflects Unauthenticated when user is null`() = runTest(testDispatcher) {
    // Given - User was signed in
    userFlow.value = testUser
    testDispatcher.scheduler.advanceUntilIdle()

    // When - User signs out
    userFlow.value = null
    testDispatcher.scheduler.advanceUntilIdle()

    // Then - ViewModel state should reflect unauthenticated
    val state = viewModel.authenticationState.first()
    assertTrue("State should be Unauthenticated", state is AuthenticationState.Unauthenticated)
}
```

**StateFlow Testing Pattern:**
1. **Arrange:** Set initial state with `MutableStateFlow.value = ...`
2. **Act:** Trigger action or state change
3. **Assert:** Collect with `.first()` to verify state
4. **Advance:** Use `testDispatcher.scheduler.advanceUntilIdle()` to process coroutines

**Why `.first()`?**
- StateFlow is a hot stream that immediately emits current value
- `.first()` collects one emission and completes
- Avoids hanging tests waiting for more emissions

---

### Error Handling Tests

**Testing Error Results (Given-When-Then Structure):**

```kotlin
@Test
fun `signInWithEmail with valid credentials returns Success`() = runTest(testDispatcher) {
    // Given - Repository configured to return success
    coEvery {
        mockAuthRepository.signInWithEmail("test@example.com", "password123")
    } returns Result.success(testUser)

    // When - User attempts sign-in
    viewModel.signInWithEmail("test@example.com", "password123")
    testDispatcher.scheduler.advanceUntilIdle()

    // Then - Verify repository was called
    coVerify { mockAuthRepository.signInWithEmail("test@example.com", "password123") }

    // Then - Verify ViewModel state updated correctly
    assertTrue(viewModel.lastResult.value is AuthenticationResult.Success)
    assertFalse(viewModel.isLoading.value)
}

@Test
fun `signInWithEmail with invalid credentials returns Error`() = runTest(testDispatcher) {
    // Given - Repository configured to return failure
    val error = Exception("Invalid email or password")
    coEvery {
        mockAuthRepository.signInWithEmail("test@example.com", "wrong")
    } returns Result.failure(error)

    // When - User attempts sign-in with wrong password
    viewModel.signInWithEmail("test@example.com", "wrong")
    testDispatcher.scheduler.advanceUntilIdle()

    // Then - Verify error state
    val result = viewModel.lastResult.value
    assertTrue("Result should be Error", result is AuthenticationResult.Error)
    assertEquals("Invalid email or password", (result as AuthenticationResult.Error).message)
    assertFalse(viewModel.isLoading.value)
}

@Test
fun `signInWithEmail with network error returns Error`() = runTest(testDispatcher) {
    // Given - Repository throws exception
    coEvery {
        mockAuthRepository.signInWithEmail(any(), any())
    } throws IOException("Network unavailable")

    // When - Sign-in attempted with network error
    viewModel.signInWithEmail("test@example.com", "password123")
    testDispatcher.scheduler.advanceUntilIdle()

    // Then - ViewModel handles exception gracefully
    val result = viewModel.lastResult.value
    assertTrue("Result should be Error", result is AuthenticationResult.Error)
    assertTrue(
        "Error message should mention network",
        (result as AuthenticationResult.Error).message.contains("Network")
    )
}
```

**MockK Mocking Patterns:**
- **`coEvery`** - Mock suspend functions (returns result)
- **`every`** - Mock regular functions
- **`coVerify`** - Verify suspend function was called
- **`verify`** - Verify regular function was called
- **`any()`** - Match any parameter value
- **`throws`** - Simulate exceptions

---

### Loading State Tests

**Testing Transient States:**

```kotlin
@Test
fun `signInWithEmail sets isLoading during operation`() = runTest(testDispatcher) {
    // Given - Repository responds successfully but we check loading state midway
    coEvery { mockAuthRepository.signInWithEmail(any(), any()) } coAnswers {
        // This block runs DURING the repository call
        assertTrue("isLoading should be true during operation", viewModel.isLoading.value)
        Result.success(testUser)
    }

    // When - Sign-in starts
    viewModel.signInWithEmail("test@example.com", "password123")
    testDispatcher.scheduler.advanceUntilIdle()

    // Then - isLoading should be false after completion
    assertFalse("isLoading should be false after operation", viewModel.isLoading.value)
}

@Test
fun `createAccount sets isLoading to false even on error`() = runTest(testDispatcher) {
    // Given - Repository throws exception
    coEvery {
        mockAuthRepository.createAccount(any(), any())
    } throws Exception("Account creation failed")

    // When - Account creation attempted
    viewModel.createAccount("test@example.com", "password123")
    testDispatcher.scheduler.advanceUntilIdle()

    // Then - isLoading should still be reset to false
    assertFalse("isLoading should be false even after error", viewModel.isLoading.value)
}
```

**Testing Loading States:**
1. Use `coAnswers` to verify state DURING the operation
2. Verify final state AFTER operation completes
3. Test both success and error paths reset loading state

---

### Validation Testing

**File:** `app/src/test/java/com/archeryapprentice/ui/tournament/TournamentCreationViewModelTest.kt`

**Testing Input Validation:**

```kotlin
@Test
fun `updateName should update name and set error when blank`() = runTest {
    // When - User enters blank name
    viewModel.updateName("")

    // Then - Error message set
    val state = viewModel.uiState.first()
    assertThat(state.name).isEmpty()
    assertThat(state.nameError).isEqualTo("Tournament name is required")
}

@Test
fun `updateName should clear error when valid`() = runTest {
    // Given - Name error exists
    viewModel.updateName("")
    assertThat(viewModel.uiState.first().nameError).isNotNull()

    // When - User enters valid name
    viewModel.updateName("Valid Tournament")

    // Then - Error cleared
    val state = viewModel.uiState.first()
    assertThat(state.name).isEqualTo("Valid Tournament")
    assertThat(state.nameError).isNull()
}

@Test
fun `updateMaxParticipants should set error when below minimum`() = runTest {
    // When - User sets participants below 2
    viewModel.updateMaxParticipants(1)

    // Then - Validation error set
    val state = viewModel.uiState.first()
    assertThat(state.maxParticipants).isEqualTo(1)
    assertThat(state.maxParticipantsError).isEqualTo("Must allow at least 2 participants")
}
```

**Comprehensive Validation Test:**

```kotlin
@Test
fun `validation should catch all required field errors`() = runTest {
    // Given - Invalid values for all validated fields
    viewModel.updateName("")               // blank name
    viewModel.updateMaxParticipants(1)     // too low
    viewModel.updateNumEnds(0)             // too low
    viewModel.updateArrowsPerEnd(0)        // too low

    var tournamentCreatedCalled = false

    // When - User attempts to create tournament
    viewModel.createTournament { tournamentCreatedCalled = true }
    testDispatcher.scheduler.advanceUntilIdle()

    // Then - All validation errors present
    val state = viewModel.uiState.first()
    assertThat(state.nameError).isEqualTo("Tournament name is required")
    assertThat(state.maxParticipantsError).isEqualTo("Must allow at least 2 participants")
    assertThat(state.numEndsError).isEqualTo("Must have at least 1 end")
    assertThat(state.arrowsPerEndError).isEqualTo("Must have at least 1 arrow per end")

    // Then - Creation callback not called
    assertThat(tournamentCreatedCalled).isFalse()

    // Then - Repository never called
    coVerify(exactly = 0) { mockTournamentRepository.createTournament(any()) }
}
```

**Validation Testing Principles:**
1. Test each validation rule individually
2. Test valid inputs clear errors
3. Test comprehensive validation prevents invalid submissions
4. Verify repository never called when validation fails

---

### Slot Capturing for Complex Arguments

**Capturing and Verifying Argument Details:**

```kotlin
@Test
fun `createTournament with valid form should call repository and succeed`() = runTest {
    // Given - Valid form inputs
    viewModel.updateName("Test Tournament")
    viewModel.updateDescription("Test Description")
    viewModel.updateMaxParticipants(4)
    viewModel.updateNumEnds(6)
    viewModel.updateArrowsPerEnd(3)

    var capturedTournamentId: String? = null

    // When - Tournament created
    viewModel.createTournament { tournamentId ->
        capturedTournamentId = tournamentId
    }
    testDispatcher.scheduler.advanceUntilIdle()

    // Then - Callback invoked with tournament ID
    assertThat(capturedTournamentId).isEqualTo("tournament-123")

    // Then - Repository called with correct tournament object
    val tournamentSlot = slot<Tournament>()
    coVerify { mockTournamentRepository.createTournament(capture(tournamentSlot)) }

    val capturedTournament = tournamentSlot.captured
    assertThat(capturedTournament.name).isEqualTo("Test Tournament")
    assertThat(capturedTournament.description).isEqualTo("Test Description")
    assertThat(capturedTournament.maxParticipants).isEqualTo(4)
    assertThat(capturedTournament.numEnds).isEqualTo(6)
    assertThat(capturedTournament.arrowsPerEnd).isEqualTo(3)
    assertThat(capturedTournament.createdBy).isEqualTo("test-user-123")
}
```

**Slot Capturing Pattern:**
1. **Create slot:** `val slot = slot<Type>()`
2. **Verify and capture:** `coVerify { method(capture(slot)) }`
3. **Access captured value:** `slot.captured`
4. **Assert on details:** Verify object properties match expectations

**When to Use Slots:**
- Testing complex object construction
- Verifying multiple properties of passed arguments
- Ensuring calculated fields (like timestamps) are correct

---

## Repository Testing Patterns

Repositories abstract data sources (local database, Firebase, etc.). Testing them ensures data operations work correctly without launching the full app.

### Firebase Repository Testing

**File:** `app/src/test/java/com/archeryapprentice/data/authentication/FirebaseAuthenticationRepositoryTest.kt`

**Test Setup with Firebase Mocks:**

```kotlin
@ExperimentalCoroutinesApi
class FirebaseAuthenticationRepositoryTest {

    private lateinit var repository: FirebaseAuthenticationRepository
    private lateinit var mockFirebaseAuth: FirebaseAuth
    private lateinit var mockAuthResult: AuthResult

    private val testDispatcher = UnconfinedTestDispatcher()

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)

        mockFirebaseAuth = mockk()
        mockAuthResult = mockk()

        repository = FirebaseAuthenticationRepository(mockFirebaseAuth)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }
}
```

**Test Data Helpers:**

```kotlin
private fun createMockFirebaseUser(
    uid: String = "firebase_uid_123",
    email: String? = "test@example.com",
    displayName: String? = "Test User",
    photoUrl: String? = null
): FirebaseUser {
    val user = mockk<FirebaseUser>()
    every { user.uid } returns uid
    every { user.email } returns email
    every { user.displayName } returns displayName
    every { user.photoUrl } returns photoUrl?.let { Uri.parse(it) }
    return user
}

private fun <T> createSuccessfulTask(result: T): Task<T> {
    return Tasks.forResult(result)
}

private fun <T> createFailedTask(exception: Exception): Task<T> {
    return Tasks.forException(exception)
}
```

**Testing Firebase Success Paths:**

```kotlin
@Test
fun `signInWithEmail succeeds with valid credentials`() = runTest {
    val email = "test@example.com"
    val password = "password123"
    val mockUser = createMockFirebaseUser()

    // Given - Firebase returns successful auth result
    every { mockAuthResult.user } returns mockUser
    every {
        mockFirebaseAuth.signInWithEmailAndPassword(email, password)
    } returns createSuccessfulTask(mockAuthResult)

    // When - Sign in called
    val result = repository.signInWithEmail(email, password)

    // Then - Result is success with correct user
    assertTrue("Sign in should succeed", result.isSuccess)
    val user = result.getOrNull()
    assertNotNull("User should not be null", user)
    assertEquals("User ID should match Firebase UID", "firebase_uid_123", user!!.id)
    assertEquals("Email should match", email, user.email)

    // Then - Firebase SDK called
    verify { mockFirebaseAuth.signInWithEmailAndPassword(email, password) }
}
```

**Testing Firebase Exception Handling:**

```kotlin
@Test
fun `signInWithEmail fails with invalid credentials exception`() = runTest {
    val exception = FirebaseAuthInvalidCredentialsException("ERROR_INVALID_CREDENTIAL", "Invalid credentials")

    // Given - Firebase throws exception
    every {
        mockFirebaseAuth.signInWithEmailAndPassword(any(), any())
    } returns createFailedTask(exception)

    // When - Sign in attempted
    val result = repository.signInWithEmail("test@example.com", "wrong")

    // Then - Result is failure
    assertTrue("Sign in should fail", result.isFailure)
    val resultException = result.exceptionOrNull()
    assertEquals("Exception should be preserved", exception, resultException)
}

@Test
fun `repository handles various Firebase exceptions`() = runTest {
    val exceptions = listOf(
        FirebaseAuthInvalidCredentialsException("CODE", "Invalid credentials"),
        FirebaseAuthInvalidUserException("CODE", "Invalid user"),
        FirebaseAuthUserCollisionException("CODE", "User collision"),
        FirebaseAuthWeakPasswordException("CODE", "Weak password", "6"),
        FirebaseAuthException("CODE", "Generic auth error")
    )

    for (exception in exceptions) {
        // Given - Firebase throws this exception
        every {
            mockFirebaseAuth.signInWithEmailAndPassword(any(), any())
        } returns createFailedTask(exception)

        // When - Sign in attempted
        val result = repository.signInWithEmail("test@example.com", "password")

        // Then - Failure with exception preserved
        assertTrue("Should fail with ${exception::class.simpleName}", result.isFailure)
        val resultException = result.exceptionOrNull()
        assertEquals("Exception should be preserved", exception, resultException)
    }
}
```

**Firebase Repository Testing Best Practices:**
1. **Helper Functions:** Create reusable mock builders for Firebase types
2. **Task Mocking:** Use `Tasks.forResult()` and `Tasks.forException()` for Firebase Task types
3. **Exception Coverage:** Test all Firebase exception types your code handles
4. **User Mapping:** Verify Firebase user objects map correctly to domain models

---

### Mock Repository Testing

**File:** `app/src/test/java/com/archeryapprentice/data/authentication/MockAuthenticationRepositoryTest.kt`

Mock repositories provide predictable test data without network calls. They're useful for:
- UI testing without Firebase
- Offline development
- Predictable test scenarios

**Testing Pre-Defined Test Accounts:**

```kotlin
@Test
fun `pre-defined test accounts can sign in successfully`() = runTest {
    // Given - Repository has pre-defined test account: test@example.com / password123
    val repository = MockAuthenticationRepository()

    // When - Sign in with test account
    val result = repository.signInWithEmail("test@example.com", "password123")

    // Then - Success with predictable user data
    assertTrue("Should successfully sign in with test account", result.isSuccess)
    val user = result.getOrNull()
    assertNotNull("User should not be null", user)
    assertEquals("User ID should be generated correctly", "mock_test", user!!.id)
    assertEquals("Email should be preserved", "test@example.com", user.email)
    assertEquals("Display name should be set", "Test User", user.displayName)

    // Then - Current user StateFlow updated
    val currentUser = repository.currentUser().first()
    assertEquals("Current user should be updated", user, currentUser)
}
```

**Testing Account Creation and Sign-In Flow:**

```kotlin
@Test
fun `created account can be used for sign in`() = runTest {
    val repository = MockAuthenticationRepository()
    val email = "newuser${System.currentTimeMillis()}@example.com"
    val password = "strongpassword123"

    // Given - Create new account
    val createResult = repository.createAccount(email, password)
    assertTrue("Account creation should succeed", createResult.isSuccess)
    val createdUser = createResult.getOrNull()

    // When - Sign out
    repository.signOut()
    val userAfterSignOut = repository.currentUser().first()
    assertNull("User should be null after sign out", userAfterSignOut)

    // When - Sign in with created account
    val signInResult = repository.signInWithEmail(email, password)

    // Then - Sign in succeeds with same user
    assertTrue("Sign in should succeed with created account", signInResult.isSuccess)
    val signedInUser = signInResult.getOrNull()
    assertEquals("Signed in user should match created user", createdUser, signedInUser)
}
```

**Testing Wrong Password:**

```kotlin
@Test
fun `signInWithEmail fails with wrong password for existing account`() = runTest {
    val repository = MockAuthenticationRepository()

    // Given - Account exists
    repository.createAccount("user@example.com", "correct_password")
    repository.signOut()

    // When - Sign in with wrong password
    val result = repository.signInWithEmail("user@example.com", "wrong_password")

    // Then - Failure
    assertTrue("Sign in should fail with wrong password", result.isFailure)
    val exception = result.exceptionOrNull()
    assertNotNull("Exception should exist", exception)
    assertTrue(
        "Error message should indicate invalid credentials",
        exception!!.message?.contains("Invalid") == true
    )
}
```

---

### Contract Testing

**File:** `app/src/test/java/com/archeryapprentice/data/authentication/AuthenticationRepositoryContractTest.kt`

Contract tests ensure all implementations of an interface behave consistently. They're abstract test classes that concrete implementations inherit.

**Abstract Contract Test:**

```kotlin
/**
 * Contract tests for AuthenticationRepository interface.
 * Tests verify that all implementations follow the same interface contract.
 */
@ExperimentalCoroutinesApi
abstract class AuthenticationRepositoryContractTest {

    /**
     * Subclasses must provide a repository implementation to test
     */
    abstract fun createRepository(): AuthenticationRepository

    // Shared test data factories
    protected fun createTestEmail() = "test@example.com"
    protected fun createTestPassword() = "password123"
    protected fun createValidGoogleIdToken() = "mock_google_id_token"

    @Test
    fun `currentUser returns StateFlow of User`() = runTest {
        // Given - Repository created
        val repository = createRepository()

        // When - Access currentUser
        val result = repository.currentUser()

        // Then - Returns StateFlow
        assertNotNull("currentUser should not be null", result)

        // Should be able to collect at least one emission
        val user = result.first()
        // User may be null (not signed in) or non-null (signed in)
    }

    @Test
    fun `signInWithEmail returns Result with User on success`() = runTest {
        val repository = createRepository()
        val email = createTestEmail()
        val password = createTestPassword()

        // When - Sign in called
        val result = repository.signInWithEmail(email, password)

        // Then - Returns Result type
        assertNotNull("Result should not be null", result)
        // Result may be success or failure depending on credentials
    }

    @Test
    fun `signOut clears current user`() = runTest {
        val repository = createRepository()

        // When - Sign out called
        repository.signOut()

        // Then - Current user is null
        val user = repository.currentUser().first()
        assertNull("User should be null after sign out", user)
    }
}
```

**Concrete Implementation Test:**

```kotlin
class MockAuthenticationRepositoryContractTest : AuthenticationRepositoryContractTest() {
    override fun createRepository(): AuthenticationRepository {
        return MockAuthenticationRepository()
    }
}

class FirebaseAuthenticationRepositoryContractTest : AuthenticationRepositoryContractTest() {
    private lateinit var mockFirebaseAuth: FirebaseAuth

    @Before
    fun setup() {
        mockFirebaseAuth = mockk()
        // Setup Firebase mocks...
    }

    override fun createRepository(): AuthenticationRepository {
        return FirebaseAuthenticationRepository(mockFirebaseAuth)
    }
}
```

**Contract Testing Benefits:**
1. **Consistent Behavior:** All implementations must pass same tests
2. **Interface Compliance:** Ensures LSP (Liskov Substitution Principle)
3. **Shared Test Logic:** Write tests once, run for all implementations
4. **Regression Protection:** Adding new implementation requires passing all contract tests

---

## Service Testing Patterns

Services contain business logic that doesn't fit in ViewModels or Repositories. Testing them is straightforward since they typically have minimal dependencies.

**File:** `app/src/test/java/com/archeryapprentice/domain/services/AccuracyCalculationServiceTest.kt`

**Simple Delegation Test:**

```kotlin
class AccuracyCalculationServiceTest {

    private val calculator: AccuracyCalculator = mockk()
    private val service = AccuracyCalculationService(calculator)

    @Test
    fun `calculateMuAccuracy delegatesToCalculator`() {
        // Given - Calculator returns specific value
        every { calculator.calculateMuAccuracy(50, 80) } returns 62.5f

        // When - Service method called
        val result = service.calculateMuAccuracy(50, 80)

        // Then - Delegates to calculator
        assertEquals(62.5f, result, 0.001f)
        verify { calculator.calculateMuAccuracy(50, 80) }
    }

    @Test
    fun `calculateAccuracy delegatesToCalculator`() {
        // Given - Calculator returns specific value
        every { calculator.calculateAccuracy(120, 150) } returns 80

        // When - Service method called
        val result = service.calculateAccuracy(120, 150)

        // Then - Delegates to calculator
        assertEquals(80, result)
        verify { calculator.calculateAccuracy(120, 150) }
    }

    @Test
    fun `calculateMuAccuracy handles zero total arrows`() {
        // Given - Calculator handles edge case
        every { calculator.calculateMuAccuracy(0, 0) } returns 0f

        // When - Zero arrows
        val result = service.calculateMuAccuracy(0, 0)

        // Then - Returns 0
        assertEquals(0f, result, 0.001f)
    }
}
```

**Service Testing Principles:**
1. **Mock Dependencies:** Use MockK for calculator/helper dependencies
2. **Test Delegation:** Verify service calls dependencies correctly
3. **Test Edge Cases:** Zero values, null inputs, boundary conditions
4. **Test Return Values:** Verify calculations return expected results

---

## Compose UI Testing Patterns

Compose UI tests verify visual state and component behavior without launching the full app.

**File:** `app/src/test/java/com/archeryapprentice/ui/roundScoring/components/ArrowDisplayBoxTest.kt`

**State Calculation Testing:**

```kotlin
@Test
fun `arrow display box state calculation`() {
    val testCases = listOf(
        // (score, isX, isActive, isFilled, isSelectable, description)
        ArrowDisplayState(null, false, true, false, true, "active empty selectable arrow"),
        ArrowDisplayState(null, false, false, false, false, "inactive empty non-selectable arrow"),
        ArrowDisplayState(10, true, false, true, true, "filled X-ring selectable arrow"),
        ArrowDisplayState(9, false, false, true, true, "filled regular selectable arrow"),
        ArrowDisplayState(0, false, false, true, true, "filled miss arrow"),
    )

    testCases.forEach { state ->
        // Test state consistency
        if (state.score != null) {
            assertTrue(
                "Arrow with score should be filled: ${state.description}",
                state.isFilled
            )
        } else {
            assertFalse(
                "Arrow without score should not be filled: ${state.description}",
                state.isFilled
            )
        }

        // Test X-ring consistency
        if (state.isX) {
            assertEquals(
                "X-ring arrow should have score 10: ${state.description}",
                10,
                state.score
            )
            assertTrue(
                "X-ring arrow should be filled: ${state.description}",
                state.isFilled
            )
        }
    }
}
```

**Color Logic Testing:**

```kotlin
data class ColorTestCase(
    val isActive: Boolean,
    val isFilled: Boolean,
    val isSelectable: Boolean,
    val expectedColorType: String,
    val description: String
)

@Test
fun `arrow background color logic`() {
    val testCases = listOf(
        ColorTestCase(true, false, true, "primary", "active empty selectable"),
        ColorTestCase(false, true, true, "secondary", "inactive filled selectable"),
        ColorTestCase(false, false, false, "disabled", "inactive empty non-selectable"),
        ColorTestCase(false, false, true, "surface", "inactive empty selectable")
    )

    testCases.forEach { case ->
        val expectedColorType = when {
            case.isActive -> "primary"
            case.isFilled -> "secondary"
            !case.isSelectable -> "disabled"
            else -> "surface"
        }

        assertEquals(
            "Color type for ${case.description}",
            case.expectedColorType,
            expectedColorType
        )

        if (!case.isSelectable) {
            val expectedAlpha = 0.5f
            assertEquals(
                "Disabled arrows should have 50% opacity",
                expectedAlpha,
                0.5f,
                0.001f
            )
        }
    }
}
```

**Compose UI Testing Best Practices:**
1. **State Testing:** Test component state calculation logic separately from rendering
2. **Table-Driven Tests:** Use lists of test cases for comprehensive coverage
3. **Edge Cases:** Test all combinations of boolean flags
4. **Visual Logic:** Verify color, opacity, and style calculations

---

## Integration Testing Patterns

Integration tests verify that multiple components work together correctly. In Android, this often means testing Room database migrations or multi-layer data flows.

### Room Migration Testing

**File:** `app/src/androidTest/java/com/archeryapprentice/data/migrations/Migration20to21Test.kt`

**Database Migration Test:**

```kotlin
@RunWith(AndroidJUnit4::class)
class Migration20to21Test {

    private val TEST_DB = "migration-test"

    @get:Rule
    val helper = MigrationTestHelper(
        InstrumentationRegistry.getInstrumentation(),
        ArcheryDatabase::class.java
    )

    @Test
    fun migrate20To21_schemaMatches_andDefaultsWork() {
        // 1) Create database at version 20
        helper.createDatabase(TEST_DB, 20).apply {
            // Insert test data with v20 schema if needed
            execSQL("""
                INSERT INTO rounds (id, roundName, numEnds, numArrows)
                VALUES (1, 'Test Round', 6, 3)
            """)
            close()
        }

        // 2) Run migration to version 21 and validate schema
        val db = helper.runMigrationsAndValidate(
            TEST_DB,
            21,
            true,  // validateDroppedTables
            MIGRATION_20_21
        )

        // 3) Verify new columns exist with correct defaults
        db.verifyColumnExists(
            table = "rounds",
            column = "participants",
            expectedNotNull = false,
            expectedDefault = null
        )

        db.verifyColumnExists(
            table = "rounds",
            column = "tournamentId",
            expectedNotNull = false,
            expectedDefault = null
        )

        // 4) Verify indices created
        db.assertIndexPresent("rounds", "index_rounds_bowSetupId", unique = false)
        db.assertIndexPresent("rounds", "index_rounds_tournamentId", unique = false)

        // 5) Verify data preserved
        db.query("SELECT * FROM rounds WHERE id = 1").use { cursor ->
            assertTrue("Test round should still exist", cursor.moveToFirst())
            assertEquals("Test Round", cursor.getString(cursor.getColumnIndex("roundName")))
        }
    }

    @Test
    fun migrate20To21_withExistingData_preservesAllFields() {
        // Given - Database at v20 with complex data
        helper.createDatabase(TEST_DB, 20).apply {
            execSQL("""
                INSERT INTO rounds (id, roundName, numEnds, numArrows, distance)
                VALUES (1, 'Existing Round', 10, 6, '70m')
            """)
            close()
        }

        // When - Migration executed
        val db = helper.runMigrationsAndValidate(TEST_DB, 21, true, MIGRATION_20_21)

        // Then - All original data preserved
        db.query("SELECT * FROM rounds WHERE id = 1").use { cursor ->
            assertTrue(cursor.moveToFirst())
            assertEquals("Existing Round", cursor.getString(cursor.getColumnIndex("roundName")))
            assertEquals(10, cursor.getInt(cursor.getColumnIndex("numEnds")))
            assertEquals(6, cursor.getInt(cursor.getColumnIndex("numArrows")))
            assertEquals("70m", cursor.getString(cursor.getColumnIndex("distance")))

            // New columns should be null (default)
            assertTrue(cursor.isNull(cursor.getColumnIndex("participants")))
            assertTrue(cursor.isNull(cursor.getColumnIndex("tournamentId")))
        }
    }
}
```

**Migration Test Helpers:**

```kotlin
// Helper extension functions for database verification
private fun SupportSQLiteDatabase.verifyColumnExists(
    table: String,
    column: String,
    expectedNotNull: Boolean,
    expectedDefault: String?
) {
    query("PRAGMA table_info(`$table`)").use { c ->
        val nameIdx = c.getColumnIndex("name")
        val notNullIdx = c.getColumnIndex("notnull")
        val dfltIdx = c.getColumnIndex("dflt_value")

        var found = false
        var notNullVal = -1
        var defaultVal: String? = null

        while (c.moveToNext()) {
            if (c.getString(nameIdx) == column) {
                found = true
                notNullVal = c.getInt(notNullIdx)
                defaultVal = c.getString(dfltIdx)
                break
            }
        }

        check(found) { "Column $table.$column not found" }
        check((notNullVal == 1) == expectedNotNull) {
            "Column $table.$column NOT NULL mismatch: expected=$expectedNotNull, actual=${notNullVal == 1}"
        }
        if (expectedDefault != null) {
            check(defaultVal == expectedDefault) {
                "Column $table.$column default mismatch: expected=$expectedDefault, actual=$defaultVal"
            }
        }
    }
}

private fun SupportSQLiteDatabase.assertIndexPresent(
    table: String,
    indexName: String,
    unique: Boolean
) {
    query("PRAGMA index_list(`$table`)").use { c ->
        val nameIdx = c.getColumnIndex("name")
        val uniqueIdx = c.getColumnIndex("unique")

        var found = false
        while (c.moveToNext()) {
            if (c.getString(nameIdx) == indexName) {
                found = true
                val isUnique = c.getInt(uniqueIdx) == 1
                check(isUnique == unique) {
                    "Index $indexName unique mismatch: expected=$unique, actual=$isUnique"
                }
                break
            }
        }

        check(found) { "Index $indexName not found on table $table" }
    }
}
```

**Migration Testing Best Practices:**
1. **Test Data Preservation:** Verify existing data survives migration
2. **Test Schema Changes:** Verify new columns, indices, and constraints
3. **Test Defaults:** Verify new columns have correct default values
4. **Test Complex Scenarios:** Insert realistic data before migration
5. **Use Helper Functions:** Create reusable verification utilities

---

## Test Fixtures and Builders

Test fixtures and builders create reusable test data, reducing boilerplate and improving test readability.

### Mock Platform Providers

**File:** `app/src/test/java/com/archeryapprentice/test/mocks/MockPlatformProviders.kt`

**Mock Network Monitor:**

```kotlin
class MockNetworkMonitor(
    private var connected: Boolean = true
) : NetworkMonitor {
    private val connectivityFlow = MutableStateFlow(connected)

    override fun isConnected(): Boolean = connected

    override fun observeConnectivity(): Flow<Boolean> = connectivityFlow

    // Test helper method
    fun setConnected(isConnected: Boolean) {
        connected = isConnected
        connectivityFlow.value = isConnected
    }
}

// Usage in tests:
@Test
fun `repository uses offline data when network unavailable`() = runTest {
    val mockNetwork = MockNetworkMonitor(connected = false)
    val repository = HybridTournamentRepository(
        offlineRepo = offlineRepo,
        firebaseRepo = firebaseRepo,
        networkMonitor = mockNetwork
    )

    // When - Fetch tournaments while offline
    val tournaments = repository.getPublicTournaments().first()

    // Then - Uses offline data, doesn't call Firebase
    verify(exactly = 0) { firebaseRepo.getPublicTournaments() }
}
```

**Mock Preference Storage:**

```kotlin
class MockPreferenceStorage : PreferenceStorage {
    private val storage = mutableMapOf<String, Any>()

    override fun getString(key: String, defaultValue: String?): String? {
        return storage[key] as? String ?: defaultValue
    }

    override fun putString(key: String, value: String) {
        storage[key] = value
    }

    override fun getBoolean(key: String, defaultValue: Boolean): Boolean {
        return storage[key] as? Boolean ?: defaultValue
    }

    override fun putBoolean(key: String, value: Boolean) {
        storage[key] = value
    }

    override fun getInt(key: String, defaultValue: Int): Int {
        return storage[key] as? Int ?: defaultValue
    }

    override fun putInt(key: String, value: Int) {
        storage[key] = value
    }

    // Test helper
    fun clearAll() = storage.clear()
}

// Usage in tests:
@Test
fun `settings persist across app restarts`() {
    val prefs = MockPreferenceStorage()

    // When - Save setting
    prefs.putBoolean("dark_mode", true)

    // Then - Retrieve setting
    assertEquals(true, prefs.getBoolean("dark_mode", false))
}
```

**Mock Tournament Mode Provider:**

```kotlin
class MockTournamentModeProvider(
    private var onlineMode: Boolean = false
) : TournamentModeProvider {
    override fun isOnlineMode(): Boolean = onlineMode

    override fun setOnlineMode(enabled: Boolean) {
        onlineMode = enabled
    }

    // Test helper
    fun setMode(enabled: Boolean) {
        onlineMode = enabled
    }
}
```

---

### Participant Fixtures

**File:** `app/src/test/java/com/archeryapprentice/test/fixtures/ParticipantFixtures.kt`

**Fixture Factory Functions:**

```kotlin
object ParticipantFixtures {
    // Create local user participant
    fun mu(id: String = "local_user", name: String = "You") =
        SessionParticipant.LocalUser(id = id, displayName = name)

    // Create guest archer participant
    fun gu(id: String = "guest_archer", name: String = "Guest") =
        SessionParticipant.GuestArcher(id = id, displayName = name)

    // Create participant progress
    fun progress(
        endsCompleted: Int = 0,
        endsTotal: Int = 3,
        isComplete: Boolean = false
    ) = ParticipantProgress(
        endsCompleted = endsCompleted,
        endsTotal = endsTotal,
        isComplete = isComplete
    )

    // Create tournament participant
    fun tournamentParticipant(
        id: String = "participant_123",
        userId: String = "user_123",
        displayName: String = "Test Participant",
        status: ParticipantStatus = ParticipantStatus.ACTIVE
    ) = TournamentParticipant(
        id = id,
        userId = userId,
        displayName = displayName,
        status = status
    )
}

// Usage in tests:
@Test
fun `session with local user and guest`() {
    val participants = listOf(
        ParticipantFixtures.mu(name = "Main User"),
        ParticipantFixtures.gu(name = "Guest 1"),
        ParticipantFixtures.gu(name = "Guest 2")
    )

    assertEquals(3, participants.size)
    assertTrue(participants[0] is SessionParticipant.LocalUser)
    assertTrue(participants[1] is SessionParticipant.GuestArcher)
}
```

---

### Builder Pattern

**File:** `app/src/test/java/com/archeryapprentice/test/helpers/TestHelpers.kt`

**Round Builder:**

```kotlin
class RoundBuilder {
    private var id: Long = 0
    private var roundName: String = "Test Round"
    private var numEnds: Int = 6
    private var numArrows: Int = 3
    private var distance: Distance = Distance.EIGHTEEN_METERS
    private var status: RoundStatus = RoundStatus.NOT_STARTED
    private var startTime: Long? = null
    private var endTime: Long? = null
    private var maxPossibleScore: Int = 180

    fun withId(id: Long) = apply { this.id = id }
    fun withName(name: String) = apply { roundName = name }
    fun withEnds(ends: Int) = apply {
        numEnds = ends
        maxPossibleScore = ends * numArrows * 10
    }
    fun withArrows(arrows: Int) = apply {
        numArrows = arrows
        maxPossibleScore = numEnds * arrows * 10
    }
    fun at(distance: Distance) = apply { this.distance = distance }

    fun notStarted() = apply {
        status = RoundStatus.NOT_STARTED
        startTime = null
        endTime = null
    }

    fun inProgress() = apply {
        status = RoundStatus.IN_PROGRESS
        startTime = System.currentTimeMillis()
        endTime = null
    }

    fun completed() = apply {
        status = RoundStatus.COMPLETED
        startTime = System.currentTimeMillis() - 3600000  // 1 hour ago
        endTime = System.currentTimeMillis()
    }

    fun build() = Round(
        id = id,
        roundName = roundName,
        numEnds = numEnds,
        numArrows = numArrows,
        distance = distance,
        status = status,
        startTime = startTime,
        endTime = endTime,
        maxPossibleScore = maxPossibleScore
    )
}

// Usage in tests:
@Test
fun `completed round calculates duration correctly`() {
    val round = RoundBuilder()
        .withName("Test Round")
        .withEnds(10)
        .completed()
        .build()

    assertNotNull(round.startTime)
    assertNotNull(round.endTime)
    assertEquals(RoundStatus.COMPLETED, round.status)
    assertTrue(round.endTime!! > round.startTime!!)
}
```

**Scoring Pattern Helpers:**

```kotlin
object ScoringPatterns {
    /**
     * Perfect round - all 10s with X-ring
     */
    fun perfectRound(numArrows: Int): Pair<List<Int>, List<Boolean>> {
        val scores = List(numArrows) { 10 }
        val xRings = List(numArrows) { true }
        return Pair(scores, xRings)
    }

    /**
     * Variable scoring pattern: 10, 9, 7, 5, 3, 0 (repeating)
     */
    fun variableRound(numArrows: Int): Pair<List<Int>, List<Boolean>> {
        val scores = List(numArrows) { index ->
            when (index % 6) {
                0 -> 10
                1 -> 9
                2 -> 7
                3 -> 5
                4 -> 3
                else -> 0  // Miss
            }
        }
        val xRings = List(numArrows) { index ->
            index % 6 == 0 && scores[index] == 10
        }
        return Pair(scores, xRings)
    }

    /**
     * Declining performance - simulates fatigue
     */
    fun fatiguedRound(numArrows: Int): Pair<List<Int>, List<Boolean>> {
        val scores = List(numArrows) { index ->
            val progression = index.toFloat() / numArrows
            when {
                progression < 0.33f -> 10  // Early: 10s
                progression < 0.66f -> 8   // Middle: 8s
                else -> 6                  // Late: 6s (fatigue)
            }
        }
        val xRings = List(numArrows) { false }
        return Pair(scores, xRings)
    }
}

// Usage in tests:
@Test
fun `fatigue analysis detects performance drop`() {
    val (scores, xRings) = ScoringPatterns.fatiguedRound(18)
    val fatigueMetrics = service.calculateFatigue(scores)

    assertTrue("Should detect fatigue", fatigueMetrics.fatigueDetected)
    assertTrue("Performance should drop", fatigueMetrics.performanceDrop > 0)
}
```

---

## Testing Best Practices

### 1. Test Structure

**Use Given-When-Then:**

```kotlin
@Test
fun `descriptive test name in backticks`() = runTest {
    // Given - Setup preconditions
    val repository = createMockRepository()
    val input = createValidInput()

    // When - Execute action being tested
    val result = viewModel.performAction(input)

    // Then - Verify outcomes
    assertTrue(result.isSuccess)
    verify { repository.save(any()) }
}
```

**Benefits:**
- **Readability:** Clear structure for reviewers
- **Completeness:** Ensures all test phases present
- **Documentation:** Tests serve as usage examples

---

### 2. Test Naming

**Use Descriptive Names:**

```kotlin
// ✅ Good - Descriptive, behavior-focused
@Test
fun `signInWithEmail with valid credentials returns Success`()

@Test
fun `createTournament with blank name shows validation error`()

@Test
fun `repository uses offline data when network unavailable`()

// ❌ Bad - Vague, implementation-focused
@Test
fun testSignIn()

@Test
fun testValidation()

@Test
fun testRepository()
```

**Naming Guidelines:**
- Use backticks for natural language
- Include method/feature being tested
- Include input/condition
- Include expected outcome
- Read like a specification

---

### 3. Dispatcher Management

**Always Set and Reset Test Dispatcher:**

```kotlin
@ExperimentalCoroutinesApi
class MyViewModelTest {
    private val testDispatcher = UnconfinedTestDispatcher()

    @Before
    fun setup() {
        Dispatchers.setMain(testDispatcher)
        // ... rest of setup
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()  // Critical - prevents test pollution
    }
}
```

**Common Mistakes:**
- ❌ Forgetting `resetMain()` - causes test pollution
- ❌ Using `runBlocking` instead of `runTest` - doesn't advance test time
- ❌ Not advancing dispatcher - `testDispatcher.scheduler.advanceUntilIdle()`

---

### 4. Mock Configuration

**Use `coEvery` for Suspend Functions:**

```kotlin
// ✅ Correct
coEvery { repository.getData() } returns Result.success(data)

// ❌ Wrong - will fail at runtime
every { repository.getData() } returns Result.success(data)
```

**Use `coVerify` for Suspend Functions:**

```kotlin
// ✅ Correct
coVerify { repository.save(any()) }

// ❌ Wrong - won't match suspend function calls
verify { repository.save(any()) }
```

---

### 5. StateFlow Testing

**Collect with `.first()` for Single Emission:**

```kotlin
// ✅ Good - Collects one value and completes
val state = viewModel.uiState.first()
assertEquals(expected, state.value)

// ❌ Bad - Hangs waiting for flow to complete
val state = viewModel.uiState.toList()  // StateFlow never completes!
```

**Control Flow with `MutableStateFlow` in Tests:**

```kotlin
@Test
fun `viewModel reacts to repository state changes`() = runTest {
    // Given - Controllable flow
    val dataFlow = MutableStateFlow<List<Item>>(emptyList())
    every { repository.getData() } returns dataFlow

    // When - Repository emits new data
    dataFlow.value = listOf(item1, item2)
    testDispatcher.scheduler.advanceUntilIdle()

    // Then - ViewModel updates
    assertEquals(2, viewModel.items.first().size)
}
```

---

### 6. Test Coverage Goals

**What to Test:**
- ✅ Business logic (validation, calculation, state management)
- ✅ Error handling (all failure paths)
- ✅ Edge cases (null, empty, boundary values)
- ✅ State transitions (loading → success → error)
- ✅ Integration points (repository calls, service calls)

**What NOT to Test:**
- ❌ Framework code (Room, Compose, Firebase internals)
- ❌ Simple getters/setters
- ❌ Data classes (auto-generated equals/hashCode)
- ❌ UI layout (use screenshot testing instead)

---

### 7. Test Independence

**Each Test Should Be Independent:**

```kotlin
// ✅ Good - Each test creates own data
@Test
fun `test A`() {
    val data = createTestData()
    // ... test with data
}

@Test
fun `test B`() {
    val data = createTestData()  // Fresh data
    // ... test with data
}

// ❌ Bad - Tests share mutable state
class MyTest {
    private val sharedData = mutableListOf<Item>()  // Pollution risk!

    @Test
    fun `test A`() {
        sharedData.add(item)  // Affects other tests!
    }

    @Test
    fun `test B`() {
        assertEquals(0, sharedData.size)  // Fails if test A ran first!
    }
}
```

**Test Independence Principles:**
- Don't share mutable state between tests
- Use `@Before` to reset state
- Don't rely on test execution order
- Each test should pass in isolation

---

### 8. Assertion Best Practices

**Use Specific Assertions:**

```kotlin
// ✅ Good - Specific, clear failure messages
assertEquals("Expected name", "Test User", user.name)
assertTrue("User should be active", user.isActive)
assertNotNull("User should exist", user)

// ❌ Bad - Generic, unclear failures
assert(user.name == "Test User")
assert(user != null)
```

**Use AssertJ/Truth for Fluent Assertions:**

```kotlin
// ✅ Good - Fluent, readable
assertThat(users).hasSize(3)
assertThat(user.name).isEqualTo("Test User")
assertThat(result).isInstanceOf(Success::class.java)

// ❌ Bad - Verbose, less readable
assertEquals(3, users.size)
assertEquals("Test User", user.name)
assertTrue(result is Success)
```

---

## Testing Checklist

When writing tests for a new feature:

- [ ] **Setup/Teardown:** Proper `@Before` and `@After` with dispatcher management
- [ ] **Happy Path:** Test successful operation with valid inputs
- [ ] **Error Paths:** Test all failure scenarios (network error, validation error, etc.)
- [ ] **Edge Cases:** Test null, empty, boundary values
- [ ] **Loading States:** Verify loading indicators during async operations
- [ ] **State Transitions:** Test state changes correctly
- [ ] **Repository Calls:** Verify repository methods called with correct arguments
- [ ] **StateFlow Updates:** Verify UI state updates correctly
- [ ] **Test Independence:** Each test can run in isolation
- [ ] **Descriptive Names:** Test names clearly describe what's being tested
- [ ] **Given-When-Then:** Tests follow structured format

---

## Summary

Archery Apprentice uses comprehensive testing strategies across all architectural layers:

**ViewModel Testing:**
- MockK for dependency injection
- UnconfinedTestDispatcher for synchronous coroutine execution
- StateFlow testing with MutableStateFlow
- Given-When-Then structure for clarity

**Repository Testing:**
- Firebase mocking with test Tasks
- Contract tests for interface compliance
- Mock repositories for predictable behavior

**Service Testing:**
- Simple delegation tests
- Business logic verification
- Edge case coverage

**UI Testing:**
- State calculation verification
- Visual logic testing
- Table-driven test cases

**Integration Testing:**
- Room migration testing
- Multi-component integration
- Data preservation verification

**Test Fixtures:**
- Builder pattern for complex objects
- Factory functions for common test data
- Mock platform providers for controllable dependencies

Follow these patterns when adding new features to maintain high test coverage and code quality.

---

## Related Documentation

- [Common Patterns](../Common-Patterns/) - Common code patterns used in production code
- [Feature Examples](../Feature-Examples/) - Complete feature implementations
- [Architecture Overview](../../Architecture/) - Application architecture
- [Testing Guide](/developer-guide/testing/) - Testing philosophy and strategy

---

**Last Updated:** 2025-11-04
