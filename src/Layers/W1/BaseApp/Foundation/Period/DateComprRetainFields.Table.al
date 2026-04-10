// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Period;

table 9041 "Date Compr. Retain Fields"
{
    Access = Public;
    Extensible = true;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[20])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Retain Document Type"; Boolean)
        {
            Caption = 'Retain Document Type';
            DataClassification = SystemMetadata;
        }
        field(3; "Retain Document No."; Boolean)
        {
            Caption = 'Retain Document No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Retain Job No."; Boolean)
        {
            Caption = 'Retain Job No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Retain Business Unit Code"; Boolean)
        {
            Caption = 'Retain Business Unit Code';
            DataClassification = SystemMetadata;
        }
        field(6; "Retain Journal Template Name"; Boolean)
        {
            Caption = 'Retain Journal Template Name';
            DataClassification = SystemMetadata;
        }
        field(7; "Retain Contact Code"; Boolean)
        {
            Caption = 'Retain Contact Code';
            DataClassification = SystemMetadata;
        }
        field(8; "Retain Salesperson Code"; Boolean)
        {
            Caption = 'Retain Salesperson Code';
            DataClassification = SystemMetadata;
        }
        field(9; "Retain Sell-to Customer No."; Boolean)
        {
            Caption = 'Retain Sell-to Customer No.';
            DataClassification = SystemMetadata;
        }
        field(10; "Retain Buy-from Vendor No."; Boolean)
        {
            Caption = 'Retain Buy-from Vendor No."';
            DataClassification = SystemMetadata;
        }
        field(11; "Retain Purchaser Code"; Boolean)
        {
            Caption = 'Retain Purchaser Code';
            DataClassification = SystemMetadata;
        }
        field(12; "Retain Bill-to/Pay-to No."; Boolean)
        {
            Caption = 'Retain Bill-to/Pay-to No.';
            DataClassification = SystemMetadata;
        }
        field(13; "Retain EU 3-Party Trade"; Boolean)
        {
            Caption = 'Retain EU 3-Party Trade';
            DataClassification = SystemMetadata;
        }
        field(14; "Retain Country/Region Code"; Boolean)
        {
            Caption = 'Retain Country/Region Code';
            DataClassification = SystemMetadata;
        }
        field(15; "Retain Internal Ref. No."; Boolean)
        {
            Caption = 'Retain Internal Ref. No.';
            DataClassification = SystemMetadata;
        }
        field(16; "Retain Quantity"; Boolean)
        {
            Caption = 'Retain Quantity';
            DataClassification = SystemMetadata;
        }
        field(18; "Retain Global Dimension 1"; Boolean)
        {
            Caption = 'Retain Global Dimension 1';
            DataClassification = SystemMetadata;
        }
        field(19; "Retain Global Dimension 2"; Boolean)
        {
            Caption = 'Retain Global Dimension 2';
            DataClassification = SystemMetadata;
        }
        field(20; "Retain Totals"; Boolean)
        {
            Caption = 'Retain Totals';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
