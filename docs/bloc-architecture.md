# BLoC Architecture

## Overview

This app uses **Cubit** (a simplified version of BLoC) for state management throughout the application. Cubit is part of the `bloc` and `flutter_bloc` packages and provides a predictable, testable state management solution.

## What is Cubit?

**Cubit** is a lightweight subset of BLoC that:
- Emits states (no explicit events)
- Uses simple methods instead of event-driven architecture
- Perfect for simpler state management needs
- Less boilerplate than full BLoC pattern

**BLoC (Business Logic Component)** pattern separates:
- **Presentation Layer** (UI widgets)
- **Business Logic Layer** (Cubits/Blocs)
- **Data Layer** (Repositories, API calls)

---

## Architecture Layers

### 1. Cubit Setup in main.dart

The app initializes global Cubits at the root level:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (context) => SessionCubit(...)),    // User session management
    BlocProvider(create: (context) => PlayerCubit(...)),     // Audio player state
    BlocProvider(create: (context) => ThemeCubit(...)),      // Theme/appearance
    BlocProvider(create: (context) => LocationCubit()),      // Location services
    BlocProvider(create: (context) => PurchaseCubit(...)),   // Subscriptions
  ],
  child: Builder(...),
)
```

**Why at root level?**
- These cubits need to be accessible from anywhere in the app
- They manage global app state (player, session, theme)
- Survive navigation changes

### 2. Feature-Specific Cubits in AppScope

Feature-specific Cubits are initialized in `AppScope`:

```dart
MultiBlocProvider(providers: [
  BlocProvider(create: (context) => RadioListCubit()),       // Radio station lists
  BlocProvider(create: (context) => RadioFavoriteCubit()),   // User favorites
  BlocProvider(create: (context) => TimeLineCubit(...)),     // Program timeline
  BlocProvider(create: (context) => BottomNavigationCubit()), // Bottom nav state
  BlocProvider(create: (context) => TranscriptCubit(...)),   // Radio transcripts
], child: ...)
```

**Why separate from root?**
- Scoped to specific features
- Can be recreated when needed
- Reduces memory footprint

### 3. Global Cubit Connections

The `GlobalCubitConnection` widget handles cross-cubit communication:

```dart
class GlobalCubitConnection extends StatelessWidget {
  Widget build(BuildContext context) {
    return purchaseCubit(
      _locationCubit(
        _radioListEvents(child: child)
      )
    );
  }
}
```

This uses `BlocPresentationListener` to:
- Listen to one-time events (not state changes)
- Show dialogs, toasts, or navigation
- Coordinate between different cubits

---

## Cubit Examples

### Example 1: PlayerCubit (Simple State Management)

**File:** `lib/features/player/player_cubit.dart`

```dart
class PlayerCubit extends Cubit<PlayerCubitState> {
  MediaPlayer player;

  PlayerCubit(this.player) : super(PlayerCubitState());

  selectRadio(AppRadio radio) {
    if(state.selectedRadio?.id == radio.id) {
      if(player.isPause() || player.isStopped()){
        player.play();
      }
      return;
    }

    settings.setLastRadio(radio.id);
    emit(state.copyWith(selectedRadio: radio));  // Emit new state
    player.playMediaItem(...);
  }

  pause() {
    player.pause();
  }

  unPause() {
    player.play();
  }
}

class PlayerCubitState {
  AppRadio? selectedRadio;

  PlayerCubitState({this.selectedRadio});

  PlayerCubitState copyWith({AppRadio? selectedRadio}) {
    return PlayerCubitState(
      selectedRadio: selectedRadio ?? this.selectedRadio,
    );
  }
}
```

**Key Concepts:**
- **State class**: Holds the current state data (`selectedRadio`)
- **copyWith**: Creates new state instances (immutability)
- **emit()**: Notifies listeners of state changes
- **Methods**: Simple functions that modify state

---

### Example 2: LocationCubit (With Presentation Events)

**File:** `lib/features/location/location_cubit.dart`

```dart
// Define event types
class LocationEvents {}
class LocationEnabledEvent extends LocationEvents {}
class LocationShowEvent extends LocationEvents {}
class LocationErrorEvent extends LocationEvents {
  LocationPermissionStatus status;
  LocationErrorEvent(this.status);
}

// Cubit with presentation mixin
class LocationCubit extends Cubit<LocationState>
    with BlocPresentationMixin<LocationState,LocationEvents> {

  LocationCubit() : super(LocationState());

  enableLocation() async {
    emit(LocationState(isLoading: true));  // Show loading

    bool isLocationEnabled = await LocationService.isLocationServiceEnabled();
    if(!isLocationEnabled) {
      emitPresentation(LocationErrorEvent(...));  // One-time event
      emit(LocationState(isLoading: false));
      return;
    }

    // ... more logic

    if(status == LocationPermissionStatus.ALLOW) {
      settings.isUserEnableLocation = true;
      emitPresentation(LocationEnabledEvent());  // Success event
    }
  }
}

