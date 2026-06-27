// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Manufacturing.Setup;

pageextension 99000779 "Mfg. Administrator Main RC" extends "Administrator Main Role Center"
{
    actions
    {
        addafter("Report Selections Inventory")
        {
            action("Report Selections Prod. Order")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Report Selections Prod. Order';
                RunObject = page "Report Selection - Prod. Order";
            }
        }
    }
}