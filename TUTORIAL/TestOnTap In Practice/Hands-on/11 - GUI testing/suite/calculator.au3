; Hack to test the calculator

ConsoleWrite("1..3" & @CRLF)

Run("calc.exe")

WinWaitActive("Kalkylatorn")

ConsoleWrite("ok 1 - Started calculator" & @CRLF)
Sleep(1000)

Local $a = Random(1, 10, 1)
Local $b = Random(1, 10, 1)
Local $c = Random(1, 10, 1)

Local $expected = ($a + $b) * $c
ConsoleWrite("# Expected computation: (" & $a & " + " & $b & ") * " & $c & " = " & $expected & @CRLF)

AutoItSetOption("SendKeyDelay", 400)

Send($a & "{+}" & $b & "{=}{*}" & $c & "{=}^c")
Local $calculated = ClipGet();

If $calculated <> $expected Then
	ConsoleWrite("not ")
EndIf
ConsoleWrite("ok 2 - checked expected (" & $expected & ") and calculated (" & $calculated & ") value" & @CRLF)

WinClose("Kalkylatorn")
WinWaitClose("Kalkylatorn")

ConsoleWrite("ok 3 - Ended calculator" & @CRLF)
