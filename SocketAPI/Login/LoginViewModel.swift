import FirebaseAuth

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
    
    func register(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                self.onError?(error.localizedDescription)
            } else {
                print("Kullanıcı oluşturuldu")
            }
        }
    }
}
