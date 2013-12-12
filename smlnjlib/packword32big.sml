
structure PackWord32Big :> PACK_WORD =
struct
  structure V = Word8Vector
  structure A = Word8Array
  infix << >>
  val op<< = Word32.<<
  val op>> = Word32.>>

  val bytesPerElem = 4
  val isBigEndian  = true

  fun extract4 length sub (vec,i) =
    if i < 0 orelse length vec < bytesPerElem * (i+1)
    then raise Subscript
    else
      (sub(vec, bytesPerElem*i+0)
      ,sub(vec, bytesPerElem*i+1)
      ,sub(vec, bytesPerElem*i+2)
      ,sub(vec, bytesPerElem*i+3))

  fun subVec (vec,i) =
    let
      val (w0,w1,w2,w3) = extract4 V.length V.sub (vec, i)
    in
      Word32.orb (Word8.toLarge w0<<0w24,
      Word32.orb (Word8.toLarge w1<<0w16,
      Word32.orb (Word8.toLarge w2<<0w08,
                  Word8.toLarge w3<<0w00)))
    end

  val subVecX = subVec

  fun subArr (arr,i) =
    let
      val (w0,w1,w2,w3) = extract4 A.length A.sub (arr, i)
    in
      Word32.orb (Word8.toLarge w0<<0w24,
      Word32.orb (Word8.toLarge w1<<0w16,
      Word32.orb (Word8.toLarge w2<<0w08,
                  Word8.toLarge w3<<0w00)))
    end

  val subArrX = subArr

  fun update (arr, i, w) =
    if i < 0 orelse A.length arr < bytesPerElem * (i+1)
    then raise Subscript
    else
      (A.update (arr, bytesPerElem*i+0, Word8.fromLarge (w >> 0w24));
       A.update (arr, bytesPerElem*i+1, Word8.fromLarge (w >> 0w16));
       A.update (arr, bytesPerElem*i+2, Word8.fromLarge (w >> 0w08));
       A.update (arr, bytesPerElem*i+3, Word8.fromLarge (w >> 0w00)))
end

