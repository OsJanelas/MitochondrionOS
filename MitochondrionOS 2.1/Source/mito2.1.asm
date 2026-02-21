[BITS 16]
[ORG 0x7C00]

; =================================================================
; SECTOR: BOOTLOADER
; =================================================================
boot_start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    mov ax, 0x0003
    int 0x10

    mov ah, 0x02    
    mov al, 5
    mov ch, 0       
    mov cl, 2          
    mov dh, 0       
    mov bx, kernel_entry 
    int 0x13
    
    jmp kernel_entry

times 510-($-$$) db 0
dw 0xAA55

; =================================================================
; KERNEL (MitochondrionOS v2.1)
; =================================================================
kernel_entry:
    xor ax, ax
    mov ds, ax
    mov es, ax

    mov si, msg_boot
    call print_string

.wait_input:
    mov di, buffer
    call read_line
    mov si, buffer
    cmp byte [si], 'b'
    jne .wait_input
    cmp byte [si+1], 'o'
    jne .wait_input
    jmp load_gui

load_gui:
    mov ax, 0x0013      
    int 0x10
    call InitMouse
    call EnableMouse
    call draw_full_desktop

gui_loop:
    hlt                 
    
    mov ah, 1
    int 0x16
    jz gui_loop         

    mov ah, 0
    int 0x16            
    cmp al, 'm'
    je .show_menu
    cmp al, 'n'
    je .show_notes
    cmp al, 'c'
    je .show_cmd
    cmp al, 'b'         
    je load_gui
    jmp gui_loop

.show_menu:
    call draw_start_menu
    jmp gui_loop
.show_notes:
    call draw_notepad
    jmp gui_loop
.show_cmd:
    call draw_cmd_window
    jmp gui_loop

MouseCallback:
    push bp
    mov bp, sp
    pusha
    push ds
    push es
    
    xor ax, ax
    mov ds, ax

    mov al, 0
    call DrawCursor

    mov al, [bp + 12]
    mov bl, al
    mov ax, [bp + 10]
    test bl, 0x10
    jz .x_pos
    or ax, 0xFF00
.x_pos: 
    add [MouseX], ax

    mov ax, [bp + 8]
    test bl, 0x20
    jz .y_pos
    or ax, 0xFF00
.y_pos: 
    sub [MouseY], ax

    cmp word [MouseX], 0
    jl .minx
    cmp word [MouseX], 310
    jg .maxx
    jmp .y_clip
.minx: 
    mov word [MouseX], 0
    jmp .y_clip
.maxx: 
    mov word [MouseX], 310
.y_clip:
    cmp word [MouseY], 0
    jl .miny
    cmp word [MouseY], 190
    jg .maxy
    jmp .draw
.miny: 
    mov word [MouseY], 0
    jmp .draw
.maxy: 
    mov word [MouseY], 188

.draw:
    mov al, 15
    call DrawCursor

    pop es
    pop ds
    popa
    pop bp
    retf

; --- DRAW ---
draw_full_desktop:
    mov ax, 0xA000
    mov es, ax
    xor di, di
.l1: 
    mov ax, di
    shr ax, 7
    add al, 32
    stosb
    cmp di, 320*182
    jb .l1
    call draw_taskbar
    ret

draw_taskbar:
    mov ax, 0xA000
    mov es, ax
    mov di, 320*182
    mov al, 7       ; Bar color
    mov cx, 320*18
    rep stosb

    mov dx, 0x1701
    mov ah, 2
    xor bh, bh
    int 0x10
    
    mov si, btn_start
    call print_string_gui
    ret

draw_start_menu:
    mov bx, 100
.l: 
    mov ax, 320
    mul bx
    mov di, ax
    mov al, 8
    mov cx, 80
    call draw_line_gui
    inc bx
    cmp bx, 182
    jne .l
    ret

draw_notepad:
    mov bx, 40
.l: 
    mov ax, 320
    mul bx
    add ax, 60
    mov di, ax
    mov al, 15
    mov cx, 200
    call draw_line_gui
    inc bx
    cmp bx, 140
    jne .l
    ret

draw_cmd_window:
    mov bx, 50
.l: 
    mov ax, 320
    mul bx
    add ax, 100
    mov di, ax
    mov al, 0
    mov cx, 120
    call draw_line_gui
    inc bx
    cmp bx, 110
    jne .l
    ret

draw_line_gui:
    push es
    push ax
    mov ax, 0xA000
    mov es, ax
    pop ax
    rep stosb
    pop es
    ret

; --- MOUSE CORE ---
InitMouse:
    mov ax, 0xC205
    mov bh, 0x03
    int 0x15
    mov ax, 0xC203
    mov bh, 0x03
    int 0x15
    ret

EnableMouse:
    mov ax, 0xC207
    mov bx, MouseCallback
    int 0x15
    mov ax, 0xC200
    mov bh, 0x01
    int 0x15
    ret

DrawCursor:
    pusha
    mov dx, [MouseY]
    mov si, mousebmp
    mov di, 11
    mov bl, al
.loopY:
    lodsb
    mov bh, al
    mov cx, [MouseX]
    mov bp, 8
.loopX:
    test bh, 0x80
    jz .skip
    mov ah, 0x0C
    mov al, bl
    push bx
    xor bx, bx
    int 0x10
    pop bx
.skip:
    inc cx
    shl bh, 1
    dec bp
    jnz .loopX
    inc dx
    dec di
    jnz .loopY
    popa
    ret

; --- UTILS ---
print_string:
    mov ah, 0x0e
.l: 
    lodsb
    or al, al
    jz .d
    int 0x10
    jmp .l
.d: ret

print_string_gui:
    mov ah, 0x0e
    mov bl, 15
.l: 
    lodsb
    or al, al
    jz .d
    int 0x10
    jmp .l
.d: ret

read_line:
    xor cx, cx
.l: 
    mov ah, 0
    int 0x16
    cmp al, 0x0D
    je .d
    mov ah, 0x0e
    int 0x10
    stosb
    jmp .l
.d: 
    mov al, 0
    stosb
    ret

; --- DATA ---
msg_boot  db 'MitochondrionOS v2.1', 13, 10, 'Type boot: ', 0
btn_start db '[M] Menu - [N] Notes - [C] CMD - [B] Clear', 0
MouseX    dw 160
MouseY    dw 100
mousebmp  db 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE, 0xF8, 0xDC, 0x8E, 0x06
buffer    times 16 db 0

times 3072-($-$$) db 0