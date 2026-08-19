// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Foundation.Company;
using System.Utilities;

report 10409 "Bank Account - Reconcile"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Bank/Reconciliation/BankAccountReconcile.rdlc';
    Caption = 'Bank Account - Reconcile';

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            DataItemTableView = sorting("No.");
            PrintOnlyIfDetail = true;
            RequestFilterFields = "No.", "Bank Acc. Posting Group", "Date Filter";
            column(PeriodBankAccDateFilte; 'Period: ' + BankAccDateFilter)
            {
            }
            column(TodayFormatted; Format(Today, 0, 4))
            {
            }
            column(CompanyInfoName; CompanyInformation.Name)
            {
            }
            column(NewPagePerRecordNo; NewPagePerRecordNo)
            {
            }
            column(BankAccFilter; BankAccFilter)
            {
            }
            column(ListChecks; ListChecks)
            {
            }
            column(TblCaptionBankAccFilter; "Bank Account".TableCaption + ': ' + BankAccFilter)
            {
            }
            column(No_BankAccount; "No.")
            {
            }
            column(BankAccountName; Name)
            {
            }
            column(PhoneNo_BankAccount; "Phone No.")
            {
            }
            column(CurrCode_BankAccount; "Currency Code")
            {
            }
            column(BankAccountReconcileCaption; BankAccountReconcileCaptionLbl)
            {
            }
            column(PageCaption; PageCaptionLbl)
            {
            }
            column(PhoneNoCaption_BankAccount; FieldCaption("Phone No."))
            {
            }
            column(CurrCodeCaption_BankAccount; FieldCaption("Currency Code"))
            {
            }
            dataitem(Withdrawals; "Bank Account Ledger Entry")
            {
                DataItemLink = "Bank Account No." = field("No.");
                DataItemTableView = sorting("Bank Account No.", "Posting Date");
                column(Amount_Withdrawals; Amount)
                {
                }
                column(PostingDate_Withdrawals; "Posting Date")
                {
                }
                column(Description_Withdrawals; Description)
                {
                }
                column(EntryNo_Withdrawals; "Entry No.")
                {
                }
                column(BankAccountNo_Withdrawals; "Bank Account No.")
                {
                }
                column(WithdrawalsCaption; WithdrawalsCaptionLbl)
                {
                }
                column(AmountCaption_Withdrawals; FieldCaption(Amount))
                {
                }
                column(DescriptionCaption_Withdrawals; FieldCaption(Description))
                {
                }
                column(PostingDateCaption_Withdrawals; FieldCaption("Posting Date"))
                {
                }
                column(CheckNoCaption_CheckLedgEntry; "Check Ledger Entry".FieldCaption("Check No."))
                {
                }
                column(WithdrawalsTotalCaption; WithdrawalsTotalCaptionLbl)
                {
                }
                dataitem("Check Ledger Entry"; "Check Ledger Entry")
                {
                    DataItemLink = "Bank Account No." = field("Bank Account No."), "Bank Account Ledger Entry No." = field("Entry No.");
                    DataItemTableView = sorting("Bank Account No.", "Check Date") where("Entry Status" = const(Posted));
                    column(CheckNo_CheckLedgEntry; "Check No.")
                    {
                    }
                    column(Description_CheckLedgEntry; Description)
                    {
                    }
                    column(Amount_CheckLedgEntry; ReversedCheckAmount)
                    {
                    }
                    column(PostingDate_CheckLedgEntry; "Posting Date")
                    {
                    }
                    column(EntryNo_CheckLedgEntry; "Entry No.")
                    {
                    }
                    column(BankAccountNo_CheckLedgEntry; "Bank Account No.")
                    {
                    }
                    column(BankAcLedgEntryNo_CheckLedgEntry; "Bank Account Ledger Entry No.")
                    {
                    }

                    trigger OnAfterGetRecord()
                    begin
                        ReversedCheckAmount := -Amount;
                        WithdrawAmount := WithdrawAmount + ReversedCheckAmount;
                    end;

                    trigger OnPreDataItem()
                    begin
                        if not ListChecks then
                            CurrReport.Skip();
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    CheckLedgEntry.SetCurrentKey("Bank Account Ledger Entry No.");
                    CheckLedgEntry.SetRange("Bank Account Ledger Entry No.", "Entry No.");
                    CheckLedgEntry.SetRange("Entry Status", CheckLedgEntry."Entry Status"::Posted);
                    if CheckLedgEntry.FindFirst() then
                        ListChecks := true
                    else begin
                        ListChecks := false;
                        WithdrawAmount := WithdrawAmount + Amount;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Posting Date", BankAccDateFilter);
                    SetFilter("Document Type", '%1|%2', "Document Type"::Payment, "Document Type"::Refund);
                    SetRange(Positive, false);
                end;
            }
            dataitem(Deposits; "Bank Account Ledger Entry")
            {
                DataItemLink = "Bank Account No." = field("No.");
                DataItemTableView = sorting("Bank Account No.", "Posting Date");
                column(Amount_Deposits; Amount)
                {
                }
                column(PostingDate_Deposits; "Posting Date")
                {
                }
                column(Description_Deposits; Description)
                {
                }
                column(EntryNo_Deposits; "Entry No.")
                {
                }
                column(BankAccountNo_Deposits; "Bank Account No.")
                {
                }
                column(DepositsCaption; DepositsCaptionLbl)
                {
                }
                column(AmountCaption_Deposits; FieldCaption(Amount))
                {
                }
                column(PostingDateCaption_Deposits; FieldCaption("Posting Date"))
                {
                }
                column(DescriptionCaption_Deposits; FieldCaption(Description))
                {
                }
                column(DepositsTotalCaption; DepositsTotalCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    DepositAmount := DepositAmount + Amount;
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Posting Date", BankAccDateFilter);
                    SetFilter("Document Type", '%1|%2', "Document Type"::Payment, "Document Type"::Refund);
                    SetRange(Positive, true);
                end;
            }
            dataitem(Adjustments; "Bank Account Ledger Entry")
            {
                DataItemLink = "Bank Account No." = field("No.");
                DataItemTableView = sorting("Bank Account No.", "Posting Date");
                column(Amount_Adjustments; Amount)
                {
                }
                column(Description_Adjustments; Description)
                {
                }
                column(PostingDate_Adjustments; "Posting Date")
                {
                }
                column(EntryNo_Adjustments; "Entry No.")
                {
                }
                column(BankAccountNo_Adjustments; "Bank Account No.")
                {
                }
                column(AdjustmentsCaption; AdjustmentsCaptionLbl)
                {
                }
                column(AmountCaption_Adjustments; FieldCaption(Amount))
                {
                }
                column(DescriptionCaption_Adjustments; FieldCaption(Description))
                {
                }
                column(PostingDateCaption_Adjustments; FieldCaption("Posting Date"))
                {
                }
                column(AdjustmentsTotalAmtCaption; AdjustmentsTotalAmtCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    AdjustAmount := AdjustAmount + Amount;
                end;

                trigger OnPreDataItem()
                begin
                    SetFilter("Posting Date", BankAccDateFilter);
                    SetFilter("Document Type", '<>%1&<>%2', "Document Type"::Payment, "Document Type"::Refund);
                end;
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number);
                MaxIteration = 1;
                column(WithdrawAmount; WithdrawAmount)
                {
                }
                column(DepositAmount; DepositAmount)
                {
                }
                column(AdjustAmount; AdjustAmount)
                {
                }
                column(WithdrawCaptionInterger; WithdrawalsCaptionLbl)
                {
                }
                column(DepositAmountCaption; DepositsCaptionLbl)
                {
                }
                column(AdjustmentCaptionInteger; AdjustmentsCaptionLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                Clear(WithdrawAmount);
                Clear(DepositAmount);
                Clear(AdjustAmount);

                if PrintOnlyOnePerPage then
                    NewPagePerRecordNo := NewPagePerRecordNo + 1;
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
        CompanyInformation.Get();
    end;

    var
        CompanyInformation: Record "Company Information";
        CheckLedgEntry: Record "Check Ledger Entry";
        PrintOnlyOnePerPage: Boolean;
        ListChecks: Boolean;
        BankAccFilter: Text;
        BankAccDateFilter: Text;
        WithdrawAmount: Decimal;
        DepositAmount: Decimal;
        AdjustAmount: Decimal;
        ReversedCheckAmount: Decimal;
        NewPagePerRecordNo: Integer;
        BankAccountReconcileCaptionLbl: Label 'Bank Account - Reconcile';
        PageCaptionLbl: Label 'Page';
        WithdrawalsCaptionLbl: Label 'Withdrawals';
        WithdrawalsTotalCaptionLbl: Label 'Withdrawal Total';
        DepositsCaptionLbl: Label 'Deposits';
        DepositsTotalCaptionLbl: Label 'Deposit Total';
        AdjustmentsCaptionLbl: Label 'Adjustments';
        AdjustmentsTotalAmtCaptionLbl: Label 'Adjustment Total';
}

