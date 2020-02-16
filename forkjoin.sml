
structure ForkJoin : FORK_JOIN =
struct
  fun unfoldr f e =
    case f e
      of SOME(x, e') => x::unfoldr f e'
       | NONE => []

  fun parfor grain (begin,limit) f =
    let val ths = unfoldr (fn i =>
                  if i < limit
                  then
                    let
                      fun go j = if j < i+grain
                                 then (f j; go (j+1))
                                 else ()
                    in
                      SOME (Myth.Thread.create (fn ()=> (go i;0)), i + grain)
                    end
                  else
                    NONE)
                  begin
    in
      app (ignore o Myth.Thread.join) ths
    end
end

