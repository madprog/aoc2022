.global main
main:
    push %rbp
    mov %rsp, %rbp
    # buffer       -64(%rbp)
    # read size    -72(%rbp)
    # command      -80(%rbp)  1: noop, 2: addx, 3: subx
    # argument     -88(%rbp)
    # register X   -96(%rbp)
    # cycle        -104(%rbp)
    # screen       -351(%rbp)
    sub $351, %rsp

    xor %rbx, %rbx
    mov %rbx, -88(%rbp) # argument
    mov %rbx, -104(%rbp) # cycle
    inc %rbx
    mov %rbx, -96(%rbp) # register X
    mov $0x200a, %bx
    xor %rax, %rax
.init_screen_loop:
    cmp $40, %al
    je .init_screen_endline
    cmp $81, %al
    je .init_screen_endline
    cmp $122, %al
    je .init_screen_endline
    cmp $163, %al
    je .init_screen_endline
    cmp $204, %al
    je .init_screen_endline
    cmp $245, %al
    je .init_screen_endline
    mov %bh, -351(%rbp, %rax)
    jmp .init_screen_loop_end
.init_screen_endline:
    mov %bl, -351(%rbp, %rax)
.init_screen_loop_end:
    inc %rax
    cmp $246, %rax
    jl .init_screen_loop
    movb $0, -351(%rbp, %rax)

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
.execution_loop:
    mov -64(%rbp, %rcx), %al
    cmp $'\n', %al
    je .execute_command
    cmp $'n', %al
    je .set_command_noop
    cmp $'o', %al
    je .execution_loop_end
    cmp $'p', %al
    je .execution_loop_end
    cmp $'a', %al
    je .set_command_addx
    cmp $'d', %al
    je .execution_loop_end
    cmp $'x', %al
    je .execution_loop_end
    cmp $' ', %al
    je .execution_loop_end
    cmp $'-', %al
    je .set_command_subx

.parse_digit:
    mov -88(%rbp), %rax # argument
    imul $10, %rax
    movzxb -64(%rbp, %rcx), %rbx
    add %rbx, %rax
    sub $'0', %rax
    mov %rax, -88(%rbp) # argument
    jmp .execution_loop_end

.set_command_noop:
    mov $1, %rax
    mov %rax, -80(%rbp) # command
    jmp .execution_loop_end

.set_command_addx:
    mov $2, %rax
    mov %rax, -80(%rbp) # command
    jmp .execution_loop_end

.set_command_subx:
    mov $3, %rax
    mov %rax, -80(%rbp) # command
    jmp .execution_loop_end

.execute_command:
    mov -80(%rbp), %rax # command
    cmp $1, %rax
    je .execute_noop
    cmp $2, %rax
    je .execute_addx
.execute_subx:
    mov -88(%rbp), %rax
    neg %rax
    mov %rax, -88(%rbp)
.execute_addx:
    call .inc_cycle
    call .inc_cycle
    mov -88(%rbp), %rax # argument
    add %rax, -96(%rbp) # register X
    xor %rax, %rax
    mov %rax, -88(%rbp) # argument
    jmp .execution_loop_end
.execute_noop:
    call .inc_cycle

.execution_loop_end:
    cmpb $'\n', -64(%rbp, %rcx)
    jne .no_reset
    xor %rax, %rax
    mov %rax, -80(%rbp) # command
    mov %rax, -88(%rbp) # argument
.no_reset:
    inc %rcx
    cmp -72(%rbp), %rcx # read size
    jb .execution_loop
    jmp .read_loop

.inc_cycle:
    push %rcx
    mov -104(%rbp), %rax # cycle
    xor %rdx, %rdx
    mov $40, %rbx
    idiv %rbx
    mov -104(%rbp), %rbx # cycle
    add %rbx, %rax # screen offset = cycle + (cycle // 40)
    sub -96(%rbp), %rdx # rdx = (cycle % 40) - register X
    jz .draw_on
    cmp $-1, %rdx
    je .draw_on
    cmp $1, %rdx
    je .draw_on
.draw_off:
    movb $'.', -351(%rbp, %rax) # screen
    jmp .draw_end
.draw_on:
    movb $'#', -351(%rbp, %rax) # screen
.draw_end:

    mov -104(%rbp), %rax # cycle
    incq %rax
    mov %rax, -104(%rbp) # cycle

    #mov -80(%rbp), %rax # command
    #lea .fmt_commands(%rip), %rsi
    #lea (%rsi, %rax, 8), %rsi
    #mov -88(%rbp), %rdx # argument
    #mov -96(%rbp), %rcx # register X
    #mov -104(%rbp), %r8 # cycle
    #lea -351(%rbp), %r9 # screen
    #lea .fmt_print(%rip), %rdi
    #xor %rax, %rax
    #call printf

    pop %rcx
    ret

.fmt_print:
    .asciz "%s %ld X=%ld cycle=%ld\n%s\n"
.fmt_commands:
    .quad 0
    .quad 0x706f6f6e
    .quad 0x78646461
    .quad 0x78627573

.exit:
    lea -351(%rbp), %rdi # screen
    xor %rax, %rax
    call printf

    xor %rax, %rax # return 0
    mov %rbp, %rsp
    pop %rbp
    ret
