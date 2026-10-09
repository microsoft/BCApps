// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;

tableextension 8420 "IC Posted Gen. Journal Line" extends "Posted Gen. Journal Line"
{
    fields
    {
        modify("Account No.")
        {
            TableRelation = if ("Account Type" = const("IC Partner")) "IC Partner";
        }
        modify("Bal. Account No.")
        {
            TableRelation = if ("Account Type" = const("IC Partner")) "IC Partner";
        }
        /// <summary>
        /// Intercompany partner code for intercompany transaction processing.
        /// </summary>
        field(113; "IC Partner Code"; Code[20])
        {
            Caption = 'IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Intercompany transaction direction (Outgoing or Incoming).
        /// </summary>
        field(114; "IC Direction"; Enum Microsoft.Intercompany.Setup."IC Direction Type")
        {
            Caption = 'IC Direction';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Intercompany partner transaction number for cross-reference tracking.
        /// </summary>
        field(117; "IC Partner Transaction No."; Integer)
        {
            Caption = 'IC Partner Transaction No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        /// <summary>
        /// Intercompany account type for intercompany transactions and postings.
        /// </summary>
        field(130; "IC Account Type"; Enum Microsoft.Intercompany.Journal."IC Journal Account Type")
        {
            Caption = 'IC Account Type';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Intercompany account number for intercompany transactions and reconciliation.
        /// </summary>
        field(131; "IC Account No."; Code[20])
        {
            Caption = 'IC Account No.';
            DataClassification = CustomerContent;
            TableRelation =
            if ("IC Account Type" = const("G/L Account")) "IC G/L Account" where("Account Type" = const(Posting), Blocked = const(false))
            else
            if ("Account Type" = const(Customer), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Account Type" = const(Vendor), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Account Type" = const("IC Partner"), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("Account No."), Blocked = const(false))
            else
            if ("Bal. Account Type" = const(Customer), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Bal. Account Type" = const(Vendor), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("IC Partner Code"), Blocked = const(false))
            else
            if ("Bal. Account Type" = const("IC Partner"), "IC Account Type" = const("Bank Account")) "IC Bank Account" where("IC Partner Code" = field("Bal. Account No."), Blocked = const(false));
        }
    }
}