# .name     byte[20] 0(%reg)
# .size     qword    20(%reg)
# .parent   qword    28(%reg)
# .contents qword    36(%reg)   chained list to contents, 0 for files
# .next     qword    44(%reg)   next item of the chained list
.global main
main:
    push %rbp
    mov %rsp, %rbp
    sub $84, %rsp
    # -20(%rbp): line buffer
    # -24(%rbp): state
    # -32(%rbp): current node
    # -84(%rbp): root folder
    xor %rax, %rax
    mov %eax, -24(%rbp) # state = 0 read_command
                        #         1 read_ls
    mov %rax, -84+44(%rbp) # root.next
    mov %rax, -84+36(%rbp) # root.contents
    mov %rax, -84+28(%rbp) # root.parent
    mov %rax, -84+20(%rbp) # root.size
    mov %rax, -84+12(%rbp) # root.name + 12
    mov %rax, -84+4(%rbp) # root.name + 4
    add $'/', %al
    mov %eax, -84(%rbp) # root.name

.parsing_loop:
    lea -20(%rbp), %rax
    call .read_line
    cmp $0, %r8
    je .exit

    cmpb $'$', -20(%rbp) # line buffer[0]
    je .parse_command

    mov -32(%rbp), %rbx # current node
    lea 36(%rbx), %rdx # ptr to current node.contents
.find_end_of_contents:
    cmpq $0, (%rdx)
    je .found_end_of_contents
    mov (%rdx), %rdx # follow contents chained list
    add $44, %rdx # ptr to next item's next field
    jmp .find_end_of_contents
.found_end_of_contents:
    # rbx: current node
    # rdx: ptr to end of contents

    sub $52, %rsp
    xor %rax, %rax
    mov %rax, 20(%rsp) # node.size
    mov %rax, 36(%rsp) # node.contents
    mov %rax, 44(%rsp) # node.next
    mov -32(%rbp), %rax # current node
    mov %rax, 28(%rsp) # node.parent

    mov %rsp, (%rdx) # add new node to end of chained list

    mov $3, %rcx
    cmpb $'d', -20(%rbp) # line buffer[0]
    je .copy_entry_name

    xor %rcx, %rcx
    xor %rax, %rax
.parse_file_size:
    movzxb -20(%rbp, %rcx), %rbx
    cmpb $' ', %bl
    je .file_size_parsed
    sub $'0', %bl
    imul $10, %rax
    add %rbx, %rax
    inc %rcx
    jmp .parse_file_size
.file_size_parsed:
    mov %rax, 20(%rsp)

.copy_entry_name:
    inc %rcx
    mov %rsp, %rdx
    sub %rcx, %rdx
.copy_entry_name_loop:
    mov -20(%rbp, %rcx), %al
    mov %al, (%rdx, %rcx)
    test %al, %al
    jz .entry_name_copied
    inc %rcx
    jmp .copy_entry_name_loop
.entry_name_copied:
    jmp .parsing_loop

.parse_command:
    cmpb $'c', -18(%rbp) # line buffer[2]
    jne .parsing_loop # parse_ls => nothing to do
    cmpb $'.', -15(%rbp) # line buffer[5]
    jne .process_cd_or_root
    cmpb $'.', -14(%rbp) # line buffer[6]
    jne .process_cd_or_root
    # process 'cd ..'
    mov -32(%rbp), %rax # current node
    mov 28(%rax), %rax # node.parent
    mov %rax, -32(%rbp) # current node
    jmp .parsing_loop

.process_cd_or_root:
    cmpb $'/', -15(%rbp) # line buffer[5]
    jne .process_cd
    lea -84(%rbp), %rax # root folder
    mov %rax, -32(%rbp) # current node
    jmp .parsing_loop
.process_cd:
    mov -32(%rbp), %r8 # current node
    mov 36(%r8), %r8 # current node.contents
.process_cd_find_loop:
    test %r8, %r8
    jz .process_cd_find_loop_end
    mov %r8, %rsi # node.name
    lea -15(%rbp), %rdi # line buffer[15]
    call .cmp_strings
    test %rax, %rax
    jz .process_cd_find_loop_end
    mov 44(%r8), %r8 # node.next
    jmp .process_cd_find_loop
.process_cd_find_loop_end:
    test %r8, %r8
    jz .subfolder_not_found
    mov %r8, -32(%rbp) # current node
    jmp .parsing_loop

.subfolder_not_found:
    pushq $0x0a646e75
    mov $0x6f6620746f6e2072, %rax
    push %rax
    mov $0x65646c6f66627573, %rax
    push %rax
    xor %rax, %rax
    mov %rsp, %rdi
    call printf
    add $24, %rsp
    mov $-1, %rax # return -1
    jmp .return

