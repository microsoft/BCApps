// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using System.IO;

table 10302 "ACH US Footer"
{
    Caption = 'ACH US Footer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Entry Addenda Count"; Integer)
        {
            Caption = 'Entry Addenda Count';
            Description = 'Detail + Addenda Count';
            TableRelation = "ACH US Detail"."Data Exch. Entry No.";
        }
        field(3; "File Hash Total"; Decimal)
        {
            Caption = 'File Hash Total';
            Description = 'File Hash Total';
        }
        field(4; "Total File Debit Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Total File Debit Amount';
            Description = 'Total File Debit Amount';
        }
        field(5; "Total File Credit Amount"; Decimal)
        {
            BlankZero = true;
            Caption = 'Total File Credit Amount';
            Description = 'Total File Credit Amount';
        }
        field(6; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            Description = 'Checkbook Electronic Funds Transfer Master EFT Company Name';
        }
        field(7; "Filler/Reserved"; Text[30])
        {
            Caption = 'Filler/Reserved';
            FieldClass = Normal;
        }
        field(9; "Transit Routing Number"; Text[30])
        {
            Caption = 'Transit Routing Number';
            Description = 'Checkbook Electronic Funds Transfer Master EFT Transit Routing Number';
        }
        field(10; "File Record Type"; Integer)
        {
            Caption = 'File Record Type';
            Description = 'File Footer Record Type';
        }
        field(13; "Service Class Code"; Text[30])
        {
            Caption = 'Service Class Code';
            Description = 'Checkbook Electronic Funds Transfer Master EFT Service Class Code';
        }
        field(14; "Batch Number"; Integer)
        {
            Caption = 'Batch Number';
        }
        field(15; "Batch Count"; Integer)
        {
            Caption = 'Batch Count';
            Description = 'Batch Count';
            FieldClass = Normal;
        }
        field(16; "Block Count"; Integer)
        {
            Caption = 'Block Count';
            Description = 'Block Count';
            FieldClass = Normal;
        }
        field(17; "Total Batch Debit Amount"; Decimal)
        {
            Caption = 'Total Batch Debit Amount';
            Description = 'Total Batch Debit Amount';
        }
        field(18; "Total Batch Credit Amount"; Decimal)
        {
            Caption = 'Total Batch Credit Amount';
            Description = 'Total Batch Credit Amount';
        }
        field(19; "Federal ID No."; Text[30])
        {
            Caption = 'Federal ID No.';
        }
        field(20; "Batch Hash Total"; Decimal)
        {
            Caption = 'Batch Hash Total';
            Description = 'Batch Hash Total';
        }
        field(21; "Batch Record Type"; Integer)
        {
            Caption = 'Batch Record Type';
            Description = 'Batch Footer Record Type';
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

