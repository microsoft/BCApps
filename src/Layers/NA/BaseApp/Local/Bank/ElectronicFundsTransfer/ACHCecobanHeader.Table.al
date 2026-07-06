// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using System.IO;

table 10306 "ACH Cecoban Header"
{
    Caption = 'ACH Cecoban Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Sequence No"; Integer)
        {
            Caption = 'Sequence No';
        }
        field(3; "Operation Code"; Integer)
        {
            Caption = 'Operation Code';
        }
        field(4; "Bank Account No"; Text[30])
        {
            Caption = 'Bank Account No';
        }
        field(5; Service; Integer)
        {
            Caption = 'Service';
        }
        field(6; "Export Type"; Text[30])
        {
            Caption = 'Export Type';
        }
        field(7; "Batch Day"; Integer)
        {
            Caption = 'Batch Day';
        }
        field(8; "Batch No"; Integer)
        {
            Caption = 'Batch No';
        }
        field(9; "Settlement Date"; Date)
        {
            Caption = 'Settlement Date';
        }
        field(10; "Rejection Code"; Integer)
        {
            Caption = 'Rejection Code';
        }
        field(11; System; Integer)
        {
            Caption = 'System';
        }
        field(12; "Future Cecoban Use"; Text[50])
        {
            Caption = 'Future Cecoban Use';
        }
        field(13; "Future Bank Use"; Text[250])
        {
            Caption = 'Future Bank Use';
        }
        field(14; "Record Type"; Text[30])
        {
            Caption = 'Record Type';
        }
        field(15; "Currency Code"; Text[10])
        {
            Caption = 'Currency Code';
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

