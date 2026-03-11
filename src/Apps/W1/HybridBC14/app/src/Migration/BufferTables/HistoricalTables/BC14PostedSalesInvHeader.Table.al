// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.DataMigration.BC14;

table 50180 "BC14 Posted Sales Inv Header"
{
    Caption = 'BC14 Posted Sales Invoice Header';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
        }
        field(3; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
        }
        field(4; "Bill-to Customer No."; Code[20])
        {
            Caption = 'Bill-to Customer No.';
        }
        field(5; "Bill-to Name"; Text[100])
        {
            Caption = 'Bill-to Name';
        }
        field(6; "Bill-to Address"; Text[100])
        {
            Caption = 'Bill-to Address';
        }
        field(7; "Bill-to City"; Text[30])
        {
            Caption = 'Bill-to City';
        }
        field(8; "Bill-to Post Code"; Code[20])
        {
            Caption = 'Bill-to Post Code';
        }
        field(9; "Bill-to Country/Region Code"; Code[10])
        {
            Caption = 'Bill-to Country/Region Code';
        }
        field(10; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(11; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(12; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(13; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(14; "Your Reference"; Text[35])
        {
            Caption = 'Your Reference';
        }
        field(20; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(21; "Currency Factor"; Decimal)
        {
            Caption = 'Currency Factor';
            DecimalPlaces = 0 : 15;
            AutoFormatType = 0;
            AutoFormatExpression = '<Precision,0:15><Standard Format,0>';
        }
        field(30; "Salesperson Code"; Code[20])
        {
            Caption = 'Salesperson Code';
        }
        field(31; "Shortcut Dimension 1 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 1 Code';
        }
        field(32; "Shortcut Dimension 2 Code"; Code[20])
        {
            Caption = 'Shortcut Dimension 2 Code';
        }
        field(40; "Payment Terms Code"; Code[10])
        {
            Caption = 'Payment Terms Code';
        }
        field(41; "Payment Method Code"; Code[10])
        {
            Caption = 'Payment Method Code';
        }
        field(50; "Ship-to Name"; Text[100])
        {
            Caption = 'Ship-to Name';
        }
        field(51; "Ship-to Address"; Text[100])
        {
            Caption = 'Ship-to Address';
        }
        field(52; "Ship-to City"; Text[30])
        {
            Caption = 'Ship-to City';
        }
        field(53; "Ship-to Post Code"; Code[20])
        {
            Caption = 'Ship-to Post Code';
        }
        field(54; "Ship-to Country/Region Code"; Code[10])
        {
            Caption = 'Ship-to Country/Region Code';
        }
        field(60; Amount; Decimal)
        {
            Caption = 'Amount';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(61; "Amount Including VAT"; Decimal)
        {
            Caption = 'Amount Including VAT';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(70; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(71; "Pre-Assigned No."; Code[20])
        {
            Caption = 'Pre-Assigned No.';
        }
        field(80; "User ID"; Code[50])
        {
            Caption = 'User ID';
        }
        field(81; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
        }
        field(90; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            AutoFormatType = 1;
            AutoFormatExpression = '<Precision,2:2><Standard Format,0>';
        }
        field(91; Closed; Boolean)
        {
            Caption = 'Closed';
        }
        field(200; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
        }
        field(201; "VAT Bus. Posting Group"; Code[20])
        {
            Caption = 'VAT Bus. Posting Group';
        }
        field(202; "Customer Posting Group"; Code[20])
        {
            Caption = 'Customer Posting Group';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
        key(Customer; "Sell-to Customer No.", "Posting Date")
        {
        }
        key(PostingDate; "Posting Date")
        {
        }
    }
}
