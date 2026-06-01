// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.RoleCenters;

pageextension 99001536 "Subc. Manufacturing Manager RC" extends "Manufacturing Manager RC"
{
    actions
    {
        addlast(Sections)
        {
            group(Subcontracting)
            {
                Caption = 'Subcontracting';
                action("Subc. Subcontracting Worksheet")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontracting Worksheets';
                    RunObject = page "Subc. Subcontracting Worksheet";
                    ToolTip = 'Calculate the needed production supply, find the production orders that have material ready to send to a subcontractor, and automatically create purchase orders for subcontracted operations from production order routings.';
                }
                action("Subc. Subcontractor Prices")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Subcontractor Prices';
                    RunObject = page "Subcontractor Prices";
                    ToolTip = 'View and maintain the prices that subcontractors charge for the operations they perform.';
                }
            }
        }
    }
}