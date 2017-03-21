import Foundation
import Firebase
import FirebaseAuth

struct User {
  
  let uid: String
  let email: String
  
  init(authData: FIRUser) {
    uid = authData.uid
    email = authData.email!
  }
  
  init(uid: String, email: String) {
    self.uid = uid
    self.email = email
  }
  
}
