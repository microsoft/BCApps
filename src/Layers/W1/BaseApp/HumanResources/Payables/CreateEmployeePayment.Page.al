// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Payables;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;

page 1191 "Create Employee Payment"
{
    Caption = 'Create Employee Payment';
    PageType = StandardDialog;
    SaveValues = true;

    layout
    {
        area(content)
        {
            group(Control6)
            {
                ShowCaption = false;
                field("Batch Name"; JournalBatchName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batch Name';
                    ShowMandatory = true;
                    TableRelation = "Gen. Journal Batch".Name where("Template Type" = const(Payments),
                                                                     Recurring = const(false));
                    ToolTip = 'Specifies the name of the journal batch.';

                    trigger OnValidate()
                    var
                        GenJournalBatch: Record "Gen. Journal Batch";
                    begin
                        SetJournalTemplate();
                        if JournalTemplateName <> '' then begin
                            GenJournalBatch.Get(JournalTemplateName, JournalBatchName);
                            SetNextNo(GenJournalBatch."No. Series");
                        end;
                    end;
                }
                field("Posting Date"; PostingDate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Posting Date';
                    ShowMandatory = true;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Starting Document No."; NextDocNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Starting Document No.';
                    ShowMandatory = true;
                    ToolTip = 'Specifies a document number for the journal line.';

                    trigger OnValidate()
                    begin
                        if NextDocNo <> '' then
                            if IncStr(NextDocNo) = '' then
                                Error(StartingDocumentNoErr);
                    end;
                }
                field("Bank Account"; BalAccountNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bank Account';
                    TableRelation = "Bank Account";
                    ToolTip = 'Specifies the bank account to which a balancing entry for the journal line will be posted.';
                }
                field("Payment Type"; BankPaymentType)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Type';
                    ToolTip = 'Specifies the code for the payment type to be used for the entry on the payment journal line.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        SetJournalTemplate();
        if GenJournalBatch.Get(JournalTemplateName, JournalBatchName) then
            SetNextNo(GenJournalBatch."No. Series")
        else
            Clear(JournalBatchName);
        PostingDate := WorkDate();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::OK then begin
            if JournalBatchName = '' then
                Error(BatchNumberNotFilledErr);
            if Format(PostingDate) = '' then
                Error(PostingDateNotFilledErr);
            if NextDocNo = '' then
                Error(SpecifyStartingDocNumErr);
        end;
    end;

    var
        TempEmplPaymentBuffer: Record "Employee Payment Buffer" temporary;
        PostingDate: Date;
        BalAccountNo: Code[20];
        NextDocNo: Code[20];
        JournalBatchName: Code[10];
        JournalTemplateName: Code[10];
        BankPaymentType: Enum "Bank Payment Type";
        StartingDocumentNoErr: Label 'Starting Document No.';
        BatchNumberNotFilledErr: Label 'You must fill the Batch Name field.';
        PostingDateNotFilledErr: Label 'You must fill the Posting Date field.';
        SpecifyStartingDocNumErr: Label 'In the Starting Document No. field, specify the first document number to be used.';

    procedure GetPostingDate(): Date
    begin
        exit(PostingDate);
    end;

    procedure GetBankAccount(): Text
    begin
        exit(Format(BalAccountNo));
    end;

    procedure GetBankPaymentType(): Integer
    begin
        exit(BankPaymentType.AsInteger());
    end;

    procedure GetBatchNumber(): Code[10]
    begin
        exit(JournalBatchName);
    end;

    procedure MakeGenJnlLines(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
        TempEmplPaymentBuffer.Reset();
        TempEmplPaymentBuffer.DeleteAll();

        CopyEmployeeLedgerEntriesToTempEmplPaymentBuffer(EmployeeLedgerEntry);
        CopyTempEmpPaymentBuffersToGenJnlLines();
    end;

    local procedure CopyEmployeeLedgerEntriesToTempEmplPaymentBuffer(var EmployeeLedgerEntry: Record "Employee Ledger Entry")
    var
        PaymentAmt: Decimal;
    begin
        if EmployeeLedgerEntry.Find('-') then
            repeat
                EmployeeLedgerEntry.CalcFields("Remaining Amount");
                if (EmployeeLedgerEntry."Applies-to ID" = '') and (EmployeeLedgerEntry."Remaining Amount" < 0) then begin
                    TempEmplPaymentBuffer."Employee No." := EmployeeLedgerEntry."Employee No.";
                    TempEmplPaymentBuffer."Currency Code" := EmployeeLedgerEntry."Currency Code";
                    TempEmplPaymentBuffer."Payment Method Code" := EmployeeLedgerEntry."Payment Method Code";
                    TempEmplPaymentBuffer."Creditor No." := EmployeeLedgerEntry."Creditor No.";
                    TempEmplPaymentBuffer."Payment Reference" := EmployeeLedgerEntry."Payment Reference";
                    TempEmplPaymentBuffer."Exported to Payment File" := EmployeeLedgerEntry."Exported to Payment File";
                    TempEmplPaymentBuffer."Dimension Entry No." := 0;
                    TempEmplPaymentBuffer."Global Dimension 1 Code" := '';
                    TempEmplPaymentBuffer."Global Dimension 2 Code" := '';
                    TempEmplPaymentBuffer."Dimension Set ID" := 0;
                    TempEmplPaymentBuffer."Employee Ledg. Entry No." := EmployeeLedgerEntry."Entry No.";
                    TempEmplPaymentBuffer."Employee Ledg. Entry Doc. Type" := EmployeeLedgerEntry."Document Type";
                    OnCopyEmployeeLedgerEntriesToTempEmplPaymentBufferOnAfterAssignTempBufferFields(TempEmplPaymentBuffer, EmployeeLedgerEntry);

                    PaymentAmt := -EmployeeLedgerEntry."Remaining Amount";

                    TempEmplPaymentBuffer.Reset();
                    TempEmplPaymentBuffer.SetRange("Employee No.", EmployeeLedgerEntry."Employee No.");
                    if TempEmplPaymentBuffer.Find('-') then begin
                        TempEmplPaymentBuffer.Amount := TempEmplPaymentBuffer.Amount + PaymentAmt;
                        TempEmplPaymentBuffer.Modify();
                    end else begin
                        TempEmplPaymentBuffer."Document No." := NextDocNo;
                        NextDocNo := IncStr(NextDocNo);
                        TempEmplPaymentBuffer.Amount := PaymentAmt;
                        TempEmplPaymentBuffer.Insert();
                    end;
                    EmployeeLedgerEntry."Applies-to ID" := TempEmplPaymentBuffer."Document No.";
                    EmployeeLedgerEntry."Amount to Apply" := EmployeeLedgerEntry."Remaining Amount";
                    CODEUNIT.Run(CODEUNIT::"Empl. Entry-Edit", EmployeeLedgerEntry);
                end;
            until EmployeeLedgerEntry.Next() = 0;
    end;

    local procedure CopyTempEmpPaymentBuffersToGenJnlLines()
    var
        CompanyInformation: Record "Company Information";
        GenJnlLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        Employee: Record Employee;
        BalAccType: Enum "Gen. Journal Account Type";
        LastLineNo: Integer;
    begin
        GenJnlLine.LockTable();
        GenJournalTemplate.Get(JournalTemplateName);
        GenJournalBatch.Get(JournalTemplateName, JournalBatchName);
        GenJnlLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJnlLine.SetRange("Journal Batch Name", JournalBatchName);
        if GenJnlLine.FindLast() then begin
            LastLineNo := GenJnlLine."Line No.";
            GenJnlLine.Init();
        end;

        TempEmplPaymentBuffer.Reset();
        TempEmplPaymentBuffer.SetCurrentKey("Document No.");
        TempEmplPaymentBuffer.SetFilter(
          "Employee Ledg. Entry Doc. Type", '<>%1&<>%2', TempEmplPaymentBuffer."Employee Ledg. Entry Doc. Type"::Refund,
          TempEmplPaymentBuffer."Employee Ledg. Entry Doc. Type"::Payment);
        if TempEmplPaymentBuffer.FindSet() then
            repeat
                GenJnlLine.Init();
                GenJnlLine.Validate("Journal Template Name", JournalTemplateName);
                GenJnlLine.Validate("Journal Batch Name", JournalBatchName);
                LastLineNo := LastLineNo + 10000;
                GenJnlLine."Line No." := LastLineNo;
                GenJnlLine."Document Type" := GenJnlLine."Document Type"::Payment;
                GenJnlLine."Posting No. Series" := GenJournalBatch."Posting No. Series";
                GenJnlLine."Document No." := TempEmplPaymentBuffer."Document No.";
                GenJnlLine."Account Type" := GenJnlLine."Account Type"::Employee;
                GenJnlLine.SetHideValidation(true);
                GenJnlLine.Validate("Posting Date", PostingDate);
                GenJnlLine.Validate("Account No.", TempEmplPaymentBuffer."Employee No.");

                Employee.Get(TempEmplPaymentBuffer."Employee No.");

                GenJnlLine."Bal. Account Type" := BalAccType::"Bank Account";
                GenJnlLine.Validate("Bal. Account No.", BalAccountNo);
                GenJnlLine.Validate("Currency Code", TempEmplPaymentBuffer."Currency Code");

                CompanyInformation.Get();
                GenJnlLine."Message to Recipient" := CompanyInformation.Name;

                GenJnlLine."Bank Payment Type" := BankPaymentType;
                GenJnlLine."Applies-to ID" := GenJnlLine."Document No.";
                GenJnlLine.Description := CopyStr(Employee.FullName(), 1, MaxStrLen(GenJnlLine.Description));
                GenJnlLine."Source Line No." := TempEmplPaymentBuffer."Employee Ledg. Entry No.";
                GenJnlLine."Shortcut Dimension 1 Code" := TempEmplPaymentBuffer."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := TempEmplPaymentBuffer."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := TempEmplPaymentBuffer."Dimension Set ID";
                GenJnlLine."Source Code" := GenJournalTemplate."Source Code";
                GenJnlLine."Reason Code" := GenJournalBatch."Reason Code";
                GenJnlLine.Validate(Amount, TempEmplPaymentBuffer.Amount);
                GenJnlLine."Applies-to Doc. Type" := TempEmplPaymentBuffer."Employee Ledg. Entry Doc. Type";
                GenJnlLine."Applies-to Doc. No." := TempEmplPaymentBuffer."Employee Ledg. Entry Doc. No.";
                GenJnlLine.Validate("Payment Method Code", TempEmplPaymentBuffer."Payment Method Code");
                GenJnlLine."Creditor No." := CopyStr(TempEmplPaymentBuffer."Creditor No.", 1, MaxStrLen(GenJnlLine."Creditor No."));
                GenJnlLine."Payment Reference" := CopyStr(TempEmplPaymentBuffer."Payment Reference", 1, MaxStrLen(GenJnlLine."Payment Reference"));
                GenJnlLine."Exported to Payment File" := TempEmplPaymentBuffer."Exported to Payment File";
                GenJnlLine."Applies-to Ext. Doc. No." := TempEmplPaymentBuffer."Applies-to Ext. Doc. No.";

                UpdateDimensions(GenJnlLine, TempEmplPaymentBuffer);
                GenJnlLine.Insert();
            until TempEmplPaymentBuffer.Next() = 0;
    end;

    local procedure UpdateDimensions(var GenJnlLine: Record "Gen. Journal Line"; TempEmplPaymentBuffer: Record "Employee Payment Buffer" temporary)
    var
        DimBuf: Record "Dimension Buffer";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimVal: Record "Dimension Value";
        DimBufMgt: Codeunit "Dimension Buffer Management";
        DimMgt: Codeunit DimensionManagement;
        NewDimensionID: Integer;
        DimSetIDArr: array[10] of Integer;
    begin
        OnBeforeUpdateDimensions(GenJnlLine, TempEmplPaymentBuffer);
        NewDimensionID := GenJnlLine."Dimension Set ID";

        DimBuf.Reset();
        DimBuf.DeleteAll();
        DimBufMgt.GetDimensions(TempEmplPaymentBuffer."Dimension Entry No.", DimBuf);
        if DimBuf.FindSet() then
            repeat
                DimVal.Get(DimBuf."Dimension Code", DimBuf."Dimension Value Code");
                TempDimSetEntry."Dimension Code" := DimBuf."Dimension Code";
                TempDimSetEntry."Dimension Value Code" := DimBuf."Dimension Value Code";
                TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
                TempDimSetEntry.Insert();
            until DimBuf.Next() = 0;
        NewDimensionID := DimMgt.GetDimensionSetID(TempDimSetEntry);
        GenJnlLine."Dimension Set ID" := NewDimensionID;

        GenJnlLine.CreateDimFromDefaultDim(0);
        if NewDimensionID <> GenJnlLine."Dimension Set ID" then
            AssignCombinedDimensionSetID(GenJnlLine, DimSetIDArr, NewDimensionID);

        DimMgt.GetDimensionSet(TempDimSetEntry, GenJnlLine."Dimension Set ID");
        DimMgt.UpdateGlobalDimFromDimSetID(GenJnlLine."Dimension Set ID", GenJnlLine."Shortcut Dimension 1 Code",
          GenJnlLine."Shortcut Dimension 2 Code");

        OnAfterUpdateDimensions(GenJnlLine);
    end;

    local procedure AssignCombinedDimensionSetID(var GenJournalLine: Record "Gen. Journal Line"; var DimSetIDArr: array[10] of Integer; NewDimensionID: Integer)
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimSetIDArr[1] := GenJournalLine."Dimension Set ID";
        DimSetIDArr[2] := NewDimensionID;
        GenJournalLine."Dimension Set ID" := DimensionManagement.GetCombinedDimensionSetID(DimSetIDArr, GenJournalLine."Shortcut Dimension 1 Code", GenJournalLine."Shortcut Dimension 2 Code");

        OnAfterAssignCombinedDimensionSetID(GenJournalLine, DimSetIDArr);
    end;

    local procedure SetJournalTemplate()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.Reset();
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        GenJournalTemplate.SetRange(Recurring, false);
        if GenJournalTemplate.FindFirst() then
            JournalTemplateName := GenJournalTemplate.Name;
    end;

    local procedure SetNextNo(GenJournalBatchNoSeries: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
    begin
        if GenJournalBatchNoSeries = '' then
            NextDocNo := ''
        else begin
            GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
            GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
            if GenJournalLine.FindLast() then
                NextDocNo := IncStr(GenJournalLine."Document No.")
            else
                NextDocNo := NoSeries.PeekNextNo(GenJournalBatchNoSeries, PostingDate);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDimensions(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignCombinedDimensionSetID(var GenJournalLine: Record "Gen. Journal Line"; DimSetIDArr: array[10] of Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateDimensions(var GenJournalLine: Record "Gen. Journal Line"; TempEmployeePaymentBuffer: Record "Employee Payment Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyEmployeeLedgerEntriesToTempEmplPaymentBufferOnAfterAssignTempBufferFields(var TempEmployeePaymentBuffer: Record "Employee Payment Buffer" temporary; EmployeeLedgerEntry: Record "Employee Ledger Entry")
    begin
    end;
}

