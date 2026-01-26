// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

table 10604 "E-Invoice Export Header"
{
    Caption = 'E-Invoice Export Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            Caption = 'ID';
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
        }
        field(6; Note; Text[80])
        {
            Caption = 'Note';
        }
        field(7; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
        }
        field(8; "Bill-to Address 2"; Text[50])
        {
            Caption = 'Bill-to Address 2';
        }
        field(9; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
        }
        field(11; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(15; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
        }
        field(16; "Ship-to Address 2"; Text[50])
        {
            Caption = 'Ship-to Address 2';
        }
        field(17; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(21; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(23; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
        }
        field(24; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(32; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(43; "Salesperson Code"; Code[10])
        {
            Caption = 'Salesperson Code';
        }
        field(44; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(70; "VAT Registration No."; Text[20])
        {
            Caption = 'VAT Registration No.';
        }
        field(85; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
        }
        field(86; "Bill-to County"; Text[30])
        {
            Caption = 'Bill-to County';
        }
        field(87; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
        }
        field(90; "Sell-to Country/Region Code"; Code[10])
        {
            Caption = 'Sell-to Country/Region Code';
        }
        field(91; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
        }
        field(93; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
        }
        field(100; "Document No."; Code[35])
        {
            Caption = 'Document No.';
        }
        field(111; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
        }
        field(5052; "Sell-to Contact No."; Code[20])
        {
            Caption = 'Sell-to Contact No.';
        }
        field(5700; "Responsibility Center"; Code[10])
        {
            Caption = 'Responsibility Center';
        }
        field(10600; GLN; Code[13])
        {
            Caption = 'GLN';
        }
        field(10606; "Payment ID"; Code[30])
        {
            Caption = 'Payment ID';
        }
        field(10680; "Schema Name"; Text[250])
        {
            Caption = 'Schema Name';
        }
        field(10681; "Schema Location"; Text[250])
        {
            Caption = 'Schema Location';
        }
        field(10682; xmlns; Text[250])
        {
            Caption = 'xmlns';
        }
        field(10683; "Customization ID"; Text[250])
        {
            Caption = 'Customization ID';
        }
        field(10684; "Profile ID"; Text[250])
        {
            Caption = 'Profile ID';
        }
        field(10685; "Uses Common Aggregate Comp."; Boolean)
        {
            Caption = 'Uses Common Aggregate Comp.';
        }
        field(10686; "Uses Common Basic Comp."; Boolean)
        {
            Caption = 'Uses Common Basic Comp.';
        }
        field(10687; "Uses Common Extension Comp."; Boolean)
        {
            Caption = 'Uses Common Extension Comp.';
        }
        field(10688; "Legal Taxable Amount"; Decimal)
        {
            Caption = 'Legal Taxable Amount';
        }
        field(10689; "Total Amount"; Decimal)
        {
            Caption = 'Total Amount';
        }
        field(10690; "Total Invoice Discount Amount"; Decimal)
        {
            Caption = 'Total Invoice Discount Amount';
        }
        field(10691; "Quantity Name"; Text[50])
        {
            Caption = 'Quantity Name';
        }
        field(10692; "Sales Line Found"; Boolean)
        {
            Caption = 'Sales Line Found';
        }
        field(10693; "Tax Amount"; Decimal)
        {
            Caption = 'Tax Amount';
        }
        field(10694; "Total Rounding Amount"; Decimal)
        {
            Caption = 'Total Rounding Amount';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