.exit:
    lea -84(%rbp), %rdi
    call .compute_size

    #xor %rsi, %rsi
    #lea -84(%rbp), %rdi
    #call .print_node

    lea -84(%rbp), %rdi
    mov $70000000, %rax
    sub 20(%rdi), %rax
    mov $30000000, %rsi
    sub %rax, %rsi
    call .find_smallest_dir_over

    movq %rax, %rsi # sum
    pushq $0x000a6425 # "%d\n"
    movq %rsp, %rdi
    movq $0, %rax
    call printf

    xor %rax, %rax # return 0
.return:
    mov %rbp, %rsp
    pop %rbp
    ret

.compute_size:
    # rdi: node
    push %rax
    push %rbx
    mov 36(%rdi), %rax # node.contents
    test %rax, %rax
    jz .compute_size_contents_loop_end # not a directory
    xor %rbx, %rbx
    mov %rbx, 20(%rdi) # node.size = 0
.compute_size_contents_loop:
    push %rdi
    mov %rax, %rdi
    call .compute_size
    mov 20(%rdi), %rbx
    pop %rdi
    add %rbx, 20(%rdi)
    mov 44(%rax), %rax # subnode.next
    test %rax, %rax
    jnz .compute_size_contents_loop
.compute_size_contents_loop_end:
    pop %rbx
    pop %rax
    ret

.find_smallest_dir_over:
    # rdi: node
    # rsi: minimum
    push %rbx
    push %r8
    mov $-1, %rbx
    mov 36(%rdi), %r8 # node.contents
    test %r8, %r8
    jz .find_smallest_dir_over_contents_loop_end # not a directory
    cmp %rsi, 20(%rdi)
    jb .find_smallest_dir_over_contents_loop
    mov 20(%rdi), %rbx
.find_smallest_dir_over_contents_loop:
    push %rdi
    mov %r8, %rdi
    call .find_smallest_dir_over
    pop %rdi
    cmp %rax, %rbx
    jb .find_smallest_dir_over_subdir_below
    mov %rax, %rbx
.find_smallest_dir_over_subdir_below:
    mov 44(%r8), %r8 # subnode.next
    test %r8, %r8
    jnz .find_smallest_dir_over_contents_loop
.find_smallest_dir_over_contents_loop_end:
    mov %rbx, %rax
    pop %r8
    pop %rbx
    ret

.read_line:
    # rax: ptr to char[20]
    push %rdx
    push %rsi
    push %rdi
    push %rax # (%rsp): ptr
    xor %r8, %r8
.read_line_nextc:
    mov $1, %rdx # n
    mov (%rsp), %rsi
    add %r8, %rsi # buffer
    xor %rdi, %rdi # stdin
    xor %rax, %rax # read
    syscall
    cmp $1, %rax
    jne .read_line_return
    mov (%rsp), %rsi
    inc %r8
    cmpb $'\n', -1(%rsi, %r8)
    jne .read_line_nextc
.read_line_return:
    movb $0, -1(%rsi, %r8)
    pop %rax
    pop %rdi
    pop %rsi
    pop %rdx
    ret

.cmp_strings:
    push %rcx
    xor %rax, %rax
    xor %rcx, %rcx
.cmp_strings_next:
    mov (%rdi, %rcx), %al
    sub (%rsi, %rcx), %al
    test %al, %al
    jnz .cmp_strings_ret

    cmpb $0, (%rdi, %rcx)
    je .cmp_strings_ret
    cmpb $0, (%rsi, %rcx)
    je .cmp_strings_ret

    inc %rcx
    jmp .cmp_strings_next
.cmp_strings_ret:
    pop %rcx
    ret

.print_node:
    # rdi: node
    # rsi: indent
    push %rax
    push %rcx
    push %rdx
    push %r8
    push %rdi
    push %rsi
    mov %rsi, %r8
.print_node_indent_loop:
    test %r8, %r8
    jz .print_node_indent_loop_end
    push $0x002020
    mov %rsp, %rdi
    mov $0, %rax
    call printf
    add $8, %rsp
    dec %r8
    jmp .print_node_indent_loop
.print_node_indent_loop_end:

    mov 8(%rsp), %rdx
    mov 20(%rdx), %rsi
    mov $0x000a7325206425, %rax # "%d %s\n"
    push %rax
    mov %rsp, %rdi
    mov $0, %rax
    call printf
    add $8, %rsp

    mov (%rsp), %rsi
    inc %rsi
    mov 8(%rsp), %rdi
    mov 36(%rdi), %rax
    test %rax, %rax
    jz .print_node_end
.print_node_subnode_loop:
    mov %rax, %rdi
    call .print_node
    mov 44(%rax), %rax
    test %rax, %rax
    jnz .print_node_subnode_loop
.print_node_end:
    pop %rsi
    pop %rdi
    pop %r8
    pop %rcx
    pop %rdx
    pop %rax
    ret
