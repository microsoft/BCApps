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

table 5821 "Item Statistics Buffer"
{
    Caption = 'Item Statistics Buffer';
    DataCaptionFields = "Code";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
        }
        field(2; "Item Filter"; Code[20])
        {
            Caption = 'Item Filter';
            FieldClass = FlowFilter;
            TableRelation = Item;
            ValidateTableRelation = false;
        }
        field(3; "Variant Filter"; Code[10])
        {
            Caption = 'Variant Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Variant".Code;
        }
        field(4; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(5; "Budget Filter"; Code[10])
        {
            Caption = 'Budget Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Budget Name".Name where("Analysis Area" = field("Analysis Area Filter"));
        }
        field(6; "Global Dimension 1 Filter"; Code[20])
        {
            CaptionClass = '1,3,1';
            Caption = 'Global Dimension 1 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(7; "Global Dimension 2 Filter"; Code[20])
        {
            CaptionClass = '1,3,2';
            Caption = 'Global Dimension 2 Filter';
            FieldClass = FlowFilter;
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(9; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            ClosingDates = true;
            FieldClass = FlowFilter;
        }
        field(10; "Entry Type Filter"; Enum "Cost Entry Type")
        {
            Caption = 'Entry Type Filter';
            FieldClass = FlowFilter;
        }
        field(11; "Item Ledger Entry Type Filter"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Item Ledger Entry Type Filter';
            FieldClass = FlowFilter;
        }
        field(12; "Item Charge No. Filter"; Code[20])
        {
            Caption = 'Item Charge No. Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Charge";
        }
        field(13; "Source Type Filter"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type Filter';
            FieldClass = FlowFilter;
        }
        field(14; "Source No. Filter"; Code[20])
        {
            Caption = 'Source No. Filter';
            FieldClass = FlowFilter;
            TableRelation = if ("Source Type Filter" = const(Customer)) Customer
            else
            if ("Source Type Filter" = const(Vendor)) Vendor
            else
            if ("Source Type Filter" = const(Item)) Item;
            ValidateTableRelation = false;
        }
        field(15; "Invoiced Quantity"; Decimal)
        {
            CalcFormula = sum("Value Entry"."Invoiced Quantity" where("Item No." = field("Item Filter"),
                                                                       "Posting Date" = field("Date Filter"),
                                                                       "Variant Code" = field("Variant Filter"),
                                                                       "Location Code" = field("Location Filter"),
                                                                       "Entry Type" = field("Entry Type Filter"),
                                                                       "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                       "Variance Type" = field("Variance Type Filter"),
                                                                       "Item Charge No." = field("Item Charge No. Filter"),
                                                                       "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                       "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                       "Source Type" = field("Source Type Filter"),
                                                                       "Source No." = field("Source No. Filter")));
            Caption = 'Invoiced Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Sales Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Sales Amount (Actual)" where("Item No." = field("Item Filter"),
                                                                           "Posting Date" = field("Date Filter"),
                                                                           "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                           "Entry Type" = field("Entry Type Filter"),
                                                                           "Variance Type" = field("Variance Type Filter"),
                                                                           "Location Code" = field("Location Filter"),
                                                                           "Variant Code" = field("Variant Filter"),
                                                                           "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                           "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                           "Item Charge No." = field("Item Charge No. Filter"),
                                                                           "Source Type" = field("Source Type Filter"),
                                                                           "Source No." = field("Source No. Filter")));
            Caption = 'Sales Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Cost Amount (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Actual)" where("Item No." = field("Item Filter"),
                                                                          "Posting Date" = field("Date Filter"),
                                                                          "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                          "Entry Type" = field("Entry Type Filter"),
                                                                          "Variance Type" = field("Variance Type Filter"),
                                                                          "Location Code" = field("Location Filter"),
                                                                          "Variant Code" = field("Variant Filter"),
                                                                          "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                          "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                          "Item Charge No." = field("Item Charge No. Filter"),
                                                                          "Source Type" = field("Source Type Filter"),
                                                                          "Source No." = field("Source No. Filter")));
            Caption = 'Cost Amount (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(18; "Cost Amount (Non-Invtbl.)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Non-Invtbl.)" where("Item No." = field("Item Filter"),
                                                                               "Posting Date" = field("Date Filter"),
                                                                               "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                               "Variance Type" = field("Variance Type Filter"),
                                                                               "Entry Type" = field("Entry Type Filter"),
                                                                               "Location Code" = field("Location Filter"),
                                                                               "Variant Code" = field("Variant Filter"),
                                                                               "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                               "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                               "Item Charge No." = field("Item Charge No. Filter"),
                                                                               "Source Type" = field("Source Type Filter"),
                                                                               "Source No." = field("Source No. Filter")));
            Caption = 'Cost Amount (Non-Invtbl.)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(19; "Variance Type Filter"; Enum "Cost Variance Type")
        {
            Caption = 'Variance Type Filter';
            FieldClass = FlowFilter;
        }
        field(20; "Sales (LCY)"; Integer)
        {
            Caption = 'Sales (LCY)';
            DataClassification = SystemMetadata;
        }
        field(21; "COGS (LCY)"; Integer)
        {
            Caption = 'COGS (LCY)';
            DataClassification = SystemMetadata;
        }
        field(22; "Profit (LCY)"; Integer)
        {
            Caption = 'Profit (LCY)';
            DataClassification = SystemMetadata;
        }
        field(23; "Profit %"; Integer)
        {
            Caption = 'Profit %';
            DataClassification = SystemMetadata;
        }
        field(24; "Inventoriable Costs"; Integer)
        {
            Caption = 'Inventoriable Costs';
            DataClassification = SystemMetadata;
        }
        field(25; "Direct Cost (LCY)"; Integer)
        {
            Caption = 'Direct Cost (LCY)';
            DataClassification = SystemMetadata;
        }
        field(26; "Revaluation (LCY)"; Integer)
        {
            Caption = 'Revaluation (LCY)';
            DataClassification = SystemMetadata;
        }
        field(27; "Rounding (LCY)"; Integer)
        {
            Caption = 'Rounding (LCY)';
            DataClassification = SystemMetadata;
        }
        field(28; "Indirect Cost (LCY)"; Integer)
        {
            Caption = 'Indirect Cost (LCY)';
            DataClassification = SystemMetadata;
        }
        field(29; "Variance (LCY)"; Integer)
        {
            Caption = 'Variance (LCY)';
            DataClassification = SystemMetadata;
        }
        field(30; "Inventoriable Costs, Total"; Integer)
        {
            Caption = 'Inventoriable Costs, Total';
            DataClassification = SystemMetadata;
        }
        field(31; "Inventory (LCY)"; Integer)
        {
            Caption = 'Inventory (LCY)';
            DataClassification = SystemMetadata;
        }
        field(34; "Non-Invtbl. Costs (LCY)"; Integer)
        {
            Caption = 'Non-Invtbl. Costs (LCY)';
            DataClassification = SystemMetadata;
        }
        field(40; "Line Option"; Enum "Item Statistics Line Option")
        {
            Caption = 'Line Option';
            DataClassification = SystemMetadata;
        }
        field(41; "Column Option"; Enum "Item Statistics Column Option")
        {
            Caption = 'Column Option';
            DataClassification = SystemMetadata;
        }
