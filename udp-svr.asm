.text
    .global _start
    .p2align 3     ; 2^3 byte alignment

    ; -- Should be mostly universal
    .equ STDIN,  0
    .equ STDOUT, 1
    .equ STDERR, 2

    ; -- sys/socket.h
    .equ AF_INET,     2
    .equ SOCK_DGRAM,  2
    ; -- netinet/in.h
    .equ INADDR_ANY,  0x00000000

    .include "syscalls.s"

_start:

socket:
    ; int socket(int domain, int type, int protocol);
    mov x0, AF_INET     ; domain
    mov x1, SOCK_DGRAM  ; type
    mov x2, #0          ; protocol
    mov x16, SYS_SOCKET
    svc 0
    cmp x0, 0
    blt exit
    str x0, [sp, #-16]!  ; store the fd on the stack - 16

bind:
    ; int bind(int socket, sockaddr *address, socklen_t address_len);
    ; sock fd already in x0      ; socket fd
    adrp x1, srv_addr@PAGE       ; name
    add x1, x1, srv_addr@PAGEOFF
    mov x2, srv_addr_len         ; namelen
    mov x16, SYS_BIND
    svc 0
    cmp x0, 0
    bne exit

print_lstn_msg:
    mov x0, STDOUT               ; fd
    adrp x1, lstn_msg@PAGE       ; buffer ptr
    add x1, x1, lstn_msg@PAGEOFF ; (buffer offset)
    mov x2, lstn_msg_len         ; nbytes
    mov x16, SYS_WRITE
    svc 0                        ; call the syscall
    cmp x0, 0                    ; rc is in x0
    blt exit                     ; < 0, error

recv_loop:

recvfrom:
    ; int recvfrom(int s, void *buf, size_t len, int flags, struct sockaddr *from, int *fromlenaddr);
    ldr x0, [sp]                      ; load fd from the stack
    adrp x1, recv_buf@PAGE            ; buffer ptr
    add x1, x1, recv_buf@PAGEOFF      ; (buffer offset)
    mov x2, recv_buf_len              ; len
    mov x3, 0                         ; flags
    adrp x4, cli_addr@PAGE            ; from ptr
    add x4, x4, cli_addr@PAGEOFF
    adrp x5, cli_addr_len@PAGE        ; fromlenaddr ptr
    add x5, x5, cli_addr_len@PAGEOFF
    mov x16, SYS_RECVFROM
    svc 0
    cmp x0, 0
    blt exit       ; < 0, error
    beq recv_loop  ; == 0, shutdown
    str x0, [sp, #-16]!               ; push rx byte count to the stack

print_recv:
    ; print "Received: "
    mov x0, STDOUT               ; fd
    adrp x1, recv_msg@PAGE       ; buffer ptr
    add x1, x1, recv_msg@PAGEOFF ; (buffer offset)
    mov x2, recv_msg_len         ; nbytes
    mov x16, SYS_WRITE
    svc 0
    cmp x0, 0
    blt exit

    ; print message
    mov x0, STDOUT
    adrp x1, recv_buf@PAGE
    add x1, x1, recv_buf@PAGEOFF
    ldr x2, [sp]                 ; load rx byte count from the stack
    mov x16, SYS_WRITE
    svc 0
    cmp x0, 0
    blt exit

sendto:
    ; int sendto(int s, caddr_t buf, size_t len, int flags, caddr_t to, socklen_t tolen);
    ldr x0, [sp, #16]                   ; load fd from the stack
    adrp x1, recv_buf@PAGE              ; buffer ptr
    add x1, x1, recv_buf@PAGEOFF        ; (buffer offset)
    ldr x2, [sp], #16                   ; nbytes - pop rx byte count from the stack
    mov x3, #0                          ; flags
    adrp x4, cli_addr@PAGE              ; to ptr
    add x4, x4, cli_addr@PAGEOFF
    adrp x5, cli_addr_len@PAGE          ; tolen
    ldr x5, [x5,  cli_addr_len@PAGEOFF]
    mov x16, SYS_SENDTO
    svc 0
    cmp x0, 0
    blt exit

    b recv_loop

    mov x0, #0
exit:
    mov x16, SYS_EXIT
    svc 0

.data

.p2align 3
lstn_msg: .asciz  "Listening on 0.0.0.0:8080/udp\n"
lstn_msg_len = (. - lstn_msg) - 1

.p2align 3
recv_msg: .asciz  "Received: "
recv_msg_len = (. - recv_msg) - 1

; struct sockaddr_in {
;     short            sin_family;   // e.g. AF_INET
;     unsigned short   sin_port;     // e.g. htons(8080)
;     struct in_addr   sin_addr;     // see struct in_addr, below
;     char             sin_zero[8];  // zero this if you want to
; };
; struct in_addr {
;     unsigned long s_addr;          // load with inet_aton()
; };
.p2align 3
srv_addr:
    srv_addr.sin_family: .short    AF_INET
    srv_addr.sin_port:   .short    0x901f ; htons(8080)
    srv_addr.in_addr:    .long     INADDR_ANY
    srv_addr.sin_zero:   .space 8, 0
srv_addr_len = (. - srv_addr)
cli_addr:
    cli_addr.sin_family: .short
    cli_addr.sin_port:   .short
    cli_addr.in_addr:    .long
    cli_addr.sin_zero:   .space 8, 0
cli_addr_len:            .space 4, (. - cli_addr)

.p2align 3
recv_buf:    .space 128, 0
recv_buf_len = (. - recv_buf)