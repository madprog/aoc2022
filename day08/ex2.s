.global main
main:
    push %rbp
    mov %rsp, %rbp
    # square size          -1(%rbp)
    # highest scenic score -5(%rbp)
    # matrix               -10005(%rbp)
    sub $10005, %rsp

    xor %bx, %bx # coordinates
    sub $64, %rsp
.read_loop:
    mov $64, %rdx
    mov %rsp, %rsi # buffer
    xor %rdi, %rdi # stdin
    xor %rax, %rax # read
    syscall

    test %rax, %rax
    jz .read_finished

    xor %rcx, %rcx
.copy_loop:
    mov (%rsp, %rcx), %dl
    cmp $'\n', %dl
    je .newline
    sub $'0', %dl
    movzx %bx, %r8
    shr $8, %r8
    imul $100, %r8
    movzx %bl, %r9
    add %r9, %r8
    mov %dl, -10005(%rbp, %r8)
    inc %bl
    jmp .copy_loop_continue
.newline:
    inc %bh
    xor %bl, %bl
.copy_loop_continue:
    inc %rcx
    cmp %rax, %rcx
    jae .read_loop
    jmp .copy_loop

.read_finished:
    add $64, %rsp
    mov %bh, -1(%rbp)

    # rbx: row
    # rcx: column
    # r8: value at (row, column)
    xor %rcx, %rcx
    mov %ecx, -5(%rbp)
.rowcol_loop:
    xor %rbx, %rbx
.tree_loop:
    mov %rcx, %rsi
    mov %rbx, %rdi
    call .get_value_at
    mov %rax, %r8

    xor %r9, %r9   # distance from (row, column)
    xor %r10, %r10 # nb trees north
    dec %r10
    mov %r10, %r11 # nb trees west
    mov %r10, %r12 # nb trees south
    mov %r10, %r13 # nb trees east
.view_loop:
    inc %r9

.view_loop_north:
    test %r10, %r10
    jns .view_loop_west
    mov %rcx, %rsi
    mov %rbx, %rdi
    sub %r9, %rsi
    jl .view_loop_north_oob
    call .get_value_at
    cmp %rax, %r8
    jg .view_loop_west
    mov %r9, %r10
    jmp .view_loop_west
.view_loop_north_oob:
    mov %r9, %r10
    dec %r10

.view_loop_west:
    test %r11, %r11
    jns .view_loop_south
    mov %rcx, %rsi
    mov %rbx, %rdi
    sub %r9, %rdi
    jl .view_loop_west_oob
    call .get_value_at
    cmp %rax, %r8
    jg .view_loop_south
    mov %r9, %r11
    jmp .view_loop_south
.view_loop_west_oob:
    mov %r9, %r11
    dec %r11

.view_loop_south:
    test %r12, %r12
    jns .view_loop_east
    mov %rcx, %rsi
    mov %rbx, %rdi
    add %r9, %rsi
    cmp %sil, -1(%rbp)
    jle .view_loop_south_oob
    call .get_value_at
    cmp %rax, %r8
    jg .view_loop_east
    mov %r9, %r12
    jmp .view_loop_east
.view_loop_south_oob:
    mov %r9, %r12
    dec %r12

.view_loop_east:
    test %r13, %r13
    jns .view_loop_end
    mov %rcx, %rsi
    mov %rbx, %rdi
    add %r9, %rdi
    cmp %dil, -1(%rbp)
    jle .view_loop_east_oob
    call .get_value_at
    cmp %rax, %r8
    jg .view_loop_end
    mov %r9, %r13
    jmp .view_loop_end
.view_loop_east_oob:
    mov %r9, %r13
    dec %r13

.view_loop_end:

    test %r10, %r10
    js .view_loop
    test %r11, %r11
    js .view_loop
    test %r12, %r12
    js .view_loop
    test %r13, %r13
    js .view_loop

    mov %r10, %rax
    imul %r11, %rax
    imul %r12, %rax
    imul %r13, %rax
    cmp -5(%rbp), %eax
    jng .tree_loop_end
    mov %eax, -5(%rbp)

.tree_loop_end:
    inc %rbx
    cmp -1(%rbp), %bl
    jl .tree_loop
    inc %rcx
    cmp -1(%rbp), %cl
    jl .rowcol_loop

    mov -5(%rbp), %esi
    pushq $0x000a6425 # "%d\n"
    movq %rsp, %rdi
    movq $0, %rax
    call printf

    mov %rbp, %rsp
    pop %rbp
    xor %rax, %rax
    ret

.get_value_at:
    # rdi: row
    # rsi: col
    mov %rdi, %rax
    imul $100, %rax
    add %rsi, %rax
    movzxb -10005(%rbp, %rax), %rax
    ret
