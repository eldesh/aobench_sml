(**
 * SML/NJ
 * $ ml-build aobench.cm AObench.main aobench-image
 * $ sml @SMLload=aobench-image.x86-cygwin
 *
 * MLton
 * $ mlton aobench.mlb
 *
 * SML#
 * $ make -f makefile-smlsharp
 *)
structure AObench :
sig
  val main : (string * string list) -> int
end
=
struct
  type range = { begin : int, limit : int, step : int -> int }

  fun for {begin,limit,step} f =
    let
      fun for' i = if i<limit
                   then
                     (f i;
                      for' (step i))
                   else
                     ()
    in
      for' begin
    end

  fun succ x = x + 1

  val (WIDTH, HEIGHT) = (256, 256)
  val (NSUBSAMPLES, NAO_SAMPLES) = (2, 8)
  val img = Word8Array.array (WIDTH * HEIGHT * 3, 0w0)

  type vec = { x : real, y : real, z : real }
  type sphere = { center : vec
                , radius : real }
  type plane = { p : vec, n : vec }
  type 'a triple = 'a * 'a * 'a
  type ray = { org : vec, dir : vec }

  type isect = { t : real
               , p : vec
               , n : vec
               , hit : bool
               }

  fun vec_to_string {x,y,z} =
    let
      val real = Real.fmt (StringCvt.FIX (SOME 3))
    in
      concat["vec={", real x, ",", real y, ",", real z, "}"]
    end

  fun ray_to_string {org, dir} =
    concat ["ray=(", vec_to_string org, ",", vec_to_string dir, ")"]

  fun isect_to_string {t,p,n,hit} =
    let
      val real = Real.fmt (StringCvt.FIX (SOME 3))
    in
      concat["isect{t=", real t, " p=", vec_to_string p, ", n=", vec_to_string n, " hit=", Bool.toString hit, "}"]
    end

  fun init_scene () : sphere triple * plane =
    let
      val ss = ({ center={ x= ~2.0, y= 0.0, z= ~3.5 }, radius= 0.5 }
               ,{ center={ x= ~0.5, y= 0.0, z= ~3.0 }, radius= 0.5 }
               ,{ center={ x=  1.0, y= 0.0, z= ~2.2 }, radius= 0.5 }
               )
      val plane = { p={ x= 0.0, y= ~0.5, z= 0.0 }
                  , n={ x= 0.0, y=  1.0, z= 0.0 }
                  }
    in
      (ss, plane)
    end

  infix 7 <*>
  fun (v0:vec) <*> (v1:vec) : real =
    (#x v0 * #x v1) + (#y v0 * #y v1) + (#z v0 * #z v1)

  fun vcross (v0:vec, v1:vec) : vec =
    { x= #y v0 * #z v1 - #z v0 * #y v1
    , y= #z v0 * #x v1 - #x v0 * #z v1
    , z= #x v0 * #y v1 - #y v0 * #x v1
    }

  fun vnormalize (c as {x,y,z}:vec) =
    let
      val length = Math.sqrt (c <*> c)
    in
      if abs length > 1.0e~17
      then
        { x= x / length
        , y= y / length
        , z= z / length
        }
      else
        c
    end

  fun ray_sphere_intersect isect ({org,dir}:ray) ({center,radius}:sphere) =
    let
      val rs = { x= #x org - #x center
               , y= #y org - #y center
               , z= #z org - #z center
               }
      val B = rs <*> dir
      val C = rs <*> rs - radius * radius
      val D = B * B - C
    in
      if D > 0.0
      then
        let val t = ~B - Math.sqrt D
        in
          if t > 0.0 andalso t < #t isect
          then
            let
              val p = { x= #x org + #x dir * t
                      , y= #y org + #y dir * t
                      , z= #z org + #z dir * t }
              val n = { x= #x p - #x center
                      , y= #y p - #y center
                      , z= #z p - #z center }
            in
                { t= t
                , p= p
                , n= vnormalize n
                , hit= true
                }
            end
          else
            isect
        end
      else
        isect
    end

  fun ray_plane_intersect isect ({dir,org}:ray) ({n,p}:plane) =
    let
      val d = Real.~ (p <*> n)
      val v = dir <*> n
    in
      if abs v < 1.0e~17 then isect
      else
        let
          val t = Real.~ ((org <*> n) + d) / v
        in
          if t > 0.0 andalso t < #t isect
          then
            { t= t
            , p= { x = #x org + #x dir * t
                 , y = #y org + #y dir * t
                 , z = #z org + #z dir * t }
            , n= n
            , hit= true
            }
          else
            isect
        end
    end

  fun orthoBasis (n as {x,y,z}) =
    let
      val basis2 = n
      val basis1 = if x < 0.6 andalso x > ~0.6 then
                     { x= 1.0, y= 0.0, z= 0.0 }
                   else if y < 0.6 andalso y > ~0.6 then
                     { x= 0.0, y= 1.0, z= 0.0 }
                   else if z < 0.6 andalso z > ~0.6 then
                     { x= 0.0, y= 0.0, z= 1.0 }
                   else
                     { x= 1.0, y= 0.0, z= 0.0 }
      val basis0 = vnormalize (vcross (basis1, basis2))
      val basis1 = vnormalize (vcross (basis2, basis0))
    in
      (basis0, basis1, basis2)
    end

  (* smlnj-lib *)
  local
    val rand = Random.rand (48271, valOf Int.maxInt)
  in
  fun drand48 () = Random.randReal rand
  end

  fun ambient_occlusion ({p,n,...}:isect) (spheres:sphere triple) plane =
    let
      val ntheta = NAO_SAMPLES
      val nphi   = NAO_SAMPLES
      val eps = 0.0001
      val p = { x= #x p + eps * #x n
              , y= #y p + eps * #y n
              , z= #z p + eps * #z n
              }
      val (basis0, basis1, basis2) = orthoBasis n
      val occlusion = ref 0.0
    in
      for {begin=0, limit=ntheta, step=succ} (fn j=>
        for {begin=0, limit=nphi, step=succ} (fn i=>
          let
            val theta = Math.sqrt(drand48())
            val phi   = 2.0 * Math.pi * drand48()
            val (x,y,z) = ( (Math.cos phi) * theta
                          , (Math.sin phi) * theta
                          , Math.sqrt (1.0 - theta * theta))
            val rx = x * (#x basis0) + y * (#x basis1) + z * (#x basis2)
            val ry = x * (#y basis0) + y * (#y basis1) + z * (#y basis2)
            val rz = x * (#z basis0) + y * (#z basis1) + z * (#z basis2)

            val zero = { x=0.0, y=0.0, z=0.0 }
            val ray = { org= p, dir= { x= rx, y= ry, z= rz } }
            val occIsect = { t= 1.0e17, p=zero, n=zero, hit= false }
            val occIsect = ray_sphere_intersect occIsect ray (#1 spheres)
            val occIsect = ray_sphere_intersect occIsect ray (#2 spheres)
            val occIsect = ray_sphere_intersect occIsect ray (#3 spheres)
            val occIsect = ray_plane_intersect occIsect ray plane
          in
            occlusion := !occlusion + (if #hit occIsect then 1.0 else 0.0)
          end
        ));
      let val occlusion = (real (ntheta * nphi) - !occlusion)
                        / real (ntheta * nphi)
      in
        { x=occlusion, y=occlusion, z=occlusion }
      end
    end

  fun clamp f =
    let val i = Real.floor (f * 255.5)
    in
      Word8.fromInt (Int.min (255, Int.max (i, 0)))
    end

  fun render img w h nsubsamples (spheres:sphere triple) plane =
    let
      val fimg = RealArray.array(w*h*3, 0.0)
    in
      for {begin=0, limit=h, step=succ} (fn y=>
        for {begin=0, limit=w, step=succ} (fn x=>
        (
          for {begin=0, limit=nsubsamples, step=succ} (fn v=>
            for {begin=0, limit=nsubsamples, step=succ} (fn u=>
              let
                val zero = { x=0.0, y=0.0, z= 0.0 }
                val px =  (real x + (real u / real nsubsamples) - (real w/2.0)) / (real w/2.0)
                val py = ~(real y + (real v / real nsubsamples) - (real h/2.0)) / (real h/2.0)
                val ray = { org=zero
                          , dir=vnormalize { x=px, y=py, z= ~1.0 }
                          }
                val isect = { t= 1.0e17, p=zero, n=zero, hit= false }
                val isect = ray_sphere_intersect isect ray (#1 spheres)
                val isect = ray_sphere_intersect isect ray (#2 spheres)
                val isect = ray_sphere_intersect isect ray (#3 spheres)
                val isect = ray_plane_intersect  isect ray plane
              in
                if #hit isect
                then
                  let
                    val col = ambient_occlusion isect spheres plane
                    val real = Real.fmt (StringCvt.FIX (SOME 3))
                  in
                    RealArray.update (fimg, 3*(y*w+x)+0, RealArray.sub(fimg, 3*(y*w+x)+0) + #x col);
                    RealArray.update (fimg, 3*(y*w+x)+1, RealArray.sub(fimg, 3*(y*w+x)+1) + #y col);
                    RealArray.update (fimg, 3*(y*w+x)+2, RealArray.sub(fimg, 3*(y*w+x)+2) + #z col)
                  end
                else
                  ()
              end
            ));
          RealArray.update (fimg, 3*(y*w+x)+0, RealArray.sub(fimg, 3*(y*w+x)+0) / real (nsubsamples * nsubsamples));
          RealArray.update (fimg, 3*(y*w+x)+1, RealArray.sub(fimg, 3*(y*w+x)+1) / real (nsubsamples * nsubsamples));
          RealArray.update (fimg, 3*(y*w+x)+2, RealArray.sub(fimg, 3*(y*w+x)+2) / real (nsubsamples * nsubsamples));

          Word8Array.update (img, 3*(y*w+x)+0, clamp (RealArray.sub(fimg, 3*(y*w+x)+0)));
          Word8Array.update (img, 3*(y*w+x)+1, clamp (RealArray.sub(fimg, 3*(y*w+x)+1)));
          Word8Array.update (img, 3*(y*w+x)+2, clamp (RealArray.sub(fimg, 3*(y*w+x)+2)))
        ))
      )
    end

  fun saveppm fname w h img =
    let
      val fp = BinIO.openOut fname
      fun write_str fp ss = Substring.app (fn c=> BinIO.output1 (fp, Word8.fromInt (ord c))) (Substring.full ss)
    in
      write_str fp "P6\n";
      write_str fp (Int.toString w^" "^Int.toString h^"\n");
      write_str fp "255\n";
      BinIO.output (fp, Word8Array.vector img);
      BinIO.closeOut fp
    end

  fun main (name,args) =
    let
      val _ = print "init_scene...\n"
      val (spheres,plane) = init_scene()
    in
      print "rendering...\n";
      render img WIDTH HEIGHT NSUBSAMPLES spheres plane;
      saveppm 
        (case args of file::_ => file | _=> "aosml.ppm")
        WIDTH HEIGHT img;
      0
    end
end

