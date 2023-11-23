section .data
    message db "Type in exactly 5 characters", 10
    message_len equ $-message

    right_happy db "          (> ^_^)>          "
    right_happy_len equ 18

    left_happy db "         _<(^_^ <)          "
    left_happy_len equ 18

    trash db "🗑️"
    trash_len equ $-trash

    input_buff db 5 dup(0)
    input_buff_len equ 5

    clear_screen_text db `\033[H\033[2J`, 10
    clear_screen_text_len equ $-clear_screen_text

    timespec:
        ; sleep for 500 ms
        tv_sec dq 0
        tv_nsec dq 500000000


section .text
    global _start

print_push:
    mov rax, 1                                  ; sys_write
    mov rdi, 1                                  ; fd
    syscall
    ret

pause_clear:
    ; sleep for 700ms
    mov rax, 35                                 ; sys_nanosleep
    mov rdi, timespec                           ; struct timespec
    mov rsi, 0                                  ; timespec
    syscall

    ; clear terminal
    mov rsi, clear_screen_text                  ; buff
    mov rdx, clear_screen_text_len              ; buff_len
    call print_push
    ret

print_right_happy:
    ; arguments
    ; r10:   left_spacing
    mov rdx, 10                                 ; initial_pos
    sub rdx, r10

    lea rsi, [right_happy + rdx]                ; buff
    mov rdx, right_happy_len                    ; buff_len
    call print_push
    ret

print_left_happy:
    ; arguments
    ; r10:   a letter
    ; r11:   left_spacing

    lea rsi, left_happy
    mov byte [rsi + 9], r10b                    ; set eating character
    add rsi, r11                                ; buff

    mov rdx, left_happy_len                     ; buff_len
    call print_push
    ret

right_iter:
    ; initial arguments
    ; r15:  0
    ; arguments
    ; [unmodifiable] rbx:   char index
    ; [unmodifiable] r12:   input_buff_len

    call pause_clear

    ; print trash can
    mov rsi, trash
    mov rdx, trash_len
    call print_push

    ; print happy
    mov r10, r15
    call print_right_happy

    ; print text
    lea rsi, [input_buff + rbx]
    mov rdx, r12
    sub rdx, rbx
    call print_push

    ; breaking
    inc r15
    cmp r15, 10
    jne right_iter
    ret

left_iter:
    ; initial arguments
    ; r15: 0
    ; arguments
    ; [unmodifiable] r14:   a letter
    ; [unmodifiable] rbx:   char index
    ; [unmodifiable] r12:   input_buff_len

    call pause_clear

    ; print trash_can
    mov rsi, trash
    mov rdx, trash_len
    call print_push

    ; print happy
    mov r11, r15                                ; index
    mov r10, r14                 ; input_char
    call print_left_happy

    ; print text

    lea rsi, [input_buff + rbx]
    mov rdx, r12
    sub rdx, rbx
    call print_push

    ; breaking
    inc r15
    cmp r15, 11
    jne left_iter
    ret

char_iter:
    ; initial arguments
    ; rbx: 0
    ; arguments

    ; init arg
    mov r15, 0
    call right_iter

    ; init arg
    mov r14, [input_buff + rbx]
    mov r15, 0

    ; 1 char is being eaten
    inc rbx
    call left_iter

    ; breaking
    cmp rbx, r12
    jne char_iter
    ret

_start:
    ; mov r10, 10
    ; call print_right_happy

    ; mov r10, 'B'
    ; mov r11, 10
    ; call print_left_happy

    ; write message
    mov rax, 1                                  ; sys_write
    mov rdi, 1                                  ; fd
    mov rsi, message                            ; input_buff
    mov rdx, message_len                        ; input_buff_len
    syscall

    ; read user text
    mov rax, 0                                  ; sys_read
    mov rdi, 1                                  ; fd
    mov rsi, input_buff                         ; input_buff
    mov rdx, input_buff_len                     ; input_buff_len
    syscall

    ; init arguments
    mov r12, input_buff_len
    mov rbx, 0
    call char_iter

    ; exit
    mov rax, 60                                 ; sys_exit
    mov rdi, 0                                  ; exit_code
    syscall