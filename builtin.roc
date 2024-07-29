app [main] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br" }

import pf.Stdout
import pf.Task
import pf.Utc exposing [now, deltaAsMillis]

cLIMIT : U64
cLIMIT = 1_000_000

RandSeed : (U64, U64)

initRandSeed : RandSeed
initRandSeed = (0x69B4C98CB8530805u64, 0xFED1DD3004688D68u64)

nextRandI64 : RandSeed -> (RandSeed, I64)
nextRandI64 = \r ->
    s0 = r.0
    s1 = r.1
    ns1 = Num.bitwiseXor s0 s1
    nr0 =
        Num.shiftLeftBy s0 55
        |> Num.bitwiseOr (Num.shiftRightZfBy s0 9)
        |> Num.bitwiseXor ns1
        |> Num.bitwiseXor (Num.shiftLeftBy ns1 14) # a, b
    nr1 = Num.shiftLeftBy ns1 36 |> Num.bitwiseOr (Num.shiftRightZfBy ns1 28) # c
    ((nr0, nr1), Num.intCast (Num.addWrap s0 s1))

buildList : U64 -> List I64
buildList = \size ->
    loopi = \lst, r, i ->
        if i >= size then
            lst
        else
            (nr, rv) = nextRandI64 r
            loopi (List.set lst i (Num.intCast rv)) nr (i + 1)
    List.repeat 0 size |> loopi initRandSeed 0

testSort : List _ -> Bool
testSort = \lst ->
    len = List.len lst
    loopi = \i ->
        if i >= len then
            Bool.true
        else
            f = List.get lst (i - 1) |> Result.withDefault 0
            s = List.get lst i |> Result.withDefault 0
            if s < f then Bool.false else loopi (i + 1)
    loopi 1

main =
    tstlst = buildList cLIMIT
    start = now!
    answrlst = tstlst |> List.sortWith Num.compare
    stop = now!
    elpsdStr = deltaAsMillis start stop |> Num.toStr
    Stdout.line!
        (
            if testSort answrlst then
                "List sorted correctly!"
            else
                "Failure in sorting list!!!"
        )
    Stdout.line! "Sorted $(cLIMIT |> Num.toStr) integers in $(elpsdStr) milliseconds."
