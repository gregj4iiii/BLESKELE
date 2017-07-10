//
//  BluetoothViewController.swift
//  BLESKELE
//
//  Created by Gregory Joseph on 2017-07-04.
//  Copyright © 2017 4iiii. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"
private let unNecesssaryBool: Bool = false

class BluetoothViewController: UICollectionViewController, deviceModelListUpdateDelegate {
    
    let skeleton: BLESkeleton = BLESkeleton()
    var actionInProgress: Bool = false
    let connectedDevice: deviceModelList.deviceModel? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        // Do any additional setup after loading the view.
        skeleton.deviceModelDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using [segue destinationViewController].
     // Pass the selected object to the new view controller.
     }
     */
    
    // MARK: UICollectionViewDataSource
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return (skeleton.listOfDevicesDiscovered.getAllDiscoveredDevices() != nil ? (skeleton.listOfDevicesDiscovered.getAllDiscoveredDevices()!.count) : 0 )
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
        
        // Configure the cell
        cell.prepareForReuse()
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView.frame.size.width/2, height: 50))
        label.text = "\(indexPath.row). " + (skeleton.listOfDevicesDiscovered.getAllDiscoveredDevices() != nil ? "\(skeleton.listOfDevicesDiscovered.getDevice(forIndex: indexPath.row).deviceName)" : "Unspecified") + " RSSI:  " + (skeleton.listOfDevicesDiscovered.getAllDiscoveredDevices() != nil ? "\(skeleton.listOfDevicesDiscovered.getDevice(forIndex: indexPath.row).deviceRSSI)" : "??")
        label.highlightedTextColor = UIColor.red
        label.backgroundColor = UIColor.white
        label.textColor = UIColor.black
        if (skeleton.listOfDevicesDiscovered.getDevice(forIndex: indexPath.row).deviceIsConnected){
            label.backgroundColor = UIColor.cyan
            label.textColor = UIColor.orange
        }
        cell.contentView.addSubview(label)
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        
        if !skeleton.listOfDevicesDiscovered.getDevice(forIndex: indexPath.row).deviceIsConnected{
            let actionMenu = UIAlertController(title: (skeleton.listOfDevicesDiscovered.getAllDiscoveredDevices() != nil ? "\(skeleton.listOfDevicesDiscovered.getDevice(forIndex: indexPath.row).deviceName)" : "Unspecified"), message: "Select connect to begin pairing", preferredStyle: .actionSheet)
            let connectAction = UIAlertAction(title: "Connect", style: .default) { (connectAction) in
                //handle connect here
                self.skeleton.connectDevice(thisDevice: self.skeleton.listOfDevicesDiscovered.getDevice(forIndex: indexPath.row))
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (cancelAction) in
                //handle
                
            }
            actionMenu.addAction(connectAction)
            actionMenu.addAction(cancelAction)
            self.present(actionMenu, animated: false) {
                //completioncodehere
            }
        }else{
            let actionMenu = UIAlertController(title: (skeleton.listOfDevicesDiscovered.getAllDiscoveredDevices() != nil ? "\(skeleton.listOfDevicesDiscovered.getDevice(forIndex: indexPath.row).deviceName)" : "Unspecified"), message: "Select disconnect to cancel pairing", preferredStyle: .actionSheet)
            let disconnectAction = UIAlertAction(title: "Disconnect", style: .default) { (disconnectAction) in
                //handle connect here
                self.skeleton.disconnectDevice(thisDevice: self.skeleton.listOfDevicesDiscovered.getDevice(forIndex: indexPath.row))
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (cancelAction) in
                //handle
                
            }
            actionMenu.addAction(disconnectAction)
            actionMenu.addAction(cancelAction)
            self.present(actionMenu, animated: false)
                
        }
    }
    
    
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
    }
    
    
    // MARK: deviceModelUpdateDelegate methods
    func deviceModelListWasUpdated(withNewModel: deviceModelList){
        //print("deviceModelListWasUpdated(withNewModel: deviceModelList) called in BluetoothViewController")
        if(!actionInProgress){collectionView?.reloadData()}
    }
    
    func deviceToConnect(didConnect: Bool, withDevice: deviceModelList.deviceModel, isTimeout: Bool){
        print("BluetoothViewController deviceToConnect(didConnect: \(didConnect) )");
        if(didConnect){
            let alertController = UIAlertController(title: "Connected \(withDevice.deviceName) Successfully", message: "Disconnect from device now?", preferredStyle: .alert)
            let disconnectAction = UIAlertAction(title: "Disconnect", style: .destructive, handler: { (disconnectAction) in
                //perform sensors disconnect
                self.skeleton.disconnectDevice(thisDevice: withDevice)
            })
            let okayAction = UIAlertAction(title: "Okay", style: .default, handler: { (okayAction) in
                //do nothing
            })
            alertController.addAction(okayAction)
            alertController.addAction(disconnectAction)
            self.present(alertController, animated: true)
        }else{
            let alertController = UIAlertController(title: "\(withDevice.deviceName) disconnected", message: isTimeout ? "Connection Timeout" : "The peripheral disconnected begin scan again?", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .cancel, handler: { (okAction) in
                self.skeleton.beginScan()
            })
            alertController.addAction(okAction)
            if self.presentedViewController != nil
            {
                self.presentedViewController?.dismiss(animated: true, completion: {
                    self.present(alertController, animated: true)
                    
                })
            }else{
                self.present(alertController, animated: true)
            }
            
        }
        
    }
    
}
