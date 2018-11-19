//
//  ViewController.swift
//  Sunsrise sunset
//
//  Created by Stas Shetko on 4/11/18.
//  Copyright © 2018 Stas Shetko. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
    
    @IBOutlet weak var cityName: UILabel!
    @IBOutlet weak var changeCityTextField: UITextField!
    @IBOutlet weak var getDataButton: UIButton!
    @IBOutlet weak var sunriseTimeLabel: UILabel!
    @IBOutlet weak var sunsetTimeLabel: UILabel!
    
    let locationManager = CLLocationManager()
    
    @IBAction func getSunriseSunsetButtonPressed(_ sender: Any) {
        if let city = changeCityTextField.text {
            sunriseSunsetTimeFor(city, url: GOOGLE_PLACE_API)
        }
        changeCityTextField.resignFirstResponder()
    }
    
    let SUNRISE_SUNSET_API = "https://api.sunrise-sunset.org/json?&formatted=1"
    let GOOGLE_PLACE_API = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?&fields=geometry&inputtype=textquery"
    let API_KEY = "AIzaSyCh0i0c8waABy7zmhDVLkGgZwKWDh72Qq4"
    let GOOGLE_MAP_API = "https://maps.googleapis.com/maps/api/geocode/json?"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        self.hideKeyboardWhenTappedAround()
        
    }
    
    func sunriseSunsetTime(url: String, parameters: [String: String]) {
        
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                
                let sunJSON : JSON = JSON(response.result.value!)
                if sunJSON["status"].stringValue == "OK" {
                    let sunrise = sunJSON["results"]["sunrise"].stringValue
                    let sunset = sunJSON["results"]["sunset"].stringValue
                    self.updateUIWith(sunrise, sunsetTime: sunset)
                } else {
                    self.cityName.text = "Enter Another City"
                    self.sunriseTimeLabel.text = "No data"
                    self.sunsetTimeLabel.text = "No data"
                }
                
            } else {
                self.sunsetTimeLabel.text = "Connection Issues"
            }
        }
    }
    
    
    func updateUIWith(_ sunriseTime: String, sunsetTime: String ) {
        if !(changeCityTextField.text?.isEmpty)! {
            self.cityName.text = changeCityTextField.text?.capitalized
        }
        sunriseTimeLabel.text = sunriseTime
        sunsetTimeLabel.text = sunsetTime
    }
    
    func sunriseSunsetTimeFor(_ city: String, url: String) {
        
        let parameters = ["input": city, "key": API_KEY]
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                
                let cityJSON : JSON = JSON(response.result.value!)
                
                if cityJSON["status"].stringValue == "OK" {
                    
                    let lat = String(cityJSON["candidates"][0]["geometry"]["location"]["lat"].doubleValue)
                    let lng = String(cityJSON["candidates"][0]["geometry"]["location"]["lng"].doubleValue)
                    let params = ["lat": lat, "lng": lng]
                    self.sunriseSunsetTime(url: self.SUNRISE_SUNSET_API, parameters: params)
                } else {
                    self.cityName.text = "Enter Another City"
                    self.sunriseTimeLabel.text = "No data"
                    self.sunsetTimeLabel.text = "No data"
                }
                
                
            } else {
                self.sunsetTimeLabel.text = "Connection Issues"
            }
        }
        
    }
    
    func reverseGeocoding(_ url: String, parameters: [String: String]) {
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                
                let cityJSON : JSON = JSON(response.result.value!)
                let components = cityJSON["results"][0]["address_components"].arrayValue
                for item in components {
                    let arr = item["types"].arrayObject as! [String]
                    if arr.contains("locality") {
                        self.cityName.text = item["long_name"].stringValue
                    }
                }
                
            } else {
                self.sunsetTimeLabel.text = "Connection Issues"
            }
        }
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]
        if location.horizontalAccuracy > 0 {
            
            self.locationManager.stopUpdatingLocation()
            let latitude = String(location.coordinate.latitude)
            let longitude = String(location.coordinate.longitude)
            
            let params : [String : String] = ["lat" : latitude, "lng" : longitude]
            let geoCodingParam = ["latlng" : "\(latitude),\(longitude)", "key": API_KEY]
            reverseGeocoding(GOOGLE_MAP_API, parameters: geoCodingParam)
            sunriseSunsetTime(url: SUNRISE_SUNSET_API, parameters: params)
        }
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
