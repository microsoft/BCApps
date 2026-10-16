// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.Bank.Ledger;

tableextension 7442 "EA Bank Acc. Ledger Entry" extends "Bank Account Ledger Entry"
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
    }

    keys
    {
        key(EACorpCardTrans; "EA Corp Card Trans Entry No.")
        {
        }
    }
}
