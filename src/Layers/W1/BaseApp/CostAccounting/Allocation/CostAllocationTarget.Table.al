// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CostAccounting.Allocation;

using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Budget;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Inventory.Item;
using System.Security.AccessControl;

table 1107 "Cost Allocation Target"
{
    Caption = 'Cost Allocation Target';
    DataClassification = CustomerContent;
    DrillDownPageID = "Cost Allocation Target List";
    LookupPageID = "Cost Allocation Target List";

    fields
    {
        field(1; ID; Code[10])
        {
            Caption = 'ID';
            Editable = false;
            TableRelation = "Cost Allocation Source";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
            InitValue = 0;
            NotBlank = true;
        }
        field(5; "Target Cost Type"; Code[20])
        {
            Caption = 'Target Cost Type';
            TableRelation = "Cost Type";
        }
        field(6; "Target Cost Center"; Code[20])
        {
            Caption = 'Target Cost Center';
            TableRelation = "Cost Center";

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateTargetCostCenter(Rec, IsHandled);
                if IsHandled then
                    exit;
                if ("Target Cost Center" <> '') and ("Target Cost Object" <> '') then
                    Error(Text000);
            end;
        }
        field(7; "Target Cost Object"; Code[20])
        {
            Caption = 'Target Cost Object';
            TableRelation = "Cost Object";

            trigger OnValidate()
            begin
                Validate("Target Cost Center")
            end;
        }
        field(8; "Static Base"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Static Base';
            DecimalPlaces = 0 : 2;
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate("Static Weighting");
            end;
        }
        field(9; "Static Weighting"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Static Weighting';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if Base = Base::Static then begin
                    Share := "Static Base" * "Static Weighting";
                    Validate(Share);
                end else begin
                    if "Static Base" > 0 then
                        Error(Text001, "Static Base");
                    if "Static Weighting" > 0 then
                        Error(Text001, "Static Weighting");
                end;
            end;
        }
        field(10; Share; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Share';
            DecimalPlaces = 2 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CalcPercent();
            end;
        }
        field(11; Percent; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Percent';
            DecimalPlaces = 2 : 5;
            Editable = false;
            MaxValue = 100;
            MinValue = 0;
        }
        field(20; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        field(30; Base; Enum "Cost Allocation Target Base")
        {
            Caption = 'Base';

            trigger OnValidate()
            begin
                if Base <> xRec.Base then begin
                    Share := 0;
                    Percent := 0;
                    "No. Filter" := '';
                    "Group Filter" := '';
                end;

                if Base = Base::Static then begin
                    "No. Filter" := '';
                    "Cost Center Filter" := '';
                    "Cost Object Filter" := '';
                    "Date Filter Code" := "Cost Allocation Target Period"::" ";
                    "Group Filter" := '';
                end else begin
                    "Static Base" := 0;
                    "Static Weighting" := 0;
                end;
            end;
        }
        field(31; "No. Filter"; Text[250])
        {
            Caption = 'No. Filter';

            trigger OnLookup()
            var
                SelectionFilter: Text[1024];
            begin
                if LookupNoFilter(SelectionFilter) then
                    Validate("No. Filter", CopyStr(SelectionFilter, 1, MaxStrLen("No. Filter")));
            end;
        }
        field(32; "Cost Center Filter"; Text[250])
        {
            Caption = 'Cost Center Filter';
            TableRelation = "Cost Center";
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                CostCenter: Record "Cost Center";
                SelectionFilter: Text[1024];
            begin
                if CostCenter.LookupCostCenterFilter(SelectionFilter) then
                    Validate("Cost Center Filter", CopyStr(SelectionFilter, 1, MaxStrLen("Cost Center Filter")));
            end;
        }
        field(33; "Cost Object Filter"; Text[250])
        {
            Caption = 'Cost Object Filter';
            TableRelation = "Cost Object";
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                CostObject: Record "Cost Object";
                SelectionFilter: Text[1024];
            begin
                if CostObject.LookupCostObjectFilter(SelectionFilter) then
                    Validate("Cost Object Filter", CopyStr(SelectionFilter, 1, MaxStrLen("Cost Object Filter")));
            end;
        }
        field(34; "Date Filter Code"; Enum "Cost Allocation Target Period")
        {
            Caption = 'Date Filter Code';
        }
        field(35; "Group Filter"; Text[250])
        {
            Caption = 'Group Filter';

            trigger OnLookup()
            var
                SelectionFilter: Text[1024];
            begin
                if LookupGroupFilter(SelectionFilter) then
                    Validate("Group Filter", CopyStr(SelectionFilter, 1, MaxStrLen("Group Filter")));
            end;
        }
        field(38; "Allocation Target Type"; Enum "Cost Allocation Target Type")
        {
            Caption = 'Allocation Target Type';

            trigger OnValidate()
            begin
                if "Allocation Target Type" <> xRec."Allocation Target Type" then begin
                    "Percent per Share" := 0;
                    "Amount per Share" := 0;
                end;
            end;
        }
        field(40; "Percent per Share"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Percent per Share';
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Percent per Share" <> 0 then begin
                    "Allocation Target Type" := "Allocation Target Type"::"Percent per Share";
                    "Amount per Share" := 0;
                end else
                    "Allocation Target Type" := "Allocation Target Type"::"All Costs";
            end;
        }
        field(41; "Amount per Share"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            BlankZero = true;
            Caption = 'Amount per Share';
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Amount per Share" <> 0 then begin
                    "Allocation Target Type" := "Allocation Target Type"::"Amount per Share";
                    "Percent per Share" := 0;
                end else
                    "Allocation Target Type" := "Allocation Target Type"::"All Costs";
            end;
        }
        field(50; "Share Updated on"; Date)
        {
            Caption = 'Share Updated on';
            Editable = false;
        }
        field(60; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(61; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
    }

    keys
    {
        key(Key1; ID, "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Target Cost Type")
        {
        }
        key(Key3; "Target Cost Center")
        {
        }
        key(Key4; "Target Cost Object")
        {
        }
        key(Key5; ID, "Allocation Target Type")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        // Default value according to previous line
        "Allocation Target Type" := xRec."Allocation Target Type";
        if xRec."Target Cost Type" <> '' then
            "Target Cost Type" := xRec."Target Cost Type";

        Base := xRec.Base;
        "Last Date Modified" := Today;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'You cannot define both cost center and cost object.';
#pragma warning disable AA0470
        Text001: Label '%1 can only be used with static allocations.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure CalcPercent()
    var
        CostAllocationTarget: Record "Cost Allocation Target";
        PctTotal: Decimal;
        TotalShare: Decimal;
        IsHandled: Boolean;
    begin
        CostAllocationTarget.SetRange(ID, Rec.ID);
        CostAllocationTarget.SetFilter("Line No.", '<>%1', Rec."Line No.");
        OnCalcPercentOnAfterSetFilters(CostAllocationTarget, Rec);
        CostAllocationTarget.CalcSums(Share);
        TotalShare := CostAllocationTarget.Share + Rec.Share;

        if TotalShare = 0 then begin
            CostAllocationTarget.ModifyAll(Percent, 0);
            CostAllocationTarget.ModifyAll("Share Updated on", Today);
            Rec.Percent := 0;
            Rec."Share Updated on" := Today;
            exit;
        end;

        if CostAllocationTarget.FindSet() then
            repeat
                CostAllocationTarget.Percent := Round(100 * CostAllocationTarget.Share / TotalShare, 0.00001);
                CostAllocationTarget."Share Updated on" := Today;
                CostAllocationTarget.Modify();
            until CostAllocationTarget.Next() = 0;
        Rec.Percent := Round(100 * Rec.Share / TotalShare, 0.00001);
        Rec."Share Updated on" := Today;
        Rec.Modify();

        // distribute rounding error:
        CostAllocationTarget.CalcSums(Percent);
        PctTotal := CostAllocationTarget.Percent + Rec.Percent;
        IsHandled := false;
        OnCalcPercentOnBeforeDistributeRoundingError(Rec, PctTotal, IsHandled);
        if not IsHandled then
            if PctTotal <> 100 then
                if (Rec."Line No." <> 0) and CostAllocationTarget.FindLast() and (CostAllocationTarget."Line No." > Rec."Line No.") then begin
                    CostAllocationTarget.Percent := CostAllocationTarget.Percent + (100 - PctTotal);
                    CostAllocationTarget.Modify();
                end else
                    Rec.Percent := Rec.Percent + (100 - PctTotal);
    end;

    local procedure LookupNoFilter(var SelectionFilter: Text): Boolean
    var
        CostType: Record "Cost Type";
    begin
        case Base of
            Base::"G/L Entries",
          Base::"G/L Budget Entries":
                exit(CostType.LookupGLAccFilter(SelectionFilter));
            Base::"Cost Type Entries",
          Base::"Cost Budget Entries":
                exit(CostType.LookupCostTypeFilter(SelectionFilter));
            Base::"Items Sold (Qty.)",
          Base::"Items Purchased (Qty.)",
          Base::"Items Sold (Amount)",
          Base::"Items Purchased (Amount)":
                exit(LookupItemFilter(SelectionFilter));
        end;
    end;

    local procedure LookupItemFilter(var SelectionFilter: Text): Boolean
    var
        ItemList: Page "Item List";
    begin
        ItemList.LookupMode(true);
        if ItemList.RunModal() = ACTION::LookupOK then begin
            SelectionFilter := ItemList.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    local procedure LookupGroupFilter(var SelectionFilter: Text): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookupGroupFilter(Base.AsInteger(), SelectionFilter, IsHandled);
        if IsHandled then
            exit;

        case Base of
            Base::"G/L Budget Entries":
                exit(LookupGLBudgetFilter(SelectionFilter));
            Base::"Cost Budget Entries":
                exit(LookupCostBudgetFilter(SelectionFilter));
            Base::"Items Sold (Qty.)",
          Base::"Items Purchased (Qty.)",
          Base::"Items Sold (Amount)",
          Base::"Items Purchased (Amount)":
                exit(LookupInvtPostingGrFilter(SelectionFilter));
        end;
    end;

    local procedure LookupGLBudgetFilter(var SelectionFilter: Text): Boolean
    var
        GLBudgetNames: Page "G/L Budget Names";
    begin
        GLBudgetNames.LookupMode(true);
        if GLBudgetNames.RunModal() = ACTION::LookupOK then begin
            SelectionFilter := GLBudgetNames.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    local procedure LookupCostBudgetFilter(var SelectionFilter: Text): Boolean
    var
        CostBudgetNames: Page "Cost Budget Names";
    begin
        CostBudgetNames.LookupMode(true);
        if CostBudgetNames.RunModal() = ACTION::LookupOK then begin
            SelectionFilter := CostBudgetNames.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    local procedure LookupInvtPostingGrFilter(var SelectionFilter: Text): Boolean
    var
        InvtPostingGroups: Page "Inventory Posting Groups";
    begin
        InvtPostingGroups.LookupMode(true);
        if InvtPostingGroups.RunModal() = ACTION::LookupOK then begin
            SelectionFilter := InvtPostingGroups.GetSelectionFilter();
            exit(true);
        end;
        exit(false)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupGroupFilter(SourceBase: Integer; var SelectionFilter: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPercentOnBeforeDistributeRoundingError(var CostAllocationTarget: Record "Cost Allocation Target"; PctTotal: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcPercentOnAfterSetFilters(var CostAllocationTarget: Record "Cost Allocation Target"; var Rec: Record "Cost Allocation Target")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateTargetCostCenter(var CostAllocationTarget: Record "Cost Allocation Target"; var IsHandled: Boolean)
    begin
    end;
}
