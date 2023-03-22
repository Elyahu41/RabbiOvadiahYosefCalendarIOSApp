//
//  ViewController.swift
//  Rabbi Ovadiah Yosef Calendar
//
//  Created by Elyahu on 2/10/23.
//

import UIKit
import KosherCocoa
import CoreLocation

class ZmanListViewController: UITableViewController {
    
    var locationName: String = ""
    var lat: Double = 0
    var long: Double = 0
    var elevation: Double = 0.0
    var timezone: TimeZone = TimeZone.current
    var userChosenDate: Date = Date()
    var zmanimCalendar: ComplexZmanimCalendar = ComplexZmanimCalendar()
    var jewishCalendar: JewishCalendar = JewishCalendar()
    let defaults = UserDefaults.standard
    var zmanimList = Array<ZmanListEntry>()
    
    @IBAction func prevDayButton(_ sender: Any) {
        userChosenDate = userChosenDate.advanced(by: -86400)
        syncCalendarDates()
        updateZmanimList()
    }
    @IBOutlet weak var calendarButton: UIButton!
    @IBAction func calendarButton(_ sender: Any) {
        showDatePicker()
    }
    @IBAction func nextDayButton(_ sender: Any) {
        userChosenDate = userChosenDate.advanced(by: 86400)
        syncCalendarDates()
        updateZmanimList()
    }
    @IBAction func enterZipcode(_ sender: Any) {
        showZipcodeAlert()
    }
    @IBAction func setupElevetion(_ sender: Any) {
        self.performSegue(withIdentifier: "elevationSegue", sender: self)
    }
    @IBOutlet weak var zmanimTableView: UITableView!
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return zmanimList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ZmanEntry", for: indexPath)
        cell.textLabel?.text = zmanimList[indexPath.row].title
        return cell
    }
    
    @objc func refreshTable() {
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
        userChosenDate = Date()
        syncCalendarDates()
        updateZmanimList()
        tableView.refreshControl?.endRefreshing()
    }
    
    @objc func showDatePicker() {
        let alertController = UIAlertController(title: "Select a date", message: nil, preferredStyle: .actionSheet)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.date = userChosenDate
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        } else {
            // Fallback on earlier versions
        }
        datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        alertController.view.addSubview(datePicker)

        // Add constraints to the date picker that pin it to the edges of the alert controller's view
        datePicker.leadingAnchor.constraint(equalTo: alertController.view.leadingAnchor, constant: 32).isActive = true
        datePicker.trailingAnchor.constraint(equalTo: alertController.view.trailingAnchor, constant: -32).isActive = true
        datePicker.topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: 64).isActive = true
        datePicker.bottomAnchor.constraint(equalTo: alertController.view.bottomAnchor, constant: -96).isActive = true
        
        let changeCalendarAction = UIAlertAction(title: "Switch Calendar", style: .default) { (_) in
            self.dismiss(animated: true)
            self.showHebrewDatePicker()
        }

        alertController.addAction(changeCalendarAction)

        let doneAction = UIAlertAction(title: "Done", style: .default) { (_) in
            self.syncCalendarDates()
            self.updateZmanimList()
        }

        alertController.addAction(doneAction)

        present(alertController, animated: true, completion: nil)
    }
    
    @objc func showHebrewDatePicker() {
        let alertController = UIAlertController(title: "Select a date", message: nil, preferredStyle: .actionSheet)

        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        } else {
            // Fallback on earlier versions
        }
        datePicker.calendar = Calendar(identifier: .hebrew)
        datePicker.locale = Locale(identifier: "he")
        datePicker.date = userChosenDate
        datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        alertController.view.addSubview(datePicker)

        // Add constraints to the date picker that pin it to the edges of the alert controller's view
        datePicker.leadingAnchor.constraint(equalTo: alertController.view.leadingAnchor, constant: 32).isActive = true
        datePicker.trailingAnchor.constraint(equalTo: alertController.view.trailingAnchor, constant: -32).isActive = true
        datePicker.topAnchor.constraint(equalTo: alertController.view.topAnchor, constant: 64).isActive = true
        datePicker.bottomAnchor.constraint(equalTo: alertController.view.bottomAnchor, constant: -96).isActive = true
        
        let changeCalendarAction = UIAlertAction(title: "Switch Calendar", style: .default) { (_) in
            self.dismiss(animated: true)
            self.showDatePicker()
        }

        alertController.addAction(changeCalendarAction)

        let doneAction = UIAlertAction(title: "Done", style: .default) { (_) in
            self.syncCalendarDates()
            self.updateZmanimList()
        }

        alertController.addAction(doneAction)

        present(alertController, animated: true, completion: nil)
    }


    // Function to handle changes to the date picker value
    @objc func datePickerValueChanged(sender: UIDatePicker) {
        userChosenDate = sender.date
    }
    
    override func viewDidLoad() {//first this happens
        super.viewDidLoad()
        zmanimTableView.dataSource = self
        zmanimTableView.delegate = self
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshTable), for: .valueChanged)
        tableView.refreshControl = refreshControl
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
                jewishCalendar = JewishCalendar(location: zmanimCalendar.geoLocation)
                jewishCalendar.inIsrael = false
                jewishCalendar.returnsModernHolidays = true
                updateZmanimList()
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
                    jewishCalendar = JewishCalendar(location: zmanimCalendar.geoLocation)
                    jewishCalendar.inIsrael = false
                    jewishCalendar.returnsModernHolidays = true
                    updateZmanimList()
                }
            }
        }
    }
    
    func updateZmanimList() {
        zmanimList = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM, yyyy"
        dateFormatter.timeZone = timezone
        zmanimList.append(ZmanListEntry(title: locationName))
        var date = dateFormatter.string(from: userChosenDate)
                
        let hebrewDateFormatter = DateFormatter()
        hebrewDateFormatter.calendar = Calendar(identifier: .hebrew)
        hebrewDateFormatter.dateFormat = "d MMMM, yyyy"
        let hebrewDate = hebrewDateFormatter.string(from: userChosenDate)
        
        if Calendar.current.isDateInToday(userChosenDate) {
            date += "   ▼   " + hebrewDate
        } else {
            date += "       " + hebrewDate
        }
        zmanimList.append(ZmanListEntry(title:date))
        //forward jewish calendar to saturday
        while jewishCalendar.currentDayOfTheWeek() != 7 {
            jewishCalendar.workingDate = jewishCalendar.workingDate.advanced(by: 86400)
        }
        //now that we are on saturday, check the parasha
        let specialParasha = jewishCalendar.getSpecialParasha()
        var parasha = ""
        
        if defaults.bool(forKey: "inIsrael") {
            parasha = ParashatHashavuaCalculator().parashaInIsrael(for: jewishCalendar.workingDate).name()
        } else {
            parasha = ParashatHashavuaCalculator().parashaInDiaspora(for: jewishCalendar.workingDate).name()
        }
        if !specialParasha.isEmpty {
            parasha += " / " + specialParasha
        }
        zmanimList.append(ZmanListEntry(title:parasha))
        syncCalendarDates()//reset
        dateFormatter.dateFormat = "EEEE"
        zmanimList.append(ZmanListEntry(title:dateFormatter.string(from: zmanimCalendar.workingDate) + " / " + getHebrewDay(day: jewishCalendar.currentDayOfTheWeek())))
        let specialDay = jewishCalendar.getSpecialDay()
        if !specialDay.isEmpty {
            zmanimList.append(ZmanListEntry(title:specialDay))
        }
        let music = jewishCalendar.isOKToListenToMusic()
        if !music.isEmpty {
            zmanimList.append(ZmanListEntry(title: music))
        }
        let ulChaparatPesha = jewishCalendar.getIsUlChaparatPeshaSaid()
        if !ulChaparatPesha.isEmpty {
            zmanimList.append(ZmanListEntry(title: ulChaparatPesha))
        }
        let hallel = jewishCalendar.getHallelOrChatziHallel()
        if !hallel.isEmpty {
            zmanimList.append(ZmanListEntry(title: hallel))
        }
        let bircatHelevana = jewishCalendar.getIsTonightStartOrEndBircatLevana()
        if !bircatHelevana.isEmpty {
            zmanimList.append(ZmanListEntry(title: bircatHelevana))
        }
        if jewishCalendar.isBirkasHachamah() {
            zmanimList.append(ZmanListEntry(title: "Birchat HaChamah is said today"))
        }
        zmanimList.append(ZmanListEntry(title:jewishCalendar.getTachanun()))
        //zmanim
        if defaults.bool(forKey: "showSeconds") {
            dateFormatter.dateFormat = "h:mm:ss aa"
        } else {
            dateFormatter.dateFormat = "h:mm aa"
        }
        zmanimList.append(ZmanListEntry(title:"Dawn: " + dateFormatter.string(from: zmanimCalendar.alos72Zmanis()!)))
        zmanimList.append(ZmanListEntry(title:"Earliest Talit and Tefilin: " + dateFormatter.string(from: zmanimCalendar.talitTefilin()!)))
        zmanimList.append(ZmanListEntry(title:"Sunrise (Sea Level): " + dateFormatter.string(from: zmanimCalendar.sunrise()!)))
        zmanimList.append(ZmanListEntry(title:"Latest Shma MG'A: " + dateFormatter.string(from: zmanimCalendar.sofZmanShmaMGA72MinutesZmanis()!)))
        zmanimList.append(ZmanListEntry(title:"Latest Shma GR'A: " + dateFormatter.string(from: zmanimCalendar.sofZmanShmaGra()!)))
        zmanimList.append(ZmanListEntry(title:"Latest Berachot Shma: " + dateFormatter.string(from: zmanimCalendar.sofZmanTfilaGra()!)))
        zmanimList.append(ZmanListEntry(title:"Mid-day: " + dateFormatter.string(from: zmanimCalendar.chatzos()!)))
        zmanimList.append(ZmanListEntry(title:"Earliest Mincha: " + dateFormatter.string(from: zmanimCalendar.minchaGedolaGreaterThan30()!)))
        zmanimList.append(ZmanListEntry(title:"Mincha Ketana: " + dateFormatter.string(from: zmanimCalendar.minchaKetana()!)))
        zmanimList.append(ZmanListEntry(title:"Plag HaMincha: " + dateFormatter.string(from: zmanimCalendar.plagHamincha()!)))
        if jewishCalendar.isErevYomTov() || jewishCalendar.currentDayOfTheWeek() == 6 {
            zmanimCalendar.candleLightingOffset = 20
            zmanimList.append(ZmanListEntry(title:"Candle Lighting: " + dateFormatter.string(from:zmanimCalendar.candleLighting()!)))
        }
        zmanimList.append(ZmanListEntry(title:"Sunset: " + dateFormatter.string(from: zmanimCalendar.sunset()!)))
        zmanimList.append(ZmanListEntry(title:"NightFall: " + dateFormatter.string(from: zmanimCalendar.tzeit()!)))
        zmanimList.append(ZmanListEntry(title:"Rabbeinu Tam: " + dateFormatter.string(from: zmanimCalendar.tzais72Zmanis()!)))
        zmanimList.append(ZmanListEntry(title:"Midnight: " + dateFormatter.string(from: zmanimCalendar.solarMidnight()!)))
        let dafYomi = jewishCalendar.dafYomiBavli()
        if dafYomi != nil {
            zmanimList.append(ZmanListEntry(title:"Daf Yomi: " + ((dafYomi!.name())) + " " + dafYomi!.pageNumber.formatHebrew()))
        }
        let dateString = "1980-02-02"//Yerushalmi start date
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let yerushalmiYomi = DafYomiCalculator(date: userChosenDate).dafYomiYerushalmi(calendar: jewishCalendar)
        if let targetDate = dateFormatter.date(from: dateString) {
            let comparisonResult = targetDate.compare(userChosenDate)
            if comparisonResult == .orderedDescending {
                print("The target date is before Feb 2, 1980.")
            } else if comparisonResult == .orderedAscending {
                if yerushalmiYomi != nil {
                    zmanimList.append(ZmanListEntry(title:"Daf Yomi Yerushalmi: " +  yerushalmiYomi!.nameYerushalmi() + " " + yerushalmiYomi!.pageNumber.formatHebrew()))
                } else {
                    zmanimList.append(ZmanListEntry(title:"No Daf Yomi Yerushalmi"))
                }
            }
        }
        zmanimList.append(ZmanListEntry(title:jewishCalendar.getIsMashivHaruchOrMoridHatalSaid() + " / " + jewishCalendar.getIsBarcheinuOrBarechAleinuSaid()))
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        zmanimList.append(ZmanListEntry(title:"GRA: " + (formatter.string(from: TimeInterval(zmanimCalendar.shaahZmanisGra())) ?? "N/A") + " / " + "MGA: " + (formatter.string(from: TimeInterval(zmanimCalendar.shaahZmanis72MinutesZmanis())) ?? "N/A")))
        for zman in zmanimList {
            print(zman.title, "\n")
        }
        tableView.reloadData()
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
    
    public func syncCalendarDates() {//with userChosenDate
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

public extension JewishCalendar {
    
    func getSpecialDay() -> String {
        var result = Array<String>()
        
        let index = yomTovIndex()
        let indexNextDay = getYomTovIndexForNextDay()
        
        let yomTovOfToday = yomTovAsString(index:index)
        let yomTovOfNextDay = yomTovAsString(index:indexNextDay)
        
        if yomTovOfToday.isEmpty && yomTovOfNextDay.isEmpty {
            //Do nothing
        } else if yomTovOfToday.isEmpty && !yomTovOfNextDay.hasPrefix("Erev") {
            result.append("Erev " + yomTovOfNextDay)
        } else if !(yomTovOfNextDay.isEmpty) && !yomTovOfNextDay.hasPrefix("Erev") && !yomTovOfToday.hasSuffix(yomTovOfNextDay) {
            result.append(yomTovOfToday + " / Erev " + yomTovOfNextDay)
        } else {
            result.append(yomTovOfToday)
        }
        
        result = addTaanitBechorot(result: result)
        result = addRoshChodesh(result: result)
        result = addDayOfOmer(result: result)
        result = replaceChanukahWithDayOfChanukah(result: result)

        return result.joined(separator: " / ")
    }
    
    func addTaanitBechorot(result:Array<String>) -> Array<String> {
        var arr = result
        if tomorrowIsTaanitBechorot() {
            arr.append("Erev Taanit Bechorot")
        }
        if isTaanisBechoros() {
            arr.append("Taanit Bechorot")
        }
        return arr
    }
    
    func tomorrowIsTaanitBechorot() -> Bool {
        let backup = workingDate
        workingDate = workingDate.advanced(by: 86400)
        let result = isTaanisBechoros()
        workingDate = backup
        return result
    }
    
    func addRoshChodesh(result:Array<String>) -> Array<String> {
        var arr = result
        let roshChodeshOrErevRoshChodesh = getRoshChodeshOrErevRoshChodesh()
        if !roshChodeshOrErevRoshChodesh.isEmpty {
            arr.append(roshChodeshOrErevRoshChodesh)
        }
        return arr
    }
    
    func getRoshChodeshOrErevRoshChodesh() -> String {
        var result = ""
        let hebrewDateFormatter = DateFormatter()
        hebrewDateFormatter.calendar = Calendar(identifier: .hebrew)
        hebrewDateFormatter.dateFormat = "MMMM"

        let hebrewMonth = hebrewDateFormatter.string(from: workingDate)
        
        if isRoshChodesh() {
            result = "Rosh Chodesh " + hebrewMonth
        } else if isErevRoshChodesh() {
            result = "Erev Rosh Chodesh " + hebrewDateFormatter.string(from: workingDate.advanced(by: 86400))
        }
        
        return result
    }
    
    func replaceChanukahWithDayOfChanukah(result:Array<String>) -> Array<String> {
        var arr = result
        let dayOfChanukah = dayOfChanukah()
        if dayOfChanukah != -1 {
            if let index = arr.firstIndex(of: "Chanukah") {
                arr.remove(at: index)
            }
            let formatter = NumberFormatter()
            formatter.numberStyle = .ordinal
            arr.append(formatter.string(from: dayOfChanukah as NSNumber)! + " day of Chanukah")
        }
        return arr
    }
    
    func dayOfChanukah() -> Int {
        let day = currentHebrewDayOfMonth()
        if isChanukah() {
            if currentHebrewMonth() == HebrewMonth.kislev.rawValue {
                return day - 24
            } else {
                return isKislevShort() ? day + 5 : day + 6
            }
        } else {
            return -1
        }
    }
    
    func addDayOfOmer(result:Array<String>) -> Array<String> {
        var arr = result
        let dayOfOmer = getDayOfOmer()
        if dayOfOmer != -1 {
            let formatter = NumberFormatter()
            formatter.numberStyle = .ordinal
            arr.append(formatter.string(from: dayOfOmer as NSNumber)! + " day of Omer")
        }
        return arr
    }
    
    func getDayOfOmer() -> Int {
        var omer = -1
        let month = currentHebrewMonth()
        let day = currentHebrewDayOfMonth()
        
        if month == HebrewMonth.nissan.rawValue && day >= 16 {
            omer = day - 15
        } else if month == HebrewMonth.iyar.rawValue {
            omer = day + 15
        } else if month == HebrewMonth.sivan.rawValue && day < 6 {
            omer = day + 44
        }
        return omer
    }
    
    func yomTovAsString(index:Int) -> String {
        if index == 33 {
            return "Lag Ba'Omer"
        } else if index == 34 {
            return "Shushan Purim Katan"
        } else if index != -1 {
            let yomtov = JewishHoliday(index: index).nameTransliterated()
            if yomtov.contains("Shemini Atzeret") {
                if inIsrael {
                    return "Shemini Atzeret & Simchat Torah"
                }
            }
            if yomtov.contains("Simchat Torah") {
                if !inIsrael {
                    return "Shemini Atzeret & Simchat Torah"
                }
            }
            return yomtov
        }
        return ""
    }

    func getSpecialParasha() -> String {
        if currentDayOfTheWeek() == 7 {
            if (currentHebrewMonth() == kHebrewMonth.shevat.rawValue && !isCurrentlyHebrewLeapYear()) || (currentHebrewMonth() == kHebrewMonth.adar.rawValue && isCurrentlyHebrewLeapYear()) {
                if [25, 27, 29].contains(currentHebrewDayOfMonth()) {
        return "שקלים"
        }
        }
            if (currentHebrewMonth() == kHebrewMonth.adar.rawValue && !isCurrentlyHebrewLeapYear()) || currentHebrewMonth() == kHebrewMonth.adar_II.rawValue {
        if currentHebrewDayOfMonth() == 1 {
        return "שקלים"
        }
        if [8, 9, 11, 13].contains(currentHebrewDayOfMonth()) {
        return "זכור"
        }
        if [18, 20, 22, 23].contains(currentHebrewDayOfMonth()) {
        return "פרה"
        }
        if [25, 27, 29].contains(currentHebrewDayOfMonth()) {
        return "החדש"
        }
        }
        if currentHebrewMonth() == kHebrewMonth.nissan.rawValue && currentHebrewDayOfMonth() == 1 {
        return "החדש"
        }
        }
        return ""
    }
                
    func isTaanisBechoros() -> Bool {
        let day = currentHebrewDayOfMonth()
        let dayOfWeek = currentDayOfTheWeek()
        //the fast is on the 14th of Nisan unless that is a Shabbos where the fast is moved to Thursday
        return currentHebrewMonth() == HebrewMonth.nissan.rawValue && ((day == 14 && dayOfWeek != 7) || (day == 12 && dayOfWeek == 5))
    }
    
    func getTachanun() -> String {
        let yomTovIndex = yomTovIndex()
        if isRoshChodesh()
            || yomTovIndex == kPesachSheni.rawValue
            || (currentHebrewMonth() == HebrewMonth.iyar.rawValue && currentHebrewDayOfMonth() == 18)//lag baomer
            || yomTovIndex == kTishaBeav.rawValue
            || yomTovIndex == kTuBeav.rawValue
            || yomTovIndex == kErevRoshHashana.rawValue
            || yomTovIndex == kRoshHashana.rawValue
            || yomTovIndex == kErevYomKippur.rawValue
            || yomTovIndex == kYomKippur.rawValue
            || yomTovIndex == kTuBeshvat.rawValue
            || yomTovIndex == kPurimKatan.rawValue
            || (isHebrewLeapYear(currentHebrewYear()) && currentHebrewMonth() == HebrewMonth.adar.rawValue && currentHebrewDayOfMonth() == 15)//shushan purim katan
            || yomTovIndex == kShushanPurim.rawValue
            || yomTovIndex == kPurim.rawValue
            || yomTovIndex == kYomYerushalayim.rawValue
            || isChanukah()
            || currentHebrewMonth() == HebrewMonth.nissan.rawValue
            || (currentHebrewMonth() == HebrewMonth.sivan.rawValue && currentHebrewDayOfMonth() <= 12)
            || (currentHebrewMonth() == HebrewMonth.tishrei.rawValue && currentHebrewDayOfMonth() >= 11) {
            return "There is no Tachanun today"
        }
        let yomTovIndexForNextDay = getYomTovIndexForNextDay()
        if currentDayOfTheWeek() == 6 //Friday
            || yomTovIndex == kFastOfEsther.rawValue
            || yomTovIndexForNextDay == kTishaBeav.rawValue
            || yomTovIndexForNextDay == kTuBeav.rawValue
            || yomTovIndexForNextDay == kTuBeshvat.rawValue
            || (currentHebrewMonth() == HebrewMonth.iyar.rawValue && currentHebrewDayOfMonth() == 17)// day before lag baomer
            || yomTovIndexForNextDay == kPesachSheni.rawValue
            || yomTovIndexForNextDay == kPurimKatan.rawValue
            || isErevRoshChodesh() {
            if currentDayOfTheWeek() == 7 {
                return "There is no Tachanun today"
            }
            return "There is only Tachanun in the morning"
        }
        return "There is Tachanun today"
    }
    
    func getYomTovIndexForNextDay() -> Int {
        //set workingDate to next day
        let temp = workingDate
        workingDate.addTimeInterval(60*60*24)
        let yomTovIndexForTomorrow = yomTovIndex()
        workingDate = temp //reset
        return yomTovIndexForTomorrow
    }
    
    func getHallelOrChatziHallel() -> String {
        let yomTovIndex = yomTovIndex()
        let jewishMonth = currentHebrewMonth()
        let jewishDay = currentHebrewDayOfMonth()
        if (jewishMonth == HebrewMonth.nissan.rawValue && jewishDay == 15) || (!inIsrael && jewishMonth == HebrewMonth.nissan.rawValue && jewishDay == 16) || yomTovIndex == kShavuos.rawValue || yomTovIndex == kSuccos.rawValue || yomTovIndex == kSheminiAtzeres.rawValue || isCholHamoedSuccos() || isChanukah() {
            return "הלל שלם";
        } else if isRoshChodesh() || isCholHamoedPesach() || (jewishMonth == HebrewMonth.nissan.rawValue && jewishDay == 21) || (!inIsrael && jewishMonth == HebrewMonth.nissan.rawValue && jewishDay == 22) {
            return "חצי הלל";
        } else {
            return ""
        }
    }
    
    func getIsUlChaparatPeshaSaid() -> String {
        if isRoshChodesh() {
            if isHebrewLeapYear(currentHebrewYear()) {
                let month = currentHebrewMonth()
                if month == HebrewMonth.cheshvan.rawValue || month == HebrewMonth.kislev.rawValue || month == HebrewMonth.teves.rawValue || month == HebrewMonth.shevat.rawValue || month == HebrewMonth.adar.rawValue || month == HebrewMonth.adar_II.rawValue {
                    return "Say וּלְכַפָּרַת פֶּשַׁע";
                } else {
                    return "Do not say וּלְכַפָּרַת פֶּשַׁע";
                }
            } else {
                return "Do not say וּלְכַפָּרַת פֶּשַׁע";
            }
        }
        return ""
    }
    
    func isOKToListenToMusic() -> String {
        if getDayOfOmer() >= 8 && getDayOfOmer() <= 33 {
            return "No Music"
        } else if currentHebrewMonth() == HebrewMonth.tammuz.rawValue {
            if currentHebrewDayOfMonth() >= 17 {
                return "No Music"
            }
        } else if currentHebrewMonth() == HebrewMonth.av.rawValue {
            if currentHebrewDayOfMonth() <= 9 {
                return "No Music"
            }
        }
        return "";
    }
    
    func isBirkasHachamah() -> Bool {
        var elapsedDays = getJewishCalendarElapsedDays(jewishYear: currentHebrewYear())
        elapsedDays = elapsedDays + getDaysSinceStartOfJewishYear()
        if elapsedDays % Int((28 * 365.25)) == 172 {
            return true
        }
        return false
    }
    
    func getIsTonightStartOrEndBircatLevana() -> String {
        let sevenDays = tchilasZmanKidushLevana7Days(for: workingDate)!
        let fifteenDays = sofZmanKidushLevana15Days(for: workingDate)!
        
        //
        //
        //FIXME
        //
        //
        if Calendar.current.isDate(workingDate, inSameDayAs: sevenDays) {
            return "Birchat HaLevana starts tonight";
        }
        
        if Calendar.current.isDate(workingDate, inSameDayAs: fifteenDays) {
            return "Last night for Birchat HaLevana";
        }
        return ""
    }
    
    func getIsMashivHaruchOrMoridHatalSaid() -> String {
        if isMashivHaruachRecited() {
            return "משיב הרוח"
        }
        if isMoridHatalRecited() {
            return "מוריד הטל"
        }
        return ""
    }
    
    func getIsBarcheinuOrBarechAleinuSaid() -> String {
        if (isVeseinBerachaRecited()) {
            return "ברכנו";
        } else {
            return "ברך עלינו";
        }
    }

    func isMashivHaruachRecited() -> Bool {
        let calendar = Calendar(identifier: .hebrew)
        let startDateComponents = DateComponents(calendar: calendar, year: currentHebrewYear(), month: 1, day: 22)
        let startDate = calendar.date(from: startDateComponents)!
        let endDateComponents = DateComponents(calendar: calendar, year: currentHebrewYear(), month: 8, day: 15)
        let endDate = calendar.date(from: endDateComponents)!
        return workingDate > startDate && workingDate < endDate
    }
    
    func isMoridHatalRecited() -> Bool {
        return !isMashivHaruachRecited() || isMashivHaruachStartDate() || isMashivHaruachEndDate()
    }
    
    func isMashivHaruachStartDate() -> Bool {
        return currentHebrewMonth() == HebrewMonth.tishrei.rawValue && currentHebrewDayOfMonth() == 22
    }
    
    func isMashivHaruachEndDate() -> Bool {
        return currentHebrewMonth() == HebrewMonth.nissan.rawValue && currentHebrewDayOfMonth() == 15
    }
    
    func isVeseinBerachaRecited() -> Bool {
        return !isVeseinTalUmatarRecited()
    }
    
    func isVeseinTalUmatarRecited() -> Bool {
        if currentHebrewMonth() == HebrewMonth.nissan.rawValue && currentHebrewDayOfMonth() < 15 {
            return true
        }
        if currentHebrewMonth() == HebrewMonth.nissan.rawValue || currentHebrewMonth() == HebrewMonth.iyar.rawValue || currentHebrewMonth() == HebrewMonth.sivan.rawValue || currentHebrewMonth() == HebrewMonth.tammuz.rawValue || currentHebrewMonth() == HebrewMonth.av.rawValue || currentHebrewMonth() == HebrewMonth.elul.rawValue || currentHebrewMonth() == HebrewMonth.tishrei.rawValue {
            return false
        }
        if inIsrael {
            return currentHebrewMonth() != HebrewMonth.cheshvan.rawValue || currentHebrewDayOfMonth() >= 7
        } else {
            let t = getTekufasTishreiElapsedDays()
            return t >= 47;
        }
    }
    
    func getTekufa() -> Double? {
        let INITIAL_TEKUFA_OFFSET = 12.625 // the number of days Tekufas Tishrei occurs before JEWISH_EPOCH

        let days = Double(getJewishCalendarElapsedDays(jewishYear: currentHebrewYear()) + getDaysSinceStartOfJewishYear()) + INITIAL_TEKUFA_OFFSET - 1 // total days since first Tekufas Tishrei event

        let solarDaysElapsed = days.truncatingRemainder(dividingBy: 365.25) // total days elapsed since start of solar year
        let tekufaDaysElapsed = solarDaysElapsed.truncatingRemainder(dividingBy: 91.3125) // the number of days that have passed since a tekufa event

        if (tekufaDaysElapsed > 0 && tekufaDaysElapsed <= 1) { // if the tekufa happens in the upcoming 24 hours
            return ((1.0 - tekufaDaysElapsed) * 24.0).truncatingRemainder(dividingBy: 24) // rationalize the tekufa event to number of hours since start of jewish day
        } else {
            return nil
        }
    }
    
    func getTekufaName() -> String {
        let tekufaNames = ["Tishri", "Tevet", "Nissan", "Tammuz"]
        let INITIAL_TEKUFA_OFFSET = 12.625 // the number of days Tekufas Tishrei occurs before JEWISH_EPOCH

        let days = Double(getJewishCalendarElapsedDays(jewishYear: currentHebrewYear()) + getDaysSinceStartOfJewishYear()) + INITIAL_TEKUFA_OFFSET - 1 // total days since first Tekufas Tishrei event

        let solarDaysElapsed = days.truncatingRemainder(dividingBy: 365.25) // total days elapsed since start of solar year
        let currentTekufaNumber = Int(solarDaysElapsed / 91.3125)
        let tekufaDaysElapsed = solarDaysElapsed.truncatingRemainder(dividingBy: 91.3125) // the number of days that have passed since a tekufa event
        
        if (tekufaDaysElapsed > 0 && tekufaDaysElapsed <= 1) {//if the tekufa happens in the upcoming 24 hours
            return tekufaNames[currentTekufaNumber]
        } else {
            return ""
        }
    }
    
    func getTekufaAsDate() -> Date? {
        let yerushalayimStandardTZ = TimeZone(identifier: "GMT+2")!
        let cal = Calendar(identifier: .gregorian)
        let workingDateComponents = cal.dateComponents([.year, .month, .day], from: workingDate)
        guard let tekufa = getTekufa() else {
            return nil
        }
        let hours = tekufa - 6
        let minutes = Int((hours - Double(Int(hours))) * 60)
        return cal.date(from: DateComponents(calendar: cal, timeZone: yerushalayimStandardTZ, year: workingDateComponents.year, month: workingDateComponents.month, day: workingDateComponents.day, hour: Int(hours), minute: minutes, second: 0, nanosecond: 0))
    }

    
    func getTekufasTishreiElapsedDays() -> Int {
        // Days since Rosh Hashana year 1. Add 1/2 day as the first tekufas tishrei was 9 hours into the day. This allows all
        // 4 years of the secular leap year cycle to share 47 days. Truncate 47D and 9H to 47D for simplicity.
        let days = Double(getJewishCalendarElapsedDays(jewishYear: currentHebrewYear())) + Double(getDaysSinceStartOfJewishYear() - 1) + 0.5
        // days of completed solar years
        let solar = Double(currentHebrewYear() - 1) * 365.25
        return Int(floor(days - solar))
    }
    
    func getDaysSinceStartOfJewishYear() -> Int {
        var elapsedDays = currentHebrewDayOfMonth()
        
        var hebrewMonth = currentHebrewMonth()
        
        if !isHebrewLeapYear(currentHebrewYear()) && hebrewMonth >= 7 {
            hebrewMonth = hebrewMonth - 1//special case for adar 2 because swift is weird
        }
        
        for month in 1..<hebrewMonth {
            elapsedDays += daysInJewishMonth(month: month, year: currentHebrewYear())
        }
        
        return elapsedDays
    }
    
    func daysInJewishMonth(month: Int, year: Int) -> Int {
        if ((month == HebrewMonth.iyar.rawValue) || (month == HebrewMonth.tammuz.rawValue) || (month == HebrewMonth.elul.rawValue) || ((month == HebrewMonth.cheshvan.rawValue) && !(isCheshvanLong()))
                || ((month == HebrewMonth.kislev.rawValue) && isKislevShort()) || (month == HebrewMonth.teves.rawValue)
                || ((month == HebrewMonth.adar.rawValue) && !(isHebrewLeapYear(year))) || (month == HebrewMonth.adar_II.rawValue)) {
            return 29;
        } else {
            return 30;
        }
    }
    
    func isCheshvanLong() -> Bool {
        return length(ofHebrewYear: currentHebrewYear()) == HebrewYearType.shalaim.rawValue
    }

    func getJewishCalendarElapsedDays(jewishYear: Int) -> Int {
        // The number of chalakim (25,920) in a 24 hour day.
        let CHALAKIM_PER_DAY: Int = 25920 // 24 * 1080
        let chalakimSince = getChalakimSinceMoladTohu(year: jewishYear, month: Int(HebrewMonth.tishrei.rawValue))
        let moladDay = Int(chalakimSince / CHALAKIM_PER_DAY)
        let moladParts = Int(chalakimSince - chalakimSince / CHALAKIM_PER_DAY * CHALAKIM_PER_DAY)
        // delay Rosh Hashana for the 4 dechiyos
        return addDechiyos(year: jewishYear, moladDay: moladDay, moladParts: moladParts)
    }
    
    func getChalakimSinceMoladTohu(year: Int, month: Int) -> Int {
        // The number  of chalakim in an average Jewish month. A month has 29 days, 12 hours and 793 chalakim (44 minutes and 3.3 seconds) for a total of 765,433 chalakim
        let CHALAKIM_PER_MONTH: Int = 765433 // (29 * 24 + 12) * 1080 + 793

        // Days from the beginning of Sunday till molad BaHaRaD. Calculated as 1 day, 5 hours and 204 chalakim = (24 + 5) * 1080 + 204 = 31524
        let CHALAKIM_MOLAD_TOHU: Int = 31524
        // Jewish lunar month = 29 days, 12 hours and 793 chalakim
        // chalakim since Molad Tohu BeHaRaD - 1 day, 5 hours and 204 chalakim
        let monthOfYear = month
        var monthsElapsed = (235 * ((year - 1) / 19))
        monthsElapsed = monthsElapsed + (12 * ((year - 1) % 19))
        monthsElapsed = monthsElapsed + ((7 * ((year - 1) % 19) + 1) / 19)
        monthsElapsed = monthsElapsed + (monthOfYear - 1)
        // return chalakim prior to BeHaRaD + number of chalakim since
        return Int(CHALAKIM_MOLAD_TOHU + (CHALAKIM_PER_MONTH * Int(monthsElapsed)))
    }
    
    func addDechiyos(year: Int, moladDay: Int, moladParts: Int) -> Int {
        var roshHashanaDay = moladDay // if no dechiyos
        // delay Rosh Hashana for the dechiyos of the Molad - new moon 1 - Molad Zaken, 2- GaTRaD 3- BeTuTaKFoT
        if (moladParts >= 19440) || // Dechiya of Molad Zaken - molad is >= midday (18 hours * 1080 chalakim)
            ((moladDay % 7) == 2 && // start Dechiya of GaTRaD - Ga = is a Tuesday
             moladParts >= 9924 && // TRaD = 9 hours, 204 parts or later (9 * 1080 + 204)
             !isHebrewLeapYear(year)) || // of a non-leap year - end Dechiya of GaTRaD
            ((moladDay % 7) == 1 && // start Dechiya of BeTuTaKFoT - Be = is on a Monday
             moladParts >= 16789 && // TRaD = 15 hours, 589 parts or later (15 * 1080 + 589)
             isHebrewLeapYear(year - 1)) { // in a year following a leap year - end Dechiya of BeTuTaKFoT
            roshHashanaDay += 1 // Then postpone Rosh HaShanah one day
        }
        // start 4th Dechiya - Lo ADU Rosh - Rosh Hashana can't occur on A- sunday, D- Wednesday, U - Friday
        if (roshHashanaDay % 7 == 0) || // If Rosh HaShanah would occur on Sunday,
            (roshHashanaDay % 7 == 3) || // or Wednesday,
            (roshHashanaDay % 7 == 5) { // or Friday - end 4th Dechiya - Lo ADU Rosh
            roshHashanaDay += 1 // Then postpone it one (more) day
        }
        return roshHashanaDay
    }
}


public extension DafYomiCalculator {
    
    func dafYomiYerushalmi(calendar: JewishCalendar) -> Daf? {
        let dafYomiStartDay = gregorianDate(forYear: 1980, month: 2, andDay: 2)
        let WHOLE_SHAS_DAFS = 1554
        let BLATT_PER_MASSECTA = [
            68, 37, 34, 44, 31, 59, 26, 33, 28, 20, 13, 92, 65, 71, 22, 22, 42, 26, 26, 33, 34, 22,
            19, 85, 72, 47, 40, 47, 54, 48, 44, 37, 34, 44, 9, 57, 37, 19, 13
        ]
        
        let dateCreator = Calendar(identifier: .gregorian)
        var nextCycle = DateComponents()
        var prevCycle = DateComponents()
        var masechta = 0
        var dafYomi: Daf?
        
        // There isn't Daf Yomi on Yom Kippur or Tisha B'Av.
        if calendar.yomTovIndex() == kYomKippur.rawValue || calendar.yomTovIndex() == kTishaBeav.rawValue {
            return nil
        }
        
        if calendar.workingDate.compare(dafYomiStartDay!) == .orderedAscending {
            return nil
        }
        
        nextCycle.year = 1980
        nextCycle.month = 2
        nextCycle.day = 2
        
//        let n = dateCreator.date(from: nextCycle)
//        let p = dateCreator.date(from: prevCycle)

        // Go cycle by cycle, until we get the next cycle
        while calendar.workingDate.compare(dateCreator.date(from: nextCycle)!) == .orderedDescending {
            prevCycle = nextCycle
            
            nextCycle.day! += WHOLE_SHAS_DAFS
            nextCycle.day! += getNumOfSpecialDays(startDate: dateCreator.date(from: prevCycle)!, endDate: dateCreator.date(from: nextCycle)!)
        }
        
        // Get the number of days from cycle start until request.
        let dafNo = getDiffBetweenDays(start: dateCreator.date(from: prevCycle)!, end: calendar.workingDate)
        
        // Get the number of special day to subtract
        let specialDays = getNumOfSpecialDays(startDate: dateCreator.date(from: prevCycle)!, endDate: calendar.workingDate)
        var total = dafNo - specialDays
        
        // Finally find the daf.
        for j in 0..<BLATT_PER_MASSECTA.count {
            if total <= BLATT_PER_MASSECTA[j] {
                dafYomi = Daf(tractateIndex: masechta, andPageNumber: total + 1)
                break
            }
            masechta += 1
            total -= BLATT_PER_MASSECTA[j]
        }
        
        return dafYomi
    }

    private func gregorianDate(forYear year: Int, month: Int, andDay day: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.calendar = Calendar(identifier: .gregorian)
        return components.date
    }
    
    func getNumOfSpecialDays(startDate: Date, endDate: Date) -> Int {
        let startCalendar = JewishCalendar()
        startCalendar.workingDate = startDate
        let endCalendar = JewishCalendar()
        endCalendar.workingDate = endDate
        
        var startYear = startCalendar.currentHebrewYear()
        let endYear = endCalendar.currentHebrewYear()
        
        var specialDays = 0
        
        let dateCreator = Calendar(identifier: .hebrew)

        //create a hebrew calendar set to the date 7/10/5770
        var yomKippurComponents = DateComponents()
        yomKippurComponents.year = 5770
        yomKippurComponents.month = 1
        yomKippurComponents.day = 10
        
        var tishaBeavComponents = DateComponents()
        tishaBeavComponents.year = 5770
        tishaBeavComponents.month = 5
        tishaBeavComponents.day = 9
        
        while startYear <= endYear {
            yomKippurComponents.year = startYear
            tishaBeavComponents.year = startYear
            
            if isBetween(start: startDate, date: dateCreator.date(from: yomKippurComponents)!, end: endDate) {
                specialDays += 1
            }
            
            if isBetween(start: startDate, date: dateCreator.date(from: tishaBeavComponents)!, end: endDate) {
                specialDays += 1
            }
            
            startYear += 1
        }

        return specialDays
    }

    func isBetween(start: Date, date: Date, end: Date) -> Bool {
        return (start.compare(date) == .orderedAscending) && (end.compare(date) == .orderedDescending)
    }

    func getDiffBetweenDays(start: Date, end: Date) -> Int {
        let DAY_MILIS: Double = 24 * 60 * 60
        let s = Int(end.timeIntervalSince1970 - start.timeIntervalSince1970)
        return s / Int(DAY_MILIS)
    }
}

public extension Daf {
    
    func nameYerushalmi() -> String {
        let names = ["ברכות"
                     , "פיאה"
                     , "דמאי"
                     , "כלאיים"
                     , "שביעית"
                     , "תרומות"
                     , "מעשרות"
                     , "מעשר שני"
                     , "חלה"
                     , "עורלה"
                     , "ביכורים"
                     , "שבת"
                     , "עירובין"
                     , "פסחים"
                     , "ביצה"
                     , "ראש השנה"
                     , "יומא"
                     , "סוכה"
                     , "תענית"
                     , "שקלים"
                     , "מגילה"
                     , "חגיגה"
                     , "מועד קטן"
                     , "יבמות"
                     , "כתובות"
                     , "סוטה"
                     , "נדרים"
                     , "נזיר"
                     , "גיטין"
                     , "קידושין"
                     , "בבא קמא"
                     , "בבא מציעא"
                     , "בבא בתרא"
                     , "שבועות"
                     , "מכות"
                     , "סנהדרין"
                     , "עבודה זרה"
                     , "הוריות"
                     , "נידה"
                     , "אין דף היום"]

        return names[tractateIndex]
    }
}


class SharedData {
    static let shared = SharedData()
    var lat: Double = 0.0
    var long: Double = 0.0
    private init() {}
}

extension Int {
    func formatHebrew() -> String {
        if self <= 0 {
            fatalError("Input must be a positive integer")
        }
        var ret = String(repeating: "ת", count: self / 400)
        var num = self % 400
        if num >= 100 {
            ret.append("קרש"[String.Index(utf16Offset: num / 100 - 1, in: "קרש")])
            num %= 100
        }
        switch num {
        // Avoid letter combinations from the Tetragrammaton
        case 16:
            ret.append("טז")
        case 15:
            ret.append("טו")
        default:
            if num >= 10 {
                ret.append("יכלמנסעפצ"[String.Index(utf16Offset: num / 10 - 1, in: "יכלמנסעפצ")])
                num %= 10
            }
            if num > 0 {
                ret.append("אבגדהוזחט"[String.Index(utf16Offset: num - 1, in: "אבגדהוזחט")])
            }
        }
        return ret
    }
}


