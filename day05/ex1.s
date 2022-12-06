.global main
main:
    push %rbp
    mov %rsp, %rbp
    # buffer       -64(%rbp)
    # read size    -72(%rbp)
    # step         -80(%rbp)
    # ptr[9]       -152(%rbp)
    sub $152, %rsp

    xor %rax, %rax
    mov %rsp, %rdi
    mov $19, %rcx
    rep stosq
    xor %r8, %r8
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
.process_loop:
    cmpq $1, -80(%rbp) # step
    je .process_move_order

    cmpb $'\n', -64(%rbp, %rcx)
    je .process_end_of_stacks

    cmpb $' ', -64(%rbp, %rcx)
    je .next_initial_item

    movzxb -63(%rbp, %rcx), %rax
    push %rax
    push $0
    lea -152(%rbp, %r8, 8), %rbx
.process_loop_search_top_stack:
    cmpb $0, (%rbx)
    je .process_loop_found_top_stack
    mov (%rbx), %rbx
    jmp .process_loop_search_top_stack
.process_loop_found_top_stack:
    mov %rsp, (%rbx)

.next_initial_item:
    add $3, %rcx
    inc %r8
    cmpb $'\n', -64(%rbp, %rcx)
    jne .next_item
    xor %r8, %r8
    jmp .next_item

.process_end_of_stacks:
    incq -80(%rbp)
    #call .print_stacks
.reset_move_info:
    xor %r12, %r12
    xor %r8, %r8
    xor %r9, %r9
    xor %r10, %r10
    jmp .next_item

.process_move_order:
    cmp $5, %r12
    jl .skip_text
    je .read_nb_moved

    cmp $11, %r12
    jl .skip_text
    je .read_move_from

    cmp $15, %r12
    jl .skip_text
    je .read_move_to

    jmp .exit

.read_nb_moved:
    cmpb $' ', -64(%rbp, %rcx)
    je .skip_text
    movzxb -64(%rbp, %rcx), %rax
    sub $'0', %rax
    shl $1, %r8
    add %r8, %rax
    shl $2, %r8
    add %rax, %r8
    jmp .next_item

.read_move_from:
    cmpb $' ', -64(%rbp, %rcx)
    je .skip_text
    movzxb -64(%rbp, %rcx), %rax
    sub $'0', %rax
    shl $1, %r9
    add %r9, %rax
    shl $2, %r9
    add %rax, %r9
    jmp .next_item

.read_move_to:
    cmpb $'\n', -64(%rbp, %rcx)
    je .process_move
    movzxb -64(%rbp, %rcx), %rax
    sub $'0', %rax
    shl $1, %r10
    add %r10, %rax
    shl $2, %r10
    add %rax, %r10
    jmp .next_item

.process_move:
    lea -152-8(%rbp, %r9, 8), %rdi
    lea -152-8(%rbp, %r10, 8), %rsi
    call .insert
    dec %r8
    jnz .process_move
    #call .print_stacks
    jmp .reset_move_info

.skip_text:
    inc %r12

.next_item:
    inc %rcx

    cmp -72(%rbp), %rcx # read size
    jnb .read_loop
    jmp .process_loop

.exit:
    xor %rcx, %rcx
.exit_next_char:
    mov -152(%rbp, %rcx, 8), %rsi
    test %rsi, %rsi
    jz .exit_end
    mov 8(%rsi), %al
    mov %al, -64(%rbp, %rcx)
    inc %rcx
    cmp $9, %rcx
    jb .exit_next_char

.exit_end:
    movb $'\n', -64(%rbp, %rcx)
    mov %rcx, %rdx
    inc %rdx
    lea -64(%rbp), %rsi # buffer
    mov $1, %rdi # stdout
    mov $1, %rax # write
    syscall

    xor %rax, %rax # return 0
    mov %rbp, %rsp
    pop %rbp
    ret

.insert:
    # rdi: ptr to link to push
    # rsi: ptr to link to be inserted
    push %rax
    push %rbx
    # [rdi] => [linkA] => [linkB]
    # [rsi] => [linkC]
    mov (%rdi), %rax # rax = linkA
    mov (%rax), %rbx # rbx = linkB
    mov %rbx, (%rdi) # rdi => linkB
    # [rdi] => [linkB]
    # [rsi] => [linkC]
    mov (%rsi), %rbx
    mov %rax, (%rsi)
    mov %rbx, (%rax)
    # [rdi] => [linkB]
    # [rsi] => [linkA] => [linkC]
    pop %rbx
    pop %rax
    ret

.print_stacks:
    push %rax
    push %rcx
    push %rdx
    push %rsi
    push %rdi
    push %r8
    mov $8, %rcx
.print_stacks_copy_roots:
    mov -152(%rbp, %rcx, 8), %rax
    push %rax
    dec %rcx
    cmp $0, %rcx
    jge .print_stacks_copy_roots
    push $0

.print_rows_loop:
    xor %rcx, %rcx
    xor %r8, %r8
.print_cells_loop:
    mov 8(%rsp, %rcx, 8), %rax
    test %rax, %rax
    jz .print_cell_zero
    movq $0x205d205b, (%rsp)
    mov 8(%rax), %bl
    mov %bl, 1(%rsp)
    mov (%rax), %rsi
    mov %rsi, 8(%rsp, %rcx, 8)
    inc %r8
    jmp .print_cell
.print_cell_zero:
    movq $0x20202020, (%rsp)
.print_cell:
    cmp $8, %rcx
    jne .print_cell_print
    movb $'\n', 3(%rsp)
.print_cell_print:
    mov $4, %rdx
    lea (%rsp), %rsi # buffer
    mov $1, %rdi # stdout
    mov $1, %rax # write
    push %rcx
    syscall
    pop %rcx
    inc %rcx
    cmp $9, %rcx
    jne .print_cells_loop
    test %r8, %r8
    jnz .print_rows_loop

    add $80, %rsp
    pop %r8
    pop %rdi
    pop %rsi
    pop %rdx
    pop %rcx
    pop %rax
    ret
