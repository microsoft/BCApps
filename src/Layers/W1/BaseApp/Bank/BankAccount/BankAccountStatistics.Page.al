// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Foundation.Period;

/// <summary>
/// Displays comprehensive statistical information and key performance indicators for bank accounts.
/// Provides summary view of balances, transaction volumes, and period-based analysis.
/// </summary>
/// <remarks>
/// Source Table: Bank Account (270). Read-only statistical view with calculated fields.
/// Features balance summaries, transaction counts, and period-based comparative analysis.
/// </remarks>
page 375 "Bank Account Statistics"
{
    Caption = 'Bank Account Statistics';
    DataCaptionFields = "No.", Name;
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            group("Balance Group")
            {
                Caption = 'Balance';
                field("Balance (LCY)"; Rec."Balance (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Balance (LCY)';
                    ToolTip = 'Specifies the bank account''s current balance in LCY.';
                }
                field(Balance; Rec.Balance)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    ToolTip = 'Specifies the bank account''s current balance denominated in the applicable foreign currency.';
                }
                field("Min. Balance"; Rec."Min. Balance")
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatExpression = Rec."Currency Code";
                    AutoFormatType = 1;
                    ToolTip = 'Specifies a minimum balance for the bank account.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Currency';
                    Lookup = false;
                    ToolTip = 'Specifies the currency code for the bank account.';
                }
            }
            group("Net Change")
            {
                Caption = 'Net Change';
                fixed(Control1904230801)
                {
                    ShowCaption = false;
                    group("This Period")
                    {
                        Caption = 'This Period';
                        field("BankAccDateName[1]"; BankAccDateName[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Date Name';
                            ToolTip = 'Specifies the date.';
                        }
                        field("BankAccNetChange[1]"; BankAccNetChange[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Net Change';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year and To Date.';
                        }
                        field("BankAccNetChangeLCY[1]"; BankAccNetChangeLCY[1])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Net Change (LCY)';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year, and To Date.';
                        }
                    }
                    group("This Year")
                    {
                        Caption = 'This Year';
                        field(Text000; PlaceholderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field("BankAccNetChange[2]"; BankAccNetChange[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Net Change';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year and To Date.';
                        }
                        field("BankAccNetChangeLCY[2]"; BankAccNetChangeLCY[2])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Net Change (LCY)';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year, and To Date.';
                        }
                    }
                    group("Last Year")
                    {
                        Caption = 'Last Year';
                        field("Placeholder 2"; PlaceholderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field("BankAccNetChange[3]"; BankAccNetChange[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Net Change';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year and To Date.';
                        }
                        field("BankAccNetChangeLCY[3]"; BankAccNetChangeLCY[3])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Net Change (LCY)';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year, and To Date.';
                        }
                    }
                    group("To Date")
                    {
                        Caption = 'To Date';
                        field("Placeholder 3"; PlaceholderLbl)
                        {
                            ApplicationArea = Basic, Suite;
                            Visible = false;
                        }
                        field("BankAccNetChange[4]"; BankAccNetChange[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Net Change';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year and To Date.';
                        }
                        field("BankAccNetChangeLCY[4]"; BankAccNetChangeLCY[4])
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Net Change (LCY)';
                            ToolTip = 'Specifies the net value of entries in LCY on the bank account for the periods: Current Month, This Year, Last Year, and To Date.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if CurrentDate <> WorkDate() then begin
            CurrentDate := WorkDate();
            DateFilterCalc.CreateAccountingPeriodFilter(BankAccDateFilter[1], BankAccDateName[1], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(BankAccDateFilter[2], BankAccDateName[2], CurrentDate, 0);
            DateFilterCalc.CreateFiscalYearFilter(BankAccDateFilter[3], BankAccDateName[3], CurrentDate, -1);
        end;

        Rec.SetRange("Date Filter", 0D, CurrentDate);
        Rec.CalcFields(Balance, "Balance (LCY)");

        for i := 1 to 4 do begin
            Rec.SetFilter("Date Filter", BankAccDateFilter[i]);
            Rec.CalcFields("Net Change", "Net Change (LCY)");
            BankAccNetChange[i] := Rec."Net Change";
            BankAccNetChangeLCY[i] := Rec."Net Change (LCY)";
        end;
        Rec.SetRange("Date Filter", 0D, CurrentDate);
    end;

    var
        DateFilterCalc: Codeunit "DateFilter-Calc";
        BankAccDateFilter: array[4] of Text[30];
        BankAccDateName: array[4] of Text[30];
        CurrentDate: Date;
        BankAccNetChange: array[4] of Decimal;
        BankAccNetChangeLCY: array[4] of Decimal;
        i: Integer;
        PlaceholderLbl: Label 'Placeholder';
}

