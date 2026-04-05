import Foundation

// ─────────────────────────────────────────────────────────────────
//  SETUP REQUIRED
//  1. Open Firebase Console → Project Settings → General
//  2. Copy "Web API Key" → paste into apiKey
//  3. Copy "Project ID"  → paste into projectId
// ─────────────────────────────────────────────────────────────────
enum FirebaseConfig {
    static let apiKey     = "YOUR_FIREBASE_API_KEY"
    static let projectId  = "YOUR_FIREBASE_PROJECT_ID"

    static let authURL      = "https://identitytoolkit.googleapis.com/v1"
    static let firestoreURL = "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents"
}
