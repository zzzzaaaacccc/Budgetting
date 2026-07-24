//
//  PlatformImage.swift
//  Budgetting
//
//  Created by Zacharie on 24/7/26.
//

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
typealias PlatformImage = NSImage
#endif
