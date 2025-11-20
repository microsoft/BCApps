// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using System.Utilities;

report 1406 "Bank Account - Check Details"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Bank/Reports/BankAccountCheckDetails.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Account - Check Details';
    UsageCategory = ReportsAndAnalysis;
    WordMergeDataItem = "Bank Account";

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
            column(STRSUBSTNO_Text000_BankAccDateFilter_; StrSubstNo(PeriodLbl, BankAccDateFilter))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO___1___2___Bank_Account__TABLECAPTION_BankAccFilter_; StrSubstNo('%1: %2', TableCaption(), BankAccFilter))
            {
            }
            column(BankFilter; BankAccFilter)
            {
            }
            column(Bank_Account__No__; "No.")
            {
            }
            column(Bank_Account_Name; Name)
            {
            }
            column(Bank_Account__Phone_No__; "Phone No.")
            {
            }
            column(Bank_Account__Currency_Code_; "Currency Code")
            {
            }
            column(ShowCurrencyCode; "Currency Code" <> '')
            {
            }
            column(Bank_Account___Check_DetailsCaption; Bank_Account___Check_DetailsCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(This_report_also_includes_bank_accounts_that_only_have_balances_Caption; This_report_also_includes_bank_accounts_that_only_have_balances_CaptionLbl)
            {
            }
            column(Check_Ledger_Entry__Entry_No__Caption; "Check Ledger Entry".FieldCaption("Entry No."))
            {
            }
            column(Check_Ledger_Entry__Bal__Account_No__Caption; "Check Ledger Entry".FieldCaption("Bal. Account No."))
            {
            }
            column(Check_Ledger_Entry__Bal__Account_Type_Caption; "Check Ledger Entry".FieldCaption("Bal. Account Type"))
            {
            }
            column(Check_Ledger_Entry__Original_Entry_Status_Caption; "Check Ledger Entry".FieldCaption("Original Entry Status"))
            {
            }
            column(Check_Ledger_Entry__Entry_Status_Caption; "Check Ledger Entry".FieldCaption("Entry Status"))
            {
            }
            column(Check_Ledger_Entry_Amount_Control47Caption; "Check Ledger Entry".FieldCaption(Amount))
            {
            }
            column(Check_Ledger_Entry_DescriptionCaption; "Check Ledger Entry".FieldCaption(Description))
            {
            }
            column(Check_Ledger_Entry__Check_No__Caption; "Check Ledger Entry".FieldCaption("Check No."))
            {
            }
            column(Check_Ledger_Entry__Check_Date_Caption; Check_Ledger_Entry__Check_Date_CaptionLbl)
            {
            }
            column(AmountVoided_Control69Caption; AmountVoided_Control69CaptionLbl)
            {
            }
            column(AmountPrinted_Control67Caption; AmountPrinted_Control67CaptionLbl)
            {
            }
            column(Bank_Account__Phone_No__Caption; FieldCaption("Phone No."))
            {
            }
            column(Bank_Account__Currency_Code_Caption; FieldCaption("Currency Code"))
            {
            }
            dataitem("Check Ledger Entry"; "Check Ledger Entry")
            {
                DataItemLink = "Bank Account No." = field("No."), "Check Date" = field("Date Filter");
                DataItemTableView = sorting("Bank Account No.", "Check Date");
                column(AmountPrinted; AmountPrinted)
                {
                    AutoFormatExpression = GetCurrencyCodeFromBank();
                    AutoFormatType = 1;
                }
                column(Check_Ledger_Entry_Amount; Amount)
                {
                }
                column(AmountVoided; AmountVoided)
                {
                    AutoFormatExpression = GetCurrencyCodeFromBank();
                    AutoFormatType = 1;
                }
                column(RecordCounter; RecordCounter)
                {
                }
                column(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
                {
                }
                column(Check_Ledger_Entry__Check_Date_; Format("Check Date"))
                {
                }
                column(Check_Ledger_Entry__Check_No__; "Check No.")
                {
                }
                column(Check_Ledger_Entry_Description; Description)
                {
                }
                column(Check_Ledger_Entry_Amount_Control47; Amount)
                {
                }
                column(Check_Ledger_Entry__Entry_Status_; "Entry Status")
                {
                }
                column(Check_Ledger_Entry__Original_Entry_Status_; "Original Entry Status")
                {
                }
                column(Check_Ledger_Entry__Bal__Account_Type_; "Bal. Account Type")
                {
                }
                column(Check_Ledger_Entry__Bal__Account_No__; "Bal. Account No.")
                {
                }
                column(Check_Ledger_Entry__Entry_No__; "Entry No.")
                {
                }
                column(AmountPrinted_Control67; AmountPrinted)
                {
                    AutoFormatExpression = GetCurrencyCodeFromBank();
                    AutoFormatType = 1;
                }
                column(AmountVoided_Control69; AmountVoided)
                {
                    AutoFormatExpression = GetCurrencyCodeFromBank();
                    AutoFormatType = 1;
                }

                trigger OnAfterGetRecord()
                begin
                    CheckLedgEntryExists := true;
                    ClearAmounts();
                    if "Entry Status" = "Entry Status"::Printed then
                        AmountPrinted := Amount;
                    if "Entry Status" = "Entry Status"::Voided then
                        AmountVoided := Amount;
                end;

                trigger OnPreDataItem()
                begin
                    RecordCounter := RecordCounter + 1;

                    CheckLedgEntryExists := false;
                    ClearAmounts();
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnAfterGetRecord()
                begin
                    if not CheckLedgEntryExists then
                        CurrReport.Skip();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.PrintOnlyIfDetail := true;
            end;

            trigger OnPreDataItem()
            begin
                RecordCounter := 0;
                ClearAmounts();
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
                    field(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Page per Bank Account';
                        ToolTip = 'Specifies if you want to print each bank account on a separate page.';
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
    end;

    var
#pragma warning disable AA0470
        PeriodLbl: Label 'Period: %1';
#pragma warning restore AA0470
        PrintOnlyOnePerPage: Boolean;
        BankAccFilter: Text;
        BankAccDateFilter: Text;
        AmountVoided: Decimal;
        AmountPrinted: Decimal;
        CheckLedgEntryExists: Boolean;
        RecordCounter: Integer;
        Bank_Account___Check_DetailsCaptionLbl: Label 'Bank Account - Check Details';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        This_report_also_includes_bank_accounts_that_only_have_balances_CaptionLbl: Label 'This report also includes bank accounts that only have balances.';
        Check_Ledger_Entry__Check_Date_CaptionLbl: Label 'Check Date';
        AmountVoided_Control69CaptionLbl: Label 'Voided Amount';
        AmountPrinted_Control67CaptionLbl: Label 'Printed Amount';

    procedure InitializeRequest(NewPrintOnlyOnePerPage: Boolean)
    begin
        PrintOnlyOnePerPage := NewPrintOnlyOnePerPage;
    end;

    local procedure ClearAmounts()
    begin
        Clear(AmountPrinted);
        Clear(AmountVoided);
    end;
}

