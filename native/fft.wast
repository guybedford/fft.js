(module
  (export "getOrAllocatePrecomputation" (func $getOrAllocatePrecomputation)) ;; size -> address in bytes
  (export "allocateBuffer" (func $allocateBuffer)) ;; size -> address in bytes
  (export "freeBuffer" (func $freeBuffer)) ;; address in bytes

  (export "transform4" (func $_Z10transform4PdS_iiiPiS_))
  (export "singleTransform2" (func $_Z16singleTransform2PdS_iii))
  (export "singleTransform4" (func $_Z16singleTransform4PdS_iiii))

  (memory (export "memory") 32)

  ;;
  ;; Memory Structure (super primitive, but it works)
  ;;
  ;; [PRECOMPUTE LIST] (0 - 1023)
  ;; We note the addresses of the table and bit_reversal for each given size
  ;; of the form:
  ;; - size (uint32) (leading one indicates if it is a table or bit reversal)
  ;; - address (uint32)
  ;; - Allocate: maximum 128 unique precompute items, 1KB
  ;;
  ;; [PRECOMPUTE BUFFERS] (1024 - 524287)
  ;; - Last location is stored as the global $free_precompute_address
  ;; - Allocate: maximum 512KB for table / bit reversal storage
  ;;
  ;; [INPUT / OUTPUT BUFFER DATA] (524288 - 2097152)
  ;; - We allocate buffers in sizes of 16384 * 8B (128KB)
  ;; - For larger buffers we just allocate multiple buffers
  ;; - Buffers get freed using a simple free list
  ;; - Extra buffers could be enabled by adding a grow_memory implementation
  ;;
  ;; Fixed memory allocation:
  ;; 32 * 64KB ~ 2MB

  (global $precompute_list_overflow_address i32 (i32.const 1024))
  (global $free_precompute_address (mut i32) (i32.const 1024))

  (global $precompute_overflow_address i32 (i32.const 524288))
  (global $free_buffer_address (mut i32) (i32.const 524288))
  (global $clear_free_address (mut i32) (i32.const 0))
  (global $buffer_size i32 (i32.const 131072))

  (func $getOrAllocatePrecomputation
    (param $size i32)
    (result i32)

    (local $precomputeListAddress i32)
    (local $curSize i32)

    ;; search precompute list to see if we have a table of this size
    ;; if so, return its address
    (loop $existing
      ;; check if the precompute indicates an entry for this size
      (if (i32.eq (tee_local $curSize
        (i32.load (get_local $precomputeListAddress))
      ) (get_local $size))
        ;; add a leading one at the first bit of the address to indicate it
        ;; is an existing table this is feigning multiple return values
        (return
          (i32.add
            (i32.load (i32.add (get_local $precomputeListAddress) (i32.const 4)))
            (i32.const 0x80000000)
          )
        )
      )

      (if (get_local $curSize)
      (then
        ;; increment precomputeListAddress by 8 bytes to next
        (set_local $precomputeListAddress (i32.add
          (get_local $precomputeListAddress)
          (i32.const 8)
        ))
        ;; keep looping
        (br $existing)
      ))
    )

    ;; precomputeListAddress will now be the end of the precompute table
    ;; so we add a new entry here and bump the free precompute address
    (i64.store (get_local $precomputeListAddress) (i64.add
      (i64.shl (i64.extend_u/i32 (get_global $free_precompute_address)) (i64.const 32))
      (i64.extend_u/i32 (get_local $size))
    ))

    ;; return value added to stack now
    (get_global $free_precompute_address)

    (set_global $free_precompute_address (i32.add
      (get_global $free_precompute_address)

      ;; ignore leading three bits, which indicate precompilation type if any
      (i32.and (get_local $size) (i32.const 0x1FFFFFFF))
    ))
  )

  ;; allocate a node in memory, returning its address
  (func $allocateBuffer
    (param $size i32)
    (param $skipFreeMem i32)
    (result i32)

    (local $allocatedSize i32)
    (local $nextFree i32)
    (local $clearPos i32)
    (local $clearEnd i32)

    ;; return the free address from the stack at the end
    (get_global $free_buffer_address)

    ;; can grow buffer on memory limit here if wanting more buffers

    ;; read the next free address pointer from the memory address
    (set_local $nextFree (i32.load (get_global $free_buffer_address)))

    ;; if we need to clear the memory allocated then do that now
    (if (i32.and
      (i32.eqz (get_local $skipFreeMem))
      (get_global $clear_free_address)
    )
    (then
      ;; clear next free memory item to be ready for next allocation
      (tee_local $clearPos (get_global $free_buffer_address))
      (i32.add (get_global $buffer_size))
      (set_local $clearEnd)

      (loop $clearmem
        (i64.store (get_local $clearPos) (i64.const 0))

        ;; loop while clearPos += 8 != end
        (br_if $clearmem (i32.eqz
          (i32.eq
            (tee_local $clearPos (i32.add
              (get_local $clearPos)
              (i32.const 8)
            ))
            (get_local $clearEnd)
          )
        ))
      )
    )
    (else
      ;; otherwise just clear this next free address pointer
      ;; from the allocated memory
      (i32.store (get_global $free_buffer_address) (i32.const 0))
    ))

    ;; update the free address for next time
    (if (get_local $nextFree)
    ;; if it exists, it is now the free address
    (then
      (set_global $free_buffer_address (get_local $nextFree))
    )
    ;; else free address is next unallocated in open address space
    (else
      (set_global $free_buffer_address
        (i32.add (get_global $free_buffer_address) (get_global $buffer_size))
      )
      ;; no longer need to clear memory
      (set_global $clear_free_address (i32.const 0))
    ))

    ;; return value from stack above
  )

  ;; free a node from memory
  (func $freeBuffer
    (param $addr i32)
    (param $size i32)

    (local $freedSize i32)

    (loop $free
      ;; write next as current free
      (i32.store (get_local $addr) (get_global $free_buffer_address))

      ;; set new free to this freed element
      (set_global $free_buffer_address (get_local $addr))

      ;; note we need to clear this memory to use it
      (set_global $clear_free_address (i32.const 1))

      ;; when we've reached the allocation size we are done
      (if (i32.gt_u
        (tee_local $freedSize (i32.add
          (get_local $freedSize)
          (get_global $buffer_size)
        ))
        (get_local $size)
      )
        (return)
      )

      ;; otherwise move address to next address and keep going
      (set_local $addr (i32.add (get_local $addr) (get_global $buffer_size)))

      ;; keep looping
      (br $free)
    )
  )

  (func $_Z10transform4PdS_iiiPiS_ (param $0 i32) (param $1 i32) (param $2 i32) (param $3 i32) (param $4 i32) (param $5 i32) (param $6 i32)
    (local $7 f64)
    (local $8 i32)
    (local $9 i32)
    (local $10 i32)
    (local $11 i32)
    (local $12 i32)
    (local $13 i32)
    (local $14 i32)
    (local $15 i32)
    (local $16 i32)
    (local $17 i32)
    (local $18 i32)
    (local $19 f64)
    (local $20 i32)
    (local $21 f64)
    (local $22 f64)
    (local $23 i32)
    (local $24 f64)
    (local $25 f64)
    (local $26 f64)
    (local $27 i32)
    (local $28 f64)
    (local $29 f64)
    (local $30 i32)
    (local $31 f64)
    (local $32 f64)
    (local $33 f64)
    (local $34 f64)
    (local $35 f64)
    (local $36 f64)
    (local $37 i32)
    (local $38 f64)
    (local $39 f64)
    (local $40 f64)
    (local $41 f64)
    (local $42 f64)
    (local $43 i32)
    (local $44 i32)
    (local $45 i32)
    (local $46 i32)
    (local $47 i32)
    (block $label$0
      (block $label$1
        (br_if $label$1
          (i32.ne
            (tee_local $27
              (i32.shl
                (i32.div_s
                  (get_local $3)
                  (tee_local $46
                    (i32.shl
                      (i32.const 1)
                      (get_local $4)
                    )
                  )
                )
                (i32.const 1)
              )
            )
            (i32.const 4)
          )
        )
        (br_if $label$0
          (i32.lt_s
            (get_local $3)
            (i32.const 1)
          )
        )
        (set_local $4
          (i32.const 0)
        )
        (loop $label$2
          (call $_Z16singleTransform2PdS_iii
            (get_local $0)
            (get_local $1)
            (get_local $4)
            (i32.load
              (i32.add
                (get_local $5)
                (get_local $4)
              )
            )
            (get_local $46)
          )
          (br_if $label$2
            (i32.lt_s
              (tee_local $4
                (i32.add
                  (get_local $4)
                  (i32.const 4)
                )
              )
              (get_local $3)
            )
          )
          (br $label$0)
        )
      )
      (br_if $label$0
        (i32.lt_s
          (get_local $3)
          (i32.const 1)
        )
      )
      (set_local $4
        (i32.const 0)
      )
      (loop $label$3
        (call $_Z16singleTransform4PdS_iiii
          (get_local $0)
          (get_local $1)
          (get_local $2)
          (get_local $4)
          (i32.load
            (get_local $5)
          )
          (get_local $46)
        )
        (set_local $5
          (i32.add
            (get_local $5)
            (i32.const 4)
          )
        )
        (br_if $label$3
          (i32.lt_s
            (tee_local $4
              (i32.add
                (get_local $4)
                (get_local $27)
              )
            )
            (get_local $3)
          )
        )
      )
    )
    (block $label$4
      (br_if $label$4
        (i32.lt_s
          (tee_local $43
            (i32.shr_s
              (get_local $46)
              (i32.const 2)
            )
          )
          (i32.const 2)
        )
      )
      (set_local $7
        (f64.convert_s/i32
          (get_local $2)
        )
      )
      (loop $label$5
        (set_local $5
          (i32.div_s
            (get_local $3)
            (get_local $43)
          )
        )
        (block $label$6
          (br_if $label$6
            (i32.lt_s
              (get_local $3)
              (i32.const 1)
            )
          )
          (set_local $16
            (i32.shl
              (get_local $43)
              (i32.const 3)
            )
          )
          (set_local $15
            (i32.shl
              (get_local $43)
              (i32.const 4)
            )
          )
          (set_local $14
            (i32.shl
              (tee_local $9
                (i32.shr_s
                  (tee_local $8
                    (i32.shl
                      (get_local $5)
                      (i32.const 1)
                    )
                  )
                  (i32.const 2)
                )
              )
              (i32.const 3)
            )
          )
          (set_local $13
            (i32.shl
              (get_local $9)
              (i32.const 4)
            )
          )
          (set_local $12
            (i32.mul
              (get_local $43)
              (i32.const 24)
            )
          )
          (set_local $11
            (i32.mul
              (get_local $9)
              (i32.const 24)
            )
          )
          (set_local $10
            (i32.shl
              (get_local $5)
              (i32.const 4)
            )
          )
          (set_local $45
            (i32.const 0)
          )
          (set_local $44
            (get_local $0)
          )
          (loop $label$7
            (block $label$8
              (br_if $label$8
                (i32.lt_s
                  (get_local $9)
                  (i32.const 1)
                )
              )
              (set_local $17
                (i32.add
                  (get_local $45)
                  (get_local $9)
                )
              )
              (set_local $4
                (i32.const 0)
              )
              (set_local $46
                (i32.const 0)
              )
              (set_local $1
                (i32.const 0)
              )
              (set_local $5
                (get_local $44)
              )
              (set_local $47
                (get_local $45)
              )
              (loop $label$9
                (f64.store
                  (get_local $5)
                  (f64.add
                    (tee_local $41
                      (f64.add
                        (tee_local $40
                          (f64.load
                            (get_local $5)
                          )
                        )
                        (tee_local $39
                          (f64.sub
                            (f64.mul
                              (tee_local $35
                                (f64.load
                                  (tee_local $2
                                    (i32.add
                                      (get_local $5)
                                      (get_local $13)
                                    )
                                  )
                                )
                              )
                              (tee_local $34
                                (f64.load
                                  (tee_local $27
                                    (i32.add
                                      (get_local $6)
                                      (get_local $46)
                                    )
                                  )
                                )
                              )
                            )
                            (f64.mul
                              (tee_local $38
                                (f64.load
                                  (tee_local $37
                                    (i32.add
                                      (get_local $2)
                                      (i32.const 8)
                                    )
                                  )
                                )
                              )
                              (tee_local $36
                                (f64.mul
                                  (f64.load
                                    (i32.add
                                      (get_local $27)
                                      (i32.const 8)
                                    )
                                  )
                                  (get_local $7)
                                )
                              )
                            )
                          )
                        )
                      )
                    )
                    (tee_local $33
                      (f64.add
                        (tee_local $32
                          (f64.sub
                            (f64.mul
                              (tee_local $28
                                (f64.load
                                  (tee_local $27
                                    (i32.add
                                      (get_local $5)
                                      (get_local $14)
                                    )
                                  )
                                )
                              )
                              (tee_local $26
                                (f64.load
                                  (tee_local $20
                                    (i32.add
                                      (get_local $6)
                                      (get_local $4)
                                    )
                                  )
                                )
                              )
                            )
                            (f64.mul
                              (tee_local $31
                                (f64.load
                                  (tee_local $30
                                    (i32.add
                                      (get_local $27)
                                      (i32.const 8)
                                    )
                                  )
                                )
                              )
                              (tee_local $29
                                (f64.mul
                                  (f64.load
                                    (i32.add
                                      (get_local $20)
                                      (i32.const 8)
                                    )
                                  )
                                  (get_local $7)
                                )
                              )
                            )
                          )
                        )
                        (tee_local $25
                          (f64.sub
                            (f64.mul
                              (tee_local $21
                                (f64.load
                                  (tee_local $20
                                    (i32.add
                                      (get_local $5)
                                      (get_local $11)
                                    )
                                  )
                                )
                              )
                              (tee_local $19
                                (f64.load
                                  (tee_local $18
                                    (i32.add
                                      (get_local $6)
                                      (get_local $1)
                                    )
                                  )
                                )
                              )
                            )
                            (f64.mul
                              (tee_local $24
                                (f64.load
                                  (tee_local $23
                                    (i32.add
                                      (get_local $20)
                                      (i32.const 8)
                                    )
                                  )
                                )
                              )
                              (tee_local $22
                                (f64.mul
                                  (f64.load
                                    (i32.add
                                      (get_local $18)
                                      (i32.const 8)
                                    )
                                  )
                                  (get_local $7)
                                )
                              )
                            )
                          )
                        )
                      )
                    )
                  )
                )
                (f64.store
                  (tee_local $18
                    (i32.add
                      (get_local $5)
                      (i32.const 8)
                    )
                  )
                  (f64.add
                    (tee_local $34
                      (f64.add
                        (tee_local $42
                          (f64.load
                            (get_local $18)
                          )
                        )
                        (tee_local $35
                          (f64.add
                            (f64.mul
                              (get_local $38)
                              (get_local $34)
                            )
                            (f64.mul
                              (get_local $35)
                              (get_local $36)
                            )
                          )
                        )
                      )
                    )
                    (tee_local $28
                      (f64.add
                        (tee_local $38
                          (f64.add
                            (f64.mul
                              (get_local $31)
                              (get_local $26)
                            )
                            (f64.mul
                              (get_local $28)
                              (get_local $29)
                            )
                          )
                        )
                        (tee_local $36
                          (f64.add
                            (f64.mul
                              (get_local $24)
                              (get_local $19)
                            )
                            (f64.mul
                              (get_local $21)
                              (get_local $22)
                            )
                          )
                        )
                      )
                    )
                  )
                )
                (f64.store
                  (get_local $30)
                  (f64.sub
                    (tee_local $35
                      (f64.sub
                        (get_local $42)
                        (get_local $35)
                      )
                    )
                    (tee_local $26
                      (f64.mul
                        (f64.sub
                          (get_local $32)
                          (get_local $25)
                        )
                        (get_local $7)
                      )
                    )
                  )
                )
                (f64.store
                  (get_local $27)
                  (f64.add
                    (tee_local $40
                      (f64.sub
                        (get_local $40)
                        (get_local $39)
                      )
                    )
                    (tee_local $38
                      (f64.mul
                        (f64.sub
                          (get_local $38)
                          (get_local $36)
                        )
                        (get_local $7)
                      )
                    )
                  )
                )
                (f64.store
                  (get_local $37)
                  (f64.sub
                    (get_local $34)
                    (get_local $28)
                  )
                )
                (f64.store
                  (get_local $2)
                  (f64.sub
                    (get_local $41)
                    (get_local $33)
                  )
                )
                (f64.store
                  (get_local $23)
                  (f64.add
                    (get_local $35)
                    (get_local $26)
                  )
                )
                (f64.store
                  (get_local $20)
                  (f64.sub
                    (get_local $40)
                    (get_local $38)
                  )
                )
                (set_local $4
                  (i32.add
                    (get_local $4)
                    (get_local $16)
                  )
                )
                (set_local $46
                  (i32.add
                    (get_local $46)
                    (get_local $15)
                  )
                )
                (set_local $1
                  (i32.add
                    (get_local $1)
                    (get_local $12)
                  )
                )
                (set_local $5
                  (i32.add
                    (get_local $5)
                    (i32.const 16)
                  )
                )
                (br_if $label$9
                  (i32.lt_s
                    (tee_local $47
                      (i32.add
                        (get_local $47)
                        (i32.const 2)
                      )
                    )
                    (get_local $17)
                  )
                )
              )
            )
            (set_local $44
              (i32.add
                (get_local $44)
                (get_local $10)
              )
            )
            (br_if $label$7
              (i32.lt_s
                (tee_local $45
                  (i32.add
                    (get_local $45)
                    (get_local $8)
                  )
                )
                (get_local $3)
              )
            )
          )
        )
        (br_if $label$5
          (i32.ge_s
            (tee_local $43
              (i32.shr_s
                (get_local $43)
                (i32.const 2)
              )
            )
            (i32.const 2)
          )
        )
      )
    )
  )
  (func $_Z16singleTransform2PdS_iii (param $0 i32) (param $1 i32) (param $2 i32) (param $3 i32) (param $4 i32)
    (local $5 i32)
    (local $6 f64)
    (local $7 f64)
    (local $8 f64)
    (local $9 f64)
    (set_local $8
      (f64.load
        (i32.add
          (tee_local $5
            (i32.add
              (get_local $1)
              (i32.shl
                (get_local $3)
                (i32.const 3)
              )
            )
          )
          (i32.const 8)
        )
      )
    )
    (set_local $9
      (f64.load
        (i32.add
          (tee_local $3
            (i32.add
              (get_local $1)
              (i32.shl
                (i32.add
                  (get_local $4)
                  (get_local $3)
                )
                (i32.const 3)
              )
            )
          )
          (i32.const 8)
        )
      )
    )
    (f64.store
      (tee_local $1
        (i32.add
          (get_local $0)
          (i32.shl
            (get_local $2)
            (i32.const 3)
          )
        )
      )
      (f64.add
        (tee_local $6
          (f64.load
            (get_local $5)
          )
        )
        (tee_local $7
          (f64.load
            (get_local $3)
          )
        )
      )
    )
    (f64.store
      (i32.add
        (get_local $1)
        (i32.const 16)
      )
      (f64.sub
        (get_local $6)
        (get_local $7)
      )
    )
    (f64.store
      (i32.add
        (get_local $1)
        (i32.const 8)
      )
      (f64.add
        (get_local $8)
        (get_local $9)
      )
    )
    (f64.store
      (i32.add
        (get_local $1)
        (i32.const 24)
      )
      (f64.sub
        (get_local $8)
        (get_local $9)
      )
    )
  )
  (func $_Z16singleTransform4PdS_iiii (param $0 i32) (param $1 i32) (param $2 i32) (param $3 i32) (param $4 i32) (param $5 i32)
    (local $6 i32)
    (local $7 f64)
    (local $8 f64)
    (local $9 f64)
    (local $10 i32)
    (local $11 f64)
    (local $12 i32)
    (local $13 f64)
    (local $14 f64)
    (local $15 f64)
    (local $16 f64)
    (local $17 f64)
    (local $18 f64)
    (set_local $15
      (f64.load
        (i32.add
          (tee_local $10
            (i32.add
              (get_local $1)
              (i32.shl
                (get_local $4)
                (i32.const 3)
              )
            )
          )
          (i32.const 8)
        )
      )
    )
    (set_local $16
      (f64.load
        (i32.add
          (tee_local $12
            (i32.add
              (get_local $1)
              (i32.shl
                (i32.add
                  (i32.shl
                    (get_local $5)
                    (i32.const 1)
                  )
                  (get_local $4)
                )
                (i32.const 3)
              )
            )
          )
          (i32.const 8)
        )
      )
    )
    (set_local $17
      (f64.load
        (i32.add
          (tee_local $6
            (i32.add
              (get_local $1)
              (i32.shl
                (i32.add
                  (get_local $5)
                  (get_local $4)
                )
                (i32.const 3)
              )
            )
          )
          (i32.const 8)
        )
      )
    )
    (set_local $18
      (f64.load
        (i32.add
          (tee_local $4
            (i32.add
              (get_local $1)
              (i32.shl
                (i32.add
                  (i32.mul
                    (get_local $5)
                    (i32.const 3)
                  )
                  (get_local $4)
                )
                (i32.const 3)
              )
            )
          )
          (i32.const 8)
        )
      )
    )
    (f64.store
      (tee_local $1
        (i32.add
          (get_local $0)
          (i32.shl
            (get_local $3)
            (i32.const 3)
          )
        )
      )
      (f64.add
        (tee_local $14
          (f64.add
            (tee_local $11
              (f64.load
                (get_local $10)
              )
            )
            (tee_local $13
              (f64.load
                (get_local $12)
              )
            )
          )
        )
        (tee_local $9
          (f64.add
            (tee_local $7
              (f64.load
                (get_local $6)
              )
            )
            (tee_local $8
              (f64.load
                (get_local $4)
              )
            )
          )
        )
      )
    )
    (f64.store
      (i32.add
        (get_local $1)
        (i32.const 32)
      )
      (f64.sub
        (get_local $14)
        (get_local $9)
      )
    )
    (f64.store
      (i32.add
        (get_local $1)
        (i32.const 8)
      )
      (f64.add
        (tee_local $14
          (f64.add
            (get_local $15)
            (get_local $16)
          )
        )
        (tee_local $9
          (f64.add
            (get_local $17)
            (get_local $18)
          )
        )
      )
    )
    (f64.store
      (i32.add
        (get_local $1)
        (i32.const 24)
      )
      (f64.sub
        (tee_local $15
          (f64.sub
            (get_local $15)
            (get_local $16)
          )
        )
        (tee_local $7
          (f64.mul
            (f64.sub
              (get_local $7)
              (get_local $8)
            )
            (tee_local $16
              (f64.convert_s/i32
                (get_local $2)
              )
            )
          )
        )
      )
    )
    (f64.store
      (i32.add
        (get_local $1)
        (i32.const 40)
      )
      (f64.sub
        (get_local $14)
        (get_local $9)
      )
    )
    (f64.store
      (i32.add
        (get_local $1)
        (i32.const 16)
      )
      (f64.add
        (tee_local $11
          (f64.sub
            (get_local $11)
            (get_local $13)
          )
        )
        (tee_local $16
          (f64.mul
            (f64.sub
              (get_local $17)
              (get_local $18)
            )
            (get_local $16)
          )
        )
      )
    )
    (f64.store
      (i32.add
        (get_local $1)
        (i32.const 48)
      )
      (f64.sub
        (get_local $11)
        (get_local $16)
      )
    )
    (f64.store
      (i32.add
        (get_local $1)
        (i32.const 56)
      )
      (f64.add
        (get_local $15)
        (get_local $7)
      )
    )
  )

)
