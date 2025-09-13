format ELF64 executable 3

entry _start

include 'import64.inc'
interpreter '/lib64/ld-linux-x86-64.so.2'
needed 'libc.so.6'
import printf, malloc, free

segment readable executable

label _start

    ; initialize array
    mov rdi, 0       ; initial cap; 0 means use default
    call arr_alloc
    push qword rax   ; save the pointer to the allocated memory
                     ; TODO: handle errors

    ; print the pointer obtained from `malloc`
    mov rdi, c_fmt_arr_ptr
    mov rsi, [rsp]
    mov rdx, [rsp]
    call print_fmt_int_2

    lea rdi, [rsp]
    mov rsi, rdi
    mov rdx, rdi
    mov rdi, c_fmt_arr_addr
    call print_fmt_int_2

    call divider

    ; direct write 64-bit int at [0]
    ; lea rdi, [rsp] ; address of memory (no offset)
    ; mov qword [rdi], 0x13 ; value

    mov rdi, rsp
    mov rsi, 0
    mov rdx, 13
    call arr_set

    lea rdi, [rsp]
    mov rdi, [rdi]
    call print_hex_dec_int_n

    lea rdi, [rsp]
    mov rsi, 0
    call print_arr_elem

    call divider

    mov rdi, rsp
    mov rsi, 1
    mov rdx, 26
    call arr_set

    lea rdi, [rsp]
    mov rsi, 1
    call print_arr_elem

    call divider

    mov rdi, rsp
    mov rsi, 2
    mov rdx, 52
    call arr_set

    lea rdi, [rsp]
    mov rsi, 2
    call print_arr_elem

    call divider

    mov rdi, r8      ; rsi = a pointer from `arr_alloc` call
    call arr_free

    ; stack reset
    sub rsp, 8

    mov rdi, c_exit_msg
    call print_str
    mov rax, 0x3c     ; NR = sys_exit
    xor rdi, rdi      ; exit_code = 0
    syscall

;=====================================================================;

define ELEM_TYPE qword
define ELEM_SIZE_BYTES 8
define DEFAULT_ARR_CAP 2

label arr_alloc
    ; arg_0: initial capacity
    cmp rdi, 0
    mov r11, DEFAULT_ARR_CAP*ELEM_SIZE_BYTES
    cmove rdi, r11
    call [malloc]
    ret

label arr_free
    ; arg_0: ptr returned from `malloc`
    ; mov rdi, rdi ; keep rdi as is
    call [free]
    ret

label arr_set
    ; arg0 (rdi): effective address of ptr from `malloc`
    ; arg1 (rsi): element_index
    ; arg2 (rdx): 64-bit int value

    ; r10 := value (rdx is volatile)
    mov r10, rdx

    ; addr (rax) := calc effective address of element by its index
    call arr_calc_elem_addr
    ; write value at the calculated location
    mov ELEM_TYPE [rax], r10
    ret

label arr_set_by_ptr
    ; arg0 (rdi): ptr from `malloc`
    ; arg1 (rsi): element_index
    ; arg2 (rdx): 64-bit int value

    ; addr (rax) := calc ptr to an element by its index
    mov rax, ELEM_SIZE_BYTES
    mul rsi
    add rax, rdi
    ; write value at the calculated location
    mov rax, rdx
    ret


label arr_calc_elem_addr
    ; arg0 (rdi): effective address of memory (array)
    ; arg1 (rsi): index

    ; addr (rax) := (index + 1) * ELEM_SIZE_BYTES
    mov rax, rsi
    mov ELEM_TYPE rcx, ELEM_SIZE_BYTES
    mul rcx

    ; ret addr (rax)
    add rax, rdi ; = elem addr
    ret

label print_arr_elem
    ; arg0 (rdi) = effective address of array
    ; arg1 (rsi) = index

    ; addr (r11) := convert an index to the address of the element
    call arr_calc_elem_addr
    mov r11, rax

    ; fmt (rdi) := local pointer to the format string
    mov rdi, c_fmt_arr_elem_val
    ; int_val_1 (rsi) := arg1
    ; int_val_2 (rdx) := load value from array element memory
    mov ELEM_TYPE rdx, [r11]
    call print_fmt_int_2
    ret

;=====================================================================;

label print_int_n
    ; arg0 (rdi): in value

    mov rsi, c_fmt_int_n
    call print_fmt_int
    ret

label print_hex_int_n
    ; arg0 (rdi): int value

    ; fmt (rsi) := hex int + new line
    mov rsi, c_fmt_hex_int_n
    ; val1 (rdi) := arg1
    call print_fmt_int
    ret

label print_hex_dec_int_n
    ; arg_0: in value
    mov rdx, rdi
    mov rsi, c_fmt_hex_dec_int_n
    call print_fmt_int
    ret

label print_str
    ; arg_0: local prt to format message
    lea rdi, [rdi]
    xor rsi,rsi
    xor rax, rax
    call [printf]
    ret

label print_fmt_int
    ; arg0 (rdi): int val
    ; arg1 (rsi): *char local ptr to c format string, 0 terminated

    ; val (r11) := arg0
    mov r11, rdi
    ; addr (rdi) := load effective address of format string
    lea rdi, [rsi]
    ; val (r11 -> rsi)
    mov rsi, r11
    ; val2 (rdx) := val
    mov rdx, r11
    ; flags (rax) := NULL
    xor rax, rax
    call [printf]
    ret

label print_fmt_int_2
    ; arg0 (rdi): *char local pointer to c format string, 0 terminated
    ; arg1 (rsi): int value 1
    ; arg2 (rdx): int value 2

    ; addr (rdi) := get effective address of format string
    lea r11, [rdi]
    ; addr (r11 -> rdi)
    mov rdi, r11
    ; var_arg_1 (rsi) := arg1
    ; var_arg_2 (rdx) := arg2
    ; flags (rax) := NULL
    xor rax,rax
    call [printf]
    ret

label print_fmt_rdi_rsi
    ; arg0 (rdi): *char local pty to the c format string, 0 terminated
    ; arg1 (rsi): 64bit int value 1
    ; arg2 (rdx): 64bit int value 2

    ; save volatile registers
    ; val1 (r11) := arg1
    mov r11, rsi

    ; call printf
    ; addr (arg0, rdi) := lea [arg0]
    mov rax, rdi
    lea rdi, [rax]
    ; val1 (arg1, rsi) := 1st int
    mov rsi, r11
    ; val2 (arg2, rdx) := 2nd int
    ; flags (rax) := NULL
    xor rax, rax
    call [printf]
    ret

label divider
    mov rdi, c_fmt_divider
    call print_str
    ret

label print_n
    mov rdi, c_fmt_n
    call print_str
    ret

;=====================================================================;

segment readable writeable

exit_msg db 'Done.',0xa
exit_msg_size = $-exit_msg

c_exit_msg db 'Done.',0xa,0

c_fmt_int db '%llu',0

c_fmt_hex_int_n db '0x%x',0xa,0
c_fmt_int_n db '%llu',0xa,0

c_fmt_hex_dec_int_n db '0x%x (%llu)',0xa,0
c_fmt_n db 0xa,0

c_fmt_arr_elem_val db 'array[%llu] = %llu',0xa,0

c_fmt_arr_ptr db  '*int array = *0x%x (%lu)',0xa,0
c_fmt_arr_addr db '  eff addr = *0x%x (%lu)',0xa,0

c_fmt_divider db '----------------------------------------------------------------',0xa,0