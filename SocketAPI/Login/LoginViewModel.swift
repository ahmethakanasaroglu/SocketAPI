import FirebaseAuth
import FirebaseFirestore

class LoginViewModel {
    
    var onLoginSuccess: (() -> Void)?
    var onError: ((String) -> Void)?
    
    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                self.onError?(error.localizedDescription)
            } else {
                self.onLoginSuccess?()
            }
        }
    }
    
    func register(name: String, email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Kayıt hatası: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let uid = result?.user.uid else {
                print("UID bulunamadı!")
                completion(false)
                return
            }
            
            let db = Firestore.firestore()
            let userData: [String: Any] = ["name": name, "email": email, "uid": uid]
            
            db.collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    print("Firestore'a kaydedilemedi: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("🔥 Kullanıcı Firestore'a başarıyla kaydedildi! UID: \(uid)")
                    completion(true)
                }
            }
        }
    }
}
