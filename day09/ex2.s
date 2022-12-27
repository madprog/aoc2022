.global main
main:
    push %rbp
    mov %rsp, %rbp
    sub $262312, %rsp
    # -64(%rbp) buffer
    # -68(%rbp) number
    # -72(%rbp) command
    # -76(%rbp) min x
    # -80(%rbp) max x
    # -84(%rbp) min y
    # -88(%rbp) max y
    # -92(%rbp) head x
    # -96(%rbp) head y
    # -100(%rbp) knot 1 x
    # -104(%rbp) knot 1 y
    # -108(%rbp) knot 2 x
    # -112(%rbp) knot 2 y
    # -116(%rbp) knot 3 x
    # -120(%rbp) knot 3 y
    # -124(%rbp) knot 4 x
    # -128(%rbp) knot 4 y
    # -132(%rbp) knot 5 x
    # -136(%rbp) knot 5 y
    # -140(%rbp) knot 6 x
    # -144(%rbp) knot 6 y
    # -148(%rbp) knot 7 x
    # -152(%rbp) knot 7 y
    # -156(%rbp) knot 8 x
    # -160(%rbp) knot 8 y
    # -164(%rbp) tail x
    # -168(%rbp) tail y
    # -262312(%rbp) matrix

    xor %rax, %rax
    mov $32789, %rcx
.memzero_loop:
    mov %rax, -262312(%rbp, %rcx, 8)
    dec %rcx
    jnz .memzero_loop

    mov $256, %eax
    mov $24, %rcx
.init_knots_loop:
    mov %eax, -172(%rbp, %rcx, 4) # head to tail, x+y
    dec %rcx
    jnz .init_knots_loop

    call .mark_matrix
    #call .print_matrix

.read_loop:
    mov $64, %rdx
    lea -64(%rbp), %rsi # buffer
    xor %rdi, %rdi # stdin
    xor %rax, %rax # read
    syscall

    test %rax, %rax
    jz .exit

    xor %rcx, %rcx
.parse_loop:
    cmpb $' ', -64(%rbp, %rcx)
    je .parse_loop_end

    cmpb $'\n', -64(%rbp, %rcx)
    je .run_command

    cmpb $'9', -64(%rbp, %rcx)
    jle .parse_number

.parse_command:
    mov -64(%rbp, %rcx), %bl
    mov %bl, -72(%rbp) # command
    jmp .parse_loop_end

.parse_number:
    mov -68(%rbp), %ebx # number
    imul $10, %ebx
    movzxb -64(%rbp, %rcx), %edx
    sub $'0', %edx
    add %edx, %ebx
    mov %ebx, -68(%rbp) # number
    jmp .parse_loop_end

.run_command:
    #call .print_command
.run_command_loop:
    mov -72(%rbp), %bl # command
    cmp $'U', %bl
    je .run_command_up
    cmp $'L', %bl
    je .run_command_left
    cmp $'D', %bl
    je .run_command_down
.run_command_right:
    incl -92(%rbp) # head x
    jmp .run_command_end
.run_command_down:
    incl -96(%rbp) # head y
    jmp .run_command_end
.run_command_left:
    decl -92(%rbp) # head x
    jmp .run_command_end
.run_command_up:
    decl -96(%rbp) # head y
.run_command_end:
    mov -92(%rbp), %ebx # head x
    cmp -76(%rbp), %ebx # min x
    jge .no_copy_min_x
    mov %ebx, -76(%rbp) # min x
.no_copy_min_x:
    cmp -80(%rbp), %ebx # max x
    jle .no_copy_max_x
    mov %ebx, -80(%rbp) # max x
.no_copy_max_x:
    mov -96(%rbp), %ebx # head y
    cmp -84(%rbp), %ebx # min y
    jge .no_copy_min_y
    mov %ebx, -84(%rbp) # min y
.no_copy_min_y:
    cmp -88(%rbp), %ebx # max y
    jle .no_copy_max_y
    mov %ebx, -88(%rbp) # max y
