// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using System.IO;

table 10307 "ACH Cecoban Detail"
{
    Caption = 'ACH Cecoban Detail';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Sequence Number"; Integer)
        {
            Caption = 'Sequence Number';
        }
        field(3; "Operation Code"; Integer)
        {
            Caption = 'Operation Code';
        }
        field(4; "Bank No."; Text[30])
        {
            Caption = 'Bank No.';
        }
        field(5; "Client Number"; Text[30])
        {
            Caption = 'Client Number';
        }
        field(6; "Payment Amount"; Decimal)
        {
            Caption = 'Payment Amount';
        }
        field(7; "Customer/Vendor Number"; Text[30])
        {
            Caption = 'Customer/Vendor Number';
        }
        field(8; "Payment Number"; Integer)
        {
            Caption = 'Payment Number';
        }
        field(10; "Transfer Date"; Date)
        {
            Caption = 'Transfer Date';
        }
        field(11; "Record Type"; Text[30])
        {
            Caption = 'Record Type';
        }
        field(12; ODFI; Text[30])
        {
            Caption = 'ODFI';
        }
        field(13; RDFI; Text[30])
        {
            Caption = 'RDFI';
        }
        field(14; "Operation Fee"; Decimal)
        {
            Caption = 'Operation Fee';
        }
        field(15; "Future Use"; Text[30])
        {
            Caption = 'Future Use';
        }
        field(16; "Currency Code"; Text[10])
        {
            Caption = 'Currency Code';
        }
        field(17; "Date Entered"; Date)
        {
            Caption = 'Date Entered';
        }
        field(18; "Originator Account Type"; Integer)
        {
            Caption = 'Originator Account Type';
        }
        field(19; "Originator Account no."; Text[20])
        {
            Caption = 'Originator Account no.';
        }
        field(20; "Originator Account Name"; Text[40])
        {
            Caption = 'Originator Account Name';
        }
        field(21; "Originator RFC/CURP"; Text[20])
        {
            Caption = 'Originator RFC/CURP';
        }
        field(22; "Payee Account Type"; Integer)
        {
            Caption = 'Payee Account Type';
        }
        field(23; "Payee Account No."; Text[20])
        {
            Caption = 'Payee Account No.';
        }
        field(24; "Payee Account Name"; Text[40])
        {
            Caption = 'Payee Account Name';
        }
        field(25; "Payee RFC/CURP"; Text[20])
        {
            Caption = 'Payee RFC/CURP';
        }
        field(26; "Transmitter Service Reference"; Text[40])
        {
            Caption = 'Transmitter Service Reference';
        }
        field(27; "Service Owner"; Text[40])
        {
            Caption = 'Service Owner';
        }
        field(28; "Operation Tax Cost"; Integer)
        {
            Caption = 'Operation Tax Cost';
        }
        field(29; "Originator Numeric Reference"; Integer)
        {
            Caption = 'Originator Numeric Reference';
        }
        field(30; "Originator Alpha Reference"; Text[10])
        {
            Caption = 'Originator Alpha Reference';
        }
        field(31; "Tracking Code"; Text[30])
        {
            Caption = 'Tracking Code';
        }
        field(32; "Return Reason"; Integer)
        {
            Caption = 'Return Reason';
        }
        field(33; "Initial Presentation Date"; Date)
        {
            Caption = 'Initial Presentation Date';
        }
        field(34; "Data Exch. Line Def Code"; Code[20])
        {
            Caption = 'Data Exch. Line Def Code';
            NotBlank = true;
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

