// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Address;

table 11407 "Post Code Update Log Entry"
{
    Caption = 'Post Code Update Log Entry';
    DrillDownPageID = "Post Code Updates";
    LookupPageID = "Post Code Updates";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(10; Date; Date)
        {
            Caption = 'Date';
        }
        field(20; Time; Time)
        {
            Caption = 'Time';
        }
        field(30; "User ID"; Code[50])
        {
            Caption = 'User ID';
        }
        field(50; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
        }
        field(60; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = 'Full Data Set,Update';
            OptionMembers = "Full Data Set",Update;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; Type)
        {
        }
    }

    fieldgroups
    {
    }
}