class LocationState {
  bool isLoading;
  LocationState({this.isLoading = false});
}
```

**Key Concepts:**
- **BlocPresentationMixin**: Enables one-time events (vs continuous state)
- **emitPresentation()**: Triggers one-time actions (dialogs, navigation)
- **State vs Events**:
  - State = continuous (loading status)
  - Events = one-time (show dialog, navigate)

---

### Example 3: PurchaseCubit (Complex Business Logic)

**File:** `lib/features/purchase/purchase_cubit.dart`

```dart
class PurchaseEvent {}
class PurchaseMessageEvent extends PurchaseEvent {
  final String message;
  PurchaseMessageEvent(this.message);
}

class PurchaseCubit extends Cubit<PurchaseState>
    with BlocPresentationMixin<PurchaseState,PurchaseEvent> {

  final UserRepo userRepo;

  PurchaseCubit(this.userRepo):super(PurchaseState()) {
    _initPurchases(userRepo.deviceId);
  }

  restorePurchases(AppLocalizations localization) async {
    if(state.isRestoring) return;  // Prevent duplicate calls

    emit(state.copyWith(isRestoring: true));  // Update state

    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();

      if (customerInfo.activeSubscriptions.isNotEmpty) {
        // Complex business logic...
        userRepo.activePlan.value = ActiveSubscribePlan(...);
        emitPresentation(PurchaseMessageEvent(
          localization.restore_purchases_restored_title
        ));
        emit(state.copyWith(isRestoring: false, isRestoringDone: true));
      } else {
        emitPresentation(PurchaseMessageEvent(
          localization.restore_purchases_not_restored_title
        ));
        emit(state.copyWith(isRestoring: false));
      }
    } catch (e) {
      emitPresentation(PurchaseMessageEvent(e.toString()));
      emit(state.copyWith(isRestoring: false));
    }
  }
}
```

**Key Concepts:**
- **Guard clauses**: Prevent duplicate operations (`if(state.isRestoring) return`)
- **Error handling**: Try-catch with user feedback
- **Localization**: Messages depend on user language
- **Repository injection**: Cubit doesn't handle data directly

---

## How Cubits are Used in UI

### Pattern 1: context.read() - Call Methods

**Use when:** You want to call a method on the Cubit (no rebuild needed)

```dart
// From: lib/features/radio_list/page_radio_list_city.dart:75
onTap: () {
  context.read<BottomNavigationCubit>().openMenu(true);
  context.read<PlayerCubit>().selectRadio(radio);
  context.read<TimeLineCubit>().selectRadio(radio);
}
```

**Explanation:**
- `context.read<CubitType>()` - Get cubit instance without listening
- No widget rebuild when state changes
- Used for **actions/commands**

---

### Pattern 2: context.select() - Listen to Specific State

**Use when:** You want to rebuild only when a specific part of state changes

```dart
// From: lib/features/radio_list/page_radio_list_city.dart:45-47
bool isLoading = context.select((RadioListCityCubit bloc) => bloc.state.isLoading);
List<AppRadio> list = context.select((RadioListCityCubit bloc) => bloc.state.list);
List<String> favorites = context.select((RadioFavoriteCubit bloc) => bloc.state.favoriteList);
```

**Explanation:**
- Rebuilds **only** when selected value changes
- More efficient than listening to entire state
- Use for **data that changes independently**

---

### Pattern 3: BlocBuilder - Build UI from State

**Use when:** You need to build different UI based on state

```dart
// From: lib/features/player/widgets/player_progress.dart:11
return BlocBuilder<TimeLineCubit, TimeLineState>(
  builder: (context, state) {
    // Build UI based on state
    return ProgressBar(
      current: state.currentPosition,
      total: state.totalDuration,
    );
  },
);
```

**Explanation:**
- Rebuilds when **any** state property changes
- Good for widgets that depend on multiple state fields
- Builder function receives current state

---

### Pattern 4: BlocPresentationListener - One-Time Events

**Use when:** You need to handle one-time actions (dialogs, navigation, toasts)

```dart
// From: lib/app/gobal_cubit_connection.dart:42
purchaseCubit(Widget child) {
  return BlocPresentationListener<PurchaseCubit, PurchaseEvent>(
    listener: (context, event) {
      if(event is PurchaseMessageEvent) {
        toastification.show(
          context: context,
          title: Text(event.message),
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    },
    child: child
  );
}
```

**Explanation:**
- Listens to **events** (not state)
- Events fire once and don't persist
- Perfect for: navigation, dialogs, toasts, snackbars

---

## Complete Flow Example: Playing a Radio Station

Let's trace what happens when a user taps a radio station:

### 1. User Taps Radio Item (UI Layer)

```dart
// lib/features/radio_list/page_radio_list_city.dart:74-76
onRadioSelect: (radio) {
  context.read<BottomNavigationCubit>().openMenu(true);   // ①
  context.read<PlayerCubit>().selectRadio(radio);         // ②
  context.read<TimeLineCubit>().selectRadio(radio);       // ③
}
```

### 2. PlayerCubit Handles Business Logic

```dart
// lib/features/player/player_cubit.dart:26
selectRadio(AppRadio radio) {
  // Check if already selected
  if(state.selectedRadio?.id == radio.id) {
    if(player.isPause() || player.isStopped()){
      player.play();
    }
    return;
  }

  // Save to settings (persistence)
  settings.setLastRadio(radio.id);

  // Update state (UI will rebuild)
  emit(state.copyWith(selectedRadio: radio));

  // Start playback (side effect)
  player.playMediaItem(MediaItem(
    id: radio.stream.getPlatformStream(),
    title: radio.name,
    artUri: Uri.parse(radio.thumbnail)
  ));
}
```

### 3. UI Automatically Updates

Multiple widgets listening to PlayerCubit will rebuild:

```dart
// Player widget using context.select
AppRadio? selectedRadio = context.select(
  (PlayerCubit cubit) => cubit.state.selectedRadio
);

// Display current radio
if (selectedRadio != null) {
  return Text(selectedRadio.name);
}
```

### 4. Cross-Cubit Effects

```dart
// TimeLineCubit also updates
selectRadio(AppRadio radio) {
  // Load program schedule for this radio
  emit(state.copyWith(selectedRadio: radio));
  _loadSchedule(radio.id);
}
```

**The beauty of this architecture:**
- UI doesn't know about API calls, data storage, or business logic
- Cubits are testable in isolation
- State changes automatically update all listeners
- Clear separation of concerns

---

## Cubit Hierarchy & Scope

### Global Scope (app-wide, created in main.dart)
1. **SessionCubit** - User authentication, session data
2. **PlayerCubit** - Audio playback state
3. **ThemeCubit** - App appearance (light/dark mode)
4. **LocationCubit** - Location permissions and services
5. **PurchaseCubit** - Subscription/payment state

### Feature Scope (created in AppScope)
1. **RadioListCubit** - Radio station list management
2. **RadioFavoriteCubit** - User's favorite stations
3. **TimeLineCubit** - Program schedule/timeline
4. **BottomNavigationCubit** - Bottom nav bar state
5. **TranscriptCubit** - Radio transcripts/captions

### Page Scope (created per page/route)
1. **RadioListCityCubit** - City-specific radio list
2. **RadioListSearchCubit** - Search functionality
3. **VisualCubit** - Visual customization

---

## Benefits of This Architecture

### ✅ Separation of Concerns
- UI widgets only care about rendering
- Business logic lives in Cubits
- Data fetching handled by repositories

### ✅ Testability
```dart
test('PlayerCubit selects radio', () {
  final cubit = PlayerCubit(mockPlayer);
  final radio = AppRadio(id: '1', name: 'Test');

  cubit.selectRadio(radio);

  expect(cubit.state.selectedRadio, radio);
  verify(mockPlayer.playMediaItem(any));
});
```

### ✅ Predictable State Changes
- All state changes go through `emit()`
- Easy to debug with bloc observer
- Time-travel debugging possible

### ✅ Reusability
- Same Cubit can be used by multiple widgets
- Widgets automatically update when state changes

### ✅ Type Safety
- Flutter's type system catches errors at compile time
- No runtime surprises

---

## Common Patterns

### 1. Loading States
```dart
class SomeState {
  bool isLoading;

  SomeState({this.isLoading = false});
}

// Usage in Cubit
somMethod() async {
  emit(state.copyWith(isLoading: true));
  try {
    var data = await fetchData();
    emit(state.copyWith(data: data, isLoading: false));
  } catch (e) {
    emit(state.copyWith(isLoading: false, error: e));
  }
}
```

### 2. Optimistic Updates
```dart
toggleFavorite(AppRadio radio, bool isFavorite) {
  // Update UI immediately
  emit(state.copyWith(
    favoriteList: isFavorite
      ? [...state.favoriteList, radio.id]
      : state.favoriteList.where((id) => id != radio.id).toList()
  ));

  // Sync to backend
  _syncToServer(radio.id, isFavorite);
}
```

### 3. Coordinated State Updates
```dart
// Multiple cubits working together
onRadioSelect: (radio) {
  context.read<PlayerCubit>().selectRadio(radio);      // Start playing
  context.read<TimeLineCubit>().selectRadio(radio);    // Load schedule
  context.read<TranscriptCubit>().loadTranscript(radio); // Load lyrics
}
```

---

## Best Practices

### 1. ✅ Immutable State
```dart
// Good: Return new instance
PlayerCubitState copyWith({AppRadio? selectedRadio}) {
  return PlayerCubitState(
    selectedRadio: selectedRadio ?? this.selectedRadio,
  );
}

// Bad: Mutate existing state
// state.selectedRadio = radio; // Never do this!
```

### 2. ✅ Guard Clauses
```dart
restorePurchases() async {
  if(state.isRestoring) return;  // Prevent duplicate calls
  // ... rest of logic
}
```

### 3. ✅ Dependency Injection
```dart
// Inject dependencies in constructor
PlayerCubit(this.player) : super(PlayerCubitState());
PurchaseCubit(this.userRepo) : super(PurchaseState());
```

### 4. ✅ Use context.select for Performance
```dart
// Only rebuilds when isLoading changes
bool isLoading = context.select(
  (LocationCubit cubit) => cubit.state.isLoading
);
```

### 5. ✅ Separate Events from State
```dart
// State = continuous (loading, data)
class LocationState { bool isLoading; }

// Events = one-time (show dialog)
class LocationShowEvent extends LocationEvents {}
```

---

## Migration to BLoC v9.x Considerations

Your app currently uses bloc 8.1.2 and flutter_bloc 8.1.3. Here's what to know:

### Breaking Changes in v9.0
1. **Event transformer changes** (doesn't affect Cubits)
2. **Observer API updates** (if you use BlocObserver)
3. **Performance improvements** (faster rebuilds)

### Migration Effort
- **Cubits**: Minimal changes (Cubit API is stable)
- **BlocBuilder/BlocListener**: No changes
- **context.read/select/watch**: No changes

### What to Test After Upgrade
- [ ] All Cubit state transitions
- [ ] BlocPresentationListener functionality
- [ ] Cross-cubit communication in GlobalCubitConnection
- [ ] Navigation flows
- [ ] Purchase flows (critical!)

---

## Debugging Tips

### 1. Add BlocObserver for Logging
```dart
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    print('${bloc.runtimeType} $change');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('${bloc.runtimeType} $error $stackTrace');
    super.onError(bloc, error, stackTrace);
  }
}

