;; TODO:
;; 1) make entries dynamically sized
;; 2) fix prefixes breaking at 10
;; 3) make empty lines not become entries

global _start

MAX_CHARACTERS_PER_ENTRY equ 256
MAX_ENTRIES equ 10

section .rodata
separator db "-----------------------", 10
separator_length equ $ - separator

too_long_message db "TOO LONG!", 10
too_long_message_length equ $ - too_long_message

section .data
entry_prefix db "1) "
entry_prefix_length equ $ - entry_prefix

section .bss
entries resb MAX_CHARACTERS_PER_ENTRY * MAX_ENTRIES
entry_count resd 1
entry_lengths resd MAX_ENTRIES
discard resb 1

section .text
exit:
        mov eax, 1
        xor ebx, ebx
        int 0x80

crash:
        mov eax, 1
        mov ebx, 1
        int 0x80

print_separator:
        mov eax, 4
        mov ebx, 1
        mov ecx, separator
        mov edx, separator_length
        int 0x80

        ret

print_entries:
        xor esi, esi
        
.loop:
        cmp esi, [entry_count]
        jge .finish

        mov eax, esi
        add al, 49
        mov [entry_prefix], al

        mov eax, 4
        mov ebx, 1
        mov ecx, entry_prefix
        mov edx, entry_prefix_length
        int 0x80

        imul ecx, esi, MAX_CHARACTERS_PER_ENTRY
        lea ecx, [entries + ecx]

        mov edx, [entry_lengths + esi * 4]

        mov eax, 4
        mov ebx, 1
        int 0x80

        inc esi

        jmp .loop
        
.finish:
        call print_separator

        jmp input_loop

_start:
input_loop:
        imul ecx, [entry_count], MAX_CHARACTERS_PER_ENTRY
        lea ecx, [entries + ecx]

        mov eax, 3
        mov ebx, 0
        mov edx, MAX_CHARACTERS_PER_ENTRY
        int 0x80

        ;; check for EOF or error
        test eax, eax
        je exit
        jle crash

        cmp eax, MAX_CHARACTERS_PER_ENTRY
        jne .store

        cmp byte [ecx + eax - 1], 10 ;; is the last character a newline
        je .store

        jmp .too_long

.store:        
        mov esi, [entry_count]
        mov [entry_lengths + esi * 4], eax
        inc dword [entry_count]

        call print_separator

        jmp print_entries

.too_long:
        call print_separator

        mov eax, 4
        mov ebx, 1
        mov ecx, too_long_message
        mov edx, too_long_message_length
        int 0x80

        call print_separator

.drain:
        mov eax, 3
        mov ebx, 0
        mov ecx, discard
        mov edx, 1
        int 0x80

        ;; check for EOF or error, we want exactly 1 byte
        cmp eax, 1
        jne input_loop ;; let the main loop handle it

        cmp byte [discard], 10
        je input_loop

        jmp .drain
