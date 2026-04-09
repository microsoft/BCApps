// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.RoleCenters;

pageextension 99001537 "Subc. Prod. Planner Activities" extends "Production Planner Activities"
{
    layout
    {
        addlast(content)
        {
            cuegroup(SubcontractingCuegroup)
            {
                Caption = 'Subcontracting - Operations';
                actions
                {
                    action("Subc. Edit Subcontracting Worksheet")
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Edit Subcontracting Worksheet';
                        RunObject = Page "Subc. Subcontracting Worksheet";
                        ToolTip = 'Plan outsourcing of operation on released production orders.';
                    }
                }
            }
        }
    }
}