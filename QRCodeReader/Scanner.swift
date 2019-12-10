//
//  Scanner.swift
//  QRCodeReader
//
//  Created by ProgrammingWithSwift on 2019/01/09.
//  Copyright © 2019 ProgrammingWithSwift. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

protocol ScannerDelegate: class
{
    func cameraView() -> UIView
    func delegateViewController() -> UIViewController
    func scanCompleted(withCode code: String)
}

class Scanner: NSObject
{
    public weak var delegate: ScannerDelegate?
    private var captureSession : AVCaptureSession?
    
    init(withDelegate delegate: ScannerDelegate)
    {
        self.delegate = delegate
        super.init()
        self.scannerSetup()
    }
    
    private func scannerSetup()
    {
        guard let captureSession = self.createCaptureSession() else {
            return
        }
        
        self.captureSession = captureSession
        
        guard let delegate = self.delegate else {
            return
        }
        
        let cameraView = delegate.cameraView()
        let previewLayer = self.createPreviewLayer(withCaptureSession: captureSession,
                                                   view: cameraView)
        cameraView.layer.addSublayer(previewLayer)
    }
    
    private func createCaptureSession() -> AVCaptureSession?
    {
        do
        {
            let captureSession = AVCaptureSession()
            guard let captureDevice = AVCaptureDevice.default(for: .video) else {
                return nil
            }
            
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            let metaDataOutput = AVCaptureMetadataOutput()
            
            // Add device input
            if captureSession.canAddInput(deviceInput) && captureSession.canAddOutput(metaDataOutput)
            {
                captureSession.addInput(deviceInput)
                captureSession.addOutput(metaDataOutput)
                
                guard let delegate = self.delegate,
                    let viewController = delegate.delegateViewController() as? AVCaptureMetadataOutputObjectsDelegate else {
                        return nil
                }
                
                metaDataOutput.setMetadataObjectsDelegate(viewController,
                                                          queue: DispatchQueue.main)
                metaDataOutput.metadataObjectTypes = self.metaObjectTypes()
                
                return captureSession
            }
        }
        catch
        {
            // Handle error
        }
        
        return nil
    }
    
    private func createPreviewLayer(withCaptureSession captureSession: AVCaptureSession,
                                    view: UIView) -> AVCaptureVideoPreviewLayer
    {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        return previewLayer
    }
    
    private func metaObjectTypes() -> [AVMetadataObject.ObjectType]
    {
        return [.qr,
                .code128,
                .code39,
                .code39Mod43,
                .code93,
                .ean13,
                .ean8,
                .interleaved2of5,
                .itf14,
                .pdf417,
                .upce
        ]
    }
    
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                         didOutput metadataObjects: [AVMetadataObject],
                         from connection: AVCaptureConnection)
    {
        self.requestCaptureSessionStopRunning()
        
        guard let metadataObject = metadataObjects.first,
            let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
            let scannedValue = readableObject.stringValue,
            let delegate = self.delegate else {
                return
        }
            
        delegate.scanCompleted(withCode: scannedValue)
    }
    
    public func requestCaptureSessionStartRunning()
    {
        self.toggleCaptureSessionRunningState()
    }
    
    public func requestCaptureSessionStopRunning()
    {
        self.toggleCaptureSessionRunningState()
    }
    
    private func toggleCaptureSessionRunningState() {
        guard let captureSession = self.captureSession else {
            return
        }
        
        if !captureSession.isRunning
        {
            captureSession.startRunning()
        }
        else
        {
            captureSession.stopRunning()
        }
    }
}
