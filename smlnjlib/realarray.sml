
structure RealArray : MONO_ARRAY =
struct
  open Array
  type array = real array
  type elem  = real
  type vector = real vector
end

