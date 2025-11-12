// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Inventory.BOM;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Foundation.ExtendedText;

codeunit 1019 "Job-Explode BOM"
{
    TableNo = "Job Planning Line";

    trigger OnRun()
    var
        AssembleToOrderLink: Record "Assemble-to-Order Link";
        HideDialog: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        Job.Get(Rec."Job No.");

        CheckJobPlanningLine(Rec);
        DeleteReservEntries(Rec);

        FromBOMComp.SetRange("Parent Item No.", Rec."No.");
        NoOfBOMComp := FromBOMComp.Count();

        if not HideDialog then
            if NoOfBOMComp = 0 then
                Error(ItemNotBOMErr, Rec."No.");

        ToJobPlanningLine := Rec;
        FromBOMComp.SetRange(Type, FromBOMComp.Type::Item);
        FromBOMComp.SetFilter("No.", '<>%1', '');
        if FromBOMComp.FindSet() then
            repeat
                FromBOMComp.TestField(Type, FromBOMComp.Type::Item);
                Item.Get(FromBOMComp."No.");
                AssingJobPlannigLineDataFromBOMComp();
            until FromBOMComp.Next() = 0;

        if Rec."BOM Item No." = '' then
            BOMItemNo := Rec."No."
        else
            BOMItemNo := Rec."BOM Item No.";

        if Rec.Type = Rec.Type::Item then
            AssembleToOrderLink.DeleteAsmFromJobPlanningLine(Rec);

        InitParentItemLine(Rec);
        AddExtText();
        ExplodeBOMCompLines(Rec);
    end;

    var
        ToJobPlanningLine: Record "Job Planning Line";
        FromBOMComp: Record "BOM Component";
        Job: Record Job;
        ItemTranslation: Record "Item Translation";
        Item: Record Item;
        Resource: Record Resource;
        UOMMgt: Codeunit "Unit of Measure Management";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ReservMgt: Codeunit "Reservation Management";
        BOMItemNo: Code[20];
        LineSpacing: Integer;
        NextLineNo: Integer;
        NoOfBOMComp: Integer;

        ItemNotBOMErr: Label 'Item %1 is not a BOM.', Comment = '%1 = Item No.';
        NotEnoughSpaceMsg: Label 'There is not enough space to explode the BOM.';

    procedure CallExplodeBOMCompLines(JobPlanningLine: Record "Job Planning Line")
    begin
        ExplodeBOMCompLines(JobPlanningLine);
    end;

    local procedure ExplodeBOMCompLines(JobPlanningLine: Record "Job Planning Line")
    var
        PreviousJobPlanningLine: Record "Job Planning Line";
        InsertLinesBetween: Boolean;
    begin
        SetFiltersOnJobPlanningLine(JobPlanningLine);
        ToJobPlanningLine := JobPlanningLine;
        NextLineNo := JobPlanningLine."Line No.";
        InsertLinesBetween := false;
        if ToJobPlanningLine.Find('>') then
            if ToJobPlanningLine.IsExtendedText() and (ToJobPlanningLine."Attached to Line No." = JobPlanningLine."Line No.") then begin
                ToJobPlanningLine.SetRange("Attached to Line No.", JobPlanningLine."Line No.");
                ToJobPlanningLine.FindLast();
                ToJobPlanningLine.SetRange("Attached to Line No.");
                NextLineNo := ToJobPlanningLine."Line No.";
                InsertLinesBetween := ToJobPlanningLine.Find('>');
            end else
                InsertLinesBetween := true;
        GenerateLineSpacing(InsertLinesBetween);

        FromBOMComp.Reset();
        FromBOMComp.SetRange("Parent Item No.", JobPlanningLine."No.");
        FromBOMComp.FindSet();
        repeat
            ToJobPlanningLine.Init();
            NextLineNo := NextLineNo + LineSpacing;
            ToJobPlanningLine."Line No." := NextLineNo;
            ToJobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type");
            AssignBOMCompType();

            if ToJobPlanningLine.Type <> ToJobPlanningLine.Type::Text then begin
                FromBOMComp.TestField("No.");
                ValidateJobPlanningLineData(JobPlanningLine);
            end;
            AddDescriptionFromTranslationIfExist();
            ToJobPlanningLine."BOM Item No." := BOMItemNo;
            ToJobPlanningLine.Insert(true);

            if not (ToJobPlanningLine."Line Type" = ToJobPlanningLine."Line Type"::Billable) then
                ToJobPlanningLine.Validate("Qty. to Assemble");

            if (ToJobPlanningLine.Type = ToJobPlanningLine.Type::Item) and (ToJobPlanningLine.Reserve = ToJobPlanningLine.Reserve::Always) then
                ToJobPlanningLine.AutoReserve();

            if PreviousJobPlanningLine."Job No." <> '' then
                if TransferExtendedText.JobCheckIfAnyExtText(PreviousJobPlanningLine, false) then
                    TransferExtendedText.InsertJobExtText(PreviousJobPlanningLine);

            PreviousJobPlanningLine := ToJobPlanningLine;
        until FromBOMComp.Next() = 0;

        AddExtText();
    end;

    local procedure ValidateJobPlanningLineData(JobPlanningLine: Record "Job Planning Line")
    begin
        ToJobPlanningLine.Validate("Planning Date", JobPlanningLine."Planning Date");
        ToJobPlanningLine.Validate("Document No.", JobPlanningLine."Document No.");
        ToJobPlanningLine.Validate("No.", FromBOMComp."No.");
        ToJobPlanningLine.Validate("Location Code", JobPlanningLine."Location Code");
        if FromBOMComp."Variant Code" <> '' then
            ToJobPlanningLine.Validate("Variant Code", FromBOMComp."Variant Code");
        ValidateQtyAndUoMForDifferentTypes(JobPlanningLine);
    end;

    local procedure SetFiltersOnJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    begin
        ToJobPlanningLine.Reset();
        ToJobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        ToJobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
    end;

    local procedure AddExtText()
    begin
        if TransferExtendedText.JobCheckIfAnyExtText(ToJobPlanningLine, false) then
            TransferExtendedText.InsertJobExtText(ToJobPlanningLine);
    end;

    local procedure AssignBOMCompType()
    begin
        case FromBOMComp.Type of
            FromBOMComp.Type::" ":
                ToJobPlanningLine.Type := ToJobPlanningLine.Type::Text;
            FromBOMComp.Type::Item:
                ToJobPlanningLine.Type := ToJobPlanningLine.Type::Item;
            FromBOMComp.Type::Resource:
                ToJobPlanningLine.Type := ToJobPlanningLine.Type::Resource;
        end;
    end;

    local procedure AssingJobPlannigLineDataFromBOMComp()
    begin
        ToJobPlanningLine."Line No." := 0;
        ToJobPlanningLine."No." := FromBOMComp."No.";
        ToJobPlanningLine."Variant Code" := FromBOMComp."Variant Code";
        ToJobPlanningLine."Unit of Measure Code" := FromBOMComp."Unit of Measure Code";
        ToJobPlanningLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, FromBOMComp."Unit of Measure Code");
    end;

    local procedure CheckJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    begin
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
        JobPlanningLine.TestField("Reserved Qty. (Base)", 0);
    end;

    local procedure InitParentItemLine(var FromJobPlanningLine: Record "Job Planning Line")
    begin
        ToJobPlanningLine := FromJobPlanningLine;
        ToJobPlanningLine.Init();
        ToJobPlanningLine."Line Type" := FromJobPlanningLine."Line Type";
        ToJobPlanningLine.Type := ToJobPlanningLine.Type::Text;
        ToJobPlanningLine.Description := FromJobPlanningLine.Description;
        ToJobPlanningLine."Description 2" := FromJobPlanningLine."Description 2";
        ToJobPlanningLine."BOM Item No." := BOMItemNo;
        ToJobPlanningLine.Modify();
    end;

    local procedure ValidateQtyAndUoMForDifferentTypes(JobPlanningLine: Record "Job Planning Line")
    begin
        case ToJobPlanningLine.Type of
            ToJobPlanningLine.Type::Item:
                begin
                    Item.Get(FromBOMComp."No.");
                    ToJobPlanningLine.Validate("Unit of Measure Code", FromBOMComp."Unit of Measure Code");
                    ToJobPlanningLine."Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, ToJobPlanningLine."Unit of Measure Code");
                    ToJobPlanningLine.Validate(Quantity, Round(JobPlanningLine."Quantity (Base)" * FromBOMComp."Quantity per", UOMMgt.QtyRndPrecision()));
                end;
            ToJobPlanningLine.Type::Resource:
                begin
                    Resource.Get(FromBOMComp."No.");
                    ToJobPlanningLine.Validate("Unit of Measure Code", FromBOMComp."Unit of Measure Code");
                    ToJobPlanningLine."Qty. per Unit of Measure" := UOMMgt.GetResQtyPerUnitOfMeasure(Resource, ToJobPlanningLine."Unit of Measure Code");
                    ToJobPlanningLine.Validate(Quantity, Round(JobPlanningLine."Quantity (Base)" * FromBOMComp."Quantity per", UOMMgt.QtyRndPrecision()));
                end;
            else
                ToJobPlanningLine.Validate(Quantity, JobPlanningLine."Quantity (Base)" * FromBOMComp."Quantity per");
        end;
    end;

    local procedure AddDescriptionFromTranslationIfExist()
    begin
        if Job."Language Code" = '' then
            ToJobPlanningLine.Description := FromBOMComp.Description
        else
            if not ItemTranslation.Get(FromBOMComp."No.", FromBOMComp."Variant Code", Job."Language Code") then
                ToJobPlanningLine.Description := FromBOMComp.Description;
    end;

    local procedure GenerateLineSpacing(InsertLinesBetween: Boolean)
    begin
        if InsertLinesBetween then
            LineSpacing := (ToJobPlanningLine."Line No." - NextLineNo) div (1 + NoOfBOMComp)
        else
            LineSpacing := 10000;
        if LineSpacing = 0 then
            Error(NotEnoughSpaceMsg);
    end;

    local procedure DeleteReservEntries(JobPlanningLine: Record "Job Planning Line")
    begin
        ReservMgt.SetReservSource(JobPlanningLine);
        ReservMgt.SetItemTrackingHandling(1);
        ReservMgt.DeleteReservEntries(true, 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;
}