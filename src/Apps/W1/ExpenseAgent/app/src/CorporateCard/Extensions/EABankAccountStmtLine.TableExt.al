// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.Statement;

tableextension 7441 "EA Bank Account Stmt. Line" extends "Bank Account Statement Line"
{
    fields
    {
        field(7420; "EA Corp Card Trans Entry No."; Integer)
        {
            Caption = 'Corp Card Transaction Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "EA Corp Card Trans"."Entry No.";
        }
        field(7421; "EA Posted Exp. Report No."; Code[20])
        {
            Caption = 'Posted Expense Report No.';
            DataClassification = AccountData;
            Editable = false;
            TableRelation = "Posted Expense Report Header"."No.";
        }
    }

    keys
    {
        key(EACorpCardTrans; "EA Corp Card Trans Entry No.")
        {
        }
    }
}
