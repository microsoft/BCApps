// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Check;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using System.IO;

/// <summary>
/// Manages electronic payment transmission and voiding operations for exported payment files.
/// Processes electronic payments through bank-specific transmission protocols and void procedures.
/// </summary>
/// <remarks>
/// Data source: Gen. Journal Line filtered for electronic payments exported but not transmitted.
/// Integrates with CheckManagement codeunit for electronic payment processing.
/// Supports both void operations for untransmitted payments and transmission for ready payments.
/// </remarks>
report 9200 "Void/Transmit Elec. Pmnts"
{
    Caption = 'Void/Transmit Electronic Payments';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.") where("Document Type" = filter(Payment | Refund), "Bank Payment Type" = filter("Electronic Payment" | "Electronic Payment-IAT"), "Exported to Payment File" = const(true), "Check Transmitted" = const(false));

            trigger OnAfterGetRecord()
            var
                ExpUserFeedbackGenJnl: Codeunit "Exp. User Feedback Gen. Jnl.";
            begin
                if SkipReport("Account Type", "Bal. Account Type", "Account No.", "Bal. Account No.", BankAccount."No.") then
                    CurrReport.Skip();

                if FirstTime then begin
                    case UsageType of
                        UsageType::Void:
                            if "Check Transmitted" then
                                Error(AlreadyTransmittedNoVoidErr);
                        UsageType::Transmit:
                            begin
                                if "Check Transmitted" then
                                    Error(AlreadyTransmittedErr);
                                if "Document No." = '' then
                                    Error(VoidedOrNoDocNoErr);
                                if not RTCConfirmTransmit() then
                                    exit;
                            end;
                    end;
                    FirstTime := false;
                end;
                if UsageType = UsageType::Void then
                    ExpUserFeedbackGenJnl.SetExportFlagOnAppliedCustVendLedgerEntry("Gen. Journal Line", false);
                CheckManagement.ProcessElectronicPayment("Gen. Journal Line", UsageType);

                if UsageType = UsageType::Void then begin
                    "Check Printed" := false;
                    "Check Exported" := false;
                    "Document No." := '';
                    "Exported to Payment File" := false;
                end else
                    "Check Transmitted" := true;
                Modify();
            end;

            trigger OnPreDataItem()
            begin
                FirstTime := true;
            end;
        }
    }

    requestpage
    {
        SaveValues = false;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
#pragma warning disable AA0100
                    field("BankAccount.""No."""; BankAccount."No.")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account No.';
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies the bank account that the payment is transmitted to.';
                    }
                    field(DisplayUsageType; DisplayUsageType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Operation';
                        Editable = false;
                        OptionCaption = ',Void,Transmit';
                        ToolTip = 'Specifies if you want to transmit or void the electronic payment file. The Transmit option produces an electronic payment file to be transmitted to your bank for processing. The Void option voids the exported file. Confirm that the correct selection has been made before you process the electronic payment file.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            DisplayUsageType := UsageType;
            if DisplayUsageType = 0 then
                Error(OnlyRunFromPaymentJournalErr);
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField(Blocked, false);

        if UsageType <> UsageType::Transmit then
            if not Confirm(ActionConfirmQst,
                 false,
                 UsageType,
                 BankAccount.TableCaption(),
                 BankAccount."No.")
            then
                CurrReport.Quit();
    end;

    var
        BankAccount: Record "Bank Account";
        CheckManagement: Codeunit CheckManagement;
        FirstTime: Boolean;
        UsageType: Option ,Void,Transmit;
        DisplayUsageType: Option ,Void,Transmit;
        ActionConfirmQst: Label 'Are you SURE you want to %1 all of the Electronic Payments written against %2 %3?', Comment = '%1=Action taken., %2=Name of the Bank Account table., %3=Bank Account Number.';
        AlreadyTransmittedNoVoidErr: Label 'The export file has already been transmitted. You can no longer void these entries.';
        AlreadyTransmittedErr: Label 'The export file has already been transmitted.';
        OnlyRunFromPaymentJournalErr: Label 'This process can only be run from the Payment Journal.';
        TransmittedQst: Label 'Has export file been successfully transmitted?';
        VoidedOrNoDocNoErr: Label 'The export file cannot be transmitted if the payment has been voided or is missing a Document No.';

    /// <summary>
    /// Sets the usage type for the electronic payment operation.
    /// </summary>
    /// <param name="NewUsageType">Usage type to set (Void or Transmit)</param>
    procedure SetUsageType(NewUsageType: Option ,Void,Transmit)
    begin
        UsageType := NewUsageType;
    end;

    /// <summary>
    /// Displays confirmation dialog for electronic payment transmission.
    /// </summary>
    /// <returns>True if user confirms transmission, false otherwise</returns>
    procedure RTCConfirmTransmit(): Boolean
    begin
        if not Confirm(TransmittedQst, false) then
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// Sets the bank account number for electronic payment processing.
    /// </summary>
    /// <param name="AccountNumber">Bank account number to set</param>
    procedure SetBankAccountNo(AccountNumber: Code[20])
    begin
        BankAccount.Get(AccountNumber);
    end;

    local procedure SkipReport(AccountType: Enum "Gen. Journal Account Type"; BalAccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountNo: Code[20]; BankAccountNo: Code[20]): Boolean
    begin
        if AccountType = AccountType::"Bank Account" then
            if AccountNo <> BankAccountNo then
                exit(true);

        if BalAccountType = BalAccountType::"Bank Account" then
            if BalAccountNo <> BankAccountNo then
                exit(true);

        if (AccountType <> AccountType::"Bank Account") and (BalAccountType <> BalAccountType::"Bank Account") then
            exit(true);
    end;
}

