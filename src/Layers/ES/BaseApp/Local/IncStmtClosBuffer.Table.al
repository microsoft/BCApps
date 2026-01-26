// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

table 10700 "Inc. Stmt. Clos. Buffer"
{
    Caption = 'Inc. Stmt. Clos. Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Account No."; Text[20])
        {
            Caption = 'Account No.';
            DataClassification = SystemMetadata;
        }
        field(2; Amount; Decimal)
        {
            Caption = 'Amount';
            DataClassification = SystemMetadata;
        }
        field(3; "Additional-Currency Amount"; Decimal)
        {
            Caption = 'Additional-Currency Amount';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Account No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

