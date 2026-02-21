[BITS 16]
[ORG 0x7C00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

shell:
    mov si, msg_boot
    call print
.wb: 
    mov di, buffer
    call read_line
    mov si, buffer
    mov di, cmd_ok
    call compare
    jne .wb

load_gui:
    mov ax, 0x0013
    int 0x10
    call InitMouse
    call EnableMouse
    call draw_bg
    call draw_ui

gui_loop:
    hlt
    mov ah, 1
    int 0x16
    jz gui_loop
    mov ah, 0
    int 0x16            
    cmp al, 'b'
    je load_gui
    jmp gui_loop

; --- MOUSE DRIVER ---
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

MouseCallback:
    push bp
    mov bp, sp
    pusha
    push ds
    push es
    xor ax, ax
    mov ds, ax
    call HideCursor
    mov al, [bp+12]
    mov bl, al
    mov ax, [bp+10]
    test bl, 0x10
    jz .x
    or ax, 0xFF00
.x: add [mX], ax
    mov ax, [bp+8]
    test bl, 0x20
    jz .y
    or ax, 0xFF00
.y: sub [mY], ax
    mov al, 0x0F
    call DrawCursor
    pop es
    pop ds
    popa
    pop bp
    retf

DrawCursor:
    pusha
    mov dx, [mY]
    mov si, mousebmp
    mov di, 11
.lY: 
    lodsb
    mov bl, al
    mov cx, [mX]
    mov bp, 8
.lX: 
    test bl, 0x80
    jz .s
    mov ah, 0x0C
    mov al, 0x0F ; White cursor
    int 0x10
.s: 
    inc cx
    shl bl, 1
    dec bp
    jnz .lX
    inc dx
    dec di
    jnz .lY
    popa
    ret

HideCursor:
    pusha
    mov dx, [mY]
    mov si, mousebmp
    mov di, 11
.lY: 
    lodsb
    mov bl, al
    mov cx, [mX]
    mov bp, 8
.lX: 
    test bl, 0x80
    jz .s
    mov ah, 0x0C
    mov al, 0x00 ; Black to clear
    int 0x10
.s: 
    inc cx
    shl bl, 1
    dec bp
    jnz .lX
    inc dx
    dec di
    jnz .lY
    popa
    ret

; --- GRAPHICS ---
draw_bg:
    mov ax, 0xA000
    mov es, ax
    xor di, di
.l: 
    mov ax, di
    shr ax, 7
    add al, 32
    stosb
    cmp di, 320*182
    jb .l
    ret

draw_ui:
    mov di, 320*182
    mov al, 7
    mov cx, 320*18
    rep stosb
    ret

; --- SYSTEM UTILS ---
compare:
.l: 
    lodsb
    scasb
    jne .n
    or al, al
    jnz .l
    add sp, 2
    jmp load_gui
.n: 
    ret

print:
    mov ah, 0x0e
.l: 
    lodsb
    or al, al
    jz .d
    int 0x10
    jmp .l
.d: 
    ret

read_line:
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

; --- DATA SECTION ---
msg_boot db 'MitochondrionOS', 13, 10, 'Type boot: ', 0
cmd_ok   db 'boot', 0
mX       dw 160
mY       dw 100
mousebmp db 0x80, 0xC0, 0xE0, 0xF0, 0xF8, 0xFC, 0xFE, 0xF8, 0xDC, 0x8E, 0x06
buffer   times 16 db 0

times 510-($-$$) db 0
dw 0xAA55