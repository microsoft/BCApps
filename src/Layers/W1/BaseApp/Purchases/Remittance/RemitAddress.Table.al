// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Remittance;

using Microsoft.EServices.OnlineMap;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Vendor;
using System.Email;

table 2224 "Remit Address"
{
    Caption = 'Remit Address';
    DataCaptionFields = "Vendor No.", Name, "Code";
    LookupPageID = "Remit Address List";
    DrillDownPageID = "Remit Address List";
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies an remit-to address code.';
            NotBlank = true;
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the company name for the remit address.';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
            ToolTip = 'Specifies the remit address.';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        field(7; City; Text[30])
        {
            Caption = 'City';
            ToolTip = 'Specifies the city of the remit address.';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

#pragma warning disable AA0139
            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;
#pragma warning restore AA0139

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCity(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; Contact; Text[100])
        {
            Caption = 'Contact';
            ToolTip = 'Specifies the name of the person you regularly contact when you do business with this vendor at this address.';
        }
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ToolTip = 'Specifies the telephone number that is associated with the remit address.';
            ExtendedDatatype = PhoneNo;
        }
        field(10; Default; Boolean)
        {
            Caption = 'Default Address';
            ToolTip = 'Specifies if this address is used by default for this vendor. Only one address can be set as the default.';
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            ToolTip = 'Specifies the country/region of the address.';
            TableRelation = "Country/Region";

#pragma warning disable AA0139
            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
#pragma warning restore AA0139
        }
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
            ToolTip = 'Specifies the fax number associated with the address.';
        }
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            ToolTip = 'Specifies the postal code.';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

#pragma warning disable AA0139
            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;
#pragma warning restore AA0139

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidatePostCode(Rec, PostCode, CurrFieldNo, IsHandled);
                if not IsHandled then
                    PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(92; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
            ToolTip = 'Specifies the county of the address.';
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ToolTip = 'Specifies the email address associated with the remit address.';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
#pragma warning disable AA0139
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
#pragma warning restore AA0139
        }
#if not CLEAN27
#pragma warning disable AS0086
#endif
        field(103; "Home Page"; Text[255])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Home Page';
            ToolTip = 'Specifies the recipient''s web site.';
            ExtendedDatatype = URL;
        }
    }

    keys
    {
        key(Key1; "Code", "Vendor No.")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        Vend.Get("Vendor No.");
        Name := Vend.Name;
    end;

    var
        Vend: Record Vendor;
        PostCode: Record "Post Code";
        UntitledLbl: Label 'Untitled';
        CaptionInformationLbl: Label '%1 %2 %3 %4', Comment = '%1 = Vendor No, %2 = Vendor Name, %3 = Code, %4 = Name';

    procedure Caption(): Text
    begin
        if "Vendor No." = '' then
            exit(UntitledLbl);
        Vend.Get("Vendor No.");
        exit(StrSubstNo(CaptionInformationLbl, Vend."No.", Vend.Name, Code, Name));
    end;

#pragma warning disable AA0139
    procedure DisplayMap()
    var
        OnlineMapManagement: Codeunit "Online Map Management";
    begin
        OnlineMapManagement.MakeSelectionIfMapEnabled(Database::"Remit Address", GetPosition());
    end;
#pragma warning restore AA0139

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var RemitAddress: Record "Remit Address"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var RemitAddress: Record "Remit Address"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
}
