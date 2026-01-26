// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

using Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Defines G/L account assignments for bank account posting operations.
/// Maps bank account transactions to appropriate general ledger accounts.
/// </summary>
/// <remarks>
/// Used by Bank Account table to determine posting account for bank transactions.
/// Validates G/L account for direct posting capability.
/// </remarks>
table 277 "Bank Account Posting Group"
{
    Caption = 'Bank Account Posting Group';
    DrillDownPageID = "Bank Account Posting Groups";
    LookupPageID = "Bank Account Posting Groups";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Unique identifier for the bank account posting group.
        /// </summary>
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        /// <summary>
        /// G/L account number where bank transactions will be posted.
        /// </summary>
        field(3; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";

            trigger OnValidate()
            begin
                CheckGLAcc("G/L Account No.");
            end;
        }
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

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", "G/L Account No.")
        {
        }
        fieldgroup(Brick; "Code")
        {
        }
    }

    var
        Text1000000: Label 'Manual posting is possible on General Ledger Account %1. ';
        Text1000001: Label 'This can be changed by turning off %2.';

    local procedure CheckGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
    begin
        if AccNo <> '' then begin
            GLAcc.Get(AccNo);
            GLAcc.CheckGLAcc();
        end;
    end;
}
