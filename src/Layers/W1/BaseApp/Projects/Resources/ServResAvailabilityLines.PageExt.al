// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Analysis;

pageextension 6495 "Serv. Res. Availability Lines" extends "Res. Availability Lines"
{
    layout
    {
        addafter(CapacityAfterQuotes)
        {
#pragma warning disable AA0100
            field("Resource.""Qty. on Service Order"""; Rec."Qty. on Service Order")
#pragma warning restore AA0100
            {
                ApplicationArea = Service;
                Caption = 'Qty. on Service Order';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies how many units of the item are allocated to service orders, meaning listed on outstanding service order lines.';
            }
        }
    }
}
