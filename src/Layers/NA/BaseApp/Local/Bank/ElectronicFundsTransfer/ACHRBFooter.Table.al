// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using System.IO;

table 10305 "ACH RB Footer"
{
    Caption = 'ACH RB Footer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Record Count"; Integer)
        {
            Caption = 'Record Count';
        }
        field(3; "Record Type"; Text[10])
        {
            Caption = 'Record Type';
        }
        field(4; "Transaction Code"; Text[10])
        {
            Caption = 'Transaction Code';
        }
        field(5; "Client Number"; Text[30])
        {
            Caption = 'Client Number';
        }
        field(6; "Credit Payment Transactions"; Integer)
        {
            Caption = 'Credit Payment Transactions';
        }
        field(7; "Total File Credit"; Decimal)
        {
            Caption = 'Total File Credit';
        }
        field(8; "Zero Fill"; Integer)
        {
            Caption = 'Zero Fill';
        }
        field(9; "Number of Cust Info Records"; Integer)
        {
            Caption = 'Number of Cust Info Records';
        }
        field(10; "File Creation Number"; Integer)
        {
            Caption = 'File Creation Number';
        }
    }

    keys
    {
        key(Key1; "Data Exch. Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

