// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Foundation.Company;
using System.Utilities;

report 12112 "Bank Sheet - Print"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Reports/BankSheetPrint.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'Bank Sheet - Print';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            DataItemTableView = sorting("No.") order(ascending);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Date Filter";
            column(CompAddr5; CompAddr[5])
            {
            }
            column(CompAddr4; CompAddr[4])
            {
            }
            column(CompAddr3; CompAddr[3])
            {
            }
            column(PeroidBankDateFilter; Text1035 + BankDateFilter)
            {
            }
            column(CompAddr2; CompAddr[2])
            {
            }
            column(CompAddr1; CompAddr[1])
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(Filters1; Filters[1])
            {
            }
            column(Filters2; Filters[2])
            {
            }
            column(BankFilterNo; BankFilterNo)
            {
            }
            column(BankAccBankAccNoBankAccName; Text1038 + "Bank Account"."No." + ' - ' + "Bank Account".Name)
            {
            }
            column(No_BankAccount; "No.")
            {
            }
            column(DateFilter_BankAccount; "Date Filter")
            {
            }
            column(PageNoCaption; PageNoCaptionLbl)
            {
            }
            column(BankSheetCaption; BankSheetCaptionLbl)
            {
            }
            column(AccountNoCaption; AccountNoCaptionLbl)
            {
            }
            column(DepartmentCodeCaption; DepartmentCodeCaptionLbl)
            {
            }
            column(ProjectNoCaption; ProjectNoCaptionLbl)
            {
            }
            column(IncreasesAmntCaption; DebitCaptionLbl)
            {
            }
            column(DecreasesAmntCaption; CreditCaptionLbl)
            {
            }
            column(AmtCaption; BalanceCaptionLbl)
            {
            }
            column(BankAccLedgEntryDocNoCaption; "Bank Account Ledger Entry".FieldCaption("Document No."))
            {
            }
            column(BankAccLedgEntryDocDateCaption; DocumentDateCaptionLbl)
            {
            }
            column(Bank_AccLedgEntryExternalDocNoCaption; "Bank Account Ledger Entry".FieldCaption("External Document No."))
            {
            }
            column(BankAccLedgEntryDescCaption; "Bank Account Ledger Entry".FieldCaption(Description))
            {
            }
            column(Bank_AccLedgEntryPostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(BankAccLedgEntryTransactionNoCaption; "Bank Account Ledger Entry".FieldCaption("Transaction No."))
            {
            }
            column(BankAccLedgEntryEntryNoCaption; "Bank Account Ledger Entry".FieldCaption("Entry No."))
            {
            }
            dataitem(PageCounter; "Integer")
            {
                DataItemTableView = sorting(Number) order(ascending) where(Number = const(1));
                column(MinimumDateFormat; Format(MinimumDate))
                {
                }
                column(StartOnHand; StartOnHand)
                {
                    AutoFormatType = 1;
                    DecimalPlaces = 0 : 5;
                }
                column(ProgressiveTotAtCaption; ProgressiveTotAtCaptionLbl)
                {
                }
                column(PrintedEntriesTotCaption; PrintedEntriesTotCaptionLbl)
                {
                }
                column(PrintedEntriesTotProgressiveTotCaption; PrintedEntriesTotProgressiveTotCaptionLbl)
                {
                }
                dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
                {
                    DataItemLink = "Bank Account No." = field("No."), "Posting Date" = field("Date Filter");
                    DataItemLinkReference = "Bank Account";
                    DataItemTableView = sorting("Bank Account No.", "Posting Date") order(ascending);
                    column(StartOnHandAmount; StartOnHand + Amount)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                        DecimalPlaces = 0 : 5;
                    }
                    column(Amt; Amnt)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(DecreasesAmt; DecreasesAmnt)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(IncreasesAmt; IcreasesAmnt)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(Desc_BankAccLedgEntry; Description)
                    {
                    }
                    column(ExternalDocNo_BankAccLedgEntry; "External Document No.")
                    {
                    }
                    column(DocDateFormat_BankAccLedgEntry; Format("Document Date"))
                    {
                    }
                    column(DocNo_BankAccLedgEntry; "Document No.")
                    {
                    }
                    column(PostingDateFormat_BankAccLedgEntry; Format("Posting Date"))
                    {
                    }
                    column(TransactionNo_BankAccLedgEntry; "Transaction No.")
                    {
                    }
                    column(EntryNo_BankAccLedgEntry; "Entry No.")
                    {
                    }
                    column(Amount_BankAccLedgEntry; Amount)
                    {
                        AutoFormatExpression = "Currency Code";
                        AutoFormatType = 1;
                    }
                    column(BankAccNo_BankAccLedgEntry; "Bank Account No.")
                    {
                    }
                    column(PostingDate_BankAccLedgEntry; "Posting Date")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        Amnt := Amnt + Amount;
                        IcreasesAmnt := 0;
                        DecreasesAmnt := 0;
                        if Amount > 0 then
                            IcreasesAmnt := Amount
                        else
                            DecreasesAmnt := Abs(Amount);
                    end;
                }

                trigger OnAfterGetRecord()
                var
                    BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
                begin
                    BankAccountLedgerEntry.SetRange("Bank Account No.", "Bank Account"."No.");
                    BankAccountLedgerEntry.SetFilter("Posting Date", BankDateFilter);
                    if (StartOnHand = 0) and (BankAccountLedgerEntry.Count = 0) then
                        CurrReport.Skip();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                StartOnHand := 0;
                if BankDateFilter <> '' then
                    if GetRangeMin("Date Filter") > 00000101D then begin
                        SetRange("Date Filter", 0D, GetRangeMin("Date Filter") - 1);
                        CalcFields("Net Change");
                        StartOnHand := "Net Change";
                        SetFilter("Date Filter", BankDateFilter);
                    end;
                Amnt := StartOnHand;
            end;

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                CompAddr[1] := CompanyInfo.Name;
                CompAddr[2] := CompanyInfo.Address;
                CompAddr[3] := CompanyInfo."Post Code";
                CompAddr[4] := CompanyInfo.City;
                CompAddr[5] := CompanyInfo."Fiscal Code";
                CompressArray(CompAddr);

                if "Bank Account".GetFilter("No.") <> '' then
                    BankFilterNo := "Bank Account".GetFilter("No.")
                else
                    BankFilterNo := Text1036;
            end;
        }
    }

    requestpage
    {

        layout
        {
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
        BankDateFilter := "Bank Account".GetFilter("Date Filter");
        if BankDateFilter <> '' then
            MinimumDate := "Bank Account".GetRangeMin("Date Filter") - 1;
    end;

    var
        Text1035: Label 'Period: ';
        Text1036: Label 'ALL';
        Text1038: Label 'Bank Account ';
        CompanyInfo: Record "Company Information";
        CompAddr: array[5] of Text[100];
        BankFilterNo: Text[30];
        BankDateFilter: Text;
        Amnt: Decimal;
        StartOnHand: Decimal;
        IcreasesAmnt: Decimal;
        DecreasesAmnt: Decimal;
        Filters: array[2] of Text[20];
        MinimumDate: Date;
        PageNoCaptionLbl: Label 'Page';
        BankSheetCaptionLbl: Label 'Bank Sheet';
        AccountNoCaptionLbl: Label 'Account No.';
        DepartmentCodeCaptionLbl: Label 'Department Code';
        ProjectNoCaptionLbl: Label 'Project No.';
        DebitCaptionLbl: Label 'Debit Amount';
        CreditCaptionLbl: Label 'Credit Amount';
        BalanceCaptionLbl: Label 'Balance';
        DocumentDateCaptionLbl: Label 'Document Date';
        PostingDateCaptionLbl: Label 'Posting Date';
        ProgressiveTotAtCaptionLbl: Label 'Progressive Total at';
        PrintedEntriesTotCaptionLbl: Label 'Printed Entries Total';
        PrintedEntriesTotProgressiveTotCaptionLbl: Label 'Printed Entries Total + Progressive Total';
}

