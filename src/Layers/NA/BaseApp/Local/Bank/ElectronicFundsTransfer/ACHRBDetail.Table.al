// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using System.IO;

table 10304 "ACH RB Detail"
{
    Caption = 'ACH RB Detail';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Data Exch. Entry No."; Integer)
        {
            Caption = 'Data Exch. Entry No.';
            TableRelation = "Data Exch."."Entry No.";
        }
        field(2; "Transaction Code"; Text[10])
        {
            Caption = 'Transaction Code';
        }
        field(3; "Transit Routing No."; Text[30])
        {
            Caption = 'Transit Routing No.';
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
        field(9; "Recipient Bank No."; Text[30])
        {
            Caption = 'Recipient Bank No.';
        }
        field(10; "Payment Date"; Integer)
        {
            Caption = 'Payment Date';
            Description = 'Payment Date';
        }
        field(11; "Record Type"; Text[10])
        {
            Caption = 'Record Type';
        }
        field(12; "Record Count"; Integer)
        {
            Caption = 'Record Count';
        }
        field(13; "Vendor/Customer Name"; Text[30])
        {
            Caption = 'Vendor/Customer Name';
        }
        field(14; "Language Code"; Text[30])
        {
            Caption = 'Language Code';
        }
        field(15; "Client Name"; Text[30])
        {
            Caption = 'Client Name';
        }
        field(16; "Currency Code"; Text[30])
        {
            Caption = 'Currency Code';
        }
        field(17; Country; Text[30])
        {
            Caption = 'Country';
        }
        field(18; AD1NoOfRec; Integer)
        {
            Caption = 'Address 1 Number Of Records';
        }
        field(19; "AD1Client No"; Text[30])
        {
            Caption = 'Address 1 Client Number';
        }
        field(20; "AD1Company Name"; Text[100])
        {
            Caption = 'Address 1 Company Name';
        }
        field(21; AD1Address; Text[100])
        {
            Caption = 'Address 1 Address';
        }
        field(22; "AD1City State"; Text[62])
        {
            Caption = 'Address 1 City State';
        }
        field(23; "AD1Region Code/Post Code"; Text[32])
        {
            Caption = 'Address 1 Region Code/Post Code';
        }
        field(24; AD2NoOfRec; Integer)
        {
            Caption = 'Address 2 Number Of Records';
        }
        field(25; "AD2Client No"; Text[30])
        {
            Caption = 'Address 2 Client Number';
        }
        field(26; "AD2Transaction Type Code"; Text[30])
        {
            Caption = 'Address 2 Transaction Type Code';
        }
        field(27; "AD2Recipient Address"; Text[80])
        {
            Caption = 'Address 2 Recipient Address';
        }
        field(28; "AD2Recipient City/County"; Text[62])
        {
            Caption = 'Address 2 Recipient City/County';
        }
        field(29; "AD2Region Code/Post Code"; Text[52])
        {
            Caption = 'Address 2 Region Code/Post Code';
        }
        field(30; "AD2Company Entry Description"; Text[40])
        {
            Caption = 'Address 2 Company Entry Description';
        }
        field(31; RRNoOfRec; Integer)
        {
            Caption = 'Remittance Record Number Of Records';
        }
        field(32; "RRClient No"; Text[30])
        {
            Caption = 'Remittance Record Client Number';
        }
        field(33; "RRPayment Related Info1"; Text[90])
        {
            Caption = 'Remittance Record Payment Related Info 1';
        }
        field(34; "RRPayment Related Info2"; Text[60])
        {
            Caption = 'Remittance Record Payment Related Info 2 ';
        }
        field(35; "Data Exch. Line Def Code"; Code[20])
        {
            Caption = 'Data Exch. Line Def Code';
            NotBlank = true;
        }
        field(36; "File Creation Number"; Integer)
        {
            Caption = 'File Creation Number';
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

