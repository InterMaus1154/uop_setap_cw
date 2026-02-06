# setap - Work Tracking Document (will make it easier for claudia)

Use this document to log your contributions. Add new entries at the top.

---

## Entry Template

```
### [Your Name and up number] - [Date] [Time]
**Summary:** Brief description of what you did

**Files Modified/Created:**
- path/to/file1
- path/to/file2

**Notes:** Any additional context
```

---

## Entries

### Josh up2255832 - 06/02/2026
**Summary:** Built pin creation form UI with bottom sheet, tap-to-place flow, category-based auto-expiry, and performed strict code review with fixes

**Files Created:**
- frontend/lib/widgets/pin_creation_sheet.dart (bottom sheet form with category/subcategory dropdowns, title, description, auto TTL display)
- frontend/lib/models/pin_form_data.dart (extracted data class for form submission, includes toJson for API)

**Files Modified:**
- frontend/lib/screens/map_screen.dart (pin placement mode, tap-to-place marker, confirm location flow, bottom sheet integration, added MapController dispose)
- frontend/lib/models/category.dart (renamed catLevelPins to catLevelTtlMins to match backend schema, added explicit type casting in fromJson)
- frontend/lib/models/pin.dart (added explicit type casting in fromJson for null safety)
- frontend/lib/models/user.dart (added explicit type casting in fromJson)
- frontend/lib/services/api_service.dart (added TimeoutException handling, extracted timeout to constant)
- frontend/lib/screens/user_selection_screen.dart (fixed _getInitials to handle empty strings)

**Issues encountered and resolved:**
1. Dropdown assertion error when switching categories — subcategory dropdown held stale state. Fixed by adding ValueKey to force widget rebuild.
2. Deprecated `value` parameter in DropdownButtonFormField (Flutter 3.33+) — removed deprecated usage.
3. `firstWhere` in _ttlMinutes could throw if no matching level found — added try-catch with graceful fallback.
4. JSON parsing had no null safety — added explicit `as Type` casts to all model fromJson methods to catch bad data at parse time.
5. TimeoutException not caught in ApiService — added explicit catch block.
6. MapController memory leak — added dispose() method.
7. _getInitials crash on empty firstName/lastName — added defensive checks with '?' fallback.

**Notes:** Pin creation is fully functional UI-wise but does NOT save to database — purely mock/testing. Categories and subcategories are hardcoded to match seed data. Auto-expiry calculates from category level TTL (Danger=60min, Information=120min, Level 3=180min). All frontend model JSON keys verified to match backend column names exactly.

**Backend team action needed:** To complete this feature, please create:
1. `routes/pins.py` with `GET /pins/` and `POST /pins/` endpoints
2. `routes/categories.py` with `GET /categories/`, `GET /category-levels/`, `GET /sub-categories/` endpoints
3. Register routers in `main.py`

Once endpoints exist, I can wire up the API calls and remove hardcoded data.

---

### Josh up2255832 - 03/02/2026
**Summary:** Built out frontend models and map screen in preparation for backend endpoints

**Files Modified/Created:**
- frontend/lib/models/category.dart (CategoryLevel, Category, SubCategory models)
- frontend/lib/models/pin.dart (Pin, PinReaction models with safe num to double casting for coordinates)
- frontend/lib/screens/home_screen.dart (wrapper for MapScreen)
- frontend/lib/screens/map_screen.dart (OpenStreetMap integration, campus centered on Portsmouth, recenter button, logout flow, placeholder for pin creation)

**Notes:** Read the erd, frontend models are aligned with backend DB schema and ready for API integration. Added defensive casting for latitude/longitude to handle int/double JSON inconsistencies.(this issue was alerted from a code review by the flutter discord community) Map screen has UI scaffolding, just needs pin fetching and creation endpoints wired up.

---

### Josh up2255832 - 31/01/2026 
**Summary:** Created test user flow branch with fake login system for UI testing

**Files Modified/Created:**
- frontend/lib/main.dart
- frontend/lib/models/user.dart
- frontend/lib/providers/user_provider.dart
- frontend/lib/services/api_service.dart
- frontend/lib/screens/user_selection_screen.dart
- frontend/lib/screens/home_screen.dart
- backend/main.py (added CORS, included users router) sorry for fiddling with backend mark XD 

**Notes:** Users can select from DB users to "login" without OAuth. Placeholder for map screen. minor work i did on the backend -  CORS properly configured, Router included correctly
questions i asked: could the user_selection_screen be split to remove a single long file, i asked the flutter discord and they informed me that there is no need. 
---
