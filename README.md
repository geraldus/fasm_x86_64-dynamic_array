## API

### Array Struct

It is expected that arrays are stored in the memory as three 8-bytes
consequent values:
-   0-8 bytes: address of memory holding array data (obtained when calling init)
-  9-16 bytes: array's current length
- 17-24 bytes: array's current capacity

The memory should be writable.

API users are free to store these data wherever they want. Most API
methods (eg. `arr_set`, `arr_append`, ..,), expect _memory address_ as
the first argument. In other words, arrays are expressed in the API as
addresses of memory, holding data in a certain format.

### API Usage examples

TODO:
- [ ] provide `arr_get`
- [ ] bounds check

#### Initialize new array
```asm
    mov rdi, 64     ; capacity
    call arr_alloc  ; Returns an address of memory where array data
	                ; lives. In terms of C this is (void*) from the
					; `malloc` call.
    push 64         ; arr.cap, current cap is 64
    push 0          ; arr.cap, current len is 0
	push rax        ; arr.ptr, address of data
```

#### Append new element
```asm
    lea rdi, [rsp]  ; address of memory location, where
	mov rsi, 113    ; value
    call arr_append ; rax will contain `1` if relocation happened
```

#### Write value to element
```asm
    lea rdi, [rsp]  ; address of memory location, where
	mov rsi, 3      ; index
	mov rdi, 113    ; value
    call arr_append ; rax will contain `1` if relocation happened
```
