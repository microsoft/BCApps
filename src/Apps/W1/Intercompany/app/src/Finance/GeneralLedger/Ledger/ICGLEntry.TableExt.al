// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Intercompany.Partner;

tableextension 8423 "IC G/L Entry" extends "G/L Entry"
{
    fields
    {
        modify("Bal. Account No.")
        {
            TableRelation = if ("Bal. Account Type" = const("IC Partner")) "IC Partner";
        }
        modify("IC Partner Code")
        {
            TableRelation = "IC Partner";
        }
    }
}
