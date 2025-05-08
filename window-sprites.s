; Amiga 68020 code to open an intuition window with gadgets and a hardware sprite
; Program terminates when the close gadget is pressed

; Intuition function offsets
openlib      = -408    ; OpenLibrary function offset
closelibrary = -414    ; CloseLibrary function offset
openwindow   = -204    ; OpenWindow function offset
closewindow  = -72     ; CloseWindow function offset
openscreen   = -198    ; OpenScreen function offset
closescreen  = -66     ; CloseScreen function offset
getmsg       = -372    ; GetMsg function offset

; Graphics library function offsets
getspriteattr = -696   ; GetSpriteAttrs function offset
changesprite  = -690   ; ChangeSprite function offset
movesprite    = -684   ; MoveSprite function offset
freesprite    = -678   ; FreeSprite function offset
getsprite     = -672   ; GetSprite function offset

; System constants
execbase     = 4       ; Exec base address
CUSTOMBASE   = $DFF000 ; Custom chip base address
SPRITE0DATA  = $120    ; Sprite 0 data register offset
SPRITE0POS   = $140    ; Sprite 0 position register offset
SPRITE0CTL   = $142    ; Sprite 0 control register offset

    SECTION code,CODE

start:
    bsr.w    openint      ; Open intuition library
    bsr.w    opengfx      ; Open graphics library
    bsr.w    windopen     ; Open our window with gadgets
    bsr.w    initsprite   ; Initialize our sprite
    
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
    bsr.w    freemysprite         ; Free sprite resources
    bsr.w    windclose             ; Close window
    bsr.w    closegfx              ; Close graphics library
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

; Open Graphics library
opengfx:
    move.l   execbase,a6           ; Exec base address
    lea      gfxname,a1        ; Name of graphics library
    jsr      openlib(a6)           ; Open graphics library
    move.l   d0,gfxbase            ; Save graphics base address
    rts

; Close Graphics library
closegfx:
    move.l   execbase,a6           ; Exec base address
    move.l   gfxbase,a1            ; Graphics base address
    jsr      closelibrary(a6)      ; Close graphics
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

; Initialize sprite
initsprite:
    move.l   gfxbase,a6            ; Graphics base address
    moveq    #0,d0                 ; Request sprite number 0
    jsr      getsprite(a6)         ; Allocate sprite
    move.w   d0,spritenumber       ; Save sprite number
    
    ; Set sprite position
    move.l   gfxbase,a6            ; Graphics base address
    move.w   spritenumber,d0       ; Sprite number
    move.l   windowhd,a0           ; Window handle
    move.l   50(a0),a1             ; Get ViewPort from window
    moveq    #100,d1               ; X position
    moveq    #80,d2                ; Y position
    jsr      movesprite(a6)        ; Position sprite
    
    ; Change sprite data
    move.l   gfxbase,a6            ; Graphics base address
    move.w   spritenumber,d0       ; Sprite number
    move.l   windowhd,a0           ; Window handle
    move.l   50(a0),a1             ; Get ViewPort from window
    lea      sprite_data,a2        ; Sprite data
    jsr      changesprite(a6)      ; Set sprite data
    rts

; Free sprite resources
freemysprite:
    move.l   gfxbase,a6            ; Graphics base address
    move.w   spritenumber,d0       ; Sprite number
    jsr      freesprite(a6)        ; Free sprite
    rts

; *** Data Section ***

    SECTION data,DATA

; Intuition library name
intname:
    dc.b    "intuition.library",0

; Graphics library name
gfxname:
    dc.b    "graphics.library",0
    even    ; Ensure alignment

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
window_title:
    dc.b    "My Intuition Window with Sprite",0
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
    dc.w    2                      ; Gadget ID
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
    dc.w    -2, -2                 ; Start point
    dc.w    200, -2                ; Top right
    dc.w    200, 9                 ; Bottom right
    dc.w    -2, 9                  ; Bottom left
    dc.w    -2, -2                 ; Back to start

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

; Sprite data - 16x16 simple arrow sprite
; Format: Control words, then bitplane data
sprite_data:
    ; Control words for each line (position and control)
    dc.w    $0000, $0000          ; Position/control words
    
    ; Sprite data (16 pixels wide, 16 lines)
    ; First bitplane
    dc.w    %1000000000000000, %0000000000000000  ; Line 0
    dc.w    %1100000000000000, %0000000000000000  ; Line 1
    dc.w    %1110000000000000, %0000000000000000  ; Line 2
    dc.w    %1111000000000000, %0000000000000000  ; Line 3
    dc.w    %1111100000000000, %0000000000000000  ; Line 4
    dc.w    %1111110000000000, %0000000000000000  ; Line 5
    dc.w    %1111111000000000, %0000000000000000  ; Line 6
    dc.w    %1111111100000000, %0000000000000000  ; Line 7
    dc.w    %1111111000000000, %0000000000000000  ; Line 8
    dc.w    %1111110000000000, %0000000000000000  ; Line 9
    dc.w    %1111100000000000, %0000000000000000  ; Line 10
    dc.w    %1111000000000000, %0000000000000000  ; Line 11
    dc.w    %1110000000000000, %0000000000000000  ; Line 12
    dc.w    %1100000000000000, %0000000000000000  ; Line 13
    dc.w    %1000000000000000, %0000000000000000  ; Line 14
    dc.w    %0000000000000000, %0000000000000000  ; Line 15
    
    ; Second bitplane (for color)
    dc.w    %0000000000000000, %0000000000000000  ; Line 0 
    dc.w    %0100000000000000, %0000000000000000  ; Line 1
    dc.w    %0110000000000000, %0000000000000000  ; Line 2
    dc.w    %0111000000000000, %0000000000000000  ; Line 3
    dc.w    %0111100000000000, %0000000000000000  ; Line 4
    dc.w    %0111110000000000, %0000000000000000  ; Line 5
    dc.w    %0111111000000000, %0000000000000000  ; Line 6
    dc.w    %0111111100000000, %0000000000000000  ; Line 7
    dc.w    %0111111000000000, %0000000000000000  ; Line 8
    dc.w    %0111110000000000, %0000000000000000  ; Line 9
    dc.w    %0111100000000000, %0000000000000000  ; Line 10
    dc.w    %0111000000000000, %0000000000000000  ; Line 11
    dc.w    %0110000000000000, %0000000000000000  ; Line 12
    dc.w    %0100000000000000, %0000000000000000  ; Line 13
    dc.w    %0000000000000000, %0000000000000000  ; Line 14
    dc.w    %0000000000000000, %0000000000000000  ; Line 15
    
    ; End marker for sprite data
    dc.w    $0000, $0000          ; End of sprite marker

; Global variables
intbase:
    dc.l    0                      ; Intuition base address
gfxbase:
    dc.l    0                      ; Graphics library base address
windowhd:
    dc.l    0                      ; Window handle
spritenumber:
    dc.w    0                      ; Hardware sprite number allocated

    END