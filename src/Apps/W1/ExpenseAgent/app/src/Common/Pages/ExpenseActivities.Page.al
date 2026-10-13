// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7141 "Expense Activities"
{
    Caption = 'Expense Activities';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Expense Activities Cue";
    Permissions = tabledata "Expense Activities Cue" = rim;

    layout
    {
        area(Content)
        {
            cuegroup("Expense Reports")
            {
                Caption = 'Expense Reports';

                field("Expense Reports - Open"; Rec."Expense Reports - Open")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Expense Reports";
                }
                field("Expense Reports - Released"; Rec."Expense Reports - Released")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Expense Reports";
                }
                field("Exp. Reports - Pending Appr."; Rec."Exp. Reports - Pending Appr.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Expense Reports";
                }
                field("Exp. Reports - Interim Appr."; Rec."Exp. Reports - Interim Appr.")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Expense Reports";
                }
                field("Expense Reports - Approved"; Rec."Expense Reports - Approved")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Expense Reports";
                }
                field("Expense Reports - Rejected"; Rec."Expense Reports - Rejected")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Expense Reports";
                }
                field("Exp. Reports - Processed Pay"; Rec."Exp. Reports - Processed Pay")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Expense Reports";
                }
                field("Expense Reports - Completed"; Rec."Expense Reports - Completed")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Expense Reports";
                }
            }
            cuegroup(Expenses)
            {
                Caption = 'Expenses';

                field("Expenses - Released"; Rec."Expenses - Released")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = Expenses;
                }
                field("Expenses - Policy Violated"; Rec."Expenses - Policy Violated")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = Expenses;
                }
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