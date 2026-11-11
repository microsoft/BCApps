// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

/// <summary>
/// Extends Resource Card with Intercompany-specific controls.
/// Adds the IC Partner Purch. G/L Acc. No. field for intercompany purchase posting.
/// </summary>
pageextension 8531 ICResourceCard extends "Resource Card"
{
    layout
    {
        addafter("Automatic Ext. Texts")
        {
            field("IC Partner Purch. G/L Acc. No."; Rec."IC Partner Purch. G/L Acc. No.")
            {
                ApplicationArea = Jobs;
            }
        }
    }
}
