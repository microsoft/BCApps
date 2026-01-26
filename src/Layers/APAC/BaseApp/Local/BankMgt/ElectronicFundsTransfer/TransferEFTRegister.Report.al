// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;

report 11607 "Transfer EFT Register"
{
    Caption = 'From EFT Journal';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting(Open, "Due Date");

            trigger OnAfterGetRecord()
            begin
                CalcFields("Remaining Amount");
                if EFTRegister.Get("EFT Register No.") and EFTRegister."EFT Payment" then begin
                    I += 1;
                    ProcessWindow.Update(1, Round(I / NoOfRec * 10000, 1.0));
                    GenJnlLine1 := GenJnlLine;
                    GenJnlLine.Init();
                    GenJnlLine."Line No." += 10000;
                    GenJnlLine.SetUpNewLine(GenJnlLine1, 0, true);
                    GenJnlLine.Validate("Posting Date", PostingDate);
                    GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Vendor);
                    GenJnlLine.Validate("Account No.", "Vendor No.");
                    GenJnlLine.Validate("Document Type", "Document Type"::Payment);
                    GenJnlLine.Validate("EFT Bank Account No.", "EFT Bank Account No.");
                    if Positive then
                        GenJnlLine.Description := StrSubstNo(Text11003, "Document Type", "Document No.")
                    else
                        GenJnlLine.Description := StrSubstNo(Text11004, "Document Type", "Document No.");
                    GenJnlLine.Validate("Currency Code", "Currency Code");
                    GenJnlLine.Validate(Amount, "EFT Amount Transferred");
                    GenJnlLine.Validate("Applies-to Doc. Type", "Document Type");
                    GenJnlLine.Validate("Applies-to Doc. No.", "Document No.");
                    GenJnlLine.Insert();
                end;
            end;

            trigger OnPreDataItem()
            begin
                if DueDate = 0D then
                    Error(Text11002);

                if PostingDate = 0D then
                    Error(Text11001);

                GenJnlLine.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                GenJnlLine.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
                if GenJnlLine.FindFirst() then
                    GenJnlLine.Init()
                else
                    Clear(GenJnlLine."Line No.");

                SetRange(Open, true);
                SetFilter("Due Date", '..%1', DueDate);

                if EFTNo <> 0 then
                    SetFilter("EFT Register No.", '=%1', EFTNo)
                else
                    SetFilter("EFT Register No.", '<>0');

                ProcessWindow.Open('@1@@@@@@@@@@@@@@@@@@@@@@@@@');
                NoOfRec := Count;
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
                    field(EFTNo; EFTNo)
                    {
                        ApplicationArea = Basic, Suite;
                        BlankZero = true;
                        Caption = 'EFT No.';
                        TableRelation = "EFT Register";
                        ToolTip = 'Specifies the electronic funds transfer (EFT) file that you want to transfer.';
                    }
                    field(DueDate; DueDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Due Date';
                        ToolTip = 'Specifies the vendor due date for the EFT file.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the entry.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            Clear(EFTNo);
        end;
    }

    labels
    {
    }

    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine1: Record "Gen. Journal Line";
        EFTRegister: Record "EFT Register";
        ProcessWindow: Dialog;
        NoOfRec: Integer;
        EFTNo: Integer;
        I: Integer;
        PostingDate: Date;
        DueDate: Date;
        Text11001: Label 'Enter the posting date';
        Text11002: Label 'Enter the due date';
        Text11003: Label 'Deduction for %1 %2';
        Text11004: Label 'Payment for %1 %2';

    [Scope('OnPrem')]
    procedure SetGenJnlLine(NewGLJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine := NewGLJnlLine;
    end;
}

