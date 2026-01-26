// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

report 11608 "Create EFT File"
{
    Caption = 'Create EFT File';
    Permissions = TableData "Vendor Ledger Entry" = rim;
    ProcessingOnly = true;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");

            trigger OnAfterGetRecord()
            begin
                Counter += 1;
                ProcessWindow.Update(1, Round(Counter / NoOfRec * 10000, 1.0));
                if Vendor.Get("Account No.") then
                    if Vendor."EFT Payment" then
                        Vendor.TestField("EFT Bank Account No.")
                    else
                        Error(Text11003, "Account No.");
                TestField("EFT Payment");
                if "EFT Register No." <> 0 then
                    Error(PaymentAlreadyExportedErr, "Journal Template Name", "Journal Batch Name", "Line No.");
                BankAccountNo := GetBankAccountNo("Gen. Journal Line");
                if (PrevBankAcctNo <> '') and (PrevBankAcctNo <> BankAccountNo) then
                    Error(BankAccountNotTheSameErr, BankAccountNo, "Line No.", PrevBankAcctNo);

                if "EFT Payment" then begin
                    VendBankAcc.Get(Vendor."No.", "EFT Bank Account No.");
                    VendBankAcc.TestField("Bank Account No.");
                    VendBankAcc.TestField("EFT BSB No.");
                end;

                if VendLedgEntry."EFT Register No." <> 0 then
                    Error(Text11001, Format("Applies-to Doc. Type"), "Applies-to Doc. No.",
                      VendLedgEntry.FieldCaption("EFT Register No."), VendLedgEntry."EFT Register No.");

                "EFT Register No." := EFTRegister."No.";
                Modify();

                PrevBankAcctNo := BankAccountNo;
            end;

            trigger OnPostDataItem()
            begin
                ProcessWindow.Close();

                if Counter = 0 then
                    Error(NothingToExportErr);
                BankAcc.Get(BankAccountNo);
                BankAcc.TestField("Bank Account No.");
                BankAcc.TestField("EFT Bank Code");
                BankAcc.TestField("EFT BSB No.");
                BankAcc.TestField("EFT Security No.");
                OnGenJournalLinePostDataItemOnBeforeEFTRegisterInsert(EFTRegister, BankAcc);
                EFTRegister.Insert();
                EFTManagement.CreateFileFromEFTRegister(EFTRegister, EFTFileDescription, BankAcc);
            end;

            trigger OnPreDataItem()
            begin
                if EFTFileDescription = '' then
                    Error(Text11007);

                SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");

                EFTRegister.Reset();
                EFTRegister.LockTable();
                if not EFTRegister.FindLast() then
                    Clear(EFTRegister."No.");
                EFTRegister."No." += 1;

                EFTRegister.Init();
                EFTRegister."EFT Payment" := true;
                SetFilter("Account No.", '<>%1', '');
                SetRange("Account Type", "Account Type"::Vendor);

                GenJnlLine1.CopyFilters(GenJnlLine);

                ProcessWindow.Open('@1@@@@@@@@@@@@@@@@@@@@@@@@@');
                NoOfRec := GenJnlLine1.Count();
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(EFTFileDescription; EFTFileDescription)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'EFT File Description';
                        ToolTip = 'Specifies a description for the EFT file.';
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

    var
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        VendBankAcc: Record "Vendor Bank Account";
        GenJnlLine1: Record "Gen. Journal Line";
        EFTManagement: Codeunit "EFT Management";
        ProcessWindow: Dialog;
        Counter: Integer;
        NoOfRec: Integer;
        PrevBankAcctNo: Code[20];
        Text11001: Label '%1 %2 already exist in %3 %4.';
        Text11003: Label 'EFT Type must not be blank for Vendor No. %1.';
        Text11007: Label 'Please enter the EFT File Description.', Comment = 'Input for description of EFT File.';
        BankAccountNo: Code[20];
        BankAccountNotTheSameErr: Label 'The file can be created for one bank account only. Balancing bank account number %1 for line %2 does not match bank account number %3.', Comment = '%1 and %3 - bank account number, %2 - journal line number.';
        NothingToExportErr: Label 'There is nothing to export.';
        PaymentAlreadyExportedErr: Label 'Line number %3 in journal template name %1, journal batch name %2 has been already exported.', Comment = '%1 - journal template name, %2 - journal batch name, %3 - line number';
    protected var
        EFTRegister: Record "EFT Register";
        GenJnlLine: Record "Gen. Journal Line";    
        BankAcc: Record "Bank Account";
        EFTFileDescription: Text[12];

    procedure SetGenJnlLine(NewGLJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine := NewGLJnlLine;
    end;

    [Scope('OnPrem')]
    procedure GetServerFileName(): Text
    begin
        exit(EFTManagement.GetServerFileName());
    end;

    local procedure GetBankAccountNo(GenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        BalGenJournalLine: Record "Gen. Journal Line";
    begin
        if GenJournalLine."Bal. Account No." <> '' then
            exit(GenJournalLine."Bal. Account No.");

        BalGenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        BalGenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        BalGenJournalLine.SetRange("Document No.", GenJnlLine."Document No.");
        BalGenJournalLine.SetRange("Posting Date", GenJnlLine."Posting Date");
        BalGenJournalLine.SetRange("Account Type", BalGenJournalLine."Account Type"::"Bank Account");
        BalGenJournalLine.FindFirst();
        exit(BalGenJournalLine."Account No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGenJournalLinePostDataItemOnBeforeEFTRegisterInsert(var EFTRegister: Record "EFT Register"; var BankAccount: Record "Bank Account")
    begin
    end;
}

