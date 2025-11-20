// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;

table 5895 "Inventory Adjustment Buffer"
{
    Caption = 'Inventory Adjustment Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
            TableRelation = Item;
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(8; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
            TableRelation = Location;
        }
        field(11; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            DataClassification = SystemMetadata;
            TableRelation = "Item Ledger Entry";
        }
        field(13; "Item Ledger Entry Quantity"; Decimal)
        {
            Caption = 'Item Ledger Entry Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(43; "Cost Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount (Actual)';
            DataClassification = SystemMetadata;
        }
        field(68; "Cost Amount (Actual) (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Cost Amount (Actual) (ACY)';
            DataClassification = SystemMetadata;
        }
        field(98; "Expected Cost"; Boolean)
        {
            Caption = 'Expected Cost';
            DataClassification = SystemMetadata;
        }
        field(100; "Valued By Average Cost"; Boolean)
        {
            Caption = 'Valued By Average Cost';
            DataClassification = SystemMetadata;
        }
        field(104; "Valuation Date"; Date)
        {
            Caption = 'Valuation Date';
            DataClassification = SystemMetadata;
        }
        field(105; "Entry Type"; Enum "Cost Entry Type")
        {
            Caption = 'Entry Type';
            DataClassification = SystemMetadata;
        }
        field(106; "Variance Type"; Enum "Cost Variance Type")
        {
            Caption = 'Variance Type';
            DataClassification = SystemMetadata;
        }
        field(151; "Cost Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount (Expected)';
            DataClassification = SystemMetadata;
        }
        field(156; "Cost Amount (Expected) (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Cost Amount (Expected) (ACY)';
            DataClassification = SystemMetadata;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Item Ledger Entry No.")
        {
            SumIndexFields = "Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Expected) (ACY)", "Cost Amount (Actual) (ACY)";
        }
        key(Key3; "Item No.", "Valuation Date", "Location Code", "Variant Code")
        {
            SumIndexFields = "Cost Amount (Expected)", "Cost Amount (Actual)", "Cost Amount (Expected) (ACY)", "Cost Amount (Actual) (ACY)", "Item Ledger Entry Quantity";
        }
    }

    fieldgroups
    {
    }

    var
        GLSetup: Record "General Ledger Setup";
        UOMMgt: Codeunit "Unit of Measure Management";
        GLSetupRead: Boolean;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure CalcItemLedgEntryCost(ItemLedgEntryNo: Integer; Expected: Boolean)
    var
        ItemLedgEntryQty: Decimal;
        CostAmtActual: Decimal;
        CostAmtActualACY: Decimal;
        CostAmtExpected: Decimal;
        CostAmtExpectedACY: Decimal;
    begin
        Reset();
        SetCurrentKey("Item Ledger Entry No.");
        SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        if Find('-') then
            repeat
                if "Expected Cost" = Expected then begin
                    ItemLedgEntryQty := ItemLedgEntryQty + "Item Ledger Entry Quantity";
                    CostAmtActual := CostAmtActual + "Cost Amount (Actual)";
                    CostAmtActualACY := CostAmtActualACY + "Cost Amount (Actual) (ACY)";
                    CostAmtExpected := CostAmtExpected + "Cost Amount (Expected)";
                    CostAmtExpectedACY := CostAmtExpectedACY + "Cost Amount (Expected) (ACY)";
                end;
            until Next() = 0;

        "Item Ledger Entry Quantity" := ItemLedgEntryQty;
        "Cost Amount (Actual)" := CostAmtActual;
        "Cost Amount (Actual) (ACY)" := CostAmtActualACY;
        "Cost Amount (Expected)" := CostAmtExpected;
        "Cost Amount (Expected) (ACY)" := CostAmtExpectedACY;
    end;

    procedure SumCostsTillValuationDate(var ValueEntry: Record "Value Entry")
    var
        AccountingPeriod: Record "Accounting Period";
        PrevInvtAdjmtBufSum: Record "Inventory Adjustment Buffer";
        Item: Record Item;
        FromDate: Date;
        ToDate: Date;
        CostCalcIsChanged: Boolean;
        QtyFactor: Decimal;
    begin
        Item.Get(ValueEntry."Item No.");
        OnSumCostsTillValuationDateGetItem(Item, ValueEntry);
        if Item."Costing Method" = Item."Costing Method"::Average then
            ToDate := ValueEntry.GetAvgToDate(ValueEntry."Valuation Date")
        else
            ToDate := "Valuation Date";

        repeat
            if Item."Costing Method" = Item."Costing Method"::Average then
                FromDate := ValueEntry.GetAvgFromDate(ToDate, AccountingPeriod, CostCalcIsChanged)
            else
                FromDate := 0D;

            QtyFactor := 1;
            Reset();
            SetCurrentKey("Item No.", "Valuation Date", "Location Code", "Variant Code");
            SetRange("Item No.", ValueEntry."Item No.");
            SetRange("Valuation Date", FromDate, ToDate);
            if (AccountingPeriod."Average Cost Calc. Type" =
                AccountingPeriod."Average Cost Calc. Type"::"Item & Location & Variant") or
               (Item."Costing Method" <> Item."Costing Method"::Average)
            then begin
                SetRange("Location Code", ValueEntry."Location Code");
                SetRange("Variant Code", ValueEntry."Variant Code");
            end else
                if CostCalcIsChanged then
                    QtyFactor := ValueEntry.CalcQtyFactor(FromDate, ToDate);

            OnSumCostsTillValuationDateOnBeforeCalcSums(Rec, QtyFactor, FromDate, ToDate, ValueEntry);
            CalcSums(
              "Item Ledger Entry Quantity",
              "Cost Amount (Actual)", "Cost Amount (Actual) (ACY)",
              "Cost Amount (Expected)", "Cost Amount (Expected) (ACY)");

            "Item Ledger Entry Quantity" :=
              Round("Item Ledger Entry Quantity" * QtyFactor, UOMMgt.QtyRndPrecision()) + PrevInvtAdjmtBufSum."Item Ledger Entry Quantity";
            "Cost Amount (Actual)" :=
              "Cost Amount (Actual)" * QtyFactor + PrevInvtAdjmtBufSum."Cost Amount (Actual)";
            "Cost Amount (Expected)" :=
              "Cost Amount (Expected)" * QtyFactor + PrevInvtAdjmtBufSum."Cost Amount (Expected)";
            "Cost Amount (Expected) (ACY)" :=
              "Cost Amount (Expected) (ACY)" * QtyFactor + PrevInvtAdjmtBufSum."Cost Amount (Expected) (ACY)";
            "Cost Amount (Actual) (ACY)" :=
              "Cost Amount (Actual) (ACY)" * QtyFactor + PrevInvtAdjmtBufSum."Cost Amount (Actual) (ACY)";
            OnSumCostsTillValuationDateOnAfterSetCostAmounts(Rec, PrevInvtAdjmtBufSum, QtyFactor);
            PrevInvtAdjmtBufSum := Rec;

            if FromDate <> 0D then
                ToDate := CalcDate('<-1D>', FromDate);
        until FromDate = 0D;
    end;

    procedure AddActualCostBuf(ValueEntry: Record "Value Entry"; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal; ItemLedgEntryPostingDate: Date)
    begin
        Reset();
        "Entry No." := ValueEntry."Entry No.";
        if Find() then begin
            if ValueEntry."Expected Cost" then begin
                "Cost Amount (Expected)" := "Cost Amount (Expected)" + NewAdjustedCost;
                "Cost Amount (Expected) (ACY)" := "Cost Amount (Expected) (ACY)" + NewAdjustedCostACY;
            end else begin
                "Cost Amount (Actual)" := "Cost Amount (Actual)" + NewAdjustedCost;
                "Cost Amount (Actual) (ACY)" := "Cost Amount (Actual) (ACY)" + NewAdjustedCostACY;
            end;
            Modify();
        end else begin
            Init();
            "Item No." := ValueEntry."Item No.";
            "Document No." := ValueEntry."Document No.";
            "Location Code" := ValueEntry."Location Code";
            "Variant Code" := ValueEntry."Variant Code";
            "Entry Type" := ValueEntry."Entry Type";
            "Item Ledger Entry No." := ValueEntry."Item Ledger Entry No.";
            "Expected Cost" := ValueEntry."Expected Cost";
            if ItemLedgEntryPostingDate = 0D then
                "Posting Date" := ValueEntry."Posting Date"
            else
                "Posting Date" := ItemLedgEntryPostingDate;
            if ValueEntry."Expected Cost" then begin
                "Cost Amount (Expected)" := NewAdjustedCost;
                "Cost Amount (Expected) (ACY)" := NewAdjustedCostACY;
            end else begin
                "Cost Amount (Actual)" := NewAdjustedCost;
                "Cost Amount (Actual) (ACY)" := NewAdjustedCostACY;
            end;
            "Valued By Average Cost" := ValueEntry."Valued By Average Cost";
            "Valuation Date" := ValueEntry."Valuation Date";
            OnAddActualCostBufOnBeforeInsert(Rec, ValueEntry);
            Insert();
        end;
    end;

    procedure AddBalanceExpectedCostBuf(ValueEntry: Record "Value Entry"; NewAdjustedCost: Decimal; NewAdjustedCostACY: Decimal)
    begin
        if ValueEntry."Expected Cost" or
           (ValueEntry."Entry Type" <> ValueEntry."Entry Type"::"Direct Cost")
        then
            exit;

        Reset();
        "Entry No." := ValueEntry."Entry No.";
        Find();
        "Cost Amount (Expected)" := NewAdjustedCost;
        "Cost Amount (Expected) (ACY)" := NewAdjustedCostACY;
        Modify();
    end;

    procedure AddOrderCost(ItemLedgEntryNo: Integer; EntryType: Option; VarianceType: Option; CostAmt: Decimal; CostAmtLCY: Decimal)
    begin
        AddCost(ItemLedgEntryNo, "Cost Entry Type".FromInteger(EntryType), "Cost Variance Type".FromInteger(VarianceType), CostAmt, CostAmtLCY);
    end;

    procedure AddCost(ItemLedgEntryNo: Integer; EntryType: Enum "Cost Entry Type"; VarianceType: Enum "Cost Variance Type"; CostAmt: Decimal; CostAmtLCY: Decimal)
    var
        CopyOfInvtAdjmtBuf: Record "Inventory Adjustment Buffer";
    begin
        CopyOfInvtAdjmtBuf.Copy(Rec);
        Reset();
        SetCurrentKey("Item Ledger Entry No.");
        SetRange("Item Ledger Entry No.", ItemLedgEntryNo);
        SetRange("Entry Type", EntryType);
        SetRange("Variance Type", VarianceType);
        if FindFirst() then begin
            "Cost Amount (Actual)" += CostAmt;
            "Cost Amount (Actual) (ACY)" += CostAmtLCY;
            Modify();
        end else begin
            Init();
            "Item Ledger Entry No." := ItemLedgEntryNo;
            "Entry Type" := EntryType;
            "Variance Type" := VarianceType;
            "Entry No." := GetLastNo() + 1;
            "Cost Amount (Actual)" := CostAmt;
            "Cost Amount (Actual) (ACY)" := CostAmtLCY;
            Insert();
        end;
        Copy(CopyOfInvtAdjmtBuf);
    end;

    local procedure GetLastNo() LastNo: Integer
    var
        CopyOfInvtAdjmtBuf: Record "Inventory Adjustment Buffer";
    begin
        CopyOfInvtAdjmtBuf.Copy(Rec);
        Reset();
        if FindLast() then
            LastNo := "Entry No.";
        Copy(CopyOfInvtAdjmtBuf);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddActualCostBufOnBeforeInsert(var InventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer"; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumCostsTillValuationDateGetItem(var Item: Record Item; var ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumCostsTillValuationDateOnAfterSetCostAmounts(var InventoryAdjustmentBuffer: Record "Inventory Adjustment Buffer"; PrevInventoryAdjustmentBufferSum: Record "Inventory Adjustment Buffer"; QtyFactor: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSumCostsTillValuationDateOnBeforeCalcSums(var Rec: Record "Inventory Adjustment Buffer"; var QtyFactor: decimal; FromDate: Date; ToDate: Date; ValueEntry: Record "Value Entry")
    begin
    end;
}
