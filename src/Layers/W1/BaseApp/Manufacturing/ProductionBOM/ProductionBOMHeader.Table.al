// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.ProductionBOM;

using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Planning;
using Microsoft.Manufacturing.Comment;
using Microsoft.Manufacturing.Setup;

table 99000771 "Production BOM Header"
{
    Caption = 'Production BOM Header';
    DataCaptionFields = "No.", Description;
    DrillDownPageID = "Production BOM List";
    LookupPageID = "Production BOM List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                "Search Name" := Description;
            end;
        }
        field(11; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(12; "Search Name"; Code[100])
        {
            Caption = 'Search Name';
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
                if Status = Status::Certified then
                    FieldError(Status);
                Item.SetCurrentKey("Production BOM No.");
                Item.SetRange("Production BOM No.", "No.");
                if Item.FindSet() then
                    repeat
                        ItemUnitOfMeasure.Get(Item."No.", "Unit of Measure Code");
                    until Item.Next() = 0;
            end;
        }
        field(22; "Low-Level Code"; Integer)
        {
            Caption = 'Low-Level Code';
            Editable = false;
        }
        field(25; Comment; Boolean)
        {
            CalcFormula = exist("Manufacturing Comment Line" where("Table Name" = const("Production BOM Header"),
                                                                    "No." = field("No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
            Editable = false;
        }
        field(43; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(45; Status; Enum "BOM Status")
        {
            Caption = 'Status';

            trigger OnValidate()
            var
                ProdBOMLineRec: Record "Production BOM Line";
                PlanningAssignment: Record "Planning Assignment";
                MfgSetup: Record "Manufacturing Setup";
                ProdBOMCheck: Codeunit "Production BOM-Check";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeOnValidateStatus(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if (Status <> xRec.Status) and (Status = Status::Certified) then begin
                    ProdBOMLineRec.SetLoadFields(Type, "No.", "Variant Code");
                    ProdBOMLineRec.SetRange("Production BOM No.", "No.");
                    while ProdBOMLineRec.Next() <> 0 do
                        CheckVariantIfMandatory(ProdBOMLineRec);
                    MfgSetup.LockTable();
                    MfgSetup.Get();
                    ProdBOMCheck.ProdBOMLineCheck("No.", '');
                    "Low-Level Code" := 0;
                    ProdBOMCheck.Run(Rec);
                    PlanningAssignment.NewBOM("No.");
                end;
                if Status = Status::Closed then begin
                    IsHandled := false;
                    OnValidateStatusOnBeforeConfirm(Rec, xRec, IsHandled);
                    if not IsHandled then
                        if Confirm(Text001, false) then begin
                            ProdBOMVersion.SetRange("Production BOM No.", "No.");
                            if ProdBOMVersion.Find('-') then
                                repeat
                                    ProdBOMVersion.Status := ProdBOMVersion.Status::Closed;
                                    ProdBOMVersion.Modify();
                                until ProdBOMVersion.Next() = 0;
                        end else
                            Status := xRec.Status;
                end;
            end;
        }
        field(50; "Version Nos."; Code[20])
        {
            Caption = 'Version Nos.';
            TableRelation = "No. Series";
        }
        field(51; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
        key(Key3; Description)
        {
        }
        key(Key4; Status)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description, Status)
        {
        }
    }

    trigger OnDelete()
    var
        Item: Record Item;
    begin
        Item.SetRange("Production BOM No.", "No.");
        if not Item.IsEmpty() then
            Error(Text000);

        ProdBOMLine.SetRange("Production BOM No.", "No.");
        ProdBOMLine.DeleteAll(true);

        ProdBOMVersion.SetRange("Production BOM No.", "No.");
        ProdBOMVersion.DeleteAll();

        MfgComment.SetRange("Table Name", MfgComment."Table Name"::"Production BOM Header");
        MfgComment.SetRange("No.", "No.");
        MfgComment.DeleteAll();
    end;

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";

    begin
        MfgSetup.Get();
        if "No." = '' then begin
            MfgSetup.TestField("Production BOM Nos.");
            if NoSeries.AreRelated(MfgSetup."Production BOM Nos.", xRec."No. Series") then
                "No. Series" := xRec."No. Series"
            else
                "No. Series" := MfgSetup."Production BOM Nos.";
            "No." := NoSeries.GetNextNo("No. Series");
        end;

        "Creation Date" := Today;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        if Status = Status::Certified then
            Error(Text002, TableCaption(), FieldCaption(Status), Format(Status));
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'This Production BOM is being used on Items.';
        Text001: Label 'All versions attached to the BOM will be closed. Close BOM?';
#pragma warning restore AA0074
        MfgSetup: Record "Manufacturing Setup";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
        ProdBOMLine: Record "Production BOM Line";
        MfgComment: Record "Manufacturing Comment Line";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text002: Label 'You cannot rename the %1 when %2 is %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure AssistEdit(OldProdBOMHeader: Record "Production BOM Header"): Boolean
    var
        NoSeries: Codeunit "No. Series";
        SeriesSelected: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeAsistEdit(Rec, OldProdBOMHeader, SeriesSelected, IsHandled);
        if IsHandled then
            exit(SeriesSelected);

        ProdBOMHeader := Rec;
        MfgSetup.Get();
        MfgSetup.TestField("Production BOM Nos.");
        if NoSeries.LookupRelatedNoSeries(MfgSetup."Production BOM Nos.", OldProdBOMHeader."No. Series", ProdBOMHeader."No. Series") then begin
            ProdBOMHeader."No." := NoSeries.GetNextNo(ProdBOMHeader."No. Series");
            Rec := ProdBOMHeader;
            exit(true);
        end;
    end;

    local procedure CheckVariantIfMandatory(var ProductionBOMLine: Record "Production BOM Line")
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckVariantIfMandatory(Rec, xRec, ProductionBOMLine, IsHandled);
        if IsHandled then
            exit;

        if Item.IsVariantMandatory(ProductionBOMLine.Type = ProductionBOMLine.Type::Item, ProductionBOMLine."No.") then
            ProductionBOMLine.TestField("Variant Code");
    end;

    procedure ProductionBOMLinesExist(): Boolean
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", Rec."No.");
        ProductionBOMLine.SetRange("Version Code", '');
        exit(not ProductionBOMLine.IsEmpty());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAsistEdit(var ProductionBOMHeader: Record "Production BOM Header"; OldProductionBOMHeader: Record "Production BOM Header"; var SeriesSelected: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckVariantIfMandatory(var ProductionBOMHeader: Record "Production BOM Header"; xProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMLine: Record "Production BOM Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateStatusOnBeforeConfirm(var ProductionBOMHeader: Record "Production BOM Header"; xProductionBOMHeader: Record "Production BOM Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnValidateStatus(var ProductionBOMHeader: Record "Production BOM Header"; var xProductionBOMHeader: Record "Production BOM Header"; var IsHandled: Boolean)
    begin
    end;
}
