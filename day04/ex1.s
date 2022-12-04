.global main
main:
    push %rbp
    mov %rsp, %rbp
    # buffer       -64(%rbp)
    # read size    -72(%rbp)
    # counter      -80(%rbp)
    # pairs        -88(%rbp)
    sub $88, %rsp

    xor %rax, %rax
    mov %rax, -80(%rbp) # counter
    mov %rax, -88(%rbp) # pairs
.read_loop:
    mov $64, %rdx
    lea -64(%rbp), %rsi # buffer
    xor %rdi, %rdi # stdin
    xor %rax, %rax # read
    syscall

    test %rax, %rax
    jz .exit
    mov %rax, -72(%rbp) # read size

    xor %rcx, %rcx
.pair_loop:
    cmpb $'\n', -64(%rbp, %rcx) # buffer[%rcx]
    jne .read_pair

    mov -86(%rbp), %ax # pairs[0..1]
    mov -88(%rbp), %bx # pairs[2..4]
    movq $0, -88(%rbp) # pairs

    # (ah <= bh and bl <= al) or (bh <= ah and al <= bl)
    cmpb %bh, %ah
    jg .test_or   # jump if ah > bh
    cmpb %al, %bl
    jle .test_ok  # jump if bl <= al
.test_or:
    cmpb %ah, %bh
    jg .next_item # jump if bh > ah
    cmpb %bl, %al
    jg .next_item # jump if al > bl
.test_ok:
    incq -80(%rbp)
    jmp .next_item

.read_pair:
    mov -64(%rbp, %rcx), %ah # buffer[%rcx]
    cmp $'-', %ah
    je .shift_pair
    cmp $',', %ah
    je .shift_pair

    mov -88(%rbp), %al # pairs
    shl $1, %al
    mov %al, %bl
    shl $2, %al
    add %bl, %al
    sub $'0', %ah
    add %ah, %al
    mov %al, -88(%rbp) # pairs
    jmp .next_item

.shift_pair:
    shlq $8, -88(%rbp) # pairs

.next_item:
    inc %rcx

    cmp -72(%rbp), %rcx # read size
    jnb .read_loop
    jmp .pair_loop

.exit:
    movq -80(%rbp), %rsi # counter
    pushq $0x000a6425 # "%d\n"
    movq %rsp, %rdi
    movq $0, %rax
    call printf

    xor %rax, %rax # return 0
    add $96, %rsp
    pop %rbp
    ret
