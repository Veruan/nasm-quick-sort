section .data
entry_msg db "Enter a number:", 10, 0
entry_msg_len equ $ - entry_msg

input_buffer times 32 db 0

array times 5 dd 0

section .bss

section .text
global _start

_start:
    ; Write entry message
    mov eax, 4                  ; syscall number for sys_write
    mov ebx, 1                  ; file descriptor (stdout)
    mov ecx, entry_msg          ; pointer to the message
    mov edx, entry_msg_len      ; length of the message
    int 0x80                    ; call kernel

    ; Initialize loop counter
    xor esi, esi                ; loop counter
    jmp read_loop               ; jump to reading

read_loop:
    cmp esi, 5                  ; compare loop counter with 5
    jge exit                    ; if counter >= 5, exit

    ; Read input
    mov eax, 3                  ; syscall number for sys_read
    mov ebx, 0                  ; file descriptor (stdin)
    mov ecx, input_buffer       ; pointer to the input buffer
    mov edx, 32                 ; number of bytes to read
    int 0x80                    ; call kernel

    ; Strip newline character
    xor edi, edi                ; clear edi (will hold the converted integer)
    xor ebx, ebx                ; clear ebx (index for buffer)
    xor eax, eax                ; clear eax (help register)
    jmp strip_newline           ; jump to stripping \n

strip_newline:
    cmp byte [ecx + ebx], 10    ; if char is \n we convert the number to int
    je convert_loop 
    
    inc ebx
    jmp strip_newline           ; else - we loop

convert_loop:
    cmp ebx, -1
    je store_int

    imul edi, edi, 10           ; multiply current edi val by 10
    dec ebx                     ; dec ebx to get char before \n
    movzx eax, byte [ecx + ebx] ; load next byte into eax
    sub eax, '0'                ; convert ASCII to integer
    add edi, eax                ; multiply current result by 10

    jmp convert_loop            ; repeat loop

store_int:
    mov eax, esi
    shl eax, 2
    mov [array + eax], edi    ; store the integer in the array
    inc esi
    jmp read_loop               ; repeat read loop

exit:
    mov eax, 1                  ; syscall number for sys_exit
    xor ebx, ebx                ; exit code 0
    int 0x80                    ; call kernel
