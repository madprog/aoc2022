# struct item (16):
#     0(%reg) worry level
#     8(%reg) next item
# struct monkey (16):
#     0(%reg) [8] first item
#     8(%reg) [1] operation operator
#     9(%reg) [1] operation operand (0 = old)
#    10(%reg) [1] test divisor
#    11(%reg) [1] target monkey (f0: if true, 0f: if false)
#    12(%reg) [4] inspection counter
.global main
main:
    push %rbp
    mov %rsp, %rbp
    sub $224, %rsp
    # -64(%rbp) buffer
    # -72(%rbp) read length
    # -200(%rbp) monkeys (8 monkeys of 16 bytes)
    # -208(%rbp) step
    # -216(%rbp) current monkey; then nb monkeys
    # -224(%rbp) product of divisors
    xor %rax, %rax
    mov $16, %rcx
.init_loop:
    dec %rcx
    mov %rax, -200(%rbp, %rcx, 8)
    jnz .init_loop

    mov %rcx, -208(%rbp) # step
    mov %rcx, -216(%rbp) # current monkey
.read_loop:
    mov $64, %rdx
    lea -64(%rbp), %rsi # buffer
    xor %rdi, %rdi # stdin
    xor %rax, %rax # read
    syscall

    test %rax, %rax
    jz .parsing_finished
    mov %rax, -72(%rbp) # read length

    xor %rcx, %rcx
.parse_loop:
    mov -64(%rbp, %rcx), %al
    cmp $'\n', %al
    je .next_step
    cmp $':', %al
    je .next_step
    cmpb $',', %al
    je .next_item

    cmp $'*', %al
    je .parse_operator
    cmp $'+', %al
    je .parse_operator

    cmp $'0', %al
    jl .parse_loop_end
    cmp $'9', %al
    jg .parse_loop_end

    mov -208(%rbp), %rbx # step
    cmp $3, %rbx
    je .parse_item
    cmp $5, %rbx
    je .parse_operand
    cmp $7, %rbx
    je .parse_divisor
    cmp $9, %rbx
    je .parse_monkey_true
    cmp $11, %rbx
    je .parse_monkey_false

    jmp .parse_loop_end

.next_step:
    mov -208(%rbp), %r8 # step
    inc %r8
    cmp $13, %r8
    jl .no_reset_step
    mov $0, %r8
.no_reset_step:
    mov %r8, -208(%rbp) # step
    cmp $3, %r8
    je .init_parse_items
    cmp $12, %r8
    je .next_monkey
    jmp .parse_loop_end

.init_parse_items:
    mov -216(%rbp), %rax # current monkey
    shl $1, %rax
    lea -200(%rbp, %rax, 8), %r10
.next_item:
    sub $16, %rsp
    mov %rsp, (%r10)
    lea 8(%rsp), %r10
    xor %rax, %rax
    mov %rax, -8(%r10)
    mov %rax, (%r10)
    jmp .parse_loop_end

.parse_item:
    movzx %al, %rsi
    mov -8(%r10), %rdi
    call .parse_number
    mov %rax, -8(%r10)
    jmp .parse_loop_end

.parse_operator:
    mov -216(%rbp), %rbx
    shl $1, %rbx
    mov %al, -200+8(%rbp, %rbx, 8) # operation operator
    jmp .parse_loop_end

.parse_operand:
    movzx %al, %rsi
    mov -216(%rbp), %rax # current monkey
    shl $1, %rax
    lea -200+9(%rbp, %rax, 8), %rbx # operation operand
    movzxb (%rbx), %rdi
    call .parse_number
    mov %al, (%rbx)
    jmp .parse_loop_end

.parse_divisor:
    movzx %al, %rsi
    mov -216(%rbp), %rax # current monkey
    shl $1, %rax
    lea -200+10(%rbp, %rax, 8), %rbx # test divisor
    movzxb (%rbx), %rdi
    call .parse_number
    mov %al, (%rbx)
    jmp .parse_loop_end

.parse_monkey_true:
    movzx %al, %rsi
    mov -216(%rbp), %rax # current monkey
    shl $1, %rax
    lea -200+11(%rbp, %rax, 8), %rbx # target monkey
    movzxb (%rbx), %rdi
    shr $4, %rdi
    call .parse_number
    andb $0x0f, (%rbx)
    shl $4, %al
    or %al, (%rbx)
    jmp .parse_loop_end

