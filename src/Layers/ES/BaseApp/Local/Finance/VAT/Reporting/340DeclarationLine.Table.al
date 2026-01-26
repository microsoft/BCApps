// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Bank.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Enums;

table 10744 "340 Declaration Line"
{
    Caption = '340 Declaration Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Integer)
        {
            Caption = 'Key';
        }
        field(3; "Fiscal Year"; Text[8])
        {
            Caption = 'Fiscal Year';
        }
        field(4; "VAT Registration No."; Text[9])
        {
            Caption = 'VAT Registration No.';
        }
        field(5; "VAT Number"; Text[9])
        {
            Caption = 'VAT Number';
        }
        field(7; "Customer/Vendor No."; Text[20])
        {
            Caption = 'Customer/Vendor No.';
        }
        field(8; "Customer/Vendor Name"; Text[100])
        {
            Caption = 'Customer/Vendor Name';
        }
        field(9; "Country Code"; Text[10])
        {
            Caption = 'Country Code';
        }
        field(10; "Resident ID"; Text[1])
        {
            Caption = 'Resident ID';
        }
        field(11; "International VAT No."; Text[20])
        {
            Caption = 'International VAT No.';
        }
        field(12; "Book Type Code"; Text[1])
        {
            Caption = 'Book Type Code';
        }
        field(13; "Operation Code"; Code[1])
        {
            Caption = 'Operation Code';
            TableRelation = "Operation Code";

            trigger OnValidate()
            begin
                if "Operation Code" <> 'R' then begin
                    "Property Location" := "Property Location"::" ";
                    "Property Tax Account No." := '';
                end;

                if "Unrealized VAT Entry No." <> 0 then begin
                    if not ("Operation Code" in ['Z', '1' .. '8']) then
                        FieldError("Operation Code")
                end else
                    if "Operation Code" in ['Z', '1' .. '8'] then
                        FieldError("Operation Code");
            end;
        }
        field(14; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(15; "Operation Date"; Text[8])
        {
            Caption = 'Operation Date';
        }
        field(16; "VAT %"; Decimal)
        {
            Caption = 'VAT %';
        }
        field(17; Base; Decimal)
        {
            Caption = 'Base';
        }
        field(21; "Document No."; Text[40])
        {
            Caption = 'Document No.';
        }
        field(22; "Document Type"; Text[30])
        {
            Caption = 'Document Type';
        }
        field(23; "VAT Document No."; Text[18])
        {
            Caption = 'VAT Document No.';
        }
        field(24; "Buffer Value 18"; Text[18])
        {
            Caption = 'Buffer Value 18';
        }
        field(25; "No. of Registers"; Text[2])
        {
            Caption = 'No. of Registers';
        }
        field(27; "Buffer Value 40"; Text[40])
        {
            Caption = 'Buffer Value 40';
        }
        field(28; "Property Location"; Option)
        {
            BlankZero = true;
            Caption = 'Property Location';
            OptionCaption = ' ,Property in Spain,Property in Basque / Navarra,Property W/o Tax number,Property outside Spain';
            OptionMembers = " ","Property in Spain","Property in Basque / Navarra","Property W/o Tax number","Property outside Spain";

            trigger OnValidate()
            begin
                if "Property Location" = "Property Location"::" " then
                    if "Operation Code" = 'R' then
                        Error(Text001);
            end;
        }
        field(29; "Property Tax Account No."; Text[25])
        {
            Caption = 'Property Tax Account No.';

            trigger OnValidate()
            begin
                if "Property Location" = "Property Location"::"Property W/o Tax number" then
                    Error(Text002);
            end;
        }
        field(30; "EC %"; Decimal)
        {
            Caption = 'EC %';
        }
        field(31; "EC Amount"; Decimal)
        {
            Caption = 'EC Amount';
        }
        field(32; "VAT Amount"; Decimal)
        {
            Caption = 'VAT Amount';
        }
        field(33; "VAT Amount / EC Amount"; Decimal)
        {
            Caption = 'VAT Amount / EC Amount';
        }
        field(34; "Amount Including VAT / EC"; Decimal)
        {
            Caption = 'Amount Including VAT / EC';
        }
        field(35; Type; Enum "General Posting Type")
        {
            Caption = 'Type';
        }
        field(36; "Unrealized VAT Entry No."; Integer)
        {
            Caption = 'Unrealized VAT Entry No.';
        }
        field(37; "Bank Account Ledger Entry No."; Integer)
        {
            Caption = 'Bank Account Ledger Entry No.';
            TableRelation = "Bank Account Ledger Entry";
        }
        field(38; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(10705; "VAT Cash Regime"; Boolean)
        {
            Caption = 'VAT Cash Regime';
        }
        field(10706; "Collection Amount"; Decimal)
        {
            Caption = 'Collection Amount';
        }
    }

    keys
    {
        key(Key1; "Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    begin
        if ("Operation Code" = 'R') and (Type = Type::Sale) then
            TestField("Property Location");
        if "Property Location" in ["Property Location"::"Property in Spain", "Property Location"::"Property in Basque / Navarra"] then
            TestField("Property Tax Account No.");
    end;

    var
        Text001: Label 'You cannot select a blank option for operation code R. Select another option for the field.';
        Text002: Label 'You cannot insert property tax account no. for selected property location.';

    [Scope('OnPrem')]
    procedure RemoveDuplicateAmounts()
    var
        VATEntry: Record "VAT Entry";
    begin
        if not "VAT Cash Regime" then
            exit;

        if "Document Type" in
           [Format(VATEntry."Document Type"::Payment),
            Format(VATEntry."Document Type"::Refund),
            Format(VATEntry."Document Type"::Bill)]
        then begin
            "VAT Amount" := 0;
            "VAT Amount / EC Amount" := 0;
            "Amount Including VAT / EC" := 0;
            "VAT %" := 0;
            Base := 0;
            "EC %" := 0;
            "EC Amount" := 0;
        end;
    end;
}

