//
//  NotesTableViewController.swift
//  Notes
//
//  Created by Kirill Smirnov on 25.09.2023.
//

import UIKit
import CoreData

class NotesTableViewController: UITableViewController {
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    var notes: [Note]?
    var selectedCategory : NoteCategory? {
        didSet{
            loadNotes()
            print("selectedCategory DIDSET")
            //            tableView.separatorStyle = .none
            tableView.estimatedRowHeight = 400
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.automaticallyAdjustsScrollIndicatorInsets = true
        tableView.register(NoteTableViewCell.self, forCellReuseIdentifier: NoteTableViewCell.identifier)
        tableView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(longPressGestureRecognizer:))))
        
        let searchBar = UISearchBar()
        searchBar.frame = CGRect(x: 0, y: 0, width: 200, height: 70)
        searchBar.delegate = self
        searchBar.showsCancelButton = false
        searchBar.searchBarStyle = UISearchBar.Style.default
        searchBar.placeholder = "_ "
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar
        
        let addNoteButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addNote))
        self.navigationItem.rightBarButtonItems = [addNoteButton]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        title = selectedCategory?.title
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        tableView.reloadData()
        print("orientation")
    }
    
    
    @objc func addNote(){
        var textField = UITextField()
        let alert = UIAlertController(title: "", message: "Add new Note", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add", style: .default) { action in
            if (textField.text?.count != 0) {
                if soundOn { playSound(sound: "Popup") }
                let newNote = Note(context: self.context)
                newNote.category = self.selectedCategory // .category comes from CoreData relation !
                newNote.text = textField.text
                newNote.isDone = false
                newNote.dateCreated = Date()
                self.notes?.append(newNote)
                self.saveNotes()
            }
        }
        alert.addTextField { alertTextField in
            alertTextField.keyboardType = .asciiCapable
            alertTextField.placeholder = "Note name, like \"buy milk tomorrow\""
            textField = alertTextField //to use textField above
        }
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    @objc func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let index = self.tableView.indexPathForRow(at: touchPoint)  {
                print("longPress \(String(describing: notes?[index.row].text))")
                
                let alertTextOfNote = String(notes?[index.row].text ?? "")
                let alert = UIAlertController(title: "", message: "Delete \(alertTextOfNote) ?" , preferredStyle: .alert)
                let no = UIAlertAction(title: "No", style: .cancel)
                let yes = UIAlertAction(title: "Yes", style: .destructive) { [self] action in
                    let note = self.notes?[index.row]
                    self.context.delete(note!)
                    notes?.remove(at: index.row)
                    if soundOn { playSound(sound: "Recycle") }
                    saveNotes()
                }
                alert.addAction(yes)
                alert.addAction(no)
                present(alert, animated: true)
            }
        }
    }
    
    // MARK: - loading and saving
    
    func saveNotes() {
        print("saving context, Notes")
        do {
            try self.context.save()
        }
        catch {
            print(error.localizedDescription)
        }
        loadNotes()
        tableView.reloadData()
        print("reloading tableView after saving")
    }
    
    func loadNotes(_ request: NSFetchRequest<Note> = Note.fetchRequest(), predicateTo: NSPredicate? = nil) { // just adding a default parameter Note.fetchRequest()
        //        print(selectedCategory)
        notes = nil
        request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
        let predicateCategory = NSPredicate(format: "category.title MATCHES %@", selectedCategory!.title!) // "category.title" is a relationshop from DataModel
        if let additionalPredicate = predicateTo {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateCategory, additionalPredicate])
        } else {
            request.predicate = predicateCategory
        }
        
        do {
            notes = try context.fetch(request)
            print("fetching context")
        }
        catch {
            print(error.localizedDescription)
        }
        tableView.reloadData()
        
        print("reloading tableView after fetching")
    }
    
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoteTableViewCell.identifier, for: indexPath) as? NoteTableViewCell else {return UITableViewCell()}
        if let note = notes?[indexPath.row]{
            cell.accessoryType = note.isDone ? .checkmark : .none
            cell.configure(note: note)
        } else {
            cell.textLabel?.text = "No items added"
        }
        cell.layoutIfNeeded() //to hold size of the label
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        notes![indexPath.row].isDone.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            tableView.deselectRow(at: indexPath, animated: true)
            tableView.reloadData()
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
}

// MARK: - SearchBar

extension NotesTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if !searchText.isEmpty {
            let rqst : NSFetchRequest<Note> = Note.fetchRequest()
            let predicate = NSPredicate(format: "text CONTAINS[cd] %@", searchText)
            rqst.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
            self.loadNotes(rqst, predicateTo: predicate)
        } else {
            searchBar.resignFirstResponder()
            self.loadNotes()
        }
        
    }
}
