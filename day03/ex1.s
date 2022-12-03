.global main
main:
    push %rbp
    mov %rsp, %rbp
    # buffer       -64(%rbp)
    # read size    -72(%rbp)
    # sum          -80(%rbp)
    # rucksack    -128(%rbp)
    # ruckcounter -136(%rbp)
    # ruckbitmap1 -144(%rbp)
    sub $144, %rsp

    xor %rbx, %rbx
    mov %rbx, -80(%rbp) # sum
    mov %rbx, -136(%rbp) # ruckcounter
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
.rucksack_loop:
    cmpb $'\n', -64(%rbp, %rcx) # buffer[%rcx]
    jne .copy_item

    # ruckcounter is twice the size of a compartment
    mov -136(%rbp), %rsi
    shr $1, %rsi
    jo .odd_rucksack

    lea -128(%rbp), %rdi # rucksack
    call .compartment_to_bitmap
    mov %rax, -144(%rbp) # ruckbitmap1

    lea -128(%rbp, %rsi), %rdi # rucksack + ruckcounter/2
    call .compartment_to_bitmap

    mov %rax, %rdi
    and -144(%rbp), %rdi # ruckbitmap1 & ruckbitmap2
    call .bitmap_to_priority
    add %rax, -80(%rbp) # sum

    # reset variables for next rucksack
    xor %rbx, %rbx
    mov %rbx, -136(%rbp) # ruckcounter
    mov %rbx, -144(%rbp) # ruckbitmap1
    mov %rbx, -152(%rbp) # ruckbitmap2
    jmp .next_item

.copy_item:
    mov -136(%rbp), %rbx # ruckcounter
    mov -64(%rbp, %rcx), %al # buffer[%rcx]
    mov %al, -128(%rbp, %rbx) # rucksack[%rbx]
    incq -136(%rbp) # ruckcounter
.next_item:
    inc %rcx

    cmp -72(%rbp), %rcx # read size
    jnb .read_loop
    jmp .rucksack_loop

.odd_rucksack:
    mov $-1, %rax # return -1
    jmp .just_exit

.exit:
    movq -80(%rbp), %rsi # sum
    pushq $0x000a6425 # "%d\n"
    movq %rsp, %rdi
    movq $0, %rax
    call printf

    pop %rax # pushed string remains on stack
    xor %rax, %rax # return 0
.just_exit:
    add $144, %rsp
    pop %rbp
    ret

.compartment_to_bitmap:
    # rdi: compartment
    # rsi: length
    # -> rax: bitmap
    push %rbx
    push %rdx

    xor %rax, %rax
    mov %rsi, %rbx
.c2b_loop:
    xor %rdx, %rdx
    mov -1(%rdi, %rbx), %dl
    sub $'a', %dl
    jns .c2b_else
    add $'a'-'A'+26, %dl
.c2b_else:
    inc %dl
    push %rdi
    push %rax
    mov %rdx, %rdi
    call .priority_to_bitmap
    or %rax, (%rsp)
    pop %rax
    pop %rdi

    dec %rbx
    jnz .c2b_loop

    pop %rdx
    pop %rbx
    ret

.bitmap_to_priority:
    # rdi: bitmap
    # -> rax: priority
    push %rdi
    finit
    fld1
    fildq (%rsp)
    fyl2x
    fistpq (%rsp)
    pop %rax
    ret

.priority_to_bitmap:
    # rdi: priority
    # -> rax: bitmap
    push %rcx
    mov %rdi, %rcx
    xor %rax, %rax
    inc %rax
    shl %cl, %rax
    pop %rcx
    ret
