// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

pageextension 10611 "Service Credit Memo Subform NO" extends "Service Credit Memo Subform"
{
    layout
    {
        addafter("ShortcutDimCode[8]")
        {
            field("Account Code"; Rec."Account Code")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the account code of the customer.';
                Visible = false;
            }
        }
    }
}