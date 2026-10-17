// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
tableextension 50110 "Report Filename Report Inbox" extends "Report Inbox"
{
    // The app's only field on a Base Application table, and section 12 says why it is unavoidable. A scheduled
    // report is rendered into a stream, so nothing is ever named while the report runs and
    // GetFilename cannot fire. The row that lands in the Report Inbox carries no file name at
    // all: a name is invented much later, at download, from the report's own caption or the
    // job queue entry's description. Storing the name at the moment the row is inserted is
    // what lets the scheduled route produce the same file name as every other route.

    fields
    {
        field(50110; "File Name"; Text[250])
        {
            // Named in Business Central's own words, as a File Name field beside the Report
            // Name it replaces at download. This field stays in the shipped app.
            Caption = 'File Name';
            ToolTip = 'Specifies the file name this entry downloads under, as decided by the file name patterns when the report was produced. If it is blank, the file gets Business Central''s own file name.';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }
}
