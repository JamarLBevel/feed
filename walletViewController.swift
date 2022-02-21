//
//  walletViewController.swift
//  StoryX
//
//  Created by jamar Bevel on 5/29/21.
//

import UIKit
import Stripe
import SafariServices
import Firebase

var cashOut : Bool!
struct recentActions {
    var RA : String
}
class walletViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate {
   
    
 let card = STPAddCardViewController()
    
    @IBOutlet weak var LastFour: UILabel!
    
    @IBOutlet weak var Balence: UILabel!
    
    @IBOutlet weak var CashOut: UIButton!
    
    @IBOutlet weak var AddCash: UIButton!
    
    @IBOutlet weak var PaymentMethod: UIButton!
    
    @IBOutlet weak var sxCard: UIImageView!
    
    @IBOutlet weak var recentTransactions: UITableView!
    
    var paymentMethodDone : Bool!
    override func viewDidLoad() {
        super.viewDidLoad()
        retrieveRT {
            self.recentTransactions.reloadData()
            print(self.recentTransactionsL)
        }
        view.backgroundColor = .black
        sxCard.layer.borderWidth = 1
        sxCard.layer.borderColor = UIColor.white.cgColor
        sxCard.clipsToBounds = true
        sxCard.layer.cornerRadius = 8
        CashOut.layer.cornerRadius = 26
        AddCash.layer.cornerRadius = 26
        PaymentMethod.layer.cornerRadius = 26
        sxCard.contentMode = .scaleAspectFit
        sxCard.image = UIImage(named: "sxCard")
        recentTransactions.delegate = self
        recentTransactions.dataSource = self
        recentTransactions.register(UINib(nibName: walletTableViewCell().identifier, bundle: nil), forCellReuseIdentifier: walletTableViewCell().identifier)
        Stripe.setDefaultPublishableKey("pk_test_J2ypYMWfgw6sCeUyhyG0BD9S")
        recentTransactions.allowsSelection = false
        recentTransactions.backgroundColor = .black
        print(self.recentTransactionsL)
        
        getBalence()
    paymentMethodBool()
  
    }
    
    @IBAction func CashOut(_ sender: UIButton) {
        if paymentMethodDone == true {
        cashOut = true
    performSegue(withIdentifier: "AddCashToDigits", sender: self)
        }
        else {
          alert()
        }
    }
    
