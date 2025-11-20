// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Resources.Resource;

table 5870 "BOM Buffer"
{
    Caption = 'BOM Buffer';
    DataCaptionFields = "No.", Description;
    ReplicateData = false;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; Type; Enum "BOM Type")
        {
            Caption = 'Type';
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(6; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."));
        }
        field(7; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
        }
        field(8; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(9; "Replenishment System"; Enum "Replenishment System")
        {
            Caption = 'Replenishment System';
        }
        field(10; Indentation; Integer)
        {
            Caption = 'Indentation';
        }
        field(11; "Is Leaf"; Boolean)
        {
            Caption = 'Is Leaf';
        }
        field(13; Bottleneck; Boolean)
        {
            Caption = 'Bottleneck';
        }
        field(20; "Lot Size"; Decimal)
        {
            Caption = 'Lot Size';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(21; "Low-Level Code"; Integer)
        {
            Caption = 'Low-Level Code';
            Editable = false;
        }
        field(22; "Rounding Precision"; Decimal)
        {
            Caption = 'Rounding Precision';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(30; "Qty. per Parent"; Decimal)
        {
            Caption = 'Qty. per Parent';
            DecimalPlaces = 0 : 5;
        }
        field(31; "Qty. per Top Item"; Decimal)
        {
            Caption = 'Qty. per Top Item';
            DecimalPlaces = 0 : 5;
        }
        field(32; "Able to Make Top Item"; Decimal)
        {
            Caption = 'Able to Make Top Item';
            DecimalPlaces = 0 : 5;
        }
        field(33; "Able to Make Parent"; Decimal)
        {
            Caption = 'Able to Make Parent';
            DecimalPlaces = 0 : 5;
        }
        field(35; "Available Quantity"; Decimal)
        {
            Caption = 'Available Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(36; "Gross Requirement"; Decimal)
        {
            Caption = 'Gross Requirement';
            DecimalPlaces = 0 : 5;
        }
        field(37; "Scheduled Receipts"; Decimal)
        {
            Caption = 'Scheduled Receipts';
            DecimalPlaces = 0 : 5;
        }
        field(38; "Unused Quantity"; Decimal)
        {
            Caption = 'Unused Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(40; "Lead Time Calculation"; DateFormula)
        {
            Caption = 'Lead Time Calculation';
        }
        field(41; "Lead-Time Offset"; DateFormula)
        {
            Caption = 'Lead-Time Offset';
        }
        field(42; "Rolled-up Lead-Time Offset"; Integer)
        {
            Caption = 'Rolled-up Lead-Time Offset';
        }
        field(43; "Needed by Date"; Date)
        {
            Caption = 'Needed by Date';
        }
        field(45; "Safety Lead Time"; DateFormula)
        {
            Caption = 'Safety Lead Time';
        }
        field(50; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
        }
        field(52; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
        }
        field(54; "Overhead Rate"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Overhead Rate';
        }
        field(55; "Scrap %"; Decimal)
        {
            BlankZero = true;
            Caption = 'Scrap %';
        }
        field(56; "Scrap Qty. per Parent"; Decimal)
        {
            Caption = 'Scrap Qty. per Parent';
            DecimalPlaces = 0 : 5;
        }
        field(57; "Scrap Qty. per Top Item"; Decimal)
        {
            Caption = 'Scrap Qty. per Top Item';
            DecimalPlaces = 0 : 5;
        }
        field(59; "Resource Usage Type"; Option)
        {
            Caption = 'Resource Usage Type';
            OptionCaption = 'Direct,Fixed';
            OptionMembers = Direct,"Fixed";
        }
        field(61; "Single-Level Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Single-Level Material Cost';
            DecimalPlaces = 2 : 5;
        }
        field(62; "Single-Level Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Single-Level Capacity Cost';
            DecimalPlaces = 2 : 5;
        }
        field(64; "Single-Level Cap. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Single-Level Cap. Ovhd Cost';
            DecimalPlaces = 2 : 5;
        }
        field(63; "Single-Level Subcontrd. Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Single-Level Subcontrd. Cost';
            DecimalPlaces = 2 : 5;
        }
        field(65; "Single-Level Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Single-Level Mfg. Ovhd Cost';
            DecimalPlaces = 2 : 5;
        }
        field(66; "Single-Level Scrap Cost"; Decimal)
        {
            BlankZero = true;
            Caption = 'Single-Level Scrap Cost';
            DecimalPlaces = 2 : 5;
        }
        field(71; "Rolled-up Material Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Rolled-up Material Cost';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(72; "Rolled-up Capacity Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Rolled-up Capacity Cost';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(74; "Rolled-up Capacity Ovhd. Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Rolled-up Capacity Ovhd. Cost';
            Editable = false;
        }
        field(73; "Rolled-up Subcontracted Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Rolled-up Subcontracted Cost';
            Editable = false;
        }
        field(75; "Rolled-up Mfg. Ovhd Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Rolled-up Mfg. Ovhd Cost';
            Editable = false;
        }
        field(76; "Rolled-up Scrap Cost"; Decimal)
        {
            BlankZero = true;
            Caption = 'Rolled-up Scrap Cost';
            DecimalPlaces = 2 : 5;
        }
        field(77; "Single-Lvl Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Single-Level Material Non-Inventory Cost';
            DecimalPlaces = 2 : 5;
        }
        field(78; "Rolled-up Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 2;
            BlankZero = true;
            Caption = 'Rolled-up Material Non-Inventory Cost';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(81; "Total Cost"; Decimal)
        {
            BlankZero = true;
            Caption = 'Total Cost';
            DecimalPlaces = 2 : 5;
        }
        field(82; "BOM Unit of Measure Code"; Code[10])
        {
            Caption = 'BOM Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."));
        }
        field(83; "Qty. per BOM Line"; Decimal)
        {
            Caption = 'Qty. per BOM Line';
            DecimalPlaces = 0 : 5;
        }
        field(84; "Inventoriable"; Boolean)
        {
            Caption = 'Inventoriable';
        }
        field(85; "Calculation Formula"; Enum "Quantity Calculation Formula")
        {
            Caption = 'Calculation Formula';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Low-Level Code")
        {
        }
        key(Key3; Type, "No.", Indentation)
        {
            SumIndexFields = "Able to Make Parent";
        }
        key(Key4; "Total Cost")
        {
        }
    }

    fieldgroups
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        UOMMgt: Codeunit "Unit of Measure Management";
        GLSetupRead: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The Low-level Code for Item %1 has not been calculated.';
        Text002: Label 'The Quantity per. field in the BOM for Item %1 has not been set.';
        Text005: Label 'Item %1 is not a BOM. Therefore, the Replenishment System field must be set to Purchase.';
        Text006: Label 'Replenishment System for Item %1 is Assembly, but the item is not an assembly BOM. Verify that this is correct.';
        Text007: Label 'Replenishment System for Item %1 is Prod. Order, but the item does not have a production BOM. Verify that this is correct.';
        Text008: Label 'Item %1 is a BOM, but the Replenishment System field is not set to Assembly or Prod. Order. Verify that the value is correct.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure TransferFromItem(var EntryNo: Integer; Item: Record Item; DemandDate: Date)
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;
        Type := Type::Item;

        InitFromItem(Item);

        "Qty. per Parent" := 1;
        "Qty. per Top Item" := 1;
        "Needed by Date" := DemandDate;
        Indentation := 0;

        OnTransferFromItemCopyFields(Rec, Item);
        Insert(true);
    end;

    procedure TransferFromBOMComp(var EntryNo: Integer; BOMComp: Record "BOM Component"; NewIndentation: Integer; ParentQtyPer: Decimal; ParentScrapQtyPer: Decimal; NeedByDate: Date; ParentLocationCode: Code[10])
    var
        BOMItem: Record Item;
        BOMRes: Record Resource;
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;

        case BOMComp.Type of
            BOMComp.Type::Item:
                begin
                    BOMItem.Get(BOMComp."No.");
                    InitFromItem(BOMItem);
                end;
            BOMComp.Type::Resource:
                begin
                    BOMRes.Get(BOMComp."No.");
                    InitFromRes(BOMRes);
                    "Resource Usage Type" := BOMComp."Resource Usage Type";
                end;
        end;

        Description := BOMComp.Description;
        "Qty. per Parent" := BOMComp."Quantity per";
        "Qty. per Top Item" := Round(BOMComp."Quantity per" * ParentQtyPer, UOMMgt.QtyRndPrecision());

        "Scrap Qty. per Top Item" :=
          "Qty. per Top Item" - Round((ParentQtyPer - ParentScrapQtyPer) * "Qty. per Parent", UOMMgt.QtyRndPrecision());

        "Unit of Measure Code" := BOMComp."Unit of Measure Code";
        "Variant Code" := BOMComp."Variant Code";
        "Location Code" := ParentLocationCode;
        "Lead-Time Offset" := BOMComp."Lead-Time Offset";
        "Needed by Date" := NeedByDate;
        Indentation := NewIndentation;

        OnTransferFromBOMCompCopyFields(Rec, BOMComp);
        Insert(true);
    end;

    procedure InitFromItem(Item: Record Item)
    var
        SKU: Record "Stockkeeping Unit";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitFromItem(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        Type := Type::Item;
        "No." := Item."No.";
        Description := Item.Description;
        "Unit of Measure Code" := Item."Base Unit of Measure";

        if GetSKUFromFilter(SKU, "No.") then
            "Replenishment System" := SKU."Replenishment System"
        else
            "Replenishment System" := Item."Replenishment System";
        OnInitFromItemOnAfterSetReplenishmentSystem(Rec, Item, SKU);

        "Lot Size" := Item."Lot Size";
        "Scrap %" := Item."Scrap %";
        "Indirect Cost %" := Item."Indirect Cost %";
        "Overhead Rate" := Item."Overhead Rate";
        "Low-Level Code" := Item."Low-Level Code";
        "Rounding Precision" := Item."Rounding Precision";
        "Lead Time Calculation" := Item."Lead Time Calculation";
        "Safety Lead Time" := Item."Safety Lead Time";
        "Inventoriable" := Item.IsInventoriableType();

        SetRange("Location Code");
        SetRange("Variant Code");

        OnAfterInitFromItem(Rec, Item, SKU);
    end;

    procedure InitFromRes(Resourse: Record Resource)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitFromRes(Rec, Resourse, IsHandled);
        if IsHandled then
            exit;

        Type := Type::Resource;
        "No." := Resourse."No.";
        Description := Resourse.Name;
        "Unit of Measure Code" := Resourse."Base Unit of Measure";

        "Replenishment System" := "Replenishment System"::Transfer;
        "Is Leaf" := true;

        OnAfterInitFromRes(Rec, Resourse);
    end;

    local procedure SetAbleToMakeToZeroIfNegative()
    begin
        if "Able to Make Parent" < 0 then
            "Able to Make Parent" := 0;
        if "Able to Make Top Item" < 0 then
            "Able to Make Top Item" := 0;
    end;

    procedure UpdateAbleToMake(AvailQty: Decimal)
    var
        Item: Record Item;
        QtyPerUOM: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateAbleToMake(Rec, AvailQty, IsHandled);
        if IsHandled then
            exit;

        QtyPerUOM := 1;
        if Type = Type::Item then begin
            Item.Get("No.");
            QtyPerUOM := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
        end;

        if "Is Leaf" then begin
            if "Qty. per Parent" <> 0 then
                "Able to Make Parent" := Round(AvailQty / ("Qty. per Parent" * QtyPerUOM), UOMMgt.QtyRndPrecision());
            if "Qty. per Top Item" <> 0 then
                "Able to Make Top Item" := Round(AvailQty / ("Qty. per Top Item" * QtyPerUOM), UOMMgt.QtyRndPrecision());
        end else
            if Indentation = 0 then begin
                "Able to Make Parent" := "Able to Make Parent";
                "Able to Make Top Item" := "Able to Make Top Item";
            end else begin
                if "Qty. per Parent" <> 0 then
                    "Able to Make Parent" :=
                      Round((AvailQty + "Able to Make Parent") / ("Qty. per Parent" * QtyPerUOM), UOMMgt.QtyRndPrecision());
                if "Qty. per Top Item" <> 0 then
                    "Able to Make Top Item" :=
                      Round(AvailQty / ("Qty. per Top Item" * QtyPerUOM) + "Able to Make Top Item", UOMMgt.QtyRndPrecision());
            end;

        SetAbleToMakeToZeroIfNegative();
    end;

    procedure AddMaterialCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Level Material Cost" += SingleLvlCostAmt;
        "Rolled-up Material Cost" += RolledUpCostAmt;
    end;

    procedure AddCapacityCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Level Capacity Cost" += SingleLvlCostAmt;
        "Rolled-up Capacity Cost" += RolledUpCostAmt;
    end;

    procedure AddCapOvhdCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Level Cap. Ovhd Cost" += SingleLvlCostAmt;
        "Rolled-up Capacity Ovhd. Cost" += RolledUpCostAmt;
    end;

    procedure AddSubcontrdCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Level Subcontrd. Cost" += SingleLvlCostAmt;
        "Rolled-up Subcontracted Cost" += RolledUpCostAmt;
    end;

    procedure AddMfgOvhdCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Level Mfg. Ovhd Cost" += SingleLvlCostAmt;
        "Rolled-up Mfg. Ovhd Cost" += RolledUpCostAmt;
    end;

    procedure AddScrapCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Level Scrap Cost" += SingleLvlCostAmt;
        "Rolled-up Scrap Cost" += RolledUpCostAmt;
    end;

    procedure AddNonInvMaterialCost(SingleLvlCostAmt: Decimal; RolledUpCostAmt: Decimal)
    begin
        "Single-Lvl Mat. Non-Invt. Cost" += SingleLvlCostAmt;
        "Rolled-up Mat. Non-Invt. Cost" += RolledUpCostAmt;
    end;

    procedure GetItemCosts()
    var
        Item: Record Item;
    begin
        TestField(Type, Type::Item);
        Item.Get("No.");

        "Unit Cost" := Item."Unit Cost";
        if Item.IsInventoriableType() then begin
            "Single-Level Material Cost" := "Unit Cost";
            "Rolled-up Material Cost" := "Single-Level Material Cost";
        end;

        OnGetItemCostsOnBeforeRoundCosts(Rec, Item);
        RoundCosts(UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code") * "Qty. per Top Item");

        OnAfterGetItemCosts(Rec, Item);
    end;

    procedure GetItemUnitCost()
    var
        Item: Record Item;
    begin
        TestField(Type, Type::Item);
        Item.Get("No.");

        "Unit Cost" := Item."Unit Cost";
        "Single-Level Material Cost" :=
          RoundUnitAmt(Item."Single-Level Material Cost", UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code") * "Qty. per Top Item");
        "Rolled-up Material Cost" :=
          RoundUnitAmt(Item."Unit Cost", UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code") * "Qty. per Top Item");

        OnAfterGetUnitCost(Rec, Item);
    end;

    procedure GetResCosts()
    var
        Res: Record Resource;
    begin
        TestField(Type, Type::Resource);
        Res.Get("No.");

        "Unit Cost" := Res."Unit Cost";
        "Indirect Cost %" := Res."Indirect Cost %";

        "Single-Level Capacity Cost" := Res."Direct Unit Cost";
        "Single-Level Cap. Ovhd Cost" := Res."Unit Cost" - Res."Direct Unit Cost";

        "Rolled-up Capacity Cost" := Res."Direct Unit Cost";
        "Rolled-up Capacity Ovhd. Cost" := Res."Unit Cost" - Res."Direct Unit Cost";

        if "Resource Usage Type" = "Resource Usage Type"::Fixed then
            RoundCosts(UOMMgt.GetResQtyPerUnitOfMeasure(Res, "Unit of Measure Code") * "Qty. per Parent")
        else
            RoundCosts(UOMMgt.GetResQtyPerUnitOfMeasure(Res, "Unit of Measure Code") * "Qty. per Top Item");
    end;

    local procedure GetSKUFromFilter(var SKU: Record "Stockkeeping Unit"; ItemNo: Code[20]): Boolean
    var
        LocationFilter: Text;
        VariantFilter: Text;
    begin
        LocationFilter := GetFilter("Location Code");
        if StrLen(LocationFilter) > MaxStrLen("Location Code") then
            exit(false);

        VariantFilter := GetFilter("Variant Code");
        if StrLen(VariantFilter) > MaxStrLen("Variant Code") then
            exit(false);

        exit(SKU.Get(LocationFilter, ItemNo, VariantFilter));
    end;

    procedure RoundCosts(ShareOfTotalCost: Decimal)
    begin
        "Single-Level Material Cost" := RoundUnitAmt("Single-Level Material Cost", ShareOfTotalCost);
        "Single-Level Capacity Cost" := RoundUnitAmt("Single-Level Capacity Cost", ShareOfTotalCost);
        "Single-Level Cap. Ovhd Cost" := RoundUnitAmt("Single-Level Cap. Ovhd Cost", ShareOfTotalCost);

        "Rolled-up Material Cost" := RoundUnitAmt("Rolled-up Material Cost", ShareOfTotalCost);
        "Rolled-up Capacity Cost" := RoundUnitAmt("Rolled-up Capacity Cost", ShareOfTotalCost);
        "Rolled-up Capacity Ovhd. Cost" := RoundUnitAmt("Rolled-up Capacity Ovhd. Cost", ShareOfTotalCost);

        OnAfterRoundCosts(Rec, ShareOfTotalCost);
    end;

    procedure RoundUnitAmt(Amt: Decimal; ShareOfCost: Decimal) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRoundUnitAmt(Amt, ShareOfCost, IsHandled, Result);
        if IsHandled then
            exit(Result);

        GetGLSetup();
        exit(Round(Amt * ShareOfCost, GLSetup."Unit-Amount Rounding Precision"));
    end;

    procedure CalcOvhdCost()
    var
        Item: Record Item;
        LotSize: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcOvhdCost(Rec, IsHandled);
        if IsHandled then
            exit;

        LotSize := 1;
        if "Lot Size" <> 0 then
            LotSize := "Lot Size";

        Item.Get("No.");

        "Overhead Rate" :=
          RoundUnitAmt("Overhead Rate", UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code") * "Qty. per Top Item");

        OnAfterCalcOvhdCost(Rec, LotSize);
    end;

    procedure CalcDirectCost() Cost: Decimal
    begin
        Cost := "Single-Level Material Cost" + "Single-Level Capacity Cost";

        OnAfterCalcDirectCost(Rec, Cost);
    end;

    procedure CalcIndirectCost() Cost: Decimal
    begin
        Cost := "Single-Level Cap. Ovhd Cost";

        OnAfterCalcIndirectCost(Rec, Cost);
    end;

    procedure CalcUnitCost()
    begin
        "Total Cost" := CalcDirectCost() + CalcIndirectCost();
        "Unit Cost" := 0;
        if "Qty. per Top Item" <> 0 then
            "Unit Cost" := Round("Total Cost" / "Qty. per Top Item", 0.00001);
        OnAfterCalcUnitCost(Rec);
    end;

    local procedure IsLowLevelOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log") Result: Boolean
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsLowLevelOk(Rec, Result, IsHandled, LogWarning, BOMWarningLog);
        if IsHandled then
            exit(Result);

        if Type <> Type::Item then
            exit(true);
        if "No." = '' then
            exit(true);

        Item.Get("No.");
        if TraverseIsLowLevelOk(Item) then
            exit(true);

        if LogWarning then
            SetItemWarningLog(BOMWarningLog, Item, Text001);
    end;

    local procedure TraverseIsLowLevelOk(ParentItem: Record Item): Boolean
    var
        ParentBOMBuffer: Record "BOM Buffer";
        ChildItem: Record Item;
    begin
        if Type <> Type::Item then
            exit(true);
        if "No." = '' then
            exit(true);

        ParentItem.Get("No.");
        ParentBOMBuffer := Rec;
        while (Next() <> 0) and (ParentBOMBuffer.Indentation < Indentation) do
            if (ParentBOMBuffer.Indentation + 1 = Indentation) and (Type = Type::Item) and ("No." <> '') then begin
                ChildItem.Get("No.");
                if ParentItem."Low-Level Code" >= ChildItem."Low-Level Code" then begin
                    Rec := ParentBOMBuffer;
                    exit(false);
                end;
            end;

        Rec := ParentBOMBuffer;
        exit(true);
    end;

    local procedure IsQtyPerOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log"): Boolean
    var
        Item: Record Item;
        CopyOfBOMBuffer: Record "BOM Buffer";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsQtyPerOk(Rec, BOMWarningLog, LogWarning, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if "Qty. per Parent" <> 0 then
            exit(true);
        if "No." = '' then
            exit(true);
        if Indentation = 0 then
            exit(true);
        if Type in [Type::"Machine Center", Type::"Work Center"] then
            exit(true);

        if LogWarning then begin
            CopyOfBOMBuffer.Copy(Rec);
            Reset();
            SetRange(Indentation, 0, Indentation);
            SetRange(Type, Type::Item);
            while (Next(-1) <> 0) and (Indentation >= CopyOfBOMBuffer.Indentation) do
                ;
            if "Entry No." <> CopyOfBOMBuffer."Entry No." then begin
                Item.Get("No.");
                Item.CalcFields("Assembly BOM");
                if Item."Assembly BOM" then
                    SetItemWarningLog(BOMWarningLog, Item, Text002);
                OnIsQtyPerOKOnAfterCheckItemAssemblyBOM(Item, BOMWarningLog);
            end;
            Copy(CopyOfBOMBuffer);
        end;
    end;

    local procedure IsReplenishmentOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log"): Boolean
    var
        Item: Record Item;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsReplenishmentOk(Rec, BOMWarningLog, LogWarning, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Type <> Type::Item then
            exit(true);
        if "No." = '' then
            exit(true);

        Item.Get("No.");
        if "Is Leaf" then begin
            if Item."Replenishment System" in ["Replenishment System"::Purchase, "Replenishment System"::Transfer] then
                exit(true);
            if LogWarning then
                SetItemWarningLog(BOMWarningLog, Item, Text005);
        end else begin
            if Item.IsMfgItem() or Item.IsAssemblyItem() then
                exit(IsBOMOk(LogWarning, BOMWarningLog));
            if LogWarning then
                SetItemWarningLog(BOMWarningLog, Item, Text008);
        end;
    end;

    local procedure IsBOMOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log") Result: Boolean
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsBOMOk(Rec, Result, IsHandled, LogWarning, BOMWarningLog);
        if IsHandled then
            exit(Result);

        if Type <> Type::Item then
            exit(true);
        if "No." = '' then
            exit(true);

        Item.Get("No.");
        case Item."Replenishment System" of
            Item."Replenishment System"::Assembly:
                begin
                    Item.CalcFields("Assembly BOM");
                    if Item."Assembly BOM" then
                        exit(true);
                    if LogWarning then
                        SetItemWarningLog(BOMWarningLog, Item, Text006);
                end;
            Item."Replenishment System"::"Prod. Order":
                begin
                    if Item.IsProductionBOM() then
                        exit(true);
                    if LogWarning then
                        SetItemWarningLog(BOMWarningLog, Item, Text007);
                end;
            else begin
                IsHandled := false;
                exit(true);
            end;
        end;
    end;

    procedure IsLineOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log") Result: Boolean
    begin
        Result :=
          IsLowLevelOk(LogWarning, BOMWarningLog) and
          IsQtyPerOk(LogWarning, BOMWarningLog) and
          IsReplenishmentOk(LogWarning, BOMWarningLog);

        OnAfterIsLineOk(Rec, LogWarning, BOMWarningLog, Result);
    end;

    procedure AreAllLinesOk(var BOMWarningLog: Record "BOM Warning Log") IsOk: Boolean
    var
        CopyOfBOMBuffer: Record "BOM Buffer";
    begin
        IsOk := true;
        CopyOfBOMBuffer.Copy(Rec);

        BOMWarningLog.Reset();
        BOMWarningLog.DeleteAll();

        Reset();
        if FindSet() then
            repeat
                if not IsLineOk(true, BOMWarningLog) then
                    IsOk := false;
            until Next() = 0;
        Copy(CopyOfBOMBuffer);
    end;

    local procedure GetGLSetup()
    begin
        if GLSetupRead then
            exit;
        GLSetup.Get();
        GLSetupRead := true;
    end;

    procedure SetLocationVariantFiltersFrom(var ItemFilter: Record Item)
    begin
        SetFilter("Location Code", ItemFilter.GetFilter("Location Filter"));
        SetFilter("Variant Code", ItemFilter.GetFilter("Variant Filter"));
    end;

    procedure SetItemWarningLog(var BOMWarningLog: Record "BOM Warning Log"; var Item: Record Item; WarningText: Text)
    begin
        BOMWarningLog.SetWarning(StrSubstNo(WarningText, Item."No."), DATABASE::Item, CopyStr(Item.GetPosition(), 1, 250));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcUnitCost(var BOMBuffer: Record "BOM Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItemCosts(var BOMBuffer: Record "BOM Buffer"; Item: Record Item);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromItem(var BOMBuffer: Record "BOM Buffer"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromRes(var BOMBuffer: Record "BOM Buffer"; Resource: Record Resource);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsLineOk(var BOMBuffer: Record "BOM Buffer"; LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundCosts(var BOMBuffer: Record "BOM Buffer"; ShareOfTotalCost: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcOvhdCost(var BOMBuffer: Record "BOM Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFromItem(var BOMBuffer: Record "BOM Buffer"; Item: Record Item; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsBOMOk(var BOMBuffer: Record "BOM Buffer"; var Result: Boolean; var IsHandled: Boolean; var LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsLowLevelOk(var BOMBuffer: Record "BOM Buffer"; var Result: Boolean; var IsHandled: Boolean; var LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFromRes(var BOMBuffer: Record "BOM Buffer"; Resource: Record Resource; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateAbleToMake(var BOMBuffer: Record "BOM Buffer"; var AvailQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetItemCostsOnBeforeRoundCosts(var BOMBuffer: Record "BOM Buffer"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromItemCopyFields(var BOMBuffer: Record "BOM Buffer"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromBOMCompCopyFields(var BOMBuffer: Record "BOM Buffer"; BOMComponent: Record "BOM Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsQtyPerOk(var BOMBuffer: Record "BOM Buffer"; var BOMWarningLog: Record "BOM Warning Log"; LogWarning: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsReplenishmentOk(var BOMBuffer: Record "BOM Buffer"; var BOMWarningLog: Record "BOM Warning Log"; LogWarning: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundUnitAmt(Amt: Decimal; ShareOfCost: Decimal; var IsHandled: Boolean; var ReturnValue: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcDirectCost(var BOMBuffer: Record "BOM Buffer"; var Cost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcIndirectCost(var BOMBuffer: Record "BOM Buffer"; var Cost: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcOvhdCost(var BOMBuffer: Record "BOM Buffer"; LotSize: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUnitCost(var BOMBuffer: Record "BOM Buffer"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsQtyPerOKOnAfterCheckItemAssemblyBOM(Item: Record Item; var BOMWarningLog: Record "BOM Warning Log")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitFromItemOnAfterSetReplenishmentSystem(var BOMBuffer: Record "BOM Buffer"; Item: Record Item; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;
}

