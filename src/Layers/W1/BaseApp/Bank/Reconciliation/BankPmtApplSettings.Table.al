// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

table 1253 "Bank Pmt. Appl. Settings"
{
    Caption = 'Bank Payment Application Settings';
    DataClassification = CustomerContent;

    fields
    {
        field(1; PrimaryKey; Code[20])
        {
            DataClassification = SystemMetadata;
        }

        field(3; "Vendor Ledger Entries Matching"; Boolean)
        {
        }

        field(4; "Cust. Ledger Entries Matching"; Boolean)
        {
        }

        field(5; "Bank Ledger Entries Matching"; Boolean)
        {
        }

        field(6; "RelatedParty Name Matching"; Enum "Pmt. Appl. Related Party Name Matching")
        {
        }

        field(7; "Bank Ledg Closing Doc No Match"; boolean)
        {
        }

        field(8; "Apply Man. Disable Suggestions"; boolean)
        {
        }

        field(9; "Enable Apply Immediatelly"; boolean)
        {
        }
        field(10; "Empl. Ledger Entries Matching"; Boolean)
        {
        }
        field(11; "Vend Ledg Hidden In Apply Man"; Boolean)
        {
        }
        field(12; "Cust Ledg Hidden In Apply Man"; Boolean)
        {
        }
        field(13; "Bank Ledg Hidden In Apply Man"; Boolean)
        {
        }
        field(14; "Empl Ledg Hidden In Apply Man"; Boolean)
        {
        }

    }

    keys
    {
        key(Key1; PrimaryKey)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetOrInsert()
    begin
        if Get('') then
            exit;

        "Vendor Ledger Entries Matching" := true;
        "Cust. Ledger Entries Matching" := true;
        "Bank Ledger Entries Matching" := true;
        "Empl. Ledger Entries Matching" := true;
        "Bank Ledg Closing Doc No Match" := false;
        Insert(true);
    end;
}

