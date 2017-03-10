(module
 (table 0 anyfunc)
 (memory $0 1)
 (export "memory" (memory $0))
 (export "transform4" (func $transform4))
 (export "singleTransform2" (func $singleTransform2))
 (export "singleTransform4" (func $singleTransform4))
 (func $transform4 (param $0 i32) (param $1 i32) (param $2 i32) (param $3 i32) (param $4 i32) (param $5 i32) (param $6 i32)
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
  (local $19 i32)
  (local $20 i32)
  (local $21 i32)
  (local $22 f64)
  (local $23 i32)
  (local $24 i32)
  (local $25 f64)
  (local $26 f64)
  (local $27 f64)
  (local $28 f64)
  (local $29 f64)
  (local $30 i32)
  (local $31 i32)
  (local $32 f64)
  (local $33 f64)
  (local $34 f64)
  (local $35 f64)
  (local $36 f64)
  (local $37 f64)
  (local $38 i32)
  (local $39 i32)
  (local $40 f64)
  (local $41 f64)
  (local $42 f64)
  (local $43 f64)
  (local $44 f64)
  (local $45 f64)
  (local $46 f64)
  (local $47 i32)
  (block $label$0
   (block $label$1
    (br_if $label$1
     (i32.ne
      (tee_local $38
       (i32.shl
        (i32.div_s
         (get_local $3)
         (tee_local $47
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
    (set_local $4
     (i32.const 0)
    )
    (loop $label$2
     (br_if $label$0
      (i32.ge_s
       (get_local $4)
       (get_local $3)
      )
     )
     (call $singleTransform2
      (get_local $0)
      (get_local $1)
      (get_local $4)
      (i32.load
       (i32.add
        (get_local $5)
        (get_local $4)
       )
      )
      (get_local $47)
     )
     (set_local $4
      (i32.add
       (get_local $4)
       (i32.const 4)
      )
     )
     (br $label$2)
    )
   )
   (set_local $4
    (i32.const 0)
   )
   (loop $label$3
    (br_if $label$0
     (i32.ge_s
      (get_local $4)
      (get_local $3)
     )
    )
    (call $singleTransform4
     (get_local $0)
     (get_local $1)
     (get_local $2)
     (get_local $4)
     (i32.load
      (get_local $5)
     )
     (get_local $47)
    )
    (set_local $5
     (i32.add
      (get_local $5)
      (i32.const 4)
     )
    )
    (set_local $4
     (i32.add
      (get_local $4)
      (get_local $38)
     )
    )
    (br $label$3)
   )
  )
  (set_local $8
   (i32.add
    (get_local $0)
    (i32.const 8)
   )
  )
  (set_local $7
   (f64.convert_s/i32
    (get_local $2)
   )
  )
  (block $label$4
   (loop $label$5
    (br_if $label$4
     (i32.lt_s
      (tee_local $47
       (i32.shr_s
        (get_local $47)
        (i32.const 2)
       )
      )
      (i32.const 2)
     )
    )
    (set_local $13
     (i32.shl
      (get_local $47)
      (i32.const 3)
     )
    )
    (set_local $12
     (i32.shl
      (get_local $47)
      (i32.const 4)
     )
    )
    (set_local $11
     (i32.mul
      (get_local $47)
      (i32.const 24)
     )
    )
    (set_local $14
     (i32.shl
      (tee_local $4
       (i32.div_s
        (get_local $3)
        (get_local $47)
       )
      )
      (i32.const 4)
     )
    )
    (set_local $17
     (i32.shl
      (tee_local $10
       (i32.shr_s
        (tee_local $9
         (i32.shl
          (get_local $4)
          (i32.const 1)
         )
        )
        (i32.const 2)
       )
      )
      (i32.const 4)
     )
    )
    (set_local $16
     (i32.mul
      (get_local $10)
      (i32.const 24)
     )
    )
    (set_local $15
     (i32.shl
      (get_local $10)
      (i32.const 3)
     )
    )
    (set_local $19
     (i32.const 0)
    )
    (set_local $18
     (get_local $8)
    )
    (loop $label$6
     (br_if $label$5
      (i32.ge_s
       (get_local $19)
       (get_local $3)
      )
     )
     (set_local $20
      (i32.add
       (get_local $19)
       (get_local $10)
      )
     )
     (set_local $0
      (i32.const 0)
     )
     (set_local $4
      (get_local $18)
     )
     (set_local $1
      (i32.const 0)
     )
     (set_local $2
      (i32.const 0)
     )
     (set_local $5
      (get_local $19)
     )
     (block $label$7
      (loop $label$8
       (br_if $label$7
        (i32.ge_s
         (get_local $5)
         (get_local $20)
        )
       )
       (f64.store
        (tee_local $38
         (i32.add
          (get_local $4)
          (i32.const -8)
         )
        )
        (f64.add
         (tee_local $45
          (f64.add
           (tee_local $44
            (f64.load
             (get_local $38)
            )
           )
           (tee_local $43
            (f64.sub
             (f64.mul
              (tee_local $40
               (f64.load
                (tee_local $39
                 (i32.add
                  (tee_local $38
                   (i32.add
                    (get_local $4)
                    (get_local $17)
                   )
                  )
                  (i32.const -8)
                 )
                )
               )
              )
              (tee_local $37
               (f64.load
                (tee_local $30
                 (i32.add
                  (get_local $6)
                  (get_local $1)
                 )
                )
               )
              )
             )
             (f64.mul
              (tee_local $42
               (f64.load
                (get_local $38)
               )
              )
              (tee_local $41
               (f64.mul
                (f64.load
                 (i32.add
                  (get_local $30)
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
         (tee_local $36
          (f64.add
           (tee_local $35
            (f64.sub
             (f64.mul
              (tee_local $32
               (f64.load
                (tee_local $31
                 (i32.add
                  (tee_local $30
                   (i32.add
                    (get_local $4)
                    (get_local $15)
                   )
                  )
                  (i32.const -8)
                 )
                )
               )
              )
              (tee_local $29
               (f64.load
                (tee_local $23
                 (i32.add
                  (get_local $6)
                  (get_local $0)
                 )
                )
               )
              )
             )
             (f64.mul
              (tee_local $34
               (f64.load
                (get_local $30)
               )
              )
              (tee_local $33
               (f64.mul
                (f64.load
                 (i32.add
                  (get_local $23)
                  (i32.const 8)
                 )
                )
                (get_local $7)
               )
              )
             )
            )
           )
           (tee_local $28
            (f64.sub
             (f64.mul
              (tee_local $25
               (f64.load
                (tee_local $24
                 (i32.add
                  (tee_local $23
                   (i32.add
                    (get_local $4)
                    (get_local $16)
                   )
                  )
                  (i32.const -8)
                 )
                )
               )
              )
              (tee_local $22
               (f64.load
                (tee_local $21
                 (i32.add
                  (get_local $6)
                  (get_local $2)
                 )
                )
               )
              )
             )
             (f64.mul
              (tee_local $27
               (f64.load
                (get_local $23)
               )
              )
              (tee_local $26
               (f64.mul
                (f64.load
                 (i32.add
                  (get_local $21)
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
        (get_local $4)
        (f64.add
         (tee_local $37
          (f64.add
           (tee_local $46
            (f64.load
             (get_local $4)
            )
           )
           (tee_local $40
            (f64.add
             (f64.mul
              (get_local $42)
              (get_local $37)
             )
             (f64.mul
              (get_local $40)
              (get_local $41)
             )
            )
           )
          )
         )
         (tee_local $32
          (f64.add
           (tee_local $42
            (f64.add
             (f64.mul
              (get_local $34)
              (get_local $29)
             )
             (f64.mul
              (get_local $32)
              (get_local $33)
             )
            )
           )
           (tee_local $41
            (f64.add
             (f64.mul
              (get_local $27)
              (get_local $22)
             )
             (f64.mul
              (get_local $25)
              (get_local $26)
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
         (tee_local $40
          (f64.sub
           (get_local $46)
           (get_local $40)
          )
         )
         (tee_local $29
          (f64.mul
           (f64.sub
            (get_local $35)
            (get_local $28)
           )
           (get_local $7)
          )
         )
        )
       )
       (f64.store
        (get_local $31)
        (f64.add
         (tee_local $44
          (f64.sub
           (get_local $44)
           (get_local $43)
          )
         )
         (tee_local $42
          (f64.mul
           (f64.sub
            (get_local $42)
            (get_local $41)
           )
           (get_local $7)
          )
         )
        )
       )
       (f64.store
        (get_local $38)
        (f64.sub
         (get_local $37)
         (get_local $32)
        )
       )
       (f64.store
        (get_local $39)
        (f64.sub
         (get_local $45)
         (get_local $36)
        )
       )
       (f64.store
        (get_local $23)
        (f64.add
         (get_local $40)
         (get_local $29)
        )
       )
       (f64.store
        (get_local $24)
        (f64.sub
         (get_local $44)
         (get_local $42)
        )
       )
       (set_local $4
        (i32.add
         (get_local $4)
         (i32.const 16)
        )
       )
       (set_local $0
        (i32.add
         (get_local $0)
         (get_local $13)
        )
       )
       (set_local $1
        (i32.add
         (get_local $1)
         (get_local $12)
        )
       )
       (set_local $2
        (i32.add
         (get_local $2)
         (get_local $11)
        )
       )
       (set_local $5
        (i32.add
         (get_local $5)
         (i32.const 2)
        )
       )
       (br $label$8)
      )
     )
     (set_local $18
      (i32.add
       (get_local $18)
       (get_local $14)
      )
     )
     (set_local $19
      (i32.add
       (get_local $19)
       (get_local $9)
      )
     )
     (br $label$6)
    )
   )
  )
 )
 (func $singleTransform2 (param $0 i32) (param $1 i32) (param $2 i32) (param $3 i32) (param $4 i32)
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
 (func $singleTransform4 (param $0 i32) (param $1 i32) (param $2 i32) (param $3 i32) (param $4 i32) (param $5 i32)
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
