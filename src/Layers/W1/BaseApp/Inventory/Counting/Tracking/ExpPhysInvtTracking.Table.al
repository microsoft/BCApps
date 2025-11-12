#if not CLEANSCHEMA27 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Tracking;

using Microsoft.Inventory.Counting.Document;

table 5886 "Exp. Phys. Invt. Tracking"
{
    Caption = 'Exp. Phys. Invt. Tracking';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Replaced by table Exp.Invt.Order.Tracking.';
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
    ReplicateData = false;

    fields
    {
        field(1; "Order No"; Code[20])
        {
            Caption = 'Order No';
            TableRelation = "Phys. Invt. Order Header";
        }
        field(2; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            TableRelation = "Phys. Invt. Order Line"."Line No." where("Document No." = field("Order No"));
        }
        field(3; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(4; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(30; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Order No", "Order Line No.", "Serial No.", "Lot No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure InsertLine(DocumentNo: Code[20]; LineNo: Integer; SerialNo: Code[50]; LotNo: Code[50]; Quantity: Decimal)
    begin
        Init();
        "Order No" := DocumentNo;
        "Order Line No." := LineNo;
        "Serial No." := SerialNo;
        "Lot No." := LotNo;
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
    local procedure OnBeforeDeleteLine(var ExpPhysInvtTracking: Record "Exp. Phys. Invt. Tracking"; DocumentNo: Code[20]; LineNo: Integer; var RemoveAll: Boolean; var IsHandled: Boolean)
    begin
    end;
}

 
#endif
