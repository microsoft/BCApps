// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Intercompany.Partner;

tableextension 8403 "IC Gen. Journal Template" extends "Gen. Journal Template"
{
    fields
    {
        modify("Bal. Account No.")
        {
            TableRelation = if ("Bal. Account Type" = const("IC Partner")) "IC Partner";
        }
    }
}