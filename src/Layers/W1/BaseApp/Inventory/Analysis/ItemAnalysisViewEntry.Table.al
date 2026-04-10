// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;

table 7154 "Item Analysis View Entry"
{
    Caption = 'Item Analysis View Entry';
    DrillDownPageID = "Item Analysis View Entries";
    LookupPageID = "Item Analysis View Entries";
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
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item number to which the item ledger entry in an analysis view entry was posted.';
            TableRelation = Item;
        }
        field(4; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
        }
        field(5; "Source No."; Code[20])
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
            ToolTip = 'Specifies the code of the location to which the item ledger entry in an analysis view entry was posted.';
            TableRelation = Location;
        }
        field(9; "Dimension 1 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Value Code';
            ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 1 on the analysis view card.';
        }
        field(10; "Dimension 2 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Value Code';
            ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 2 on the analysis view card.';
        }
        field(11; "Dimension 3 Value Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Value Code';
            ToolTip = 'Specifies the dimension value you selected for the analysis view dimension that you defined as Dimension 3 on the analysis view card.';
        }
        field(12; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the date when the item ledger entry in an analysis view entry was posted.';
        }
        field(13; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(14; "Item Ledger Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Item Ledger Entry Type';
            ToolTip = 'Specifies which type of transaction that the entry is created from.';
        }
        field(15; "Entry Type"; Enum "Cost Entry Type")
        {
            Caption = 'Entry Type';
            ToolTip = 'Specifies the value entry type for an analysis view entry.';
        }
        field(21; "Invoiced Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Invoiced Quantity';
            ToolTip = 'Specifies the sum of the quantity invoiced for the item ledger entries included in the analysis view entry.';
        }
        field(22; "Sales Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Sales Amount (Actual)';
        }
        field(23; "Cost Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Cost Amount (Actual)';
        }
        field(24; "Cost Amount (Non-Invtbl.)"; Decimal)
        {
            AccessByPermission = TableData "Item Charge" = R;
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Cost Amount (Non-Invtbl.)';
        }
        field(31; Quantity; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Quantity';
            ToolTip = 'Specifies the sum of the quantity for the item ledger entries included in the analysis view entry.';
        }
        field(32; "Sales Amount (Expected)"; Decimal)
        {
            AccessByPermission = TableData "Sales Shipment Header" = R;
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Sales Amount (Expected)';
        }
        field(33; "Cost Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Cost Amount (Expected)';
        }
    }

    keys
    {
        key(Key1; "Analysis Area", "Analysis View Code", "Item No.", "Item Ledger Entry Type", "Entry Type", "Source Type", "Source No.", "Dimension 1 Value Code", "Dimension 2 Value Code", "Dimension 3 Value Code", "Location Code", "Posting Date", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        ItemAnalysisView: Record "Item Analysis View";

#pragma warning disable AA0074
        Text000: Label '1,5,,Dimension 1 Value Code';
        Text001: Label '1,5,,Dimension 2 Value Code';
        Text002: Label '1,5,,Dimension 3 Value Code';
#pragma warning restore AA0074

    procedure GetCaptionClass(AnalysisViewDimType: Integer): Text[250]
    begin
        if (ItemAnalysisView."Analysis Area" <> "Analysis Area") or
           (ItemAnalysisView.Code <> "Analysis View Code")
        then
            ItemAnalysisView.Get("Analysis Area", "Analysis View Code");
        case AnalysisViewDimType of
            1:
                begin
                    if ItemAnalysisView."Dimension 1 Code" <> '' then
                        exit('1,5,' + ItemAnalysisView."Dimension 1 Code");
                    exit(Text000);
                end;
            2:
                begin
                    if ItemAnalysisView."Dimension 2 Code" <> '' then
                        exit('1,5,' + ItemAnalysisView."Dimension 2 Code");
                    exit(Text001);
                end;
            3:
                begin
                    if ItemAnalysisView."Dimension 3 Code" <> '' then
                        exit('1,5,' + ItemAnalysisView."Dimension 3 Code");
                    exit(Text002);
                end;
        end;
    end;
}

