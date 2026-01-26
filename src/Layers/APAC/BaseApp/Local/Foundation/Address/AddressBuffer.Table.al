// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

table 28002 "Address Buffer"
{
    Caption = 'Address Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Integer)
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; Name; Text[100])
        {
            Caption = 'Name';
            DataClassification = SystemMetadata;
        }
        field(3; "Name 2"; Text[90])
        {
            Caption = 'Name 2';
            DataClassification = SystemMetadata;
        }
        field(4; Contact; Text[100])
        {
            Caption = 'Contact';
            DataClassification = SystemMetadata;
        }
        field(5; Address; Text[100])
        {
            Caption = 'Address';
            DataClassification = SystemMetadata;
        }
        field(6; "Address 2"; Text[90])
        {
            Caption = 'Address 2';
            DataClassification = SystemMetadata;
        }
        field(7; City; Text[90])
        {
            Caption = 'City';
            DataClassification = SystemMetadata;
        }
        field(8; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            DataClassification = SystemMetadata;
        }
        field(9; County; Text[90])
        {
            Caption = 'County';
            DataClassification = SystemMetadata;
        }
        field(10; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
            DataClassification = SystemMetadata;
        }
        field(11; "Address ID"; Text[10])
        {
            Caption = 'Address ID';
            DataClassification = SystemMetadata;
            Numeric = true;
        }
        field(12; "Bar Code"; Text[100])
        {
            Caption = 'Bar Code';
            DataClassification = SystemMetadata;
        }
        field(13; "Address Sort Plan"; Text[10])
        {
            Caption = 'Address Sort Plan';
            DataClassification = SystemMetadata;
            Numeric = true;
        }
        field(14; "Error Flag No."; Text[2])
        {
            Caption = 'Error Flag No.';
            DataClassification = SystemMetadata;
        }
        field(19; "Bar Code System"; Option)
        {
            Caption = 'Bar Code System';
            DataClassification = SystemMetadata;
            OptionCaption = ',4-State Bar Code';
            OptionMembers = ,"4-State Bar Code";
        }
        field(20; "Validation Type"; Option)
        {
            Caption = 'Validation Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,GUI Only,GUI Optional,No GUI';
            OptionMembers = " ","GUI Only","GUI Optional","No GUI";
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

