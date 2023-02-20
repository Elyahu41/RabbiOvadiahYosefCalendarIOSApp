//
//  ViewController.swift
//  Rabbi Ovadiah Yosef Calendar
//
//  Created by Elyahu on 2/10/23.
//

import UIKit
import KosherCocoa
import CoreLocation

class ViewController: UIViewController {
    
    var locationName: String = ""
    var lat: Double = 0
    var long: Double = 0
    var elevation: Double = 0.0
    var timezone: TimeZone = TimeZone.current
    var userChosenDate: Date = Date()
    var zmanimCalendar: ComplexZmanimCalendar = ComplexZmanimCalendar()
    var jewishCalendar: JewishCalendar = JewishCalendar()
    let defaults = UserDefaults.standard
    
    @IBAction func enterZipcode(_ sender: Any) {
        showZipcodeAlert()
    }
    @IBAction func setupElevetion(_ sender: Any) {
        self.performSegue(withIdentifier: "elevationSegue", sender: self)
    }
    
    override func viewDidLoad() {//first this happens
        super.viewDidLoad()
        GlobalStruct.useElevation = defaults.bool(forKey: "useElevation")
        GlobalStruct.roundUp = defaults.bool(forKey: "roundUp")
        //if #available(iOS 14.0, *) {
                //datePicker.preferredDatePickerStyle = .inline
        //}
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: NSNotification.Name("text"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {//then this method happens
        if !defaults.bool(forKey: "hasRunBefore") {
            showZipcodeAlert()
        } else {//not first run
            if defaults.bool(forKey: "useZipcode") {
                locationName = defaults.string(forKey: "locationName") ?? ""
                lat = defaults.double(forKey: "lat")
                long = defaults.double(forKey: "long")
                SharedData.shared.lat = lat
                SharedData.shared.long = long
                elevation = defaults.double(forKey: "elevation" + locationName)
                timezone = TimeZone.init(identifier: defaults.string(forKey: "timezone")!)!
                recreateZmanimCalendar()
            } else {
                getUserLocation()
            }
        }
    }
    
    func getUserLocation() {
        LocationManager.shared.getUserLocation {
            location in DispatchQueue.main.async { [self] in
                self.lat = location.coordinate.latitude
                self.long = location.coordinate.longitude
                SharedData.shared.lat = lat
                SharedData.shared.long = long
                self.timezone = TimeZone.current
                self.recreateZmanimCalendar()
                self.defaults.set(true, forKey: "hasRunBefore")
                self.defaults.set(false, forKey: "useZipcode")
                self.defaults.set(timezone.identifier, forKey: "timezone")
                //let yesterday: Date = calendar.internalCalendar().date(byAdding: .day, value: -1, to: calendar.workingDate)!
                //calendar.workingDate = yesterday

                //let formatter = DateFormatter()
                //formatter.dateFormat = "HH:mm:ss E, d MMM y"
                LocationManager.shared.resolveLocationName(with: location) { [self] locationName in
                    self.locationName = locationName!
                    if self.defaults.object(forKey: "elevation" + self.locationName) != nil {//if we have been here before, use the elevation saved for this location
                        self.elevation = self.defaults.double(forKey: "elevation" + self.locationName)
                    } else {//we have never been here before, remove elevation settings
                        self.elevation = 0
                    }
                    self.recreateZmanimCalendar()
                    print(self.locationName)
                    jewishCalendar = JewishCalendar(location: zmanimCalendar.geoLocation)
                    var date = String(Date().description)
                    date += "   ▼   " + String(jewishCalendar.currentHebrewDayOfMonth()) + " " + self.getHebrewMonth(month:jewishCalendar.currentHebrewMonth()) + " " + String(jewishCalendar.currentHebrewYear())
                    print(date)
                    //forward jewish calendar to saturday
                    while jewishCalendar.currentDayOfTheWeek() != 7 {
                        jewishCalendar.workingDate = jewishCalendar.workingDate.advanced(by: 86400)
                    }
                    print(ParashatHashavuaCalculator().parashaInDiaspora(for: zmanimCalendar.workingDate).name() + " / " + getSpecialParasha())//TODO fix in israel
                    syncCalendarDates()//reset
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "EEEE"
                    print(dateFormatter.string(from: zmanimCalendar.workingDate) + " / " + getHebrewDay(day: jewishCalendar.currentDayOfTheWeek()))
                    jewishCalendar.returnsModernHolidays = true
                    jewishCalendar.inIsrael = false
                    let index = jewishCalendar.yomTovIndex()
                    if index != -1 {
                        print(JewishHoliday(index: index).nameTransliterated())
                    }
                    //zmanim
                    dateFormatter.dateFormat = "h:mm:ss aa"
                    print("Alot Hashachar: " + dateFormatter.string(from: zmanimCalendar.alos72Zmanis()!))
                    print("Talit: " + dateFormatter.string(from: zmanimCalendar.talitTefilin()!))
                    print("Sunrise (Mishor): " + dateFormatter.string(from: zmanimCalendar.sunrise()!))
                    print("Latest Shma MGA: " + dateFormatter.string(from: zmanimCalendar.sofZmanShmaMGA72MinutesZmanis()!))
                    print("Latest Shma GRA: " + dateFormatter.string(from: zmanimCalendar.sofZmanShmaGra()!))
                    print("Latest Berachot Shma: " + dateFormatter.string(from: zmanimCalendar.sofZmanTfilaGra()!))
                    print("Mid-day: " + dateFormatter.string(from: zmanimCalendar.chatzos()!))
                    print("Mincha Gedolah: " + dateFormatter.string(from: zmanimCalendar.minchaGedolaGreaterThan30()!))
                    print("Mincha Ketana: " + dateFormatter.string(from: zmanimCalendar.minchaKetana()!))
                    print("Plag: " + dateFormatter.string(from: zmanimCalendar.plagHamincha()!))
                    print("Sunset: " + dateFormatter.string(from: zmanimCalendar.sunset()!))
                    print("Tzeit: " + dateFormatter.string(from: zmanimCalendar.tzeit()!))
                    print("RT: " + dateFormatter.string(from: zmanimCalendar.tzais72Zmanis()!))
                    print("Midnight: " + dateFormatter.string(from: zmanimCalendar.solarMidnight()!))
                    print("Daf Yomi: " + ((jewishCalendar.dafYomiBavli().name())) + " " + String(jewishCalendar.dafYomiBavli().pageNumber))
                    print("Daf Yomi Yerushalmi: " + YerushalmiYomiCalculator().dafYomiYerushalmi(userChosenDate, calendar: jewishCalendar).nameYerushalmi() + " " + String(YerushalmiYomiCalculator().dafYomiYerushalmi(userChosenDate, calendar: jewishCalendar).pageNumber))
                    //mashiv haruach and barech aleinu
                    print("GRA: " + DateComponentsFormatter().string(from: TimeInterval(zmanimCalendar.shaahZmanisGra()))! + " / " + "MGA: " + DateComponentsFormatter().string(from: TimeInterval(zmanimCalendar.shaahZmanis72MinutesZmanis()))!)
                    
                }
            }
        }
    }
    
    func showZipcodeAlert() {
        let alert = UIAlertController(title: "Location or Search a place?",
                                      message: "You can choose to use your device's location, or you can search for a place below. It is recommended to use your devices location as this provides more accurate results.", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Zipcode/Address"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            //if text is empty, display a message notifying the user:
            if textField?.text == "" {
                let alert = UIAlertController(title: "Error", message: "Please enter a valid zipcode or address.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in
                    self.showZipcodeAlert()
                }))
                self.present(alert, animated: true)
                return
            }
            let geoCoder = CLGeocoder()
            geoCoder.geocodeAddressString((textField?.text)!, completionHandler: { i, j in
                var name = ""
                if let locality = i?.first?.locality {
                    name += locality
                }
                if let adminRegion = i?.first?.administrativeArea {
                    name += ", \(adminRegion)"
                }
                if name.isEmpty {
                    name = "No location name info"
                }
                self.locationName = name
                let coordinates = i?.first?.location?.coordinate
                self.lat = coordinates?.latitude ?? 0
                self.long = coordinates?.longitude ?? 0
                SharedData.shared.lat = self.lat
                SharedData.shared.long = self.long
                self.elevation = self.defaults.double(forKey: "elevation" + name)//if ran before, get elevation save for this location
                self.timezone = (i?.first?.timeZone)!
                self.recreateZmanimCalendar()
                self.defaults.set(name, forKey: "locationName")
                self.defaults.set(self.lat, forKey: "lat")
                self.defaults.set(self.long, forKey: "long")
                self.defaults.set(true, forKey: "hasRunBefore")
                self.defaults.set(true, forKey: "useZipcode")
                self.defaults.set(self.timezone.identifier, forKey: "timezone")
            })
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { UIAlertAction in
            alert.dismiss(animated: true) {}
        }))
        alert.addAction(UIAlertAction(title: "Use Location", style: .default, handler: { UIAlertAction in
            self.getUserLocation()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func didGetNotification(_ notification: Notification) {
        let amount = notification.object as! String
        elevation = NumberFormatter().number(from: amount)!.doubleValue
        defaults.set(elevation, forKey: "elevation" + locationName)
        recreateZmanimCalendar()
    }
    
    public func recreateZmanimCalendar() {
        let geoLocation = KosherCocoa.GeoLocation.init(latitude: self.lat, andLongitude: self.long, elevation: self.elevation, andTimeZone: timezone)
        zmanimCalendar = ComplexZmanimCalendar(location: geoLocation)
    }
    
    public func getSpecialParasha() -> String {
        if jewishCalendar.currentDayOfTheWeek() == 7 {
            if (jewishCalendar.currentHebrewMonth() == kHebrewMonth.shevat.rawValue && !jewishCalendar.isCurrentlyHebrewLeapYear()) || (jewishCalendar.currentHebrewMonth() == kHebrewMonth.adar.rawValue && jewishCalendar.isCurrentlyHebrewLeapYear()) {
                if [25, 27, 29].contains(jewishCalendar.currentHebrewDayOfMonth()) {
        return "שקלים"
        }
        }
            if (jewishCalendar.currentHebrewMonth() == kHebrewMonth.adar.rawValue && !jewishCalendar.isCurrentlyHebrewLeapYear()) || jewishCalendar.currentHebrewMonth() == kHebrewMonth.adar_II.rawValue {
        if jewishCalendar.currentHebrewDayOfMonth() == 1 {
        return "שקלים"
        }
        if [8, 9, 11, 13].contains(jewishCalendar.currentHebrewDayOfMonth()) {
        return "זכור"
        }
        if [18, 20, 22, 23].contains(jewishCalendar.currentHebrewDayOfMonth()) {
        return "פרה"
        }
        if [25, 27, 29].contains(jewishCalendar.currentHebrewDayOfMonth()) {
        return "החדש"
        }
        }
        if jewishCalendar.currentHebrewMonth() == kHebrewMonth.nissan.rawValue && jewishCalendar.currentHebrewDayOfMonth() == 1 {
        return "החדש"
        }
        }
        return ""
    }
    
    public func getHebrewDay(day:Int) -> String {
        var dayHebrew = "יום "
        if day == 1 {
            dayHebrew += "ראשון"
        }
        if day == 2 {
            dayHebrew += "שני"
        }
        if day == 3 {
            dayHebrew += "שלישי"
        }
        if day == 4 {
            dayHebrew += "רביעי"
        }
        if day == 5 {
            dayHebrew += "חמישי"
        }
        if day == 6 {
            dayHebrew += "ששי"
        }
        if day == 7 {
            dayHebrew += "שבת"
        }
        return dayHebrew
    }

    
    public func getHebrewMonth(month:Int) -> String {
        if kHebrewMonth.tishrei.rawValue == month {
                return "Tishrei"
        }
        if kHebrewMonth.cheshvan.rawValue == month {
                return "Cheshvan"
        }
        if kHebrewMonth.kislev.rawValue == month {
                return "Kislev"
        }
        if kHebrewMonth.teves.rawValue == month {
                return "Tevet"
        }
        if kHebrewMonth.shevat.rawValue == month {
                return "Shevat"
        }
        if kHebrewMonth.adar.rawValue == month {
                return "Adar"
        }
        if kHebrewMonth.adar_II.rawValue == month {
                return "Adar II"
        }
        if kHebrewMonth.nissan.rawValue == month {
                return "Nissan"
        }
        if kHebrewMonth.iyar.rawValue == month {
                return "Iyar"
        }
        if kHebrewMonth.sivan.rawValue == month {
                return "Sivan"
        }
        if kHebrewMonth.tammuz.rawValue == month {
                return "Tamuz"
        }
        if kHebrewMonth.av.rawValue == month {
                return "Av"
        }
        if kHebrewMonth.elul.rawValue == month {
                return "Elul"
        }
        return "???"
    }
    
    public func syncCalendarDates() {
        zmanimCalendar.workingDate = userChosenDate
        jewishCalendar.workingDate = userChosenDate
    }
}

struct GlobalStruct {
    static var useElevation = false
    static var roundUp = false
}

public extension ComplexZmanimCalendar {
    
    func tzait72Zmanit() -> Date? {
        let shaahZmanit = shaahZmanisGra()
        
        if (shaahZmanit == .leastNormalMagnitude) {
            return nil;
        }
        
        if GlobalStruct.useElevation {
            return sunset()?.addingTimeInterval(shaahZmanit*1.2);
        }
        return seaLevelSunset()?.addingTimeInterval(shaahZmanit*1.2);
    }
    
    func tzeitTaanitLChumra() -> Date? {
        return sunset()?.addingTimeInterval(20 * 60);
    }
    
    func tzeitTaanit() -> Date? {
        return sunset()?.addingTimeInterval(30 * 60);
    }
    
    func tzeit() -> Date? {
        let shaahZmanit = shaahZmanisGra()
        
        if (shaahZmanit == .leastNormalMagnitude) {
            return nil;
        }
        
        let dakahZmanit = shaahZmanit / 60
        
        return sunset()?.addingTimeInterval(13 * dakahZmanit + (dakahZmanit / 2));
    }
    
    override func sunset() -> Date? {
        if GlobalStruct.useElevation {
            return super.sunset()
        }
        return seaLevelSunset()
    }
    
    override func plagHamincha() -> Date? {
        let shaahZmanit = shaahZmanisGra()
        
        if (shaahZmanit == .leastNormalMagnitude) {
            return nil;
        }
        
        let dakahZmanit = shaahZmanit / 60
        
        return tzeit()?.addingTimeInterval(-(shaahZmanit + (15 * dakahZmanit)));
    }
    
    override func sunrise() -> Date? {
        if GlobalStruct.useElevation {
            return super.sunrise()
        }
        return seaLevelSunrise()
    }
    
    func talitTefilin() -> Date? {
        let shaahZmanit = shaahZmanisGra()
        
        if (shaahZmanit == .leastNormalMagnitude) {
            return nil;
        }
        
        let dakahZmanit = shaahZmanit / 60
        
        return alos72Zmanis()?.addingTimeInterval(6 * dakahZmanit);
    }
    
    override func shaahZmanisGra() -> Double {
        if GlobalStruct.useElevation {
            return temporalHour(fromSunrise: sunrise()!, toSunset: sunset()!)
        }
        return temporalHour(fromSunrise: seaLevelSunrise()!, toSunset: seaLevelSunset()!)
    }
}

class SharedData {
    static let shared = SharedData()
    var lat: Double = 0.0
    var long: Double = 0.0
    private init() {}
}



