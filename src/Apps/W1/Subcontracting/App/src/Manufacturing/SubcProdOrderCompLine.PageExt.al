// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Manufacturing.Document;

#pragma warning disable AS0072, AS0136
pageextension 20513 "Subc. ProdOrderCompLine" extends "Prod. Order Comp. Line List"
{
    layout
    {
        addlast(Control1)
        {
            field("Component Supply Method"; Rec."Component Supply Method")
            {
                ApplicationArea = Subcontracting;
                ToolTip = 'Specifies how components are supplied to the subcontractor for the production component.';
            }
        }
    }
}
#pragma warning restore AS0072, AS0136
