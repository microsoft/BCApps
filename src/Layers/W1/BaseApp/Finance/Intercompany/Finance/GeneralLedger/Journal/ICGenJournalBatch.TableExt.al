// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Intercompany.Partner;

tableextension 8426 "IC Gen. Journal Batch" extends "Gen. Journal Batch"
{
    fields
    {
        modify("Bal. Account No.")
        {
            TableRelation = if ("Bal. Account Type" = const("IC Partner")) "IC Partner";
        }
    }
}
