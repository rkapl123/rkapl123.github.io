[![License](https://img.shields.io/github/license/rkapl123/rkapl123.github.io.svg)](https://github.com/rkapl123/rkapl123.github.io/blob/master/LICENSE)

[Github Overview](https://github.com/rkapl123), [All repositories](https://github.com/rkapl123?tab=repositories)

## Quantlib fully annotated source documentation
As a frequent user of [Quantlib](http://quantlib.org), I found that I needed to read more than the official reference documentation provided on the official website.
So I decided to tweak the doxygen config to produce a fully annotated source documentation of quantlib including collaboration diagrams, call/caller diagrams and a working search box: [https://rkapl123.github.io/QLAnnotatedSource](https://rkapl123.github.io/QLAnnotatedSource)

## ORE and OreControl
I'm using the Opensource Risk Engine ([ORE](http://www.opensourcerisk.org), based on Quantlib), my intention is to provide Tools for easier interaction with/integration of the Opensource Risk Engine. Following goals are envisaged:

- [ ]  easy starting from Excel (OreAddin),
- [x]  loading and migrating ORE data from/to a Database (OreDB)

This will be / is available here: [OreControl]( https://rkapl123.github.io/OreControl/)

Following Article summarizes the [Enhancement of ORE with new instruments](Enhancing_ORE.md).

Also, a fully annotated source documentation of ORE's three libraries is available here: [https://rkapl123.github.io/OREAnnotatedSource](https://rkapl123.github.io/OREAnnotatedSource)

### Tips for building ORE

First, it is important to retrieve the QuantLib compatible with the chosen ORE version (e.g. 1.8.10), the safest way is usually NOT to pull the current master but rather to switch to the corresponding tag in the branch/tag switch (e.g. v.1.8.10.0), then download the zip with the <> code download button, next go to the QuantLib version that this ORE Version was built with on the external submodule link (e.g. QuantLib @ c235cda) and download the zip with the <> code download button there as well. The last step is to integrate the downloaded QuantLib source into the ORE source tree (QuantLib folder).

If you rather like to check out directly from the source, then following git commands should be sufficient:

```
git clone https://github.com/opensourcerisk/engine.git oredir
cd oredir
git checkout tags/v1.8.10.0 (or any other tag)
git submodule init
git submodule update
cd QuantLib
git checkout c235cdabbb34beaae601700092b9abfefdd7fc6a (commit number of the associated/patched Quantlib version)
```

The commit on the last line for the QuantLib submodule could either be communicated along with the release or can always be found on the git code page when having selected the release tag in the branch/tag switch.

Another challenge is to get the correct boost binary for the Visual Studio version (from [sourceforge boost-binaries](https://sourceforge.net/projects/boost/files/boost-binaries/)), to find the appropriate toolset version compatible with visual studio a good reference is [Microsoft Visual C++ Internal_version_numbering](https://en.wikipedia.org/wiki/Microsoft_Visual_C%2B%2B#Internal_version_numbering), the runtime library version is in the last column, the toolset version (as needed by the linker looking up the libraries) can be obtained by taking the first three digits of the runtime library version and dropping the decimal point, e.g. '143' for all Visual Studio 2022 versions.

Since boost 1_78, there is a problem with the application binary interface, it's important to add a target_compile_definition that restricts the used version to 0x0600 after the add_executable of the orea-test-suite in $ORE/OREAnalytics/test/CMakeLists.txt:

```
add_executable(orea-test-suite ${OREAnalytics-Test_SRC})
target_link_libraries(orea-test-suite ${QL_LIB_NAME})
target_link_libraries(orea-test-suite ${QLE_LIB_NAME})
target_link_libraries(orea-test-suite ${ORED_LIB_NAME})
target_link_libraries(orea-test-suite ${OREA_LIB_NAME})
target_link_libraries(orea-test-suite ${Boost_LIBRARIES} ${RT_LIBRARY})

target_compile_definitions(orea-test-suite PUBLIC BOOST_USE_WINAPI_VERSION=0x0600)
```


## DBAddin
DBAddin is an ExcelDNA-based Addin, providing two main functionalities and a definition Tool:

- Userdefined functions (DBFuncs) for database querying. This is opposed to the integrated MS-Query, which is stored statically in the worksheet and has serious limitations in terms of querying possibilities and constructing parameterized queries (MS-Query allows parameterized queries only for simple queries that can be displayed graphically). Further useful functions for working with database data are included as well.
- Modify Database data in Excel using so called "DBModifiers", which are either datatables that enable you to manipulate database data directly inside Excel (DBMappers, similar to MS Access table view). Another method are DBActions, allowing DML code to be issued (insert/update/delete) and finally DBSequences that put DBMappers and DBActions together, additionally allowing refreshing of DB functions and defining a transactional context (Begin and Commit/Rollback).
- As a useful "leftover" of the old DBSheets (DBSheets definitions are now used for DBMappers, additionally defining foreign key lookup resolutions for foreign keys, so columns containing foreign IDs can be edited more easily), legacy DBSheet definitions can be edited/created with the "Create DBSheet definition" tool and afterwards assigned to Worksheets with the "Assign DBSheet definition" tool.

[Documentation](https://rkapl123.github.io/DBAddin/)  
[Slideshow](https://rkapl123.github.io/dbaddinslides/)

## ScriptAddin
ScriptAddin is a simple ExcelDNA-based Add-in for handling scripts (R, Python, Perl, whatever you configure) from Excel, storing input objects (scalars/vectors/matrices)
and retrieving result objects (scalars/vectors/matrices) as text files (currently restricted to tab separated).
Graphics are retrieved from produced png files into Excel to be displayed as diagrams.  
This is an extension and replacement for the now obsolete RAddin.  
[Documentation](https://rkapl123.github.io/ScriptAddin)

## ExchangeSetOOF
ExchangeSetOOF provides programmatic setting of automatic replies (out of office) in an exchange environment, based on calendar appointments having an "away" status.

ExchangeSetOOF logs in to the currently logged in users account (using EWS AutoDiscover with users account Emailaddress using System.DirectoryServices.AccountManagement) and searches the appointments between today and the next business day (based on configured holidays) for appointments being set "away".

If any such appointment is found, ExchangeSetOOF replaces the template's date placeholder with the respective end date and (if wanted) also start date. The languages used for the replacement of the date placeholders are configurable (hardcoded are german and english). The automatic reply (out of office) is being scheduled to start from the Start Date of the OOF appointment and end on the End Date of the OOF appointment.

[Documentation and download](https://rkapl123.github.io/ExchangeSetOOF)

## DatePicker

After struggling to find a replacement for the MSCOMCT2 based Datepicker, I finally decided to wrap the .NET MonthCalendar into a nice and small Add-In that offers this functionality to VBA: [Repository](https://github.com/rkapl123/DatePicker)  
It can also be used directly from the Ribbon to insert date values into cells.

## CmdLogAddin
ExcelDNA-based Addin that allows you to parse Excel's Cmdline and start any Macro that is contained either inside the started Workbook, a startup loaded Addin or outside.  

Additionally, a logging possibility is provided by retrieving a logger object in VBA (set log = CreateObject("LogAddin.Logger")) and using this to
provide logging messages using 5 levels:  

- log.Fatal (like log.Error but quits Excel)
- log.Error (also can send Mails, if desired)
- log.Warn
- log.Info
- log.Debug

[Documentation and download](https://rkapl123.github.io/CmdLogAddin)

## Scouts administration helper

As a member of a local scouting group and being responsible for the member registration/administration, I've created a few tools to produce invoice- and other mailings to the members as well as registering/updating member information from our WordPress Form based pages. This however only works in conjunction with the registration tool iGrins from the Scouts of Lower Austria: [https://www.noe-pfadfinder.at/igrins](https://www.noe-pfadfinder.at/igrins)  

If you still think this is useful, read the [documentation](https://rkapl123.github.io/PfadfinderSchreiben).

## Some History
After more than 30 years, I decided to revitalize some of my first projects to contribute to the IT-Nostalgia. The story and its results can be found here, in [History](History.md).

## Useful Tips/Tools from other people
Following are links to pages with useful information or tools I've found during my endeavors:

### Creating Excel Add-Ins with Excel-DNA
For creating Excel Addins/Solutions, this is a tool/library you simply can't bypass: [http://excel-dna.net/](http://excel-dna.net/)
It's very easy to start for all that have some experience in VBA-Programming and - for an open source library - it has a lot of [documentation](https://docs.excel-dna.net/).

### Parsing Excel Data in Perl with Data-XLSX-Parser
A really nice, fast and memory efficient parser for new-format Excel (xlsx) files by Daisuke Murase (original author)/Masatoshi Kawazoe (active maintainer, [CPAN-Module](https://metacpan.org/pod/Data::XLSX::Parser)).

### Log-viewing with LogJoint
After quite a lot of searching, I finally found a very helpful log viewer that displays multiple logs (also rotated historic logs) side-by-side with a nice overview by thread, filtering and lots of other features: [LogJoint](https://github.com/sergey-su/logjoint).
Can be used for all kinds of logs, if your type is not built in, then simply roll your own format using regular expressions.

### SQL Server XML Queries
With examples from the ORE DB project: [SQLServerXML](SQLServerXML.md)


### A nice VB script to get the title of the current desktop wallpaper

As I'm a fond user of beautiful landscape wallpapers and also like to know the location of these pictures, I always try to store the information in the title of these pictures.
From [what I've seen](https://techdows.com/2016/01/where-windows-10-themes-photos-were-taken.html) this is also done for several Windows 10 desktop themes.

Now, if there is a wallpaper displayed that I'm not really familiar with, I wanted a quick way get to this info. 
Following script, derived from raveren's [https://gist.github.com/raveren/ab475336cc69879a378b](https://gist.github.com/raveren/ab475336cc69879a378b) does this job quite properly, if there are no unicode characters in the path.
Put it in a vbs file on the desktop or anywhere easily reachable and click it whenever you need this information!


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

### Face-IDs for Office Versions >= 2010
Following Code was adapted from John D. Mclean's code for Excel <= 2003 and displays all Face-IDs available for commandbar buttons in the Add-Ins ribbon (this is a long list, change the 4891 (max. number for Office 2010) to your office version):

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

### executing VB.NET dynamically

Using below method you can execute dynamically provided code, in order to execute C-Sharp code, replace "VisualBasic" with "CSharp" in the `Dim codeProvider As CodeDomProvider = CodeDomProvider.CreateProvider("VisualBasic")` assignmenent.

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