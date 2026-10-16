# XML Audit File FR

This app exports French general ledger entries to XML through the Audit File Export framework.

## Setup and permissions

Assign the **XML Audit - Export** permission set to users who need to generate XML audit files.
The app does not grant export access through standard roles such as D365 READ or D365 TEAM MEMBER.
The dedicated permission set includes export-object execution and indirect read access to G/L entries.

Select **GL Entries XML FR** on the audit export document and specify the reporting dates.
If the XML format setup is missing, use **Open format setup** in the error dialog to add it.

## Export behavior

Generated filenames use `GLEntries_YYYYMMDD.xml`, based on the ending date, independently of the session language.
Controls that do not apply to XML are hidden through the selected format's page-visibility interface.
Changing formats refreshes the document and setup controls without reopening the pages.
