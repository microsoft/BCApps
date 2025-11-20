// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Tracking;

using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Tracking;

table 6026 "Exp. Invt. Order Tracking"
{
    Caption = 'Exp. Invt. Order Tracking';
    DrillDownPageID = "Exp. Invt. Order Tracking";
    LookupPageID = "Exp. Invt. Order Tracking";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Order No"; Code[20])
        {
            Caption = 'Order No';
            DataClassification = SystemMetadata;
            TableRelation = "Phys. Invt. Order Header";
        }
        field(2; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            DataClassification = SystemMetadata;
            TableRelation = "Phys. Invt. Order Line"."Line No." where("Document No." = field("Order No"));
        }
        field(3; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            DataClassification = SystemMetadata;
        }
        field(6; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
            DataClassification = SystemMetadata;
        }
        field(30; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Order No", "Order Line No.", "Serial No.", "Lot No.", "Package No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InsertLine(DocumentNo: Code[20]; LineNo: Integer; ItemTrackingSetup: Record "Item Tracking Setup"; Quantity: Decimal)
    begin
        Init();
        "Order No" := DocumentNo;
        "Order Line No." := LineNo;
        "Serial No." := ItemTrackingSetup."Serial No.";
        "Lot No." := ItemTrackingSetup."Lot No.";
        "Package No." := ItemTrackingSetup."Package No.";
        "Quantity (Base)" := Quantity;
        Insert();
    end;

    procedure DeleteLine(DocumentNo: Code[20]; LineNo: Integer; RemoveAll: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteLine(Rec, DocumentNo, LineNo, RemoveAll, IsHandled);
        if IsHandled then
            exit;

        SetRange("Order No", DocumentNo);
        SetRange("Order Line No.", LineNo);
        if not RemoveAll then
            SetRange("Quantity (Base)", 0);
        DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteLine(var ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking"; DocumentNo: Code[20]; LineNo: Integer; var RemoveAll: Boolean; var IsHandled: Boolean)
    begin
    end;
}

