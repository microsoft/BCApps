// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Setup;

using Microsoft.Finance.GeneralLedger.Account;

table 347 "Close Income Statement Buffer"
{
    Caption = 'Close Income Statement Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Closing Date"; Date)
        {
            Caption = 'Closing Date';
            DataClassification = SystemMetadata;
        }
        field(2; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            DataClassification = SystemMetadata;
            TableRelation = "G/L Account";
        }
    }

    keys
    {
        key(Key1; "Closing Date", "G/L Account No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

