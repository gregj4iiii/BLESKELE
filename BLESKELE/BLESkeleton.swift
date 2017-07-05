//
//  File.swift
//  BLESKELE
//
//  Created by Gregory Joseph on 2017-07-04.
//  Copyright © 2017 4iiii. All rights reserved.
//

import Foundation

import CoreBluetooth

class BLESkeleton: NSObject, CBCentralManagerDelegate{
    
    var manager:CBCentralManager? = nil
    var listOfDevicesDiscovered: deviceModelList = deviceModelList()
    var deviceModelDelegate: deviceModelListUpdateDelegate?
    var discoveredPeripherals: [CBPeripheral] = [CBPeripheral]()
    var connectedPeripherals: [CBPeripheral] = [CBPeripheral]()
    var connectedToDevice: Bool = false
    //var peripheral:CBPeripheral
    
    let BLE_NAME = "PRECISION"
    //let BLE_UUID = CBUUID(string: "")
    //let BLE_SERVICE_UUID = CBUUID(string: "")
    
    override init() {
        super.init()
        self.manager = CBCentralManager(delegate: self, queue: nil)
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state==CBManagerState.poweredOn {
            central.scanForPeripherals(withServices: nil)
        }else{
            print("Bluetooth unavailable")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("discovered \(peripheral) with advertismentData \(advertisementData) with rssi \(RSSI)")
        if let _ = peripheral.name {
            let justDiscovered = deviceModelList.deviceModel.init(withDeviceName: (peripheral.name != nil ? "\(peripheral.name!)" : "Unknown"), withDeviceRSSI: "\(RSSI)", withDeviceIdentifier: peripheral.identifier)
            listOfDevicesDiscovered.updateModelWith(deviceDiscovered: justDiscovered)
            //print("number of discovered devices:" + (listOfDevicesDiscovered.getAllDiscoveredDevices() != nil ? "\(listOfDevicesDiscovered.getAllDiscoveredDevices()!.count)" : "Empty") )
            discoveredPeripherals.append(peripheral)
            if let delegateCallback = deviceModelDelegate?.deviceModelListWasUpdated{
                delegateCallback(listOfDevicesDiscovered)
            }
            
        }else{
            return
        }
    }
    
    func beginScan(){
        self.manager?.stopScan()
        if(!self.manager!.isScanning){
            self.manager?.scanForPeripherals(withServices: nil)
        }
        
    }
    
    func connectDevice(thisDevice: deviceModelList.deviceModel){
        self.manager?.stopScan()
        for peripheral in discoveredPeripherals{
            if peripheral.identifier == thisDevice.deviceIdentifier{
                manager?.connect(peripheral)
                let dispatchTime = DispatchTime.now() + .seconds(30)
                DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                    self.disconnectDevice(thisDevice: thisDevice)
                    if let _ = self.deviceModelDelegate?.deviceToConnect , !self.checkIfConnectedToDevice(device: thisDevice){
                        self.deviceModelDelegate?.deviceToConnect(didConnect: false, withDevice: thisDevice, isTimeout: true)
                        return
                    }
                })
                return
            }
        }
        print("device unable to connect cannot find peripheral")
    }
    
    func checkIfConnectedToDevice(device: deviceModelList.deviceModel) -> Bool{
        var connected = false
        for peripheral in connectedPeripherals{
            if peripheral.identifier == device.deviceIdentifier
            {
                connected = true
                break
            }
        }
        return connected
    }
    
    func disconnectDevice(thisDevice: deviceModelList.deviceModel){
        for peripheral in discoveredPeripherals{
            if peripheral.identifier == thisDevice.deviceIdentifier{
                manager?.cancelPeripheralConnection(peripheral)
                return
            }
        }
        print("device unable to disonnect peripheral")
    }
    // MARK: - CBCManager delegate protocol methods
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        print("device connected")
        self.connectedToDevice = true
        connectedPeripherals.append(peripheral)
        if let _ = self.deviceModelDelegate?.deviceToConnect{
            if let devices = listOfDevicesDiscovered.getAllDiscoveredDevices(){
                for device in devices{
                    if device.deviceIdentifier == peripheral.identifier
                    {
                        listOfDevicesDiscovered.setDeviceConnected(forDevice: device, toState: true)
                        if let delegateCallback = deviceModelDelegate?.deviceModelListWasUpdated{
                            delegateCallback(listOfDevicesDiscovered)
                        }
                        self.deviceModelDelegate?.deviceToConnect(didConnect: true, withDevice: device, isTimeout: false)
                        return
                    }
                }
            }
        }
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?){
        print("device failed to connect")
        if let _ = error{
            print(error!.localizedDescription)
        }
        if let _ = self.deviceModelDelegate?.deviceToConnect{
            if let devices = listOfDevicesDiscovered.getAllDiscoveredDevices(){
                for device in devices{
                    if device.deviceIdentifier == peripheral.identifier
                    {
                        self.deviceModelDelegate?.deviceToConnect(didConnect: false, withDevice: device, isTimeout: false)
                        return
                    }
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?){
        print("disconnected from " + ( peripheral.name != nil ? "\(peripheral.name!)" : "Unknown") )
        if let _ = error{
            print(error!.localizedDescription)
        }
        for (index,connectedPeripheral) in connectedPeripherals.enumerated(){
            if peripheral.identifier == connectedPeripheral.identifier{
                connectedPeripherals.remove(at: index)
            }
        }
        self.connectedToDevice = false
        if let _ = self.deviceModelDelegate?.deviceToConnect{
            if let devices = listOfDevicesDiscovered.getAllDiscoveredDevices(){
                for device in devices{
                    if device.deviceIdentifier == peripheral.identifier
                    {
                        listOfDevicesDiscovered.setDeviceConnected(forDevice: device, toState: false)
                        if let delegateCallback = deviceModelDelegate?.deviceModelListWasUpdated{
                            delegateCallback(listOfDevicesDiscovered)
                        }
                        self.deviceModelDelegate?.deviceToConnect(didConnect: false, withDevice: device, isTimeout: false)
                        return
                    }
                }
            }
        }
    }
    
}

public class deviceModelList{
    class deviceModel{
        var deviceName: String
        var deviceRSSI: Int
        var deviceIdentifier: UUID
        var deviceIsConnected: Bool = false
        init(withDeviceName: String, withDeviceRSSI: String, withDeviceIdentifier: UUID){
            self.deviceName = withDeviceName
            self.deviceRSSI = Int(withDeviceRSSI)!
            self.deviceIdentifier = withDeviceIdentifier
            return
        }
    }
    private var deviceList = [deviceModel]()
    
    func getAllDiscoveredDevices()->[deviceModel]?{
        if deviceList.count == 0{
            return nil
        }
        return deviceList
    }
    
    func updateModelWith(deviceDiscovered: deviceModel){
        if deviceList.count == 0{
            deviceList.append(deviceDiscovered)
        }else{
            for (index,device) in deviceList.enumerated(){
                if deviceDiscovered.deviceIdentifier == device.deviceIdentifier{
                    deviceList[index] = deviceDiscovered
                    return
                }
            }
            var index = 0
            for deviceModel in deviceList{
                if abs(deviceDiscovered.deviceRSSI) > abs(deviceModel.deviceRSSI){
                    index+=1
                }
            }
            deviceList.insert(deviceDiscovered, at: index)
        }
    }
    
    func getDevice(forIndex: Int) -> deviceModel{
        return deviceList[forIndex]
        
    }
    
    func setDeviceConnected(forDevice: deviceModel, toState: Bool){
        for device in deviceList{
            if device.deviceIdentifier == forDevice.deviceIdentifier{
                device.deviceIsConnected = toState
            }
        }
    }
    
}

protocol deviceModelListUpdateDelegate{
    func deviceModelListWasUpdated(withNewModel: deviceModelList)
    func deviceToConnect(didConnect: Bool, withDevice: deviceModelList.deviceModel, isTimeout: Bool)
}
