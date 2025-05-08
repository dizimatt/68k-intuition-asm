close_lib_exit:
    move.l   execbase,a6
    move.l   intbase,a1
    jsr      closelib(a6)    ; Close library
    
exit_program:
    moveq    #0,d0           ; Clean exit
    rts                      ; Return to system; String gadget and related structures will be commented out for now
; String gadget (DISABLED FOR NOW)
; string_gadget:
;    dc.l    0                   ; No next gadget
;    dc.w    20                  ; Left position
;    dc.w    80                  ; Top position
;    dc.w    200                 ; Width
;    dc.w    20                  ; Height
;    dc.w    GADGHCOMP           ; Flags: complement highlight
;    dc.w    GADGIMMEDIATE       ; Activation flags
;    dc.w    STRGADGET           ; Gadget type (string)
;    dc.l    0                   ; No render image
;    dc.l    0                   ; No select image
;    dc.l    0                   ; No text
;    dc.l    0                   ; No mutual exclude
;    dc.l    string_info         ; Special info
;    dc.w    2                   ; Gadget ID
;    dc.l    0                   ; User data
;
; String info structure (DISABLED FOR NOW)
; string_info:
;    dc.l    str_buffer          ; Buffer
;    dc.l    undo_buffer         ; Undo buffer
;    dc.w    0                   ; Buffer position
;    dc.w    40                  ; Max characters
;    dc.w    0                   ; Display position
;    dc.w    0                   ; Undo size
;    dc.w    0                   ; Num chars
;    dc.w    0                   ; Visible size
;    dc.w    0                   ; Horizontal delta
;    dc.w    0                   ; Vertical delta
;    dc.l    0                   ; RastPort
;    dc.l    0                   ; LongInt
;    dc.l    0                   ; KeyMap; Minimal Amiga 68000 code to open an intuition window with a button
; Program terminates when the close gadget is pressed

    SECTION code,CODE

; Constants
execbase     = 4          ; Exec base address
openlib      = -408       ; OpenLibrary offset
closelib     = -414       ; CloseLibrary offset
openwin      = -204       ; OpenWindow offset
closewin     = -72        ; CloseWindow offset 
getmsg       = -372       ; GetMsg offset

; Gadget flags/constants
GADGHCOMP    = 0          ; Complement highlight method
GADGHBOX     = 1          ; Draw box highlight method
BOOLGADGET   = 1          ; Boolean gadget type
STRGADGET    = 4          ; String gadget type
TOGGLESELECT = $0100      ; Toggle select flag
GADGIMMEDIATE= $0002      ; Immediate gadget flag

start:
    ; Open intuition.library
    move.l   execbase,a6
    lea      intname,a1
    clr.l    d0                ; Any version
    jsr      openlib(a6)  
    tst.l    d0
    beq.l      exit_program      ; Failed to open library - use long branch
    move.l   d0,intbase        ; Save intuition base

    ; Open a simple window
    move.l   d0,a6             ; Intuition base to a6
    lea      win_def,a0        ; Window definition pointer
    jsr      openwin(a6)
    tst.l    d0
    beq.l      close_lib_exit    ; Failed to open window - use long branch
    move.l   d0,winhandle      ; Save window handle

    ; Main message loop
    ; Modified main message loop to handle gadget events
wait_loop:
    move.l   execbase,a6         ; Exec base
    move.l   winhandle,a0        ; Window handle
    move.l   86(a0),a0           ; MsgPort
    jsr      getmsg(a6)          ; Check for messages
    tst.l    d0                  ; Any message?
    beq      wait_loop           ; No, keep waiting - use long branch
    
    move.l   d0,a1               ; Message to a1
    move.l   20(a1),d2           ; IDCMP class
    
    btst     #9,d2               ; CLOSEWINDOW?
    bne      do_cleanup          ; Yes, exit - use long branch
    
    btst     #3,d2               ; GADGETUP?
    beq      wait_loop           ; No, keep waiting - use long branch
    
    ; A gadget was released - check which one
    move.l   28(a1),a2           ; Get gadget address
    move.w   26(a2),d3           ; Get gadget ID
    cmpi.w   #1,d3               ; Is it our button (ID=1)?
    bne      wait_loop           ; No, ignore - use long branch
    
    ; Button was clicked - would do something here
    ; For now, we'll just continue waiting
    bra      wait_loop           ; use long branch

