// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.ElectronicFundsTransfer;
using Microsoft.Finance.GeneralLedger.Journal;

report 10084 "Void/Transmit Elec. Payments"
{
    Caption = 'Void/Transmit Electronic Payments';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.") where("Document Type" = filter(Payment | Refund), "Bank Payment Type" = filter("Electronic Payment" | "Electronic Payment-IAT"), "Check Printed" = const(true), "Check Exported" = const(true), "Check Transmitted" = const(false));

            trigger OnAfterGetRecord()
            begin
                if "Account Type" = "Account Type"::"Bank Account" then begin
                    if "Account No." <> BankAccount."No." then
                        CurrReport.Skip();
                end else
                    if "Bal. Account Type" = "Bal. Account Type"::"Bank Account" then begin
                        if "Bal. Account No." <> BankAccount."No." then
                            CurrReport.Skip();
                    end else
                        CurrReport.Skip();

                if FirstTime then begin
                    case UsageType of
                        UsageType::Void:
                            if "Check Transmitted" then
                                Error(Text001);
                        UsageType::Transmit:
                            begin
                                if not RTCConfirmTransmit() then
                                    exit;
                                if "Check Transmitted" then
                                    Error(Text003);
                            end;
                    end;
                    FirstTime := false;
                end;
                CheckManagement.ProcessElectronicPayment("Gen. Journal Line", UsageType);

                if UsageType = UsageType::Void then begin
                    "Check Exported" := false;
                    "Check Printed" := false;
                    "Document No." := '';
                    ClearApplication("Gen. Journal Line");
                    CleanEFTExportTable("Gen. Journal Line");
                    "EFT Export Sequence No." := 0;
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
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("BankAccount.""No."""; BankAccount."No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account No.';
                        TableRelation = "Bank Account";
                        ToolTip = 'Specifies the bank account that the payment is transmitted to.';
                    }
                    field(DisplayUsageType; DisplayUsageType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'E-Pay Operation';
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
                Error(Text004);
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        BankAccount.Get(BankAccount."No.");
        BankAccount.TestField(Blocked, false);
        BankAccount.TestField("Export Format");

        if UsageType <> UsageType::Transmit then
            if not Confirm(Text000,
                 false,
                 UsageType,
                 BankAccount.TableCaption,
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
        Text000: Label 'Are you SURE you want to %1 all of the Electronic Payments written against %2 %3?';
        Text001: Label 'The export file has already been transmitted. You can no longer void these entries.';
        Text003: Label 'The export file has already been transmitted.';
        Text004: Label 'This process can only be run from the Payment Journal';
        Text005: Label 'Has export file been successfully transmitted?';

    procedure SetUsageType(NewUsageType: Option ,Void,Transmit)
    begin
        UsageType := NewUsageType;
    end;

    procedure RTCConfirmTransmit(): Boolean
    begin
        if not Confirm(Text005, false) then
            exit(false);

        exit(true);
    end;

    procedure SetBankAccountNo(AccountNumber: Code[20])
    begin
        BankAccount.Get(AccountNumber);
    end;

    local procedure CleanEFTExportTable(var GenJournalLine: Record "Gen. Journal Line")
    var
        EFTExport: Record "EFT Export";
    begin
        if EFTExport.Get(
            GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name",
            GenJournalLine."Line No.",
            GenJournalLine."EFT Export Sequence No.")
        then
            EFTExport.Delete();
    end;

    local procedure ClearApplication(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if (GenJournalLine."Applies-to Doc. Type" <> GenJournalLine."Applies-to Doc. Type"::" ") or (GenJournalLine.IsApplied()) then
            exit;

        if GenJournalLine."Applies-to ID" <> '' then begin
            GenJournalLine.Validate("Applies-to ID", '');
            GenJournalLine.Validate("Applies-to Doc. No.", '');
        end;
    end;
}

