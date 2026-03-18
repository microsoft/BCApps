// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Remittance;

table 2225 "Remit Address Buffer"
{
    Caption = 'Remit Address Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = SystemMetadata;

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
        field(5; County; Text[30])
        {
            Caption = 'County';
        }
        field(6; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
        }
        field(7; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
        }
        field(8; Contact; Text[100])
        {
            Caption = 'Contact';
        }
    }

    keys
    {
        key(Key1; Name, Address, "Post Code")
        {
            Clustered = true;
        }
    }
}

