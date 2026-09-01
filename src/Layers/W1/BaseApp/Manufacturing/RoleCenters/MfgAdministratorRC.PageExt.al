// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Manufacturing.Setup;

pageextension 99000778 "Mfg. Administrator RC" extends "Administrator Role Center"
{
    actions
    {
        addafter("Mini&forms")
        {
            action("Man&ufacturing Setup")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Man&ufacturing Setup';
                Image = ProductionSetup;
                RunObject = Page "Manufacturing Setup";
                ToolTip = 'Define company policies for manufacturing, such as the default safety lead time and whether warnings are displayed in the planning worksheet.';
            }
        }
        addafter("Report Selection - &Warehouse")
        {
            action("Report Selection - Prod. &Order")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Report Selection - Prod. &Order';
                Image = SelectReport;
                RunObject = Page "Report Selection - Prod. Order";
                ToolTip = 'View or edit the list of reports that can be printed when you work with manufacturing.';
            }
        }
    }
}