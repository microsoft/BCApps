// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Archive;

using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;

/// <summary>
/// Extends Purchase Header Archive with Intercompany-specific fields.
/// </summary>
tableextension 8442 ICPurchaseHeaderArchive extends "Purchase Header Archive"
{
    fields
    {
        field(123; "Send IC Document"; Boolean)
        {
            Caption = 'Send IC Document';
            DataClassification = CustomerContent;
        }
        field(124; "IC Status"; Enum "Purchase Document IC Status")
        {
            Caption = 'IC Status';
            DataClassification = CustomerContent;
        }
        field(125; "Buy-from IC Partner Code"; Code[20])
        {
            Caption = 'Buy-from IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(126; "Pay-to IC Partner Code"; Code[20])
        {
            Caption = 'Pay-to IC Partner Code';
            DataClassification = CustomerContent;
            Editable = false;
            TableRelation = "IC Partner";
        }
        field(127; "IC Reference Document No."; Code[20])
        {
            Caption = 'IC Reference Document No.';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(129; "IC Direction"; Enum "IC Direction Type")
        {
            Caption = 'IC Direction';
            DataClassification = CustomerContent;
        }
    }
}
