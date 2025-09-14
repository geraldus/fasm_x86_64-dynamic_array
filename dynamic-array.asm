format ELF64 executable 3

entry _start

include 'import64.inc'
interpreter '/lib64/ld-linux-x86-64.so.2'
needed 'libc.so.6'
import printf, malloc, realloc, free

define ELEM_TYPE qword
define ELEM_SIZE_BYTES 8
define DEFAULT_ARR_CAP 2

segment readable executable

label _start

    ; setup stack
    push qword rbp
    mov rbp, rsp

    ; reserve local variables area
    define ARR_SIZE 24
    sub rsp, ARR_SIZE*2

    ; initialize 1st array
    mov rdi, 0       ; initial cap; 0 means use default
    call arr_alloc
    mov qword [rbp-8],  DEFAULT_ARR_CAP ; array.capacity
    mov qword [rbp-16], 0               ; array.len
    mov qword [rbp-24], rax             ; array.data*
                                        ; TODO: handle errors

    ; print the pointer obtained from `malloc`
    lea rdi, [rbp-24]
    call print_arr_ptr

    ; a[] := ...          //        , 1
    lea rdi, [rbp-24]
    mov rsi, 13
    call arr_append

    ; a[] := ...          //        , 2
    lea rdi, [rbp-24]
    mov rsi, 26
    call arr_append

    ; print the pointer obtained from `malloc`
    call print_arr_info

    ; a[] := 1025 (0x401) // realloc, 3
    lea rdi, [rbp-24]
    mov rsi, 0x401
    call arr_append

    ; a[1] := 1337
    lea rdi, [rbp-24]
    mov rsi, 1
    mov rdx, 29
    call arr_set

    ; a[] := ...          //        , 4
    lea rdi, [rbp-24]
    mov rsi, 1993
    call arr_append

    ; print the pointer obtained from `malloc`
    call print_arr_info

    ; a[] := ...          // realloc, 5
    lea rdi, [rbp-24]
    mov rsi, 2025
    call arr_append

    ; a[2] := 1337
    lea rdi, [rbp-24]
    mov rsi, 2
    mov rdx, 1337
    call arr_set

    ; a[] := ...          //        , 6
    lea rdi, [rbp-24]
    mov rsi, 956421
    call arr_append

    ; print the pointer obtained from `malloc`
    call print_arr_info

    ; print a[2]
    lea rdi, [rbp-24]
    mov rsi, 0
    call print_arr_elem
    lea rdi, [rbp-24]
    mov rsi, 1
    call print_arr_elem
    lea rdi, [rbp-24]
    mov rsi, 2
    call print_arr_elem
    lea rdi, [rbp-24]
    mov rsi, 3
    call print_arr_elem
    lea rdi, [rbp-24]
    mov rsi, 4
    call print_arr_elem
    lea rdi, [rbp-24]
    mov rsi, 5
    call print_arr_elem

    call divider ;----------------------------------------------------

    ; free a[]
    lea rdi, [rbp-24]      ; rsi = a pointer from `arr_alloc` call
    call arr_free

    ; stack recover
    mov rsp, rbp
    mov rbp, rsp

    mov rdi, c_exit_msg
    call print_str
    mov rax, 0x3c     ; NR = sys_exit
    xor rdi, rdi      ; exit_code = 0
    syscall

;=====================================================================;

label arr_alloc
    ; arg0 (rdi): initial capacity

    cmp rdi, 0
    mov r11, DEFAULT_ARR_CAP*ELEM_SIZE_BYTES
    cmove rdi, r11
    call [malloc]
    ret

label arr_free
    ; arg0 (rdi): memory address holding pointer to the array structure

    ; arg0 (rdi) := (void*) array.ptr
    mov rdi, [rdi]
    call [free]
    ret

label arr_calc_elem_addr
    ; arg0 (rdi): memory address holding pointer to the array structure
    ; arg1 (rsi): index

    ; offset (rax) := index * ELEM_SIZE_BYTES
    mov rax, rsi
    mov ELEM_TYPE rcx, ELEM_SIZE_BYTES
    mul rcx

    ; addr (rcx) := (void*) array.ptr
    mov rcx, [rdi]
    ; ret elem_addr (rax) := addr + offset
    add rax, rcx ; = elem addr
    ret

