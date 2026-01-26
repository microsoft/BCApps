// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.ElectronicFundsTransfer;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Finance.GeneralLedger.Journal;

table 10810 "EFT Export"
{
    Caption = 'EFT Export';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(4; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(5; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
        }
        field(6; "Settle Date"; Date)
        {
            Caption = 'Settle Date';
        }
        field(7; "Posting Date Option"; Option)
        {
            Caption = 'Posting Date Option';
            OptionCaption = 'Change Posting Date To Match,Skip Lines Which Do Not Match';
            OptionMembers = "Change Posting Date To Match","Skip Lines Which Do Not Match";
        }
        field(8; "Bank Payment Type"; Enum "Bank Payment Type")
        {
            AccessByPermission = TableData "Bank Account" = R;
            Caption = 'Bank Payment Type';
        }
        field(9; "Transaction Code"; Code[10])
        {
            Caption = 'Transaction Code';
        }
        field(10; "Document Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Document Type';
        }
        field(11; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ClosingDates = true;
        }
        field(13; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
        }
        field(14; "Account No."; Code[20])
        {
            Caption = 'Account No.';
        }
        field(15; "Payment Reference"; Code[50])
        {
            Caption = 'Payment Reference';
        }
        field(16; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(21; "Applies-to ID"; Code[50])
        {
            Caption = 'Applies-to ID';
        }
        field(23; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(25; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(27; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
        }
        field(31; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
        }
        field(32; "Bal. Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Bal. Account Type';
        }
        field(33; "Applies-to Doc. Type"; Enum "Gen. Journal Document Type")
        {
            Caption = 'Applies-to Doc. Type';
        }
        field(34; "Applies-to Doc. No."; Code[20])
        {
            Caption = 'Applies-to Doc. No.';
        }
        field(35; "Check Exported"; Boolean)
        {
            Caption = 'Check Exported';
            Editable = false;
        }
        field(36; "Check Printed"; Boolean)
        {
            AccessByPermission = TableData "Check Ledger Entry" = R;
            Caption = 'Check Printed';
            Editable = false;
        }
        field(37; "Exported to Payment File"; Boolean)
        {
            Caption = 'Exported to Payment File';
            Editable = false;
        }
        field(38; "Amount (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(40; "Foreign Exchange Reference"; Code[20])
        {
            Caption = 'Foreign Exchange Reference';
        }
        field(41; "Foreign Exchange Indicator"; Option)
        {
            Caption = 'Foreign Exchange Indicator';
            OptionCaption = ',FV,VF,FF';
            OptionMembers = ,FV,VF,FF;
        }
        field(42; "Foreign Exchange Ref.Indicator"; Option)
        {
            Caption = 'Foreign Exchange Ref.Indicator';
            OptionCaption = ',1,2,3';
            OptionMembers = ,"1","2","3";
        }
        field(43; "Country/Region Code"; Code[10])
        {
            Caption = 'Country/Region Code';
        }
        field(47; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
        }
        field(48; "Company Entry Description"; Text[10])
        {
            Caption = 'Company Entry Description';
        }
        field(49; "Transaction Type Code"; Option)
        {
            Caption = 'Transaction Type Code';
            OptionCaption = 'ANN,BUS,DEP,LOA,MIS,MOR,PEN,RLS,SAL,TAX';
            OptionMembers = ANN,BUS,DEP,LOA,MIS,MOR,PEN,RLS,SAL,TAX;
        }
        field(50; "Payment Related Information 1"; Text[80])
        {
            Caption = 'Payment Related Information 1';
        }
        field(51; "Payment Related Information 2"; Text[52])
        {
            Caption = 'Payment Related Information 2';
        }
        field(52; "Gateway Operator OFAC Scr.Inc"; Option)
        {
            Caption = 'Gateway Operator OFAC Scr.Inc';
            OptionCaption = ',0,1';
            OptionMembers = ,"0","1";
        }
        field(53; "Secondary OFAC Scr.Indicator"; Option)
        {
            Caption = 'Secondary OFAC Scr.Indicator';
            OptionCaption = ',0,1';
            OptionMembers = ,"0","1";
        }
        field(54; "Origin. DFI ID Qualifier"; Option)
        {
            Caption = 'Origin. DFI ID Qualifier';
            OptionCaption = ',01,02,03';
            OptionMembers = ,"01","02","03";
        }
        field(55; "Receiv. DFI ID Qualifier"; Option)
        {
            Caption = 'Receiv. DFI ID Qualifier';
            OptionCaption = ',01,02,03';
            OptionMembers = ,"01","02","03";
        }
        field(56; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(57; Transmitted; Boolean)
        {
            Caption = 'Transmitted';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Line No.", "Sequence No.")
        {
            Clustered = true;
        }
        key(Key2; "Bank Account No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", "Journal Batch Name");
        GenJournalLine.SetRange("Line No.", "Line No.");
        GenJournalLine.SetRange("EFT Export Sequence No.", "Sequence No.");
        if GenJournalLine.FindFirst() then begin
            GenJournalLine."EFT Export Sequence No." := 0;
            GenJournalLine.Modify();
        end;
    end;
}

