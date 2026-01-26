// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;

/// <summary>
/// Generates detailed check information report for bank accounts with check ledger entry details.
/// Displays check transaction history, amounts, status changes, and voided check information.
/// </summary>
/// <remarks>
/// Data Sources: Bank Account, Check Ledger Entry. 
/// Features: Check status tracking, amount calculations, void detection, entry status reporting.
/// Usage: Check audit trails, bank reconciliation support, check history analysis, compliance reporting.
/// </remarks>
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
            column(BankAccDateFilter; StrSubstNo(PeriodLbl, BankAccDateFilter))
            {
            }
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(BankAccountCaption; StrSubstNo('%1: %2', "Bank Account".TableCaption(), BankAccFilter))
            {
            }
            column(BankFilter; BankAccFilter)
            {
            }
            column(No_BankAccount; "No.")
            {
            }
            column(Name_BankAccount; Name)
            {
            }
            column(PhoneNo_BankAccount; "Phone No.")
            {
                IncludeCaption = true;
            }
            column(CurrencyCode_BankAccount; "Currency Code")
            {
                IncludeCaption = true;
            }
            column(ShowCurrencyCode; "Currency Code" <> '')
            {
            }
            column(BankAccCheckDetailsCaption; BankAccCheckDetailsCaptionLbl)
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(BankAccBalCaption; BankAccBalCaptionLbl)
            {
            }
            column(CheckDateCaption; CheckDateCaptionLbl)
            {
            }
            column(AmtVoidedCaption; AmtVoidedCaptionLbl)
            {
            }
            column(PrintedAmtCaption; PrintedAmtCaptionLbl)
            {
            }
            dataitem("Check Ledger Entry"; "Check Ledger Entry")
            {
                DataItemLink = "Bank Account No." = field("No."), "Check Date" = field("Date Filter");
                DataItemTableView = sorting("Bank Account No.", "Check Date");
                column(AmountPrinted; AmountPrinted)
                {
                    AutoFormatExpression = "Check Ledger Entry".GetCurrencyCodeFromBank();
                    AutoFormatType = 1;
                }
                column(Amount_CheckLedgerEntry; Amount)
                {
                    IncludeCaption = true;
                }
                column(AmountVoided; AmountVoided)
                {
                    AutoFormatExpression = "Check Ledger Entry".GetCurrencyCodeFromBank();
                    AutoFormatType = 1;
                }
                column(RecordCounter; RecordCounter)
                {
                }
                column(PrintOnlyOnePerPage; PrintOnlyOnePerPage)
                {
                }
                column(CheckDate_CheckLedgEntry; Format("Check Date"))
                {
                }
                column(CheckType_CheckLedgEntry; "Check Type")
                {
                }
                column(CheckNo_CheckLedgEntry; "Check No.")
                {
                    IncludeCaption = true;
                }
                column(Description_CheckLedgEntry; Description)
                {
                    IncludeCaption = true;
                }
                column(EntryStatus_CheckLedgEntry; "Entry Status")
                {
                    IncludeCaption = true;
                }
                column(OriginalEntryStatus_CheckLedgEntry; "Original Entry Status")
                {
                    IncludeCaption = true;
                }
                column(BalAccType_CheckLedgEntry; "Bal. Account Type")
                {
                    IncludeCaption = true;
                }
                column(BalAccNo_CheckLedgEntry; "Bal. Account No.")
                {
                    IncludeCaption = true;
                }
                column(EntryNo_CheckLedgerEntry; "Entry No.")
                {
                    IncludeCaption = true;
                }

                trigger OnAfterGetRecord()
                begin
                    CheckLedgEntryExists := true;
                    ClearAmounts();
                    if ("Entry Status" = "Entry Status"::Printed) or
                       (("Entry Status" = "Entry Status"::Posted) and ("Bank Payment Type" = "Bank Payment Type"::"Computer Check"))
                    then
                        AmountPrinted := Amount;
                    if ("Entry Status" = "Entry Status"::Voided) or
                       ("Entry Status" = "Entry Status"::"Financially Voided")
                    then
                        AmountVoided := Amount;
                end;

                trigger OnPreDataItem()
                begin
                    RecordCounter := RecordCounter + 1;

                    CheckLedgEntryExists := false;
                    ClearAmounts();
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
        BankAccCheckDetailsCaptionLbl: Label 'Bank Account - Check Details';
        PageNoCaptionLbl: Label 'Page';
        BankAccBalCaptionLbl: Label 'This report also includes bank accounts that only have balances.';
        CheckDateCaptionLbl: Label 'Check Date';
        AmtVoidedCaptionLbl: Label 'Voided Amount';
        PrintedAmtCaptionLbl: Label 'Printed Amount';

    /// <summary>
    /// Initializes report printing options for page layout and output formatting.
    /// Configures whether to print each bank account on a separate page.
    /// </summary>
    /// <param name="NewPrintOnlyOnePerPage">Controls single bank account per page printing behavior</param>
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

