#if not CLEANSCHEMA25 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.Address;
using Microsoft.Purchases.Vendor;

table 7000015 "Vendor Pmt. Address"
{
    Caption = 'Vendor Pmt. Address';
    ObsoleteReason = 'Address is taken from the fields Pay-to Address, Pay-to City, etc.';
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
    DataClassification = CustomerContent;
    ReplicateData = false;

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Name; Text[50])
        {
            Caption = 'Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[50])
        {
            Caption = 'Address';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(7; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(9; County; Text[30])
        {
            Caption = 'County';
        }
        field(10; Contact; Text[50])
        {
            Caption = 'Contact';
        }
        field(11; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(12; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(13; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(14; "Telex No."; Text[30])
        {
            Caption = 'Telex No.';
        }
        field(15; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(16; "Telex Answer Back"; Text[20])
        {
            Caption = 'Telex Answer Back';
        }
        field(17; "E-Mail"; Text[80])
        {
            Caption = 'E-Mail';
            ExtendedDatatype = EMail;
        }
        field(18; "Home Page"; Text[80])
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    var
        Text1100000: Label 'untitled';
        PostCode: Record "Post Code";

    procedure Caption(): Text
    var
        Vend: Record Vendor;
    begin
        if "Vendor No." = '' then
            exit(Text1100000);
        Vend.Get("Vendor No.");
        exit(StrSubstNo('%1 %2 %3 %4', Vend."No.", Vend.Name, Code, Name));
    end;
}

 
#endif
