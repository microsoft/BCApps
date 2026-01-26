// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Account;

table 12106 "Contribution Code"
{
    Caption = 'Contribution Code';
    DrillDownPageID = "Contribution Codes-INPS";
    LookupPageID = "Contribution Codes-INPS";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
        }
        field(5; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(10; "Social Security Payable Acc."; Code[20])
        {
            Caption = 'Social Security Payable Acc.';
            TableRelation = "G/L Account";
        }
        field(11; "Social Security Charges Acc."; Code[20])
        {
            Caption = 'Social Security Charges Acc.';
            TableRelation = "G/L Account";
        }
        field(12; "Contribution Type"; Option)
        {
            Caption = 'Contribution Type';
            OptionCaption = 'INPS,INAIL';
            OptionMembers = INPS,INAIL;
        }
    }

    keys
    {
        key(Key1; "Code", "Contribution Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", "Contribution Type", Description)
        {
        }
    }

    trigger OnDelete()
    begin
        SocialSecurityCodeLine.Reset();
        SocialSecurityCodeLine.SetRange(Code, Code);

        if SocialSecurityCodeLine.FindFirst() then
            SocialSecurityCodeLine.DeleteAll();
    end;

    var
        SocialSecurityCodeLine: Record "Contribution Code Line";

    [Scope('OnPrem')]
    procedure LookupINAIL(var INAILCode: Code[20])
    var
        ContrCodeRec: Record "Contribution Code";
    begin
        if not GuiAllowed then
            exit;
        ContrCodeRec.SetCurrentKey(Code);
        ContrCodeRec.Code := INAILCode;
        if PAGE.RunModal(PAGE::"Contribution Codes-INAIL", ContrCodeRec, ContrCodeRec.Code) = ACTION::LookupOK then
            INAILCode := ContrCodeRec.Code;
    end;
}

