// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Insurance;

using Microsoft.FixedAssets.FixedAsset;

codeunit 5656 InsuranceJnlManagement
{
    Permissions = TableData "Insurance Journal Template" = rimd,
                  TableData "Insurance Journal Batch" = rimd;

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'INSURANCE';
        Text001: Label 'Insurance Journal';
        Text002: Label 'DEFAULT';
        Text003: Label 'Default Journal';
#pragma warning restore AA0074
        OldInsuranceNo: Code[20];
        OldFANo: Code[20];
        OpenFromBatch: Boolean;

    procedure TemplateSelection(PageID: Integer; var InsuranceJnlLine: Record "Insurance Journal Line"; var JnlSelected: Boolean)
    var
        InsuranceJnlTempl: Record "Insurance Journal Template";
    begin
        JnlSelected := true;

        InsuranceJnlTempl.Reset();
        InsuranceJnlTempl.SetRange("Page ID", PageID);

        case InsuranceJnlTempl.Count of
            0:
                begin
                    InsuranceJnlTempl.Init();
                    InsuranceJnlTempl.Name := Text000;
                    InsuranceJnlTempl.Description := Text001;
                    InsuranceJnlTempl.Validate("Page ID");
                    InsuranceJnlTempl.Insert();
                    Commit();
                end;
            1:
                InsuranceJnlTempl.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, InsuranceJnlTempl) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            InsuranceJnlLine.FilterGroup := 2;
            InsuranceJnlLine.SetRange("Journal Template Name", InsuranceJnlTempl.Name);
            InsuranceJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                InsuranceJnlLine."Journal Template Name" := '';
                PAGE.Run(InsuranceJnlTempl."Page ID", InsuranceJnlLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromBatch(var InsuranceJnlBatch: Record "Insurance Journal Batch")
    var
        InsuranceJnlLine: Record "Insurance Journal Line";
        InsuranceJnlTempl: Record "Insurance Journal Template";
    begin
        OpenFromBatch := true;
        InsuranceJnlTempl.Get(InsuranceJnlBatch."Journal Template Name");
        InsuranceJnlTempl.TestField("Page ID");
        InsuranceJnlBatch.TestField(Name);

        InsuranceJnlLine.FilterGroup := 2;
        InsuranceJnlLine.SetRange("Journal Template Name", InsuranceJnlTempl.Name);
        InsuranceJnlLine.FilterGroup := 0;

        InsuranceJnlLine."Journal Template Name" := '';
        InsuranceJnlLine."Journal Batch Name" := InsuranceJnlBatch.Name;
        PAGE.Run(InsuranceJnlTempl."Page ID", InsuranceJnlLine);
    end;

    procedure OpenJournal(var CurrentJnlBatchName: Code[10]; var InsuranceJnlLine: Record "Insurance Journal Line")
    begin
        OnBeforeOpenJournal(CurrentJnlBatchName, InsuranceJnlLine);

        CheckTemplateName(InsuranceJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        InsuranceJnlLine.FilterGroup := 2;
        InsuranceJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        InsuranceJnlLine.FilterGroup := 0;
    end;

    procedure OpenJnlBatch(var InsuranceJnlBatch: Record "Insurance Journal Batch")
    var
        InsuranceJnlTemplate: Record "Insurance Journal Template";
        InsuranceJnlLine: Record "Insurance Journal Line";
        JnlSelected: Boolean;
    begin
        if InsuranceJnlBatch.GetFilter("Journal Template Name") <> '' then
            exit;
        InsuranceJnlBatch.FilterGroup(2);
        if InsuranceJnlBatch.GetFilter("Journal Template Name") <> '' then begin
            InsuranceJnlBatch.FilterGroup(0);
            exit;
        end;
        InsuranceJnlBatch.FilterGroup(0);

        if not InsuranceJnlBatch.Find('-') then begin
            if not InsuranceJnlTemplate.FindFirst() then
                TemplateSelection(0, InsuranceJnlLine, JnlSelected);
            if InsuranceJnlTemplate.FindFirst() then
                CheckTemplateName(InsuranceJnlTemplate.Name, InsuranceJnlBatch.Name);
        end;
        InsuranceJnlBatch.Find('-');
        JnlSelected := true;
        if InsuranceJnlBatch.GetFilter("Journal Template Name") <> '' then
            InsuranceJnlTemplate.SetRange(Name, InsuranceJnlBatch.GetFilter("Journal Template Name"));
        case InsuranceJnlTemplate.Count of
            1:
                InsuranceJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, InsuranceJnlTemplate) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        InsuranceJnlBatch.FilterGroup(0);
        InsuranceJnlBatch.SetRange("Journal Template Name", InsuranceJnlTemplate.Name);
        InsuranceJnlBatch.FilterGroup(2);
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; var InsuranceJnlLine: Record "Insurance Journal Line")
    var
        InsuranceJnlBatch: Record "Insurance Journal Batch";
    begin
        InsuranceJnlBatch.Get(InsuranceJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var InsuranceJnlLine: Record "Insurance Journal Line")
    begin
        InsuranceJnlLine.FilterGroup := 2;
        InsuranceJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        InsuranceJnlLine.FilterGroup := 0;
        if InsuranceJnlLine.Find('-') then;
    end;

    procedure LookupName(var CurrentJnlBatchName: Code[10]; var InsuranceJnlLine: Record "Insurance Journal Line")
    var
        InsuranceJnlBatch: Record "Insurance Journal Batch";
    begin
        Commit();
        InsuranceJnlBatch."Journal Template Name" := InsuranceJnlLine.GetRangeMax("Journal Template Name");
        InsuranceJnlBatch.Name := InsuranceJnlLine.GetRangeMax("Journal Batch Name");
        InsuranceJnlBatch.FilterGroup(2);
        InsuranceJnlBatch.SetRange("Journal Template Name", InsuranceJnlBatch."Journal Template Name");
        InsuranceJnlBatch.FilterGroup(0);
        if PAGE.RunModal(0, InsuranceJnlBatch) = ACTION::LookupOK then begin
            CurrentJnlBatchName := InsuranceJnlBatch.Name;
            SetName(CurrentJnlBatchName, InsuranceJnlLine);
        end;
    end;

    local procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        InsuranceJnlBatch: Record "Insurance Journal Batch";
    begin
        if not InsuranceJnlBatch.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            InsuranceJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
            if not InsuranceJnlBatch.FindFirst() then begin
                InsuranceJnlBatch.Init();
                InsuranceJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
                InsuranceJnlBatch.SetupNewBatch();
                InsuranceJnlBatch.Name := Text002;
                InsuranceJnlBatch.Description := Text003;
                InsuranceJnlBatch.Insert(true);
                Commit();
            end;
            CurrentJnlBatchName := InsuranceJnlBatch.Name;
        end;
    end;

    procedure GetDescriptions(InsuranceJnlLine: Record "Insurance Journal Line"; var InsuranceDescription: Text[100]; var FADescription: Text[100])
    var
        Insurance: Record Insurance;
        FA: Record "Fixed Asset";
    begin
        if InsuranceJnlLine."Insurance No." <> OldInsuranceNo then begin
            InsuranceDescription := '';
            if InsuranceJnlLine."Insurance No." <> '' then
                if Insurance.Get(InsuranceJnlLine."Insurance No.") then
                    InsuranceDescription := Insurance.Description;
            OldInsuranceNo := InsuranceJnlLine."Insurance No.";
        end;
        if InsuranceJnlLine."FA No." <> OldFANo then begin
            FADescription := '';
            if InsuranceJnlLine."FA No." <> '' then
                if FA.Get(InsuranceJnlLine."FA No.") then
                    FADescription := FA.Description;
            OldFANo := FA."No.";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJournal(var CurrentJnlBatchName: Code[10]; var InsuranceJournalLine: Record "Insurance Journal Line")
    begin
    end;
}

