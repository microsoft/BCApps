// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

using Microsoft.Bank.BankAccount;

table 2000042 "CODA Statement Source Line"
{
    Caption = 'CODA Statement Source Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(2; "Statement No."; Code[20])
        {
            Caption = 'Statement No.';
            TableRelation = "CODA Statement"."Statement No." where("Bank Account No." = field("Bank Account No."));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; ID; Option)
        {
            Caption = 'ID';
            OptionCaption = 'Header,Old Balance,Movement,Information,Free Message,,,,New Balance,Trailer';
            OptionMembers = Header,"Old Balance",Movement,Information,"Free Message",,,,"New Balance",Trailer;
        }
        field(5; Data; Text[128])
        {
            Caption = 'Data';
        }
        field(6; "Item Code"; Text[1])
        {
            Caption = 'Item Code';
        }
        field(7; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
            MaxValue = 9999;
            MinValue = 0;
        }
        field(8; "Detail No."; Integer)
        {
            Caption = 'Detail No.';
            MaxValue = 9999;
            MinValue = 0;
        }
        field(9; "Bank Reference No."; Text[21])
        {
            Caption = 'Bank Reference No.';
        }
        field(10; "Ext. Reference No."; Text[8])
        {
            Caption = 'Ext. Reference No.';
        }
        field(11; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(12; "Transaction Date"; Date)
        {
            Caption = 'Transaction Date';
        }
        field(13; "Transaction Type"; Integer)
        {
            Caption = 'Transaction Type';
        }
        field(14; "Transaction Family"; Integer)
        {
            Caption = 'Transaction Family';
        }
        field(15; Transaction; Integer)
        {
            Caption = 'Transaction';
        }
        field(16; "Transaction Category"; Integer)
        {
            Caption = 'Transaction Category';
        }
        field(17; "Message Type"; Option)
        {
            Caption = 'Message Type';
            OptionCaption = 'Non standard format,Standard format';
            OptionMembers = "Non standard format","Standard format";
        }
        field(18; "Type Standard Format Message"; Integer)
        {
            Caption = 'Type Standard Format Message';
        }
        field(19; "Statement Message"; Text[105])
        {
            Caption = 'Statement Message';
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(21; "Globalisation Code"; Integer)
        {
            Caption = 'Globalisation Code';
            MaxValue = 9;
            MinValue = 0;
        }
        field(22; "Customer Reference"; Text[35])
        {
            Caption = 'Customer Reference';
        }
        field(23; "Bank Account No. Other Party"; Text[34])
        {
            Caption = 'Bank Account No. Other Party';
        }
        field(24; "Internal Codes Other Party"; Text[10])
        {
            Caption = 'Internal Codes Other Party';
        }
        field(25; "Ext. Acc. No. Other Party"; Text[15])
        {
            Caption = 'Ext. Acc. No. Other Party';
        }
        field(26; "Name Other Party"; Text[35])
        {
            Caption = 'Name Other Party';
        }
        field(27; "Address Other Party"; Text[35])
        {
            Caption = 'Address Other Party';
        }
        field(28; "City Other Party"; Text[35])
        {
            Caption = 'City Other Party';
        }
        field(29; "Sequence Code"; Integer)
        {
            Caption = 'Sequence Code';
            MaxValue = 1;
            MinValue = 0;
        }
        field(30; "Binding Code"; Integer)
        {
            Caption = 'Binding Code';
            MaxValue = 2;
            MinValue = 0;
        }
        field(40; "CODA Statement No."; Integer)
        {
            Caption = 'CODA Statement No.';
        }
        field(50; Transferred; Boolean)
        {
            Caption = 'Transferred';
        }
        field(60; "Original Transaction Currency"; Code[3])
        {
            Caption = 'Original Transaction Currency';
            Editable = false;
        }
        field(61; "Original Transaction Amount"; Decimal)
        {
            Caption = 'Original Transaction Amount';
            Editable = false;
        }
        field(62; "SWIFT Address"; Text[11])
        {
            Caption = 'SWIFT Address';
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Statement No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; ID, "Sequence No.", "Detail No.")
        {
        }
    }

    fieldgroups
    {
    }
}

