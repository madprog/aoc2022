.global main
main:
    push %rbp
    sub $64, %rsp # buffer       32(%rsp)
    push $0       # read size    24(%rsp)
    push $0       # current food 16(%rsp)
    push $0       # current elf   8(%rsp)
    push $0       # max elf        (%rsp)

.read_loop:
    mov $64, %rdx
    lea 32(%rsp), %rsi # buffer
    xor %rdi, %rdi # stdin
    xor %rax, %rax # read
    syscall

    test %rax, %rax
    jz .exit
    mov %rax, 24(%rsp) # read size

    xor %rcx, %rcx
.food_loop:
    cmpb $'\n', 32(%rsp,%rcx) # buffer[%rcx]
    je .next_food

    mov 16(%rsp), %rax # current food
    imul $10, %rax
    mov 32(%rsp,%rcx), %bl # buffer[%rcx]
    and $0xf, %rbx
    add %rbx, %rax
    mov %rax, 16(%rsp) # current food

    jmp .end_elf_loop
.next_food:
    cmpq $0, 16(%rsp)
    jz .next_elf

    mov 16(%rsp), %rax # current food
    movq $0, 16(%rsp) # current food
    add %rax, 8(%rsp) # current elf
    jmp .end_elf_loop

.next_elf:
    mov 8(%rsp), %rax # current elf
    movq $0, 8(%rsp) # current elf
    cmp (%rsp), %rax # max elf
    jng .end_elf_loop
    mov %rax, (%rsp) # max elf

.end_elf_loop:
    inc %rcx
    cmp 24(%rsp), %rcx # read size
    jne .food_loop

    jmp .read_loop

.exit:
    movq (%rsp), %rsi # max elf
    pushq $0x000a6425
    movq %rsp, %rdi
    movq $0, %rax
    call printf

    add $104, %rsp
    pop %rbp
    xor %rax, %rax
    ret
