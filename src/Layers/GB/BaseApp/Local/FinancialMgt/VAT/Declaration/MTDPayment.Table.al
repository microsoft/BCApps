#if not CLEANSCHEMA28 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

table 10534 "MTD-Payment"
{
    Caption = 'VAT Payment';
    ObsoleteReason = 'Moved to extension';
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Start Date"; Date)
        {
            Caption = 'Start Date';
        }
        field(2; "End Date"; Date)
        {
            Caption = 'End Date';
        }
        field(3; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(4; "Received Date"; Date)
        {
            Caption = 'Received Date';
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
        }
    }

    keys
    {
        key(Key1; "Start Date", "End Date", "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

 
#endif