.no_copy_max_y:

    call .update_tail
    call .mark_matrix
    decl -68(%rbp) # number
    jnz .run_command_loop
    #call .print_matrix

.parse_loop_end:
    inc %rcx
    cmp %rax, %rcx
    jl .parse_loop
    jmp .read_loop

.exit:
    xor %rsi, %rsi # counter
    mov -76(%rbp), %ebx # min x
    mov -84(%rbp), %ecx # min y
.count_matrix_loop:
    mov %ecx, %eax
    imul $512, %rax
    add %ebx, %eax
    mov -262312(%rbp, %rax), %dl
    test %dl, %dl
    jz .count_not_visited
    inc %rsi
.count_not_visited:
    inc %ebx
    cmp -80(%rbp), %ebx # max x
    jle .count_matrix_loop
    mov -76(%rbp), %ebx # min x
    inc %ecx
    cmp -88(%rbp), %ecx # max y
    jle .count_matrix_loop

    pushq $0x000a6425 # "%d\n"
    movq %rsp, %rdi
    movq $0, %rax
    call printf

    pop %rax # pushed string remains on stack
    xor %rax, %rax # return 0
    mov %rbp, %rsp
    pop %rbp
    ret

.mark_matrix:
    push %rax
    push %rbx
    mov -168(%rbp), %eax # tail y
    imul $512, %rax
    add -164(%rbp), %eax # tail x
    mov $1, %bl
    mov %bl, -262312(%rbp, %rax)
    pop %rbx
    pop %rax
    ret

.print_command:
    push %rax
    push %rcx
    push %rdx
    push %rdi
    push %rsi
    mov $0x000a6425206325, %rax
    push %rax
    mov %rsp, %rdi
    movzxb -72(%rbp), %rsi # command
    movl -68(%rbp), %edx # number
    xor %rax, %rax
    call printf
    pop %rax
    pop %rsi
    pop %rdi
    pop %rdx
    pop %rcx
    pop %rax
    ret

.print_matrix:
    push %rax
    push %rbx
    push %rcx
    push %rdx
    push %rdi
    push %rsi
    pushq $0x000a006325 # "%c\0\n"
    mov -76(%rbp), %ebx # min x
    mov -84(%rbp), %ecx # min y
.print_matrix_loop:
    mov $'.', %sil

    mov %ecx, %eax
    imul $512, %rax
    add %ebx, %eax
    mov -262312(%rbp, %rax), %dl
    test %dl, %dl
    jz .not_visited
    mov $'#', %sil
.not_visited:

    cmp $256, %ebx
    jne .not_start
    cmp $256, %ecx
    jne .not_start
    mov $'s', %sil
.not_start:

    cmp -164(%rbp), %ebx # tail x
    jne .not_tail
    cmp -168(%rbp), %ecx # tail y
    jne .not_tail
    mov $'T', %sil
.not_tail:

    mov $-8, %rdx
.print_knot_loop:
    cmp -100(%rbp, %rdx, 8), %ebx # knot N x
    jne .not_knot
    cmp -104(%rbp, %rdx, 8), %ecx # knot N y
    jne .not_knot
    mov %dl, %sil
    neg %sil
    inc %sil
    add $'0', %sil
.not_knot:
    inc %rdx
    jle .print_knot_loop

    cmp -92(%rbp), %ebx # head x
    jne .not_head
    cmp -96(%rbp), %ecx # head y
    jne .not_head
    mov $'H', %sil
.not_head:

    lea (%rsp), %rdi # "%c"
    movq $0, %rax
    push %rcx
    call printf
    pop %rcx

    inc %ebx
    cmp -80(%rbp), %ebx # max x
    jle .print_matrix_loop

    lea 3(%rsp), %rdi # "\n"
    movq $0, %rax
    push %rcx
    call printf
    pop %rcx

    mov -76(%rbp), %ebx # min x
    inc %ecx
    cmp -88(%rbp), %ecx # max y
    jle .print_matrix_loop
    pop %rax # format string
    pop %rsi
    pop %rdi
    pop %rdx
    pop %rcx
    pop %rbx
    pop %rax
    ret

