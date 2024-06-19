.global _start
.intel_syntax noprefix

.section .data
entry_msg: 
    .asciz "Enter Data\n"
    entry_msg_len = . - entry_msg

input_buffer: 
    .skip 64

int_array:
    .int 0, 0, 0, 0, 0

.section .text
_start:

    // sys_write
    mov rax, 1
    mov rdi, 1
    lea rsi, [entry_msg]
    mov rdx, entry_msg_len
    syscall

    // sys_read
    mov rax, 0
    mov rdi, 0
    mov rsi, input_buffer
    mov rdx, 64
    syscall

    // Convert input to integers and store in int_array
    mov rsi, input_buffer
    mov ecx, 0

.read_loop:
    cmp ecx, 5
    jge .exit_read_loop

    mov eax, [rsi]
    mov [int_array + ecx*4], eax
    add rsi, 4
    inc ecx
    jmp .read_loop

.exit_read_loop:

    // sys_exit
    mov rax, 60
    xor rdi, rdi
    syscall
