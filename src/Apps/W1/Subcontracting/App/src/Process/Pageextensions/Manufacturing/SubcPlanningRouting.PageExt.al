// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Routing;

pageextension 99001515 "Subc. Planning Routing" extends "Planning Routing"
{
    layout
    {
        addlast(Control1)
        {
            field("Routing Link Code"; Rec."Routing Link Code")
            {
                ApplicationArea = Manufacturing;
                Editable = false;
                ToolTip = 'Specifies the routing link code.';
                Visible = false;
            }
        }
    }
}