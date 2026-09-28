// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Finance.GeneralLedger.Account;

tableextension 11410 "Bank Acc. Posting Group NL" extends "Bank Account Posting Group"
{
    fields
    {
        field(11000000; "Acc.No. Pmt./Rcpt. in Process"; Code[20])
        {
            Caption = 'Acc.No. Pmt./Rcpt. in Process';
            TableRelation = "G/L Account";

            trigger OnValidate()
            var
                GLAccount: Record "G/L Account";
            begin
                if "Acc.No. Pmt./Rcpt. in Process" <> '' then begin
                    GLAccount.Get("Acc.No. Pmt./Rcpt. in Process");
                    GLAccount.TestField(GLAccount."Account Type", GLAccount."Account Type"::Posting);
                    GLAccount.TestField(GLAccount."Income/Balance", GLAccount."Income/Balance"::"Balance Sheet");

                    if GLAccount."Direct Posting" then
                        Message(Text1000000 + Text1000001, GLAccount."No.", GLAccount.FieldCaption(GLAccount."Direct Posting"));
                end;
            end;
        }
    }

    var
        Text1000000: Label 'Manual posting is possible on General Ledger Account %1. ';
        Text1000001: Label 'This can be changed by turning off %2.';
}