    @IBAction func AddCash(_ sender: UIButton) {
        if paymentMethodDone == true {
        cashOut = false
    performSegue(withIdentifier: "AddCashToDigits", sender: self)
        }
        else {
            alert()
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier ==  "AddCashToDigits" {
            if let walletToAddCash = segue.destination as? addCashViewController {
               
            }
        else {
         return
            }
        }
    }
    func alert(){
        let alert = UIAlertController(title: "payment method", message: "Please authenticate and add a payment metohd", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    func paymentMethodBool(){
        let db = Firestore.firestore()
        let uid = Firebase.Auth.auth().currentUser?.uid
        db.collection("user").document(uid!).getDocument { document, err in
            let c = document?.data()?["stripe"] as? String
            if c == nil {
                self.paymentMethodDone = false
            }
            else {
                self.paymentMethodDone = true
            }
        }
    }
    @IBAction func PaymentMethod(_ sender: UIButton) {

           editOrBoard()
    }

    @IBAction func RecentTransactions(_ sender: UIButton) {
    }
    
    
    
    @IBAction func back(_ sender: UIButton) {
        dismiss(animated: false, completion: nil)
//        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
//        let v = storyBoard.instantiateViewController(identifier: "SXFeedCollectionViewController")
//        show(v, sender: self)
    }
        
    func getBalence(){
        let db = Firestore.firestore()
        let uid = Firebase.Auth.auth().currentUser?.uid
        db.collection("user").document(uid!).getDocument { document, errr in
            let balenceDB = document?.data()?["balence"] as? Int ?? 0
            self.Balence.text = String("$") + String(balenceDB)
            
        }
    }
    
    func fleFetch(completion: @escaping () -> Void){
        
        let db = Firestore.firestore()
        let uuidFromUser = Auth.auth().currentUser?.uid
        print("time\(uuidFromUser!)")
        db.collection("user").whereField("uid", isEqualTo: uuidFromUser!).getDocuments { love, err in
            if let errrrr = err {
                print(errrrr.localizedDescription)
            }
            else {
                for document in love!.documents {
                    
                    let firstName = document.data()["firstname"] as? String ?? ""
                    let lastName = document.data()["lastname"] as? String ?? ""
                    let email = document.data()["email"] as? String ?? ""
                    let json = ["first_name":firstName,"last_name":lastName,"email":email]
                    let httpBody = try? JSONSerialization.data(withJSONObject: json, options: [])
                    let url = URL(string: "http://127.0.0.1:5000/user")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.httpBody = httpBody
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    let task = URLSession.shared.dataTask(with: request) { data, response, err in
                        
                        guard let response = response else {return}
                        print(response)
                        print(err ?? "")
                        print(data ?? "")
                    
                    }
                    task.resume()
                completion()
                }
                
            }
           
            
        }
        
        
    }
    
    
    func editOrBoard(){
        let db = Firestore.firestore()
        let uid = Firebase.Auth.auth().currentUser?.uid
        db.collection("user").document(uid!).getDocument { document, err in
            print(err?.localizedDescription ?? "")
            let stripe = document?.data()?["stripe"] as? String
            if stripe != nil {
                print("editing stripe A")
                
                self.editUser()
            }
            else {
                print("creating stripe A")
                self.onboardUser()
            }
        
        }
    }
    
    func editUser(){
        let db = Firestore.firestore()
        let uid = Firebase.Auth.auth().currentUser?.uid
        
        db.collection("user").document(uid!).getDocument { document, err in
          let stripeUID = document?.data()?["stripe"] as? String
            print(err?.localizedDescription ?? "")
            if stripeUID != nil {
        let url = URL(string: "http://127.0.0.1:5000/edit")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let json =  ["sid" : stripeUID!]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: json, options: []) else {
              return
          }
        print(json)
        request.httpBody = httpBody
        let task = URLSession.shared.dataTask(with: request) { data, response, err in
            guard let data = data,
                        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            else {
                return
            }
        print(json)
            let accountURL = URL(string: json["url"] as! String)
            let safariViewController = SFSafariViewController(url: accountURL!)
                        safariViewController.delegate = self
            
                        DispatchQueue.main.async {
                            safariViewController.preferredBarTintColor = .black
                            safariViewController.preferredControlTintColor = .black
                            safariViewController.view.backgroundColor = .black
                            self.present(safariViewController, animated: true, completion: nil)
                       
                        }
        }
        task.resume()
            }
            else {
                print("idk what happened man")
            }
        }
    }
    
    func onboardUser(){
        let url =  URL(string: "http://127.0.0.1:5000/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, err in
            guard let data = data,
                            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                            let accountURLString = json["url"] as? String,
                            let accountURL = URL(string: accountURLString) else {
                                // handle error
                        return
            }
            
            let safariViewController = SFSafariViewController(url: accountURL)
                        safariViewController.delegate = self
            
                        DispatchQueue.main.async {
                            safariViewController.preferredBarTintColor = .black
                            safariViewController.preferredControlTintColor = .black
                            safariViewController.view.backgroundColor = .black
                            self.present(safariViewController, animated: true, completion: nil)
                       
                        }
        
            
        
        }
    
        task.resume()
    
    
    
    
    }
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        
       checkID()
        
    }
    
    func checkID(){
        let db = Firestore.firestore()
        let uid = Firebase.Auth.auth().currentUser?.uid
        db.collection("user").document(uid!).getDocument { document, err in
            let stripe = document?.data()?["stripe"] as? String
            if stripe == nil {
                self.putID()
            }
            else{
                print("account is already made")
            return
            }
        }
       
    }
    
    func putID() {
        let url =  URL(string: "http://127.0.0.1:5000/AC")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, err in
            guard let data = data,
                        let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
            else {
                return
            }
            let accountIdentification = json["id"] as? String
            let logisticsDone = json["done"] as? Bool
            
            if logisticsDone == true {
                let uid =  Firebase.Auth.auth().currentUser?.uid
                let db = Firestore.firestore()
                db.collection("user").document(uid!).setData(["stripe" : accountIdentification ?? ""], merge: true) { ree in
                    print(ree?.localizedDescription ?? "")
                }
            }
            else {
                print("did not finish sign up process")
                let alert = UIAlertController(title: "incomplete", message: "did not finish payment method", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Okay", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            return
            }
            
        
        }
    
        task.resume()
    
    }
    var recentTransactionsL : [Any] = []
    func retrieveRT(completion: @escaping () -> Void){
        let db = Firestore.firestore()
        let uid = Firebase.Auth.auth().currentUser?.uid
        db.collection("user").document(uid!).getDocument { document, err in
            
            let d = document?.data()?["recentActions"] as? [String]
            if d != nil {
            self.recentTransactionsL = d!
            print(self.recentTransactionsL.first!)
           completion()
            }
            else {
                print("user has no actions")
            }
            }
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recentTransactionsL.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : walletTableViewCell = recentTransactions.dequeueReusableCell(withIdentifier: "walletTableViewCell", for: indexPath) as! walletTableViewCell
        
        cell.recentLabel.text = "\(self.recentTransactionsL[indexPath.row])"
        cell.recentLabel.textColor = .white
        cell.backgroundColor = .black
        cell.contentView.layer.masksToBounds = true
        cell.contentView.layer.cornerRadius = 10
       
        
        
        
        return cell
    }
    

}
