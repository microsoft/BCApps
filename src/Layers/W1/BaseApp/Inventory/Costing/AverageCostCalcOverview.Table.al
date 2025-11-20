// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;

table 5847 "Average Cost Calc. Overview"
{
    Caption = 'Average Cost Calc. Overview';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Closing Entry,Increase,Applied Increase,Applied Decrease,Decrease,Revaluation';
            OptionMembers = "Closing Entry",Increase,"Applied Increase","Applied Decrease",Decrease,Revaluation;
        }
        field(3; "Valuation Date"; Date)
        {
            Caption = 'Valuation Date';
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(5; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(6; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(7; "Cost is Adjusted"; Boolean)
        {
            Caption = 'Cost is Adjusted';
        }
        field(11; "Attached to Entry No."; Integer)
        {
            Caption = 'Attached to Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(12; "Attached to Valuation Date"; Date)
        {
            Caption = 'Attached to Valuation Date';
        }
        field(13; Level; Integer)
        {
            Caption = 'Level';
        }
        field(21; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(22; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(23; "Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(24; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = ' ,Sales Shipment,Sales Invoice,Sales Return Receipt,Sales Credit Memo,Purchase Receipt,Purchase Invoice,Purchase Return Shipment,Purchase Credit Memo,Transfer Shipment,Transfer Receipt,Service Shipment,Service Invoice,Service Credit Memo';
            OptionMembers = " ","Sales Shipment","Sales Invoice","Sales Return Receipt","Sales Credit Memo","Purchase Receipt","Purchase Invoice","Purchase Return Shipment","Purchase Credit Memo","Transfer Shipment","Transfer Receipt","Service Shipment","Service Invoice","Service Credit Memo";
        }
        field(25; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(26; "Document Line No."; Integer)
        {
            Caption = 'Document Line No.';
        }
        field(27; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(31; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(32; "Applied Quantity"; Integer)
        {
            Caption = 'Applied Quantity';
        }
        field(33; "Cost Amount (Expected)"; Decimal)
        {
            Caption = 'Cost Amount (Expected)';
        }
        field(34; "Cost Amount (Actual)"; Decimal)
        {
            Caption = 'Cost Amount (Actual)';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Attached to Valuation Date", "Attached to Entry No.", Type)
        {
        }
        key(Key3; "Item Ledger Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        ValueEntry: Record "Value Entry";

    procedure CalculateAverageCost() AverageCost: Decimal
    begin
        AverageCost := 0;
        if Type = Type::"Closing Entry" then begin
            SetItemFilters();
            ValueEntry.SumCostsTillValuationDate(ValueEntry);
            if ValueEntry."Item Ledger Entry Quantity" = 0 then
                exit(AverageCost);
            AverageCost :=
              (ValueEntry."Cost Amount (Actual)" + ValueEntry."Cost Amount (Expected)") /
              ValueEntry."Item Ledger Entry Quantity";
            exit(Round(AverageCost));
        end;
        if Quantity = 0 then
            exit(AverageCost);
        AverageCost := ("Cost Amount (Actual)" + "Cost Amount (Expected)") / Quantity;
        exit(Round(AverageCost));
    end;

    procedure CalculateRemainingQty(): Decimal
    begin
        if Type <> Type::"Closing Entry" then
            exit(0);
        SetItemFilters();
        ValueEntry.SumCostsTillValuationDate(ValueEntry);
        exit(ValueEntry."Item Ledger Entry Quantity");
    end;

    procedure CalculateCostAmt(Actual: Boolean): Decimal
    begin
        if Type <> Type::"Closing Entry" then
            exit(0);
        SetItemFilters();
        ValueEntry.SumCostsTillValuationDate(ValueEntry);
        if Actual then
            exit(ValueEntry."Cost Amount (Actual)");
        exit(ValueEntry."Cost Amount (Expected)");
    end;

    procedure SetItemFilters()
    begin
        ValueEntry."Item No." := "Item No.";
        ValueEntry."Valuation Date" := "Valuation Date";
        ValueEntry."Location Code" := "Location Code";
        ValueEntry."Variant Code" := "Variant Code";

        OnAfterSetItemFilters(ValueEntry, Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemFilters(var ValueEntry: Record "Value Entry"; AverageCostCalcOverview: Record "Average Cost Calc. Overview")
    begin
    end;
}

