// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Journal;

codeunit 1106 CostJnlManagement
{
    Permissions = TableData "Cost Journal Template" = rimd,
                  TableData "Cost Journal Batch" = rimd;

    trigger OnRun()
    begin
    end;

    var
        OpenFromBatch: Boolean;
#pragma warning disable AA0074
        Text001: Label 'STANDARD';
        Text002: Label 'Standard Template';
        Text003: Label 'DEFAULT';
        Text004: Label 'Default Batch';
#pragma warning restore AA0074

    procedure TemplateSelection(var CostJnlLine: Record "Cost Journal Line"; var JnlSelected: Boolean)
    var
        CostJnlTemplate: Record "Cost Journal Template";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTemplateSelection(CostJnlLine, JnlSelected, IsHandled);
        if IsHandled then
            exit;

        JnlSelected := true;
        CostJnlTemplate.Reset();

        case CostJnlTemplate.Count of
            0:
                begin
                    CostJnlTemplate.Init();
                    CostJnlTemplate.Name := Text001;
                    CostJnlTemplate.Description := Text002;
                    CostJnlTemplate.Insert(true);
                end;
            1:
                CostJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, CostJnlTemplate) = ACTION::LookupOK;
        end;

        if JnlSelected then begin
            CostJnlLine.FilterGroup := 2;
            CostJnlLine.SetRange("Journal Template Name", CostJnlTemplate.Name);
            CostJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                CostJnlLine."Journal Template Name" := '';
                PAGE.Run(PAGE::"Cost Journal", CostJnlLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromBatch(var CostJnlBatch: Record "Cost Journal Batch")
    var
        CostJnlLine: Record "Cost Journal Line";
        CostJnlTemplate: Record "Cost Journal Template";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTemplateSelectionFromBatch(CostJnlBatch, IsHandled);
        if IsHandled then
            exit;

        OpenFromBatch := true;
        CostJnlTemplate.Get(CostJnlBatch."Journal Template Name");
        CostJnlBatch.TestField(Name);

        CostJnlLine.FilterGroup := 2;
        CostJnlLine.SetRange("Journal Template Name", CostJnlTemplate.Name);
        CostJnlLine.FilterGroup := 0;

        CostJnlLine."Journal Template Name" := '';
        CostJnlLine."Journal Batch Name" := CostJnlBatch.Name;
        PAGE.Run(PAGE::"Cost Journal", CostJnlLine);
    end;

    procedure OpenJnl(var CostJnlBatchName: Code[10]; var CostJnlLine: Record "Cost Journal Line")
    begin
        CheckTemplateName(CostJnlLine.GetRangeMax("Journal Template Name"), CostJnlBatchName);
        CostJnlLine.FilterGroup := 2;
        CostJnlLine.SetRange("Journal Batch Name", CostJnlBatchName);
        CostJnlLine.FilterGroup := 0;
    end;

    procedure OpenJnlBatch(var CostJnlBatch: Record "Cost Journal Batch")
    var
        CostJnlTemplate: Record "Cost Journal Template";
        CostJnlLine: Record "Cost Journal Line";
        JnlSelected: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenJnlBatch(CostJnlBatch, IsHandled);
        if IsHandled then
            exit;

        if CostJnlBatch.GetFilter("Journal Template Name") <> '' then
            exit;
        CostJnlBatch.FilterGroup(2);
        if CostJnlBatch.GetFilter("Journal Template Name") <> '' then begin
            CostJnlBatch.FilterGroup(0);
            exit;
        end;
        CostJnlBatch.FilterGroup(0);

        if not CostJnlBatch.FindFirst() then begin
            if not CostJnlTemplate.FindFirst() then
                TemplateSelection(CostJnlLine, JnlSelected);
            if CostJnlTemplate.FindFirst() then
                CheckTemplateName(CostJnlTemplate.Name, CostJnlBatch.Name);
            if not CostJnlTemplate.FindFirst() then
                TemplateSelection(CostJnlLine, JnlSelected);
            if CostJnlTemplate.FindFirst() then
                CheckTemplateName(CostJnlTemplate.Name, CostJnlBatch.Name);
        end;
        CostJnlBatch.FindFirst();
        JnlSelected := true;
        if CostJnlBatch.GetFilter("Journal Template Name") <> '' then
            CostJnlTemplate.SetRange(Name, CostJnlBatch.GetFilter("Journal Template Name"));
        case CostJnlTemplate.Count of
            1:
                CostJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, CostJnlTemplate) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        CostJnlBatch.FilterGroup(0);
        CostJnlBatch.SetRange("Journal Template Name", CostJnlTemplate.Name);
        CostJnlBatch.FilterGroup(2);
    end;

    procedure CheckTemplateName(CostJnlTemplateName: Code[10]; var CostJnlBatchName: Code[10])
    var
        CostJnlBatch: Record "Cost Journal Batch";
    begin
        CostJnlBatch.SetRange("Journal Template Name", CostJnlTemplateName);
        if not CostJnlBatch.Get(CostJnlTemplateName, CostJnlBatchName) then begin
            if not CostJnlBatch.FindFirst() then begin
                CostJnlBatch.Init();
                CostJnlBatch."Journal Template Name" := CostJnlTemplateName;
                CostJnlBatch.Name := Text003;
                CostJnlBatch.Description := Text004;
                CostJnlBatch.Insert(true);
                Commit();
            end;
            CostJnlBatchName := CostJnlBatch.Name;
        end;
    end;

    procedure CheckName(CostJnlBatchName: Code[10]; var CostJnlLine: Record "Cost Journal Line")
    var
        CostJnlBatch: Record "Cost Journal Batch";
    begin
        CostJnlBatch.Get(CostJnlLine.GetRangeMax("Journal Template Name"), CostJnlBatchName);
    end;

    procedure SetName(CostJnlBatchName: Code[10]; var CostJnlLine: Record "Cost Journal Line")
    begin
        CostJnlLine.FilterGroup := 2;
        CostJnlLine.SetRange("Journal Batch Name", CostJnlBatchName);
        CostJnlLine.FilterGroup := 0;
        if CostJnlLine.FindFirst() then;
    end;

    procedure LookupName(var CostJnlBatchName: Code[10]; var CostJnlLine: Record "Cost Journal Line")
    var
        CostJnlBatch: Record "Cost Journal Batch";
    begin
        Commit();
        CostJnlBatch."Journal Template Name" := CostJnlLine.GetRangeMax("Journal Template Name");
        CostJnlBatch.Name := CostJnlLine.GetRangeMax("Journal Batch Name");
        CostJnlBatch."Journal Template Name" := CostJnlLine."Journal Template Name";
        CostJnlBatch.Name := CostJnlLine."Journal Batch Name";
        CostJnlBatch.FilterGroup(2);
        CostJnlBatch.SetRange("Journal Template Name", CostJnlBatch."Journal Template Name");
        CostJnlBatch.FilterGroup(0);
        if PAGE.RunModal(PAGE::"Cost Journal Batches", CostJnlBatch) = ACTION::LookupOK then begin
            CostJnlBatchName := CostJnlBatch.Name;
            SetName(CostJnlBatchName, CostJnlLine);
        end;
    end;

    procedure CalcBalance(var CostJnlLine: Record "Cost Journal Line"; LastCostJnlLine: Record "Cost Journal Line"; var Balance: Decimal; var TotalBalance: Decimal; var ShowBalance: Boolean; var ShowTotalBalance: Boolean)
    var
        CostJnlLine2: Record "Cost Journal Line";
    begin
        CostJnlLine2.CopyFilters(CostJnlLine);
        ShowTotalBalance := CostJnlLine2.CalcSums(Balance);
        if ShowTotalBalance then begin
            TotalBalance := CostJnlLine2.Balance;
            if CostJnlLine."Line No." = 0 then
                TotalBalance := TotalBalance + LastCostJnlLine.Balance;
        end;

        if CostJnlLine."Line No." <> 0 then begin
            CostJnlLine2.SetRange("Line No.", 0, CostJnlLine."Line No.");
            ShowBalance := CostJnlLine2.CalcSums(Balance);
            if ShowBalance then
                Balance := CostJnlLine2.Balance;
        end else begin
            CostJnlLine2.SetRange("Line No.", 0, LastCostJnlLine."Line No.");
            ShowBalance := CostJnlLine2.CalcSums(Balance);
            if ShowBalance then begin
                Balance := CostJnlLine2.Balance;
                CostJnlLine2.CopyFilters(CostJnlLine);
                CostJnlLine2 := LastCostJnlLine;
                if CostJnlLine2.Next() = 0 then
                    Balance := Balance + LastCostJnlLine.Balance;
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTemplateSelection(var CostJournalLine: Record "Cost Journal Line"; var JnlSelected: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTemplateSelectionFromBatch(var CostJnlBatch: Record "Cost Journal Batch"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJnlBatch(var CostJournalBatch: Record "Cost Journal Batch"; var IsHandled: Boolean)
    begin
    end;
}

