// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using System.IO;

table 10300 "ACH US Header"
{
    Caption = 'ACH US Header';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Priority Code"; Integer)
        {
            Caption = 'Priority Code';
            Description = 'Checkbook Electronic Funds Transfer Master EFT Priority Code';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
            Description = 'Checkbook Electronic Funds Transfer Master EFT Company Name';
        }
        field(3; "Bank Account Number"; Text[30])
        {
            Caption = 'Bank Account Number';
            Description = 'Checkbook Electronic Funds Transfer Master EFT Bank Identification Number';
        }
        field(4; "File Creation Date"; Date)
        {
            Caption = 'File Creation Date';
            Description = 'File Creation Date';
        }
        field(5; "File Creation Time"; Time)
        {
            Caption = 'File Creation Time';
        }
        field(6; "File Record Type"; Integer)
        {
            Caption = 'File Record Type';
            Description = 'File Header Record Type';
        }
        field(7; "Transit Routing Number"; Text[30])
        {
            Caption = 'Transit Routing Number';
            Description = 'Checkbook Electronic Funds Transfer Master EFT Transit Routing Number';
        }
        field(8; "File ID Modifier"; Text[1])
        {
            Caption = 'File ID Modifier';
        }
        field(9; "Record Size"; Integer)
        {
            Caption = 'Record Size';
        }
        field(10; "Blocking Factor"; Integer)
        {
            Caption = 'Blocking Factor';
            Description = 'Checkbook Electronic Funds Transfer Master EFT Blocking Factor';
        }
        field(11; "Format Code"; Integer)
        {
            Caption = 'Format Code';
            Description = 'Checkbook Electronic Funds Transfer Master EFT Format Code';
        }
        field(12; Reference; Code[10])
        {
            Caption = 'Reference';
            Description = 'Checkbook Electronic Funds Transfer Master EFT Reference';
        }
        field(13; "Service Class Code"; Code[10])
        {
            Caption = 'Service Class Code';
            Description = 'Checkbook Electronic Funds Transfer Master EFT Service Class Code';
        }
        field(14; "Small Company Name"; Text[30])
        {
            Caption = 'Small Company Name';
            Description = 'Checkbook Electronic Funds Transfer Master EFT Small Company Name';
        }
        field(15; "Company Discretionary Data"; Text[30])
        {
            Caption = 'Company Discretionary Data';
        }
        field(16; "Standard Class Code"; Code[10])
        {
            Caption = 'Standard Class Code';
        }
        field(17; "Company Entry Description"; Code[10])
        {
            Caption = 'Company Entry Description';
        }
        field(18; "Company Descriptive Date"; Date)
        {
            Caption = 'Company Descriptive Date';
            Description = 'Transmission Date';
        }
        field(19; "Effective Date"; Date)
        {
            Caption = 'Effective Date';
            Description = 'Settlement Date';
        }
        field(20; "Payment Date"; Text[30])
        {
            Caption = 'Payment Date';
        }
        field(21; "Originator Status Code"; Integer)
        {
            Caption = 'Originator Status Code';
        }
        field(22; "Batch Number"; Integer)
        {
            Caption = 'Batch Number';
        }
        field(23; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
        }
        field(24; "Federal ID No."; Text[30])
        {
            Caption = 'Federal ID No.';
        }
        field(25; "Batch Record Type"; Integer)
        {
            Caption = 'Batch Record Type';
            Description = 'Batch Header Record Type';
        }
        field(26; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
        }
        field(28; "Foreign Exchange Indicator"; Text[10])
        {
            Caption = 'Foreign Exchange Indicator';
        }
        field(29; "Foreign Exchange Ref Indicator"; Text[10])
        {
            Caption = 'Foreign Exchange Ref Indicator';
        }
        field(30; "Foreign Exchange Reference"; Code[20])
        {
            Caption = 'Foreign Exchange Reference';
        }
        field(31; "Destination Country Code"; Text[30])
        {
            Caption = 'Destination Country Code';
        }
        field(32; "Currency Type"; Code[10])
        {
            Caption = 'Currency Type';
        }
        field(33; "Destination Currency Code"; Code[10])
        {
            Caption = 'Destination Currency Code';
        }
        field(34; "Filler/Reserved"; Text[30])
        {
            Caption = 'Filler/Reserved';
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