do_cleanup:
    ; Clean up 
    move.l   intbase,a6
    move.l   winhandle,a0
    jsr      closewin(a6)        ; Close window
    bra.l      close_lib_exit      ; use long branch

    SECTION data,DATA_C    ; CHIP memory for window

intname:
    dc.b    'intuition.library',0
    cnop    0,2              ; Ensure word alignment

; Button gadget with box highlighting (non-toggle)
button_gadget:
    dc.l    0                  ; No next gadget
    dc.w    20                 ; Left position
    dc.w    50                 ; Top position 
    dc.w    100                ; Width
    dc.w    20                 ; Height
    dc.w    GADGHBOX           ; Flags: BOX highlighting method
    dc.w    GADGIMMEDIATE      ; Activation flags (removed TOGGLESELECT)
    dc.w    BOOLGADGET         ; Gadget type (boolean)
    dc.l    button_border      ; Border structure for rendering
    dc.l    0                  ; No select image
    dc.l    button_text        ; Text structure
    dc.l    0                  ; No mutual exclude
    dc.l    0                  ; No special info
    dc.w    1                  ; Gadget ID
    dc.l    0                  ; User data

; Button border structure - we'll create a double border effect
button_border:
    dc.w    0, 0               ; Left edge, top edge offset
    dc.b    1, 0               ; Pen colors (1=white)
    dc.b    0                  ; Drawing mode (JAM1)
    cnop    0,2                ; Word align
    dc.b    5                  ; 5 pairs of coordinates
    cnop    0,2                ; Word align
    dc.l    button_coords      ; Coordinates
    dc.l    button_border2     ; Next border - link to inner border

; Second border structure for inner border
button_border2:
    dc.w    1, 1               ; Left edge, top edge offset (inset by 1 pixel)
    dc.b    2, 0               ; Pen colors (2=different color)
    dc.b    0                  ; Drawing mode (JAM1)
    cnop    0,2                ; Word align
    dc.b    5                  ; 5 pairs of coordinates
    cnop    0,2                ; Word align
    dc.l    button_coords2     ; Coordinates
    dc.l    0                  ; No next border

; Button border coordinates (outer)
button_coords:
    dc.w    0, 0               ; Top left
    dc.w    100, 0             ; Top right
    dc.w    100, 20            ; Bottom right
    dc.w    0, 20              ; Bottom left
    dc.w    0, 0               ; Back to start

; Button border coordinates (inner)
button_coords2:
    dc.w    0, 0               ; Top left
    dc.w    98, 0              ; Top right
    dc.w    98, 18             ; Bottom right
    dc.w    0, 18              ; Bottom left
    dc.w    0, 0               ; Back to start

; Button text
button_text:
    dc.b    1,0              ; Pen colors
    dc.b    0                ; Drawing mode
    cnop    0,2              ; Word align
    dc.w    30,6             ; X/Y offset for text
    dc.l    0                ; Font (system default)
    dc.l    button_string    ; String pointer
    dc.l    0                ; Next text

button_string:
    dc.b    'Click Me',0
    cnop    0,2              ; Word align

; Modify Window IDCMP flags to include gadget events
win_def:
    dc.w    10,10            ; Left, Top
    dc.w    300,100          ; Width, Height
    dc.b    1,0              ; Detail/Block pens
    cnop    0,2              ; Word align after bytes!
    dc.l    $208             ; IDCMP: CLOSEWINDOW + GADGETUP
    dc.l    $1000F           ; Flags: ACTIVATE + system gadgets
    dc.l    button_gadget    ; First gadget
    dc.l    0                ; No checkmark
    dc.l    win_title        ; Window title
    dc.l    0                ; No custom screen
    dc.l    0                ; No bitmap
    dc.w    50,20            ; Min width/height
    dc.w    640,200          ; Max width/height 
    dc.w    1                ; WBENCHSCREEN

win_title:
    dc.b    'Test Window',0
    cnop    0,2

; String buffers (DISABLED FOR NOW)
; str_buffer:
;    dc.b    'Enter text here',0
;    cnop    0,2
;    blk.b   25,0               ; Additional space (total 40 chars)
;    
; undo_buffer:
;    blk.b   40,0               ; Undo buffer space

; Global variables
intbase:
    dc.l    0                ; Intuition library base
winhandle:
    dc.l    0                ; Window handle

    END     start            ; Entry point