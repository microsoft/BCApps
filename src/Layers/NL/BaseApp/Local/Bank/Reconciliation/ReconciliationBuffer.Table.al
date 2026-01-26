// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

table 11000008 "Reconciliation Buffer"
{
    Caption = 'Reconciliation Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Word; Code[40])
        {
            Caption = 'Word';
            DataClassification = SystemMetadata;
        }
        field(2; "Source Type"; Option)
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Customer,Vendor,Payment History,Employee';
            OptionMembers = " ",Customer,Vendor,"Payment History",Employee;
        }
        field(3; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            DataClassification = SystemMetadata;
        }
        field(4; "Data Type"; Option)
        {
            Caption = 'Data Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Sundries,Name,Street,City,Bankaccount,Identification';
            OptionMembers = Sundries,Name,Street,City,Bankaccount,Identification;
        }
    }

    keys
    {
        key(Key1; Word, "Source Type", "Source No.", "Data Type")
        {
            Clustered = true;
        }
        key(Key2; "Source Type", "Source No.")
        {
        }
    }

    fieldgroups
    {
    }
}

