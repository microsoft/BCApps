// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6931 "Expense Report Line Items"
{
    Caption = 'Expense Report Line Itemizations';
    PageType = List;
    ApplicationArea = Basic, Suite;
    RefreshOnActivate = true;
    SourceTable = "Expense Report Line Item";
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Expense Subcategory Code"; Rec."Expense Subcategory Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense subcategory code for this itemization.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for this itemization.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date for this itemization.';
                }
                field("Quantity"; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity for this itemization.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Daily Rate"; Rec."Daily Rate")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the daily rate for this itemization.';
                }
                field("Amount"; Rec."Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount for all itemization lines.';
                }
            }
            group(Totals)
            {
                Caption = 'Totals';
                field(TotalAmount; TotalAmount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total amount for the itemizations.';
                }
                field(ExpenseAmount; ExpenseAmount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expense Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total amount for the itemizations.';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if ExpenseReportLine.Get(Rec.GetFilter("Expense Report No."), Rec.GetFilter("Expense Report Line No.")) then
            Rec."Expense Category Code" := ExpenseReportLine."Expense Category";
    end;

    trigger OnAfterGetCurrRecord()
    var
        Itemization: Record "Expense Report Line Item";
    begin
        Itemization.SetRange("Expense Report No.", Rec."Expense Report No.");
        Itemization.SetRange("Expense Report Line No.", Rec."Expense Report Line No.");
        Itemization.CalcSums(Amount);

        TotalAmount := Itemization.Amount;

        if ExpenseReportLine."Document No." = '' then
            ExpenseReportLine.Get(Rec.GetFilter("Expense Report No."), Rec.GetFilter("Expense Report Line No."));

        ExpenseAmount := ExpenseReportLine.Amount;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            if ExpenseReportLine.Get(Rec."Expense Report No.", Rec."Expense Report Line No.") then begin
                ExpenseRuleValidation.ValidateExpenseReportLineAgainstRule(ExpenseReportLine);
                ExpenseRuleValidation.ValidateItemizationAmount(ExpenseReportLine, true);
            end;
    end;

    var
        ExpenseReportLine: Record "Expense Report Line";
        TotalAmount: Decimal;
        ExpenseAmount: Decimal;
}