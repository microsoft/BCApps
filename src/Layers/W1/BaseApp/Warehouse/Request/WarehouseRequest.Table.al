// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity;

table 5765 "Warehouse Request"
{
    Caption = 'Warehouse Request';
    LookupPageID = "Source Documents";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(2; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(3; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            ToolTip = 'Specifies the number of the source document that the entry originates from.';
            Editable = false;
            TableRelation = if ("Source Document" = const("Sales Order")) "Sales Header"."No." where("Document Type" = const(Order),
                                                                                                     "No." = field("Source No."))
            else
            if ("Source Document" = const("Sales Return Order")) "Sales Header"."No." where("Document Type" = const("Return Order"),
                                                                                            "No." = field("Source No."))
            else
            if ("Source Document" = const("Purchase Order")) "Purchase Header"."No." where("Document Type" = const(Order),
                                                                                           "No." = field("Source No."))
            else
            if ("Source Document" = const("Purchase Return Order")) "Purchase Header"."No." where("Document Type" = const("Return Order"),
                                                                                                  "No." = field("Source No."))
            else
            if ("Source Type" = const(5741)) "Transfer Header"."No." where("No." = field("Source No."))
            else
            if ("Source Type" = const(167)) "Job"."No." where("No." = field("Source No."));
        }
        field(4; "Source Document"; Enum "Warehouse Request Source Document")
        {
            Caption = 'Source Document';
            ToolTip = 'Specifies the type of document that the line relates to.';
            Editable = false;
        }
        field(5; "Document Status"; Option)
        {
            Caption = 'Document Status';
            Editable = false;
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
        field(6; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location code to which the request line is linked.';
            Editable = false;
            TableRelation = Location;
        }
        field(7; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
            Editable = false;
            TableRelation = "Shipment Method";
        }
        field(8; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
            Editable = false;
            TableRelation = "Shipping Agent";
        }
        field(9; "Shipping Agent Service Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Service Code';
            Editable = false;
            TableRelation = "Shipping Agent Services";
        }
        field(10; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';
            ToolTip = 'Specifies the shipping advice, which informs whether partial deliveries are acceptable.';
            Editable = false;
        }
        field(11; "Destination Type"; enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
            ToolTip = 'Specifies whether the type of destination associated with the warehouse request is a customer or a vendor.';
        }
        field(12; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            ToolTip = 'Specifies the number or code of the customer or vendor related to the warehouse request.';
            TableRelation = if ("Destination Type" = const(Vendor)) Vendor
            else
            if ("Destination Type" = const(Customer)) Customer
            else
            if ("Destination Type" = const(Location)) Location
            else
            if ("Destination Type" = const(Item)) Item
            else
            if ("Destination Type" = const("Sales Order")) "Sales Header"."No." where("Document Type" = const(Order));
        }
        field(13; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
            ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
        }
        field(14; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
            ToolTip = 'Specifies the date when receipt of the items is expected.';
        }
        field(15; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
        }
        field(19; Type; Enum "Warehouse Request Type")
        {
            Caption = 'Type';
            Editable = false;
        }
        field(20; "Put-away / Pick No."; Code[20])
        {
            CalcFormula = lookup("Warehouse Activity Line"."No." where("Source Type" = field("Source Type"),
                                                                        "Source Subtype" = field("Source Subtype"),
                                                                        "Source No." = field("Source No."),
                                                                        "Location Code" = field("Location Code")));
            Caption = 'Put-away / Pick No.';
            ToolTip = 'Specifies the number of the inventory put-away or pick that was created from this warehouse request.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(41; "Completely Handled"; Boolean)
        {
            Caption = 'Completely Handled';
        }
    }

    keys
    {
        key(Key1; Type, "Location Code", "Source Type", "Source Subtype", "Source No.")
        {
            Clustered = true;
        }
        key(Key2; "Source Type", "Source Subtype", "Source No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key3; "Source Type", "Source No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key4; "Source Document", "Source No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; Type, "Location Code", "Completely Handled", "Document Status", "Expected Receipt Date", "Shipment Date", "Source Document", "Source No.")
        {
        }
        key(Key6; "Source No.", "Source Subtype", "Source Type", Type, "Document Status")
        {
        }
    }

    fieldgroups
    {
    }

    procedure DeleteRequest(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20])
    begin
        SetSourceFilter(SourceType, SourceSubtype, SourceNo);
        if not IsEmpty() then
            DeleteAll();

        OnAfterDeleteRequest(SourceType, SourceSubtype, SourceNo);
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20])
    begin
        SetRange("Source Type", SourceType);
        SetRange("Source Subtype", SourceSubtype);
        SetRange("Source No.", SourceNo);
    end;

    procedure ShowSourceDocumentCard()
    begin
        OnShowSourceDocumentCard(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRequest(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowSourceDocumentCard(var WarehouseRequest: Record "Warehouse Request")
    begin
    end;
}