#pragma warning disable AS0070
        field(42; "Analysis Area Filter"; Enum "Analysis Area Type")
        {
            Caption = 'Analysis Area Filter';
            FieldClass = FlowFilter;
        }
#pragma warning restore AS0070
        field(45; Quantity; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("Item Filter"),
                                                                  "Source Type" = field("Source Type Filter"),
                                                                  "Source No." = field("Source No. Filter"),
                                                                  "Posting Date" = field("Date Filter"),
                                                                  "Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                  "Location Code" = field("Location Filter"),
                                                                  "Variant Code" = field("Variant Filter"),
                                                                  "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                  "Global Dimension 2 Code" = field("Global Dimension 2 Filter")));
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(46; "Sales Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Sales Amount (Expected)" where("Item No." = field("Item Filter"),
                                                                             "Source Type" = field("Source Type Filter"),
                                                                             "Source No." = field("Source No. Filter"),
                                                                             "Posting Date" = field("Date Filter"),
                                                                             "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                             "Variance Type" = field("Variance Type Filter"),
                                                                             "Entry Type" = field("Entry Type Filter"),
                                                                             "Location Code" = field("Location Filter"),
                                                                             "Variant Code" = field("Variant Filter"),
                                                                             "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                             "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                             "Item Charge No." = field("Item Charge No. Filter")));
            Caption = 'Sales Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(47; "Cost Amount (Expected)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Expected)" where("Item No." = field("Item Filter"),
                                                                            "Source Type" = field("Source Type Filter"),
                                                                            "Source No." = field("Source No. Filter"),
                                                                            "Posting Date" = field("Date Filter"),
                                                                            "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                            "Variance Type" = field("Variance Type Filter"),
                                                                            "Entry Type" = field("Entry Type Filter"),
                                                                            "Location Code" = field("Location Filter"),
                                                                            "Variant Code" = field("Variant Filter"),
                                                                            "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                            "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                            "Item Charge No." = field("Item Charge No. Filter")));
            Caption = 'Cost Amount (Expected)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Budgeted Quantity"; Decimal)
        {
            CalcFormula = sum("Item Budget Entry".Quantity where("Analysis Area" = field("Analysis Area Filter"),
                                                                  "Budget Name" = field("Budget Filter"),
                                                                  "Item No." = field("Item Filter"),
                                                                  Date = field("Date Filter"),
                                                                  "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                  "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                  "Budget Dimension 1 Code" = field("Dimension 1 Filter"),
                                                                  "Budget Dimension 2 Code" = field("Dimension 2 Filter"),
                                                                  "Budget Dimension 3 Code" = field("Dimension 3 Filter"),
                                                                  "Source Type" = field("Source Type Filter"),
                                                                  "Source No." = field("Source No. Filter"),
                                                                  "Location Code" = field("Location Filter")));
            Caption = 'Budgeted Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(51; "Budgeted Sales Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Item Budget Entry"."Sales Amount" where("Analysis Area" = field("Analysis Area Filter"),
                                                                        "Budget Name" = field("Budget Filter"),
                                                                        "Item No." = field("Item Filter"),
                                                                        Date = field("Date Filter"),
                                                                        "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                        "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                        "Budget Dimension 1 Code" = field("Dimension 1 Filter"),
                                                                        "Budget Dimension 2 Code" = field("Dimension 2 Filter"),
                                                                        "Budget Dimension 3 Code" = field("Dimension 3 Filter"),
                                                                        "Source Type" = field("Source Type Filter"),
                                                                        "Source No." = field("Source No. Filter"),
                                                                        "Location Code" = field("Location Filter")));
            Caption = 'Budgeted Sales Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Budgeted Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Item Budget Entry"."Cost Amount" where("Analysis Area" = field("Analysis Area Filter"),
                                                                       "Budget Name" = field("Budget Filter"),
                                                                       "Item No." = field("Item Filter"),
                                                                       Date = field("Date Filter"),
                                                                       "Global Dimension 1 Code" = field("Global Dimension 1 Filter"),
                                                                       "Global Dimension 2 Code" = field("Global Dimension 2 Filter"),
                                                                       "Budget Dimension 1 Code" = field("Dimension 1 Filter"),
                                                                       "Budget Dimension 2 Code" = field("Dimension 2 Filter"),
                                                                       "Budget Dimension 3 Code" = field("Dimension 3 Filter"),
                                                                       "Source Type" = field("Source Type Filter"),
                                                                       "Source No." = field("Source No. Filter"),
                                                                       "Location Code" = field("Location Filter")));
            Caption = 'Budgeted Cost Amount';
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Analysis View Filter"; Code[10])
        {
            Caption = 'Analysis View Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Analysis View".Code where("Analysis Area" = field("Analysis Area Filter"));
        }
        field(71; "Dimension 1 Filter"; Code[20])
        {
            Caption = 'Dimension 1 Filter';
            FieldClass = FlowFilter;
        }
        field(72; "Dimension 2 Filter"; Code[20])
        {
            Caption = 'Dimension 2 Filter';
            FieldClass = FlowFilter;
        }
        field(73; "Dimension 3 Filter"; Code[20])
        {
            Caption = 'Dimension 3 Filter';
            FieldClass = FlowFilter;
        }
        field(80; "Analysis - Quantity"; Decimal)
        {
            CalcFormula = sum("Item Analysis View Entry".Quantity where("Analysis Area" = field("Analysis Area Filter"),
                                                                         "Analysis View Code" = field("Analysis View Filter"),
                                                                         "Item No." = field("Item Filter"),
                                                                         "Location Code" = field("Location Filter"),
                                                                         "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                         "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                         "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                         "Posting Date" = field("Date Filter"),
                                                                         "Source Type" = field("Source Type Filter"),
                                                                         "Source No." = field("Source No. Filter"),
                                                                         "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                         "Entry Type" = field("Entry Type Filter")));
            Caption = 'Analysis - Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(81; "Analysis - Invoiced Quantity"; Decimal)
        {
            CalcFormula = sum("Item Analysis View Entry"."Invoiced Quantity" where("Analysis Area" = field("Analysis Area Filter"),
                                                                                    "Analysis View Code" = field("Analysis View Filter"),
                                                                                    "Item No." = field("Item Filter"),
                                                                                    "Location Code" = field("Location Filter"),
                                                                                    "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                                    "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                                    "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                                    "Posting Date" = field("Date Filter"),
                                                                                    "Source Type" = field("Source Type Filter"),
                                                                                    "Source No." = field("Source No. Filter"),
                                                                                    "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                                    "Entry Type" = field("Entry Type Filter")));
            Caption = 'Analysis - Invoiced Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(82; "Analysis - Sales Amt. (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Item Analysis View Entry"."Sales Amount (Actual)" where("Analysis Area" = field("Analysis Area Filter"),
                                                                                        "Analysis View Code" = field("Analysis View Filter"),
                                                                                        "Item No." = field("Item Filter"),
                                                                                        "Location Code" = field("Location Filter"),
                                                                                        "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                                        "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                                        "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                                        "Posting Date" = field("Date Filter"),
                                                                                        "Source Type" = field("Source Type Filter"),
                                                                                        "Source No." = field("Source No. Filter"),
                                                                                        "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                                        "Entry Type" = field("Entry Type Filter")));
            Caption = 'Analysis - Sales Amt. (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(83; "Analysis - Sales Amt. (Exp)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Item Analysis View Entry"."Sales Amount (Expected)" where("Analysis Area" = field("Analysis Area Filter"),
                                                                                          "Analysis View Code" = field("Analysis View Filter"),
                                                                                          "Item No." = field("Item Filter"),
                                                                                          "Location Code" = field("Location Filter"),
                                                                                          "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                                          "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                                          "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                                          "Posting Date" = field("Date Filter"),
                                                                                          "Source Type" = field("Source Type Filter"),
                                                                                          "Source No." = field("Source No. Filter"),
                                                                                          "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                                          "Entry Type" = field("Entry Type Filter")));
            Caption = 'Analysis - Sales Amt. (Exp)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(84; "Analysis - Cost Amt. (Actual)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Item Analysis View Entry"."Cost Amount (Actual)" where("Analysis Area" = field("Analysis Area Filter"),
                                                                                       "Analysis View Code" = field("Analysis View Filter"),
                                                                                       "Item No." = field("Item Filter"),
                                                                                       "Location Code" = field("Location Filter"),
                                                                                       "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                                       "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                                       "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                                       "Posting Date" = field("Date Filter"),
                                                                                       "Source Type" = field("Source Type Filter"),
                                                                                       "Source No." = field("Source No. Filter"),
                                                                                       "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                                       "Entry Type" = field("Entry Type Filter")));
            Caption = 'Analysis - Cost Amt. (Actual)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(85; "Analysis - Cost Amt. (Exp)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Item Analysis View Entry"."Cost Amount (Expected)" where("Analysis Area" = field("Analysis Area Filter"),
                                                                                         "Analysis View Code" = field("Analysis View Filter"),
                                                                                         "Item No." = field("Item Filter"),
                                                                                         "Location Code" = field("Location Filter"),
                                                                                         "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                                         "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                                         "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                                         "Posting Date" = field("Date Filter"),
                                                                                         "Source Type" = field("Source Type Filter"),
                                                                                         "Source No." = field("Source No. Filter"),
                                                                                         "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                                         "Entry Type" = field("Entry Type Filter")));
            Caption = 'Analysis - Cost Amt. (Exp)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(86; "Analysis CostAmt.(Non-Invtbl.)"; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Item Analysis View Entry"."Cost Amount (Non-Invtbl.)" where("Analysis Area" = field("Analysis Area Filter"),
                                                                                            "Analysis View Code" = field("Analysis View Filter"),
                                                                                            "Item No." = field("Item Filter"),
                                                                                            "Location Code" = field("Location Filter"),
                                                                                            "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                                            "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                                            "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                                            "Posting Date" = field("Date Filter"),
                                                                                            "Source Type" = field("Source Type Filter"),
                                                                                            "Source No." = field("Source No. Filter"),
                                                                                            "Item Ledger Entry Type" = field("Item Ledger Entry Type Filter"),
                                                                                            "Entry Type" = field("Entry Type Filter")));
            Caption = 'Analysis CostAmt.(Non-Invtbl.)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(91; "Analysis - Budgeted Quantity"; Decimal)
        {
            CalcFormula = sum("Item Analysis View Budg. Entry".Quantity where("Analysis Area" = field("Analysis Area Filter"),
                                                                               "Analysis View Code" = field("Analysis View Filter"),
                                                                               "Budget Name" = field("Budget Filter"),
                                                                               "Item No." = field("Item Filter"),
                                                                               "Location Code" = field("Location Filter"),
                                                                               "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                               "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                               "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                               "Posting Date" = field("Date Filter"),
                                                                               "Source Type" = field("Source Type Filter"),
                                                                               "Source No." = field("Source No. Filter")));
            Caption = 'Analysis - Budgeted Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(92; "Analysis - Budgeted Sales Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Item Analysis View Budg. Entry"."Sales Amount" where("Analysis Area" = field("Analysis Area Filter"),
                                                                                     "Analysis View Code" = field("Analysis View Filter"),
                                                                                     "Budget Name" = field("Budget Filter"),
                                                                                     "Item No." = field("Item Filter"),
                                                                                     "Location Code" = field("Location Filter"),
                                                                                     "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                                     "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                                     "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                                     "Posting Date" = field("Date Filter"),
                                                                                     "Source Type" = field("Source Type Filter"),
                                                                                     "Source No." = field("Source No. Filter")));
            Caption = 'Analysis - Budgeted Sales Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(93; "Analysis - Budgeted Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Item Analysis View Budg. Entry"."Cost Amount" where("Analysis Area" = field("Analysis Area Filter"),
                                                                                    "Analysis View Code" = field("Analysis View Filter"),
                                                                                    "Budget Name" = field("Budget Filter"),
                                                                                    "Item No." = field("Item Filter"),
                                                                                    "Location Code" = field("Location Filter"),
                                                                                    "Dimension 1 Value Code" = field("Dimension 1 Filter"),
                                                                                    "Dimension 2 Value Code" = field("Dimension 2 Filter"),
                                                                                    "Dimension 3 Value Code" = field("Dimension 3 Filter"),
                                                                                    "Posting Date" = field("Date Filter"),
                                                                                    "Source Type" = field("Source Type Filter"),
                                                                                    "Source No." = field("Source No. Filter")));
            Caption = 'Analysis - Budgeted Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

