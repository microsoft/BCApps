// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using System.IO;

table 10308 "ACH Cecoban Footer"
{
    Caption = 'ACH Cecoban Footer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Record Type"; Text[30])
        {
            Caption = 'Record Type';
        }
        field(3; "Sequence Number"; Integer)
        {
            Caption = 'Sequence Number';
        }
        field(4; "Op Code"; Integer)
        {
            Caption = 'Op Code';
        }
        field(5; "Batch Number day of month"; Integer)
        {
            Caption = 'Batch Number day of month';
        }
        field(6; "Batch Number sequence part"; Integer)
        {
            Caption = 'Batch Number sequence part';
        }
        field(7; "Operation Number"; Integer)
        {
            Caption = 'Operation Number';
        }
        field(8; TCO; Decimal)
        {
            Caption = 'TCO';
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

