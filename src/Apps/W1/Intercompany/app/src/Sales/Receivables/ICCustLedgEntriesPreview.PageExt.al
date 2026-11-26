// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

/// <summary>
/// Extends Cust. Ledg. Entries Preview with Intercompany-specific controls.
/// </summary>
pageextension 8478 ICCustLedgEntriesPreview extends "Cust. Ledg. Entries Preview"
{
    layout
    {
        addafter("Customer Posting Group")
        {
            field("IC Partner Code"; Rec."IC Partner Code")
            {
                ApplicationArea = Intercompany;
                Editable = false;
                Visible = false;
            }
        }
    }
}
