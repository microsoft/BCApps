// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Ledger;

using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;

table 6509 "Whse. Item Entry Relation"
{
    Caption = 'Whse. Item Entry Relation';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item Entry No."; Integer)
        {
            Caption = 'Item Entry No.';
            TableRelation = "Item Ledger Entry";
        }
        field(10; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(11; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(12; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(13; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(14; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(15; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(20; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(21; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(30; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(31; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
        }
    }

    keys
    {
        key(Key1; "Item Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Source ID", "Source Type", "Source Subtype", "Source Ref. No.", "Source Prod. Order Line", "Source Batch Name")
        {
        }
        key(Key3; "Order No.", "Order Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    procedure InitFromTrackingSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        Init();
        "Item Entry No." := TrackingSpecification."Entry No.";
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";

        OnAfterInitFromTrackingSpec(Rec, TrackingSpecification);
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubtype;
        "Source ID" := SourceID;
        "Source Ref. No." := SourceRefNo;
    end;

    procedure SetSource(SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        "Source Batch Name" := SourceBatchName;
        "Source Prod. Order Line" := SourceProdOrderLine;
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
        if SourceKey then
            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Ref. No.", "Source Prod. Order Line", "Source Batch Name");
        SetRange("Source Type", SourceType);
        if SourceSubtype >= 0 then
            SetRange("Source Subtype", SourceSubtype);
        SetRange("Source ID", SourceID);
        if SourceRefNo >= 0 then
            SetRange("Source Ref. No.", SourceRefNo);

        OnAfterSetSourceFilter(Rec, SourceType, SourceSubtype, SourceID, SourceRefNo, SourceKey);
    end;

    procedure SetSourceFilter(SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        SetRange("Source Batch Name", SourceBatchName);
        SetRange("Source Prod. Order Line", SourceProdOrderLine);
    end;

    procedure SetOrderInfo(OrderNo: Code[20]; OrderLineNo: Integer)
    begin
        "Order No." := OrderNo;
        "Order Line No." := OrderLineNo;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromTrackingSpec(var WhseItemEntryRelation: Record "Whse. Item Entry Relation"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilter(var WhseItemEntryRelation: Record "Whse. Item Entry Relation"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
    end;
}

