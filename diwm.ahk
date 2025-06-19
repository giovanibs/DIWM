#Requires AutoHotkey v2.0
#SingleInstance Force

Main()

Main() {
    hwnds := WinGetList("Diablo Immortal")
    count := hwnds.Length

    if count = 0 {
        MsgBox "No 'Diablo Immortal' windows found."
        ExitApp
    }

    my_gui := Gui("+AlwaysOnTop", "Window Manager")
    my_gui.AddText(, "Foram encontradas " count " instâncias de 'Diablo Immortal'.")
    my_gui.AddText(, "Escolha o modo de redimensionamento:")
    autoRadio := my_gui.AddRadio("vMode Checked", "Ajuste automático à tela")
    manualRadio := my_gui.AddRadio(, "Ajuste manual do tamanho da janela")

    my_gui.AddButton("Default", "Continuar").OnEvent("Click", (*) => OnMainProceed(my_gui, hwnds))
    my_gui.AddButton(, "Cancelar").OnEvent("Click", (*) => ExitApp())
    my_gui.Show()
}

OnMainProceed(gui, hwnds) {
    gui.Submit()

    mode := gui["Mode"].Value  ; 1 = Auto-fit, 0 = Manual

    gui.Destroy()

    if mode = 1 {
        AutoResize(hwnds)
    } else {
        ShowManualSizeGui(hwnds)
    }
}

ShowManualSizeGui(hwnds) {
    manual_size_gui := Gui("+AlwaysOnTop", "Manual Size")
    
    wa := GetPrimaryMonitorWorkArea()
    
    manual_size_gui.AddText(, "Defina o tamanho da janela (área livre do seu monitor principal: " 
                    . wa.Width . "x"  . wa.Height . "):")
    
    manual_size_gui.AddText(, "Largura:")
    widthBox := manual_size_gui.AddEdit("vWidth w100")
    
    manual_size_gui.AddText(, "Altura:")
    heightBox := manual_size_gui.AddEdit("vHeight w100")

    manual_size_gui.AddButton("Default", "Aplicar").OnEvent("Click", (*) => OnManualApply(manual_size_gui, hwnds))
    manual_size_gui.AddButton(, "Cancelar").OnEvent("Click", (*) => ExitApp())

    manual_size_gui.Show()
}


OnManualApply(gui, hwnds) {
    gui.Submit()

    width := gui["Width"].Value
    height := gui["Height"].Value

    if (!IsInteger(width) || width <= 0 || width > A_ScreenWidth || !IsInteger(height) || height <= 0 || height > A_ScreenHeight) {
        MsgBox "Largura e/ou altura inválidas. Por favor, use valores positivos e menores que a sua área de trabalho."
        return
    }

    wa := GetPrimaryMonitorWorkArea()
    count := hwnds.Length

    for index, hwnd in hwnds {
        x := wa.Left
        y := wa.Top
        WinMove(x, y, width, height, "ahk_id " hwnd)
    }

    MsgBox "Redimensionada(s) " count " janelas para " width "x" height "."
    ExitApp
}


AutoResize(hwnds) {
    wa := GetPrimaryMonitorWorkArea()
    count := hwnds.Length
    
    switch count {
        case 1:
            resize_rate := 1
        case 2, 3, 4:
            resize_rate := 2
        case 5, 6, 7, 8, 9:
            resize_rate := 3
        case 10, 11, 12, 13, 14, 15, 16:
            resize_rate := 4
    }
    
    width := wa.Width/resize_rate
    height := wa.Height/resize_rate
    for i, hwnd in hwnds {
        x := wa.Left + width*Mod(i-1, resize_rate)
        y := wa.Top + height*Floor((i-1)/resize_rate)
        WinMove(x, y, width, height, "ahk_id " hwnd)
    }
}

GetPrimaryMonitorWorkArea() {
    ; Get handle to the primary monitor
    hMonitor := DllCall("MonitorFromPoint", "Int64", 0, "UInt", 1)  ; MONITOR_DEFAULTTOPRIMARY = 1

    ; Allocate structure for MONITORINFO (size = 40 bytes)
    ; MONITORINFO = { cbSize (4) + rcMonitor (16) + rcWork (16) + dwFlags (4) }
    monInfo := Buffer(40, 0)
    NumPut("UInt", 40, monInfo, 0)  ; Set cbSize = 40

    success := DllCall("GetMonitorInfoA", "Ptr", hMonitor, "Ptr", monInfo)
    if !success
        throw Error("GetMonitorInfo failed")

    ; Get rcWork (work area) at offset 20
    left   := NumGet(monInfo, 20, "Int")
    top    := NumGet(monInfo, 24, "Int")
    right  := NumGet(monInfo, 28, "Int")
    bottom := NumGet(monInfo, 32, "Int")

    width  := right - left
    height := bottom - top

    return { 
        Left: left, 
        Top: top, 
        Right: right, 
        Bottom: bottom, 
        Width: width, 
        Height: height 
    }
}