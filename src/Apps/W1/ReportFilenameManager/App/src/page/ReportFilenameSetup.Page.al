// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
page 50119 "Report Filename Setup"
{
    // The setup card: the switch for the whole feature, how many patterns it puts to work, and the
    // one maximum length. Captions and
    // tooltips come from the table, as on every other page in this app.

    Caption = 'Report Filename Setup';
    PageType = Card;
    SourceTable = "Report Filename Setup";
    UsageCategory = Administration;
    // Tell Me matches whole words; see the same property on Report Filename Patterns.
    AdditionalSearchTerms = 'file name, file names, file name setup, document name, PDF name, attachment name, report naming';
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Enabled; Rec.Enabled)
                {
                }
                field("Enabled Patterns"; Rec."Enabled Patterns")
                {
                }
                field("Max. File Name Length"; Rec."Max. File Name Length")
                {
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Patterns)
            {
                Caption = 'Report Filename Patterns';
                ToolTip = 'Opens the list of file name patterns.';
                Image = List;
                RunObject = page "Report Filename Patterns";
            }
        }
        area(Promoted)
        {
            actionref(Patterns_Promoted; Patterns)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        // The row is created the first time somebody opens the setup, the way Base Application's
        // setup pages do it - and only here, never while a report is being named.
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
