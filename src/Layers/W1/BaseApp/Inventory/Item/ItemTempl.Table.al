// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Assembly.Setup;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

table 1382 "Item Templ."
{
    Caption = 'Item Template';
    LookupPageID = "Item Templ. List";
    DrillDownPageID = "Item Templ. List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code of the template.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the description of the template.';
        }
        field(8; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            ToolTip = 'Specifies the base unit used to measure the item, such as piece, box, or pallet. The base unit of measure also serves as the conversion basis for alternate units of measure.';
            TableRelation = "Unit of Measure";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Base Unit of Measure"));
            end;
        }
        field(9; "Price Unit Conversion"; Integer)
        {
            Caption = 'Price Unit Conversion';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Price Unit Conversion"));
            end;
        }
        field(10; Type; Enum "Item Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies whether the item card represents a physical inventory unit (Inventory), a labor time unit (Service), or a physical unit that is not tracked in inventory (Non-Inventory).';

            trigger OnValidate()
            begin
                if (Type = Type::Service) or (Type = Type::"Non-Inventory") then
                    Validate("Inventory Posting Group", '');

                ValidateItemField(FieldNo(Type));
            end;
        }
        field(11; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            ToolTip = 'Specifies links between business transactions made for the item and an inventory account in the general ledger, to group amounts for that item type.';
            TableRelation = "Inventory Posting Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Inventory Posting Group"));
            end;
        }
        field(12; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
            ToolTip = 'Specifies where to find the item in the warehouse. This is informational only.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Shelf No."));
            end;
        }
        field(14; "Item Disc. Group"; Code[20])
        {
            Caption = 'Item Disc. Group';
            ToolTip = 'Specifies an item group code that can be used as a criterion to grant a discount when the item is sold to a certain customer.';
            TableRelation = "Item Discount Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Item Disc. Group"));
            end;
        }
        field(15; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            ToolTip = 'Specifies whether to include the item when calculating an invoice discount on documents where the item is traded.';
            InitValue = true;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Allow Invoice Disc."));
            end;
        }
        field(16; "Statistics Group"; Integer)
        {
            Caption = 'Statistics Group';
            ToolTip = 'Specifies the statistics group.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Statistics Group"));
            end;
        }
        field(17; "Commission Group"; Integer)
        {
            Caption = 'Commission Group';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Commission Group"));
            end;
        }
        field(18; "Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Price';
            ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Unit Price"));
            end;
        }
        field(19; "Price/Profit Calculation"; Enum "Item Price Profit Calculation")
        {
            Caption = 'Price/Profit Calculation';
            ToolTip = 'Specifies the relationship between the Unit Cost, Unit Price, and Profit Percentage fields associated with this item.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Price/Profit Calculation"));
            end;
        }
        field(20; "Profit %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Profit %';
            ToolTip = 'Specifies the profit margin that you want to sell the item at. You can enter a profit percentage manually or have it entered according to the Price/Profit Calculation field';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Profit %"));
            end;
        }
        field(21; "Costing Method"; Enum "Costing Method")
        {
            Caption = 'Costing Method';
            ToolTip = 'Specifies how the item''s cost flow is recorded and whether an actual or budgeted value is capitalized and used in the cost calculation.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Costing Method"));
            end;
        }
        field(22; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost';
            ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Unit Cost"));
            end;
        }
        field(24; "Standard Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Standard Cost';
            ToolTip = 'Specifies the unit cost that is used as an estimation to be adjusted with variances later. It is typically used in assembly and production where costs can vary.';
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Standard Cost"));
            end;
        }
        field(28; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            ToolTip = 'Specifies the percentage of the item''s last purchase cost that includes indirect costs, such as freight that is associated with the purchase of the item.';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Indirect Cost %"));
            end;
        }
        field(31; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            ToolTip = 'Specifies the vendor code of who supplies this item by default.';
            TableRelation = Vendor;
            ValidateTableRelation = true;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Vendor No."));
            end;
        }
        field(32; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
            ToolTip = 'Specifies the number that the vendor uses for this item.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Vendor Item No."));
            end;
        }
        field(33; "Lead Time Calculation"; DateFormula)
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Lead Time Calculation';
            ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Lead Time Calculation"));
            end;
        }
        field(34; "Reorder Point"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reorder Point';
            ToolTip = 'Specifies a stock quantity that sets the inventory below the level that you must replenish the item.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Reorder Point"));
            end;
        }
        field(35; "Maximum Inventory"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Maximum Inventory';
            ToolTip = 'Specifies a quantity that you want to use as a maximum inventory level.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Maximum Inventory"));
            end;
        }
        field(36; "Reorder Quantity"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reorder Quantity';
            ToolTip = 'Specifies a standard lot size quantity to be used for all order proposals.';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Reorder Quantity"));
            end;
        }
        field(37; "Alternative Item No."; Code[20])
        {
            Caption = 'Alternative Item No.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Alternative Item No."));
            end;
        }
        field(38; "Unit List Price"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit List Price';
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Unit List Price"));
            end;
        }
        field(39; "Duty Due %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Duty Due %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Duty Due %"));
            end;
        }
        field(40; "Duty Code"; Code[10])
        {
            Caption = 'Duty Code';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Duty Code"));
            end;
        }
        field(41; "Gross Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Gross Weight';
            ToolTip = 'Specifies the gross weight of the item.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Gross Weight"));
            end;
        }
        field(42; "Net Weight"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Net Weight';
            ToolTip = 'Specifies the net weight of the item.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Net Weight"));
            end;
        }
        field(43; "Units per Parcel"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Units per Parcel';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Units per Parcel"));
            end;
        }
        field(44; "Unit Volume"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unit Volume';
            ToolTip = 'Specifies the volume of one unit of the item.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Unit Volume"));
            end;
        }
        field(45; Durability; Code[10])
        {
            Caption = 'Durability';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo(Durability));
            end;
        }
        field(46; "Freight Type"; Code[10])
        {
            Caption = 'Freight Type';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Freight Type"));
            end;
        }
        field(47; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
            ToolTip = 'Specifies a code for the item''s tariff number.';
            TableRelation = "Tariff Number";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Tariff No."));
            end;
        }
        field(48; "Duty Unit Conversion"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Duty Unit Conversion';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Duty Unit Conversion"));
            end;
        }
        field(49; "Country/Region Purchased Code"; Code[10])
        {
            Caption = 'Country/Region Purchased Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Country/Region Purchased Code"));
            end;
        }
        field(50; "Budget Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Budget Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Budget Quantity"));
            end;
        }
        field(51; "Budgeted Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Budgeted Amount';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Budgeted Amount"));
            end;
        }
        field(52; "Budget Profit"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Budget Profit';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Budget Profit"));
            end;
        }
        field(54; Blocked; Boolean)
        {
            Caption = 'Blocked';
            ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example an item that is placed in quarantine.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo(Blocked));
            end;
        }
        field(56; "Block Reason"; Text[250])
        {
            Caption = 'Block Reason';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Block Reason"));
            end;
        }
        field(87; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';
            ToolTip = 'Specifies if the Unit Price and Line Amount fields on sales document lines for this item should be shown with or without VAT.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Price Includes VAT"));
            end;
        }
        field(90; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            TableRelation = "VAT Business Posting Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("VAT Bus. Posting Gr. (Price)"));
            end;
        }
        field(91; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            TableRelation = "Gen. Product Posting Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Gen. Prod. Posting Group"));
            end;
        }
        field(95; "Country/Region of Origin Code"; Code[10])
        {
            Caption = 'Country/Region of Origin Code';
            ToolTip = 'Specifies a code for the country/region where the item was produced or processed.';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Country/Region of Origin Code"));
            end;
        }
        field(96; "Automatic Ext. Texts"; Boolean)
        {
            Caption = 'Automatic Ext. Texts';
            ToolTip = 'Specifies that an extended text that you have set up will be added automatically on sales or purchase documents for this item.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Automatic Ext. Texts"));
            end;
        }
        field(97; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            ToolTip = 'Specifies the number series that will be used to assign numbers to items.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("No. Series"));
            end;
        }
        field(98; "Tax Group Code"; Code[20])
        {
            Caption = 'Tax Group Code';
            ToolTip = 'Specifies the tax group that is used to calculate and post sales tax.';
            TableRelation = "Tax Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Tax Group Code"));
            end;
        }
        field(99; "VAT Prod. Posting Group"; Code[20])
        {
            Caption = 'VAT Prod. Posting Group';
            ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
            TableRelation = "VAT Product Posting Group";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("VAT Prod. Posting Group"));
            end;
        }
        field(100; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData "Purch. Rcpt. Header" = R;
            Caption = 'Reserve';
            ToolTip = 'Specifies if and how the item will be reserved. Never: It is not possible to reserve the item. Optional: You can reserve the item manually. Always: The item is automatically reserved from demand, such as sales orders, against inventory, purchase orders, assembly orders, and production orders.';
            InitValue = Optional;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo(Reserve));
            end;
        }
        field(105; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(106; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(120; "Stockout Warning"; Option)
        {
            Caption = 'Stockout Warning';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Stockout Warning"));
            end;
        }
        field(121; "Prevent Negative Inventory"; Option)
        {
            Caption = 'Prevent Negative Inventory';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Prevent Negative Inventory"));
            end;
        }
        field(122; "Variant Mandatory if Exists"; Option)
        {
            Caption = 'Variant Mandatory if Exists';
            ToolTip = 'Specifies whether a variant must be selected if variants exist for the item.';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;
        }
        field(910; "Assembly Policy"; Enum "Assembly Policy")
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assembly Policy';
            ToolTip = 'Specifies which default order flow is used to supply this assembly item.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Assembly Policy"));
            end;
        }
        field(1217; GTIN; Code[14])
        {
            Caption = 'GTIN';
            ToolTip = 'Specifies the Global Trade Item Number (GTIN) for the item. For example, the GTIN is used with bar codes to track items, and when sending and receiving documents electronically. The GTIN number typically contains a Universal Product Code (UPC), or European Article Number (EAN).';
            Numeric = true;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo(GTIN));
            end;
        }
        field(1700; "Default Deferral Template Code"; Code[10])
        {
            Caption = 'Default Deferral Template Code';
            ToolTip = 'Specifies how revenue or expenses for the item are deferred to other accounting periods by default.';
            TableRelation = "Deferral Template"."Deferral Code";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Default Deferral Template Code"));
            end;
        }
        field(5401; "Lot Size"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Lot Size';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Lot Size"));
            end;
        }
        field(5402; "Serial Nos."; Code[20])
        {
            Caption = 'Serial Nos.';
            ToolTip = 'Specifies a number series code to assign consecutive serial numbers to items produced.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Serial Nos."));
            end;
        }
        field(5407; "Scrap %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Scrap %';
            DecimalPlaces = 0 : 2;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Scrap %"));
            end;
        }
        field(5408; "Rolled-up Mat. Non-Invt. Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Rolled-up Material Non-Inventory Cost';
            DataClassification = CustomerContent;
            DecimalPlaces = 2 : 5;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Rolled-up Mat. Non-Invt. Cost"));
            end;
        }
        field(5409; "Inventory Value Zero"; Boolean)
        {
            Caption = 'Inventory Value Zero';
            ToolTip = 'Specifies whether the item on inventory must be excluded from inventory valuation. This is relevant if the item is kept on inventory on someone else''s behalf.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Inventory Value Zero"));
            end;
        }
        field(5410; "Discrete Order Quantity"; Integer)
        {
            Caption = 'Discrete Order Quantity';
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Discrete Order Quantity"));
            end;
        }
        field(5411; "Minimum Order Quantity"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Minimum Order Quantity';
            ToolTip = 'Specifies a minimum allowable quantity for an item order proposal.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Minimum Order Quantity"));
            end;
        }
        field(5412; "Maximum Order Quantity"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Maximum Order Quantity';
            ToolTip = 'Specifies a maximum allowable quantity for an item order proposal.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Maximum Order Quantity"));
            end;
        }
        field(5413; "Safety Stock Quantity"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Safety Stock Quantity';
            ToolTip = 'Specifies a quantity of stock to have in inventory to protect against supply-and-demand fluctuations during replenishment lead time.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Safety Stock Quantity"));
            end;
        }
        field(5414; "Order Multiple"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Order Multiple';
            ToolTip = 'Specifies a parameter used by the planning system to round the quantity of planned supply orders to a multiple of this value.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Order Multiple"));
            end;
        }
        field(5415; "Safety Lead Time"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Safety Lead Time';
            ToolTip = 'Specifies a date formula to indicate a safety lead time that can be used as a buffer period for production and other delays.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Safety Lead Time"));
            end;
        }
        field(5417; "Flushing Method"; Enum Microsoft.Manufacturing.Setup."Flushing Method")
        {
            Caption = 'Flushing Method';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Flushing Method"));
            end;
        }
        field(5419; "Replenishment System"; Enum "Replenishment System")
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Replenishment System';
            ToolTip = 'Specifies the type of supply order created by the planning system when the item needs to be replenished.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Replenishment System"));
            end;
        }
        field(5422; "Rounding Precision"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Rounding Precision';
            DecimalPlaces = 0 : 5;
            InitValue = 1;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Rounding Precision"));
            end;
        }
        field(5428; "Time Bucket"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Time Bucket';
            ToolTip = 'Specifies a time period that defines the recurring planning horizon used with Fixed Reorder Qty. or Maximum Qty. reordering policies.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Time Bucket"));
            end;
        }
        field(5440; "Reordering Policy"; Enum "Reordering Policy")
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Reordering Policy';
            ToolTip = 'Specifies the reordering policy.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Reordering Policy"));
            end;
        }
        field(5441; "Include Inventory"; Boolean)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Include Inventory';
            ToolTip = 'Specifies that the inventory quantity is included in the projected available balance when replenishment orders are calculated.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Include Inventory"));
            end;
        }
        field(5442; "Manufacturing Policy"; Enum Microsoft.Manufacturing.Setup."Manufacturing Policy")
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Manufacturing Policy';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Manufacturing Policy"));
            end;
        }
        field(5443; "Rescheduling Period"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Rescheduling Period';
            ToolTip = 'Specifies a period within which any suggestion to change a supply date always consists of a Reschedule action and never a Cancel + New action.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Rescheduling Period"));
            end;
        }
        field(5444; "Lot Accumulation Period"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Lot Accumulation Period';
            ToolTip = 'Specifies a period in which multiple demands are accumulated into one supply order when you use the Lot-for-Lot reordering policy.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Lot Accumulation Period"));
            end;
        }
        field(5445; "Dampener Period"; DateFormula)
        {
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Dampener Period';
            ToolTip = 'Specifies a period of time during which you do not want the planning system to propose to reschedule existing supply orders forward. The dampener period limits the number of insignificant rescheduling of existing supply to a later date if that new date is within the dampener period. The dampener period function is only initiated if the supply can be rescheduled to a later date and not if the supply can be rescheduled to an earlier date. Accordingly, if the suggested new supply date is after the dampener period, then the rescheduling suggestion is not blocked. If the lot accumulation period is less than the dampener period, then the dampener period is dynamically set to equal the lot accumulation period. This is not shown in the value that you enter in the Dampener Period field. The last demand in the lot accumulation period is used to determine whether a potential supply date is in the dampener period. If this field is empty, then the value in the Default Dampener Period field in the Manufacturing Setup window applies. The value that you enter in the Dampener Period field must be a date formula, and one day (1D) is the shortest allowed period.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Dampener Period"));
            end;
        }
        field(5446; "Dampener Quantity"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Dampener Quantity';
            ToolTip = 'Specifies a dampener quantity to block insignificant change suggestions for an existing supply, if the change quantity is lower than the dampener quantity.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Dampener Quantity"));
            end;
        }
        field(5447; "Overflow Level"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData "Req. Wksh. Template" = R;
            Caption = 'Overflow Level';
            ToolTip = 'Specifies a quantity you allow projected inventory to exceed the reorder point, before the system suggests to decrease supply orders.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Overflow Level"));
            end;
        }
        field(5701; "Manufacturer Code"; Code[10])
        {
            Caption = 'Manufacturer Code';
            ToolTip = 'Specifies a code for the manufacturer of the catalog item.';
            TableRelation = Manufacturer;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Manufacturer Code"));
            end;
        }
        field(5702; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            ToolTip = 'Specifies the category that the item belongs to. Item categories also contain any assigned item attributes.';
            TableRelation = "Item Category";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Item Category Code"));
            end;
        }
        field(5711; "Purchasing Code"; Code[10])
        {
            Caption = 'Purchasing Code';
            ToolTip = 'Specifies the code for a special procurement method, such as drop shipment.';
            TableRelation = Purchasing;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Purchasing Code"));
            end;
        }
        field(6502; "Expiration Calculation"; DateFormula)
        {
            Caption = 'Expiration Calculation';
            ToolTip = 'Specifies the date formula for calculating the expiration date on the item tracking line. Note: This field will be ignored if the involved item has Require Expiration Date Entry set to Yes on the Item Tracking Code page.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Expiration Calculation"));
            end;
        }
        field(6500; "Item Tracking Code"; Code[10])
        {
            Caption = 'Item Tracking Code';
            ToolTip = 'Specifies how serial, lot or package numbers assigned to the item are tracked in the supply chain.';
            TableRelation = "Item Tracking Code";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Item Tracking Code"));
            end;
        }
        field(6501; "Lot Nos."; Code[20])
        {
            Caption = 'Lot Nos.';
            ToolTip = 'Specifies the number series code that will be used when assigning lot numbers.';
            TableRelation = "No. Series";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Lot Nos."));
            end;
        }
        field(7301; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            ToolTip = 'Specifies the code of the equipment that warehouse employees must use when handling the item.';
            TableRelation = "Special Equipment";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Special Equipment Code"));
            end;
        }
        field(7302; "Put-away Template Code"; Code[10])
        {
            Caption = 'Put-away Template Code';
            ToolTip = 'Specifies the code of the put-away template by which the program determines the most appropriate zone and bin for storage of the item after receipt.';
            TableRelation = "Put-away Template Header";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Put-away Template Code"));
            end;
        }
        field(7300; "Warehouse Class Code"; Code[10])
        {
            Caption = 'Warehouse Class Code';
            ToolTip = 'Specifies the warehouse class code for the item.';
            TableRelation = "Warehouse Class";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Warehouse Class Code"));
            end;
        }
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            ToolTip = 'Specifies the code of the counting period that indicates how often you want to count the item in a physical inventory.';
            TableRelation = "Phys. Invt. Counting Period";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Phys Invt Counting Period Code"));
            end;
        }
        field(7384; "Use Cross-Docking"; Boolean)
        {
            AccessByPermission = TableData "Bin Content" = R;
            Caption = 'Use Cross-Docking';
            ToolTip = 'Specifies if this item can be cross-docked.';
            InitValue = true;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Use Cross-Docking"));
            end;
        }
        field(8003; "Sales Blocked"; Boolean)
        {
            Caption = 'Sales Blocked';
            ToolTip = 'Specifies that the item cannot be entered on sales documents, except return orders and credit memos, and journals.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Sales Blocked"));
            end;
        }
        field(8004; "Purchasing Blocked"; Boolean)
        {
            Caption = 'Purchasing Blocked';
            ToolTip = 'Specifies that the item cannot be entered on purchase documents, except return orders and credit memos, and journals.';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Purchasing Blocked"));
            end;
        }
        field(8010; "Service Blocked"; Boolean)
        {
            Caption = 'Service Blocked';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Service Blocked"));
            end;
        }
        field(8510; "Over-Receipt Code"; Code[20])
        {
            Caption = 'Over-Receipt Code';
            ToolTip = 'Specifies the policy that will be used for the item if more items than ordered are received.';
            TableRelation = "Over-Receipt Code";

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Over-Receipt Code"));
            end;
        }
        field(99000757; "Overhead Rate"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Overhead Rate';

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Overhead Rate"));
            end;
        }
        field(99000773; "Order Tracking Policy"; Enum "Order Tracking Policy")
        {
            Caption = 'Order Tracking Policy';
            ToolTip = 'Specifies if and how order tracking entries are created and maintained between supply and its corresponding demand.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Order Tracking Policy"));
            end;
        }
        field(99000875; Critical; Boolean)
        {
            Caption = 'Critical';
            ToolTip = 'Specifies if the item is included in availability calculations to promise a shipment date for its parent item.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo(Critical));
            end;
        }
        field(99008500; "Common Item No."; Code[20])
        {
            Caption = 'Common Item No.';
            ToolTip = 'Specifies the unique common item number that the intercompany partners agree upon.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                ValidateItemField(FieldNo("Common Item No."));
            end;
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
        key(CategoryKey; "Item Category Code")
        {
        }
    }

    trigger OnDelete()
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.SetRange("Table ID", Database::"Item Templ.");
        DefaultDimension.SetRange("No.", Code);
        DefaultDimension.DeleteAll();
    end;

    trigger OnRename()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.RenameDefaultDim(Database::"Item Templ.", xRec.Code, Code);
    end;

    local procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ValidateDimValueCode(FieldNumber, ShortcutDimCode);
        if not IsTemporary then begin
            DimMgt.SaveDefaultDim(Database::"Item Templ.", Code, FieldNumber, ShortcutDimCode);
            Modify();
        end;
    end;

    procedure CopyFromTemplate(SourceItemTempl: Record "Item Templ.")
    begin
        CopyTemplate(SourceItemTempl);
        CopyDimensions(SourceItemTempl);
        OnAfterCopyFromTemplate(SourceItemTempl, Rec);
    end;

    local procedure CopyTemplate(SourceItemTempl: Record "Item Templ.")
    var
        SavedItemTempl: Record "Item Templ.";
    begin
        SavedItemTempl := Rec;
        TransferFields(SourceItemTempl, false);
        Code := SavedItemTempl.Code;
        Description := SavedItemTempl.Description;
        OnCopyTemplateOnBeforeModify(SourceItemTempl, SavedItemTempl, Rec);
        Modify();
    end;

    local procedure CopyDimensions(SourceItemTempl: Record "Item Templ.")
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        DestDefaultDimension.SetRange("Table ID", Database::"Item Templ.");
        DestDefaultDimension.SetRange("No.", Code);
        DestDefaultDimension.DeleteAll(true);

        SourceDefaultDimension.SetRange("Table ID", Database::"Item Templ.");
        SourceDefaultDimension.SetRange("No.", SourceItemTempl.Code);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", Database::"Item Templ.");
                DestDefaultDimension.Validate("No.", Code);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                if DestDefaultDimension.Insert(true) then;
            until SourceDefaultDimension.Next() = 0;
    end;

    procedure ValidateItemField(FieldId: Integer)
    var
        ItemRecordRef: RecordRef;
        ItemTemplRecordRef: RecordRef;
        ItemFieldRef: FieldRef;
        ItemTemplFieldRef: FieldRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateItemField(Rec, FieldId, IsHandled);
        if IsHandled then
            exit;

        ItemTemplRecordRef.GetTable(Rec);
        ItemRecordRef.Open(Database::Item, true);
        TransferFieldValues(ItemTemplRecordRef, ItemRecordRef, false);
        ItemRecordRef.Insert();

        ItemFieldRef := ItemRecordRef.Field(FieldId);
        ItemTemplFieldRef := ItemTemplRecordRef.Field(FieldId);
        ItemFieldRef.Validate(ItemTemplFieldRef.Value);

        TransferFieldValues(ItemTemplRecordRef, ItemRecordRef, true);

        ItemTemplRecordRef.SetTable(Rec);
        Modify();
    end;

    local procedure TransferFieldValues(var SrcRecRef: RecordRef; var DestRecRef: RecordRef; Reverse: Boolean)
    var
        SrcFieldRef: FieldRef;
        DestFieldRef: FieldRef;
        i: Integer;
        IsHandled: Boolean;
    begin
        for i := 3 to SrcRecRef.FieldCount do begin
            SrcFieldRef := SrcRecRef.FieldIndex(i);
            IsHandled := false;
            OnTransferFieldValuesOnBeforeTransferFieldValue(SrcFieldRef, DestFieldRef, Reverse, IsHandled);
            if not IsHandled then begin
                DestFieldRef := DestRecRef.Field(SrcFieldRef.Number);
                if not Reverse then
                    DestFieldRef.Value := SrcFieldRef.Value()
                else
                    SrcFieldRef.Value := DestFieldRef.Value();
            end;
        end;

        OnAfterTransferFieldValues(SrcRecRef, DestRecRef, Reverse);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromTemplate(SourceItemTempl: Record "Item Templ."; var ItemTempl: Record "Item Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyTemplateOnBeforeModify(SourceItemTempl: Record "Item Templ."; SavedItemTempl: Record "Item Templ."; var ItemTempl: Record "Item Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateItemField(var ItemTempl: record "Item Templ."; FieldId: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFieldValues(var SrcRecRef: RecordRef; var DestRecRef: RecordRef; Reverse: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFieldValuesOnBeforeTransferFieldValue(var SrcFieldRef: FieldRef; var DestFieldRef: FieldRef; Reverse: Boolean; var IsHandled: Boolean)
    begin
    end;
}

