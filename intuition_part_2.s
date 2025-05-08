; Amiga 68020 code to open an intuition window with gadgets
; Program terminates when the close gadget is pressed

; Intuition function offsets
openlib      = -408    ; OpenLibrary function offset
closelibrary = -414    ; CloseLibrary function offset
openwindow   = -204    ; OpenWindow function offset
closewindow  = -72     ; CloseWindow function offset
openscreen   = -198    ; OpenScreen function offset
closescreen  = -66     ; CloseScreen function offset
getmsg       = -372    ; GetMsg function offset

; System constants
execbase     = 4       ; Exec base address

    SECTION code,CODE

start:
    bsr.w    openint      ; Open intuition library
;    bsr.w    scropen      ; Open our custom screen
    bsr.w    windopen     ; Open our window with gadgets
    
mainloop:
    move.l   execbase,a6           ; Exec base address
    move.l   windowhd,a0           ; Window handle
    move.l   86(a0),a0             ; User port pointer
    jsr      getmsg(a6)            ; Get message
    tst.l    d0                    ; Any message?
    beq.s    mainloop              ; No, loop again
    
    move.l   d0,a0                 ; Message pointer to a0
    move.l   20(a0),d1             ; Get IDCMP flags
    btst     #9,d1                 ; Test CLOSEWINDOW bit (bit 9)
    beq.s    mainloop              ; If not set, loop again
    
    ; Close window was clicked, clean up and exit
    bsr.w    windclose             ; Close window
;    bsr.w    scrclose              ; Close screen
    bsr.w    closeint              ; Close intuition library
    rts                            ; Return to system

; Open Intuition library
openint:
    move.l   execbase,a6           ; Exec base address
    lea      intname,a1        ; Name of intuition library
    jsr      openlib(a6)           ; Open intuition library
    move.l   d0,intbase            ; Save intuition base address
    rts

; Close Intuition library
closeint:
    move.l   execbase,a6           ; Exec base address
    move.l   intbase,a1            ; Intuition base address
    jsr      closelibrary(a6)      ; Close intuition
    rts

; Open our custom screen
scropen:
    move.l   intbase,a6            ; Intuition base address
    lea      screen_defs,a0    ; Pointer to screen definition
    jsr      openscreen(a6)        ; Open screen
    move.l   d0,screenhd           ; Save screen handle
    rts

; Close screen
scrclose:
    move.l   intbase,a6            ; Intuition base address
    move.l   screenhd,a0           ; Screen handle
    jsr      closescreen(a6)       ; Close screen
    rts

; Open window with gadgets
windopen:
    move.l   intbase,a6            ; Intuition base address
    lea      window_defs,a0    ; Pointer to window definition
    jsr      openwindow(a6)        ; Open window
    move.l   d0,windowhd           ; Save window handle
    rts

; Close window
windclose:
    move.l   intbase,a6            ; Intuition base address
    move.l   windowhd,a0           ; Window handle
    jsr      closewindow(a6)       ; Close window
    rts

; *** Data Section ***

    SECTION data,DATA

; Intuition library name
intname:
    dc.b    "intuition.library",0
    even    ; Ensure alignment

; Screen definition table
screen_defs:
    dc.w    0                      ; X position
    dc.w    0                      ; Y position 
    dc.w    640                    ; Width
    dc.w    200                    ; Height
    dc.w    2                      ; Depth (2 bitplanes = 4 colors)
    dc.b    1                      ; Detail pen (text color)
    dc.b    0                      ; Block pen (background color)
    dc.w    2                      ; View modes (normal)
    dc.w    15                     ; Screen type (custom screen)
    dc.l    0                      ; Default font (standard)
    dc.l    screen_title           ; Screen title
    dc.l    0                      ; No custom gadgets
    dc.l    0                      ; No custom bitmap
screen_title:
    dc.b    "My Amiga Screen",0
    even

; Window definition table
window_defs:
    dc.w    20                     ; X position
    dc.w    20                     ; Y position
    dc.w    400                    ; Width
    dc.w    150                    ; Height
    dc.b    1                      ; Detail pen (text color)
    dc.b    0                      ; Block pen (background)
    dc.l    $200                   ; IDCMP flags: CLOSEWINDOW
    dc.l    $100F                  ; Window flags: ACTIVATE and all system gadgets
    dc.l    gadget1                ; Pointer to first gadget
    dc.l    0                      ; Checkmark (standard)
    dc.l    window_title           ; Window title
screenhd:
    dc.l    0                      ; Screen handle (filled at runtime)
    dc.l    0                      ; Custom bitmap (none)
    dc.w    100                    ; Min width
    dc.w    50                     ; Min height
    dc.w    640                    ; Max width
    dc.w    200                    ; Max height
    dc.w    1                     ; Screen type
    ; was 15
window_title:
    dc.b    "My Intuition Window",0
    even

