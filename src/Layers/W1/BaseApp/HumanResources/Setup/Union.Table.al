// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Setup;

using Microsoft.Foundation.Address;
using Microsoft.HumanResources.Employee;
using System.Email;

table 5209 Union
{
    Caption = 'Union';
    DrillDownPageID = Unions;
    LookupPageID = Unions;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a union code.';
            NotBlank = true;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the union.';
        }
        field(3; Address; Text[100])
        {
            Caption = 'Address';
            ToolTip = 'Specifies the union''s address.';
        }
        field(4; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            ToolTip = 'Specifies the postal code.';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code"
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

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
        field(5; City; Text[30])
        {
            Caption = 'City';
            ToolTip = 'Specifies the city of the address.';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnLookup()
            begin
                PostCode.LookupPostCode(City, "Post Code", County, "Country/Region Code");
            end;

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
        field(6; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ToolTip = 'Specifies the union''s telephone number.';
            ExtendedDatatype = PhoneNo;
        }
        field(7; "No. of Members Employed"; Integer)
        {
            CalcFormula = count(Employee where(Status = filter(<> Terminated),
                                                "Union Code" = field(Code)));
            Caption = 'No. of Members Employed';
            ToolTip = 'Specifies the number of members employed.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(8; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(9; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(10; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
        }
        field(11; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(12; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
#if not CLEAN27
#pragma warning disable AS0086
#endif
        field(13; "Home Page"; Text[255])
#if not CLEAN27
#pragma warning restore AS0086
#endif
        {
            Caption = 'Home Page';
            ExtendedDatatype = URL;
        }
        field(14; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PostCode: Record "Post Code";

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var Union: Record Union; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var Union: Record Union; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;
}
