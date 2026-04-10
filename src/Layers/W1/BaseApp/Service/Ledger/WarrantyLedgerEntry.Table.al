// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Maintenance;
using Microsoft.Service.Pricing;
using Microsoft.Utilities;

table 5908 "Warranty Ledger Entry"
{
    Caption = 'Warranty Ledger Entry';
    DrillDownPageID = "Warranty Ledger Entries";
    LookupPageID = "Warranty Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number of this entry.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date on the service line linked to this entry.';
        }
        field(5; "Customer No."; Code[20])
        {
            Caption = 'Customer No.';
            ToolTip = 'Specifies the number of the customer on the service order linked to this entry.';
            TableRelation = Customer;
        }
        field(6; "Ship-to Code"; Code[10])
        {
            Caption = 'Ship-to Code';
            ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(7; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
            ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
            TableRelation = Customer;
        }
        field(8; "Variant Code (Serviced)"; Code[10])
        {
            Caption = 'Variant Code (Serviced)';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No. (Serviced)"));
        }
        field(9; "Service Item No. (Serviced)"; Code[20])
        {
            Caption = 'Service Item No. (Serviced)';
            TableRelation = "Service Item";
        }
        field(10; "Item No. (Serviced)"; Code[20])
        {
            Caption = 'Item No. (Serviced)';
            TableRelation = Item."No.";
        }
        field(11; "Serial No. (Serviced)"; Code[50])
        {
            Caption = 'Serial No. (Serviced)';
        }
        field(12; "Service Item Group (Serviced)"; Code[10])
        {
            Caption = 'Service Item Group (Serviced)';
            TableRelation = "Service Item Group";
        }
        field(13; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
            ToolTip = 'Specifies the number of the service order linked to this entry.';

            trigger OnLookup()
            begin
                Clear(ServOrderMgt);
                ServOrderMgt.ServHeaderLookup(1, "Service Order No.");
            end;
        }
        field(14; "Service Contract No."; Code[20])
        {
            Caption = 'Service Contract No.';
            ToolTip = 'Specifies the number of the service contract linked to this entry.';
            TableRelation = "Service Contract Header"."Contract No." where("Contract Type" = const(Contract));
        }
        field(15; "Fault Reason Code"; Code[10])
        {
            Caption = 'Fault Reason Code';
            ToolTip = 'Specifies the fault reason code of the service line linked to this entry.';
            TableRelation = "Fault Reason Code";
        }
        field(16; "Fault Area Code"; Code[10])
        {
            Caption = 'Fault Area Code';
            TableRelation = "Fault Area";
        }
        field(17; "Fault Code"; Code[10])
        {
            Caption = 'Fault Code';
            ToolTip = 'Specifies the fault code of the service line linked to this entry.';
            TableRelation = "Fault Code".Code where("Fault Area Code" = field("Fault Area Code"),
                                                     "Symptom Code" = field("Symptom Code"));
        }
        field(18; "Symptom Code"; Code[10])
        {
            Caption = 'Symptom Code';
            ToolTip = 'Specifies the symptom code of the service line linked to this entry.';
            TableRelation = "Symptom Code";
        }
        field(19; "Resolution Code"; Code[10])
        {
            Caption = 'Resolution Code';
            ToolTip = 'Specifies the resolution code of the service line linked to this entry.';
            TableRelation = "Resolution Code";
        }
#pragma warning disable AS0070 // TODO(#359458)
        field(20; Type; Enum "Service Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of the service line linked to this entry.';
        }
#pragma warning restore AS0070
        field(21; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            TableRelation = if (Type = const(" ")) "Standard Text"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource
            else
            if (Type = const("Cost")) "Service Cost";
        }
        field(22; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the number of item units, resource hours, or cost of the service line linked to this entry.';
            DecimalPlaces = 0 : 5;
        }
        field(24; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            ToolTip = 'Specifies the work type code of the service line linked to this entry.';
            TableRelation = "Work Type";
        }
        field(25; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            "Unit of Measure";
        }
        field(26; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
            ToolTip = 'Specifies the warranty discount amount of the service line linked to this entry.';
        }
        field(27; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the item on this line.';
        }
        field(29; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(30; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(31; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Global Dimension 1 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(32; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Global Dimension 2 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(33; Open; Boolean)
        {
            Caption = 'Open';
            ToolTip = 'Specifies that the warranty ledger entry is open.';
        }
        field(35; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            ToolTip = 'Specifies the vendor number of the serviced item linked to this entry.';
            TableRelation = Vendor."No.";
        }
        field(36; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
            ToolTip = 'Specifies the number that the vendor uses for this item.';
        }
        field(38; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."));
        }
        field(39; "Service Order Line No."; Integer)
        {
            Caption = 'Service Order Line No.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Service Item No. (Serviced)", "Posting Date", "Document No.")
        {
        }
        key(Key3; "Service Order No.", "Posting Date", "Document No.")
        {
        }
        key(Key4; "Service Contract No.", "Posting Date", "Document No.")
        {
        }
        key(Key5; "Document No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Type, "Document No.", "Posting Date")
        {
        }
    }

    var
        ServOrderMgt: Codeunit ServOrderManagement;
        DimMgt: Codeunit DimensionManagement;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;
}

