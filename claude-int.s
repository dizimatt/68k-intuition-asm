; ******************************************************
; Simple Amiga 68020 Window Application with Button
; ******************************************************

        INCLUDE "exec/types.i"
        INCLUDE "exec/memory.i"
        INCLUDE "intuition/intuition.i"
        INCLUDE "graphics/graphics_lib.i"
        INCLUDE "intuition/screens.i"
        INCLUDE "intuition/intuition_lib.i"
        INCLUDE "exec/exec_lib.i"
        INCLUDE "libraries/dos_lib.i"

; Constants for our window
WINDOW_WIDTH    EQU     320
WINDOW_HEIGHT   EQU     150
WINDOW_LEFT     EQU     10
WINDOW_TOP      EQU     10
BUTTON_WIDTH    EQU     120
BUTTON_HEIGHT   EQU     20
execbase        EQU     4
HIRES           EQU     $8000

; ******************************************************
; Program start
; ******************************************************
        SECTION CODE,CODE
start:

        ; Open intuition library
        lea     intuition_name,a1       ; Name of intuition library
        moveq   #0,d0
        CALLEXEC OpenLibrary
        tst.l   d0                      ; Test if library opened successfully
        beq     exit_program            ; If zero (failed), exit
        move.l  d0,_IntuitionBase

        lea     graphics_name,a1       ; Name of intuition library
        moveq   #0,d0
        CALLEXEC OpenLibrary
        tst.l   d0                      ; Test if library opened successfully
        beq     close_intuition            ; If zero (failed), exit
        move.l  d0,_GfxBase

        moveq   #0,d0
        bsr     open_screen
        tst.l   d0                      ; Test if window opened successfully
        beq     close_gfx         ; If zero (failed), close intuition and exit

        moveq   #0,d0
        bsr     open_window
        tst.l   d0                      ; Test if window opened successfully
        beq     close_screen         ; If zero (failed), close intuition and exit

;        bsr     draw_screen_graphics
;        bsr     add_text_items
;        bsr     draw_image

        
        ; Main event loop
event_loop:
        ; Wait for an event (more efficient than continuous polling)
        move.l  window_pointer,a0
        move.l  wd_UserPort(a0),a0
        move.l  execbase,a6
        jsr     _LVOWaitPort(a6)

        ; Get the message
        move.l  window_pointer,a0
        move.l  wd_UserPort(a0),a0
        move.l  execbase,a6
        jsr     _LVOGetMsg(a6)
        tst.l   d0                      ; Check if we got a message
        beq     event_loop              ; If zero (no message), continue waiting
 
        move.l  d0,a0                   ; Message pointer in a0
        move.l  im_Class(a0),d6         ; Get message class
        
        ; Reply to the message
        move.l  execbase,a6
        jsr     _LVOReplyMsg(a6)
        
        ; Check if it was a close window or gadget up message
        cmp.l   #IDCMP_CLOSEWINDOW,d6   ; Window close?
        beq     close_window
                        
        ; Otherwise loop back
        bra     event_loop

open_screen:
        ; Open window with pre-configured gadget
        lea     new_screen,a0
        CALLINT OpenScreen
        move.l  d0,screen_pointer
        rts


open_window:
        ; Open window with pre-configured gadget
        lea     new_window,a0
        move.l  screen_pointer,nw_Screen(a0)
        CALLINT OpenWindow
        move.l  d0,window_pointer
        rts

draw_screen_graphics:
        ; Get screen's RastPort

        move.l  screen_pointer,a0
        move.l  sc_RastPort(a0),a1     ; Save RastPort in a1
        
;        moveq   #1,d0                  ; Blue pen
;        CALLGRAF SetAPen

;        CALLGRAF SetRast       ; Fill entire screen
        
        ; Draw decorative border
;        moveq   #3,d0                  ; Red pen
;        CALLGRAF SetAPen
        
        ; Draw top line
;        moveq   #0,d0
;        moveq   #0,d1
;        CALLGRAF Move
        
;        move.w  #639,d0
;        moveq   #0,d1
;        CALLGRAF Draw
        
        ; Draw bottom line
;        moveq   #0,d0
;        move.w  #199,d1
;        CALLGRAF Move
        
;        move.w  #639,d0
;        move.w  #199,d1
;        CALLGRAF Draw
        
        ; Draw some text on the screen
        moveq   #1,d0                  ; White pen
        CALLGRAF SetAPen
        
        move.l  screen_pointer,a0
        move.l  sc_RastPort(a0),a1     ; Save RastPort in a1
        moveq   #20,d0
        moveq   #20,d1
        CALLGRAF Move
        
        move.l  screen_pointer,a0
        move.l  sc_RastPort(a0),a1     ; Save RastPort in a1
        lea     screen_text,a0
        moveq   #16,d0                 ; Text length
        CALLGRAF Text

        rts


