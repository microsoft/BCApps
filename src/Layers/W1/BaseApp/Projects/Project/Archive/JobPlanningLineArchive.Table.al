// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Archive;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Calculation;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Pricing;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;
using System.Security.AccessControl;

table 5137 "Job Planning Line Archive"
{
    Caption = 'Project Planning Line';
    DrillDownPageID = "Job Planning Archive Lines";
    LookupPageID = "Job Planning Archive Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            ToolTip = 'Specifies the planning line''s entry number.';
            Editable = false;
        }
        field(2; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            ToolTip = 'Specifies the number of the related project.';
            NotBlank = true;
            TableRelation = "Job Archive";
        }
        field(3; "Planning Date"; Date)
        {
            Caption = 'Planning Date';
            ToolTip = 'Specifies the date of the planning line. You can use the planning date for filtering the totals of the project, for example, if you want to see the scheduled usage for a specific month of the year.';
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies a document number for the planning line.';
        }
        field(5; Type; Enum "Job Planning Line Type")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of account to which the planning line relates.';
        }
        field(7; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the account to which the resource, item or general ledger account is posted, depending on your selection in the Type field.';
            TableRelation = if (Type = const(Resource)) Resource
            else
            if (Type = const(Item)) Item where(Blocked = const(false))
            else
            if (Type = const("G/L Account")) "G/L Account"
            else
            if (Type = const(Text)) "Standard Text";
        }
        field(8; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies the name of the resource, item, or G/L account to which this entry applies. You can change the description.';
        }
        field(9; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the number of units of the resource, item, or general ledger account that should be specified on the planning line. If you later change the No., the quantity you have entered remains on the line.';
            DecimalPlaces = 0 : 5;
        }
        field(11; "Direct Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Direct Unit Cost (LCY)';
        }
        field(12; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost (LCY)';
            Editable = false;
        }
        field(13; "Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total Cost (LCY)';
            Editable = false;
        }
        field(14; "Unit Price (LCY)"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Price (LCY)';
            Editable = false;
        }
        field(15; "Total Price (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Total Price (LCY)';
            Editable = false;
        }
        field(16; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            Editable = false;
            TableRelation = "Resource Group";
        }
        field(17; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."))
            else
            "Unit of Measure";
        }
        field(18; "Qty. Rounding Precision"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(19; "Qty. Rounding Precision (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies a location code for an item.';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(29; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(30; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(32; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
            TableRelation = "Work Type";
        }
        field(33; "Customer Price Group"; Code[10])
        {
            Caption = 'Customer Price Group';
            TableRelation = "Customer Price Group";
        }
        field(79; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            Editable = false;
            TableRelation = "Country/Region";
        }
        field(80; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
            Editable = false;
            TableRelation = "Gen. Business Posting Group";
        }
        field(81; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
            Editable = false;
            TableRelation = "Gen. Product Posting Group";
        }
        field(83; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(84; "Planning Due Date"; Date)
        {
            Caption = 'Planning Due Date';
        }
        field(900; "Qty. to Assemble"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Assemble';
            DataClassification = CustomerContent;
        }
        field(901; "Qty. to Assemble (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Assemble (Base)';
            DataClassification = CustomerContent;
        }
        field(902; "Assemble to Order"; Boolean)
        {
            Caption = 'Assemble to Order';
            DataClassification = CustomerContent;
        }
        field(903; "BOM Item No."; Code[20])
        {
            Caption = 'BOM Item No.';
            TableRelation = Item;
            DataClassification = CustomerContent;
        }
        field(904; "Attached to Line No."; Integer)
        {
            Caption = 'Attached to Line No.';
            DataClassification = CustomerContent;
        }
        field(1000; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            ToolTip = 'Specifies the number of the related project task.';
            NotBlank = true;
            TableRelation = "Job Task Archive"."Job Task No." where("Job No." = field("Job No."));
        }
        field(1001; "Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Line Amount (LCY)';
            Editable = false;
        }
        field(1002; "Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Cost';
            ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
        }
        field(1003; "Total Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Cost';
            ToolTip = 'Specifies the total cost for the planning line. The total cost is in the project currency, which comes from the Currency Code field in the Project Card.';
            Editable = false;
        }
        field(1004; "Unit Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Unit Price';
            ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
        }
        field(1005; "Total Price"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Total Price';
            ToolTip = 'Specifies the total price in the project currency on the planning line.';
            Editable = false;
        }
        field(1006; "Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Amount';
            ToolTip = 'Specifies the amount that will be posted to the project ledger.';
        }
        field(1007; "Line Discount Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Line Discount Amount';
            ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
        }
        field(1008; "Line Discount Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Line Discount Amount (LCY)';
            Editable = false;
        }
        field(1015; "Cost Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Cost Factor';
            Editable = false;
        }
        field(1019; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ToolTip = 'Specifies the serial number that is applied to the posted item if the planning line was created from the posting of a project journal line.';
            Editable = false;
        }
        field(1020; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ToolTip = 'Specifies the lot number that is applied to the posted item if the planning line was created from the posting of a project journal line.';
            Editable = false;
        }
        field(1021; "Line Discount %"; Decimal)
        {
            AutoFormatType = 0;
            BlankZero = true;
            Caption = 'Line Discount %';
            ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
            DecimalPlaces = 0 : 5;
        }
        field(1022; "Line Type"; Enum "Job Planning Line Line Type")
        {
            Caption = 'Line Type';
            ToolTip = 'Specifies the type of planning line.';
        }
        field(1023; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            Editable = false;
            TableRelation = Currency;
        }
        field(1024; "Currency Date"; Date)
        {
            AccessByPermission = TableData Currency = R;
            Caption = 'Currency Date';
            ToolTip = 'Specifies the date that will be used to find the exchange rate for the currency in the Currency Date field.';
        }
        field(1025; "Currency Factor"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            Editable = false;
            MinValue = 0;
        }
        field(1026; "Schedule Line"; Boolean)
        {
            Caption = 'Budget Line';
            Editable = false;
            InitValue = true;
        }
        field(1027; "Contract Line"; Boolean)
        {
            Caption = 'Billable Line';
            ToolTip = 'Specifies whether this line is a billable line.';
            Editable = false;
        }
        field(1030; "Job Contract Entry No."; Integer)
        {
            Caption = 'Project Contract Entry No.';
            ToolTip = 'Specifies the entry number of the project planning line that the sales line is linked to.';
            Editable = false;
        }
        field(1035; "Invoiced Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Invoiced Amount (LCY)';
        }
        field(1036; "Invoiced Cost Amount (LCY)"; Decimal)
        {
            Caption = 'Invoiced Cost Amount (LCY)';
            AutoFormatType = 1;
            AutoFormatExpression = '';
        }
        field(1037; "VAT Unit Price"; Decimal)
        {
            Caption = 'VAT Unit Price';
            AutoFormatType = 2;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(1038; "VAT Line Discount Amount"; Decimal)
        {
            Caption = 'VAT Line Discount Amount';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(1039; "VAT Line Amount"; Decimal)
        {
            Caption = 'VAT Line Amount';
            AutoFormatType = 1;
            AutoFormatExpression = Rec."Currency Code";
        }
        field(1041; "VAT %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'VAT %';
        }
        field(1042; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            ToolTip = 'Specifies information in addition to the description.';
        }
        field(1043; "Job Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Project Ledger Entry No.';
            Editable = false;
            TableRelation = "Job Ledger Entry";
        }
        field(1048; Status; Enum "Job Planning Line Status")
        {
            Caption = 'Status';
            Editable = false;
            InitValue = "Order";
        }
        field(1050; "Ledger Entry Type"; Enum "Job Ledger Entry Type")
        {
            Caption = 'Ledger Entry Type';
            ToolTip = 'Specifies the entry type of the project ledger entry associated with the planning line.';
        }
        field(1051; "Ledger Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Ledger Entry No.';
            ToolTip = 'Specifies the entry number of the project ledger entry associated with the project planning line.';
            TableRelation = if ("Ledger Entry Type" = const(Resource)) "Res. Ledger Entry"
            else
            if ("Ledger Entry Type" = const(Item)) "Item Ledger Entry"
            else
            if ("Ledger Entry Type" = const("G/L Account")) "G/L Entry";
        }
        field(1052; "System-Created Entry"; Boolean)
        {
            Caption = 'System-Created Entry';
            ToolTip = 'Specifies that an entry has been created by Business Central and is related to a project ledger entry. The check box is selected automatically.';
        }
        field(1053; "Usage Link"; Boolean)
        {
            Caption = 'Usage Link';
            ToolTip = 'Specifies whether the Usage Link field applies to the project planning line. When this check box is selected, usage entries are linked to the project planning line. Selecting this check box creates a link to the project planning line from places where usage has been posted, such as the project journal or a purchase line. You can select this check box only if the line type of the project planning line is Budget or Both Budget and Billable.';
        }
        field(1060; "Remaining Qty."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Remaining Qty.';
            ToolTip = 'Specifies the remaining quantity of the resource, item, or G/L Account that remains to complete a project. The quantity is calculated as the difference between Quantity and Qty. Posted.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(1061; "Remaining Qty. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Remaining Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(1062; "Remaining Total Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Total Cost';
            ToolTip = 'Specifies the remaining total cost for the planning line. The total cost is in the project currency, which comes from the Currency Code field in the Project Card.';
            Editable = false;
        }
        field(1063; "Remaining Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Remaining Total Cost (LCY)';
            Editable = false;
        }
        field(1064; "Remaining Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Remaining Line Amount';
            ToolTip = 'Specifies the amount that will be posted to the project ledger.';
            Editable = false;
        }
        field(1065; "Remaining Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Remaining Line Amount (LCY)';
            Editable = false;
        }
        field(1070; "Qty. Posted"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Posted';
            ToolTip = 'Specifies the quantity that has been posted to the project ledger, if the Usage Link check box has been selected.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(1071; "Qty. to Transfer to Journal"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Transfer to Journal';
            ToolTip = 'Specifies the quantity you want to transfer to the project journal. Its default value is calculated as quantity minus the quantity that has already been posted, if the Apply Usage Link check box has been selected.';
            DecimalPlaces = 0 : 5;
        }
        field(1072; "Posted Total Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Posted Total Cost';
            ToolTip = 'Specifies the total cost that has been posted to the project ledger, if the Usage Link check box has been selected.';
            Editable = false;
        }
        field(1073; "Posted Total Cost (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Posted Total Cost (LCY)';
            Editable = false;
        }
        field(1074; "Posted Line Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Posted Line Amount';
            ToolTip = 'Specifies the amount that has been posted to the project ledger. This field is only filled in if the Apply Usage Link check box selected on the project card.';
            Editable = false;
        }
        field(1075; "Posted Line Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Posted Line Amount (LCY)';
            Editable = false;
        }
        field(1080; "Qty. Transferred to Invoice"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Transferred to Invoice';
            DecimalPlaces = 0 : 5;
        }
        field(1081; "Qty. to Transfer to Invoice"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Transfer to Invoice';
            ToolTip = 'Specifies the quantity you want to transfer to the sales invoice or credit memo. The value in this field is calculated as Quantity - Qty. Transferred to Invoice.';
            DecimalPlaces = 0 : 5;
        }
        field(1090; "Qty. Invoiced"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Invoiced';
            DecimalPlaces = 0 : 5;
        }
        field(1091; "Qty. to Invoice"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. to Invoice';
            ToolTip = 'Specifies the quantity that remains to be invoiced. It is calculated as Quantity - Qty. Invoiced.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(1100; "Reserved Quantity"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData Item = R;
            Caption = 'Reserved Quantity';
            ToolTip = 'Specifies the quantity of the item that is reserved for the project planning line.';
            DecimalPlaces = 0 : 5;
        }
        field(1101; "Reserved Qty. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            AccessByPermission = TableData Item = R;
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(1102; Reserve; Enum "Reserve Method")
        {
            AccessByPermission = TableData Item = R;
            Caption = 'Reserve';
            ToolTip = 'Specifies whether or not a reservation can be made for items on the current line. The field is not applicable if the Type field is set to Resource, Cost, or G/L Account.';
        }
        field(1103; Planned; Boolean)
        {
            Caption = 'Planned';
            Editable = false;
        }
        field(5047; "Version No."; Integer)
        {
            Caption = 'Version No.';
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."), Blocked = const(false));
        }
        field(5403; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            ToolTip = 'Specifies the bin where the selected item will be put away or picked in warehouse and inventory processes. If you specify a bin code in the To-Project Bin Code field on the Location page, that bin will be suggested when you choose the location.';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5410; "Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(5790; "Requested Delivery Date"; Date)
        {
            Caption = 'Requested Delivery Date';
        }
        field(5791; "Promised Delivery Date"; Date)
        {
            Caption = 'Promised Delivery Date';
        }
        field(5794; "Planned Delivery Date"; Date)
        {
            Caption = 'Planned Delivery Date';
            ToolTip = 'Specifies the date that is planned to deliver the item connected to the project planning line. For a resource, the planned delivery date is the date that the resource performs services with respect to the project.';
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
            Editable = false;
        }
        field(7000; "Price Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Price Calculation Method';
            ToolTip = 'Specifies the method that will be used for price calculation in the item journal line.';
        }
        field(7001; "Cost Calculation Method"; Enum "Price Calculation Method")
        {
            Caption = 'Cost Calculation Method';
            ToolTip = 'Specifies the method that will be used for cost calculation in the item journal line.';
        }
        field(7300; "Pick Qty."; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
        }
        field(7301; "Qty. Picked"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Picked';
            ToolTip = 'Specifies the quantity of the item you have picked for the project planning line.';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(7302; "Qty. Picked (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. Picked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(7303; "Completely Picked"; Boolean)
        {
            Caption = 'Completely Picked';
            Editable = false;
        }
        field(7304; "Pick Qty. (Base)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(7305; "Qty. on Journal"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. on Journal';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", "Version No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
