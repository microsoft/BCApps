// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;

table 5820 "Cost Element Buffer"
{
    Caption = 'Cost Element Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Enum "Cost Entry Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(2; "Variance Type"; Enum "Cost Variance Type")
        {
            Caption = 'Variance Type';
            DataClassification = SystemMetadata;
        }
        field(3; "Actual Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Actual Cost';
            DataClassification = SystemMetadata;
        }
        field(4; "Actual Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Actual Cost (ACY)';
            DataClassification = SystemMetadata;
        }
        field(5; "Rounding Residual"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Rounding Residual';
            DataClassification = SystemMetadata;
        }
        field(6; "Rounding Residual (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Rounding Residual (ACY)';
            DataClassification = SystemMetadata;
        }
        field(7; "Expected Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Expected Cost';
            DataClassification = SystemMetadata;
        }
        field(8; "Expected Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Expected Cost (ACY)';
            DataClassification = SystemMetadata;
        }
        field(9; "Invoiced Quantity"; Decimal)
        {
            Caption = 'Invoiced Quantity';
            DataClassification = SystemMetadata;
        }
        field(10; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DataClassification = SystemMetadata;
        }
        field(11; "Inbound Completely Invoiced"; Boolean)
        {
            Caption = 'Inbound Completely Invoiced';
            DataClassification = SystemMetadata;
        }
        field(12; "Last Valid Value Entry No"; Integer)
        {
            Caption = 'Last Valid Value Entry No';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Type, "Variance Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    protected var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralLedgerSetupRead: Boolean;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GeneralLedgerSetupRead then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetupRead := true;
        end;
        exit(GeneralLedgerSetup."Additional Reporting Currency")
    end;

    procedure Initialize(KeepRoundingResidual: Boolean)
    var
        CostElementBuffer: Record "Cost Element Buffer";
    begin
        if KeepRoundingResidual then begin
            CostElementBuffer := Rec;
            Init();
            "Rounding Residual" := CostElementBuffer."Rounding Residual";
            "Rounding Residual (ACY)" := CostElementBuffer."Rounding Residual (ACY)";
        end else
            Init();
    end;


    procedure AddActualCostElement(NewEntryType: Enum "Cost Entry Type"; NewActualCost: Decimal; NewActualCostACY: Decimal)
    begin
        if not HasNewCost(NewActualCost, NewActualCostACY) then begin
            GetElement(NewEntryType);
            exit;
        end;

        if GetElement(NewEntryType) then begin
            "Actual Cost" += NewActualCost;
            "Actual Cost (ACY)" += NewActualCostACY;
            Modify();
        end else begin
            "Actual Cost" := NewActualCost;
            "Actual Cost (ACY)" := NewActualCostACY;
            Insert();
        end;
    end;

    procedure AddActualCostElement(NewEntryType: Enum "Cost Entry Type"; ValueEntry: Record "Value Entry")
    begin
        AddActualCostElement(NewEntryType, ValueEntry."Cost Amount (Actual)", ValueEntry."Cost Amount (Actual) (ACY)");
    end;

    procedure AddExpectedCostElement(NewEntryType: Enum "Cost Entry Type"; NewExpectedCost: Decimal; NewExpectedCostACY: Decimal)
    begin
        if not HasNewCost(NewExpectedCost, NewExpectedCostACY) then begin
            GetElement(NewEntryType);
            exit;
        end;
        if GetElement(NewEntryType) then begin
            "Expected Cost" += NewExpectedCost;
            "Expected Cost (ACY)" += NewExpectedCostACY;
            Modify();
        end else begin
            "Expected Cost" := NewExpectedCost;
            "Expected Cost (ACY)" := NewExpectedCostACY;
            Insert();
        end;
    end;

    procedure AddExpectedCostElement(NewEntryType: Enum "Cost Entry Type"; ValueEntry: Record "Value Entry")
    begin
        AddExpectedCostElement(NewEntryType, ValueEntry."Cost Amount (Expected)", ValueEntry."Cost Amount (Expected) (ACY)");
    end;

    procedure RoundActualCost(ShareOfTotalCost: Decimal; AmtRndgPrec: Decimal; AmtRndgPrecACY: Decimal)
    begin
        "Actual Cost" := Round("Actual Cost" * ShareOfTotalCost, AmtRndgPrec);
        "Actual Cost (ACY)" := Round("Actual Cost (ACY)" * ShareOfTotalCost, AmtRndgPrecACY);

        OnAfterRoundActualCost(Rec, ShareOfTotalCost, AmtRndgPrec, AmtRndgPrecACY);
    end;

    procedure ExcludeEntryFromAvgCostCalc(ValueEntry: Record "Value Entry")
    begin
        "Remaining Quantity" := "Remaining Quantity" - ValueEntry."Item Ledger Entry Quantity";
        "Actual Cost" := "Actual Cost" - ValueEntry."Cost Amount (Actual)" - ValueEntry."Cost Amount (Expected)";
        "Actual Cost (ACY)" :=
          "Actual Cost (ACY)" - ValueEntry."Cost Amount (Actual) (ACY)" - ValueEntry."Cost Amount (Expected) (ACY)";

        OnAfterExcludeEntryFromAvgCostCalc(Rec, ValueEntry);
    end;

    procedure ExcludeBufFromAvgCostCalc(InvtAdjmtBuffer: Record "Inventory Adjustment Buffer")
    begin
        "Remaining Quantity" := "Remaining Quantity" - InvtAdjmtBuffer."Item Ledger Entry Quantity";
        "Actual Cost" := "Actual Cost" - InvtAdjmtBuffer."Cost Amount (Actual)" - InvtAdjmtBuffer."Cost Amount (Expected)";
        "Actual Cost (ACY)" :=
          "Actual Cost (ACY)" - InvtAdjmtBuffer."Cost Amount (Actual) (ACY)" - InvtAdjmtBuffer."Cost Amount (Expected) (ACY)";

        OnAfterExcludeBufFromAvgCostCalc(Rec, InvtAdjmtBuffer);
    end;


    procedure GetElement(NewEntryType: Enum "Cost Entry Type"): Boolean
    begin
        if Get(NewEntryType, "Variance Type"::" ") then
            exit(true);

        Init();
        Type := NewEntryType;
        "Variance Type" := "Variance Type"::" ";
        exit(false);
    end;

    local procedure HasNewCost(NewCost: Decimal; NewCostACY: Decimal): Boolean
    begin
        exit((NewCost <> 0) or (NewCostACY <> 0));
    end;

    procedure DeductOutbndValueEntryFromBuf(OutbndValueEntry: Record "Value Entry"; CostElementBuf: Record "Cost Element Buffer"; IsAvgCostCalcTypeItem: Boolean)
    begin
        if "Remaining Quantity" + OutbndValueEntry."Valued Quantity" <= 0 then
            exit;

        if (OutbndValueEntry."Item Ledger Entry Type" = OutbndValueEntry."Item Ledger Entry Type"::Transfer) and
           IsAvgCostCalcTypeItem
        then
            exit;

        "Remaining Quantity" += OutbndValueEntry."Valued Quantity";
        "Actual Cost" += CostElementBuf."Actual Cost";
        "Actual Cost (ACY)" += CostElementBuf."Actual Cost (ACY)";
        "Rounding Residual" := 0;
        "Rounding Residual (ACY)" := 0;

        OnAfterDeductOutbndValueEntryFromBuf(Rec, OutbndValueEntry, CostElementBuf, IsAvgCostCalcTypeItem);
    end;

    procedure UpdateAvgCostBuffer(CostElementBuf: Record "Cost Element Buffer"; LastValidEntryNo: Integer)
    begin
        "Actual Cost" := CostElementBuf."Actual Cost";
        "Actual Cost (ACY)" := CostElementBuf."Actual Cost (ACY)";
        "Last Valid Value Entry No" := LastValidEntryNo;
        "Remaining Quantity" := CostElementBuf."Remaining Quantity";

        OnAfterUpdateAvgCostBuffer(Rec, CostElementBuf, LastValidEntryNo);
    end;

    procedure UpdateCostElementBuffer(AvgCostBuf: Record "Cost Element Buffer")
    begin
        "Remaining Quantity" := AvgCostBuf."Remaining Quantity";
        "Actual Cost" := AvgCostBuf."Actual Cost";
        "Actual Cost (ACY)" := AvgCostBuf."Actual Cost (ACY)";
        "Rounding Residual" := AvgCostBuf."Rounding Residual";
        "Rounding Residual (ACY)" := AvgCostBuf."Rounding Residual (ACY)";

        OnAfterUpdateCostElementBuffer(Rec, AvgCostBuf);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateAvgCostBuffer(var CostElementBuffer: Record "Cost Element Buffer"; CostElementBuf: Record "Cost Element Buffer"; LastValidEntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateCostElementBuffer(var CostElementBuffer: Record "Cost Element Buffer"; AvgCostBuf: Record "Cost Element Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExcludeBufFromAvgCostCalc(var CostElementBuffer: Record "Cost Element Buffer"; InvtAdjmtBuffer: Record "Inventory Adjustment Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundActualCost(var CostElementBuffer: Record "Cost Element Buffer"; ShareOfTotalCost: Decimal; AmtRndgPrec: Decimal; AmtRndgPrecACY: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeductOutbndValueEntryFromBuf(var CostElementBuffer: Record "Cost Element Buffer"; OutbndValueEntry: Record "Value Entry"; CostElementBuf: Record "Cost Element Buffer"; IsAvgCostCalcTypeItem: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterExcludeEntryFromAvgCostCalc(var CostElementBuffer: Record "Cost Element Buffer"; ValueEntry: Record "Value Entry")
    begin
    end;
}