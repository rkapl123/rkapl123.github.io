[![License](https://img.shields.io/github/license/rkapl123/rkapl123.github.io.svg)](https://github.com/rkapl123/rkapl123.github.io/blob/master/LICENSE)

All repositories: [https://github.com/rkapl123](https://github.com/rkapl123)

## Quantlib fully annotated source documentation

As a frequent user of [Quantlib](http://quantlib.org), I found that I needed to read more than the official reference documentation provided on the official website. 
So I decided to tweak the doxygen config to produce a fully annotated source documentation of quantlib including collaboration diagrams, call/caller diagrams and a working search box: [https://rkapl123.github.io/QLAnnotatedSource](https://rkapl123.github.io/QLAnnotatedSource)

## ORE and OreControl

I'm using the Opensource Risk Engine ([ORE](http://www.opensourcerisk.org), based on Quantlib), my intention is to provide Tools for easier interaction with/integration of the Opensource Risk Engine. Following three goals are envisaged:

- [ ]  easy starting from Excel (OreAddin in conjunction with OreMgr),
- [x]  loading and migrating ORE data from/to a Database (OreDB)
- [ ]  a SWIG wrapper (OreMgr) to allow starting ORE from .NET and other environments.

All this will be available here: [https://rkapl123.github.io/OreControl/]( https://rkapl123.github.io/OreControl/)

Following Article summarizes the [Enhancement of ORE with new instruments](Enhancing_ORE.md)

## DBAddin

DBAddin (the current working version being a legacy VB6 COM Addin) is an Excel-Addin, providing two main functions:

- Userdefined functions (DBFuncs) for database querying. This is opposed to the integrated MS-Query, which is stored statically in the worksheet and has serious limitations in terms of querying possibilities and constructing parameterized queries (MS-Query allows parameterized queries only for simple queries that can be displayed graphically). Also included is a possibility for filling "data bound" controls (ComboBoxes and Listboxes) with data from queries. Further useful functions for working with database data are included as well.

- Edit Database data directly in Excel using so called "DBSheets", which are special Excel worksheets that enable you to manipulate database data directly inside Excel (similar to MS Access table view). In DBSheets you can define a foreign key lookup resolution for foreign keys, so columns containing foreign IDs can be edited more easily. Another feature is the "jumping" to a referenced record in a foreign dependent table, if it's defined as a DBSheet in the same Workbook.

A small, but useful additional database filling and updating tool is the "Mapper", which you can use to send an Excel range to the Database, updating/inserting the content into the table(s) given as arguments.

DBAddin is still hosted on [https://sourceforge.net/projects/dbaddin](https://sourceforge.net/projects/dbaddin), to get the latest version download a tarball with the [snapshot facility in sourceforge](https://sourceforge.net/p/dbaddin/code/HEAD/tarball).

To install this, run dbaddin-code-2/install/install.cmd as administrator. To configure your environment, edit dbaddin-code-2/install/DBAddinSettings.reg before.

The full documentation of DBAddin is available online at [http://dbaddin.sourceforge.net/HelpFrameset.htm](http://dbaddin.sourceforge.net/HelpFrameset.htm)

I'm in the process of rewriting this as a Excel-DNA Based .NET Addin, being available at [https://github.com/rkapl123/DBAddin](https://github.com/rkapl123/DBAddin).

## RAddin

Raddin is a simple Excel-DNA based Add-in for handling R-scripts from Excel via shell or RdotNet, storing input objects (scalars/vectors/matrices)
and retrieving result objects (scalars/vectors/matrices) as text files (currently restricted to tab separated) or RdotNet objects.
Graphics are retrieved from produced png files into Excel to be displayed as diagrams.  
For the full documentation see: [https://rkapl123.github.io/RAddin](https://rkapl123.github.io/RAddin)

## ExchangeSetOOF

ExchangeSetOOF provides programmatic setting of automatic replies (out of office) in an exchange environment, based on OOF appointments.

ExchangeSetOOF logs in to the currently logged in users account (using EWS AutoDiscover with users account Emailaddress using System.DirectoryServices.AccountManagement) and searches the appointments between today and the next business day (based on only austrian holidays, this is currently hardcoded in function isHoliday) for appointments being set "away".

If any such appointment is found, ExchangeSetOOF replaces the template's date placeholder with the respective end date and (if wanted) also start date. The languages used for the replacement of the date placeholders are (hardcoded) german and english (easily changed at the top of the program). The automatic reply (out of office) is being scheduled to start from the Start Date of the OOF appointment and end on the End Date of the OOF appointment.

Documentation and download available here: [https://rkapl123.github.io/ExchangeSetOOF](https://rkapl123.github.io/ExchangeSetOOF)

## CmdLogAddin

Excel Addin that allows you to parse Excel's Cmdline and start any Macro that is contained either inside the started Workbook, a startup loaded Addin or outside.  

Additionally, a logging possibility is provided by retrieving a logger object in VBA (set log = CreateObject("LogAddin.Logger")) and using this to
provide logging messages using 5 levels:  

- log.Fatal (like log.Error but quits Excel)
- log.Error (also can send Mails, if desired)
- log.Warn
- log.Info
- log.Debug

Documentation and download available here: [https://rkapl123.github.io/CmdLogAddin](https://rkapl123.github.io/CmdLogAddin)

The old versions of the Cmd Following Addins are still available (only for 32-bit Office installations due to VB6/COM implementation):  

### CMD-Line parser Add-In
Command Argument processing for Excel, Word and Powerpoint to allow (almost) headless starting VB-Macros: [https://sourceforge.net/projects/officegoodies/files/CmdArgs](https://sourceforge.net/projects/officegoodies/files/CmdArgs)
### Log-Addin
flexible file and eventLog logging from MS-Office applications and VBScript: [https://sourceforge.net/projects/officegoodies/files/LogAddin/1.0.2/LogAddinSetup.1.0.2.msi/download](https://sourceforge.net/projects/officegoodies/files/LogAddin/1.0.2/LogAddinSetup.1.0.2.msi/download)

## useful tips

Following are links to pages with useful information I've collected during my endeavors.

### SQL Server XML Queries
With examples from the ORE DB project: [SQLServerXML](SQLServerXML.md)

### Face-IDs for Office Versions >= 2010
Following Code was adapted from John D. Mclean's code for Excel <= 2003 and displays all Face-IDs available for commandbar buttons in the Add-Ins ribbon (this is a long list, change the 4891 (max. number for Office 2010) to your office version):

```vb.net
Option Explicit
Sub DisplayButtonFacesInGrid()
Const cbName = "FaceId"
Dim cBar As CommandBar, cBut As CommandBarControl
Dim r As Long, c As Integer, count As Integer

  count = 0
  Do                          'loop through all FaceIDs
    If count Mod 100 = 0 Then
        On Error Resume Next
        CommandBars(count \ 100 & cbName).Delete
        On Error GoTo 0
        Set cBar = CommandBars.Add    'create temporary ToolBar with one button
        With cBar
          .Name = count \ 100 & cbName
          .Top = count \ 100
          .Left = 0
          .Visible = True
          .RowIndex = count \ 100
        End With
    End If

    Set cBut = CommandBars(count \ 100 & cbName).Controls.Add(Type:=msoControlButton)
    cBut.FaceId = count
    cBut.Caption = count
    count = count + 1
    Application.StatusBar = "Creating Button FaceIDs " & count
  Loop While count < 4891 '4890 seems to be the maximum FaceID #
  Application.StatusBar = ""
End Sub
```
