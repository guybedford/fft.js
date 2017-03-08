(module
  (export "getOrAllocatePrecomputation" (func $getOrAllocatePrecomputation)) ;; size -> address in bytes
  (export "allocateBuffer" (func $allocateBuffer)) ;; size -> address in bytes
  (export "freeBuffer" (func $freeBuffer)) ;; address in bytes

  (export "transform4" (func $transform4))
  (export "singleTransform2" (func $singleTransform2))
  (export "singleTransform4" (func $singleTransform4))

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

  (func $transform4
    (param $outAddr i32)
    (param $dataAddr i32)
    (param $inv f64)
    (param $size i32)
    (param $width i32)
    (param $bitrevAddr i32)
    (param $tableAddr i32)

    (result f64)

    (local $len i32)
    (local $step i32)
    (local $outOff i32)
    (local $off i32)
    (local $i i32)
    (local $limit i32)
    (local $k i32)
    (local $curAddr i32)
    (local $loopCnt i32)
    (local $quarterLen i32)

    (local $Ar f64)
    (local $Ai f64)
    (local $Br f64)
    (local $Bi f64)
    (local $Cr f64)
    (local $Ci f64)
    (local $Dr f64)
    (local $Di f64)

    (local $tableBr f64)
    (local $tableBi f64)
    (local $tableCr f64)
    (local $tableCi f64)
    (local $tableDr f64)
    (local $tableDi f64)

    (local $MBr f64)
    (local $MBi f64)
    (local $MCr f64)
    (local $MCi f64)
    (local $MDr f64)
    (local $MDi f64)

    (local $T0r f64)
    (local $T0i f64)
    (local $T1r f64)
    (local $T1i f64)
    (local $T2r f64)
    (local $T2i f64)
    (local $T3r f64)
    (local $T3i f64)

    (set_local $step (i32.shl (i32.const 1) (get_local $width)))
    (set_local $len
      (i32.shl
        (i32.div_u (get_local $size) (get_local $step))
        (i32.const 4)
      )
    )

    (if (i32.eq (get_local $len) (i32.const 32))
    (then
      (loop $transform2
        (set_local $off
          (i32.load (i32.add (get_local $bitrevAddr) (get_local $i)))
        )

        (call $singleTransform2
          (i32.add (get_local $outAddr) (get_local $outOff))
          (i32.add (get_local $dataAddr) (get_local $off))
          (get_local $step)
        )

        ;; i++
        (set_local $i (i32.add
          (get_local $i) (i32.const 4)
        ))

        (br_if $transform2 (i32.lt_u (tee_local $outOff (i32.add
          (get_local $outOff) (get_local $len)
        )) (get_local $size)))
      )
    )
    (else
      ;; len === 8
      (loop $transform4
        (set_local $off
          (i32.load (i32.add (get_local $bitrevAddr) (get_local $i)))
        )

        (call $singleTransform4
          (i32.add (get_local $outAddr) (get_local $outOff))
          (i32.add (get_local $dataAddr) (get_local $off))
          (get_local $step)
          (get_local $inv)
        )

        ;; t++
        (set_local $i (i32.add
          (get_local $i) (i32.const 4)
        ))

        ;; loop while outOff += len < size
        (tee_local $outOff (i32.add
          (get_local $outOff) (get_local $len)
        ))
        (br_if $transform4 (i32.lt_u (get_local $size)))
      )
    ))

    ;; shift by 2
    (tee_local $step (i32.shr_u (get_local $step) (i32.const 2)))

    (if (i32.gt_u (i32.const 8))
    (loop $step
      (tee_local $len (i32.shl (i32.div_u (get_local $size) (get_local $step)) (i32.const 4)))
      (i32.shr_u (i32.const 2))
      (set_local $quarterLen)

      (set_local $outOff (i32.const 0))

      (loop $offset
        (set_local $limit (i32.add (get_local $outOff) (get_local $quarterLen)))
        (set_local $i (get_local $outOff))
        (set_local $k (i32.const 0))

        (loop $full
          ;; i
          (set_local $Ar (f64.load (tee_local $curAddr
            (i32.add (get_local $outAddr) (get_local $i))
          )))
          ;; i + 8
          (set_local $Ai (f64.load (tee_local $curAddr
            (i32.add (get_local $curAddr) (i32.const 8))
          )))
          ;; i + quarterLen + 8
          (set_local $Bi (f64.load (tee_local $curAddr
            (i32.add (get_local $curAddr) (get_local $quarterLen))
          )))
          ;; i + quarterLen
          (set_local $Br (f64.load (tee_local $curAddr
            (i32.sub (get_local $curAddr) (i32.const 8))
          )))
          ;; i + quarterLen * 2
          (set_local $Cr (f64.load (tee_local $curAddr
            (i32.add (get_local $curAddr) (get_local $quarterLen))
          )))
          ;; i + quarterLen * 2 + 8
          (set_local $Ci (f64.load (tee_local $curAddr
            (i32.add (get_local $curAddr) (i32.const 8))
          )))
          ;; i + quarterLen * 3 + 8
          (set_local $Di (f64.load (tee_local $curAddr
            (i32.add (get_local $curAddr) (get_local $quarterLen))
          )))
          ;; i + quarterLen * 3
          (set_local $Dr (f64.load (tee_local $curAddr
            (i32.sub (get_local $curAddr) (i32.const 8))
          )))

          ;; Middle values

          ;; k
          (set_local $tableBr (f64.load (tee_local $curAddr
            (i32.add (get_local $tableAddr) (get_local $k))
          )))
          ;; k + 8
          (set_local $tableBi (f64.mul
            (get_local $inv)
            (f64.load (tee_local $curAddr
              (i32.add (get_local $curAddr) (i32.const 8))
            ))
          ))
          ;; 2 * k + 8
          (set_local $tableCi (f64.mul
            (get_local $inv)
            (f64.load (tee_local $curAddr
              (i32.add (get_local $curAddr) (get_local $k))
            ))
          ))
          ;; 2 * k
          (set_local $tableCr (f64.load (tee_local $curAddr
            (i32.sub (get_local $curAddr) (i32.const 8))
          )))
          ;; 3 * k
          (set_local $tableDr (f64.load (tee_local $curAddr
            (i32.add (get_local $curAddr) (get_local $k))
          )))
          ;; 3 * k + 8
          (set_local $tableDi (f64.mul
            (get_local $inv)
            (f64.load (tee_local $curAddr
              (i32.add (get_local $curAddr) (i32.const 8))
            ))
          ))

          (set_local $MBr (f64.sub
            (f64.mul (get_local $Br) (get_local $tableBr))
            (f64.mul (get_local $Bi) (get_local $tableBi))
          ))
          (set_local $MBi (f64.add
            (f64.mul (get_local $Br) (get_local $tableBi))
            (f64.mul (get_local $Bi) (get_local $tableBr))
          ))
          (set_local $MCr (f64.sub
            (f64.mul (get_local $Cr) (get_local $tableCr))
            (f64.mul (get_local $Ci) (get_local $tableCi))
          ))
          (set_local $MCi (f64.add
            (f64.mul (get_local $Cr) (get_local $tableCi))
            (f64.mul (get_local $Ci) (get_local $tableCr))
          ))
          (set_local $MDr (f64.sub
            (f64.mul (get_local $Dr) (get_local $tableDr))
            (f64.mul (get_local $Di) (get_local $tableDi))
          ))
          (set_local $MDi (f64.add
            (f64.mul (get_local $Dr) (get_local $tableDi))
            (f64.mul (get_local $Di) (get_local $tableDr))
          ))

          ;; Pre-Final values
          (set_local $T0r (f64.add (get_local $Ar) (get_local $MCr)))
          (set_local $T0i (f64.add (get_local $Ai) (get_local $MCi)))
          (set_local $T1r (f64.sub (get_local $Ar) (get_local $MCr)))
          (set_local $T1i (f64.sub (get_local $Ai) (get_local $MCi)))
          (set_local $T2r (f64.add (get_local $MBr) (get_local $MDr)))
          (set_local $T2i (f64.add (get_local $MBi) (get_local $MDi)))
          (set_local $T3r (f64.mul
            (get_local $inv)
            (f64.sub (get_local $MBr) (get_local $MDr))
          ))
          (set_local $T3i (f64.mul
            (get_local $inv)
            (f64.sub (get_local $MBi) (get_local $MDi))
          ))

          ;;(if (i32.gt_u (get_local $k) (i32.const 0))
          ;;  (return (f64.add (get_local $T0r) (get_local $T2r)))
          ;;)

          ;; Final values
          (f64.store
            ;; i
            (tee_local $curAddr (i32.add (get_local $outAddr) (get_local $i)))
            (f64.add (get_local $T0r) (get_local $T2r))
          )
          (f64.store
            ;; i + 8
            (tee_local $curAddr (i32.add (get_local $curAddr) (i32.const 8)))
            (f64.add (get_local $T0i) (get_local $T2i))
          )
          (f64.store
            ;; i + quarterLen + 8
            (tee_local $curAddr (i32.add (get_local $curAddr) (get_local $quarterLen)))
            (f64.sub (get_local $T1i) (get_local $T3r))
          )
          (f64.store
            ;; i + quarterLen
            (tee_local $curAddr (i32.sub (get_local $curAddr) (i32.const 8)))
            (f64.add (get_local $T1r) (get_local $T3i))
          )
          (f64.store
            ;; i + quarterLen * 2
            (tee_local $curAddr (i32.add (get_local $curAddr) (get_local $quarterLen)))
            (f64.sub (get_local $T0r) (get_local $T2r))
          )
          (f64.store
            ;; i + quarterLen * 2 + 8
            (tee_local $curAddr (i32.add (get_local $curAddr) (i32.const 8)))
            (f64.sub (get_local $T0i) (get_local $T2i))
          )
          (f64.store
            ;; i + quarterLen * 3 + 8
            (tee_local $curAddr (i32.add (get_local $curAddr) (get_local $quarterLen)))
            (f64.add (get_local $T1i) (get_local $T3r))
          )
          (f64.store
            ;; i + quarterLen * 3
            (tee_local $curAddr (i32.sub (get_local $curAddr) (i32.const 8)))
            (f64.sub (get_local $T1r) (get_local $T3i))
          )

          ;; i += 16
          (set_local $i (i32.add (get_local $i) (i32.const 16)))
          ;; k += step
          (set_local $k (i32.add (get_local $k) (get_local $step)))

          ;; loop while i < limit
          (br_if $full (i32.lt_u (get_local $i) (get_local $limit)))
        )

        ;; outOff += len
        (set_local $outOff (i32.add (get_local $outOff) (get_local $len)))
        ;; loop while outOff < size
        (br_if $offset (i32.lt_u (get_local $outOff) (get_local $size)))
      )

      ;; step >>= 2
      (tee_local $step (i32.shr_u (get_local $step) (i32.const 2)))
      ;; loop while step > 8
      (br_if $step (i32.gt_u (i32.const 8)))
    ))

    (return (f64.convert_u/i32 (get_local $loopCnt)))
  )

  ;; radix-4
  ;;
  ;; NOTE: Only called for len=8
  (func $singleTransform4
    (param $outAddr i32)
    (param $dataAddr i32)
    (param $step i32)
    (param $inv f64)

    (local $Ar f64)
    (local $Ai f64)
    (local $Br f64)
    (local $Bi f64)
    (local $Cr f64)
    (local $Ci f64)
    (local $Dr f64)
    (local $Di f64)

    (local $T0r f64)
    (local $T0i f64)
    (local $T1r f64)
    (local $T1i f64)
    (local $T2r f64)
    (local $T2i f64)
    (local $T3r f64)
    (local $T3i f64)

    (set_local $Ar (f64.load (get_local $dataAddr)))
    ;; offset + 1
    (set_local $Ai (f64.load (tee_local $dataAddr
      (i32.add (get_local $dataAddr) (i32.const 8))
    )))
    ;; offset + 1 + step
    (set_local $Bi (f64.load (tee_local $dataAddr
      (i32.add (get_local $dataAddr) (get_local $step))
    )))
    ;; offset + step
    (set_local $Br (f64.load (tee_local $dataAddr
      (i32.sub (get_local $dataAddr) (i32.const 8))
    )))
    ;; offset + step * 2
    (set_local $Cr (f64.load (tee_local $dataAddr
      (i32.add (get_local $dataAddr) (get_local $step))
    )))
    ;; offset + step * 2 + 1
    (set_local $Ci (f64.load (tee_local $dataAddr
      (i32.add (get_local $dataAddr) (i32.const 8))
    )))
    ;; offset + step * 3 + 1
    (set_local $Di (f64.load (tee_local $dataAddr
      (i32.add (get_local $dataAddr) (get_local $step))
    )))
    ;; offset + step * 3
    (set_local $Dr (f64.load (tee_local $dataAddr
      (i32.sub (get_local $dataAddr) (i32.const 8))
    )))

    (set_local $T0r (f64.add (get_local $Ar) (get_local $Cr)))
    (set_local $T0i (f64.add (get_local $Ai) (get_local $Ci)))
    (set_local $T1r (f64.sub (get_local $Ar) (get_local $Cr)))
    (set_local $T1i (f64.sub (get_local $Ai) (get_local $Ci)))
    (set_local $T2r (f64.add (get_local $Br) (get_local $Dr)))
    (set_local $T2i (f64.add (get_local $Bi) (get_local $Di)))
    (set_local $T3r (f64.mul
      (get_local $inv)
      (f64.sub (get_local $Br) (get_local $Dr))
    ))
    (set_local $T3i (f64.mul
      (get_local $inv)
      (f64.sub (get_local $Bi) (get_local $Di))
    ))

    (f64.store
      (get_local $outAddr)
      (f64.add (get_local $T0r) (get_local $T2r))
    )
    (f64.store
      (tee_local $outAddr (i32.add (get_local $outAddr) (i32.const 8)))
      (f64.add (get_local $T0i) (get_local $T2i))
    )
    (f64.store
      (tee_local $outAddr (i32.add (get_local $outAddr) (i32.const 8)))
      (f64.add (get_local $T1r) (get_local $T3i))
    )
    (f64.store
      (tee_local $outAddr (i32.add (get_local $outAddr) (i32.const 8)))
      (f64.sub (get_local $T1i) (get_local $T3r))
    )
    (f64.store
      (tee_local $outAddr (i32.add (get_local $outAddr) (i32.const 8)))
      (f64.sub (get_local $T0r) (get_local $T2r))
    )
    (f64.store
      (tee_local $outAddr (i32.add (get_local $outAddr) (i32.const 8)))
      (f64.sub (get_local $T0i) (get_local $T2i))
    )
    (f64.store
      (tee_local $outAddr (i32.add (get_local $outAddr) (i32.const 8)))
      (f64.sub (get_local $T1r) (get_local $T3i))
    )
    (f64.store
      (tee_local $outAddr (i32.add (get_local $outAddr) (i32.const 8)))
      (f64.add (get_local $T1i) (get_local $T3r))
    )
  )

  ;; radix-2 implementation
  ;;
  ;; NOTE: Only called for len=4
  (func $singleTransform2
    (param $outAddr i32)
    (param $dataAddr i32)
    (param $step i32)

    (local $evenR f64)
    (local $evenI f64)
    (local $oddR f64)
    (local $oddI f64)

    (set_local $evenR (f64.load (get_local $dataAddr)))
    ;; offset + 1
    (set_local $evenI (f64.load (tee_local $dataAddr
      (i32.add (get_local $dataAddr) (i32.const 8))
    )))
    ;; offset + 1 + step
    (set_local $oddI (f64.load (tee_local $dataAddr
      (i32.add (get_local $dataAddr) (get_local $step))
    )))
    ;; offset + step
    (set_local $oddR (f64.load (tee_local $dataAddr
      (i32.sub (get_local $dataAddr) (i32.const 8))
    )))

    (f64.store
      (get_local $outAddr)
      (f64.add (get_local $evenR) (get_local $oddR))
    )
    (f64.store
      (tee_local $outAddr (i32.add (get_local $outAddr) (i32.const 8)))
      (f64.add (get_local $evenI) (get_local $oddI))
    )
    (f64.store
      (tee_local $outAddr (i32.add (get_local $outAddr) (i32.const 8)))
      (f64.sub (get_local $evenR) (get_local $oddR))
    )
    (f64.store
      (tee_local $outAddr (i32.add (get_local $outAddr) (i32.const 8)))
      (f64.sub (get_local $evenI) (get_local $oddI))
    )
  )
)
