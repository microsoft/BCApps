// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.Foundation.Address;
using Microsoft.HumanResources.Comment;
using System.Email;

table 5201 "Alternative Address"
{
    Caption = 'Alternative Address';
    DataCaptionFields = "Employee No.", Name, "Code";
    DrillDownPageID = "Alternative Address List";
    LookupPageID = "Alternative Address List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            NotBlank = true;
            TableRelation = Employee;

            trigger OnValidate()
            begin
                Employee.Get("Employee No.");
                Name := Employee."Last Name";
            end;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies a code for the employee''s alternate address.';
            NotBlank = true;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the employee''s last name.';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
            ToolTip = 'Specifies the employee''s first name, or an alternate name.';
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
            ToolTip = 'Specifies an alternate address for the employee.';
        }
        field(6; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
            ToolTip = 'Specifies additional address information.';
        }
        field(7; City; Text[30])
        {
            Caption = 'City';
            ToolTip = 'Specifies the city of the alternate address.';
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
        field(8; "Post Code"; Code[20])
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
        field(9; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country/Region Code";
            Caption = 'County';
            ToolTip = 'Specifies the county of the employee''s alternate address.';
        }
        field(10; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ToolTip = 'Specifies the employee''s telephone number at the alternate address.';
            ExtendedDatatype = PhoneNo;
        }
        field(11; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
            ToolTip = 'Specifies the employee''s fax number at the alternate address.';
        }
        field(12; "E-Mail"; Text[80])
        {
            Caption = 'Email';
            ToolTip = 'Specifies the employee''s alternate email address.';
            ExtendedDatatype = EMail;

            trigger OnValidate()
            var
                MailManagement: Codeunit "Mail Management";
            begin
                MailManagement.ValidateEmailAddressField("E-Mail");
            end;
        }
        field(13; Comment; Boolean)
        {
            CalcFormula = exist("Human Resource Comment Line" where("Table Name" = const("Alternative Address"),
                                                                     "No." = field("Employee No."),
                                                                     "Alternative Address Code" = field(Code)));
            Caption = 'Comment';
            ToolTip = 'Specifies if a comment was entered for this entry.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            ToolTip = 'Specifies the country/region of the address.';
            TableRelation = "Country/Region";

            trigger OnValidate()
            begin
                PostCode.CheckClearPostCodeCityCounty(City, "Post Code", County, "Country/Region Code", xRec."Country/Region Code");
            end;
        }
    }

    keys
    {
        key(Key1; "Employee No.", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PostCode: Record "Post Code";
        Employee: Record Employee;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCity(var AlternativeAddress: Record "Alternative Address"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidatePostCode(var AlternativeAddress: Record "Alternative Address"; var PostCode: Record "Post Code"; CurrentFieldNo: Integer; var IsHandled: Boolean);
    begin
    end;
}