draw_image:

        move.l  _IntuitionBase,a6       ; Intuition base in a6
        move.l  screen_pointer,a0       ; Window pointer in a0
        move.l  sc_RastPort(a0),a0         ; Get RastPort from window
        lea     window_image,a1
        moveq   #10,d0
        moveq   #10,d1
        jsr     _LVODrawImage(a6)      ; Draw the image

        move.l  _IntuitionBase,a6       ; Intuition base in a6
        move.l  window_pointer,a0       ; Window pointer in a0
        move.l  wd_RPort(a0),a0         ; Get RastPort from window
        lea     window_image,a1
        moveq   #10,d0
        moveq   #10,d1
        jsr     _LVODrawImage(a6)      ; Draw the image

        moveq   #20,d0
        moveq   #20,d1
        move.l  _IntuitionBase,a6       ; Intuition base in a6
        move.l  window_pointer,a0       ; Window pointer in a0
        move.l  wd_RPort(a0),a0         ; Get RastPort from window
        lea     window_image,a1
        jsr     _LVODrawImage(a6)      ; Draw the image

        move.l  _IntuitionBase,a6       ; Intuition base in a6
        move.l  window_pointer,a0       ; Window pointer in a0
        move.l  wd_RPort(a0),a0         ; Get RastPort from window
        lea     window_image,a1
        moveq   #30,d0
        moveq   #40,d1
        jsr     _LVODrawImage(a6)      ; Draw the image
        
        rts

add_text_items:
        lea     sample_text,a0
        move.b  #2,(a0)                 ; chanegd the background colour at creationtime

        move.l  _IntuitionBase,a6       ; Intuition base in a6
        move.l  window_pointer,a0       ; Window pointer in a0
        move.l  wd_RPort(a0),a0         ; Get RastPort from window
        lea     sample_text,a1          ; Address of IntuiText structure
        moveq   #40,d0                  ; X position
        moveq   #60,d1                  ; Y position
        jsr     _LVOPrintIText(a6)      ; Print the text
        rts


add_new_gadget:
        ; Prepare to add gadget to window
        move.l  _IntuitionBase,a6      ; Intuition library base
        move.l  window_pointer,a0      ; Window pointer 
        lea     close_button,a1           ; Gadget structure
        ; Pre-position the button in the center of the window
        move.w  #(WINDOW_WIDTH-BUTTON_WIDTH)/2,gg_LeftEdge(a1)
        move.w  #(WINDOW_HEIGHT-BUTTON_HEIGHT)/2,gg_TopEdge(a1)

        moveq   #0,d0                  ; Position (0 = add at the end)
        jsr     _LVOAddGadget(a6)
        
        ; d0 now contains the position where the gadget was added
        ; Optionally store this position if needed

        move.l  _IntuitionBase,a6      ; Intuition library base
        move.l  window_pointer,a0      ; Window pointer 
        jsr _LVORefreshWindowFrame(a6)
        rts

; Handle when our button is clicked
handle_button_click:
        ; We could do different things here based on which button was clicked
        ; For now, just close the window like the close gadget does
        bra     close_window


; *******************
; code jumps to here either at error trapping, or closing window trigger
; *******************
close_window:
        ; Close the window
        move.l  window_pointer,a0
        CALLINT CloseWindow

close_screen:
        ; Close the screen
        move.l  screen_pointer,a0
        CALLINT CloseScreen

close_gfx:
        ; Close intuition library
        move.l  _GfxBase,a1
        CALLEXEC CloseLibrary

close_intuition:
        ; Close intuition library
        move.l  _IntuitionBase,a1
        CALLEXEC CloseLibrary

exit_program:
        ; Clean up stack frame
        moveq   #0,d0
        rts


        
; ******************************************************
; Structures
; ******************************************************
        SECTION DATA,DATA
window_image:
        dc.w    50,50                     ; LeftEdge, TopEdge (relative to drawing position)
        dc.w    16,8                    ; Width, Height in pixels
        dc.w    1                       ; Depth (1 bitplane = 2 colors)
        dc.l    window_image_data       ; Pointer to image data
        dc.b    1,0                     ; PlanePick, PlaneOnOff
        dc.l    0                       ; NextImage

; Image data - 16x8 pixels (2 bytes per row, 8 rows)
window_image_data:
        dc.w    %0111111111111110       ; Row 1
        dc.w    %1000000000000001       ; Row 2
        dc.w    %1000000000000001       ; Row 3
        dc.w    %1000111111000001       ; Row 4
        dc.w    %1000111111000001       ; Row 5
        dc.w    %1000000000000001       ; Row 6
        dc.w    %1000000000000001       ; Row 7
        dc.w    %0111111111111110       ; Row 8

        dc.w    %1111111111111111       ; Row 1
        dc.w    %1000000000000001       ; Row 2
        dc.w    %1000000000000001       ; Row 3
        dc.w    %1000111111000001       ; Row 4
        dc.w    %1000111111000001       ; Row 5
        dc.w    %1000000000000001       ; Row 6
        dc.w    %1000000000000001       ; Row 7
        dc.w    %1111111111111111       ; Row 8