.parse_monkey_false:
    movzx %al, %rsi
    mov -216(%rbp), %rax # current monkey
    shl $1, %rax
    lea -200+11(%rbp, %rax, 8), %rbx # target monkey
    movzxb (%rbx), %rdi
    and $0x0f, %rdi
    call .parse_number
    andb $0xf0, (%rbx)
    or %al, (%rbx)
    jmp .parse_loop_end

.parse_number:
    push %rsi
    mov %rdi, %rax
    imul $10, %rax
    sub $'0', %rsi
    add %rsi, %rax
    pop %rsi
    ret

.next_monkey:
    incq -216(%rbp)

.parse_loop_end:
    inc %rcx
    cmp -72(%rbp), %rcx
    jl .parse_loop
    jmp .read_loop

.parsing_finished:
    xor %rbx, %rbx # monkey nr
    mov %rbx, -224(%rbp)
    incq -224(%rbp)
.multiply_divisors_loop:
    mov %rbx, %rax
    shl $1, %rax
    movzxb -200+10(%rbp, %rax, 8), %rax # test divisor
    mov -224(%rbp), %rcx # product of divisors
    mul %rcx
    mov %rax, -224(%rbp) # product of divisors
    inc %rbx # monkey nr
    cmp -216(%rbp), %rbx # nb monkeys
    jl .multiply_divisors_loop

    xor %rcx, %rcx # round
    xor %rbx, %rbx # monkey nr
.execution_loop:
    mov %rbx, %rax
    shl $1, %rax
    lea -200(%rbp, %rax, 8), %r8 # monkey
    mov (%r8), %r9 # ptr to item
    test %r9, %r9
    jz .no_items
    mov 8(%r9), %rax # next item
    mov %rax, (%r8) # removed considered item from monkey's list
    movq $0, 8(%r9) # nullify considered item's next ptr
    mov (%r9), %rax
    movzxb 9(%r8), %rdx # operation operand
    test %rdx, %rdx
    jnz .operand_not_old
    mov %rax, %rdx # if operand is zero, then we reuse old value as operand
.operand_not_old:
    cmpb $'*', 8(%r8) # operation operator
    je .multiply_worry
.add_worry:
    add %rdx, %rax
    jmp .worry_increased
.multiply_worry:
    mul %rdx
.worry_increased:
    #xor %rdx, %rdx
    #mov $3, %r10
    #div %r10
    #mov %rax, (%r9) # item's new worry level

    xor %rdx, %rdx
    mov -224(%rbp), %r10
    div %r10
    mov %rdx, (%r9) # item's new worry level

    xor %rdx, %rdx
    mov (%r9), %rax
    movzxb 10(%r8), %r10 # test divisor
    div %r10
    movzxb 11(%r8), %r10 # target monkey
    test %rdx, %rdx
    jnz .attach_to_monkey
    shr $4, %r10
.attach_to_monkey:
    and $0x0f, %r10
    shl $1, %r10
    lea -200(%rbp, %r10, 8), %r10 # new monkey
    sub $8, %r10
.search_item_list_end:
    cmpq $0, 8(%r10)
    jz .found_item_list_end
    mov 8(%r10), %r10
    jmp .search_item_list_end
.found_item_list_end:
    mov 8(%r10), %r11
    mov %r9, 8(%r10)
    mov %r11, 8(%r9)
    incq 12(%r8) # inspection counter

.no_items:
    cmpq $0, (%r8)
    jnz .execution_loop

    inc %rbx # monkey nr
    cmp -216(%rbp), %rbx # nb monkeys
    jl .execution_loop

    jmp .no_call_print_monkeys
    cmp $0, %rcx
    je .call_print_monkeys
    cmp $19, %rcx
    je .call_print_monkeys
    cmp $999, %rcx
    je .call_print_monkeys
    cmp $1999, %rcx
    je .call_print_monkeys
    cmp $2999, %rcx
    je .call_print_monkeys
    cmp $3999, %rcx
    je .call_print_monkeys
    cmp $4999, %rcx
    je .call_print_monkeys
    cmp $5999, %rcx
    je .call_print_monkeys
    cmp $6999, %rcx
    je .call_print_monkeys
    cmp $7999, %rcx
    je .call_print_monkeys
    cmp $8999, %rcx
    je .call_print_monkeys
    cmp $9999, %rcx
    je .call_print_monkeys
    jmp .no_call_print_monkeys
