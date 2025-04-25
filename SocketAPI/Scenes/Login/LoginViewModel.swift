import FirebaseAuth
import FirebaseFirestore

class LoginViewModel {
    
    var onLoginSuccess: (() -> Void)?
    var onError: ((String) -> Void)?
    var onPasswordResetSent: (() -> Void)?
    
    // Email veya username ile login işlemi
    func login(emailOrUsername: String, password: String) {
        // Eğer "@" içeriyorsa, bu bir email'dir
        if emailOrUsername.contains("@") {
            // Direkt email ile giriş yap
            loginWithEmail(email: emailOrUsername, password: password)
        } else {
            // Kullanıcı adı ile giriş yap (önce email'i bul)
            loginWithUsername(username: emailOrUsername, password: password)
        }
    }
    
    // Email ile login
    private func loginWithEmail(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.onError?(error.localizedDescription)
            } else {
                self.onLoginSuccess?()
            }
        }
    }
    
    // Username ile login (önce Firestore'dan email'i bulur)
    private func loginWithUsername(username: String, password: String) {
        let db = Firestore.firestore()
        
        // Username'e göre kullanıcıyı sorgula
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { [weak self] (querySnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.onError?("Sorgulama hatası: \(error.localizedDescription)")
                return
            }
            
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                self.onError?("Kullanıcı adı bulunamadı")
                return
            }
            
            // Kullanıcı adına karşılık gelen email'i al
            guard let userData = documents.first?.data(),
                  let email = userData["email"] as? String else {
                self.onError?("Kullanıcı bilgileri eksik")
                return
            }
            
            // Bulunan email ile giriş yap
            self.loginWithEmail(email: email, password: password)
        }
    }
   
    
    // ŞİFREMİ UNUTTUM FONKSİYONU
    func resetPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.onError?(error.localizedDescription)
            } else {
                self.onPasswordResetSent?()
            }
        }
    }
}