new_screen:
        dc.w    0        ; Horizontal position of screen
        dc.w    0         ; Vertical position of screen
        dc.w    640           ; Width in pixels
        dc.w    256          ; Height in pixels
        dc.w    4           ; Number of bitplanes (1-8)
        dc.b    0       ; Pen number for text/detail
        dc.b    1        ; Pen number for blocks/fill
        dc.w    HIRES|SCREENQUIET    ;SCREENHIRES|SCREENQUIET       ; Special display modes
        dc.w    CUSTOMSCREEN      ; Screen type flags
        dc.l    0            ; Pointer to TextAttr or 0 for default
        dc.l    screen_title    ; Pointer to title text or 0
        dc.l    0         ; Pointer to gadget list or 0
        dc.l    0    ; Pointer to custom bitmap or 0
screen_title: dc.b 'Intuition Screen',0
        even
screen_text:        dc.b    "Screen Graphics!"
        even

new_window:
        dc.w    0             ; LeftEdge
        dc.w    200              ; TopEdge
        dc.w    500            ; Width
        dc.w    50           ; Height
        dc.b    1,3                     ; DetailPen, BlockPen
        dc.l    IDCMP_CLOSEWINDOW|IDCMP_GADGETUP ; IDCMPFlags
        dc.l    WFLG_CLOSEGADGET|WFLG_DRAGBAR|WFLG_ACTIVATE|WFLG_SMART_REFRESH|WFLG_SIZEGADGET ; Flags
        dc.l    0            ; Was FirstGadget (pre-configured)
        dc.l    0                       ; CheckMark
        dc.l    windowtitle              ; Title
        dc.l    0                       ; Screen
        dc.l    0                       ; BitMap
        dc.w    WINDOW_WIDTH            ; MinWidth
        dc.w    WINDOW_HEIGHT           ; MinHeight
        dc.w    WINDOW_WIDTH*2          ; MaxWidth
        dc.w    WINDOW_HEIGHT*2         ; MaxHeight
        dc.w    CUSTOMSCREEN            ; Type

; Window name
windowtitle:   dc.b   'Our Window',0
        even

; Button gadget structure
close_button:
        dc.l    0                       ; NextGadget
        dc.w    0,0                     ; LeftEdge, TopEdge (will be set)
        dc.w    80,8                  ; Width, Height
        dc.w    GFLG_GADGHBOX               ; Flags (complementary highlighting)
        dc.w    GACT_RELVERIFY|GACT_IMMEDIATE ; Activation flags
        dc.w    GTYP_BOOLGADGET|GTYP_SCRGADGET              ; GadgetType (Boolean)
        dc.l    0                       ; GadgetRender
        dc.l    0                       ; SelectRender
        dc.l    button_text             ; GadgetText
        dc.l    0                       ; MutualExclude
        dc.l    0                       ; SpecialInfo
        dc.w    2                       ; GadgetID (unique ID for this gadget)
        dc.l    0                       ; UserData
button_text:
        dc.b    1                       ; FrontPen - Text color (1=white)
        dc.b    0                       ; BackPen - Background color (0=background)
        dc.b    0                       ; DrawMode - JAM1 mode (0)
        dc.b    0                       ; Padding for alignment
        dc.w    0                      ; LeftEdge - relative to output position
        dc.w    0                      ; TopEdge - relative to output position
        dc.l    0                       ; ITextFont - NULL for default font
        dc.l    button_text_string            ; IText - pointer to actual text
        dc.l    0                       ; NextText - NULL (no more text)
button_text_string:        dc.b    "Click ME!",0
        even

sample_text:
        dc.b    1                       ; FrontPen - Text color (1=white)
        dc.b    0                       ; BackPen - Background color (0=background)
        dc.b    0                       ; DrawMode - JAM1 mode (0)
        dc.b    0                       ; Padding for alignment
        dc.w    0                       ; LeftEdge - relative to output position
        dc.w    0                       ; TopEdge - relative to output position
        dc.l    0                       ; ITextFont - NULL for default font
        dc.l    text_string             ; IText - pointer to actual text
        dc.l    sample_text2            ; NextText
text_string:        dc.b    "Hello from Intuition!",0
        even

sample_text2:
        dc.b    1                       ; FrontPen - Text color (1=white)
        dc.b    0                       ; BackPen - Background color (0=background)
        dc.b    0                       ; DrawMode - JAM1 mode (0)
        dc.b    0                       ; Padding for alignment
        dc.w    40                      ; LeftEdge - relative to output position
        dc.w    100                      ; TopEdge - relative to output position
        dc.l    0                       ; ITextFont - NULL for default font
        dc.l    text_string2            ; IText - pointer to actual text
        dc.l    0                       ; NextText - NULL (no more text)
text_string2:        dc.b    "second hello!",0
        even

; ******************************************************
; Data Section
; ******************************************************


_IntuitionBase:     dc.l    0
_GfxBase:           dc.l    0
window_pointer:     dc.l    0
screen_pointer:     dc.l    0
newline:            dc.b    10
                    even

intuition_name:     dc.b    "intuition.library",0
                    even
dos_name:           dc.b    "dos.library",0
                    even
graphics_name:      dc.b    "graphics.library",0
                    even

        END