; ******************************************************
; Simple Amiga 68020 Window Application with Button
; ******************************************************

        INCLUDE "exec/types.i"
        INCLUDE "exec/memory.i"
        INCLUDE "intuition/intuition.i"
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

; ******************************************************
; Program start
; ******************************************************

start:
        ; Open intuition library
        move.l  execbase,a6
        lea     intuition_name,a1       ; Name of intuition library
        moveq   #0,d0
        jsr     _LVOOpenLibrary(a6)
        tst.l   d0                     ; Test if library opened successfully
        beq     exit_program           ; If zero (failed), exit
        move.l  d0,intuition_base

        ; Open window
        move.l  intuition_base,a6
        lea     new_window,a0
        jsr     _LVOOpenWindow(a6)
        tst.l   d0                     ; Test if window opened successfully
        beq     close_intuition         ; If zero (failed), close intuition and exit
        move.l  d0,window_pointer
        
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
        
        cmp.l   #IDCMP_GADGETUP,d6      ; Gadget up?
        beq     close_window
                
        ; Otherwise loop back
        bra     event_loop

close_window:
        ; Close the window
        move.l  intuition_base,a6
        move.l  window_pointer,a0
        jsr     _LVOCloseWindow(a6)

close_intuition:
        ; Close intuition library
        move.l  execbase,a6
        move.l  intuition_base,a1
        jsr     _LVOCloseLibrary(a6)

exit_program:
        ; Clean up stack frame
        moveq   #0,d0
        rts

; ******************************************************
; Structures
; ******************************************************

new_window:
        dc.w    WINDOW_LEFT             ; LeftEdge
        dc.w    WINDOW_TOP              ; TopEdge
        dc.w    WINDOW_WIDTH            ; Width
        dc.w    WINDOW_HEIGHT           ; Height
        dc.b    1,3                     ; DetailPen, BlockPen
        dc.l    IDCMP_CLOSEWINDOW|IDCMP_GADGETUP ; IDCMPFlags
        dc.l    WFLG_CLOSEGADGET|WFLG_DRAGBAR|WFLG_DEPTHGADGET|WFLG_ACTIVATE|WFLG_SIZEGADGET|WFLG_REFRESHBITS ; Flags
        dc.l    close_button                       ; FirstGadget (will be added later)
        dc.l    0                       ; CheckMark
        dc.l    windowname              ; Title
        dc.l    0                       ; Screen
        dc.l    0                       ; BitMap
        dc.w    WINDOW_WIDTH            ; MinWidth
        dc.w    WINDOW_HEIGHT           ; MinHeight
        dc.w    WINDOW_WIDTH*2          ; MaxWidth
        dc.w    WINDOW_HEIGHT*2         ; MaxHeight
        dc.w    WBENCHSCREEN            ; Type

;and here comes the window name:
windowname:   dc.b   'Our Window',0
        even

windowtitle2:   dc.b   'Our Upated Window',0
        even

close_button:
        dc.l    0                       ; NextGadget
        dc.w    10                       ; LeftEdge (will be set)
        dc.w    10                       ; TopEdge (will be set)
        dc.w    BUTTON_WIDTH            ; Width
        dc.w    BUTTON_HEIGHT           ; Height
        dc.w    GADGHCOMP               ; Flags (complementary highlighting)
        dc.w    RELVERIFY|GADGIMMEDIATE ; Activation (verify when releasing mouse button)
        dc.w    BOOLGADGET              ; GadgetType (BOOLGADGET)
        dc.l    0                       ; GadgetRender
        dc.l    0                       ; SelectRender
        dc.l    button_text             ; GadgetText
        dc.l    0                       ; MutualExclude
        dc.l    0                       ; SpecialInfo
        dc.w    1                       ; GadgetID
        dc.l    0                       ; UserData

; ******************************************************
; Data Section
; ******************************************************

intuition_name:     dc.b    "intuition.library",0
                    even
graphics_name:      dc.b    "graphics.library",0
                    even
button_text:        dc.b    "Close Window",0
                    even

intuition_base:     dc.l    0
graphics_base:      dc.l    0
window_pointer:     dc.l    0

        END