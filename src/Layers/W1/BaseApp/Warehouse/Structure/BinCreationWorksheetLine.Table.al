// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Setup;
using System.Security.AccessControl;

table 7338 "Bin Creation Worksheet Line"
{
    Caption = 'Bin Creation Worksheet Line';
    LookupPageID = "Bin Creation Worksheet";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            TableRelation = "Bin Creation Wksh. Template".Name where(Type = field(Type));
            ValidateTableRelation = false;
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            TableRelation = "Bin Creation Wksh. Name".Name where("Worksheet Template Name" = field("Worksheet Template Name"));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Bin,Bin Content';
            OptionMembers = Bin,"Bin Content";

            trigger OnValidate()
            var
                BinCreateWkshLine: Record "Bin Creation Worksheet Line";
            begin
                if Type <> xRec.Type then begin
                    BinCreateWkshLine := Rec;
                    "Item No." := '';
                    "Bin Code" := '';
                    "Zone Code" := '';
                    "Variant Code" := '';
                    Init();
                    Type := BinCreateWkshLine.Type;
                end;
            end;
        }
        field(5; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            NotBlank = true;
            TableRelation = Location where("Bin Mandatory" = const(true));
        }
        field(6; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                GetLocation("Location Code");
                GetZone("Location Code", "Zone Code");
                "Bin Type Code" := Zone."Bin Type Code";
                Validate("Warehouse Class Code", Zone."Warehouse Class Code");
                "Special Equipment Code" := Zone."Special Equipment Code";
                "Bin Ranking" := Zone."Zone Ranking";
                "Cross-Dock Bin" := Zone."Cross-Dock Bin Zone";
            end;
        }
        field(7; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            NotBlank = true;
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                if ("Bin Code" <> '') and (Type = Type::"Bin Content") then begin
                    Bin.Get("Location Code", "Bin Code");
                    Dedicated := Bin.Dedicated;
                    "Bin Type Code" := Bin."Bin Type Code";
                    Validate("Warehouse Class Code", Bin."Warehouse Class Code");
                    "Special Equipment Code" := Bin."Special Equipment Code";
                    "Block Movement" := Bin."Block Movement";
                    "Bin Ranking" := Bin."Bin Ranking";
                    "Cross-Dock Bin" := Bin."Cross-Dock Bin";
                    "Zone Code" := Bin."Zone Code";
                end;
            end;
        }
        field(8; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;

            trigger OnValidate()
            var
                Item: Record Item;
            begin
                if "Item No." <> '' then begin
                    GetItem("Item No.");
                    Description := Item.Description;
                    GetItemUnitOfMeasure();
                    Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
                    CheckWhseClass("Item No.");
                end else begin
                    Description := '';
                    "Variant Code" := '';
                    Validate("Unit of Measure Code", '');
                end;
            end;
        }
        field(9; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
            TableRelation = "Bin Type";
        }
        field(11; "Warehouse Class Code"; Code[10])
        {
            Caption = 'Warehouse Class Code';
            TableRelation = "Warehouse Class";

            trigger OnValidate()
            begin
                if ("Item No." <> '') and (Type = Type::"Bin Content") then
                    CheckWhseClass("Item No.");
            end;
        }
        field(12; "Block Movement"; Option)
        {
            Caption = 'Block Movement';
            OptionCaption = ' ,Inbound,Outbound,All';
            OptionMembers = " ",Inbound,Outbound,All;
        }
        field(15; "Min. Qty."; Decimal)
        {
            Caption = 'Min. Qty.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Min. Qty." > "Max. Qty." then
                    Error(
                      Text009,
                      FieldCaption("Max. Qty."), "Max. Qty.",
                      FieldCaption("Min. Qty."), "Min. Qty.");
            end;
        }
        field(16; "Max. Qty."; Decimal)
        {
            Caption = 'Max. Qty.';
            DecimalPlaces = 0 : 5;
            MinValue = 1;

            trigger OnValidate()
            begin
                if "Max. Qty." <> xRec."Max. Qty." then
                    CheckMaxQtyBinContent(true);

                if "Min. Qty." > "Max. Qty." then
                    Error(
                      Text009,
                      FieldCaption("Max. Qty."), "Max. Qty.",
                      FieldCaption("Min. Qty."), "Min. Qty.");
            end;
        }
        field(20; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            TableRelation = "Special Equipment";
        }
        field(21; "Bin Ranking"; Integer)
        {
            Caption = 'Bin Ranking';
        }
        field(22; "Maximum Cubage"; Decimal)
        {
            BlankZero = true;
            Caption = 'Maximum Cubage';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckMaxQtyBinContent(false);
            end;
        }
        field(23; "Maximum Weight"; Decimal)
        {
            BlankZero = true;
            Caption = 'Maximum Weight';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckMaxQtyBinContent(true);
            end;
        }
        field(37; "Fixed"; Boolean)
        {
            Caption = 'Fixed';
            InitValue = true;
        }
        field(38; Default; Boolean)
        {
            Caption = 'Default';

            trigger OnValidate()
            begin
                if Default then
                    if WMSMgt.CheckDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code") then
                        Error(Text010, "Location Code", "Item No.", "Variant Code");
            end;
        }
        field(40; "Cross-Dock Bin"; Boolean)
        {
            Caption = 'Cross-Dock Bin';
        }
        field(67; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if "Variant Code" <> '' then begin
                    ItemVariant.Get("Item No.", "Variant Code");
                    Description := ItemVariant.Description;
                end;
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            NotBlank = true;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                GetItem("Item No.");
                "Qty. per Unit of Measure" :=
                  UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
            end;
        }
        field(5408; Dedicated; Boolean)
        {
            Caption = 'Dedicated';
        }
    }

    keys
    {
        key(Key1; "Worksheet Template Name", Name, "Location Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Location Code", "Zone Code", "Bin Code", "Item No.", "Variant Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Location Code", "Bin Code", "Zone Code", "Item No.", Description)
        { }
    }

    trigger OnInsert()
    begin
        GetLocation("Location Code");
        if Location."Bin Mandatory" then
            TestField("Bin Code");
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;

    trigger OnModify()
    begin
        GetLocation("Location Code");
        if Location."Bin Mandatory" then
            TestField("Bin Code");
    end;

    var
        BinCreateWkshTemplate: Record "Bin Creation Wksh. Template";
        Location: Record Location;
        Zone: Record Zone;
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UOMMgt: Codeunit "Unit of Measure Management";
        WMSMgt: Codeunit "WMS Management";
        OpenFromBatch: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label '%1 Worksheet';
