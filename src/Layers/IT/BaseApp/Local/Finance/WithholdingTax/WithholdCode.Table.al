// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Account;

table 12104 "Withhold Code"
{
    Caption = 'Withhold Code';
    DrillDownPageID = "Withhold Codes";
    LookupPageID = "Withhold Codes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(4; "Tax Code"; Text[4])
        {
            Caption = 'Tax Code';
        }
        field(5; "770 Code"; Text[1])
        {
            Caption = '770 Code';
        }
        field(10; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(20; "770 Form"; Option)
        {
            Caption = '770 Form';
            OptionCaption = '770/SC,770/SE';
            OptionMembers = "770/SC","770/SE";
        }
        field(21; "Source-Withholding Tax"; Boolean)
        {
            Caption = 'Source-Withholding Tax';

            trigger OnValidate()
            begin
                if not "Source-Withholding Tax" and "Recipient May Report Income" then
                    if Confirm(DisableSrcWthTaxQst, false) then
                        "Recipient May Report Income" := false
                    else
                        "Source-Withholding Tax" := true;
            end;
        }
        field(22; "Recipient May Report Income"; Boolean)
        {
            Caption = 'Recipient May Report Income';

            trigger OnValidate()
            begin
                if "Recipient May Report Income" and (not "Source-Withholding Tax") then begin
                    Message(DisableSrcWthTaxTxt);

                    "Recipient May Report Income" := false;
                end;
            end;
        }
        field(24; "Withholding Taxes Payable Acc."; Code[20])
        {
            Caption = 'Withholding Taxes Payable Acc.';
            TableRelation = "G/L Account";
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Tax Code")
        {
        }
    }

    trigger OnDelete()
    begin
        WithholdCodeLine.Reset();
        WithholdCodeLine.SetRange("Withhold Code", Code);

        if WithholdCodeLine.FindFirst() then
            WithholdCodeLine.DeleteAll();
    end;

    var
        DisableSrcWthTaxQst: Label 'Disabling the Source-Withholding Tax field will also disable the Recipient May Report Income field. Do you want to continue?';
        DisableSrcWthTaxTxt: Label 'You cannot set the Recipient May Report Income field if the Source-Withholding Tax field is disabled.';
        WithholdCodeLine: Record "Withhold Code Line";
}

