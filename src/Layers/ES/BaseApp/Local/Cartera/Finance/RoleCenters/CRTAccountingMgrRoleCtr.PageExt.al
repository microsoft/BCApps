// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Finance.ReceivablesPayables;

pageextension 7000161 "CRT Accounting Mgr. Role Ctr." extends "Accounting Manager Role Center"
{
    actions
    {
        addafter("Cost Accounting Setup")
        {
            action("Cartera Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cartera Setup';
                RunObject = Page "Cartera Setup";
                ToolTip = 'Configure your company''s policies for bill groups and payment orders.';
            }
        }
    }
}
