//
//  ContentView.swift
//  CupcakeCorner
//
//  Created by Tahminur Rahman on 1/20/20.
//  Copyright © 2020 Tahminur Rahman. All rights reserved.
//
import Combine
import SwiftUI

class Order: ObservableObject, Codable {
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decode(Int.self, forKey: .type)
        quantity = try container.decode(Int.self, forKey: .quantity)

        extraFrosting = try container.decode(Bool.self, forKey: .extraFrosting)
        addSprinkles = try container.decode(Bool.self, forKey: .addSprinkles)

        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        city = try container.decode(String.self, forKey: .city)
        zipcode = try container.decode(String.self, forKey: .zipcode)
    }
    //below is the default init since we start off with no orders.
    init() {}
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(type, forKey: .type)
        try container.encode(quantity, forKey: .quantity)

        try container.encode(extraFrosting, forKey: .extraFrosting)
        try container.encode(addSprinkles, forKey: .addSprinkles)

        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        try container.encode(city, forKey: .city)
        try container.encode(zipcode, forKey: .zipcode)
    }
    
    
    enum CodingKeys:String, CodingKey{
        //case name
        case type, quantity, extraFrosting, addSprinkles, name, address, city, zipcode
    }
    
    //variable below is a passthrough subject that sends no data and never throws a value
    var didChange = PassthroughSubject<Void, Never>()
    
    //flavors
    static let types = ["vanilla", "chocolate", "strawberry", "rainbow"]
    
    //didset is used to run a set of code once a property has been set
    @Published var type = 0 {didSet {update()}}
    
    @Published var quantity = 3 {didSet {update()}}
    
    @Published var SpecialRequests = false {
        didSet {
            if SpecialRequests == false {
                extraFrosting = false
                addSprinkles = false
            }
        }
    }
    @Published var extraFrosting = false {didSet {update()}}
    @Published var addSprinkles = false {didSet {update()}}
    
    @Published var name = "" {didSet {update()}}
    @Published var address = ""{didSet {update()}}
    @Published var city = ""{didSet {update()}}
    @Published var zipcode = ""{didSet {update()}}
    
    //determines whether the button for placing an order should be active or not.
    var isValid: Bool {
        if name.isEmpty || address.isEmpty || city.isEmpty || zipcode.isEmpty{
            return false
        }
        return true
    }
    
    func update(){
        //Can add any other logging, etc. here
        
        //to reload any view we call didchange.set
        didChange.send(())
    }
    //similar to what is being done with the types variable
    
    
}


struct ContentView: View {
    @ObservedObject var order = Order()
    @State var confirmationMessage = ""
    @State var confirmation = false
    @State var sprinklesmsg = "Add Sprinkles"
    
    
    //function returns if stuff fails
    func placeOrder(){
        //print("I placed the order for \($order.name)")
        guard let encoded = try? JSONEncoder().encode(order) else {
            print("Failed to encode order")
            return
        }
        //some API that just returns the json being sent
        let url = URL(string: "https://reqres.in/api/cupcakes")!
        var request = URLRequest(url:url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encoded
        
        
        URLSession.shared.dataTask(with: request){
            guard let data = $0 else{
                print("No data in response:\($2?.localizedDescription ?? "Unknown error").")
                return
            }
            
            if let decodedOrder = try? JSONDecoder().decode(Order.self, from: data) {
                self.confirmationMessage = "Your order for \(decodedOrder.quantity)x \(Order.types[decodedOrder.type].lowercased()) cupcakes is on it's way!"
                self.confirmation = true
            } else {
                let dataString = String(decoding: data, as: UTF8.self)
                print("Invalid response: \(dataString)")
            }
        }.resume()
    }
    
    
    var body: some View {
        NavigationView{
            Form{
                Section{
                    //this is the picker that is made using the types variable of the Order class can make it have a wheel style by changing the pickerStyle or by putting it into a VStack
                    Picker(selection: $order.type, label: Text("Select your cake flavor")){
                        ForEach( 0 ..< Order.types.count){
                            Text(Order.types[$0]).tag($0)
                        }
                    }
                    //for some reason the order.quantity value is not changing
                    Stepper(value: $order.quantity, in: 3 ... 20){
                        Text("Number of Cakes: \(order.quantity)")
                    }
                }
                //made seperate sections to group special requests in one area and the vital information in the other
                Section{
                    Toggle(isOn: $order.SpecialRequests){
                        Text("Any Special Requests?")
                    }
                    //only enabled when special requests value becomes true
                    if order.SpecialRequests {
                        Toggle(isOn: $order.addSprinkles) {
                            Text("Add Sprinkles")
                        }
                        Toggle(isOn: $order.extraFrosting){
                            Text("Extra Frosting")
                        }
                    }
                }
                //section for contact information
                Section{
                    TextField("Enter your name", text: $order.name)
                    TextField("Enter your address", text: $order.address)
                    TextField("Enter your city", text: $order.city)
                    TextField("Enter your zipcode", text: $order.zipcode)
                    
                }
                //secdtion to place the order
                Section{
                    Button(action: {
                        self.placeOrder()
                    }) {
                        Text("Place Order")
                    }
                }.disabled(!order.isValid)
                
            }
                .navigationBarTitle(Text("Cupcake Corner"))
                //.presentation was giving issues so changed to .alert instead makes mroe sense as well
                .alert(isPresented: $confirmation){
                    Alert(title: Text("Thank you!"), message: Text(confirmationMessage), dismissButton: .default(Text("OK")))
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
