# API Endpoints

## Base Configuration

**Production URL:** Configured via `API_URL` in `.env.json`

**Local Development:**
```bash
flutter run --dart-define=API_URL=http://localhost:5001/
```

## Authentication Headers

All requests include the following headers:
- `X-API-KEY`: `{apiKey}` (from `.env.json`)
- `X-App-User`: `{deviceId}` (unique device identifier)
- `Auth`: `{token}` (when user is authenticated - currently not used)

## Endpoints Summary

| Endpoint | Used By | Required for App |
|----------|---------|------------------|
| `/broadcasters` | RadioListCubit, RadioListSearchCubit, RadioListCityCubit | ✅ Essential |
| `/get_city` | RadioListCubit | ✅ Essential |
| `/broadcasters/cities` | RadioListSearchCubit | ✅ Essential |
| `/metadata/{radioSlug}/chunks/{chunkId}` | TranscriptCubit | ⚠️ Optional (transcript feature) |
| `/streams/{radioSlug}/fft/{chunkId}` | VisualCubit | ⚠️ Optional (visualization feature) |
| `http://localhost:5003/radio/epg/{epgSlug}` | TimeLineCubit | ✅ Essential |
| `/metadata/translations/languages` | TranscriptCubit | ⚠️ Optional (transcript feature) |
| `/subscriptions/{deviceId}` | SessionCubit | ❌ **DEPRECATED** (purchase system removed) |
| `/check-eligibility/{deviceId}` | N/A | ❌ **DEPRECATED** (never used, purchase removed) |
| `/subscriptions/{deviceId}/spend/30` | TranscriptCubit | ❌ **DEPRECATED** (purchase system removed) |

## Endpoints

### 1. Load Radio Station List ✅ **ESSENTIAL**
**GET** `/broadcasters`

Load list of radio stations, optionally filtered by location or search query.

**Used by:**
- `lib/features/radio_list/cubit/radio_list_cubit.dart` - Main radio list
- `lib/features/radio_list/cubit/radio_list_search_cubit.dart` - Search functionality
- `lib/features/radio_list/cubit/radio_list_city_cubit.dart` - City-based radio list

**Parameters:**
- `source`: `"mobile_app"` (required)
- `lat`: Latitude (optional, for location-based results)
- `lng`: Longitude (optional, for location-based results)
- `q`: Search query (optional)

**Response:** `RadioListResponse`

**Response Structure:**
```json
[
  {
    "id": "string",
    "prefix": "string",
    "provider": "string",
    "streamName": "string",
    "description": "string",
    "genres": ["string"],
    "network": "string",
    "language": "de",
    "streamUrl": {
      "source": "https://...",
      "hls": "http://...",
      "dash": "http://..."
    },
    "epgPrefix": "string",
    "imgUrl": "string",
    "thumbnailUrl": "string",
    "logoBgColor": "#FFFFFF",
    "showInApp": true,
    "podcasts": ["https://..."]
  }
]
```

---

### 2. Get City by Coordinates ✅ **ESSENTIAL**
**GET** `/get_city`

Retrieve city information based on GPS coordinates.

**Used by:** `lib/features/radio_list/cubit/radio_list_cubit.dart`

**Parameters:**
- `source`: `"mobile_app"` (required)
- `lat`: Latitude (required)
- `lng`: Longitude (required)

**Response:** `CityResponse`

---

### 3. Search Cities ✅ **ESSENTIAL**
**GET** `/broadcasters/cities`

Search for cities by query string.

**Used by:** `lib/features/radio_list/cubit/radio_list_search_cubit.dart`

**Parameters:**
- `source`: `"mobile_app"` (required)
- `query`: Search query (required)

**Response:** `CityListResponse`

---

### 4. Load Transcript ⚠️ **OPTIONAL**
**GET** `/metadata/{radioSlug}/chunks/{chunkId}`

Load transcript data for a specific radio station and audio chunk.

**Used by:** `lib/features/transcript/bloc/transcript_cubit.dart`

**Path Parameters:**
- `radioSlug`: Radio station identifier (required)
- `chunkId`: Audio chunk ID (required)

**Query Parameters:**
- `lang`: Language code (optional, e.g., "de", "en")

**Response:** `TranscriptResponse`

---

### 5. Load Visual/Audio Data ⚠️ **OPTIONAL**
**GET** `/streams/{radioSlug}/fft/{chunkId}`

Load FFT (Fast Fourier Transform) visual/audio frequency data for visualizations.

**Used by:** `lib/features/visual/visual_cubit.dart`

