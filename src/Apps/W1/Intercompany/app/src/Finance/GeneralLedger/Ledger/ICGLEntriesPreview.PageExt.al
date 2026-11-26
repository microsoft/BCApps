// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Ledger;

/// <summary>
/// Extends G/L Entries Preview with Intercompany-specific controls.
/// Adds the IC Partner Code column for identifying intercompany transactions in posting previews.
/// </summary>
pageextension 8523 ICGLEntriesPreview extends "G/L Entries Preview"
{
    layout
    {
        addafter("Global Dimension 2 Code")
        {
            field("IC Partner Code"; Rec."IC Partner Code")
            {
                ApplicationArea = Intercompany;
                Visible = false;
            }
        }
    }
}
