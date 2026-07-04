//
//  PlatformImage.swift
//  Budgetting
//
//  Created by Zacharie on 4/7/26.
//

#if os(iOS)
import UIKit
public typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
public typealias PlatformImage = NSImage
#endif
