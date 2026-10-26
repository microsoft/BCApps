// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

page 8130 "Report Filename Table Lookup"
{
    // Picks the table for a pattern that covers every report on that table. Lists only tables
    // that some non-processing report is about, not all of Table Metadata.

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

    internal procedure ChosenTableNo(): Integer
    begin
        exit(Rec."Table No.");
    end;
}