#pragma warning restore AA0470
        Text002: Label 'Default Worksheet';
        Text003: Label 'Cancelled.';
        Text004: Label 'DEFAULT';
#pragma warning disable AA0470
        Text005: Label 'The Total Cubage %1 of the %2 in the bin contents exceeds the entered %3 %4.\Do you still want to enter this %3?';
        Text007: Label 'The %1 %2 %3 does not match the %4 %5.';
        Text008: Label 'The location %1 of bin creation  Wksh. batch %2 is not enabled for user %3.';
        Text009: Label 'The %1 %2 must not be less than the %3 %4.';
        Text010: Label 'There is already a default bin content for location code %1, item no. %2 and variant code %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure EmptyLine(): Boolean
    begin
        if Type = Type::Bin then
            exit(("Bin Code" = '') and ("Location Code" = '') and ("Zone Code" = ''));

        exit(("Bin Code" = '') and ("Location Code" = '') and ("Zone Code" = '') and
          ("Item No." = '') and ("Unit of Measure Code" = ''))
    end;

    procedure SetUpNewLine(CurrentWkshTemplateName: Code[10])
    begin
        if BinCreateWkshTemplate.Name <> CurrentWkshTemplateName then
            BinCreateWkshTemplate.Get(CurrentWkshTemplateName);
        Type := BinCreateWkshTemplate.Type;
    end;

    procedure TemplateSelection(PageID: Integer; PageTemplate: Option; var BinCreateWkshLine: Record "Bin Creation Worksheet Line"; var WkshSelected: Boolean)
    var
        BinCreateWkshTemplate: Record "Bin Creation Wksh. Template";
    begin
        WkshSelected := true;

        BinCreateWkshTemplate.Reset();
        BinCreateWkshTemplateSetPageIDFilter(BinCreateWkshTemplate, PageID);
        BinCreateWkshTemplate.SetRange(Type, PageTemplate);
        case BinCreateWkshTemplate.Count of
            0:
                begin
                    BinCreateWkshTemplate.Init();
                    BinCreateWkshTemplate.Type := PageTemplate;
                    BinCreateWkshTemplate.Name :=
                      Format(BinCreateWkshTemplate.Type, MaxStrLen(BinCreateWkshTemplate.Name));
                    BinCreateWkshTemplate.Description :=
                      StrSubstNo(Text001, BinCreateWkshTemplate.Type);
                    BinCreateWkshTemplate.Validate("Page ID");
                    BinCreateWkshTemplate.Insert();
                    Commit();
                end;
            1:
                BinCreateWkshTemplate.FindFirst();
            else
                WkshSelected := PAGE.RunModal(0, BinCreateWkshTemplate) = ACTION::LookupOK;
        end;
        if WkshSelected then begin
            BinCreateWkshLine.FilterGroup := 2;
            BinCreateWkshLine.SetRange("Worksheet Template Name", BinCreateWkshTemplate.Name);
            BinCreateWkshLine.SetRange(Type, BinCreateWkshTemplate.Type);
            BinCreateWkshLine.FilterGroup := 0;
            if OpenFromBatch then begin
                BinCreateWkshLine."Worksheet Template Name" := '';
                PAGE.Run(BinCreateWkshTemplate."Page ID", BinCreateWkshLine);
            end;
        end;
    end;

    local procedure BinCreateWkshTemplateSetPageIDFilter(var BinCreateWkshTemplate: Record "Bin Creation Wksh. Template"; PageID: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeBinCreateWkshTemplateSetPageIDFilter(BinCreateWkshTemplate, IsHandled);
        if IsHandled then
            exit;

        if not OpenFromBatch then
            BinCreateWkshTemplate.SetRange("Page ID", PageID);
    end;

    procedure TemplateSelectionFromBatch(var BinCreateWkshName: Record "Bin Creation Wksh. Name")
    var
        BinCreateWkshLine: Record "Bin Creation Worksheet Line";
        JnlSelected: Boolean;
    begin
        OpenFromBatch := true;
        BinCreateWkshName.CalcFields("Template Type");
        BinCreateWkshLine.Name := BinCreateWkshName.Name;
        BinCreateWkshLine."Location Code" := BinCreateWkshName."Location Code";
        TemplateSelection(0, BinCreateWkshName."Template Type", BinCreateWkshLine, JnlSelected);
    end;

    procedure OpenWksh(var CurrentWkshName: Code[10]; var CurrentLocationCode: Code[10]; var BinCreateWkshLine: Record "Bin Creation Worksheet Line")
    begin
        WMSMgt.CheckUserIsWhseEmployee();
        CheckTemplateName(
          BinCreateWkshLine.GetRangeMax("Worksheet Template Name"),
          CurrentLocationCode, CurrentWkshName);
        BinCreateWkshLine.FilterGroup := 2;
        BinCreateWkshLine.SetRange(Name, CurrentWkshName);
        if CurrentLocationCode <> '' then
            BinCreateWkshLine.SetRange("Location Code", CurrentLocationCode);
        BinCreateWkshTemplate.Get(BinCreateWkshLine.GetRangeMax("Worksheet Template Name"));
        BinCreateWkshLine.SetRange(Type, BinCreateWkshTemplate.Type);
        BinCreateWkshLine.FilterGroup := 0;
    end;

    procedure OpenWkshBatch(var BinCreateWkshName: Record "Bin Creation Wksh. Name")
    var
        CopyOfBinCreateWkshName: Record "Bin Creation Wksh. Name";
        BinCreateWkshTemplate: Record "Bin Creation Wksh. Template";
        BinCreateWkshLine: Record "Bin Creation Worksheet Line";
        JnlSelected: Boolean;
    begin
        CopyOfBinCreateWkshName := BinCreateWkshName;
        if not BinCreateWkshName.Find('-') then begin
            for BinCreateWkshTemplate.Type := BinCreateWkshTemplate.Type::Bin to BinCreateWkshTemplate.Type::"Bin Content" do begin
                BinCreateWkshTemplate.SetRange(Type, BinCreateWkshTemplate.Type);
                if not BinCreateWkshTemplate.FindFirst() then
                    TemplateSelection(0, BinCreateWkshTemplate.Type, BinCreateWkshLine, JnlSelected);
                if BinCreateWkshTemplate.FindFirst() then
                    CheckTemplateName(BinCreateWkshTemplate.Name, BinCreateWkshName.Name, BinCreateWkshName."Location Code");
            end;
            if BinCreateWkshName.Find('-') then;
            CopyOfBinCreateWkshName := BinCreateWkshName;
        end;
        BinCreateWkshName := CopyOfBinCreateWkshName;
    end;

    local procedure CheckTemplateName(CurrentWkshTemplateName: Code[10]; var CurrentLocationCode: Code[10]; var CurrentWkshName: Code[10])
    var
        BinCreateWkshName: Record "Bin Creation Wksh. Name";
    begin
        WMSMgt.GetWMSLocation(CurrentLocationCode);

        BinCreateWkshName.SetRange("Worksheet Template Name", CurrentWkshTemplateName);
        BinCreateWkshName.SetRange("Location Code", CurrentLocationCode);
        BinCreateWkshName.SetRange(Name, CurrentWkshName);
        if not BinCreateWkshName.IsEmpty() then
            exit;

        BinCreateWkshName.SetRange(Name);
        if not BinCreateWkshName.FindFirst() then begin
            BinCreateWkshName.Init();
            BinCreateWkshName."Worksheet Template Name" := CurrentWkshTemplateName;
            BinCreateWkshName.SetupNewName();
            BinCreateWkshName."Location Code" := CurrentLocationCode;
            BinCreateWkshName.Name := Text004;
            BinCreateWkshName.Description := Text002;
            BinCreateWkshName.Insert(true);
            Commit();
        end;
        CurrentWkshName := BinCreateWkshName.Name;
    end;

    procedure CheckName(CurrentWkshName: Code[10]; CurrentLocationCode: Code[10]; var BinCreateWkshLine: Record "Bin Creation Worksheet Line")
    var
        BinCreateWkshName: Record "Bin Creation Wksh. Name";
        WhseEmployee: Record "Warehouse Employee";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckName(CurrentWkshName, CurrentLocationCode, IsHandled);
        if IsHandled then
            exit;

        BinCreateWkshName.Get(
          BinCreateWkshLine.GetRangeMax("Worksheet Template Name"), CurrentWkshName, CurrentLocationCode);
        if (UserId <> '') and not WhseEmployee.Get(UserId, CurrentLocationCode) then
            Error(Text008, CurrentLocationCode, CurrentWkshName, UserId);
    end;

    procedure SetName(CurrentWkshName: Code[10]; CurrentLocationCode: Code[10]; var BinCreateWkshLine: Record "Bin Creation Worksheet Line")
    begin
        BinCreateWkshLine.FilterGroup := 2;
        BinCreateWkshLine.SetRange(Name, CurrentWkshName);
        BinCreateWkshLine.SetRange("Location Code", CurrentLocationCode);
        BinCreateWkshLine.FilterGroup := 0;
        if BinCreateWkshLine.Find('-') then;
    end;

    procedure LookupBinCreationName(var CurrentWkshName: Code[10]; var CurrentLocationCode: Code[10]; var BinCreateWkshLine: Record "Bin Creation Worksheet Line")
    var
        BinCreateWkshName: Record "Bin Creation Wksh. Name";
    begin
        Commit();
        BinCreateWkshName."Worksheet Template Name" :=
          BinCreateWkshLine.GetRangeMax("Worksheet Template Name");
        BinCreateWkshName.Name := BinCreateWkshLine.GetRangeMax(Name);
        BinCreateWkshName.SetRange(
          "Worksheet Template Name", BinCreateWkshName."Worksheet Template Name");
        if PAGE.RunModal(
             PAGE::"Bin Creation Wksh. Name List", BinCreateWkshName) = ACTION::LookupOK
        then begin
            CurrentWkshName := BinCreateWkshName.Name;
            CurrentLocationCode := BinCreateWkshName."Location Code";
            SetName(CurrentWkshName, CurrentLocationCode, BinCreateWkshLine);
        end;
    end;

    local procedure CheckMaxQtyBinContent(CheckWeight: Boolean)
    var
        BinContent: Record "Bin Content";
        TotalCubage: Decimal;
        TotalWeight: Decimal;
        Cubage: Decimal;
        Weight: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckMaxQtyBinContent(Rec, CheckWeight, IsHandled);
        if IsHandled then
            exit;

        if ("Maximum Cubage" <> 0) or ("Maximum Weight" <> 0) then begin
            BinContent.SetRange("Location Code", "Location Code");
            BinContent.SetRange("Zone Code", "Zone Code");
            BinContent.SetRange("Bin Code", "Bin Code");
            if BinContent.Find('-') then
                repeat
                    WMSMgt.CalcCubageAndWeight(
                      BinContent."Item No.", BinContent."Unit of Measure Code",
                      BinContent."Max. Qty.", Cubage, Weight);
                    TotalCubage := TotalCubage + Cubage;
                    TotalWeight := TotalWeight + Weight;
                until BinContent.Next() = 0;

            if (not CheckWeight) and
               ("Maximum Cubage" > 0) and ("Maximum Cubage" - TotalCubage < 0)
            then
                if not Confirm(Text005, false,
                     TotalCubage, BinContent.FieldCaption("Max. Qty."),
                     FieldCaption("Maximum Cubage"), "Maximum Cubage")
                then
                    Error(Text003);
            if CheckWeight and ("Maximum Weight" > 0) and ("Maximum Weight" - TotalWeight < 0) then
                if not Confirm(Text005, false,
                     TotalWeight, BinContent.FieldCaption("Max. Qty."),
                     FieldCaption("Maximum Weight"), "Maximum Weight")
                then
                    Error(Text003);
        end;
    end;

    local procedure CheckWhseClass(ItemNo: Code[20])
    begin
        GetItem(ItemNo);
        if (Item."Warehouse Class Code" <> '') and
           (Item."Warehouse Class Code" <> "Warehouse Class Code")
        then
            Error(
              Text007,
              TableCaption, FieldCaption("Warehouse Class Code"), "Warehouse Class Code",
              Item.TableCaption(), Item.FieldCaption("Warehouse Class Code"));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo <> Item."No." then
            Item.Get(ItemNo);
    end;

    local procedure GetZone(LocationCode: Code[10]; ZoneCode: Code[10])
    begin
        TestField("Location Code");
        TestField("Zone Code");
        if (Zone."Location Code" <> LocationCode) or
           (Zone.Code <> ZoneCode)
        then
            Zone.Get("Location Code", "Zone Code");
    end;

    local procedure GetItemUnitOfMeasure()
    begin
        GetItem("Item No.");
        if (Item."No." <> ItemUnitOfMeasure."Item No.") or
           ("Unit of Measure Code" <> ItemUnitOfMeasure.Code)
        then
            if not ItemUnitOfMeasure.Get(Item."No.", "Unit of Measure Code") then
                ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
    end;

    procedure GetItemDescr(ItemNo: Code[20]; VariantCode: Code[10]; var ItemDescription: Text[100])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        OldItemNo: Code[20];
    begin
        OldItemNo := '';
        ItemDescription := '';
        if ItemNo <> OldItemNo then begin
            ItemDescription := '';
            if ItemNo <> '' then begin
                if Item.Get(ItemNo) then
                    ItemDescription := Item.Description;
                if VariantCode <> '' then
                    if ItemVariant.Get(ItemNo, VariantCode) then
                        ItemDescription := ItemVariant.Description;
            end;
            OldItemNo := ItemNo;
        end;
    end;

    procedure GetUnitOfMeasureDescr(UOMCode: Code[10]; var UOMDescription: Text[50])
    var
        UOM: Record "Unit of Measure";
    begin
        UOMDescription := '';
        if UOMCode = '' then
            Clear(UOM)
        else
            if UOMCode <> UOM.Code then
                if UOM.Get(UOMCode) then;
        UOMDescription := UOM.Description;

        OnAfterGetUnitOfMeasureDescr(UOMCode, UOMDescription);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnitOfMeasureDescr(UOMCode: Code[10]; var UOMDescription: Text[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBinCreateWkshTemplateSetPageIDFilter(var BinCreateWkshTemplate: Record "Bin Creation Wksh. Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckMaxQtyBinContent(var BinCreationWorksheetLine: Record "Bin Creation Worksheet Line"; CheckWeight: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckName(var WkshName: Code[10]; var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;
}

