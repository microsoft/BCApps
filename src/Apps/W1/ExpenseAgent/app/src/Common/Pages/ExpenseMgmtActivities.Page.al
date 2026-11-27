// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Visualization;

page 7449 "EA Expense Mgmt Activities"
{
    Caption = 'Activities';
    PageType = CardPart;
    InsertAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "EA Expense Management Cue";

    layout
    {
        area(Content)
        {
            cuegroup("Expense Reports")
            {
                Caption = 'Expense Reports';

                field("Open Expense Reports"; Rec."Open Expense Reports")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Expense Reports";
                    ToolTip = 'Specifies the number of expense reports that are not yet submitted.';
                }
                field("Pending Approval"; Rec."Pending Approval")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Expense Reports";
                    ToolTip = 'Specifies the number of expense reports that are waiting for approval.';
                }
                field("Approved Reports"; Rec."Approved Reports")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Expense Reports";
                    ToolTip = 'Specifies the number of approved expense reports that are not yet posted.';
                }
                field("Rejected Reports"; Rec."Rejected Reports")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Expense Reports";
                    ToolTip = 'Specifies the number of rejected expense reports.';
                }
            }
            cuegroup(Expenses)
            {
                Caption = 'Expenses';

                field("Open Expenses"; Rec."Open Expenses")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = Expenses;
                    ToolTip = 'Specifies the number of expenses that are not yet submitted.';
                }
            }
            cuegroup("Corporate Card")
            {
                Caption = 'Corporate Card';

                field("Card Transactions to Review"; Rec."Card Transactions to Review")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "EA Corp Card Trans List";
                    ToolTip = 'Specifies the number of imported corporate card transactions that are not yet turned into expenses.';
                }
                field("Unresolved Card Exceptions"; Rec."Unresolved Card Exceptions")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "EA Corp Card Exceptions";
                    ToolTip = 'Specifies the number of corporate card import exceptions that need attention.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set up cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CuesAndKPIs: Codeunit "Cues And KPIs";
                    CueRecordRef: RecordRef;
                begin
                    CueRecordRef.GetTable(Rec);
                    CuesAndKPIs.OpenCustomizePageForCurrentUser(CueRecordRef.Number);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