.call_print_monkeys:
    lea .str_round(%rip), %rdi
    push %rcx
    mov %rcx, %rsi
    inc %rsi
    movq $0, %rax
    call printf
    pop %rcx
    call .print_monkeys
.no_call_print_monkeys:
    xor %rbx, %rbx # monkey nr
    inc %rcx
    cmp $10000, %rcx
    jl .execution_loop

.exit:
    mov -200+12(%rbp), %eax # inspection counter
    mov -200+16+12(%rbp), %ebx # inspection counter
    cmp %rax, %rbx
    ja .no_swap1
    xor %rax, %rbx
    xor %rbx, %rax
    xor %rax, %rbx
.no_swap1:
    mov $2, %rcx
.search_max:
    mov %rcx, %rdx
    shl $1, %rdx
    mov -200+12(%rbp, %rdx, 8), %edx # inspection counter
    cmp %rdx, %rax
    ja .no_swap2
    mov %rdx, %rax
    cmp %rdx, %rbx
    ja .no_swap2
    mov %rbx, %rax
    mov %rdx, %rbx
.no_swap2:
    inc %rcx
    cmp -216(%rbp), %rcx
    jl .search_max

    imul %rbx
    mov %rax, %rsi
    lea .str_percent_d_lf(%rip), %rdi
    movq $0, %rax
    call printf

    xor %rax, %rax # return 0
    mov %rbp, %rsp
    pop %rbp
    ret

.print_monkeys:
    push %rax
    push %rbx
    push %rcx
    push %rdx
    push %rsi
    push %rdi
    push %r8
    push %r9
    push $0 # monkey number
    push $0 # item pointer
.print_monkeys_loop:
    mov 8(%rsp), %rsi # monkey number
    lea .str_monkey(%rip), %rdi
    movq $0, %rax
    call printf

    mov 8(%rsp), %rax # monkey number
    shl $1, %rax
    mov -200(%rbp, %rax, 8), %rax
    mov %rax, (%rsp) # item pointer
.print_monkeys_items_loop:
    mov (%rsp), %rax # item pointer
    test %rax, %rax
    jz .print_monkeys_items_loop_end
    mov (%rax), %rsi # item value
    lea .str_percent_d(%rip), %rdi
    xor %rax, %rax
    call printf

    mov (%rsp), %rax # item pointer
    mov 8(%rax), %rax
    mov %rax, (%rsp) # item pointer
    test %rax, %rax
    jmp .print_monkeys_items_loop
.print_monkeys_items_loop_end:

    mov 8(%rsp), %rax # monkey number
    shl $1, %rax
    lea -200(%rbp, %rax, 8), %rax
    movzxb 8(%rax), %rsi # operator
    movzxb 9(%rax), %rdx # operand
    movzxb 10(%rax), %rcx # divisor
    movzxb 11(%rax), %r8 # target monkey
    mov %r8, %r9
    shr $4, %r8 # if true
    and $0x0f, %r9 # if false
    movzxw 12(%rax), %rbx # inspection counter
    push %rbx
    lea .str_operation(%rip), %rdi
    movq $0, %rax
    call printf
    add $8, %rsp

    incq 8(%rsp) # monkey number
    mov -216(%rbp), %rax # nb monkeys
    cmp %rax, 8(%rsp) # monkey number
    jl .print_monkeys_loop
    add $16, %rsp
    pop %r9
    pop %r8
    pop %rdi
    pop %rsi
    pop %rdx
    pop %rcx
    pop %rbx
    pop %rax
    ret

.str_monkey:
    #.asciz "Monkey %d:\n  Items: "
    .asciz "Monkey %d: "
.str_percent_d: .asciz "%lu "
.str_percent_d_lf: .asciz "%lu\n"
.str_operation:
    .ascii "\n  Operation: new = old %c %d"
    .ascii "\n  Test: divisible by %d"
    .ascii "\n    True => throw to monkey %d"
    .ascii "\n    False => throw to monkey %d"
    .ascii "\n  Inspections: %u"
    .asciz "\n"
.str_round:
    .asciz "\n\n== Round %d==\n"
