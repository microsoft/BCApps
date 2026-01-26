// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Company;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;
using Microsoft.Inventory.Intrastat;
using Microsoft.Utilities;

table 12159 "Company Officials"
{
    Caption = 'Company Officials';
    DataCaptionFields = "No.", "First Name", "Middle Name", "Last Name";
    DrillDownPageID = "Company Officials";
    LookupPageID = "Company Officials";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';

            trigger OnValidate()
            var
                NoSeries: Codeunit "No. Series";
            begin
                if "No." <> xRec."No." then begin
                    GLSetup.Get();
                    NoSeries.TestManual(GLSetup."Company Officials Nos.");
                    "No. Series" := '';
                end;
            end;
        }
        field(2; "First Name"; Text[30])
        {
            Caption = 'First Name';
        }
        field(3; "Middle Name"; Text[30])
        {
            Caption = 'Middle Name';
        }
        field(4; "Last Name"; Text[30])
        {
            Caption = 'Last Name';
        }
        field(5; Initials; Text[30])
        {
            Caption = 'Initials';

            trigger OnValidate()
            begin
                if ("Search Name" = UpperCase(xRec.Initials)) or ("Search Name" = '') then
                    "Search Name" := Initials;
            end;
        }
        field(6; "Job Title"; Text[30])
        {
            Caption = 'Job Title';
        }
        field(7; "Search Name"; Code[30])
        {
            Caption = 'Search Name';
        }
        field(8; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(9; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(10; City; Text[30])
        {
            Caption = 'City';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".City
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".City where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(11; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = if ("Country/Region Code" = const('')) "Post Code".Code
            else
            if ("Country/Region Code" = filter(<> '')) "Post Code".Code where("Country/Region Code" = field("Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(12; County; Text[30])
        {
            Caption = 'County';
        }
        field(13; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
        }
        field(14; "Mobile Phone No."; Text[30])
        {
            Caption = 'Mobile Phone No.';
        }
        field(15; "E-Mail"; Text[80])
        {
            Caption = 'E-Mail';
        }
#if not CLEANSCHEMA28
        field(19; Picture; BLOB)
        {
            Caption = 'Picture';
            SubType = Bitmap;
            ObsoleteReason = 'If you need a picture field, consider adding your own image field of type Media and use an upgrade codeunit to transfer the value.';
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
        }
#endif
        field(25; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(40; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(46; Extension; Text[30])
        {
            Caption = 'Extension';
        }
        field(48; Pager; Text[30])
        {
            Caption = 'Pager';
        }
        field(49; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(53; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            Editable = false;
            TableRelation = "No. Series";
        }
        field(55; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = Employee;

            trigger OnValidate()
            begin
                if Employee.Get("Employee No.") then begin
                    "First Name" := Employee."First Name";
                    "Middle Name" := Employee."Middle Name";
                    "Last Name" := Employee."Last Name";
                    Initials := Employee.Initials;
                    "Job Title" := Employee."Job Title";
                    "Search Name" := CopyStr(Employee."Search Name", 1, MaxStrLen("Search Name"));
                    Address := Employee.Address;
                    "Address 2" := Employee."Address 2";
                    City := Employee.City;
                    "Post Code" := Employee."Post Code";
                    County := Employee.County;
                    "Phone No." := Employee."Phone No.";
                    "Mobile Phone No." := Employee."Mobile Phone No.";
                    "E-Mail" := Employee."E-Mail";
                    "Country/Region Code" := Employee."Country/Region Code";
                    "Last Date Modified" := Employee."Last Date Modified";
                    Extension := Employee.Extension;
                    Pager := Employee.Pager;
                    "Fax No." := Employee."Fax No.";
                    "No. Series" := Employee."No. Series";
                    case Employee.Gender of
                        "Employee Gender"::Female:
                            Gender := Gender::Female;
                        "Employee Gender"::Male:
                            Gender := Gender::Male;
                    end;
                end;
            end;
        }
        field(56; "Area"; Code[10])
        {
            Caption = 'Area';
            TableRelation = Area;
        }
        field(57; "Fiscal Code"; Code[20])
        {
            Caption = 'Fiscal Code';
        }
        field(58; "Appointment Code"; Code[2])
        {
            Caption = 'Appointment Code';
            TableRelation = "Appointment Code";
        }
        field(60; "Date of Birth"; Date)
        {
            Caption = 'Date of Birth';
        }
        field(61; "Birth City"; Text[30])
        {
            Caption = 'Birth City';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidateCity(
                  "Birth City", "Birth Post Code", "Birth County", "Birth Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(62; "Birth Post Code"; Code[20])
        {
            Caption = 'Birth Post Code';
            TableRelation = if ("Birth Country/Region Code" = const('')) "Post Code"
            else
            if ("Birth Country/Region Code" = filter(<> '')) "Post Code" where("Country/Region Code" = field("Birth Country/Region Code"));
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(
                  "Birth City", "Birth Post Code", "Birth County", "Birth Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(63; "Birth County"; Text[30])
        {
            Caption = 'Birth County';
        }
        field(64; "Birth Country/Region Code"; Code[10])
        {
            Caption = 'Birth Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(65; Gender; Option)
        {
            Caption = 'Gender';
            OptionCaption = ' ,Male,Female';
            OptionMembers = " ",Male,Female;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Search Name")
        {
        }
        key(Key3; "Last Name", "First Name", "Middle Name")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        NoSeries: Codeunit "No. Series";
    begin
        if "No." = '' then begin
            GLSetup.Get();
            GLSetup.TestField("Company Officials Nos.");
                "No. Series" := GLSetup."Company Officials Nos.";
                if NoSeries.AreRelated("No. Series", xRec."No. Series") then
                    "No. Series" := xRec."No. Series";
                "No." := NoSeries.GetNextNo("No. Series");
        end;
    end;

    trigger OnModify()
    begin
        "Last Date Modified" := Today;
    end;

    trigger OnRename()
    begin
        "Last Date Modified" := Today;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        Employee: Record Employee;
        PostCode: Record "Post Code";
        CompanyOfficials: Record "Company Officials";

    [Scope('OnPrem')]
    procedure AssistEdit(CompanyOfficials2: Record "Company Officials"): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        CompanyOfficials := Rec;
        GLSetup.Get();
        GLSetup.TestField("Company Officials Nos.");
        if NoSeries.LookupRelatedNoSeries(GLSetup."Company Officials Nos.", CompanyOfficials2."No. Series", CompanyOfficials."No. Series") then begin
            CompanyOfficials."No." := NoSeries.GetNextNo(CompanyOfficials."No. Series");
            Rec := CompanyOfficials;
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure FullName(): Text[100]
    begin
        if "Middle Name" = '' then
            exit("First Name" + ' ' + "Last Name");
        exit("First Name" + ' ' + "Middle Name" + ' ' + "Last Name");
    end;
}