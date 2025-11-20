// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 7156 "Item Analysis View Budg. Entry"
{
    Caption = 'Item Analysis View Budg. Entry';
    DrillDownPageID = "Item Analy. View Budg. Entries";
    LookupPageID = "Item Analy. View Budg. Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Analysis Area"; Enum "Analysis Area Type")
        {
            Caption = 'Analysis Area';
        }
        field(2; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            NotBlank = true;
            TableRelation = "Item Analysis View".Code where("Analysis Area" = field("Analysis Area"),
                                                             Code = field("Analysis View Code"));
        }
        field(3; "Budget Name"; Code[10])
        {
            Caption = 'Budget Name';
            TableRelation = "Item Budget Name".Name where("Analysis Area" = field("Analysis Area"));
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(5; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) Item;
        }
        field(8; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(9; "Dimension 1 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Value Code';
        }
        field(10; "Dimension 2 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Value Code';
        }
        field(11; "Dimension 3 Value Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Value Code';
        }
        field(12; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(13; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(21; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(22; "Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Sales Amount';
        }
        field(23; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
        }
    }

    keys
    {
        key(Key1; "Analysis Area", "Analysis View Code", "Budget Name", "Item No.", "Source Type", "Source No.", "Dimension 1 Value Code", "Dimension 2 Value Code", "Dimension 3 Value Code", "Location Code", "Posting Date", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetCaptionClass(AnalysisViewDimType: Integer): Text[250]
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
    begin
        ItemAnalysisViewEntry.Init();
        ItemAnalysisViewEntry."Analysis Area" := "Analysis Area";
        ItemAnalysisViewEntry."Analysis View Code" := "Analysis View Code";
        exit(ItemAnalysisViewEntry.GetCaptionClass(AnalysisViewDimType));
    end;
}

