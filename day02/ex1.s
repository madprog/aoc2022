.global main
main:
    push %rbp
    push $0       # score    8(%rsp)
    push $0       # buffer    (%rsp)

.read_loop:
    # read a line from stdin (4 bytes)
    mov $4, %rdx
    lea (%rsp), %rsi # buffer
    xor %rdi, %rdi # stdin
    xor %rax, %rax # read
    syscall

    cmp $4, %rax
    jb .exit

    xor %rax, %rax
    mov (%rsp), %al
    sub $'A', %al
    rol $2, %al
    add 2(%rsp), %al
    sub $'X', %al

    lea .table(%rip), %rsi
    mov (%rsi, %rax), %al
    add %eax, 8(%rsp)

    jmp .read_loop

.exit:
    movq 8(%rsp), %rsi # score
    pushq $0x000a6425
    movq %rsp, %rdi
    movq $0, %rax
    call printf

    add $24, %rsp
    pop %rbp
    xor %rax, %rax
    ret

.table:
    .byte 4 # 0000  A X   rock     rock     => draw 3 + 1
    .byte 8 # 0001  A Y   rock     paper    => win  6 + 2
    .byte 3 # 0010  A Z   rock     scissors => lose 0 + 3
    .byte 0 # 0011
    .byte 1 # 0100  B X   paper    rock     => lose 0 + 1
    .byte 5 # 0101  B Y   paper    paper    => draw 3 + 2
    .byte 9 # 0110  B Z   paper    scissors => win  6 + 3
    .byte 0 # 0111
    .byte 7 # 1000  C X   scissors rock     => win  6 + 1
    .byte 2 # 1001  C Y   scissors paper    => lose 0 + 2
    .byte 6 # 1010  C Z   scissors scissors => draw 3 + 3
