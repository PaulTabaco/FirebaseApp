import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class GroceryListTableViewController: UITableViewController {

  let ref = FIRDatabase.database().reference(withPath: "grocery-items")
  let usersRef = FIRDatabase.database().reference(withPath: "online")
  
  // MARK: Constants
  let LIST_TO_USER_SEGUE = "ListToUsersSegue"
  
  // MARK: Properties
  var items: [GroceryItem] = []
  var user: User!
  var userCountBarButtonItem: UIBarButtonItem!
  
  // MARK: UIViewController Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    ref.queryOrdered(byChild: "completed").observe(.value, with: { snapshot in
      var newItems: [GroceryItem] = []
      
      for item in snapshot.children {
        let groceryItem = GroceryItem(snapshot: item as! FIRDataSnapshot)
        newItems.append(groceryItem)
      }
      
      self.items = newItems
      self.tableView.reloadData()
    })
    
    tableView.allowsMultipleSelectionDuringEditing = false
    
    userCountBarButtonItem = UIBarButtonItem(title: "1",
                                             style: .plain,
                                             target: self,
                                             action: #selector(userCountButtonDidTouch))
    userCountBarButtonItem.tintColor = UIColor.white
    navigationItem.leftBarButtonItem = userCountBarButtonItem
    
    //user = User(uid: "FakeId", email: "hungry@person.food")
    
    FIRAuth.auth()!.addStateDidChangeListener { auth, user in
      guard let user = user else { return }
      self.user = User(authData: user)
      // 1
      let currentUserRef = self.usersRef.child(self.user.uid)
      // 2
      currentUserRef.setValue(self.user.email)
      // 3
      currentUserRef.onDisconnectRemoveValue()
    }
    
    usersRef.observe(.value, with: { snapshot in
      if snapshot.exists() {
        self.userCountBarButtonItem?.title = snapshot.childrenCount.description
      } else {
        self.userCountBarButtonItem?.title = "0"
      }
    })
    
  }
  
  // MARK: UITableView Delegate methods
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
    let groceryItem = items[indexPath.row]
    
    cell.textLabel?.text = groceryItem.name
    cell.detailTextLabel?.text = groceryItem.addedByUser
    
    toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
    
    return cell
  }
  
  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return true
  }
  
  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      let groceryItem = items[indexPath.row]
      groceryItem.ref?.removeValue()
    }
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
    guard let cell = tableView.cellForRow(at: indexPath) else { return }
    let groceryItem = items[indexPath.row]
    let toggledCompletion = !groceryItem.completed
    toggleCellCheckbox(cell, isCompleted: toggledCompletion)
    groceryItem.ref?.updateChildValues(["completed": toggledCompletion])
  }
  
  func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
    if !isCompleted {
      cell.accessoryType = .none
      cell.textLabel?.textColor = UIColor.black
      cell.detailTextLabel?.textColor = UIColor.black
    } else {
      cell.accessoryType = .checkmark
      cell.textLabel?.textColor = UIColor.gray
      cell.detailTextLabel?.textColor = UIColor.gray
    }
  }
  
  // MARK: Add Item
  
  @IBAction func addButtonDidTouch(_ sender: AnyObject) {
    let alert = UIAlertController(title: "Grocery Item",
                                  message: "Add an Item",
                                  preferredStyle: .alert)
    
    let saveAction = UIAlertAction(title: "Save",
                                   style: .default) { action in
                                    
      guard let textField = alert.textFields?.first,
        let text = textField.text else { return }
      
      let groceryItem = GroceryItem(name: text,
                                    addedByUser: self.user.email,
                                    completed: false)
                                    
      let groceryItemRef = self.ref.child(text.lowercased())
      
      groceryItemRef.setValue(groceryItem.toAnyObject())
                                    
      self.items.append(groceryItem)
      self.tableView.reloadData()
    }
    
    let cancelAction = UIAlertAction(title: "Cancel",
                                     style: .default)
    
    alert.addTextField()
    
    alert.addAction(saveAction)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  func userCountButtonDidTouch() {
    performSegue(withIdentifier: LIST_TO_USER_SEGUE, sender: nil)
  }
  
}
