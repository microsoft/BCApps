// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;

codeunit 1020 JobJnlManagement
{
    Permissions = TableData "Job Journal Template" = rimd,
                  TableData "Job Journal Batch" = rimd,
                  TableData "Job Entry No." = rimd;

    trigger OnRun()
    begin
    end;

    var
        LastJobJnlLine: Record "Job Journal Line";
        OpenFromBatch: Boolean;

#pragma warning disable AA0074
        Text000: Label 'PROJECT';
        Text001: Label 'Project Journal';
        Text002: Label 'RECURRING';
        Text003: Label 'Recurring Project Journal';
        Text004: Label 'DEFAULT';
        Text005: Label 'Default Journal';
#pragma warning restore AA0074

    procedure TemplateSelection(PageID: Integer; RecurringJnl: Boolean; var JobJnlLine: Record "Job Journal Line"; var JnlSelected: Boolean)
    var
        JobJnlTemplate: Record "Job Journal Template";
    begin
        JnlSelected := true;

        JobJnlTemplate.Reset();
        JobJnlTemplate.SetRange("Page ID", PageID);
        JobJnlTemplate.SetRange(Recurring, RecurringJnl);
        OnTemplateSelectionOnAfterJobJnlTemplateSetFilters(PageID, RecurringJnl, JobJnlLine, JobJnlTemplate);
        case JobJnlTemplate.Count of
            0:
                begin
                    JobJnlTemplate.Init();
                    JobJnlTemplate.Recurring := RecurringJnl;
                    if not RecurringJnl then begin
                        JobJnlTemplate.Name := Text000;
                        JobJnlTemplate.Description := Text001;
                    end else begin
                        JobJnlTemplate.Name := Text002;
                        JobJnlTemplate.Description := Text003;
                    end;
                    JobJnlTemplate.Validate("Page ID");
                    JobJnlTemplate.Insert();
                    Commit();
                end;
            1:
                JobJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, JobJnlTemplate) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            JobJnlLine.FilterGroup := 2;
            JobJnlLine.SetRange("Journal Template Name", JobJnlTemplate.Name);
            JobJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                JobJnlLine."Journal Template Name" := '';
                PAGE.Run(JobJnlTemplate."Page ID", JobJnlLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromBatch(var JobJnlBatch: Record "Job Journal Batch")
    var
        JobJnlLine: Record "Job Journal Line";
        JobJnlTemplate: Record "Job Journal Template";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTemplateSelectionFromBatch(JobJnlBatch, OpenFromBatch, IsHandled);
        if IsHandled then
            exit;

        OpenFromBatch := true;
        JobJnlTemplate.Get(JobJnlBatch."Journal Template Name");
        JobJnlTemplate.TestField("Page ID");
        JobJnlBatch.TestField(Name);

        JobJnlLine.FilterGroup := 2;
        JobJnlLine.SetRange("Journal Template Name", JobJnlTemplate.Name);
        JobJnlLine.FilterGroup := 0;

        JobJnlLine."Journal Template Name" := '';
        JobJnlLine."Journal Batch Name" := JobJnlBatch.Name;
        PAGE.Run(JobJnlTemplate."Page ID", JobJnlLine);
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var JobJnlLine: Record "Job Journal Line")
    begin
        OnBeforeOpenJnl(CurrentJnlBatchName, JobJnlLine);

        CheckTemplateName(JobJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        JobJnlLine.FilterGroup := 2;
        JobJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        JobJnlLine.FilterGroup := 0;
    end;

    procedure OpenJnlBatch(var JobJnlBatch: Record "Job Journal Batch")
    var
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlLine: Record "Job Journal Line";
        JnlSelected: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenJnlBatch(JobJnlBatch, IsHandled);
        if IsHandled then
            exit;

        if JobJnlBatch.GetFilter("Journal Template Name") <> '' then
            exit;
        JobJnlBatch.FilterGroup(2);
        if JobJnlBatch.GetFilter("Journal Template Name") <> '' then begin
            JobJnlBatch.FilterGroup(0);
            exit;
        end;
        JobJnlBatch.FilterGroup(0);

        if not JobJnlBatch.Find('-') then begin
            if not JobJnlTemplate.FindFirst() then
                TemplateSelection(0, false, JobJnlLine, JnlSelected);
            if JobJnlTemplate.FindFirst() then
                CheckTemplateName(JobJnlTemplate.Name, JobJnlBatch.Name);
            JobJnlTemplate.SetRange(Recurring, true);
            if not JobJnlTemplate.FindFirst() then
                TemplateSelection(0, true, JobJnlLine, JnlSelected);
            if JobJnlTemplate.FindFirst() then
                CheckTemplateName(JobJnlTemplate.Name, JobJnlBatch.Name);
            JobJnlTemplate.SetRange(Recurring);
        end;
        JobJnlBatch.Find('-');
        JnlSelected := true;
        JobJnlBatch.CalcFields(Recurring);
        JobJnlTemplate.SetRange(Recurring, JobJnlBatch.Recurring);
        if JobJnlBatch.GetFilter("Journal Template Name") <> '' then
            JobJnlTemplate.SetRange(Name, JobJnlBatch.GetFilter("Journal Template Name"));
        case JobJnlTemplate.Count of
            1:
                JobJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, JobJnlTemplate) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        JobJnlBatch.FilterGroup(0);
        JobJnlBatch.SetRange("Journal Template Name", JobJnlTemplate.Name);
        JobJnlBatch.FilterGroup(2);
    end;

    local procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        JobJnlBatch: Record "Job Journal Batch";
    begin
        JobJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        if not JobJnlBatch.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            if not JobJnlBatch.FindFirst() then begin
                JobJnlBatch.Init();
                JobJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
                JobJnlBatch.SetupNewBatch();
                JobJnlBatch.Name := Text004;
                JobJnlBatch.Description := Text005;
                JobJnlBatch.Insert(true);
                Commit();
            end;
            CurrentJnlBatchName := JobJnlBatch.Name;
        end;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; var JobJnlLine: Record "Job Journal Line")
    var
        JobJnlBatch: Record "Job Journal Batch";
    begin
        JobJnlBatch.Get(JobJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var JobJnlLine: Record "Job Journal Line")
    begin
        JobJnlLine.FilterGroup := 2;
        JobJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        JobJnlLine.FilterGroup := 0;
        if JobJnlLine.Find('-') then;
    end;

    procedure LookupName(var CurrentJnlBatchName: Code[10]; var JobJnlLine: Record "Job Journal Line")
    var
        JobJnlBatch: Record "Job Journal Batch";
    begin
        Commit();
        JobJnlBatch."Journal Template Name" := JobJnlLine.GetRangeMax("Journal Template Name");
        JobJnlBatch.Name := JobJnlLine.GetRangeMax("Journal Batch Name");
        JobJnlBatch.FilterGroup(2);
        JobJnlBatch.SetRange("Journal Template Name", JobJnlBatch."Journal Template Name");
        OnLookupNameOnAfterSetFilters(JobJnlBatch);
        JobJnlBatch.FilterGroup(0);
        if PAGE.RunModal(0, JobJnlBatch) = ACTION::LookupOK then begin
            CurrentJnlBatchName := JobJnlBatch.Name;
            SetName(CurrentJnlBatchName, JobJnlLine);
        end;
    end;

    procedure GetNames(var JobJnlLine: Record "Job Journal Line"; var JobDescription: Text[100]; var AccName: Text[100])
    var
        Res: Record Resource;
        Item: Record Item;
        GLAcc: Record "G/L Account";
    begin
        JobDescription := GetJobDescription(JobJnlLine);

        if (JobJnlLine.Type <> LastJobJnlLine.Type) or
           (JobJnlLine."No." <> LastJobJnlLine."No.")
        then begin
            AccName := '';
            if JobJnlLine."No." <> '' then
                case JobJnlLine.Type of
                    JobJnlLine.Type::Resource:
                        if Res.Get(JobJnlLine."No.") then
                            AccName := Res.Name;
                    JobJnlLine.Type::Item:
                        if Item.Get(JobJnlLine."No.") then
                            AccName := Item.Description;
                    JobJnlLine.Type::"G/L Account":
                        if GLAcc.Get(JobJnlLine."No.") then
                            AccName := GLAcc.Name;
                end;
        end;

        LastJobJnlLine := JobJnlLine;
    end;

    local procedure GetJobDescription(JobJnlLine: Record "Job Journal Line") JobDescription: Text[100]
    var
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetJobDescription(JobJnlLine, LastJobJnlLine, JobDescription, IsHandled);
        if IsHandled then
            exit(JobDescription);

        if (JobJnlLine."Job No." = '') or
           (JobJnlLine."Job No." <> LastJobJnlLine."Job No.")
        then begin
            JobDescription := '';
            if Job.Get(JobJnlLine."Job No.") then
                JobDescription := Job.Description;
        end;
    end;

    procedure GetNextEntryNo(): Integer
    var
        JobEntryNo: Record "Job Entry No.";
    begin
        JobEntryNo.LockTable();
        if not JobEntryNo.Get() then
            JobEntryNo.Insert();
        JobEntryNo."Entry No." := JobEntryNo."Entry No." + 1;
        JobEntryNo.Modify();
        exit(JobEntryNo."Entry No.");
    end;

    procedure ShowItemAvailabilityFromJobJournalLines(var JobJournalLine: Record "Job Journal Line"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        JobJournalLine.TestField(Type, JobJournalLine.Type::Item);
        JobJournalLine.TestField("No.");

        Item.Reset();
        Item.Get(JobJournalLine."No.");
        ItemAvailabilityFormsMgt.FilterItem(Item, JobJournalLine."Location Code", JobJournalLine."Variant Code", JobJournalLine."Posting Date");

        case AvailabilityType of
            AvailabilityType::Period:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByPeriod(Item, JobJournalLine.FieldCaption(JobJournalLine."Posting Date"), JobJournalLine."Posting Date", NewDate) then
                    JobJournalLine.Validate(JobJournalLine."Posting Date", NewDate);
            AvailabilityType::Variant:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByVariant(Item, JobJournalLine.FieldCaption(JobJournalLine."Variant Code"), JobJournalLine."Variant Code", NewVariantCode) then
                    JobJournalLine.Validate(JobJournalLine."Variant Code", NewVariantCode);
            AvailabilityType::Location:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByLocation(Item, JobJournalLine.FieldCaption(JobJournalLine."Location Code"), JobJournalLine."Location Code", NewLocationCode) then
                    JobJournalLine.Validate(JobJournalLine."Location Code", NewLocationCode);
            AvailabilityType::"Event":
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByEvent(Item, JobJournalLine.FieldCaption(JobJournalLine."Posting Date"), JobJournalLine."Posting Date", NewDate, false) then
                    JobJournalLine.Validate(JobJournalLine."Posting Date", NewDate);
            AvailabilityType::BOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByBOMLevel(Item, JobJournalLine.FieldCaption(JobJournalLine."Posting Date"), JobJournalLine."Posting Date", NewDate) then
                    JobJournalLine.Validate(JobJournalLine."Posting Date", NewDate);
            AvailabilityType::UOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByUOM(Item, JobJournalLine.FieldCaption(JobJournalLine."Unit of Measure Code"), JobJournalLine."Unit of Measure Code", NewUnitOfMeasureCode) then
                    JobJournalLine.Validate(JobJournalLine."Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupNameOnAfterSetFilters(var JobJournalBatch: Record "Job Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJnlBatch(var JobJournalBatch: Record "Job Journal Batch"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetJobDescription(JobJnlLine: Record "Job Journal Line"; LastJobJnlLine: Record "Job Journal Line"; var JobDescription: Text[100]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJnl(var CurrentJnlBatchName: Code[10]; var JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTemplateSelectionFromBatch(var JobJnlBatch: Record "Job Journal Batch"; var OpenFromBatch: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplateSelectionOnAfterJobJnlTemplateSetFilters(PageID: Integer; RecurringJnl: Boolean; var JobJnlLine: Record "Job Journal Line"; var JobJournalTemplate: Record "Job Journal Template")
    begin
    end;
}

