//
//  FullWidthHostingView.swift
//  SoundBar
//
//  Created by Adam on 09/05/2026.
//


import SwiftUI
import AppKit

class FullWidthHostingView<Content: View>: NSHostingView<Content> {

    override var intrinsicContentSize: NSSize {
        return NSSize(width: 1000, height: 30)
    }
}