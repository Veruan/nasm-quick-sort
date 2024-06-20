section .data
entry_msg db "Enter a number:", 10, 0
entry_msg_len equ $ - entry_msg

input_buffer times 32 db 0

array times 5 dd 0

newline db 10

section .bss
str_buffer resb 12 ; buffer to hold string representation of integers

section .text
global _start

_start:
    mov eax, 4                  ; syscall number for sys_write
    mov ebx, 1                  ; file descriptor (stdout)
    mov ecx, entry_msg          ; pointer to the message
    mov edx, entry_msg_len      ; length of the message
    int 0x80                    ; call kernel

    xor esi, esi                ; loop counter
    xor edi, edi                ; value storage
    jmp read_loop               ; jump to reading

read_loop:
    cmp esi, 5                  ; compare loop counter with 5
    je clean_after_read         ; if counter >= 5, exit loop

    mov eax, 3                  ; syscall number for sys_read
    mov ebx, 0                  ; file descriptor (stdin)
    lea ecx, [input_buffer]     ; address of input buffer is in ecx
    mov edx, 32                 ; number of bytes to read
    int 0x80                    ; call kernel

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
    cmp ebx, 0                  ; if offset is equal 0 we already checked 0th offset - entire string
    je store_int

    imul edi, edi, 10           ; multiply current edi val by 10
    
    dec ebx                     ; dec ebx to get char before \n
    movzx eax, byte [ecx + ebx] ; load next byte into eax
    sub eax, 48                 ; convert ASCII to integer
    add edi, eax                ; add to result

    jmp convert_loop            ; repeat loop

store_int:
    mov eax, esi
    shl eax, 2
    mov [array + eax], edi      ; store the integer in the array
    inc esi
    jmp read_loop               ; repeat read loop

clean_after_read:
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor edi, edi
    xor esi, esi

    ;call quick_sort

    jmp print_array

quick_sort:
    sub esp, 4

print_array:
    xor esi, esi                ; reset loop counter

print_loop:
    cmp esi, 5                  ; compare loop counter with 5
    je exit                     ; if counter >= 5, exit

    ; Load integer from array
    mov eax, [array + esi*4]
    call int_to_string          ; convert integer to string

    ; Print string
    mov eax, 4                  ; syscall number for sys_write
    mov ebx, 1                  ; file descriptor (stdout)
    mov ecx, str_buffer         ; pointer to the string buffer
    mov edx, 12                 ; length of the buffer
    int 0x80                    ; call kernel

    ; Print newline
    mov eax, 4
    mov ebx, 1
    lea ecx, [newline]
    mov edx, 1
    int 0x80

    inc esi
    jmp print_loop              ; repeat loop

int_to_string:
    ; Arguments: eax = integer to convert
    ; Returns: string in str_buffer
    mov edi, str_buffer + 11    ; point to the end of the buffer
    mov byte [edi], 0           ; null terminator

    ; Handle zero explicitly
    test eax, eax
    jnz int_to_string_loop
    mov byte [edi - 1], '0'
    dec edi
    jmp int_to_string_done

int_to_string_loop:
    xor edx, edx
    mov ecx, 10
    div ecx
    add dl, '0'
    dec edi
    mov [edi], dl
    test eax, eax
    jnz int_to_string_loop

int_to_string_done:
    lea ecx, [edi]
    ret

exit:
    mov eax, 1                  ; syscall number for sys_exit
    xor ebx, ebx                ; exit code 0
    int 0x80                    ; call kernel

breakpoint:
    int 3
