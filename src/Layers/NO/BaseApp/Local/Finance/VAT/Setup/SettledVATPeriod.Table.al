// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

table 10601 "Settled VAT Period"
{
    Caption = 'Settled VAT Period';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Year; Integer)
        {
            Caption = 'Year';
            MinValue = 1980;
        }
        field(2; "Period No."; Integer)
        {
            BlankZero = true;
            Caption = 'Period No.';
            MinValue = 1;
            TableRelation = "VAT Period"."Period No.";
        }
        field(3; "Settlement Date"; Date)
        {
            Caption = 'Settlement Date';
        }
        field(10; Closed; Boolean)
        {
            Caption = 'Closed';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; Year, "Period No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

