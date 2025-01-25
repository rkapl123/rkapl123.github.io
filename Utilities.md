---
title: Utilities
description: Some VB/VBA/VBScript Utilities
---

# A VBA user defined function for getting non-intersecting range in Excel

Excel has two functions to retrieve sets of ranges, the union and the intersection of ranges. Unfortunately, the third interesting set, the non-intersecting parts of the involved ranges (all cells that do not share any common place), is a bit harder to retrieve. Below my approach that builds the complements of each range and utilizes excel to get the union of all complements' intersections with the respective other ranges.

```vb
Function NotIntersect(ParamArray theRanges()) As Range
    For Each theRange In theRanges
        Dim theComplement As Range
        Set theComplement = getComplement(theRange)
        For Each theOtherRange In theRanges
            If Not theOtherRange Is theRange Then
                If NotIntersect Is Nothing Then
                    Set NotIntersect = Intersect(theComplement, theOtherRange)
                Else
                    Set theIntersect = Intersect(theComplement, theOtherRange)
                    If Not theIntersect Is Nothing Then Set NotIntersect = Union(NotIntersect, theIntersect)
                End If
            End If
        Next
    Next
End Function

Function getComplement(theRange) As Range
Dim Complements As New Collection
    ' left complement
    If theRange.Column > 1 Then
        Set TopLeftCell_1 = Cells(1, 1)
        Set BottomRightCell_1 = Cells(ActiveSheet.Rows.Count, theRange.Column - 1)
        Complements.Add Range(TopLeftCell_1, BottomRightCell_1)
    End If
    ' upper complement
    If theRange.Row > 1 Then
        Set TopLeftCell_2 = Cells(1, theRange.Column)
        Set BottomRightCell_2 = Cells(theRange.Row - 1, theRange.Column + theRange.Columns.Count - 1)
        Complements.Add Range(TopLeftCell_2, BottomRightCell_2)
    End If
    ' right complement
    If theRange.Column + theRange.Columns.Count < ActiveSheet.Columns.Count Then
        Set TopLeftCell_3 = Cells(1, theRange.Column + theRange.Columns.Count)
        Set BottomRightCell_3 = Cells(ActiveSheet.Rows.Count, ActiveSheet.Columns.Count)
        Complements.Add Range(TopLeftCell_3, BottomRightCell_3)
    End If
    ' bottom complement
    If theRange.Row + theRange.Rows.Count < ActiveSheet.Rows.Count Then
        Set TopLeftCell_4 = Cells(theRange.Row + theRange.Rows.Count, theRange.Column)
        Set BottomRightCell_4 = Cells(ActiveSheet.Rows.Count, theRange.Column + theRange.Columns.Count - 1)
        Complements.Add Range(TopLeftCell_4, BottomRightCell_4)
    End If
    ' build the union of all complements
    For Each c In Complements
        If getComplement Is Nothing Then
            Set getComplement = c
        Else
            Set getComplement = Union(getComplement, c)
        End If
    Next
End Function


Sub test()
    Debug.Print NotIntersect(Range("$C$1:$D$24"), Range("$A$3:$J$12")).Address = "$A$3:$B$12,$E$3:$J$12,$C$1:$D$2,$C$13:$D$24"
    Debug.Print NotIntersect(Range("$C$3:$D$24"), Range("$A$3:$J$12")).Address = "$A$3:$B$12,$E$3:$J$12,$C$13:$D$24"
    Debug.Print NotIntersect(Range("$C$1:$D$24"), Range("$C$3:$J$12")).Address = "$E$3:$J$12,$C$1:$D$2,$C$13:$D$24"
    Debug.Print NotIntersect(Range("$C$1:$D$12"), Range("$A$3:$J$12")).Address = "$A$3:$B$12,$E$3:$J$12,$C$1:$D$2"
    Debug.Print NotIntersect(Range("$C$1:$D$24"), Range("$A$3:$D$12")).Address = "$A$3:$B$12,$C$1:$D$2,$C$13:$D$24"
    Debug.Print NotIntersect(Range("$C$3:$D$12"), Range("$A$3:$J$12")).Address = "$A$3:$B$12,$E$3:$J$12"
    Debug.Print NotIntersect(Range("$C$1:$D$24"), Range("$C$3:$D$12")).Address = "$C$1:$D$2,$C$13:$D$24"
    Debug.Print NotIntersect(Range("$C$1:$C$24"), Range("$A$3:$J$12")).Address = "$A$3:$B$12,$D$3:$J$12,$C$1:$C$2,$C$13:$C$24"
    Debug.Print NotIntersect(Range("$C$1:$D$24"), Range("$A$3:$J$3")).Address = "$A$3:$B$3,$E$3:$J$3,$C$1:$D$2,$C$4:$D$24"
    Debug.Print NotIntersect(Range("$A$1:$B$12"), Range("$A$3:$B$3")).Address = "$A$1:$B$2,$A$4:$B$12"
    Debug.Print NotIntersect(Range("$A$3:$J$12"), Range("$C$1:$D$24")).Address = "$C$1:$D$2,$C$13:$D$24,$A$3:$B$12,$E$3:$J$12"
    Debug.Print NotIntersect(Range("$A$3:$A$7"), Range("$A$7:$A$9")).Address = "$A$8:$A$9,$A$3:$A$6"
End Sub
```

