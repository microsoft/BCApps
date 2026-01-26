// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;

report 28020 "Bank Detail Cashflow Compare"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/BankMgt/Reports/BankDetailCashflowCompare.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Detail Cashflow Compare';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Search Name", "Bank Acc. Posting Group", "Date Filter";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(STRSUBSTNO_Text000_BankAccDateFilter_; StrSubstNo(Text000, BankAccDateFilter))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(USERID; UserId)
            {
            }
            column(myPrintOnlyOnePerPage; PrintOnlyOnePerPage)
            {
            }
            column(myPrintAllHavingBal; PrintAllHavingBal)
            {
            }
            column(STRSUBSTNO___1___2___Bank_Account__TABLECAPTION_BankAccFilter_; StrSubstNo('%1: %2', "Bank Account".TableCaption(), BankAccFilter))
            {
            }
            column(myBankAccFilter; BankAccFilter)
            {
            }
            column(Bank_Account__No__; "No.")
            {
            }
            column(Bank_Account_Name; Name)
            {
            }
            column(Bank_Account__Currency_Code_; "Currency Code")
            {
            }
            column(StartBalance; StartBalance)
            {
                AutoFormatExpression = "Bank Account Ledger Entry"."Currency Code";
                AutoFormatType = 1;
            }
            column(StartBalanceLCY; StartBalanceLCY)
            {
                AutoFormatType = 1;
            }
            column(Bank_Account_Date_Filter; "Date Filter")
            {
            }
            column(Bank_Account_Global_Dimension_2_Filter; "Global Dimension 2 Filter")
            {
            }
            column(Bank_Account_Global_Dimension_1_Filter; "Global Dimension 1 Filter")
            {
            }
            column(Bank_Detail_Cashflow_CompareCaption; Bank_Detail_Cashflow_CompareCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(This_report_also_includes_bank_accounts_that_only_have_balances_Caption; This_report_also_includes_bank_accounts_that_only_have_balances_CaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry__Posting_Date_Caption; Bank_Account_Ledger_Entry__Posting_Date_CaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry__Document_Type_Caption; Bank_Account_Ledger_Entry__Document_Type_CaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry__Document_No__Caption; "Bank Account Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(Bank_Account_Ledger_Entry_DescriptionCaption; "Bank Account Ledger Entry".FieldCaption(Description))
            {
            }
            column(BankAccBalanceCaption; BankAccBalanceCaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry__Remaining_Amount_Caption; "Bank Account Ledger Entry".FieldCaption("Remaining Amount"))
            {
            }
            column(Bank_Account_Ledger_Entry__Entry_No__Caption; "Bank Account Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(Bank_Account_Ledger_Entry_OpenCaption; Bank_Account_Ledger_Entry_OpenCaptionLbl)
            {
            }
            column(BankAccBalanceLCYCaption; BankAccBalanceLCYCaptionLbl)
            {
            }
            column(Bank_Account_Ledger_Entry__Debit_Amount_Caption; "Bank Account Ledger Entry".FieldCaption("Debit Amount"))
            {
            }
            column(Bank_Account_Ledger_Entry__Credit_Amount_Caption; "Bank Account Ledger Entry".FieldCaption("Credit Amount"))
            {
            }
            column(Bank_Account_Ledger_Entry__Debit_Amount__LCY__Caption; "Bank Account Ledger Entry".FieldCaption("Debit Amount (LCY)"))
            {
            }
            column(Bank_Account_Ledger_Entry__Credit_Amount__LCY__Caption; "Bank Account Ledger Entry".FieldCaption("Credit Amount (LCY)"))
            {
            }
            column(Starting_BalanceCaption; Starting_BalanceCaptionLbl)
            {
            }
            dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
            {
                DataItemLink = "Bank Account No." = field("No."), "Posting Date" = field("Date Filter"), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter");
                DataItemTableView = sorting("Bank Account No.", "Posting Date");
                column(StartBalance____Bank_Account_Ledger_Entry__Amount; StartBalance + "Bank Account Ledger Entry".Amount)
                {
                    AutoFormatExpression = "Bank Account Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(StartBalanceLCY____Bank_Account_Ledger_Entry___Amount__LCY__; StartBalanceLCY + "Bank Account Ledger Entry"."Amount (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(Bank_Account_Ledger_Entry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(Bank_Account_Ledger_Entry__Document_Type_; "Document Type")
                {
                }
                column(Bank_Account_Ledger_Entry__Document_No__; "Document No.")
                {
                }
                column(Bank_Account_Ledger_Entry_Description; Description)
                {
                }
                column(BankAccBalance; BankAccBalance)
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(Bank_Account_Ledger_Entry__Remaining_Amount_; "Remaining Amount")
                {
                }
                column(Bank_Account_Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(Bank_Account_Ledger_Entry_Open; Format(Open))
                {
                }
                column(BankAccBalanceLCY; BankAccBalanceLCY)
                {
                    AutoFormatType = 1;
                }
                column(Bank_Account_Ledger_Entry__Debit_Amount_; "Debit Amount")
                {
                }
                column(Bank_Account_Ledger_Entry__Credit_Amount_; "Credit Amount")
                {
                }
                column(Bank_Account_Ledger_Entry__Debit_Amount__LCY__; "Debit Amount (LCY)")
                {
                }
                column(Bank_Account_Ledger_Entry__Credit_Amount__LCY__; "Credit Amount (LCY)")
                {
                }
                column(StartBalance____Bank_Account_Ledger_Entry__Amount_Control1500045; StartBalance + "Bank Account Ledger Entry".Amount)
                {
                    AutoFormatExpression = "Bank Account Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(StartBalanceLCY____Bank_Account_Ledger_Entry___Amount__LCY___Control1500046; StartBalanceLCY + "Bank Account Ledger Entry"."Amount (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(StartBalance____Bank_Account_Ledger_Entry__Amount_Control1500048; StartBalance + "Bank Account Ledger Entry".Amount)
                {
                    AutoFormatExpression = "Bank Account Ledger Entry"."Currency Code";
                    AutoFormatType = 1;
                }
                column(StartBalanceLCY____Bank_Account_Ledger_Entry___Amount__LCY___Control1500049; StartBalanceLCY + "Bank Account Ledger Entry"."Amount (LCY)")
                {
                    AutoFormatType = 1;
                }
                column(FORMAT__Bank_Account_Ledger_Entry___Debit_Amount__; "Bank Account Ledger Entry"."Debit Amount")
                {
                }
                column(Bank_Account_Ledger_Entry__Bank_Account_Ledger_Entry___Credit_Amount_; "Bank Account Ledger Entry"."Credit Amount")
                {
                }
                column(Bank_Account_Ledger_Entry__Bank_Account_Ledger_Entry___Debit_Amount__LCY__; "Bank Account Ledger Entry"."Debit Amount (LCY)")
                {
                }
                column(Bank_Account_Ledger_Entry__Bank_Account_Ledger_Entry___Credit_Amount__LCY__; "Bank Account Ledger Entry"."Credit Amount (LCY)")
                {
                }
                column(Bank_Account_Ledger_Entry__Bank_Account_Ledger_Entry__Amount; "Bank Account Ledger Entry".Amount)
                {
                }
                column(Bank_Account_Ledger_Entry__Bank_Account_Ledger_Entry___Amount__LCY__; "Bank Account Ledger Entry"."Amount (LCY)")
                {
                }
                column(STRSUBSTNO_Text000_BankAccDateFilter__Control1500056; StrSubstNo(Text000, BankAccDateFilter))
                {
                }
                column(Bank_Account_Ledger_Entry_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(Bank_Account_Ledger_Entry_Posting_Date; "Posting Date")
                {
                }
                column(Bank_Account_Ledger_Entry_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }
                column(Bank_Account_Ledger_Entry_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }
                column(ContinuedCaption; ContinuedCaptionLbl)
                {
                }
                column(ContinuedCaption_Control1500044; ContinuedCaption_Control1500044Lbl)
                {
                }
                column(Ending_BalanceCaption; Ending_BalanceCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    BankAccLedgEntryExists := true;
                    BankAccBalance := BankAccBalance + Amount;
                    BankAccBalanceLCY := BankAccBalanceLCY + "Amount (LCY)"
                end;

                trigger OnPreDataItem()
                begin
                    BankAccLedgEntryExists := false;
                end;
            }
            dataitem(BankAccountLedgerEntry2; "Bank Account Ledger Entry")
            {
                DataItemLink = "Bank Account No." = field("No."), "Global Dimension 2 Code" = field("Global Dimension 2 Filter"), "Global Dimension 1 Code" = field("Global Dimension 1 Filter");
                DataItemTableView = sorting("Bank Account No.", "Posting Date");
                column(BankAccountLedgerEntry2_BankAccountLedgerEntry2__Debit_Amount_; "Debit Amount")
                {
                }
                column(BankAccountLedgerEntry2_BankAccountLedgerEntry2__Credit_Amount_; "Credit Amount")
                {
                }
                column(BankAccountLedgerEntry2_BankAccountLedgerEntry2_Amount; Amount)
                {
                }
                column(BankAccountLedgerEntry2_BankAccountLedgerEntry2__Debit_Amount__LCY__; "Debit Amount (LCY)")
                {
                }
                column(BankAccountLedgerEntry2_BankAccountLedgerEntry2__Credit_Amount__LCY__; "Credit Amount (LCY)")
                {
                }
                column(BankAccountLedgerEntry2_BankAccountLedgerEntry2__Amount__LCY__; "Amount (LCY)")
                {
                }
                column(STRSUBSTNO_Text000_BankAccDateFilter2_; StrSubstNo(Text000, BankAccDateFilter2))
                {
                }
                column(myDebit; Format("Debit Amount"))
                {
                }
                column(BankAccountLedgerEntry2_Entry_No_; "Entry No.")
                {
                }
                column(BankAccountLedgerEntry2_Bank_Account_No_; "Bank Account No.")
                {
                }
                column(BankAccountLedgerEntry2_Global_Dimension_2_Code; "Global Dimension 2 Code")
                {
                }
                column(BankAccountLedgerEntry2_Global_Dimension_1_Code; "Global Dimension 1 Code")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    BankAccLedgEntryExists := true;
                    BankAccBalance := BankAccBalance + Amount;
                    BankAccBalanceLCY := BankAccBalanceLCY + "Amount (LCY)"
                end;

                trigger OnPreDataItem()
                begin
                    BankAccLedgEntryExists := false;
                    SetFilter("Posting Date", '%1..%2', CompareStartDate, CompareEndDate);
                    BankAccDateFilter2 := Format(CompareStartDate) + '..' + Format(CompareEndDate);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                StartBalance := 0;
                if BankAccDateFilter <> '' then
                    if GetRangeMin("Date Filter") <> 0D then begin
                        SetRange("Date Filter", 0D, GetRangeMin("Date Filter") - 1);
                        CalcFields("Net Change", "Net Change (LCY)");
                        StartBalance := "Net Change";
                        StartBalanceLCY := "Net Change (LCY)";
                        SetFilter("Date Filter", BankAccDateFilter);
                    end;
                CurrReport.PrintOnlyIfDetail := not (PrintAllHavingBal and (StartBalance <> 0));
                BankAccBalance := StartBalance;
                BankAccBalanceLCY := StartBalanceLCY;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CompareStartDate; CompareStartDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Compare Start Date';
                        ToolTip = 'Specifies the first date for the comparison.';
                    }
                    field(CompareEndDate; CompareEndDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Compare End Date';
                        ToolTip = 'Specifies the last date for the comparison.';
                    }
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Bank Account';
                        ToolTip = 'Specifies if information about each bank account is printed on a new page.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        BankAccFilter := "Bank Account".GetFilters();
        BankAccDateFilter := "Bank Account".GetFilter("Date Filter");
        Clear(StartBalanceLCY);
    end;

    var
        PrintOnlyOnePerPage: Boolean;
        PrintAllHavingBal: Boolean;
        BankAccFilter: Text[250];
        BankAccDateFilter: Text[30];
        BankAccDateFilter2: Text[30];
        BankAccBalance: Decimal;
        BankAccBalanceLCY: Decimal;
        StartBalance: Decimal;
        StartBalanceLCY: Decimal;
        BankAccLedgEntryExists: Boolean;
        CompareStartDate: Date;
        CompareEndDate: Date;
        Text000: Label 'Period: %1';
        Bank_Detail_Cashflow_CompareCaptionLbl: Label 'Bank Detail Cashflow Compare';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        This_report_also_includes_bank_accounts_that_only_have_balances_CaptionLbl: Label 'This report also includes bank accounts that only have balances.';
        Bank_Account_Ledger_Entry__Posting_Date_CaptionLbl: Label 'Posting Date';
        Bank_Account_Ledger_Entry__Document_Type_CaptionLbl: Label 'Document Type';
        BankAccBalanceCaptionLbl: Label 'Balance';
        Bank_Account_Ledger_Entry_OpenCaptionLbl: Label 'Open';
        BankAccBalanceLCYCaptionLbl: Label 'Balance (LCY)';
        Starting_BalanceCaptionLbl: Label 'Starting Balance';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control1500044Lbl: Label 'Continued';
        Ending_BalanceCaptionLbl: Label 'Ending Balance';
}

