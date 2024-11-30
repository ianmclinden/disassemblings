; Prompt for a name, then write "Hello, <NAME>!" to a file

.text

    .global _start ; program starting address
    .p2align 3     ; 2^3 byte alignment

    ; Definitions are from the macOS sdk, and assume that prefix path
    ; e.g. $(xcrun -sdk macosx --show-sdk-path)/

    ; -- Should be mostly universal
    .equ STDIN,  0
    .equ STDOUT, 1
    .equ STDERR, 2

    ; -- usr/include/sys/syscall.h
    .equ SYSexit,  1 ;exit
    .equ SYS_READ,  3 ; read
    .equ SYS_WRITE, 4 ; write
    .equ SYS_OPEN,  5 ; open
    .equ SYS_CLOSE, 6 ; close

    ; -- usr/include/sys/fcntl.h
    ; Access modes
    .equ O_WRONLY, 0x0001      ; open for writing only
    ; Creation flags
    .equ O_CREAT,  0x00000200  ; create if nonexistant
    .equ O_APPEND, 0x00000008  ; set append mode

    ; -- usr/include/sys/_types/_s_ifmt.h
    ; Read, write, execute/search by owner
    .equ S_IRUSR, 0000400 ; R for owner
    .equ S_IWUSR, 0000200 ; W for owner
    ; Read, write, execute/search by group
    .equ S_IRGRP, 0000040 ; R for group
    ; Read, write, execute/search by others
    .equ S_IROTH, 0000004 ; R for other

; Print hello world to a file
_start:

    ; save some space on the stack for the fd
    sub sp, sp, #16                   ; 16 bytes
    ; and sp, sp, #0xfffffffffffffff0   ; 16-byte align the stack pointer

    ; A brief aarch64 syscalls primer
    ;
    ; syscalls use x0-x14 (64-bit) or r0-r7 (generic)
    ;
    ; x0.. hold the arguments to the syscall in order
    ; the rc of the syscall will be placed in x0
    ;
    ; E.g. syscall open (5) has a signature of
    ;   int open(user_addr_t path, int flags, int mode)
    ; so the arguments would be
    ;   x0 = path (adress of path string)
    ;   x1 = flags
    ;   x2 = mode
    ; and the rc will contain the returned fd or error code
    ;
    ; see https://github.com/opensource-apple/xnu/blob/master/bsd/kern/syscalls.master for syscall args
    ;

prompt:
    mov x0, STDOUT                  ; fd
    adrp x1, name_prompt@PAGE       ; buffer ptr
    add x1, x1, name_prompt@PAGEOFF ; (buffer offset)
    mov x2, name_prompt_len         ; nbytes
    mov x16, SYS_WRITE
    svc 0                           ; call the syscall
    cmp x0, 0                       ; rc is in x0
    blt exit                       ; < 0, error

read_name:
    mov x0, STDIN               ; fd
    adrp x1, namebuf@PAGE       ; buf
    add x1, x1, namebuf@PAGEOFF ; offset of buf in data
    mov x2, namebuf_len         ; nbytes
    mov x16, SYS_READ
    svc 0
    cmp x0, 1
    blt exit                   ; -1 or 0 bytes read

open_outfile:
    adrp x0, filename@PAGE                          ; path
    add x0, x0, filename@PAGEOFF                    ; offset of path in data section
    mov x1, (O_WRONLY | O_CREAT | O_APPEND)         ; flags
    mov x2, (S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH) ; mode
    mov x16, SYS_OPEN
    svc 0
    cmp x0, 1                                       ; opened fd is put in x0
    blt exit                                       ; <= 0, no fd or error
    str x0, [sp, #-16]!                             ; store the fd on the stack

write:
    ; fd already in x0
    adrp x1, hello_start@PAGE        ; string to print
    add x1, x1, hello_start@PAGEOFF  ; offset of string in data section
    mov x2, hello_start_len          ; length of our string (literal, can be mov'd directly)
    mov x16, SYS_WRITE
    svc 0
    cmp x0, 0
    blt exit                        ; < 0, error

write_name:
    adrp x1, namebuf@PAGE
    add x1, x1, namebuf@PAGEOFF
    mov x7, #0                   ; a character counter
.len_loop:
    ldr x6, [x1, x7]             ; check the next char
    cmp x6, '\n'
    beq .do_write                ; done when we hit a newline
    cmp x6, 0
    beq .do_write                ; or when we hit a 0
    add x7, x7, #1               ; increment the counter
    b .len_loop
.do_write:
    ldr x0, [sp], #16   ; TODO: There must be a better way to do this without ldr/str
    str x0, [sp, #-16]!
    ; x1 already has the string address
    mov x2, x7          ; nbytes
    mov x16, SYS_WRITE
    svc 0
    cmp x0, 0
    blt exit           ; < 0, error

write_end:
    ldr x0, [sp], #16              ; load/restore fd from the stack
    str x0, [sp, #-16]!
    adrp x1, hello_end@PAGE
    add x1, x1, hello_end@PAGEOFF
    mov x2, hello_end_len
    mov x16, SYS_WRITE
    svc 0
    cmp x0, 0
    blt exit                      ; < 0, error

close:
    ldr x0, [sp], #16   ; load fd from the stack
    mov x16, SYS_CLOSE
    svc 0
    cmp x0, 0
    blt exit           ; < 0, error

    mov x0, #0          ; finally, rc = 0
exit:
    mov x16, SYSexit
    svc 0


.data

.p2align 3 ; 8 byte aligned data
filename:   .asciz  "test.txt"

.p2align 3
name_prompt: .asciz  "Name: "
name_prompt_len = (. - name_prompt) - 1

.p2align 3
hello_start: .asciz  "Hello, "
hello_start_len = (. - hello_start) - 1

.p2align 3
hello_end: .asciz  "!\n"
hello_end_len = (. - hello_end) - 1

.p2align 3
namebuf:    .space 64, 0
namebuf_len = (. - namebuf) - 1