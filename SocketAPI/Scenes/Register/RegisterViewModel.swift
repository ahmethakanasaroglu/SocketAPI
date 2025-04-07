import FirebaseAuth
import FirebaseFirestore

class RegisterViewModel {
    // MARK: - Callbacks
    var onRegisterSuccess: (() -> Void)?
    var onError: ((String, String) -> Void)?
    
    // MARK: - Validasyon Metodları
    func validateFields(name: String?, username: String?, email: String?, password: String?, age: String?, city: String?) -> (isValid: Bool, emptyFields: [String], errors: [String: String]) {
        var emptyFields: [String] = []
        var errors: [String: String] = [:]
        
        if name?.isEmpty ?? true { emptyFields.append("Adınız") }
        if username?.isEmpty ?? true { emptyFields.append("Kullanıcı Adı") }
        if email?.isEmpty ?? true { emptyFields.append("Email") }
        if password?.isEmpty ?? true { emptyFields.append("Şifre") }
        if age?.isEmpty ?? true { emptyFields.append("Yaş") }
        if city?.isEmpty ?? true { emptyFields.append("Şehir") }
        
        // Ad sadece string (sayı ve özel karakter içermemeli)
        if let name = name, !name.isEmpty {
            let nameRegex = "^[a-zA-ZğüşıöçĞÜŞİÖÇ ]+$"
            if !NSPredicate(format: "SELF MATCHES %@", nameRegex).evaluate(with: name) {
                errors["name"] = "Ad alanı sadece harflerden oluşmalıdır."
            }
        }
        
        // Yaş sadece integer değer olmalı
        if let ageText = age, !ageText.isEmpty {
            if Int(ageText) == nil {
                errors["age"] = "Yaş alanı sadece sayılardan oluşmalıdır."
            }
        }
        
        // Şehir sadece string (sayı ve özel karakter içermemeli)
        if let city = city, !city.isEmpty {
            let cityRegex = "^[a-zA-ZğüşıöçĞÜŞİÖÇ ]+$"
            if !NSPredicate(format: "SELF MATCHES %@", cityRegex).evaluate(with: city) {
                errors["city"] = "Şehir alanı sadece harflerden oluşmalıdır."
            }
        }
        
        let isValid = emptyFields.isEmpty && errors.isEmpty
        return (isValid, emptyFields, errors)
    }
    
    func validateAge(_ ageText: String) -> Bool {
        return Int(ageText) != nil
    }
    
    // MARK: - Register İşlemi
    func registerUser(name: String, username: String, email: String, password: String, age: Int, city: String, gender: String) {
        // Önce username'in benzersiz olup olmadığını kontrol et
        checkUsernameUniqueness(username) { [weak self] isUnique, error in
            guard let self = self else { return }
            
            if let error = error {
                self.onError?("Hata", "Kullanıcı adı kontrolü sırasında bir hata oluştu: \(error.localizedDescription)")
                return
            }
            
            if !isUnique {
                self.onError?("Kullanıcı Adı Mevcut", "Bu kullanıcı adı zaten kullanımda. Lütfen farklı bir kullanıcı adı seçin.")
                return
            }
            
            // Username benzersiz, kayıt işlemine devam et
            self.createFirebaseUser(name: name, username: username, email: email, password: password, age: age, city: city, gender: gender)
        }
    }
    
    // MARK: - Firebase İşlemleri
    private func checkUsernameUniqueness(_ username: String, completion: @escaping (Bool, Error?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            // Eğer bu username zaten kullanılıyorsa
            if let snapshot = snapshot, !snapshot.documents.isEmpty {
                completion(false, nil)
                return
            }
            
            completion(true, nil)
        }
    }
    
    private func createFirebaseUser(name: String, username: String, email: String, password: String, age: Int, city: String, gender: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.onError?("Kayıt Hatası", error.localizedDescription)
                return
            }
            
            guard let uid = result?.user.uid else {
                self.onError?("Hata", "Kullanıcı ID oluşturulamadı.")
                return
            }
            
            self.saveUserData(uid: uid, name: name, username: username, email: email, age: age, city: city, gender: gender)
        }
    }
    
    private func saveUserData(uid: String, name: String, username: String, email: String, age: Int, city: String, gender: String) {
        let db = Firestore.firestore()
        
        // Genişletilmiş kullanıcı bilgilerini Firestore'a kaydet
        let userData: [String: Any] = [
            "name": name,
            "username": username,
            "email": email,
            "uid": uid,
            "age": age,
            "city": city,
            "gender": gender,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(uid).setData(userData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.onError?("Veri Kayıt Hatası", "Kullanıcı verileri kaydedilemedi: \(error.localizedDescription)")
            } else {
                // Başarılı
                self.onRegisterSuccess?()
            }
        }
    }
}
