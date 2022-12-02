.global main
main:
    push %rbp
    sub $64, %rsp # buffer       48(%rsp)
    push $0       # read size    40(%rsp)
    push $0       # current food 32(%rsp)
    push $0       # current elf  24(%rsp)
    push $0       # 1st max elf  16(%rsp)
    push $0       # 2nd max elf   8(%rsp)
    push $0       # 3rd max elf    (%rsp)

.read_loop:
    mov $64, %rdx
    lea 48(%rsp), %rsi # buffer
    xor %rdi, %rdi # stdin
    xor %rax, %rax # read
    syscall

    test %rax, %rax
    jz .exit
    mov %rax, 40(%rsp) # read size

    xor %rcx, %rcx
.food_loop:
    cmpb $'\n', 48(%rsp,%rcx) # buffer[%rcx]
    je .next_food

    mov 32(%rsp), %rax # current food
    imul $10, %rax
    mov 48(%rsp,%rcx), %bl # buffer[%rcx]
    and $0xf, %rbx
    add %rbx, %rax
    mov %rax, 32(%rsp) # current food

    jmp .end_elf_loop
.next_food:
    cmpq $0, 32(%rsp) # current food
    jz .next_elf

    mov 32(%rsp), %rax # current food
    movq $0, 32(%rsp) # current food
    add %rax, 24(%rsp) # current elf
    jmp .end_elf_loop

.next_elf:
    mov 24(%rsp), %rax # current elf
    movq $0, 24(%rsp) # current elf

    cmp 16(%rsp), %rax # 1st max elf
    jng .next_elf_2
    xor %rax, 16(%rsp) # 1st max elf
    xor 16(%rsp), %rax # 1st max elf
    xor %rax, 16(%rsp) # 1st max elf

.next_elf_2:
    cmp 8(%rsp), %rax # 2nd max elf
    jng .next_elf_3
    xor %rax, 8(%rsp) # 2nd max elf
    xor 8(%rsp), %rax # 2nd max elf
    xor %rax, 8(%rsp) # 2nd max elf

.next_elf_3:
    cmp (%rsp), %rax # 3rd max elf
    jng .end_elf_loop
    xor %rax, (%rsp) # 3rd max elf
    xor (%rsp), %rax # 3rd max elf
    xor %rax, (%rsp) # 3rd max elf

.end_elf_loop:
    inc %rcx
    cmp 40(%rsp), %rcx # read size
    jne .food_loop

    jmp .read_loop

.exit:
    movq 16(%rsp), %rsi # 1st max elf
    addq 8(%rsp), %rsi # 2nd max elf
    addq (%rsp), %rsi # 3rd max elf
    pushq $0x000a6425
    movq %rsp, %rdi
    movq $0, %rax
    call printf

    add $120, %rsp
    pop %rbp
    xor %rax, %rax
    ret
