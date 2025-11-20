// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Graph;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.API.Upgrade;

codeunit 5478 "Graph Mgt - Journal Lines"
{

    trigger OnRun()
    begin
    end;

    var
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";

    procedure SetJournalLineTemplateAndBatch(var GenJournalLine: Record "Gen. Journal Line"; JournalLineBatchName: Code[10])
    begin
        GenJournalLine.Validate("Journal Template Name", GraphMgtJournal.GetDefaultJournalLinesTemplateName());
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");

        GenJournalLine.Validate("Journal Batch Name", JournalLineBatchName);
        GenJournalLine.SetRange("Journal Batch Name", JournalLineBatchName);
    end;

    procedure SetJournalLineTemplateAndBatchV2(var GenJournalLine: Record "Gen. Journal Line"; var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");

        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
    end;

    procedure SetJournalLineFilters(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::" ");
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.SetRange("Journal Template Name", GraphMgtJournal.GetDefaultJournalLinesTemplateName());
    end;

    procedure SetJournalLineFiltersV1(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::" ");
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Account Type"::"Bank Account");
        GenJournalLine.SetRange("Journal Template Name", GraphMgtJournal.GetDefaultJournalLinesTemplateName());
    end;

    procedure SetJournalLineValues(var GenJournalLine: Record "Gen. Journal Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DummyDate: Date;
    begin
        DummyDate := 0D;
        GenJournalLine.Validate("Account Type", TempGenJournalLine."Account Type");
        GenJournalLine.Validate("Account No.", TempGenJournalLine."Account No.");
        if TempGenJournalLine."Posting Date" <> DummyDate then
            GenJournalLine.Validate("Posting Date", TempGenJournalLine."Posting Date");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::" ");
        if TempGenJournalLine."Document No." <> '' then
            GenJournalLine.Validate("Document No.", TempGenJournalLine."Document No.");
        GenJournalLine.Validate("External Document No.", TempGenJournalLine."External Document No.");
        GenJournalLine.Validate(Amount, TempGenJournalLine.Amount);
        if TempGenJournalLine.Description <> '' then
            GenJournalLine.Validate(Description, TempGenJournalLine.Description);
        GenJournalLine.Validate(Comment, TempGenJournalLine.Comment);
        GenJournalLine.Validate("Bal. Account No.", '');
        if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then begin
            GenJournalLine.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type");
            GenJournalLine.Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");
        end;
        if TempGenJournalLine."Bal. Account Type" <> GenJournalLine."Bal. Account Type" then
            GenJournalLine.Validate("Bal. Account Type", TempGenJournalLine."Bal. Account Type");
        if (TempGenJournalLine."Bal. Account No." <> '') and (TempGenJournalLine."Bal. Account No." <> GenJournalLine."Bal. Account No.") then
            GenJournalLine.Validate("Bal. Account No.", TempGenJournalLine."Bal. Account No.");
        if TempGenJournalLine."Tax Group Code" <> GenJournalLine."Tax Group Code" then
            GenJournalLine.Validate("Tax Group Code", TempGenJournalLine."Tax Group Code");

        if GenJournalLine.CopyVATSetupToJnlLines() then
            SetPostingGroupValues(GenJournalLine, TempGenJournalLine);
    end;

    procedure SetPaymentsValues(var GenJournalLine: Record "Gen. Journal Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        DummyDate: Date;
    begin
        if not IsNullGuid(TempGenJournalLine."Account Id") then
            GenJournalLine.Validate("Account Id", TempGenJournalLine."Account Id");
        GenJournalLine.Validate("Account No.", TempGenJournalLine."Account No.");
        if TempGenJournalLine."Contact Graph Id" <> '' then
            GenJournalLine.Validate("Contact Graph Id", TempGenJournalLine."Contact Graph Id");
        if TempGenJournalLine."Posting Date" <> DummyDate then
            GenJournalLine.Validate("Posting Date", TempGenJournalLine."Posting Date");
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate("Document No.", TempGenJournalLine."Document No.");
        GenJournalLine.Validate("External Document No.", TempGenJournalLine."External Document No.");
        GenJournalLine.Validate(Amount, TempGenJournalLine.Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine."Applies-to Doc. No." := TempGenJournalLine."Applies-to Doc. No.";
        if not IsNullGuid(TempGenJournalLine."Applies-to Invoice Id") then
            GenJournalLine.Validate("Applies-to Invoice Id", TempGenJournalLine."Applies-to Invoice Id");
        if TempGenJournalLine.Description <> '' then
            GenJournalLine.Validate(Description, TempGenJournalLine.Description);
        GenJournalLine.Validate(Comment, TempGenJournalLine.Comment);
        GenJournalLine.Validate("Bal. Account No.", '');
        if GenJournalBatch.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name") then begin
            GenJournalLine.Validate("Bal. Account Type", GenJournalBatch."Bal. Account Type");
            GenJournalLine.Validate("Bal. Account No.", GenJournalBatch."Bal. Account No.");
        end
    end;

    local procedure SetPostingGroupValues(var GenJournalLine: Record "Gen. Journal Line"; TempGenJournalLine: Record "Gen. Journal Line" temporary)
    begin
        if TempGenJournalLine."Gen. Posting Type" <> GenJournalLine."Gen. Posting Type" then
            GenJournalLine."Gen. Posting Type" := TempGenJournalLine."Gen. Posting Type";
        if TempGenJournalLine."Gen. Bus. Posting Group" <> GenJournalLine."Gen. Bus. Posting Group" then
            GenJournalLine."Gen. Bus. Posting Group" := TempGenJournalLine."Gen. Bus. Posting Group";
        if TempGenJournalLine."Gen. Prod. Posting Group" <> GenJournalLine."Gen. Prod. Posting Group" then
            GenJournalLine."Gen. Prod. Posting Group" := TempGenJournalLine."Gen. Prod. Posting Group";
        if TempGenJournalLine."VAT Bus. Posting Group" <> GenJournalLine."VAT Bus. Posting Group" then
            GenJournalLine."VAT Bus. Posting Group" := TempGenJournalLine."VAT Bus. Posting Group";
        if TempGenJournalLine."VAT Prod. Posting Group" <> GenJournalLine."VAT Prod. Posting Group" then
            GenJournalLine."VAT Prod. Posting Group" := TempGenJournalLine."VAT Prod. Posting Group";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'ApiSetup', '', false, false)]
    local procedure HandleApiSetup()
    begin
        UpdateIds();
    end;

    procedure UpdateIds()
    begin
        UpdateIds(false);
    end;

    procedure UpdateIds(WithCommit: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        APIDataUpgrade: Codeunit "API Data Upgrade";
        RecordCount: Integer;
    begin
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");

        if GenJournalLine.FindSet() then begin
            repeat
                GenJournalLine.UpdateAccountID();
                GenJournalLine.UpdateJournalBatchID();
                GenJournalLine.Modify(false);
                if WithCommit then
                    APIDataUpgrade.CountRecordsAndCommit(RecordCount);
            until GenJournalLine.Next() = 0;

            if WithCommit then
                Commit();
        end;
    end;
}

