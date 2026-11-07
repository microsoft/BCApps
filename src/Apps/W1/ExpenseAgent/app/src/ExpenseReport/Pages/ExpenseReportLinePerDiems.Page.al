// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6934 "Expense Report Line Per Diems"
{
    Caption = 'Expense Report Line Per Diems';
    PageType = List;
    InsertAllowed = false;
    DeleteAllowed = false;
    SourceTable = "Expense Report Line Per Diem";
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Description"; Rec."Description")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description of the per diem entry.';
                }
                field("Date"; Rec."Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date of the per diem entry.';
                }
                field("Breakfast"; Rec."Breakfast")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if breakfast is included.';
                }
                field("Lunch"; Rec."Lunch")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if lunch is included.';
                }
                field("Dinner"; Rec."Dinner")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if dinner is included.';
                }
                field("Per Diem Amount"; Rec."Per Diem Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the per diem amount.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ExpenseReportLine: Record "Expense Report Line";
    begin
        ExpenseReportLine.Get(Rec.GetFilter("Expense Report No."), Rec.GetFilter("Expense Report Line No."));

        if ExpenseReportLine."Expense Location" = '' then
            Rec.SendMissingExpenseLocationNotification(ExpenseReportLine);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            if ExpenseReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.") then
                ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);
    end;
}