**Path Parameters:**
- `radioSlug`: Radio station identifier (required)
- `chunkId`: Audio chunk ID (required)

**Response:** `VisualBandsResponse`

---

### 6. Load Electronic Program Guide ✅ **ESSENTIAL**
**GET** `http://localhost:5003/radio/epg/{epgSlug}`

Load EPG (Electronic Program Guide) data for a radio station's schedule.

**Used by:** `lib/features/timeline/bloc/timeline_cubit.dart`

**Path Parameters:**
- `epgSlug`: EPG identifier (required)

**Query Parameters:**
- `limit`: Number of results (required)
- `skip`: Number of results to skip (required)

**Response:** `EpgResponseResponse`

**Notes:**
- Hardcoded to `http://localhost:5003` in repository.dart (line 133)
- Should be configurable via environment variable
- This endpoint is on a different port than the main API

---

### 7. Get Translation Languages ⚠️ **OPTIONAL**
**GET** `/metadata/translations/languages`

Retrieve list of available translation languages for transcript feature.

**Used by:** `lib/features/transcript/bloc/transcript_cubit.dart`

**Response:** `LangListResponse`

---

### 8. Get User Subscription Info ❌ **DEPRECATED**
**GET** `/subscriptions/{deviceId}`

**Status:** Purchase system removed in commit `ca496ff` (Nov 17, 2025)

Load subscription information for a device.

**Used by:** `lib/features/auth/session_cubit.dart` (still called but response ignored)

**Path Parameters:**
- `deviceId`: Device identifier (required)

**Response:** `UserInfoResponse` (timeLeft hardcoded to 0, no plan data)

**Note:** This endpoint is still called but the subscription data is no longer parsed or used. Can be safely removed.

---

### 9. Check Subscription Eligibility ❌ **DEPRECATED**
**GET** `/check-eligibility/{deviceId}`

**Status:** Never used, purchase system removed

Check if a device is eligible for subscription features.

**Used by:** N/A (never implemented in app)

**Path Parameters:**
- `deviceId`: Device identifier (required)

**Response:** `EligibilityResponse`

**Note:** This endpoint exists in repository.dart but is never called from the app.

---

### 10. Track Usage Time ❌ **DEPRECATED**
**PUT** `/subscriptions/{deviceId}/spend/30`

**Status:** Purchase system removed in commit `ca496ff` (Nov 17, 2025)

Track 30 seconds of app usage time for subscription management.

**Used by:** `lib/features/transcript/bloc/transcript_cubit.dart` (commented out or unused)

**Path Parameters:**
- `deviceId`: Device identifier (required)

**Body:**
```json
{
  "deviceId": "string"
}
```

**Response:** `ServerResponse`

**Note:** This endpoint tracked free tier usage limits. No longer needed since app is fully free.

---

## Endpoints Required for Mock Server

For basic app functionality, you need to mock these **essential endpoints**:

1. **`GET /broadcasters`** - Radio station list (with podcasts field added for pi-radio and slubfurt)
2. **`GET /get_city`** - City lookup by coordinates
3. **`GET /broadcasters/cities`** - City search
4. **`GET http://localhost:5003/radio/epg/{epgSlug}`** - Program guide (separate service)

**Optional** (transcript and visualization features):
- `GET /metadata/{radioSlug}/chunks/{chunkId}` - Transcript data
- `GET /streams/{radioSlug}/fft/{chunkId}` - FFT visualization data
- `GET /metadata/translations/languages` - Translation languages

**Not needed** (deprecated purchase system):
- `GET /subscriptions/{deviceId}`
- `GET /check-eligibility/{deviceId}`
- `PUT /subscriptions/{deviceId}/spend/30`

See `../api-faker/` for a Node.js mock server implementation.

## Implementation Details

All API calls are implemented in `/lib/data/api/repository.dart` using the `HttpApi` wrapper class which handles:
- Request/response interceptors
- Timeout configuration (30 seconds)
- Error handling
- Authentication token management
- Automatic logout on 401 responses

## Local Development Setup

To use a local API server during development:

1. **Command Line:**
   ```bash
   flutter run --dart-define=API_URL=http://localhost:8000/
   ```

2. **IntelliJ/Android Studio:**
   - Edit Configurations → Additional run args
   - Add: `--dart-define=API_URL=http://localhost:8000/`

3. **For Physical Devices (use your machine's local IP):**
   ```bash
   flutter run --dart-define=API_URL=http://192.168.1.100:8000/
   ```

The app requires `API_URL` to be specified in `.env.json`. It will fail with an error if not configured.