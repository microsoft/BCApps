// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

using Microsoft.Intercompany.GLAccount;

tableextension 8404 "IC G/L Account" extends "G/L Account"
{
    fields
    {
        /// <summary>
        /// Default intercompany partner general ledger account for automatic intercompany transactions.
        /// </summary>
        field(66; "Default IC Partner G/L Acc. No"; Code[20])
        {
            Caption = 'Default IC Partner G/L Acc. No';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies accounts that you often enter in the Bal. Account No. field on intercompany journal or document lines.';
            TableRelation = "IC G/L Account"."No.";
        }
    }
}
