// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 50115 "Report Filename Table Lookup"
{
    // Picks the table, by name, for a pattern that covers every report on that table rather than
    // one particular report.
    //
    // Over a buffer, not straight over Table Metadata. Table Metadata is every table in the
    // system, and this list used to show all of them - buffers, session tables, setup tables -
    // none of which any report is about, so choosing one produced a pattern that could never
    // match. The buffer holds the kinds of record that reports really are about, derived from
    // each report's first data item, and says how many reports are about each so an
    // administrator can see which are worth naming.

    Caption = 'Tables';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Report Filename Table Buffer";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Tables)
            {
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = All;
                }
                field("Report Count"; Rec."Report Count")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        FilenamePlaceholderMgt: Codeunit "Report Filename Plh. Mgt.";
    begin
        FilenamePlaceholderMgt.BuildTables(Rec);
        Rec.SetCurrentKey("Table Caption");
        if Rec.FindFirst() then;
    end;

    /// <summary>
    /// The table number the administrator chose, which is what the pattern stores.
    /// </summary>
    /// <returns>The table number.</returns>
    internal procedure ChosenTableNo(): Integer
    begin
        exit(Rec."Table No.");
    end;
}
