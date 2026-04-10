#if not CLEAN28
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.RoleCenters;

pageextension 11010 "Manufacturing Manager RC DACH" extends "Manufacturing Manager RC"
{
    actions
    {
        addafter("Production Order Statistics")
        {
            action("Inventory Value (Help Report)")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Inventory Value (Help Report)';
                RunObject = Report Microsoft.Inventory.Reports."Inventory Value (Help Report)";
                ObsoleteReason = 'Delocalization of Manufacturing module';
                ObsoleteState = Pending;
                ObsoleteTag = '28.0';
            }
        }
    }
}
#endif