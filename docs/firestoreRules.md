rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Match the folder structure: users/uid/category/filename
    match /users/{userId}/{category}/{fileName} {
      
      // 1. Allow any authenticated user to READ images
      // (This allows Seekers to see Assistant NICs/certificates if needed)
      allow read: if request.auth != null;

      // 2. Only the owner of the folder can WRITE (upload/delete)
      // We compare the userId in the path to the uid of the logged-in user
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Default rule: deny everything else for safety
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
