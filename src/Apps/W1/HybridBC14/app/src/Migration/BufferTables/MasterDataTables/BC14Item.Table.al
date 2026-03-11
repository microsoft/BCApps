// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

table 50161 "BC14 Item"
{
    Caption = 'BC14 Item';
    DataClassification = CustomerContent;
    ReplicateData = false;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Search Description"; Code[100])
        {
            Caption = 'Search Description';
        }
        field(5; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(8; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
        }
        field(10; Type; Option)
        {
            Caption = 'Type';
            OptionMembers = Inventory,Service,"Non-Inventory";
        }
        field(11; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
        }
        field(14; "Item Disc. Group"; Code[20])
        {
            Caption = 'Item Disc. Group';
        }
        field(18; "Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
            Caption = 'Unit Price';
            MinValue = 0;
        }
        field(21; "Costing Method"; Option)
        {
            Caption = 'Costing Method';
            OptionMembers = FIFO,LIFO,Specific,Average,Standard;
        }
        field(22; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
            Caption = 'Unit Cost';
            MinValue = 0;
        }
        field(24; "Standard Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
            Caption = 'Standard Cost';
            MinValue = 0;
        }
        field(31; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
        }
        field(32; "Vendor Item No."; Text[50])
        {
            Caption = 'Vendor Item No.';
        }
        field(36; "Reorder Quantity"; Decimal)
        {
            Caption = 'Reorder Quantity';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,0:5><Standard Format,0>';
        }
        field(37; "Alternative Item No."; Code[20])
        {
            Caption = 'Alternative Item No.';
        }
        field(38; "Unit List Price"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
            Caption = 'Unit List Price';
            MinValue = 0;
        }
        field(42; "Net Weight"; Decimal)
        {
            Caption = 'Net Weight';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,0:5><Standard Format,0>';
            MinValue = 0;
        }
        field(44; "Unit Volume"; Decimal)
        {
            Caption = 'Unit Volume';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,0:5><Standard Format,0>';
            MinValue = 0;
        }
        field(47; "Tariff No."; Code[20])
        {
            Caption = 'Tariff No.';
        }
        field(54; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(61; "Last DateTime Modified"; DateTime)
        {
            Caption = 'Last DateTime Modified';
            Editable = false;
        }
        field(62; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(91; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
        }
        field(120; "Stockout Warning"; Option)
        {
            Caption = 'Stockout Warning';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;
        }
        field(121; "Prevent Negative Inventory"; Option)
        {
            Caption = 'Prevent Negative Inventory';
            OptionCaption = 'Default,No,Yes';
            OptionMembers = Default,No,Yes;
        }
        field(5426; "Purch. Unit of Measure"; Code[10])
        {
            Caption = 'Purch. Unit of Measure';
        }
        field(6500; "Item Tracking Code"; Code[10])
        {
            Caption = 'Item Tracking Code';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
