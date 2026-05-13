// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.RoleCenters;
using Microsoft.Purchases.Document;

pageextension 99001545 "Subc. Shop Super. Activities" extends "Shop Supervisor Activities"
{
    layout
    {
        addlast(content)
        {
            cuegroup(SubcontractingCuegroup)
            {
                Caption = 'Subcontracting';
                field("Subc. Purch. Lines Outstd."; Rec."Subc. Purch. Lines Outstd.")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageId = "Purchase Order List";
                    ToolTip = 'Specifies the number of outstanding subcontracting purchase order lines that have not yet been fully received.';
                }
                field("Subc. Purch. Lines Total"; Rec."Subc. Purch. Lines Total")
                {
                    ApplicationArea = Manufacturing;
                    DrillDownPageId = "Purchase Order List";
                    ToolTip = 'Specifies the total number of subcontracting purchase order lines.';
                }
            }
            cuegroup(SubcontractingActionsCuegroup)
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
