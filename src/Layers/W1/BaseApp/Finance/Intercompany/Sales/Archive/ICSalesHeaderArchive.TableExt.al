// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Archive;

using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

/// <summary>
/// Extends Sales Header Archive with Intercompany-specific fields.
/// </summary>
tableextension 8467 ICSalesHeaderArchive extends "Sales Header Archive"
{
    fields
    {
        /// <summary>
        /// Indicates whether the document should be sent to an intercompany partner.
        /// </summary>
        field(123; "Send IC Document"; Boolean)
        {
            Caption = 'Send IC Document';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the intercompany processing status of the document.
        /// </summary>
        field(124; "IC Status"; Enum "Sales Document IC Status")
        {
            Caption = 'IC Status';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the intercompany partner code for the sell-to customer in intercompany transactions.
        /// </summary>
        field(125; "Sell-to IC Partner Code"; Code[20])
        {
            Caption = 'Sell-to IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Specifies the intercompany partner code for the bill-to customer in intercompany transactions.
        /// </summary>
        field(126; "Bill-to IC Partner Code"; Code[20])
        {
            Caption = 'Bill-to IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        /// <summary>
        /// Specifies the document number used by the intercompany partner to reference this transaction.
        /// </summary>
        field(127; "IC Reference Document No."; Code[20])
        {
            Caption = 'IC Reference Document No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        /// <summary>
        /// Specifies the direction of the intercompany transaction, either outgoing or incoming.
        /// </summary>
        field(129; "IC Direction"; Enum "IC Direction Type")
        {
            Caption = 'IC Direction';
            DataClassification = CustomerContent;
        }
    }
}
