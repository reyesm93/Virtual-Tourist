//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Arturo Reyes on 9/27/17.
//  Copyright © 2017 Arturo Reyes. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapVC: UIViewController, UIGestureRecognizerDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLabel: UILabel!
    
    let stack = CoreDataStack.sharedInstance
    var isDeletingAlbums = false
    var mapRegion : MapViewPersistence!
    var album: Collection!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setConstrains()
        
        if !(fetchAlbums().isEmpty) {
            mapView.addAnnotations(fetchAlbums())
        }
        
        navigationItem.title = "Virtual Tourist"
        
        mapRegion = MapViewPersistence(mapView)
        
        if let storedRegion = mapRegion.getLastRegion() {
            self.mapView.region = storedRegion
        }

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.addAlbum(_:)))
        longPress.minimumPressDuration = 0.5
        longPress.delegate = self
        mapView.addGestureRecognizer(longPress)
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: true)
        showDeleteLabel(isDeletingAlbums)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "albumSegue" {
            let album = sender as! Collection
            let destination = segue.destination as! AlbumVC
            destination.album = album
        }
    }

    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        isDeletingAlbums = !isDeletingAlbums
        if isDeletingAlbums {
            sender.title = "Done"
        } else {
            sender.title = "Edit"
        }
        showDeleteLabel(isDeletingAlbums)
    }
    
    
    @objc func addAlbum(_ recognizer: UIGestureRecognizer) {
        
        let pressedAt = recognizer.location(in: self.mapView)
        let pressedAtCoordinate: CLLocationCoordinate2D = mapView.convert(pressedAt, toCoordinateFrom: mapView)
        let lat = pressedAtCoordinate.latitude
        let lon = pressedAtCoordinate.longitude
        
        if album != nil  {
            album.latitude = lat
            album.longitude = lon
        }

        if recognizer.state == UIGestureRecognizerState.began {
            self.stack.context.performAndWait {
                album = Collection(latitude: lat, longitude: lon, context: self.stack.context)
            }
        } else if recognizer.state == UIGestureRecognizerState.changed {
            album.latitude = pressedAtCoordinate.latitude
            album.longitude = pressedAtCoordinate.longitude
        } else if recognizer.state == UIGestureRecognizerState.ended {
            self.stack.context.performAndWait {
                stack.save()
            }
            mapView.addAnnotation(album)
            print("album: \(album) added")
        }
    }
    
    private func setConstrains() {
        let safeArea = view.safeAreaLayoutGuide
        mapView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0).isActive = true
        mapView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 0).isActive = true
        mapView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 0).isActive = true
        mapView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: 0).isActive = true
        
        deleteLabel.isEnabled = false
        deleteLabel.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: 0).isActive = true
        deleteLabel.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 0).isActive = true
        deleteLabel.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: 0).isActive = true
        deleteLabel.topAnchor.constraint(equalTo: mapView.bottomAnchor, constant: 0).isActive = true
    }
    
    func fetchAlbums() -> [Collection] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Collection")
        var albums = [Collection]()
        
        do {
            let fetchedObjects = try stack.context.fetch(fetchRequest)
            albums = fetchedObjects as! [Collection]
        } catch let e as NSError {
            print("Error while trying to perform fetch: \n\(e)\n Albums")
        }
        
        return albums
    }

    func showDeleteLabel(_ isDeleting: Bool) {
        let safeArea = view.safeAreaLayoutGuide
        let safeBottom = safeArea.bottomAnchor
        let viewHeight = view.frame.height
        let viewWidth = view.frame.width
        let topLabelAnchor = deleteLabel.topAnchor
        let labelHeight = (view.frame.size.height)*(0.1)
        if isDeleting {
            UIView.animate(withDuration: 0.25, animations: {
                self.mapView.frame = CGRect(x: 0, y: (labelHeight*(-1)), width: viewWidth, height: viewHeight)
                self.deleteLabel.frame = CGRect(x: 0, y: 0, width: viewWidth, height: labelHeight)
                self.mapView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 0).isActive = false
                self.mapView.bottomAnchor.constraint(equalTo: topLabelAnchor, constant: 0).isActive = true
                self.mapView.bottomAnchor.constraint(equalTo: safeBottom, constant: 0).isActive = false
                self.mapView.setNeedsUpdateConstraints()
                self.deleteLabel.backgroundColor = .red
                self.deleteLabel.text = "Tap Pins to Delete"
                self.deleteLabel.textColor = .white
                self.deleteLabel.font = UIFont(name: "Arial", size: 18)
                self.deleteLabel.textAlignment = NSTextAlignment.center
                self.deleteLabel.isEnabled = isDeleting
                self.deleteLabel.alpha = 1.0
            })
        } else {
            UIView.animate(withDuration: 0.25, animations: {
                self.mapView.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
                self.mapView.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 0).isActive = true
                self.deleteLabel.heightAnchor.constraint(equalToConstant: labelHeight).isActive = false
                self.mapView.bottomAnchor.constraint(equalTo: topLabelAnchor, constant: 0).isActive = false
                self.mapView.bottomAnchor.constraint(equalTo: safeBottom, constant: 0).isActive = true
                self.mapView.setNeedsUpdateConstraints()
                self.deleteLabel.text = ""
                self.deleteLabel.alpha = 0.0
                self.deleteLabel.isEnabled = !isDeleting
            })
        }
    }
}
    
extension MapVC: MKMapViewDelegate {
        
     func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.isDraggable = true
        }
        else {
            pinView!.annotation = annotation
            pinView!.animatesDrop = true
            pinView!.isDraggable = true
        }
        
        return pinView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        print("pin pressed")
        
        let album = view.annotation as! Collection
        if isDeletingAlbums {
            mapView.removeAnnotation(album)
            stack.context.delete(album)
            stack.save()
        } else {
            mapView.deselectAnnotation(album, animated: false)
            performSegue(withIdentifier: "albumSegue", sender: album)
        }
    }
    
    // Soruce: https://stackoverflow.com/questions/29776853/ios-swift-mapkit-making-an-annotation-draggable-by-the-user
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, didChange newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        switch newState {
        case .starting:
            view.dragState = .dragging
            view.setDragState(newState, animated: true)
        case .ending, .canceling:
            view.dragState = .none
            view.setDragState(newState, animated: true)
        default: break
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        mapRegion.storeRegion()
    }
    
}

