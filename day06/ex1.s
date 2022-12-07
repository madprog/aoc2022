.global main
main:
    push %rbp
    mov %rsp, %rbp
    # buffer       -4(%rbp)
    sub $4, %rsp

    mov $4, %rdx
    lea -4(%rbp), %rsi # buffer
    xor %rdi, %rdi # stdin
    xor %rax, %rax # read
    syscall

    mov $4, %r8
.read_loop:
    test %rax, %rax
    jz .exit

    mov -3(%rbp), %al
    cmp -4(%rbp), %al
    je .duplicate

    mov -2(%rbp), %al
    cmp -3(%rbp), %al
    je .duplicate
    cmp -4(%rbp), %al
    je .duplicate

    mov -1(%rbp), %al
    cmp -2(%rbp), %al
    je .duplicate
    cmp -3(%rbp), %al
    je .duplicate
    cmp -4(%rbp), %al
    jne .exit
.duplicate:
    inc %r8
    mov -4(%rbp), %eax
    shr $8, %eax
    mov %eax, -4(%rbp)
    mov $1, %rdx
    lea -1(%rbp), %rsi
    xor %rdi, %rdi
    xor %rax, %rax
    syscall
    jmp .read_loop

.exit:
    movq %r8, %rsi # sum
    pushq $0x000a6425 # "%d\n"
    movq %rsp, %rdi
    movq $0, %rax
    call printf

    add $12, %rsp
    xor %rax, %rax # return 0
    pop %rbp
    ret
