#pragma warning disable AA0247
table 12425 "Company Address"
{
    Caption = 'Company Address';
    LookupPageID = "Company Address List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(3; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(4; "Name 2"; Text[50])
        {
            Caption = 'Name 2';
        }
        field(5; Address; Text[100])
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

            trigger OnValidate()
            begin
                PostCode.ValidateCity(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; Contact; Text[100])
        {
            Caption = 'Contact';
        }
        field(9; "Phone No."; Text[30])
        {
            Caption = 'Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(10; "Telex No."; Text[30])
        {
            Caption = 'Telex No.';
        }
        field(11; "Registration No."; Code[20])
        {
            Caption = 'Registration No.';
        }
        field(12; "Region Code"; Code[10])
        {
            Caption = 'Region Code';
            //The property 'ValidateTableRelation' can only be set if the property 'TableRelation' is set
            //ValidateTableRelation = false;
        }
        field(13; "Region Name"; Text[30])
        {
            Caption = 'Region Name';
        }
        field(14; Settlement; Text[50])
        {
            Caption = 'Settlement';
        }
        field(15; Street; Text[30])
        {
            Caption = 'Street';
        }
        field(16; House; Text[5])
        {
            Caption = 'House';
        }
        field(17; Building; Text[5])
        {
            Caption = 'Building';
        }
        field(18; Apartment; Text[5])
        {
            Caption = 'Apartment';
        }
        field(20; "Address Type"; Option)
        {
            Caption = 'Address Type';
            NotBlank = true;
            OptionCaption = 'Legal,Foreign,High Org.,Tax Inspection,Pension Fund,Medical Fund,Org. Unit';
            OptionMembers = Legal,Foreign,"High Org.","Tax Inspection","Pension Fund","Medical Fund","Org. Unit";
        }
        field(35; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = "Country/Region";
        }
        field(54; "Last Date Modified"; Date)
        {
            Caption = 'Last Date Modified';
            Editable = false;
        }
        field(84; "Fax No."; Text[30])
        {
            Caption = 'Fax No.';
        }
        field(91; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, "Country/Region Code", (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(92; County; Text[30])
        {
            Caption = 'County';
        }
        field(102; "E-Mail"; Text[80])
        {
            Caption = 'E-Mail';
            ExtendedDatatype = EMail;
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
            ExtendedDatatype = URL;
        }
        field(104; OKPO; Code[10])
        {
            Caption = 'OKPO';
        }
        field(105; KPP; Code[10])
        {
            Caption = 'KPP';
        }
        field(106; "Director Phone No."; Text[30])
        {
            Caption = 'Director Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(107; "Accountant Phone No."; Text[30])
        {
            Caption = 'Accountant Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(108; "Additional FSI No."; Code[10])
        {
            Caption = 'Additional FSI No.';
        }
    }

    keys
    {
        key(Key1; "Code", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PostCode: Record "Post Code";
}
