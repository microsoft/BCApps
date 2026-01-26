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
        field(7000000; "Liabs. for Disc. Bills Acc."; Code[20])
        {
            Caption = 'Liabs. for Disc. Bills Acc.';
            TableRelation = "G/L Account";
        }
        field(7000001; "Bank Services Acc."; Code[20])
        {
            Caption = 'Bank Services Acc.';
            TableRelation = "G/L Account";
        }
        field(7000002; "Discount Interest Acc."; Code[20])
        {
            Caption = 'Discount Interest Acc.';
            TableRelation = "G/L Account";
        }
        field(7000003; "Rejection Expenses Acc."; Code[20])
        {
            Caption = 'Rejection Expenses Acc.';
            TableRelation = "G/L Account";
        }
        field(7000004; "Liabs. for Factoring Acc."; Code[20])
        {
            Caption = 'Liabs. for Factoring Acc.';
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
        fieldgroup(DropDown; "Code", "G/L Account No.")
        {
        }
        fieldgroup(Brick; "Code")
        {
        }
    }

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
