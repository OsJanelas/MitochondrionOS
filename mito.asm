[bits 16]
[org 0x7c00]

start:
    xor ax, ax
    mov ds, ax
    mov es, ax

shell:
    mov si, msg_boot
    call print_string
.wait_boot:
    mov di, buffer
    call read_line
    mov si, buffer
    mov di, cmd_ok
    call compare_strings
    jne .wait_boot

load_gui:
    mov ax, 0x0013      ; VGA 320x200
    int 0x10
    
    call draw_aurora    ; O papel de parede
    call draw_taskbar
    call draw_folder

gui_loop:
    mov ah, 0
    int 0x16            
    cmp al, 'm'         ; Menu Iniciar
    je .show_menu
    cmp al, 'n'         ; Bloco de Notas
    je .show_notes
    cmp al, 'c'         ; CMD
    je .show_cmd
    cmp al, 'b'         ; 'b' para fechar e voltar ao desktop (Back)
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

; --- DESENHO DO FUNDO (AURORA) ---
draw_aurora:
    mov ax, 0xA000
    mov es, ax
    xor di, di
.loop:
    mov ax, di
    shr ax, 7           ; Cria o gradiente suave
    add al, 32          ; Faixa de cores azuis/verdes
    mov cx, 1
    stosb
    cmp di, 320*182
    jb .loop
    ret

; --- ELEMENTOS DA INTERFACE ---
draw_taskbar:
    mov di, 320*182
    mov al, 7           ; Cinza Win95
    mov cx, 320*18
    rep stosb
    mov dx, 0x1701      ; Texto do botão
    mov ah, 2
    xor bh, bh
    int 0x10
    mov si, btn_start
    call print_string
    ret

draw_folder:
    mov bx, 25
.l: mov ax, 320
    mul bx
    add ax, 25
    mov di, ax
    mov al, 44          ; Amarelo
    mov cx, 15
    rep stosb
    inc bx
    cmp bx, 38
    jne .l
    mov dx, 0x0503
    mov ah, 2
    int 0x10
    mov si, txt_system
    call print_string
    ret

draw_start_menu:
    mov bx, 100
.l: mov ax, 320
    mul bx
    mov di, ax
    mov al, 7
    mov cx, 80
    rep stosb
    inc bx
    cmp bx, 182
    jne .l
    mov dx, 0x0D01
    mov ah, 2
    int 0x10
    mov si, menu_items
    call print_string
    ret

draw_notepad:
    mov bx, 40
.l: mov ax, 320
    mul bx
    add ax, 60
    mov di, ax
    mov al, 15          ; Branco
    mov cx, 200
    rep stosb
    inc bx
    cmp bx, 140
    jne .l
    mov dx, 0x0608
    mov ah, 2
    int 0x10
    mov si, txt_note
    call print_string
    ret

draw_cmd_window:
    mov bx, 50
.l: mov ax, 320
    mul bx
    add ax, 100
    mov di, ax
    mov al, 0           ; Preto
    mov cx, 120
    rep stosb
    inc bx
    cmp bx, 110
    jne .l
    mov dx, 0x070D
    mov ah, 2
    int 0x10
    mov si, txt_cmd
    call print_string
    ret

; --- SISTEMA ---
compare_strings:
.l: mov al, [si]
    mov bl, [di]
    cmp al, bl
    jne .not_eq
    or al, al
    jz .eq
    inc si
    inc di
    jmp .l
.not_eq: ret
.eq: add sp, 2
    jmp load_gui

print_string:
    mov ah, 0x0e
.l: lodsb
    or al, al
    jz .d
    int 0x10
    jmp .l
.d: ret

read_line:
    xor cx, cx
.l: mov ah, 0
    int 0x16
    cmp al, 0x0D
    je .d
    mov ah, 0x0e
    int 0x10
    stosb
    jmp .l
.d: mov al, 0
    stosb
    ret

; --- DADOS ---
msg_boot    db 'Mitochondrion OS', 13, 10, 'Type boot: ', 0
cmd_ok      db 'boot', 0
btn_start   db '[START] (M)', 0
menu_items  db ' Programs', 13, 10, ' Shutdown', 0
txt_system  db 'System (C)', 0
txt_note    db 'Notepad (N)', 0
txt_cmd     db 'C:\>', 0
buffer      times 16 db 0

times 510-($-$$) db 0
dw 0xaa55