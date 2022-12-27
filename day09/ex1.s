.global main
main:
    push %rbp
    mov %rsp, %rbp
    sub $262248, %rsp
    # -64(%rbp) buffer
    # -68(%rbp) head x
    # -72(%rbp) head y
    # -76(%rbp) tail x
    # -80(%rbp) tail y
    # -84(%rbp) number
    # -88(%rbp) command
    # -92(%rbp) min x
    # -96(%rbp) max x
    # -100(%rbp) min y
    # -104(%rbp) max y
    # -262248(%rbp) matrix

    xor %rax, %rax
    mov $32781, %rcx
.memzero_loop:
    mov %rax, -262248(%rbp, %rcx, 8)
    dec %rcx
    jnz .memzero_loop

    mov $256, %eax
    mov %eax, -68(%rbp) # head x
    mov %eax, -72(%rbp) # head y
    mov %eax, -76(%rbp) # tail x
    mov %eax, -80(%rbp) # tail y
    mov %eax, -92(%rbp) # min x
    mov %eax, -96(%rbp) # max x
    mov %eax, -100(%rbp) # min y
    mov %eax, -104(%rbp) # max y

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
    mov %bl, -88(%rbp)
    jmp .parse_loop_end

.parse_number:
    mov -84(%rbp), %ebx
    imul $10, %ebx
    movzxb -64(%rbp, %rcx), %edx
    sub $'0', %edx
    add %edx, %ebx
    mov %ebx, -84(%rbp)
    jmp .parse_loop_end

.run_command:
    mov -88(%rbp), %bl
    cmp $'U', %bl
    je .run_command_up
    cmp $'L', %bl
    je .run_command_left
    cmp $'D', %bl
    je .run_command_down
.run_command_right:
    incl -68(%rbp) # head x
    jmp .run_command_end
.run_command_down:
    incl -72(%rbp) # head y
    jmp .run_command_end
.run_command_left:
    decl -68(%rbp) # head x
    jmp .run_command_end
.run_command_up:
    decl -72(%rbp) # head y
.run_command_end:
    mov -68(%rbp), %ebx # head x
    cmp -92(%rbp), %ebx # min x
    jge .no_copy_min_x
    mov %ebx, -92(%rbp) # min x
.no_copy_min_x:
    cmp -96(%rbp), %ebx # max x
    jle .no_copy_max_x
    mov %ebx, -96(%rbp) # max x
.no_copy_max_x:
    mov -72(%rbp), %ebx # head y
    cmp -100(%rbp), %ebx # min y
    jge .no_copy_min_y
    mov %ebx, -100(%rbp) # min y
.no_copy_min_y:
    cmp -104(%rbp), %ebx # max y
    jle .no_copy_max_y
    mov %ebx, -104(%rbp) # max y
.no_copy_max_y:

    #call .print_command
    call .update_tail
    call .mark_matrix
    #call .print_matrix
    decl -84(%rbp) # number
    jnz .run_command

.parse_loop_end:
    inc %rcx
    cmp %rax, %rcx
    jl .parse_loop
    jmp .read_loop

.exit:
    xor %rsi, %rsi # counter
    mov -92(%rbp), %ebx # min x
    mov -100(%rbp), %ecx # min y
.count_matrix_loop:
    mov %ecx, %eax
    imul $512, %rax
    add %ebx, %eax
    mov -262248(%rbp, %rax), %dl
    test %dl, %dl
    jz .count_not_visited
    inc %rsi
.count_not_visited:
    inc %ebx
    cmp -96(%rbp), %ebx # max x
    jle .count_matrix_loop
    mov -92(%rbp), %ebx # min x
    inc %ecx
    cmp -104(%rbp), %ecx # max y
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
    mov -80(%rbp), %eax # tail y
    imul $512, %rax
    add -76(%rbp), %eax # tail x
    mov $1, %bl
    mov %bl, -262248(%rbp, %rax)
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
    movzxb -88(%rbp), %rsi
    movl -84(%rbp), %edx
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
    mov -92(%rbp), %ebx # min x
    mov -100(%rbp), %ecx # min y
.print_matrix_loop:
    mov $'.', %sil

    mov %ecx, %eax
    imul $512, %rax
    add %ebx, %eax
    mov -262248(%rbp, %rax), %dl
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

    cmp -76(%rbp), %ebx
    jne .not_tail
    cmp -80(%rbp), %ecx
    jne .not_tail
    mov $'T', %sil
.not_tail:

    cmp -68(%rbp), %ebx
    jne .not_head
    cmp -72(%rbp), %ecx
    jne .not_head
    mov $'H', %sil
.not_head:

    lea (%rsp), %rdi # "%c"
    movq $0, %rax
    push %rcx
    call printf
    pop %rcx

    inc %ebx
    cmp -96(%rbp), %ebx # max x
    jle .print_matrix_loop

    lea 3(%rsp), %rdi # "\n"
    movq $0, %rax
    push %rcx
    call printf
    pop %rcx

    mov -92(%rbp), %ebx # min x
    inc %ecx
    cmp -104(%rbp), %ecx # max y
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
    push %rsi

    mov -68(%rbp), %eax # head x
    sub -76(%rbp), %eax # tail x
    inc %eax
    inc %eax

    js .bad_tail
    cmp $4, %eax
    jg .bad_tail

    mov -72(%rbp), %ebx # head y
    sub -80(%rbp), %ebx # tail y
    inc %ebx
    inc %ebx

    js .bad_tail
    cmp $4, %ebx
    jg .bad_tail

    mov %eax, %ecx
    shl $3, %ecx
    add %ebx, %ecx

    lea .table(%rip), %rsi
    movsxb 1(%rsi, %rcx, 2), %rax
    movsxb (%rsi, %rcx, 2), %rbx
    neg %rax
    neg %rbx
    add -68(%rbp), %eax # head x
    add -72(%rbp), %ebx # head y
    mov %eax, -76(%rbp) # tail x
    mov %ebx, -80(%rbp) # tail y

    pop %rsi
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
