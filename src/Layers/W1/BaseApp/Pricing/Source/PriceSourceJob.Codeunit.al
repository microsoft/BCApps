// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Project.Job;

codeunit 7036 "Price Source - Job" implements "Price Source"
{
    var
        Job: Record Job;
        ParentErr: Label 'Parent Source No. must be blank for Project source type.';

    procedure GetNo(var PriceSource: Record "Price Source")
    begin
        if Job.GetBySystemId(PriceSource."Source ID") then begin
            PriceSource."Source No." := Job."No.";
            FillAdditionalFields(PriceSource);
        end else
            PriceSource.InitSource();
    end;

    procedure GetId(var PriceSource: Record "Price Source")
    begin
        if Job.Get(PriceSource."Source No.") then begin
            PriceSource."Source ID" := Job.SystemId;
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
        if Job.Get(xPriceSource."Source No.") then;
        if Page.RunModal(Page::"Job List", Job) = ACTION::LookupOK then begin
            xPriceSource.Validate("Source No.", Job."No.");
            PriceSource := xPriceSource;
            exit(true);
        end;
    end;

    procedure VerifyParent(var PriceSource: Record "Price Source") Result: Boolean
    begin
        if PriceSource."Parent Source No." <> '' then
            Error(ParentErr);
    end;

    procedure GetGroupNo(PriceSource: Record "Price Source"): Code[20];
    begin
        exit(PriceSource."Source No.");
    end;

    local procedure FillAdditionalFields(var PriceSource: Record "Price Source")
    begin
        PriceSource.Description := Job.Description;
        PriceSource."Currency Code" := Job."Currency Code";
        OnAfterFillAdditionalFields(PriceSource, Job);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Price Source List", 'OnBeforeAddChildren', '', false, false)]
    local procedure AddChildren(var Sender: Codeunit "Price Source List"; PriceSource: Record "Price Source"; var TempChildPriceSource: Record "Price Source" temporary);
    var
        JobTask: Record "Job Task";
    begin
        if PriceSource."Source Type" = "Price Source Type"::Job then begin
            JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
            JobTask.SetRange("Job No.", PriceSource."Source No.");
            if JobTask.FindSet() then
                repeat
                    JobTask.ToPriceSource(TempChildPriceSource, PriceSource."Price Type");
                    TempChildPriceSource."Entry No." += 1;
                    TempChildPriceSource.Insert();
                until JobTask.Next() = 0;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillAdditionalFields(var PriceSource: Record "Price Source"; Job: Record Job)
    begin
    end;
}