// In main.dart
void main() {
  Bloc.observer = AppBlocObserver();
  // ...
}
```

### 2. Use Flutter DevTools
- Track state changes in real-time
- Inspect current state
- See rebuild count

### 3. Add toString() to State Classes
```dart
class PlayerCubitState {
  AppRadio? selectedRadio;

  @override
  String toString() => 'PlayerCubitState(selectedRadio: ${selectedRadio?.name})';
}
```

---

## File Structure

```
lib/
├── app/
│   ├── theme_cubit.dart              # Global theme state
│   ├── bottom_navigation/
│   │   └── bottom_navigation_cubit.dart
│   ├── gobal_cubit_connection.dart   # Cross-cubit coordination
│   └── app_scope.dart                # Feature-level cubit providers
├── features/
│   ├── auth/
│   │   └── session_cubit.dart        # Authentication state
│   ├── player/
│   │   └── player_cubit.dart         # Audio playback state
│   ├── location/
│   │   └── location_cubit.dart       # Location services state
│   ├── purchase/
│   │   └── purchase_cubit.dart       # Subscription state
│   ├── radio_list/
│   │   └── cubit/
│   │       ├── radio_list_cubit.dart
│   │       ├── radio_list_city_cubit.dart
│   │       ├── radio_list_search_cubit.dart
│   │       └── radio_favorite_cubit.dart
│   ├── timeline/
│   │   └── bloc/
│   │       └── timeline_cubit.dart
│   └── transcript/
│       └── bloc/
│           └── transcript_cubit.dart
└── main.dart                          # Root cubit providers
```

---

## Summary

This app uses a **well-structured Cubit architecture** with:

1. **Clear separation** between global and feature-scoped state
2. **BlocPresentationMixin** for one-time events (dialogs, navigation)
3. **Efficient rebuilds** using `context.select()`
4. **Testable business logic** separated from UI
5. **Coordinated state** via GlobalCubitConnection

This architecture makes the app:
- Easy to test
- Easy to maintain
- Predictable and debuggable
- Scalable for new features

---

## Last Updated

2025-12-03