// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Setup;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Finance.GeneralLedger.Journal;
using System.Telemetry;

table 32000000 "Reference File Setup"
{
    Caption = 'Reference File Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = "Bank Account"."No.";
        }
        field(8; "Exchange Rate Contract No."; Code[14])
        {
            Caption = 'Exchange Rate Contract No.';
        }
        field(9; "Due Date Handling"; Option)
        {
            Caption = 'Due Date Handling';
            OptionCaption = 'Batch,Transaction';
            OptionMembers = Batch,Transaction;
        }
        field(11; "Batch by Payment Date"; Boolean)
        {
            Caption = 'Batch by Payment Date';
        }
        field(14; "Default Payment Method"; Code[1])
        {
            Caption = 'Default Payment Method';
            TableRelation = "Foreign Payment Types".Code where("Code Type" = const("Payment Method"));
        }
        field(15; "Default Service Fee Code"; Code[1])
        {
            Caption = 'Default Service Fee Code';
            TableRelation = "Foreign Payment Types".Code where("Code Type" = const("Service Fee"));
        }
        field(16; "Inform. of Appl. Cr. Memos"; Boolean)
        {
            Caption = 'Inform. of Appl. Cr. Memos';
        }
        field(17; "Allow Comb. Domestic Pmts."; Boolean)
        {
            Caption = 'Allow Comb. Domestic Pmts.';
            Editable = false;

            trigger OnValidate()
            begin
                RefFileSetup.SetFilter("No.", '<>%1', "No.");
                RefFileSetup.ModifyAll(RefFileSetup."Allow Comb. Domestic Pmts.", "Allow Comb. Domestic Pmts.")
            end;
        }
        field(18; "Allow Comb. Foreign Pmts."; Boolean)
        {
            Caption = 'Allow Comb. Foreign Pmts.';

            trigger OnValidate()
            begin
                RefFileSetup.SetFilter("No.", '<>%1', "No.");
                RefFileSetup.ModifyAll(RefFileSetup."Allow Comb. Foreign Pmts.", "Allow Comb. Foreign Pmts.")
            end;
        }
        field(19; "Payment Journal Template"; Code[10])
        {
            Caption = 'Payment Journal Template';
            TableRelation = "Gen. Journal Template".Name where(Type = const(Payments));
        }
        field(20; "Payment Journal Batch"; Code[10])
        {
            Caption = 'Payment Journal Batch';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Payment Journal Template"));
        }
        field(21; "File Name"; Text[250])
        {
            Caption = 'File Name';
        }
        field(22; "Bank Party ID"; Code[20])
        {
            Caption = 'Bank Party ID';

            trigger OnValidate()
            begin
                if "Bank Party ID" <> '' then
                    if not (StrLen("Bank Party ID") in [8 .. 13]) then
                        FieldError("Bank Party ID", Text13400);
            end;
        }
        field(23; "Allow Comb. SEPA Pmts."; Boolean)
        {
            Caption = 'Allow Comb. SEPA Pmts.';

            trigger OnValidate()
            begin
                RefFileSetup.SetFilter("No.", '<>%1', "No.");
                RefFileSetup.ModifyAll("Allow Comb. SEPA Pmts.", "Allow Comb. SEPA Pmts.")
            end;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        FeatureTelemetry.LogUptake('1000HN5', FIBankTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    var
        RefFileSetup: Record "Reference File Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FIBankTok: Label 'FI Electronic Banking', Locked = true;
        Text13400: Label 'is not valid with respect to minimal length 8 and maximal length 13.';
}
