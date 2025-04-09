import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class ProfileViewModel {
    
    // MARK: - Properties
    
    // Cinsiyet seçimi için options
    let genderOptions = ["Erkek", "Kadın", "Diğer"]
    
    // Orijinal değerleri saklayacak değişkenler
    var originalValues: [String: String] = [
        "name": "",
        "username": "",
        "age": "",
        "city": "",
        "gender": ""
    ]
    
    // Track which fields are being edited
    var editingFields: [String: Bool] = [
        "name": false,
        "username": false,
        "age": false,
        "city": false,
        "gender": false
    ]
    
    // Profil fotoğrafı için değişken
    var hasProfileImageChanged = false
    var selectedProfileImage: UIImage?
    
    // Kullanıcı verileri
    var name: String = ""
    var username: String = ""
    var age: Int?
    var city: String = ""
    var gender: String = ""
    var email: String = ""
    var uid: String = ""
    
    // MARK: - Methods
    
    // Firestore'dan kullanıcı verilerini getirir
    func fetchUserData(completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users").document(user.uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Hata: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(false)
                return
            }
            
            // Tüm alanları doldur
            self.name = data["name"] as? String ?? ""
            self.username = data["username"] as? String ?? ""
            self.age = data["age"] as? Int
            self.city = data["city"] as? String ?? ""
            self.gender = data["gender"] as? String ?? ""
            self.email = user.email ?? ""
            self.uid = user.uid
            
            // Orijinal değerleri sakla
            self.originalValues["name"] = self.name
            self.originalValues["username"] = self.username
            self.originalValues["age"] = self.age != nil ? "\(self.age!)" : ""
            self.originalValues["city"] = self.city
            self.originalValues["gender"] = self.gender
            
            completion(true)
        }
    }
    
    // Profil resmini yükler
    func loadProfileImage(userId: String, completion: @escaping (UIImage?) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        
        profileImageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            if let error = error {
                print("Profil fotoğrafı yükleme hatası: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let imageData = data, let image = UIImage(data: imageData) {
                completion(image)
            } else {
                completion(nil)
            }
        }
    }
    
    // Kullanıcı adının benzersiz olup olmadığını kontrol eder
    func checkUsernameUniqueness(username: String, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").whereField("username", isEqualTo: username).getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                completion(true) // Hata durumunda veya döküman yoksa benzersiz kabul et
                return
            }
            
            // Mevcut kullanıcının dışında aynı username'e sahip başka kullanıcı var mı?
            let isUnique = documents.allSatisfy { $0.documentID == currentUser.uid }
            completion(isUnique)
        }
    }
    
    // Profil resmini kaydeder
    func saveProfileImage(userId: String, completion: @escaping (Bool) -> Void) {
        let storage = Storage.storage()
        let storageRef = storage.reference()
        let profileImageRef = storageRef.child("profile_images/\(userId).jpg")
        
        // Eğer profil fotoğrafı kaldırıldıysa
        if selectedProfileImage == nil {
            profileImageRef.delete { error in
                if let error = error {
                    print("Profil fotoğrafı silinemedi: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
            return
        }
        
        // Yeni bir profil fotoğrafı yükleniyorsa
        guard let image = selectedProfileImage, let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(false)
            return
        }
        
        // Resmi Firebase'e yükle
        let _ = profileImageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Profil fotoğrafı yüklenemedi: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Başarıyla yüklendi
            completion(true)
        }
    }
    
    // Profil bilgilerini günceller
    func updateProfileData(userId: String, updatedData: [String: Any], completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        // Firestore'da güncelle
        db.collection("users").document(userId).updateData(updatedData) { error in
            if let error = error {
                print("Güncelleme hatası: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Profil başarıyla güncellendi!")
                completion(true)
            }
        }
    }
    
    // Güncellenmiş verileri toplar
    func collectUpdatedData() -> [String: Any] {
        var updatedData: [String: Any] = [:]
        
        if editingFields["name", default: false] {
            updatedData["name"] = name
        }
        
        if editingFields["username", default: false] {
            updatedData["username"] = username
        }
        
        if editingFields["age", default: false] {
            if let age = age {
                updatedData["age"] = age
            }
        }
        
        if editingFields["city", default: false] {
            updatedData["city"] = city
        }
        
        if editingFields["gender", default: false] {
            updatedData["gender"] = gender
        }
        
        return updatedData
    }
    
    // Form alanları validasyonu
    func validateFields() -> [String] {
        var validationErrors: [String] = []
        
        // İsim-soyisim validasyonu
        if editingFields["name", default: false] {
            if name.isEmpty {
                validationErrors.append("İsim-Soyisim alanı boş bırakılamaz.")
            } else {
                // Sadece harflerden ve boşluklardan oluşmalı
                let allowedCharacterSet = CharacterSet.letters.union(CharacterSet.whitespaces)
                if name.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                    validationErrors.append("İsim-Soyisim sadece harflerden oluşmalıdır.")
                }
                
                // Boşluk dahil en az 7 karakter olmalı
                if name.count < 7 {
                    validationErrors.append("İsim-Soyisim boşluk dahil en az 7 karakter olmalıdır.")
                }
                
                // Boşluk hariç en az 6 karakter kontrolü
                let nonSpaceCharacters = name.filter { !$0.isWhitespace }
                if nonSpaceCharacters.count < 6 {
                    validationErrors.append("İsim-Soyisim boşluk hariç en az 6 karakter olmalıdır.")
                }
            }
        }
        
        // Yaş validasyonu
        if editingFields["age", default: false] {
            if let age = age {
                let ageText = "\(age)"
                if ageText.isEmpty {
                    validationErrors.append("Yaş alanı boş bırakılamaz.")
                } else {
                    // Sadece rakamlardan oluşmalı
                    if !ageText.allSatisfy({ $0.isNumber }) {
                        validationErrors.append("Yaş sadece rakamlardan oluşmalıdır.")
                    } else if ageText.count > 3 {
                        validationErrors.append("Yaş en fazla 3 basamaklı olabilir.")
                    } else if age < 1 {
                        validationErrors.append("Yaş 0'dan büyük olmalıdır.")
                    }
                }
            } else {
                validationErrors.append("Yaş alanı boş bırakılamaz.")
            }
        }
        
        // Şehir validasyonu
        if editingFields["city", default: false] {
            if city.isEmpty {
                validationErrors.append("Şehir alanı boş bırakılamaz.")
            } else {
                // Sadece harflerden ve boşluklardan oluşmalı
                let allowedCharacterSet = CharacterSet.letters.union(CharacterSet.whitespaces)
                if city.rangeOfCharacter(from: allowedCharacterSet.inverted) != nil {
                    validationErrors.append("Şehir sadece harflerden oluşmalıdır.")
                }
                
                // En az 3 karakter olmalı
                if city.count < 3 {
                    validationErrors.append("Şehir en az 3 karakter olmalıdır.")
                }
            }
        }
        
        return validationErrors
    }
    
    // Herhangi bir alan düzenleniyor mu?
    func isAnyFieldEditing() -> Bool {
        return editingFields.values.contains(true) || hasProfileImageChanged
    }
    
    // Çıkış yap
    func logout() -> Bool {
        do {
            try Auth.auth().signOut()
            return true
        } catch {
            print("Çıkış yapılamadı: \(error.localizedDescription)")
            return false
        }
    }
    
    // Orijinal değerleri kaydet
    func updateOriginalValues() {
        originalValues["name"] = name
        originalValues["username"] = username
        originalValues["age"] = age != nil ? "\(age!)" : ""
        originalValues["city"] = city
        originalValues["gender"] = gender
    }
    
    // Alanları orijinal değerlerine sıfırla
    func resetFieldsToOriginalValues() {
        name = originalValues["name"] ?? ""
        username = originalValues["username"] ?? ""
        if let ageStr = originalValues["age"], let ageVal = Int(ageStr) {
            age = ageVal
        } else {
            age = nil
        }
        city = originalValues["city"] ?? ""
        gender = originalValues["gender"] ?? ""
    }
}
