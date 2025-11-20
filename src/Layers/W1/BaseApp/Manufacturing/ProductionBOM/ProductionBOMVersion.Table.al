// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Planning;

table 99000779 "Production BOM Version"
{
    Caption = 'Production BOM Version';
    DataCaptionFields = "Production BOM No.", "Version Code", Description;
    DrillDownPageID = "Prod. BOM Version List";
    LookupPageID = "Prod. BOM Version List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            NotBlank = true;
            TableRelation = "Production BOM Header";
        }
        field(2; "Version Code"; Code[20])
        {
            Caption = 'Version Code';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(21; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure";

            trigger OnValidate()
            var
                Item: Record Item;
                ItemUnitOfMeasure: Record "Item Unit of Measure";
            begin
                if (Status = Status::Certified) and ("Unit of Measure Code" <> xRec."Unit of Measure Code") then
                    FieldError(Status);
                Item.SetRange("Production BOM No.", "Production BOM No.");
                if Item.FindSet() then
                    repeat
                        ItemUnitOfMeasure.Get(Item."No.", "Unit of Measure Code");
                    until Item.Next() = 0;
            end;
        }
        field(22; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(45; Status; Enum "BOM Status")
        {
            Caption = 'Status';

            trigger OnValidate()
            var
                ProdBOMHeader: Record "Production BOM Header";
                PlanningAssignment: Record "Planning Assignment";
                ProdBOMCheck: Codeunit "Production BOM-Check";
                SkipCommit: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeOnValidateStatus(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if (Status <> xRec.Status) and (Status = Status::Certified) then begin
                    ProdBOMCheck.ProdBOMLineCheck("Production BOM No.", "Version Code");
                    TestField("Unit of Measure Code");
                    ProdBOMHeader.Get("Production BOM No.");
                    ProdBOMHeader."Low-Level Code" := 0;
                    ProdBOMCheck.Code(ProdBOMHeader, "Version Code");
                    PlanningAssignment.NewBOM("Production BOM No.");
                end;
                OnValidateStatusBeforeModify(Rec, xRec, CurrFieldNo);
                Modify(true);
                SkipCommit := false;
                OnValidateStatusBeforeCommit(Rec, SkipCommit);
                if not SkipCommit then
                    Commit();
            end;
        }
        field(50; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "Production BOM No.", "Version Code")
        {
            Clustered = true;
        }
        key(Key2; "Production BOM No.", "Starting Date")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        ProdBOMLine.SetRange("Production BOM No.", "Production BOM No.");
        ProdBOMLine.SetRange("Version Code", "Version Code");
        ProdBOMLine.DeleteAll(true);
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";

    begin
        ProdBOMHeader.Get("Production BOM No.");
        if "Version Code" = '' then begin
            ProdBOMHeader.TestField("Version Nos.");
            if NoSeries.AreRelated(ProdBOMHeader."Version Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := ProdBOMHeader."Version Nos.";
            "Version Code" := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        if Status = Status::Certified then
            Error(Text001, TableCaption(), FieldCaption(Status), Format(Status));
    end;

    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot rename the %1 when %2 is %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure AssistEdit(OldProdBOMVersion: Record "Production BOM Version"): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        ProdBOMVersion := Rec;
        ProdBOMHeader.Get(ProdBOMVersion."Production BOM No.");
        ProdBOMHeader.TestField("Version Nos.");
        if NoSeries.LookupRelatedNoSeries(ProdBOMHeader."Version Nos.", OldProdBOMVersion."No. Series", ProdBOMVersion."No. Series") then begin
            ProdBOMVersion."Version Code" := NoSeries.GetNextNo(ProdBOMVersion."No. Series");
            Rec := ProdBOMVersion;
            exit(true);
        end;
    end;

    procedure Caption(): Text
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        if GetFilters = '' then
            exit('');

        if not ProdBOMHeader.Get("Production BOM No.") then
            exit('');

        exit(
          CopyStr(StrSubstNo('%1 %2 %3',
            "Production BOM No.", ProdBOMHeader.Description, "Version Code"), 1, 100));
    end;

    procedure ProductionBOMLinesExist(): Boolean
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", Rec."Production BOM No.");
        ProductionBOMLine.SetRange("Version Code", Rec."Version Code");
        exit(not ProductionBOMLine.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStatusBeforeModify(var ProductionBOMVersion: Record "Production BOM Version"; var xProductionBOMVersion: Record "Production BOM Version"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStatusBeforeCommit(var ProductionBOMVersion: Record "Production BOM Version"; var SkipCommit: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnValidateStatus(var ProductionBOMVersion: Record "Production BOM Version"; var xProductionBOMVersion: Record "Production BOM Version"; var IsHandled: Boolean)
    begin
    end;
}
