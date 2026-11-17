// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.Reconciliation;

tableextension 7440 "EA Bank Acc. Rec. Line" extends "Bank Acc. Reconciliation Line"
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
        key(EAPostedExpenseReport; "EA Posted Exp. Report No.")
        {
        }
    }
}
