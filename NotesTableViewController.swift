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
    
    
    @objc func addNote() {
        let alertController = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .alert)
        let textView = UITextView(frame: CGRect.zero)
        alertController.view.addSubview(textView)

        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if !textView.text.isEmpty {
                let newNote = Note(context: self.context)
                newNote.category = self.selectedCategory
                newNote.text = textView.text
                newNote.isDone = false
                newNote.dateCreated = Date()
                self.notes?.append(newNote)
                self.saveNotes()
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }

        alertController.addAction(addAction)
        alertController.addAction(cancelAction)

        textView.translatesAutoresizingMaskIntoConstraints = false
        let leadConstraint = NSLayoutConstraint(item: alertController.view!, attribute: .leading, relatedBy: .equal, toItem: textView, attribute: .leading, multiplier: 1.0, constant: -8.0)
        let trailConstraint = NSLayoutConstraint(item: alertController.view!, attribute: .trailing, relatedBy: .equal, toItem: textView, attribute: .trailing, multiplier: 1.0, constant: 8.0)

        let topConstraint = NSLayoutConstraint(item: alertController.view!, attribute: .top, relatedBy: .equal, toItem: textView, attribute: .top, multiplier: 1.0, constant: -64.0)
        let bottomConstraint = NSLayoutConstraint(item: alertController.view!, attribute: .bottom, relatedBy: .equal, toItem: textView, attribute: .bottom, multiplier: 1.0, constant: 64.0)
        alertController.view.addConstraint(leadConstraint)
        alertController.view.addConstraint(trailConstraint)
        alertController.view.addConstraint(topConstraint)
        alertController.view.addConstraint(bottomConstraint)

        self.present(alertController, animated: true, completion: nil)
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let alertTextOfNote = String(notes?[indexPath.row].text ?? "")
            let alert = UIAlertController(title: "", message: "Delete \(alertTextOfNote) ?" , preferredStyle: .alert)
            let no = UIAlertAction(title: "No", style: .cancel)
            let yes = UIAlertAction(title: "Yes", style: .destructive) { [self] action in
                let note = self.notes?[indexPath.row]
                self.context.delete(note!)
                notes?.remove(at: indexPath.row)
                if soundOn { playSound(sound: "Recycle") }
                saveNotes()
            }
            alert.addAction(yes)
            alert.addAction(no)
            present(alert, animated: true)
        }
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
