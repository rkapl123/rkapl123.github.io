[![License](https://img.shields.io/github/license/rkapl123/rkapl123.github.io.svg)](https://github.com/rkapl123/rkapl123.github.io/blob/master/LICENSE)

[Github Overview](https://github.com/rkapl123), [All repositories](https://github.com/rkapl123?tab=repositories)

## Quantlib fully annotated source documentation
As a frequent user of [Quantlib](http://quantlib.org), I found that I needed to read more than the official reference documentation provided on the official website.
So I decided to tweak the doxygen config to produce a fully annotated source documentation of quantlib including collaboration diagrams, call/caller diagrams and a working search box: [https://rkapl123.github.io/QLAnnotatedSource](https://rkapl123.github.io/QLAnnotatedSource)

## ORE and OreControl
I'm using the Opensource Risk Engine ([ORE](http://www.opensourcerisk.org), based on Quantlib), my intention is to provide Tools for easier interaction with/integration of the Opensource Risk Engine. Following three goals are envisaged:

- [ ]  easy starting from Excel (OreAddin),
- [x]  loading and migrating ORE data from/to a Database (OreDB)
- [ ]  a Service wrapper (OreMgr) and a Database (OreDB) to run an ORE-Server.

All this will be available here: [OreControl]( https://rkapl123.github.io/OreControl/)

Following Article summarizes the [Enhancement of ORE with new instruments](Enhancing_ORE.md)

## DBAddin
DBAddin is an ExcelDNA-based Addin, providing two main functionalities and a definition Tool:

- Userdefined functions (DBFuncs) for database querying. This is opposed to the integrated MS-Query, which is stored statically in the worksheet and has serious limitations in terms of querying possibilities and constructing parameterized queries (MS-Query allows parameterized queries only for simple queries that can be displayed graphically). Further useful functions for working with database data are included as well.
- Modify Database data in Excel using so called "DBModifiers", which are either datatables that enable you to manipulate database data directly inside Excel (DBMappers, similar to MS Access table view). Another method are DBActions, allowing DML code to be issued (insert/update/delete) and finally DBSequences that put DBMappers and DBActions together, additionally allowing refreshing of DB functions and defining a transactional context (Begin and Commit/Rollback).
- As a useful "leftover" of the old DBSheets (DBSheets definitions are now used for DBMappers, additionally defining foreign key lookup resolutions for foreign keys, so columns containing foreign IDs can be edited more easily), legacy DBSheet definitions can be edited/created with the "Create DBSheet definition" tool and afterwards assigned to Worksheets with the "Assign DBSheet definition" tool.

Documentation: [https://rkapl123.github.io/DBAddin/](https://rkapl123.github.io/DBAddin/)  
Slideshow: [https://rkapl123.github.io/dbaddinslides/](https://rkapl123.github.io/dbaddinslides/)

## ScriptAddin
ScriptAddin is a simple ExcelDNA-based Add-in for handling scripts (R, Python, Perl, whatever you configure) from Excel, storing input objects (scalars/vectors/matrices)
and retrieving result objects (scalars/vectors/matrices) as text files (currently restricted to tab separated).
Graphics are retrieved from produced png files into Excel to be displayed as diagrams.  
This is an extension and replacement for the now obsolete RAddin.  
Documentation: [https://rkapl123.github.io/ScriptAddin](https://rkapl123.github.io/ScriptAddin)

## ExchangeSetOOF
ExchangeSetOOF provides programmatic setting of automatic replies (out of office) in an exchange environment, based on OOF appointments.

ExchangeSetOOF logs in to the currently logged in users account (using EWS AutoDiscover with users account Emailaddress using System.DirectoryServices.AccountManagement) and searches the appointments between today and the next business day (based on only austrian holidays, this is currently hardcoded in function isHoliday) for appointments being set "away".

If any such appointment is found, ExchangeSetOOF replaces the template's date placeholder with the respective end date and (if wanted) also start date. The languages used for the replacement of the date placeholders are (hardcoded) german and english (easily changed at the top of the program). The automatic reply (out of office) is being scheduled to start from the Start Date of the OOF appointment and end on the End Date of the OOF appointment.

Documentation and download available here: [https://rkapl123.github.io/ExchangeSetOOF](https://rkapl123.github.io/ExchangeSetOOF)

## DatePicker

After struggling to find a replacement for the MSCOMCT2 based Datepicker, I finally decided to wrap the .NET MonthCalendar into a nice and small Add-In that offers this functionality to VBA: [https://github.com/rkapl123/DatePicker](https://github.com/rkapl123/DatePicker)  
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

Documentation and download available here: [https://rkapl123.github.io/CmdLogAddin](https://rkapl123.github.io/CmdLogAddin)

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
