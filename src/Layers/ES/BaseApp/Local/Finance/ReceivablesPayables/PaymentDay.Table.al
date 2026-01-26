// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

table 10701 "Payment Day"
{
    Caption = 'Payment Day';
    DrillDownPageID = "Payment Days";
    LookupPageID = "Payment Days";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table Name"; Option)
        {
            Caption = 'Table Name';
            OptionCaption = 'Company Information,Customer,Vendor';
            OptionMembers = "Company Information",Customer,Vendor;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; "Day of the month"; Integer)
        {
            Caption = 'Day of the month';
            MaxValue = 31;
            MinValue = 1;
        }
    }

    keys
    {
        key(Key1; "Table Name", "Code", "Day of the month")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

