// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;

codeunit 7037 "Price Source - Job Task" implements "Price Source"
{
    var
        Job: Record Job; // Parent
        JobTask: Record "Job Task";

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        if JobTask.GetBySystemId(PriceSource."Source ID") then begin
            JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
            PriceSource."Parent Source No." := JobTask."Job No.";
            PriceSource."Source No." := JobTask."Job Task No.";
            FillAdditionalFields(PriceSource);
        end else
            PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        if VerifyParent(PriceSource) then
            if JobTask.Get(PriceSource."Parent Source No.", PriceSource."Source No.") then begin
                JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
                PriceSource."Source ID" := JobTask.SystemId;
                FillAdditionalFields(PriceSource);
            end else
                PriceSource.InitSource();
    end;

    procedure IsForAmountType(AmountType: Enum "Price Amount Type"): Boolean
    begin
        exit(true);
    end;

    procedure IsSourceNoAllowed() Result: Boolean;
    begin
        Result := true;
    end;

    procedure IsLookupOK(var PriceSource: Record "Price Source"): Boolean
    var
        xPriceSource: Record "Price Source";
    begin
        xPriceSource := PriceSource;
        if Job.Get(xPriceSource."Parent Source No.") then;
        if (Job."No." <> '') and (xPriceSource."Source No." = '') then
            JobTask.SetRange("Job No.", xPriceSource."Parent Source No.")
        else
            if Page.RunModal(Page::"Job List", Job) = ACTION::LookupOK then begin
                xPriceSource.Validate("Parent Source No.", Job."No.");
                JobTask.SetRange("Job No.", xPriceSource."Parent Source No.");
            end else
                exit(false);

        if JobTask.Get(xPriceSource."Parent Source No.", xPriceSource."Source No.") then;
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        if Page.RunModal(Page::"Job Task List", JobTask) = ACTION::LookupOK then begin
            xPriceSource.Validate("Parent Source No.", JobTask."Job No.");
            xPriceSource.Validate("Source No.", JobTask."Job Task No.");
            PriceSource := xPriceSource;
            exit(true);
        end;
    end;

    procedure VerifyParent(var PriceSource: Record "Price Source") Result: Boolean
    begin
        if PriceSource."Parent Source No." <> '' then
            if not Job.Get(PriceSource."Parent Source No.") then
                PriceSource."Parent Source No." := ''
            else
                PriceSource.Validate("Currency Code", Job."Currency Code");
        Result := true;
    end;

    procedure GetGroupNo(PriceSource: Record "Price Source"): Code[20];
    begin
        exit(PriceSource."Parent Source No.");
    end;

    local procedure FillAdditionalFields(var PriceSource: Record "Price Source")
    begin
        PriceSource.Description := JobTask.Description;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Price Source", 'OnGetParentSourceType', '', false, false)]
    local procedure OnGetParentSourceTypeHandler(PriceSource: Record "Price Source"; var ParentSourceType: Enum "Price Source Type");
    begin
        if PriceSource."Source Type" = "Price Source Type"::"Job Task" then
            ParentSourceType := "Price Source Type"::Job;
    end;
}