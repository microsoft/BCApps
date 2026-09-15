// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using System.IO;

table 10303 "ACH RB Header"
{
    Caption = 'ACH RB Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Client Number"; Text[30])
        {
            Caption = 'Client Number';
        }
        field(3; "File Creation Date"; Integer)
        {
            Caption = 'File Creation Date';
            Description = 'File Creation Date';
        }
        field(4; "Record Type"; Text[10])
        {
            Caption = 'Record Type';
        }
        field(5; "Transaction Code"; Text[10])
        {
            Caption = 'Transaction Code';
        }
        field(6; "Client Name"; Text[30])
        {
            Caption = 'Client Name';
        }
        field(7; "File Creation Number"; Integer)
        {
            Caption = 'File Creation Number';
        }
        field(8; "Currency Type"; Text[30])
        {
            Caption = 'Currency Type';
        }
        field(9; "Record Count"; Integer)
        {
            Caption = 'Record Count';
        }
        field(10; "Input Type"; Text[10])
        {
            Caption = 'Input Type';
        }
        field(11; "Federal ID No."; Text[30])
        {
            Caption = 'Federal ID No.';
        }
        field(12; "Input Qualifier"; Code[30])
        {
            Caption = 'Input Qualifier';
        }
        field(13; "Settlement Date"; Date)
        {
            Caption = 'Settlement Date';

            trigger OnValidate()
            var
                ExportEFTRB: Codeunit "Export EFT (RB)";
            begin
                if "Settlement Date" = 0D then
                    "Settlement Julian Date" := 0
                else
                    "Settlement Julian Date" := ExportEFTRB.JulianDate("Settlement Date");
            end;
        }
        field(14; "Settlement Julian Date"; Integer)
        {
            Caption = 'Settlement Julian Date';
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