; Boolean gadget (a button)
gadget1:
    dc.l    gadget2                ; Pointer to next gadget
    dc.w    50                     ; X position
    dc.w    60                     ; Y position
    dc.w    100                    ; Width
    dc.w    20                     ; Height
    dc.w    4                      ; Flags (GADGIMAGE)
    dc.w    $102                   ; Activation (TOGGLESELECT | GADGIMMEDIATE)
    dc.w    1                      ; Type (boolean)
    dc.l    button_image           ; Gadget image
    dc.l    button_data_select     ; No select image
    dc.l    button_text            ; Text for gadget
    dc.l    0                      ; No exclude
    dc.l    0                      ; No special info
    dc.w    1                      ; Gadget ID
    dc.l    0                      ; User data

; String gadget
gadget2:
    dc.l    0                      ; No more gadgets
    dc.w    50                     ; X position
    dc.w    100                    ; Y position
    dc.w    200                    ; Width
    dc.w    20                     ; Height
    dc.w    0                      ; Flags
    dc.w    2                      ; Activation (GADGIMMEDIATE)
    dc.w    4                      ; Type (String gadget)
    dc.l    string_border          ; Border for string
    dc.l    0                      ; No select border
    dc.l    0                      ; No text
    dc.l    0                      ; No exclude
    dc.l    string_info            ; String info
    dc.w    2                Type      ; Gadget ID
    dc.l    0                      ; User data

; Image for button
button_image:
    dc.w    0, 0                   ; Left edge, top edge
    dc.w    100, 20                ; Width, height
    dc.w    1                      ; Depth (1 bitplane)
    dc.l    button_data            ; Image data
    dc.b    1, 0                   ; PlanePick, PlaneOnOff
    dc.l    0                      ; Next image

; Button image data (simple pattern)
button_data:
    dc.w    %1111111111111111, %1000000000000001
    dc.w    %1000000000000001, %1000000000000001
    dc.w    %1000000000000001, %1000000000000001
    dc.w    %1000000000000001, %1000000000000001
    dc.w    %1000000000000001, %1000000000000001
    dc.w    %1000000000000001, %1000000000000001
    dc.w    %1000000000000001, %1000000000000001
    dc.w    %1000000000000001, %1000000000000001
    dc.w    %1000000000000001, %1111111111111111

button_data_select:
    dc.w    %1111111111111111, %1000000000000001
    dc.w    %1000000000000001, %1000000000000001
    dc.w    %1000000000000001, %1000000000000001
    dc.w    %1011111111111101, %1000000000000001
    dc.w    %1001111111111001, %1000000000000001
    dc.w    %1000111111110001, %1000000000000001
    dc.w    %1001111111111001, %1000000000000001
    dc.w    %1011111111111101, %1000000000000001
    dc.w    %1000000000000001, %1111111111111111

; Text for button
button_text:
    dc.b    3, 0                   ; Text color, background
    dc.b    0                      ; Text mode
    even
    dc.w    20, 7                  ; X and Y text position
    dc.l    0                      ; Standard font
    dc.l    button_label           ; Text pointer
    dc.l    0                      ; No more text
button_label:
    dc.b    "Click Me",0
    even

; Border for string gadget
string_border:
    dc.w    0, 0                   ; Left edge, top edge
    dc.b    3, 0                   ; Color, unused
    dc.b    0                      ; Mode (JAM1)
    dc.b    5                      ; 5 pairs of coordinates
    even
    dc.l    string_coords          ; Coordinates
    dc.l    0                      ; Next border
string_coords:
    dc.w    -2, -2                   ; Start point
    dc.w    200, -2                 ; Top right
    dc.w    200, 9                ; Bottom right
    dc.w    -2, 9                  ; Bottom left
    dc.w    -2, -2                   ; Back to start


;string_coords:
;    dc.w    0, 0                   ; Start point
;    dc.w    200, 0                 ; Top right
;    dc.w    200, 20                ; Bottom right
;    dc.w    0, 20                  ; Bottom left
;    dc.w    0, 0                   ; Back to start

; String info structure
string_info:
    dc.l    str_buffer             ; Pointer to string buffer
    dc.l    undo_buffer            ; Undo buffer
    dc.w    0                      ; Cursor position
    dc.w    40                     ; Max chars
    dc.w    0                      ; Output from char 0
    dc.w    0                      ; Chars in undo buffer
    dc.w    0                      ; Number of chars in buffer
    dc.w    0                      ; Number visible in box
    dc.w    0                      ; Horiz offset
    dc.w    0                      ; Vert offset
    dc.l    0                      ; Rastport (filled by system)
    dc.l    0                      ; Longint (for integer gadgets)
    dc.l    0                      ; Standard keymap

; Buffers for string gadget
str_buffer:
    dc.b    "Enter text here",0
    blk.b   24,0                   ; Reserve space for 40 chars
undo_buffer:
    blk.b   40,0                   ; Space for undo buffer

; Global variables
intbase:
    dc.l    0                      ; Intuition base address
windowhd:
    dc.l    0                      ; Window handle

    END