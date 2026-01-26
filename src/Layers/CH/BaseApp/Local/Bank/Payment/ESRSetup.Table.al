// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Bank;
using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Utilities;

table 3010531 "ESR Setup"
{
    Caption = 'ESR Setup';
    DrillDownPageID = "ESR Setup List";
    LookupPageID = "ESR Setup List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Code"; Code[20])
        {
            Caption = 'Bank Code';
            TableRelation = "Bank Account";
            ValidateTableRelation = false;
        }
        field(2; "ESR System"; Option)
        {
            Caption = 'ESR System';
            OptionCaption = 'ESR,ESR+';
            OptionMembers = ESR,"ESR+";
        }
        field(3; "Bal. Account No."; Code[20])
        {
            Caption = 'Bal. Account No.';
            TableRelation = if ("Bal. Account Type" = const("G/L Account")) "G/L Account"
            else
            if ("Bal. Account Type" = const("Bank Account")) "Bank Account";
        }
        field(4; "ESR Filename"; Text[50])
        {
            Caption = 'ESR Filename';
            NotBlank = true;
        }
        field(5; "BESR Customer ID"; Code[11])
        {
            Caption = 'BESR Customer ID';
            InitValue = '00000000000';
            Numeric = true;

            trigger OnValidate()
            begin
                // CHeck length of Customer ID
                if StrLen("BESR Customer ID") < MaxStrLen("BESR Customer ID") then
                    Error(Text000, FieldCaption("BESR Customer ID"), MaxStrLen("BESR Customer ID"));
            end;
        }
        field(6; "Bal. Account Type"; Option)
        {
            Caption = 'Bal. Account Type';
            OptionCaption = 'G/L Account,Bank Account';
            OptionMembers = "G/L Account","Bank Account";
        }
        field(7; "ESR Payment Method Code"; Code[10])
        {
            Caption = 'ESR Payment Method Code';
            TableRelation = "Payment Method";
        }
        field(8; "ESR Main Bank"; Boolean)
        {
            Caption = 'ESR Main Bank';

            trigger OnValidate()
            begin
                // Only one Main Bank possible
                if "ESR Main Bank" then begin
                    SetRange("ESR Main Bank", true);
                    ModifyAll("ESR Main Bank", false);
                    SetRange("ESR Main Bank");
                end;
            end;
        }
        field(10; "ESR Account No."; Code[11])
        {
            Caption = 'ESR Account No.';
            CharAllowed = '09--';
            NotBlank = true;

            trigger OnValidate()
            begin
                BankMgt.CheckPostAccountNo("ESR Account No.");
            end;
        }
        field(11; "ESR Member Name 1"; Text[30])
        {
            Caption = 'ESR Member Name 1';
        }
        field(12; "ESR Member Name 2"; Text[30])
        {
            Caption = 'ESR Member Name 2';
        }
        field(13; "ESR Member Name 3"; Text[30])
        {
            Caption = 'ESR Member Name 3';
        }
        field(19; "Beneficiary Text"; Text[30])
        {
            Caption = 'Beneficiary Text';
        }
        field(20; Beneficiary; Text[30])
        {
            Caption = 'Beneficiary';
        }
        field(21; "Beneficiary 2"; Text[30])
        {
            Caption = 'Beneficiary 2';
        }
        field(22; "Beneficiary 3"; Text[30])
        {
            Caption = 'Beneficiary 3';
        }
        field(23; "Beneficiary 4"; Text[30])
        {
            Caption = 'Beneficiary 4';
        }
        field(24; "Beneficiary 5"; Text[30])
        {
            Caption = 'Beneficiary 5';
        }
        field(40; "ESR Currency Code"; Code[10])
        {
            Caption = 'ESR Currency Code';
            TableRelation = Currency;
        }
        field(50; "Backup Copy"; Boolean)
        {
            Caption = 'Backup Copy';
        }
        field(51; "Backup Folder"; Text[50])
        {
            Caption = 'Backup Folder';

            trigger OnValidate()
            begin
                GeneralMgt.CheckFolderName("Backup Folder");
            end;
        }
        field(52; "Last Backup No."; Code[4])
        {
            Caption = 'Last Backup No.';
            InitValue = '0000';
        }
    }

    keys
    {
        key(Key1; "Bank Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Bank Code", "ESR System", "ESR Currency Code", "ESR Main Bank")
        {
        }
    }

    var
        Text000: Label 'The %1 must be a number with %2 digits or be filled with zeros.';
        BankMgt: Codeunit BankMgt;
        GeneralMgt: Codeunit GeneralMgt;
}

