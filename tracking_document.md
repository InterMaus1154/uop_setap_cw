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
