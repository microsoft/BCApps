// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 10732 "Customer/Vendor Warning 349"
{
    Caption = 'Customer/Vendor Warning 349';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            Editable = false;
        }
        field(2; "Include Correction"; Boolean)
        {
            Caption = 'Include Correction';
        }
        field(3; Type; Option)
        {
            Caption = 'Type';
            Editable = false;
            OptionCaption = ' ,Purchase,Sale';
            OptionMembers = " ",Purchase,Sale;
        }
        field(4; "Customer/Vendor No."; Code[20])
        {
            Caption = 'Customer/Vendor No.';
            Editable = false;
            TableRelation = if (Type = const(Purchase)) Vendor
            else
            if (Type = const(Sale)) Customer;
        }
        field(5; "Customer/Vendor Name"; Text[100])
        {
            Caption = 'Customer/Vendor Name';
            Editable = false;
            FieldClass = Normal;
        }
        field(6; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            Editable = false;
        }
        field(7; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            Editable = false;
        }
        field(8; "Previous Declared Amount"; Decimal)
        {
            Caption = 'Previous Declared Amount';
            Editable = false;
        }
        field(9; "Original Declaration FY"; Code[4])
        {
            Caption = 'Original Declaration FY';
            Numeric = true;
        }
        field(10; "Original Declaration Period"; Code[2])
        {
            Caption = 'Original Declaration Period';
        }
        field(11; "Original Declared Amount"; Decimal)
        {
            Caption = 'Original Declared Amount';

            trigger OnValidate()
            begin
                if not "Include Correction" then
                    Error(Text1100000, FieldCaption("Include Correction"), FieldCaption("Original Declared Amount"));
            end;
        }
        field(12; Sign; Text[1])
        {
            Caption = 'Sign';
            Editable = false;
        }
        field(13; Exported; Boolean)
        {
            Caption = 'Exported';
        }
        field(14; "VAT Entry No."; Integer)
        {
            Caption = 'VAT Entry No.';
            TableRelation = "VAT Entry";
        }
        field(15; "Delivery Operation Code"; Option)
        {
            Caption = 'Delivery Operation Code';
            OptionCaption = ' ,E - General,M - Imported Tax Exempt,H - Imported Tax Exempt (Representative)';
            OptionMembers = " ","E - General","M - Imported Tax Exempt","H - Imported Tax Exempt (Representative)";
        }
        field(10700; "EU 3-Party Trade"; Boolean)
        {
            Caption = 'EU 3-Party Trade';
            Editable = false;
        }
        field(10701; "EU Service"; Boolean)
        {
            Caption = 'EU Service';
            Editable = false;
        }
        field(10702; "VAT Reporting Date"; Date)
        {
            Caption = 'VAT Date';
        }
        field(10740; "No Taxable Entry No."; Integer)
        {
            Caption = 'No Taxable Entry No.';
            TableRelation = "No Taxable Entry";
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text1100000: Label '%1 should be TRUE in order to modify the %2 for this line.';
}

