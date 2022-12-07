.global main
main:
    push %rbp
    mov %rsp, %rbp
    # buffer       -4(%rbp)
    sub $14, %rsp

    mov $14, %rdx
    lea -14(%rbp), %rsi # buffer
    xor %rdi, %rdi # stdin
    xor %rax, %rax # read
    syscall

    mov $14, %r8
.read_loop:
    test %rax, %rax
    jz .exit

    mov $14, %rcx
.check_loop:
    mov -15(%rbp, %rcx), %al
    mov %rcx, %rdx
    dec %rdx
    jz .check_loop_not_inner
.check_loop_inner:
    cmp -15(%rbp, %rdx), %al
    je .duplicate

    dec %rdx
    jnz .check_loop_inner
.check_loop_not_inner:
    dec %rcx
    jnz .check_loop
    jmp .exit

.duplicate:
    inc %r8
    lea -13(%rbp), %rsi
    lea -14(%rbp), %rdi
    mov $14, %rcx
    rep movsb

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

    add $22, %rsp
    xor %rax, %rax # return 0
    pop %rbp
    ret
