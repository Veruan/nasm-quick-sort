.global _start
.intel_syntax noprefix

.section .data
entry_msg: 
    .asciz "Enter a number:\n"
    entry_msg_len = . - entry_msg

input_buffer: 
    .skip 32

int_array:
    .int 0

.section .text
_start:

    //write entry_msg
    mov rax, 1
    mov rdi, 1
    lea rsi, [entry_msg]
    mov rdx, entry_msg_len
    syscall

    //init loop counter
    mov ecx, 0
    jmp .read_loop

.read_loop:
    cmp ecx, 5
    jg .exit

    //sys_read
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 32
    syscall

    mov eax, [rsi]
    mov [int_array + ecx*4], eax
    xor rsi, rsi
    inc ecx
    jmp .read_loop

.exit:
    mov rax, 60
    xor rdi, rdi
    syscall
