//
//  CategoriesTableViewController.swift
//  Notes
//
//  Created by Kirill Smirnov on 24.09.2023.
//

import UIKit
import CoreData

class CategoriesTableViewController: UITableViewController {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var caregories = [NoteCategory]()
    
    
    override func viewDidLoad() {
        print("\(self) viewDidLoad")
        soundOn = userDefaults.bool(forKey: "soundOn")
        if let favCategory = userDefaults.string(forKey: "FavoriteCategory") { print(favCategory) }
        
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell") //register cell name
        //        self.navigationItem.title = "Categories"
        self.navigationController!.navigationBar.topItem!.title = ""
        
        tableView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(longPressGestureRecognizer:))))
        
        let addCategoryButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addCategory))
        self.navigationItem.rightBarButtonItems = [addCategoryButton]
        
        loadCategories()
    }
    
    
    @objc func addCategory(){
        var textField = UITextField()
        let alert = UIAlertController(title: "", message: "Add new category", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add >", style: .default) { action in
            //            print(textField.text)
            if (textField.text?.count != 0) {
                if soundOn { playSound(sound: "Popup") }
                let newCategory = NoteCategory(context: self.context)
                newCategory.title = textField.text
                self.caregories.append(newCategory)
                self.saveCategories()
            }
        }
        alert.addTextField { alertTextField in
            alertTextField.keyboardType = .asciiCapable
            alertTextField.placeholder = "Category name, like \"shopping list\""
            textField = alertTextField //to use textField above
        }
        alert.addAction(action)
        
        present(alert, animated: true)
    }
    
    @objc func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let index = self.tableView.indexPathForRow(at: touchPoint)  {
                print("longPress \(String(describing: caregories[index.row].title))")
                
                let alertTextOfCategory = String(caregories[index.row].title ?? "")
                let alert = UIAlertController(title: "", message: "Delete \(alertTextOfCategory) ?" , preferredStyle: .alert)
                let no = UIAlertAction(title: "No", style: .cancel)
                let yes = UIAlertAction(title: "Yes", style: .destructive) { [self] action in
                    let category = self.caregories[index.row]
                    self.context.delete(category)
                    caregories.remove(at: index.row)
                    if soundOn { playSound(sound: "Recycle") }
                    saveCategories()
                }
                alert.addAction(yes)
                alert.addAction(no)
                present(alert, animated: true)
            }
        }
    }
    
    // MARK: - loading and saving
    
    func saveCategories() {
        print("saving context, Categories")
        do {
            try self.context.save()
        }
        catch {
            print(error.localizedDescription)
        }
        self.tableView.reloadData()
        print("reloading tableView")
    }
    
    func loadCategories() {
        let request: NSFetchRequest<NoteCategory> = NoteCategory.fetchRequest() //always specify a Type
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        do {
            caregories = try context.fetch(request)
            print("fetching context")
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (caregories.count != 0) {
            return caregories.count }
        else {
            return 1
        }
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if (caregories.count != 0) {
            cell.textLabel?.text = caregories[indexPath.row].title
            cell.sizeToFit()
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            cell.textLabel?.numberOfLines = 3
        } else {
            cell.textLabel?.text = "Add categories of notes using + "
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt")
        if !caregories.isEmpty {
            let notesVC = NotesTableViewController()
            notesVC.selectedCategory = caregories[indexPath.row]
            navigationController?.pushViewController(notesVC, animated: true)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alertTextOfCategory = String(caregories[indexPath.row].title ?? "")
            let alert = UIAlertController(title: "", message: "Delete \(alertTextOfCategory) ?" , preferredStyle: .alert)
            let no = UIAlertAction(title: "No", style: .cancel)
            let yes = UIAlertAction(title: "Yes", style: .destructive) { [self] action in
                let category = self.caregories[indexPath.row]
                self.context.delete(category)
                caregories.remove(at: indexPath.row)
                if soundOn { playSound(sound: "Recycle") }
                saveCategories()
            }
            alert.addAction(yes)
            alert.addAction(no)
            present(alert, animated: true)
        }
    }

    
}
