// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

table 9090 "Autocomplete Address"
{
    Caption = 'Autocomplete Address';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Text[100])
        {
            Caption = 'Name';
        }
        field(2; Address; Text[100])
        {
            Caption = 'Address';
        }
        field(3; "Address 2"; Text[50])
        {
            Caption = 'Address 2';
        }
        field(4; City; Text[30])
        {
            Caption = 'City';
        }
        field(5; Postcode; Text[20])
        {
            Caption = 'Postcode';
            TableRelation = "Post Code" where("Country/Region Code" = field("Country / Region"));
            ValidateTableRelation = false;
        }
        field(6; "Country / Region"; Text[10])
        {
            Caption = 'Country / Region';
        }
        field(7; County; Text[30])
        {
            CaptionClass = '5,1,' + "Country / Region";
            Caption = 'County';
        }
        field(8; Id; Integer)
        {
            Caption = 'Id';
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