.update_tail:
    push %rax
    push %rbx
    push %rcx
    push %rdx
    push %rsi

    xor %rcx, %rcx
.update_tail_loop:
    mov -92(%rbp, %rcx, 8), %eax # head x
    sub -100(%rbp, %rcx, 8), %eax # tail x
    inc %eax
    inc %eax

    js .bad_tail
    cmp $4, %eax
    jg .bad_tail

    mov -96(%rbp, %rcx, 8), %ebx # head y
    sub -104(%rbp, %rcx, 8), %ebx # tail y
    inc %ebx
    inc %ebx

    js .bad_tail
    cmp $4, %ebx
    jg .bad_tail

    mov %eax, %edx
    shl $3, %edx
    add %ebx, %edx

    lea .table(%rip), %rsi
    movsxb 1(%rsi, %rdx, 2), %rax
    movsxb (%rsi, %rdx, 2), %rbx
    neg %rax
    neg %rbx
    add -92(%rbp, %rcx, 8), %eax # head x
    add -96(%rbp, %rcx, 8), %ebx # head y
    mov %eax, -100(%rbp, %rcx, 8) # tail x
    mov %ebx, -104(%rbp, %rcx, 8) # tail y

    dec %rcx
    cmp $-9, %rcx
    jne .update_tail_loop

    pop %rsi
    pop %rdx
    pop %rcx
    pop %rbx
    pop %rax
    ret

.bad_tail:
    push $0
    mov $0x0a6c696174646162, %rax # "badtail\n"
    push %rax
    movq %rsp, %rdi
    movq $0, %rax
    call printf

    sub $16, %rsp
    xor %rax, %rax # return 0
    mov %rbp, %rsp
    pop %rbp
    ret

.table:
    .word 0xffff # 000 000  -2 -2   =>  -1 -1
    .word 0xff00 # 000 001  -2 -1   =>  -1  0
    .word 0xff00 # 000 010  -2  0   =>  -1  0
    .word 0xff00 # 000 011  -2  1   =>  -1  0
    .word 0xff01 # 000 100  -2  2   =>  -1  1

    .word 0x0000
    .word 0x0000
    .word 0x0000

    .word 0x00ff # 001 000  -1 -2   =>   0 -1
    .word 0xffff # 001 001  -1 -1   =>  -1 -1
    .word 0xff00 # 001 010  -1  0   =>  -1  0
    .word 0xff01 # 001 011  -1  1   =>  -1  1
    .word 0x0001 # 001 100  -1  2   =>   0  1

    .word 0x0000
    .word 0x0000
    .word 0x0000

    .word 0x00ff # 010 000   0 -2   =>   0 -1
    .word 0x00ff # 010 001   0 -1   =>   0 -1
    .word 0x0000 # 010 010   0  0   =>   0  0
    .word 0x0001 # 010 011   0  1   =>   0  1
    .word 0x0001 # 010 100   0  2   =>   0  1

    .word 0x0000
    .word 0x0000
    .word 0x0000

    .word 0x00ff # 011 000   1 -2   =>   0 -1
    .word 0x01ff # 011 001   1 -1   =>   1 -1
    .word 0x0100 # 011 010   1  0   =>   1  0
    .word 0x0101 # 011 011   1  1   =>   1  1
    .word 0x0001 # 011 100   1  2   =>   0  1

    .word 0x0000
    .word 0x0000
    .word 0x0000

    .word 0x01ff # 100 000   2 -2   =>   1 -1
    .word 0x0100 # 100 001   2 -1   =>   1  0
    .word 0x0100 # 100 010   2  0   =>   1  0
    .word 0x0100 # 100 011   2  1   =>   1  0
    .word 0x0101 # 100 100   2  2   =>   1  1
