.global main
main:
    push %rbp
    mov %rsp, %rbp
    # square size  -1(%rbp)
    # max height N -2(%rbp)
    # max height W -3(%rbp)
    # max height S -4(%rbp)
    # max height E -5(%rbp)
    # matrix       -20005(%rbp)
    sub $20005, %rsp

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
    xor %dh, %dh
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
    mov %dx, -20005(%rbp, %r8, 2)
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

    xor %rcx, %rcx # row/col number
.rowcol_loop:
    mov $-1, %ebx
    mov %ebx, -5(%rbp) # max height N, W, S, E
    xor %rbx, %rbx # tree number in row
.tree_loop:
    #   --> %rcx -->
    #         |
    #       %rbx
    #         |
    #         V
    mov %rbx, %rax
    imul $100, %rax
    add %rcx, %rax
    mov -20005(%rbp, %rax, 2), %dl
    cmp -2(%rbp), %dl
    jle .invisible_from_north
    movb $1, -20004(%rbp, %rax, 2)
    mov %dl, -2(%rbp)
.invisible_from_north:

    #   |
    #   |
    # %rcx --> %rbx -->
    #   |
    #   V
    mov %rcx, %rax
    imul $100, %rax
    add %rbx, %rax
    mov -20005(%rbp, %rax, 2), %dl
    cmp -3(%rbp), %dl
    jle .invisible_from_west
    movb $1, -20004(%rbp, %rax, 2)
    mov %dl, -3(%rbp)
.invisible_from_west:

    #         ^
    #         |
    #       %rbx
    #         |
    #   --> %rcx -->
    movzxb -1(%rbp), %rax
    dec %rax
    sub %rbx, %rax
    imul $100, %rax
    add %rcx, %rax
    mov -20005(%rbp, %rax, 2), %dl
    cmp -4(%rbp), %dl
    jle .invisible_from_south
    movb $1, -20004(%rbp, %rax, 2)
    mov %dl, -4(%rbp)
.invisible_from_south:

    #                |
    #                |
    # <-- %rbx <-- %rcx
    #                |
    #                V
    mov %rcx, %rax
    imul $100, %rax
    movzxb -1(%rbp), %rdx
    add %rdx, %rax
    sub %rbx, %rax
    dec %rax
    mov -20005(%rbp, %rax, 2), %dl
    cmp -5(%rbp), %dl
    jle .invisible_from_east
    movb $1, -20004(%rbp, %rax, 2)
    mov %dl, -5(%rbp)
.invisible_from_east:

    inc %rbx
    cmp -1(%rbp), %bl
    jl .tree_loop
    inc %rcx
    cmp -1(%rbp), %cl
    jl .rowcol_loop

    #movzxb -1(%rbp), %rsi
    #lea -20005(%rbp), %rdi
    #call .print_matrix

    xor %rsi, %rsi # counter
    xor %rcx, %rcx # row/col number
.count_rowcol_loop:
    xor %rbx, %rbx # tree number in row
.count_tree_loop:
    mov %rbx, %rax
    imul $100, %rax
    add %rcx, %rax
    mov -20004(%rbp, %rax, 2), %dl
    test %dl, %dl
    jz .count_next
    inc %rsi
.count_next:
    inc %rbx
    cmp -1(%rbp), %bl
    jl .count_tree_loop
    inc %rcx
    cmp -1(%rbp), %cl
    jl .count_rowcol_loop

    pushq $0x000a6425 # "%d\n"
    movq %rsp, %rdi
    movq $0, %rax
    call printf

    mov %rbp, %rsp
    pop %rbp
    xor %rax, %rax
    ret

.print_matrix:
    # rdi: matrix
    # sil: square size
    push %rax # position in printed string
    push %rbx # read value
    push %rcx # %cl: column, %ch: row
    push %rdx # position in matrix
    push %rsi # square size
    push %rdi # matrix
    push %rbp
    push %r8
    mov %rsp, %rbp
    movzx %sil, %rax
    imul $5, %rax
    inc %rax
    imul %rsi, %rax
    add $4, %rax
    sub %rax, %rsp
    xor %rcx, %rcx
    xor %rax, %rax
.print_matrix_loop:
    mov %ch, %dl
    movzx %dl, %rdx
    imul $100, %rdx
    movzx %cl, %r8
    add %r8, %rdx
    movzxw (%rdi, %rdx, 2), %rbx
    add $'0', %bl
    mov %bl, 4(%rsp, %rax)
    xor %bl, %bl
    shl $8, %ebx
    imul $7, %ebx
    or $0x6d305b1b, %ebx # '\x1b[0m'
    mov %ebx, (%rsp, %rax)
    add $5, %rax
    inc %cl
    cmp %sil, %cl
    jb .print_matrix_loop
    movb $'\n', (%rsp, %rax)
    inc %rax
    xor %cl, %cl
    inc %ch
    mov %ch, %dl
    cmp %sil, %dl
    jb .print_matrix_loop
    mov $0x6d305b1b, %ebx
    mov %ebx, (%rsp, %rax)
    add $4, %rax
    mov %rax, %rdx
    mov %rsp, %rsi # buffer
    mov $1, %rdi # stdin
    mov $1, %rax # write
    syscall
    mov %rbp, %rsp
    pop %r8
    pop %rbp
    pop %rdi
    pop %rsi
    pop %rdx
    pop %rcx
    pop %rbx
    pop %rax
    ret
