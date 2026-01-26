// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
#if not CLEAN27
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
#endif

tableextension 99000801 "Mfg. Capacity Ledger Entry" extends "Capacity Ledger Entry"
{
    fields
    {
        modify("No.")
        {
            TableRelation = if (Type = const("Machine Center")) "Machine Center"
            else
            if (Type = const("Work Center")) "Work Center";
        }
        field(8; "Operation No."; Code[10])
        {
            Caption = 'Operation No.';
            DataClassification = CustomerContent;
        }
        field(9; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            DataClassification = CustomerContent;
            TableRelation = "Work Center";
        }
        field(11; "Setup Time"; Decimal)
        {
            Caption = 'Setup Time';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(12; "Run Time"; Decimal)
        {
            Caption = 'Run Time';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(13; "Stop Time"; Decimal)
        {
            Caption = 'Stop Time';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(16; "Output Quantity"; Decimal)
        {
            Caption = 'Output Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(17; "Scrap Quantity"; Decimal)
        {
            Caption = 'Scrap Quantity';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
        }
        field(19; "Concurrent Capacity"; Decimal)
        {
            Caption = 'Concurrent Capacity';
            DataClassification = CustomerContent;
        }
        field(39; "Last Output Line"; Boolean)
        {
            Caption = 'Last Output Line';
            DataClassification = CustomerContent;
        }
        field(43; "Starting Time"; Time)
        {
            Caption = 'Starting Time';
            DataClassification = CustomerContent;
        }
        field(44; "Ending Time"; Time)
        {
            Caption = 'Ending Time';
            DataClassification = CustomerContent;
        }
        field(52; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = CustomerContent;
            TableRelation = "Routing Header";
        }
        field(53; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            DataClassification = CustomerContent;
        }
        field(65; "Stop Code"; Code[10])
        {
            Caption = 'Stop Code';
            DataClassification = CustomerContent;
            TableRelation = Stop;
        }
        field(66; "Scrap Code"; Code[10])
        {
            Caption = 'Scrap Code';
            DataClassification = CustomerContent;
            TableRelation = Scrap;
        }
        field(68; "Work Center Group Code"; Code[10])
        {
            Caption = 'Work Center Group Code';
            DataClassification = CustomerContent;
            TableRelation = "Work Center Group";
        }
        field(69; "Work Shift Code"; Code[10])
        {
            Caption = 'Work Shift Code';
            DataClassification = CustomerContent;
            TableRelation = "Work Shift";
        }
        modify("Order No.")
        {
            TableRelation = if ("Order Type" = const(Production)) "Production Order"."No." where(Status = filter(Released ..));
        }
        modify("Order Line No.")
        {
            TableRelation = if ("Order Type" = const(Production)) "Prod. Order Line"."Line No." where(Status = filter(Released ..),
                                                                                                     "Prod. Order No." = field("Order No."));
        }
#if not CLEANSCHEMA30
        field(12180; "WIP Item Qty."; Decimal)
        {
            Caption = 'WIP Item Qty.';
            DataClassification = CustomerContent;
            DecimalPlaces = 0 : 5;
            ObsoleteReason = 'Preparation for replacement by Subcontracting app';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
#endif
        field(12181; "Shipping Document No."; Code[20])
        {
            Caption = 'Shipping Document No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
#if not CLEANSCHEMA30
        field(12182; "Subcontractor No."; Code[20])
        {
            Caption = 'Subcontractor No.';
            DataClassification = CustomerContent;
#if not CLEAN27
            TableRelation = Vendor;
#endif
            ObsoleteReason = 'Preparation for replacement by Subcontracting app';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
        field(12183; "Subcontr. Purch. Order No."; Code[20])
        {
            Caption = 'Subcontr. Purch. Order No.';
            DataClassification = CustomerContent;
#if not CLEAN27
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));
#endif
            ObsoleteReason = 'Preparation for replacement by Subcontracting app';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
        field(12184; "Subcontr. Purch. Order Line"; Integer)
        {
            Caption = 'Subcontr. Purch. Order Line';
            DataClassification = CustomerContent;
#if not CLEAN27
            TableRelation = "Purchase Line"."Line No." where("Document Type" = const(Order),
                                                              "Document No." = field("Subcontr. Purch. Order No."));
#endif
            ObsoleteReason = 'Preparation for replacement by Subcontracting app';
#if not CLEAN27
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#endif
        }
#endif
    }

    keys
    {
        key(Key4; "Work Center No.", "Work Shift Code")
        {
        }
#if not CLEAN27
        key(Key12180; "Subcontr. Purch. Order No.", "Subcontr. Purch. Order Line")
        {
            SumIndexFields = "WIP Item Qty.";
        }
        key(Key12182; "Item No.", "Order Type", "Order No.", "Posting Date", Subcontracting)
        {
        }
#endif
    }

    procedure SetFilterByProdOrderRoutingLine(ProdOrderNo: Code[20]; ProdOrderLineNo: Integer; ProdOrderRoutingNo: Code[20]; ProdOrderRoutingLineNo: Integer)
    begin
        SetRange("Order Type", "Order Type"::Production);
        SetRange("Order No.", ProdOrderNo);
        SetRange("Order Line No.", ProdOrderLineNo);
        SetRange("Routing No.", ProdOrderRoutingNo);
        SetRange("Routing Reference No.", ProdOrderRoutingLineNo);
    end;
}