# A nice VB script to get the title of the current desktop wallpaper

As I'm a fond user of beautiful landscape wallpapers and also like to know the location of these pictures, I always try to store the information in the title of these pictures.
From [what I've seen](https://techdows.com/2016/01/where-windows-10-themes-photos-were-taken.html) this is also done for several Windows 10 desktop themes.

Now, if there is a wallpaper displayed that I'm not really familiar with, I wanted a quick way get to this info. 
Following script, derived from raveren's [https://gist.github.com/raveren/ab475336cc69879a378b](https://gist.github.com/raveren/ab475336cc69879a378b) does this job quite properly, if there are no unicode characters in the path.
Put it in a vb-script file on the desktop or anywhere easily reachable and click it whenever you need this information!


```vb
Set Shell = CreateObject("WScript.Shell")

' change to TranscodedImageCache_001 for second monitor and so on
getTitleOfWallpaper("HKCU\Control Panel\Desktop\TranscodedImageCache_000")

Function getTitleOfWallpaper(regKey)
  ' decode the filename in the given registry storage
  arr = Shell.RegRead(regKey)
  a=arr
  fullPath = ""
  consequtiveZeroes = 0

  For I = 24 To Ubound(arr)
    if consequtiveZeroes > 1 then
      exit for
    end if

    a(I) = Cint(arr(I))

    if a(I) > 1 then
      fullPath = fullPath & Chr(a(I))
      consequtiveZeroes = 0
    else
      consequtiveZeroes = consequtiveZeroes + 1
    end if
  Next
  
  ' read the picture file from there
  TotalFile = readBinary(fullPath)
  
  ' grab the title from the file's meta information
  Dim oRe, oMatches
  Set oRe = New RegExp
  oRe.Pattern = "<dc:title><rdf:Alt .*?><rdf:li .*?>(.*?)</rdf:li></rdf:Alt>"
  Set oMatches = oRe.Execute(TotalFile)
  On Error Resume Next
  MsgBox(oMatches(0).SubMatches(0))
  if Err<>0 then MsgBox "No Title property found in current Wallpaper image !"
End Function

Function readBinary(strPath)
  Dim objStream, fso
  Set fso = CreateObject("Scripting.FileSystemObject")
  If not fso.FileExists(strPath) Then 
    MsgBox("File not found: " & strPath) 
    Exit Function
  End If
  Set objStream = CreateObject("ADODB.Stream")
  objStream.CharSet = "utf-8"
  objStream.Open
  objStream.LoadFromFile(strPath)
  readBinary = objStream.ReadText()
  objStream.Close
End Function
```

# Face-IDs for Office Versions >= 2010

Following Code was adapted from John D. Mclean's code for Excel <= 2003 and displays all Face-IDs available for command-bar buttons in the Add-Ins ribbon (this is a long list, change the 4891 (max. number for Office 2010) to your office version):

```vb
Option Explicit
Sub DisplayButtonFacesInGrid()
Const cbName = "FaceId"
Dim cBar As CommandBar, cBut As CommandBarControl
Dim r As Long, c As Integer, count As Integer

  count = 0
  Do                          'loop through all FaceIDs
    If count Mod 100 = 0 Then
        On Error Resume Next
        Application.CommandBars(count \ 100 & cbName).Delete
        On Error GoTo 0
        Set cBar = Application.CommandBars.Add    'create temporary ToolBar with one button
        With cBar
          .Name = count \ 100 & cbName
          .Top = count \ 100
          .Left = 0
          .Visible = True
          .RowIndex = count \ 100
        End With
    End If

    Set cBut = Application.CommandBars(count \ 100 & cbName).Controls.Add(Type:=msoControlButton)
    cBut.FaceId = count
    cBut.Caption = count
    count = count + 1
    Application.StatusBar = "Creating Button FaceIDs " & count
  Loop While count < 4891 '4890 seems to be the maximum FaceID #
  Application.StatusBar = ""
End Sub

' to get rid of all the command bars added to the Add-Ins ribbon, run the following procedure
Sub RemoveAddedCommandBars()
Const cbName = "FaceId"
Dim count As Integer

  count = 0
  Do                          'loop through all FaceIDs
    If count Mod 100 = 0 Then
        On Error Resume Next
        Application.CommandBars(count \ 100 & cbName).Delete
        On Error GoTo 0
    End If
    count = count + 1
  Loop While count < 4891 '4890 seems to be the maximum FaceID #
End Sub
```

# executing VB.NET dynamically

Using below method you can execute dynamically provided code, in order to execute C-Sharp code, replace "VisualBasic" with "CSharp" in the `Dim codeProvider As CodeDomProvider = CodeDomProvider.CreateProvider("VisualBasic")` assignment.

```vb
Imports Microsoft.VisualBasic
Imports System.CodeDom
Imports System.CodeDom.Compiler

Public Module Module1

    Public Sub runExampleScript()
        Dim script As String = "Public Class DummyClass" + vbCrLf +
        "Public Shared Function DoSomething(paramString As String) As String" + vbCrLf +
        "Return ""Hello World, you provided: "" + paramString " + vbCrLf +
        "End Function" + vbCrLf +
        "End Class"
        MsgBox(ExecuteScript(script))
    End Sub

    Public Function ExecuteScript(ByVal scripttext As String) As String
        Dim codeProvider As CodeDomProvider = CodeDomProvider.CreateProvider("VisualBasic")
        Dim params As New CompilerParameters With {
            .GenerateExecutable = False,
            .GenerateInMemory = True,
            .IncludeDebugInformation = False,
            .TreatWarningsAsErrors = False
        }
        ' add any required assemblies needed by the dynamic code here:
        'params.ReferencedAssemblies.Add("system.dll")
        'params.ReferencedAssemblies.Add("System.Windows.Forms.dll")
        Dim results As CompilerResults = codeProvider.CompileAssemblyFromSource(params, scripttext)
        If results.Errors.Count = 0 Then
            Dim methParams(0) As Object
            methParams(0) = ExcelDnaUtil.Application.ActiveCell.Text
            Return results.CompiledAssembly.GetType("DummyClass").GetMethod("DoSomething").Invoke(Nothing, methParams)
        Else
            Return Nothing
        End If
    End Function

End Module
```
