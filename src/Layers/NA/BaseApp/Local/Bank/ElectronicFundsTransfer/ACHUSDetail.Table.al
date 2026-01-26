// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using System.IO;

table 10301 "ACH US Detail"
{
    Caption = 'ACH US Detail';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Transaction Code"; Integer)
        {
            Caption = 'Transaction Code';
            Description = 'Address Electronic Funds Transfer Master EFT Account Type';
        }
        field(3; "Payee Transit Routing Number"; Text[30])
        {
            Caption = 'Payee Transit Routing Number';
            Description = 'Address Electronic Funds Transfer Master EFT Transit Routing Number';
        }
        field(4; "Payee Bank Account Number"; Text[30])
        {
            Caption = 'Payee Bank Account Number';
            Description = 'Address Electronic Funds Transfer Master EFT Bank Account';
        }
        field(5; "Payment Amount"; Decimal)
        {
            Caption = 'Payment Amount';
            Description = 'Checkbook Transaction Electronic Funds Transfer Checkbook Amount';
        }
        field(6; "Payee ID/Cross Reference Numbe"; Text[30])
        {
            Caption = 'Payee ID/Cross Reference Numbe';
            Description = 'Checkbook Transaction Electronic Funds Transfer Customer/Vendor ID';
        }
        field(7; "Payee Name"; Text[100])
        {
            Caption = 'Payee Name';
            Description = 'Checkbook Transaction Electronic Funds Transfer Paid To/Rcvd From';
        }
        field(8; "Discretionary Data"; Text[30])
        {
            Caption = 'Discretionary Data';
        }
        field(9; "Addenda Record Indicator"; Integer)
        {
            Caption = 'Addenda Record Indicator';
            Description = 'Addenda Record Indicator';
            FieldClass = Normal;
        }
        field(10; "Trace Number"; Text[50])
        {
            Caption = 'Trace Number';
            Description = 'US-NACHA Trace Number';
        }
        field(11; "Record Type"; Integer)
        {
            Caption = 'Record Type';
        }
        field(12; "Federal ID No."; Text[30])
        {
            Caption = 'Federal ID No.';
        }
        field(13; "Gateway Operator OFAC Scr.Inc"; Text[30])
        {
            Caption = 'Gateway Operator Office of Foreign Assets Control Source Indicator';
        }
        field(14; "Secondary OFAC Scr.Indicator"; Text[30])
        {
            Caption = 'Secondary Office of Foreign Assets Control Source Indicator';
        }
        field(15; "Origin. DFI ID Qualifier"; Text[30])
        {
            Caption = 'Origin. DFI ID Qualifier';
        }
        field(16; "Receiv. DFI ID Qualifier"; Text[30])
        {
            Caption = 'Receiv. DFI ID Qualifier';
        }
        field(17; "IAT Entry Trace Number"; Text[50])
        {
            Caption = 'IAT Entry Trace Number';
        }
        field(18; "Entry Detail Sequence No"; Text[50])
        {
            Caption = 'Entry Detail Sequence No';
        }
        field(19; "Company Address"; Text[105])
        {
            Caption = 'Company Address';
        }
        field(20; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
        }
        field(21; "Company City County"; Text[65])
        {
            Caption = 'Company City County';
        }
        field(22; "Cmpy CntryRegionCode PostCode"; Code[35])
        {
            Caption = 'Company Country Region Code Post Code';
        }
        field(23; "Bank CountryRegion Code"; Code[10])
        {
            Caption = 'Bank Country Region Code';
        }
        field(24; "Destination Bank"; Text[100])
        {
            Caption = 'Destination Bank';
        }
        field(25; "Destination Transit Number"; Text[30])
        {
            Caption = 'Destination Transit Number';
        }
        field(26; "Destination Federal ID No."; Text[30])
        {
            Caption = 'Destination Federal ID No.';
        }
        field(27; "Destination Address"; Text[250])
        {
            Caption = 'Destination Address';
        }
        field(28; "Destination Bank Country Code"; Text[65])
        {
            Caption = 'Destination Bank Country Code';
        }
        field(29; "Destination CntryCode PostCode"; Code[35])
        {
            Caption = 'Destination Country Code Post Code';
        }
        field(30; "Payee Small Transit Route No"; Text[30])
        {
            Caption = 'Payee Small Transit Route No';
        }
        field(31; "Addenda Record Type"; Integer)
        {
            Caption = 'Addenda Record Type';
        }
        field(32; "Bank Name"; Text[100])
        {
            Caption = 'Bank Name';
        }
        field(33; "Destination City County Code"; Code[65])
        {
            Caption = 'Destination City County Code';
        }
        field(34; "Data Exch. Line Def Code"; Code[20])
        {
            Caption = 'Data Exch. Line Def Code';
            NotBlank = true;
        }
        field(35; "Filler/Reserved"; Text[30])
        {
            Caption = 'Filler/Reserved';
        }
        field(36; "Bank Transit Routing Number"; Text[30])
        {
            Caption = 'Bank Transit Routing Number';
        }
        field(37; "Origin Bank Branch"; Text[20])
        {
            Caption = 'Origin Bank Branch';
        }
        field(38; "Destination Bank Branch"; Text[20])
        {
            Caption = 'Destination Bank Branch';
        }
        field(39; "Transaction Type Code"; Text[4])
        {
            Caption = 'Transaction Type Code';
        }
        field(100; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
        }
        field(101; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(102; "Document No."; Code[35])
        {
            Caption = 'Document No.';
        }
        field(103; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
        }
    }

    keys
    {
        key(Key1; "Data Exch. Entry No.", "Data Exch. Line Def Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

