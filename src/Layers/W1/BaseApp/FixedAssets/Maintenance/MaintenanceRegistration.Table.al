// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Maintenance;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Purchases.Vendor;

table 5616 "Maintenance Registration"
{
    Caption = 'Maintenance Registration';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "FA No."; Code[20])
        {
            Caption = 'FA No.';
            NotBlank = true;
            TableRelation = "Fixed Asset";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Service Date"; Date)
        {
            Caption = 'Service Date';
        }
        field(4; "Maintenance Vendor No."; Code[20])
        {
            Caption = 'Maintenance Vendor No.';
            TableRelation = Vendor;
        }
        field(5; Comment; Text[50])
        {
            Caption = 'Comment';
        }
        field(6; "Service Agent Name"; Text[30])
        {
            Caption = 'Service Agent Name';
        }
        field(7; "Service Agent Phone No."; Text[30])
        {
            Caption = 'Service Agent Phone No.';
            ExtendedDatatype = PhoneNo;
        }
        field(8; "Service Agent Mobile Phone"; Text[30])
        {
            Caption = 'Service Agent Mobile Phone';
            ExtendedDatatype = PhoneNo;
        }
    }

    keys
    {
        key(Key1; "FA No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        FA.LockTable();
        FA.Get("FA No.");
    end;

    var
        FA: Record "Fixed Asset";
}

