//
//  ContentView.swift
//  Signed
//
//  Created by Markus Moenig on 12/12/20.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.colorScheme) var deviceColorScheme   : ColorScheme

    @Binding var document                               : SignedDocument
    @StateObject var storeManager                       : StoreManager

    enum Layout {
        case horizontal, vertical
    }
    
    @State private var layout                           : Layout = .horizontal
    
    @State private var showSideView                     : Bool = true
    
    @State var updateView                               : Bool = false
    
    @State private var toolsAreOn                       : Bool = false
    
    @State private var searchText = ""

    @State private var modulesArrived                   : Bool = false

    @State private var colorValue                       : Color = Color(.gray)
    
    /// Indicatesn that building is in progress
    @State private var isBuilding                       : Bool = false


    #if os(macOS)
    let leftPanelWidth                      : CGFloat = 160
    #else
    let leftPanelWidth                      : CGFloat = 230
    #endif
    
    #if os(macOS)
    let rightPanelWidth                     : CGFloat = 200
    #else
    let rightPanelWidth                     : CGFloat = 230
    #endif
    
    var body: some View {
        
        GeometryReader { geometry in
            
            #if os(OSX)
            HSplitView {
                NavigationView {
                    
                    ProjectView(document.model)

                    VStack(spacing: 0) {
                        
                        if layout == .vertical {
                            HSplitView {
                                EditorView(document.model)
                                ProgressView(model: document.model)
                                    .frame(maxWidth: 3)
                                PreviewView(document: document, model: document.model)
                            }
                        } else {
                            VSplitView {
                                PreviewView(document: document, model: document.model)
                                ProgressView(model: document.model)
                                    .frame(maxHeight: 3)
                                EditorView(document.model)
                            }
                        }
                    }
                }
                
                if showSideView == true {
                    SideView(model: document.model)
                        .frame(maxWidth: rightPanelWidth)
                }
            }
            #else
            HStack {
                NavigationView {
                    
                    ProjectView(document.model)
                        .frame(maxWidth: leftPanelWidth)

                    VStack(spacing: 0) {
                        
                        if layout == .vertical {
                            HStack(spacing: 2) {
                                EditorView(document.model)
                                PreviewView(document: document, model: document.model)
                            }
                        } else {
                            VStack(spacing: 2) {
                                PreviewView(document: document, model: document.model)
                                EditorView(document.model)
                            }
                        }
                    }
                }
                
                if showSideView == true {
                    SideView(model: document.model)
                        .frame(maxWidth: rightPanelWidth)
                }
            }
            #endif
        }
        
        .toolbar {
            
            ToolbarItemGroup(placement: .automatic) {

                Button(action: {
                    
                    if isBuilding == false {
                        if document.model.codeEditorMode == .object {
                            if let object = document.model.codeEditorObjectEntity {
                                if let data = object.code {
                                    if let value = String(data: data, encoding: .utf8) {
                                        if let renderer = document.model.renderer {
                                            document.model.builder.build(code: value, kit: document.model.modeler!.mainKit, content: .object, renderKits: [renderer.mainRenderKit, renderer.iconRenderKit], objectEntity: object)
                                            isBuilding = true
                                        }
                                    }
                                }
                            }
                        } else
                        if document.model.codeEditorMode == .material {
                            if let material = document.model.codeEditorMaterialEntity {
                                if let data = material.code {
                                    if let value = String(data: data, encoding: .utf8) {
                                        if let renderer = document.model.renderer {
                                            document.model.builder.build(code: value, kit: document.model.modeler!.mainKit, content: .material, renderKits: [renderer.mainRenderKit, renderer.iconRenderKit], materialEntity: material)
                                            isBuilding = true
                                        }
                                    }
                                }
                            }
                        } else {
                            if let renderer = document.model.renderer, let object = document.model.selectedObject {
                                switch document.model.project.getObjectType(from: object.id) {
                                    case .object:
                                        document.model.builder.build(code: object.getCode(), kit: document.model.modeler!.mainKit, content: .object, renderKits: [renderer.mainRenderKit])
                                        isBuilding = true
                                    case .material:
                                        document.model.builder.build(code: object.getCode(), kit: document.model.modeler!.mainKit, content: .material, renderKits: [renderer.mainRenderKit])
                                        isBuilding = true
                                    default:
                                        document.model.builder.build(code: document.model.project.main.getCode(), kit: document.model.modeler!.mainKit, renderKits: [renderer.mainRenderKit])
                                        isBuilding = true
                                }
                            }
                        }
                    } else {
                        isBuilding = false
                        document.model.builder.workItem?.cancel()
                        document.model.builder.exitLua()
                        if let mainKit = document.model.modeler?.mainKit {
                            mainKit.pipeline = []
                        }
                        document.model.infoProgressTotalCmds = 0
                        document.model.infoProgressProcessedCmds = 0
                        document.model.builder.context.createProgressValues()
                    }
                }) {
                    if modulesArrived == false {
                        Text("Waiting for modules...")
                    } else
                    if isBuilding {
                        Text("Stop")
                    } else {
                        Text("Build")
                    }
                }
                .keyboardShortcut("b")
                .disabled(modulesArrived == false)
            }
            
            ToolbarItemGroup(placement: .automatic) {
                
                HStack(spacing: 0) {
                    Button(action: {
                        layout = .horizontal
                    }) {
                        Image(systemName: layout == .horizontal ? "rectangle.split.1x2.fill" : "rectangle.split.1x2")
                    }
                    
                    Button(action: {
                        layout = .vertical
                    }) {
                        Image(systemName: layout == .vertical ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                    }
                }
                
                Button(action: {
                    showSideView.toggle()
                }) {
                    Image(systemName: "sidebar.right")
                }
            }

            ToolbarItemGroup(placement: .automatic) {
                
                ColorPicker("", selection: $colorValue, supportsOpacity: false)
                    .onChange(of: colorValue) { newValue in
                        if let cgColor = newValue.cgColor?.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil) {
                            
                            let colorValueText = "vec3(\(String(format: "%.02f", Float(cgColor.components![0]))),\(String(format: "%.02f", Float(cgColor.components![1]))),\(String(format: "%.02f", Float(cgColor.components![2]))))"
                            
                            #if os(iOS)
                            UIPasteboard.general.string = colorValueText
                            #elseif os(OSX)
                            let pasteBoard = NSPasteboard.general
                            pasteBoard.clearContents()
                            pasteBoard.setString(colorValueText, forType: .string)
                            #endif
                        }
                    }
                

            }
            
            ToolbarItemGroup(placement: .automatic) {
            }
        }

        .onReceive(document.model.updateUI) { _ in
            updateView.toggle()
        }
        
        .onReceive(document.model.modulesArrived) { _ in
            modulesArrived = true
        }
        
        .onReceive(document.model.modelingProgressChanged) { string in
            if document.model.infoProgressProcessedCmds == document.model.infoProgressTotalCmds {
                isBuilding = false
            }
        }
    }
    
    var toolGiftMenu : some View {
        Menu {
            HStack {
                VStack(alignment: .leading) {
                    Text("Small Tip")
                        .font(.headline)
                    Text("Tip of $2 for the author")
                        .font(.caption2)
                }
                Button(action: {
                    storeManager.purchaseId("com.moenig.ShaderMania.IAP.Tip2")
                }) {
                    Text("Buy for $2")
                }
                .foregroundColor(.blue)
                Divider()
                VStack(alignment: .leading) {
                    Text("Medium Tip")
                        .font(.headline)
                    Text("Tip of $5 for the author")
                        .font(.caption2)
                }
                Button(action: {
                    storeManager.purchaseId("com.moenig.ShaderMania.IAP.Tip5")
                }) {
                    Text("Buy for $5")
                }
                .foregroundColor(.blue)
                Divider()
                VStack(alignment: .leading) {
                    Text("Large Tip")
                        .font(.headline)
                    Text("Tip of $10 for the author")
                        .font(.caption2)
                }
                Button(action: {
                    storeManager.purchaseId("com.moenig.ShaderMania.IAP.Tip10")
                }) {
                    Text("Buy for $10")
                }
                .foregroundColor(.blue)
                Divider()
                Text("You are awesome! ❤️❤️")
            }
        }
        label: {
            Label("Dollar", systemImage: "gift")//dollarsign.circle")
        }
    }
}