label arr_set
    ; arg0 (rdi): memory address holding pointer to the array structure
    ; arg1 (rsi): element_index
    ; arg2 (rdx): 64-bit int value

    ; value (rsp):= value (rdx is volatile)
    push rdx

    ; addr (rax) := calc effective address of element by its index
    call arr_calc_elem_addr

    ; write value at the calculated location
    pop ELEM_TYPE [rax]
    ret

label arr_append
    ; arg0 (rdi): memory address holding pointer to the array structure
    ; arg1 (rsi): int64 value

    ; value (rsp+8) := value;
    push rsi
    ; arr_addr (rsp) := the address of an array
    push rdi

    call arr_grow_if_needed

    ; rcx := array.ptr
    mov rcx, [rsp]
    mov rcx, [rcx]
    ; new_last_index (rsi) := array.size
    mov rsi, [rcx+8]
    ; array.size += 1
    add qword [rcx+8],1

    ; arg0, array_addr (rdi) := arr_addr (rsp)
    mov rdi, [rsp]
    ; arg1, index (rsi) := new_last_index (rsi)
    ; arg2, val (rdx) := value (rsp+8)
    mov rdx, [rsp+8]
    call arr_set

    ; rax := arr_addr
    pop rax
    pop rax
    ret

label arr_grow_if_needed
    ; arg0 (rdi): memory address holding pointer to the array structure
    ; ret (rax): bool, 1 if realloc happened, 0 otherwise

    xor rax,rax
    mov rcx, [rdi+8] ; arr.len
    cmp rcx,[rdi+16] ; arr.len == arr.app ?
    je _inline_arr_realloc
    xor rax,rax
    ret

  label _inline_arr_realloc
    ; (rdi): memory address holding pointer to the array structure
    ; ret (rax): bool, always returns 1 (true)

    ; rax := array.capacity
    mov rax, [rdi+16]
    ; new_cap (rax) = array.cap*2
    mov rcx, 2
    mul rcx
    ; new_cap  -> stack
    push rax

    ; arr_addr -> stack
    push rdi
    ; arg0 (rdi) = rdi
    ; arg1 (rsi) = array.capacity (doubled)
    call [realloc]
    pop rdi
    ; array.data := new array pointer
    mov [rdi], rax

    ; array.capacity := new_cap
    pop qword [rdi+16]
    mov rax, 1
    ret

label print_arr_info
    call divider ;----------------------------------------------------
    call print_arr_ptr
    call print_arr_len
    call print_arr_cap
    call divider ;----------------------------------------------------
    ret

label print_arr_ptr
    ; arg0 (rdi): memory address holding pointer to the array structure

    mov rsi, [rdi]
    mov rdx, [rdi]
    mov rdi, c_fmt_arr_ptr
    call print_fmt_int_2
    ret

label print_arr_len
    ; arg0 (rdi): memory address holding pointer to the array structure

    mov rdi, [rdi+8]
    mov rsi, c_fmt_arr_len
    call print_fmt_int
    ret

label print_arr_cap
    ; arg0 (rdi): memory address holding pointer to the array structure

    mov rdi, [rdi+16]
    mov rsi, c_fmt_arr_cap
    call print_fmt_int
    ret

label print_arr_elem
    ; arg0 (rdi): memory address holding pointer to the array structure
    ; arg1 (rsi): index

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

exit_msg		 db 'Done.',0xa
exit_msg_size            =  $-exit_msg

c_exit_msg		 db 'Done.',0xa,0

c_fmt_int		 db '%llu',0
c_fmt_int_n		 db '%llu',0xa,0

c_fmt_hex_int_n		 db '0x%x',0xa,0
c_fmt_hex_dec_int_n	 db '0x%x (%llu)',0xa,0

c_fmt_arr_elem_val	 db 'array[%llu] = %llu',0xa,0
c_fmt_arr_ptr		 db  '*int array = *0x%x (%lu)',0xa,0
c_fmt_arr_addr		 db '  eff addr = *0x%x (%lu)',0xa,0
c_fmt_arr_cap		 db 'array.cap = %lu',0xa,0
c_fmt_arr_len		 db 'array.len = %lu',0xa,0

c_fmt_n			 db 0xa,0
c_fmt_divider		 db '----------------------------------------------------------------',0xa,0
