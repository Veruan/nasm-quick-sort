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
    je convert_loop_start 
    
    inc ebx
    jmp strip_newline           ; else - we loop


convert_loop_start:
    mov edx, ebx                ; \n index
    xor ebx, ebx

    jmp convert_loop


convert_loop:
    cmp ebx, edx                ; if offset is equal max num
    je store_int

    imul edi, edi, 10           ; multiply current edi val by 10
    
    movzx eax, byte [ecx + ebx] ; load next byte into eax
    sub eax, 48                 ; convert ASCII to integer
    add edi, eax                ; add to result
    
    inc ebx
    jmp convert_loop            ; repeat loop


store_int:
    mov eax, esi                ; esi holds array offset
    shl eax, 2                  ; multiply by 4 cuz 4 bytes
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

    lea eax, [array]            ; eax holds array address
    push dword 4                ; push right index
    push dword 0                ; push left index
    push eax                    ; push array
    call quick_sort
    add esp, 12

    jmp print_array


print_array:
    xor esi, esi                ; reset loop counter

    mov eax, 4                  
    mov ebx, 1
    lea ecx, [newline]          ; print newline 
    mov edx, 1
    int 0x80

print_loop:
    cmp esi, 5                  ; print 5 chars
    je exit

    mov eax, [array + esi*4]    ; move int from array into eax

    call int_to_string          ; convert integer to string

    mov eax, 4                  ; syscall number for sys_write
    mov ebx, 1                  ; file descriptor (stdout)
    lea ecx, [str_buffer]       ; pointer to the string buffer
    mov edx, 12                 ; length of the buffer
    int 0x80                    ; call kernel

    mov eax, 4                  
    mov ebx, 1
    lea ecx, [newline]          ; print newline after character
    mov edx, 1
    int 0x80

    call clean_buffer           ; to clean after larger numbers before e.g. 10, 2 -> without it output is 10, 12

    inc esi
    jmp print_loop              ; repeat loop


int_to_string:
    ; Arguments: eax = integer to convert
    ; Returns: string in str_buffer
    mov ebx, 11                 ; buffer offset
    lea edi, [str_buffer]
    mov byte [edi + ebx], 0     ; null terminator

    dec ebx 

    jmp int_to_string_loop


int_to_string_loop:
    cmp ebx, 0
    je int_to_string_done

    xor edx, edx
    mov ecx, 10
    div ecx                     ; now eax = eax / 10, edx = eax % 10 -> dl also holds it

    add dl, 48                  ; convert to ASCII
    mov byte [edi + ebx], dl

    dec ebx

    cmp eax, 0                  ; if eax is 0 that means we already went through all of the numbers
    je int_to_string_done

    jmp int_to_string_loop
    

int_to_string_done:
    lea ecx, [edi]
    ret


clean_buffer:
    xor ebx, ebx
    lea ecx, [str_buffer]
    jmp clean_buffer_loop


clean_buffer_loop:
    cmp ebx, 11
    je clean_buffer_done

    mov byte [ecx + ebx], 0
    
    inc ebx
    jmp clean_buffer_loop


clean_buffer_done:
    ret


exit:
    mov eax, 1                  ; syscall number for sys_exit
    xor ebx, ebx                ; exit code 0
    int 0x80                    ; call kernel

breakpoint:
    int 3


quick_sort:
;local variable q
    push ebp
    mov ebp, esp
    sub esp, 4

    mov eax, [ebp + 16]         ; r (right index) + 12 cuz array and l + 4 cuz return address smh
    mov ecx, [ebp + 12]         ; l (left index)
    cmp ecx, eax                ; if l >= r
    jge .done                   ; return

    push eax                    ; push r
    push ecx                    ; push l
    push dword [ebp + 8]        ; push array pointer

    call partition              ; edi holds q
    
    push dword [ebp + 12]       ; push l
    push edi                    ; push q
    push dword [ebp + 8]        ; push array pointer
    call quick_sort

    inc edi
    push edi                    ; push q + 1
    push dword [ebp + 16]       ; push r
    push dword [ebp + 8]        ; push array pointer
    call quick_sort

    jmp .done

.done:
    mov esp, ebp
    pop ebp
    ret

partition:
;local variable pivot and tmp
    push ebp
    mov ebp, esp
    sub esp, 8

    mov eax, [ebp + 16]         ; r (right index)
    mov ecx, [ebp + 12]         ; l (left index)
    mov ebx, [ebp + 8]          ; array

    mov edx, [ebx + 4*ecx]      ; pivot = A[l]

    jmp .partition_loop

.partition_loop:
    jmp .find_left

.find_left:
    cmp [ebx + 4*ecx], edx      ; A[l] < pivot
    jge .left_found

    inc ecx                     ; l++
    jmp .find_left

.left_found:
    jmp .find_right

.find_right:
    cmp [ebx + 4*eax], edx      ; A[r] > pivot
    jle .right_found

    dec eax                     ; r++
    jmp .find_right

.right_found:
    jmp .test_lr

.test_lr:
    cmp ecx, eax               ; l < r
    jl .swap

    jmp .ret_r

.swap:
    mov esi, [ebx + 4*eax]    ; tmp = A[r]
    mov edi, [ebx + 4*ecx]
    mov [ebx + 4*eax], edi    ; A[r] = A[l]
    mov [ebx + 4*ecx], esi    ; A[l] = tmp 

    inc ecx                   ; l++
    dec eax                   ; r--
    
    jmp .partition_loop

.ret_r:
    mov edi, eax

    mov esp, ebp
    pop ebp
    ret
