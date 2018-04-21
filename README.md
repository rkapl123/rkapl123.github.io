All repositories: [https://github.com/rkapl123](https://github.com/rkapl123)

## Quantlib fully annotated source documentation
As a frequent user of [Quantlib](http://quantlib.org), I found that I needed to read more than the official reference documentation provided on the official website. So I decided to tweak the doxygen config to produce a fully annotated source documentation of quantlib including collaboration diagrams, call/caller diagrams and a working search box: [https://rkapl123.github.io/QLAnnotatedSource](https://rkapl123.github.io/QLAnnotatedSource)

## OreControl

I'm using the Opensource Risk Engine ([ORE](http://www.opensourcerisk.org), based on Quantlib), my intention is to provide Tools for easier interaction with/integration of the Opensource Risk Engine. Following three goals are envisaged:

- [ ] easy starting from Excel (OreAddin in conjunction with OreMgr),
- [x] loading and migrating ORE data from/to a Database (OreDB)
- [ ] a SWIG wrapper (OreMgr) to allow starting ORE from .NET and other environments.

All this will be available in: [https://github.com/rkapl123/OreControl](https://github.com/rkapl123/OreControl)

## DBAddin
DBAddin (the current working version being a legacy VB6 COM Addin) is two things in one:

- A COM/Automation Add-in for database querying by userdefined functions (DBFuncs). This is opposed to the Excel/Word integrated MS-Query, which is integrated statically into the worksheet and has some limitations in terms of querying possibilities and flexibility of constructing parameterized queries (MS-Query allows parameterized queries only in simple queries that can be displayed graphically). This also includes the possibility for filling "data bound" controls (ComboBoxes and Listboxes) with data from queries. Other useful functions for working with database data are included as well.

- A way to edit Database data directly in Excel using so called "DBSheets", which are special ExcelWorksheets that enable you to manipulate database data directly inside Excel (similar to MS Access table view). In DBSheets you can define a foreign key lookup resolution for foreign keys, so columns containing foreign IDs can be edited more easily. Another feature is the "jumping" to a referenced record in a foreign dependent table, if it's defined as a DBSheet in the same Workbook.

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

Documentation and download available here: [https://github.com/rkapl123/ExchangeSetOOF](https://github.com/rkapl123/ExchangeSetOOF)

## other MS-Office based Addins

Following Addins are available (only for 32-bit Office installations due to VB6/COM implementation):

### CMD-Line parser Add-In
Command Argument processing for Excel, Word and Powerpoint to allow (almost) headless starting VB-Macros: [https://sourceforge.net/projects/officegoodies/files/CmdArgs](https://sourceforge.net/projects/officegoodies/files/CmdArgs)
### Log-Addin
flexible file and eventLog logging from MS-Office applications and VBScript: [https://sourceforge.net/projects/officegoodies/files/LogAddin/1.0.2/LogAddinSetup.1.0.2.msi/download](https://sourceforge.net/projects/officegoodies/files/LogAddin/1.0.2/LogAddinSetup.1.0.2.msi/download)
