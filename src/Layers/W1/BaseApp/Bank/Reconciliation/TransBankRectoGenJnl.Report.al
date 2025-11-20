// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;

report 1497 "Trans. Bank Rec. to Gen. Jnl."
{
    Caption = 'Trans. Bank Rec. to Gen. Jnl.';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Bank Acc. Reconciliation"; "Bank Acc. Reconciliation")
        {
            DataItemTableView = sorting("Bank Account No.", "Statement No.") where("Statement Type" = const("Bank Reconciliation"));
            dataitem("Bank Acc. Reconciliation Line"; "Bank Acc. Reconciliation Line")
            {
                DataItemLink = "Bank Account No." = field("Bank Account No."), "Statement No." = field("Statement No.");
                DataItemTableView = sorting("Bank Account No.", "Statement No.", "Statement Line No.");

                trigger OnAfterGetRecord()
                var
                    SourceCodeSetup: Record "Source Code Setup";
                    MatchBankRecLines: Codeunit "Match Bank Rec. Lines";
                begin
                    if Difference = 0 then
                        CurrReport.Skip();
                    if not TempBankAccReconciliationLine.IsEmpty() then
                        if not TempBankAccReconciliationLine.get(
                            "Bank Acc. Reconciliation Line"."Statement Type",
                            "Bank Acc. Reconciliation Line"."Bank Account No.",
                            "Bank Acc. Reconciliation Line"."Statement No.",
                            "Bank Acc. Reconciliation Line"."Statement Line No.") then
                            CurrReport.Skip();

                    GenJnlLine.Init();
                    GenJnlLine."Line No." := GenJnlLine."Line No." + 10000;
                    GenJnlLine.Validate("Posting Date", "Transaction Date");
                    SourceCodeSetup.Get();
                    case
                        GenJnlTemplate.Type of
                        GenJnlTemplate.Type::General:
                            GenJnlLine."Source Code" := SourceCodeSetup."General Journal";
                        GenJnlTemplate.Type::Purchases:
                            GenJnlLine."Source Code" := SourceCodeSetup."Purchase Journal";
                        GenJnlTemplate.Type::Sales:
                            GenJnlLine."Source Code" := SourceCodeSetup."Sales Journal";
                        else
                            GenJnlLine."Source Code" := SourceCodeSetup."Trans. Bank Rec. to Gen. Jnl.";
                    end;
                    if "Document No." <> '' then
                        GenJnlLine."Document No." := "Document No."
                    else
                        if GenJnlBatch."No. Series" <> '' then
                            GenJnlLine."Document No." := NoSeriesBatch.GetNextNo(GenJnlBatch."No. Series", "Transaction Date");
                    GenJnlLine."Posting No. Series" := GenJnlBatch."Posting No. Series";

                    if (GenJnlBatch."Bal. Account No." <> '') and
                       ((GenJnlBatch."Bal. Account Type" <> GenJnlBatch."Bal. Account Type"::"Bank Account") or
                        (GenJnlBatch."Bal. Account No." <> "Bank Acc. Reconciliation"."Bank Account No."))
                    then begin
                        GenJnlLine.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type");
                        GenJnlLine.Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
                        GenJnlLine.Validate(Amount, Difference);
                    end else begin
                        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Account Type"::"Bank Account");
                        GenJnlLine.Validate("Bal. Account No.", "Bank Acc. Reconciliation"."Bank Account No.");
                        GenJnlLine.Validate(Amount, -Difference);
                    end;

                    GenJnlLine.Description := Description;
                    GenJnlLine."Keep Description" := true;
                    OnBeforeGenJnlLineInsert(GenJnlLine, "Bank Acc. Reconciliation Line");
                    if not MatchBankRecLines.BankReconciliationLineInManyToOne("Bank Acc. Reconciliation Line") then begin
                        GenJnlLine."Linked Table ID" := Database::"Bank Acc. Reconciliation Line";
                        GenJnlLine."Linked System ID" := "Bank Acc. Reconciliation Line".SystemId;
                    end;
                    GenJnlLine.Insert();
                end;

                trigger OnPreDataItem()
                begin
                    GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                    GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                    GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
                    if GenJnlBatch.Name <> '' then
                        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name)
                    else
                        GenJnlLine.SetRange("Journal Batch Name", '');

                    GenJnlLine.LockTable();
                    if GenJnlLine.FindLast() then;
                end;
            }

            trigger OnPreDataItem()
            begin
                SetRange("Statement Type", BankAccRecon."Statement Type");
                SetRange("Bank Account No.", BankAccRecon."Bank Account No.");
                SetRange("Statement No.", BankAccRecon."Statement No.");
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
#pragma warning disable AA0100
                    field("GenJnlLine.""Journal Template Name"""; GenJnlLine."Journal Template Name")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gen. Journal Template';
                        NotBlank = true;
                        TableRelation = "Gen. Journal Template";
                        ToolTip = 'Specifies the general journal template that the entries are placed in.';
                    }
#pragma warning disable AA0100
                    field("GenJnlLine.""Journal Batch Name"""; GenJnlLine."Journal Batch Name")
#pragma warning restore AA0100
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Gen. Journal Batch';
                        Lookup = true;
                        NotBlank = true;
                        ToolTip = 'Specifies the general journal batch that the entries are placed in.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJnlTemplate.Get(GenJnlLine."Journal Template Name");
                            GenJnlBatch.FilterGroup(2);
                            GenJnlBatch.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
                            GenJnlBatch.FilterGroup(0);
                            GenJnlBatch.Name := GenJnlLine."Journal Batch Name";
                            if GenJnlBatch.Find('=><') then;
                            if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then begin
                                Text := GenJnlBatch.Name;
                                exit(true);
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            GenJnlLine.TestField("Journal Template Name");
                            GenJnlBatch.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name");
                        end;
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
        TempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary;

    trigger OnPostReport()
    begin
        GenJnlManagement.TemplateSelectionFromBatch(GenJnlBatch);
    end;

    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        BankAccRecon: Record "Bank Acc. Reconciliation";
        GenJnlManagement: Codeunit GenJnlManagement;
        NoSeriesBatch: Codeunit "No. Series - Batch";

    procedure SetBankAccRecon(var UseBankAccRecon: Record "Bank Acc. Reconciliation")
    begin
        BankAccRecon := UseBankAccRecon;
    end;

    procedure SetBankAccReconLine(var UsetempBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line" temporary)
    begin
        if UsetempBankAccReconciliationLine.FindSet() then
            repeat
                TempBankAccReconciliationLine := UseTempBankAccReconciliationLine;
                TempBankAccReconciliationLine.Insert();
            until UsetempBankAccReconciliationLine.Next() = 0;
    end;

    procedure InitializeRequest(GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10])
    begin
        GenJnlLine."Journal Template Name" := GenJnlTemplateName;
        GenJnlLine."Journal Batch Name" := GenJnlBatchName;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGenJnlLineInsert(var GenJournalLine: Record "Gen. Journal Line"; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
    end;
}

