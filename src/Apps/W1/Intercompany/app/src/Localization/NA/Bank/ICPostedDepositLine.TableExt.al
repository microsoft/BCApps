#if INTERCOMPANY_NA
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Deposit;

using Microsoft.Intercompany.Partner;

tableextension 8559 "IC Posted Deposit Line" extends "Posted Deposit Line"
{
    fields
    {
        modify("Account No.")
        {
            TableRelation = if ("Account Type" = const("IC Partner")) "IC Partner";
        }
    }
}
#endif
