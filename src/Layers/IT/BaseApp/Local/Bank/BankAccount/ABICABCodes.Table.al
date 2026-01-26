// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Foundation.Address;

table 12176 "ABI/CAB Codes"
{
    Caption = 'ABI/CAB Codes';
    LookupPageID = "ABI/CAB List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; ABI; Code[5])
        {
            Caption = 'ABI';
        }
        field(2; CAB; Code[5])
        {
            Caption = 'CAB';
        }
        field(3; "Bank Description"; Text[50])
        {
            Caption = 'Bank Description';
        }
        field(4; "Agency Description"; Text[50])
        {
            Caption = 'Agency Description';
        }
        field(5; Address; Text[50])
        {
            Caption = 'Address';
        }
        field(6; County; Text[30])
        {
            Caption = 'County';
        }
        field(7; City; Text[30])
        {
            Caption = 'City';
            TableRelation = "Post Code".City;
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                CountryCode: Code[10];
            begin
                PostCode.ValidateCity(City, "Post Code", County, CountryCode, (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
        field(8; "Post Code"; Code[20])
        {
            Caption = 'Post Code';
            TableRelation = "Post Code";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                CountryCode: Code[10];
            begin
                PostCode.ValidatePostCode(City, "Post Code", County, CountryCode, (CurrFieldNo <> 0) and GuiAllowed);
            end;
        }
    }

    keys
    {
        key(Key1; ABI, CAB)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; ABI, CAB, "Bank Description")
        {
        }
    }

    var
        ABICodeEmptyErr: Label 'Select the ABI code first.';
        PostCode: Record "Post Code";
        SpecialCharactersUsageErr: Label 'You cannot use special characters in Italian bank account numbers.';

    procedure CheckABICAB(ABI: Code[20]; CAB: Code[20])
    var
        ABICAB: Record "ABI/CAB Codes";
    begin
        if CAB = '' then
            exit;

        if ABI = '' then
            Error(ABICodeEmptyErr);

        ABICAB.Get(ABI, CAB);
    end;

    procedure CalcBBAN(ABI: Code[5]; CAB: Code[5]; BankAcc: Text[30]): Code[30]
    var
        tmpBBAN: Code[30];
    begin
        tmpBBAN := CalcCIN(ABI, CAB, BankAcc);
        tmpBBAN := tmpBBAN + ConvertStr(Format(ABI, 5), ' ', '0') + ConvertStr(Format(CAB, 5), ' ', '0');
        tmpBBAN := tmpBBAN + ConvertStr(Format(BankAcc, 12), ' ', '0');

        exit(tmpBBAN);
    end;

    procedure CalcCIN(ABI: Code[5]; CAB: Code[5]; BankAcc: Text[30]): Code[1]
    var
        tmpBBAN: Code[30];
        CodeArray: array[27] of Integer;
        CheckStr: Text[100];
        Letters: Code[26];
        kt: Integer;
        totalcheck: Integer;
        tmpVal: Integer;
        tmpStr: Code[1];
        CIN: Code[1];
    begin
        CheckStr := '1,0,5,7,9,13,15,17,19,21,2,4,18,20,11,3,6,8,12,14,16,10,22,25,24,23';
        Letters := 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

        kt := 1;
        repeat
            Evaluate(CodeArray[kt], SelectStr(kt, CheckStr));
            kt := kt + 1;
        until kt >= 27;

        tmpBBAN := ' ';
        tmpBBAN := tmpBBAN + ConvertStr(Format(ABI, 5), ' ', '0') + ConvertStr(Format(CAB, 5), ' ', '0');
        tmpBBAN := tmpBBAN + ConvertStr(Format(BankAcc, 12), ' ', '0');

        kt := 1;
        totalcheck := 0;
        repeat
            tmpStr := CopyStr(tmpBBAN, kt, 1);

            tmpVal := StrPos(Letters, tmpStr);
            if tmpVal > 0 then
                tmpVal := tmpVal - 1
            else
                if not Evaluate(tmpVal, tmpStr) then
                    Error(SpecialCharactersUsageErr);

            if kt mod 2 = 0 then
                totalcheck := totalcheck + tmpVal
            else
                totalcheck := totalcheck + CodeArray[tmpVal + 1];

            kt := kt + 1
        until kt >= 23;

        totalcheck := totalcheck mod 26;
        if totalcheck = 0 then
            CIN := 'A'
        else
            CIN := CopyStr(Letters, totalcheck + 1, 1);

        exit(CIN);
    end;
}

