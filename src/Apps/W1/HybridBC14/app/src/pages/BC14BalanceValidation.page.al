// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Finance.GeneralLedger.Account;

page 50166 "BC14 Balance Validation"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    Caption = 'BC14 Balance Validation';
    SourceTable = "G/L Account";
    SourceTableView = where("Account Type" = const(Posting));
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the G/L Account number.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the G/L Account name.';
                }
                field("BC14 Debit"; BC14DebitAmount)
                {
                    ApplicationArea = All;
                    Caption = 'BC14 Debit Amount';
                    AutoFormatType = 1;
                    AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
                    ToolTip = 'Specifies the debit amount from BC14 source data.';
                    Style = Attention;
                    StyleExpr = HasDifference;
                }
                field("BC14 Credit"; BC14CreditAmount)
                {
                    ApplicationArea = All;
                    Caption = 'BC14 Credit Amount';
                    AutoFormatType = 1;
                    AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
                    ToolTip = 'Specifies the credit amount from BC14 source data.';
                    Style = Attention;
                    StyleExpr = HasDifference;
                }
                field("BC14 Balance"; BC14Balance)
                {
                    ApplicationArea = All;
                    Caption = 'BC14 Net Balance';
                    AutoFormatType = 1;
                    AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
                    ToolTip = 'Specifies the net balance from BC14 source data (Debit - Credit).';
                    Style = Attention;
                    StyleExpr = HasDifference;
                }
                field("BC Online Balance"; BCOnlineBalance)
                {
                    ApplicationArea = All;
                    Caption = 'BC Online Balance';
                    AutoFormatType = 1;
                    AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
                    ToolTip = 'Specifies the current balance in BC Online.';
                    Style = Attention;
                    StyleExpr = HasDifference;
                }
                field(Difference; BalanceDifference)
                {
                    ApplicationArea = All;
                    Caption = 'Difference';
                    AutoFormatType = 1;
                    AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
                    ToolTip = 'Specifies the difference between BC14 and BC Online balances.';
                    Style = Unfavorable;
                    StyleExpr = HasDifference;
                }
                field(Status; StatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the balances match.';
                    Style = Favorable;
                    StyleExpr = not HasDifference;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshData)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                ToolTip = 'Refresh the balance comparison data.';
                Image = Refresh;

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
            action(ShowDifferencesOnly)
            {
                ApplicationArea = All;
                Caption = 'Show Differences Only';
                ToolTip = 'Filter to show only accounts with balance differences.';
                Image = FilterLines;

                trigger OnAction()
                begin
                    ShowOnlyDifferences := not ShowOnlyDifferences;
                    CurrPage.Update(false);
                end;
            }
            action(ExportToExcel)
            {
                ApplicationArea = All;
                Caption = 'Export to Excel';
                ToolTip = 'Export the comparison data to Excel for further analysis.';
                Image = ExportToExcel;

                trigger OnAction()
                begin
                    Message(ExportNotImplementedMsg);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(RefreshData_Promoted; RefreshData) { }
                actionref(ShowDifferencesOnly_Promoted; ShowDifferencesOnly) { }
                actionref(ExportToExcel_Promoted; ExportToExcel) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalculateBalances();
    end;

    local procedure CalculateBalances()
    var
        BC14GLEntry: Record "BC14 G/L Entry";
    begin
        // Reset values
        BC14DebitAmount := 0;
        BC14CreditAmount := 0;
        BC14Balance := 0;
        BCOnlineBalance := 0;
        BalanceDifference := 0;
        HasDifference := false;
        StatusText := 'OK';

        // Calculate BC14 balance from G/L Entry buffer
        BC14GLEntry.SetRange("G/L Account No.", Rec."No.");
        if BC14GLEntry.FindSet() then
            repeat
                BC14DebitAmount += BC14GLEntry."Debit Amount";
                BC14CreditAmount += BC14GLEntry."Credit Amount";
            until BC14GLEntry.Next() = 0;

        BC14Balance := BC14DebitAmount - BC14CreditAmount;

        // Get BC Online balance
        Rec.CalcFields("Balance at Date", "Net Change");
        BCOnlineBalance := Rec."Net Change"; // or use "Balance at Date" depending on what you want to compare

        // Calculate difference
        BalanceDifference := BC14Balance - BCOnlineBalance;
        HasDifference := Abs(BalanceDifference) > 0.01; // Allow for small rounding differences

        if HasDifference then
            StatusText := 'DIFFERENCE'
        else
            StatusText := 'OK';

        // Filter logic
        if ShowOnlyDifferences and not HasDifference then
            Rec.Mark(false)
        else
            Rec.Mark(true);
    end;

    var
        BC14DebitAmount: Decimal;
        BC14CreditAmount: Decimal;
        BC14Balance: Decimal;
        BCOnlineBalance: Decimal;
        BalanceDifference: Decimal;
        HasDifference: Boolean;
        StatusText: Text[20];
        ShowOnlyDifferences: Boolean;
        ExportNotImplementedMsg: Label 'Export functionality can be implemented using standard Excel Buffer or Report approach.';
}
