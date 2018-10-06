//
//  DocumentsViewController.swift
//  DocumentsSearch
//
//  Created by Anand Kulkarni on 10/5/18.
//  Copyright © 2018 Anand Kulkarni. All rights reserved.
//

import UIKit
import CoreData

class DocumentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var documentsTableView: UITableView!
    let dateFormatter = DateFormatter()
    var documents = [Document]()
    var filterDocuments = [Document]()
    let searchController = UISearchController(searchResultsController: nil)
    var selectedSearch = search.all
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Documents"
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        searchController.searchResultsUpdater = self as? UISearchResultsUpdating
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Documents"
        
        navigationItem.searchController = searchController
        
        searchController.searchBar.scopeButtonTitles = ["All", "Name", "Content", "Date"]
        searchController.searchBar.delegate = self as? UISearchBarDelegate
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchDocuments(searchString: "")
        documentsTableView.reloadData()
    }
    func searchBarIsEmpty() -> Bool{
        return searchController.searchBar.text?.isEmpty ?? true
    }
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filterDocuments = documents.filter({( document: Document) -> Bool in
            let match = (scope == "All") || (document.name == scope)
            if searchBarIsEmpty(){
                return match
            } else {
                return match && (document.name?.contains(searchText))!
            }
        })
        documentsTableView.reloadData()
    }
    func isfiltering() -> Bool {
        let searchBarScopeISFiltering = searchController.searchBar.selectedScopeButtonIndex != 0
        if let searchString = searchController.searchBar.text{
            fetchDocuments(searchString: searchString)
        }
        return searchController.isActive && (!searchBarIsEmpty() || searchBarScopeISFiltering)
    }
    func alertNotifyUser(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel) {
            (alertAction) -> Void in
            print("OK selected")
        })
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func fetchDocuments(searchString: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Document> = Document.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            if (searchString != ""){
                switch(selectedSearch){
                case .all:
                        fetchRequest.predicate = NSPredicate(format: searchString, searchString)
                case .name:
                        fetchRequest.predicate = NSPredicate(format: searchString)
                case .cotent:
                        fetchRequest.predicate = NSPredicate(format: searchString)
                }
            }
            documents = try managedContext.fetch(fetchRequest)
            documentsTableView.reloadData()
        } catch {
            alertNotifyUser(message: "Fetch for documents could not be performed.")
            return
        }
    }
    func updateSearchResults(for searchController: UISearchController){
        let searchBar = searchController.searchBar
        let scope = searchBar.scopeButtonTitles![searchBar.selectedScopeButtonIndex]
        filterContentForSearchText(searchController.searchBar.text!, scope: scope)
        if let searchString = searchController.searchBar.text{
            fetchDocuments(searchString: searchString)
        }
    }
    func deleteDocument(at indexPath: IndexPath) {
        let document = documents[indexPath.row]
        
        if let managedObjectContext = document.managedObjectContext {
            managedObjectContext.delete(document)
            
            do {
                try managedObjectContext.save()
                self.documents.remove(at: indexPath.row)
                documentsTableView.deleteRows(at: [indexPath], with: .automatic)
            } catch {
                alertNotifyUser(message: "Delete failed.")
                documentsTableView.reloadData()
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return documents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "documentCell", for: indexPath)
        
        if let cell = cell as? DocumentTableViewCell {
            let document = documents[indexPath.row]
            cell.nameLabel.text = document.name
            cell.sizeLabel.text = String(document.size) + " bytes"
            
            if let modifiedDate = document.modifiedDate {
                cell.modifiedLabel.text = dateFormatter.string(from: modifiedDate)
            } else {
                cell.modifiedLabel.text = "unknown"
            }
        }
        
        return cell
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? DocumentViewController,
            let segueIdentifier = segue.identifier, segueIdentifier == "existingDocument",
            let row = documentsTableView.indexPathForSelectedRow?.row {
            destination.document = documents[row]
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteDocument(at: indexPath)
        }
    }
}
