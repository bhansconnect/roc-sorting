app [main] { pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.10.0/vNe6s9hWzoTZtFmNkvEICPErI9ptji_ySjicO6CkucY.tar.br" }

import pf.Stdout
import pf.Task exposing [Task]
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

mergeSort : List _ -> List _
mergeSort = \ilist ->
    sortByTwos = \list ->
        len = List.len list
        loopi = \lst, i ->
            if i >= len then
                lst
            else
                lft = List.get lst (i - 1) |> Result.withDefault 0
                rgt = List.get lst i |> Result.withDefault 0
                if lft > rgt then
                    loopi (List.swap lst (i - 1) i) (i + 2)
                else
                    loopi lst (i + 2)
        loopi list 1
    copylst = \srclst, si, dstlst, di, num ->
        if num <= 0 then
            dstlst
        else
            sv = List.get srclst si |> Result.withDefault 0
            copylst
                srclst
                (si + 1)
                (List.set dstlst di sv)
                (di + 1)
                (num - 1)
    merge = \ilst, xi, xlmt, yi, ylmt, olst, oi ->
        if xi >= xlmt then
            copylst ilst yi olst oi (ylmt - yi)
        else if yi >= ylmt then
            copylst ilst xi olst oi (xlmt - xi)
        else
            x = List.get ilst xi |> Result.withDefault 0
            y = List.get ilst yi |> Result.withDefault 0
            if x <= y then
                merge ilst (xi + 1) xlmt yi ylmt (List.set olst oi x) (oi + 1)
            else
                merge ilst xi xlmt (yi + 1) ylmt (List.set olst oi y) (oi + 1)
    pairs = \srclst, dstlst, mrgsz ->
        len = List.len srclst
        loopi = \dlst, i ->
            if i >= len then
                dlst
            else if i + mrgsz >= len then
                copylst srclst i dlst i (len - i)
            else
                xlmt = i + mrgsz
                ylmt = Num.min len (xlmt + mrgsz)
                loopi (merge srclst i xlmt xlmt ylmt dlst i) ylmt
        loopi dstlst 0
    loop = \srclst, dstlst, lstsz ->
        len = List.len srclst
        if lstsz >= len then
            srclst
        else
            loop (pairs srclst dstlst lstsz) srclst (lstsz * 2)
    altlst = List.repeat 0 (List.len ilist)
    ilist |> sortByTwos |> loop altlst 2

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
    answrlst =
        tstlst |> mergeSort
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
