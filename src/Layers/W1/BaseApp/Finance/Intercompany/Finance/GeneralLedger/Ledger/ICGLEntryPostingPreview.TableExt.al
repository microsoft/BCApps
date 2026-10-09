// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Intercompany.Partner;

tableextension 8425 "IC G/L Entry Posting Preview" extends "G/L Entry Posting Preview"
{
    fields
    {
        modify("Bal. Account No.")
        {
            TableRelation = if ("Bal. Account Type" = const("IC Partner")) "IC Partner";
        }

        /// <summary>
        /// Intercompany partner code for this preview G/L entry.
        /// </summary>
        field(72; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
            TableRelation = "IC Partner";
        }
    }
}
