// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Analysis;

pageextension 6465 "Serv. Res. Gr. Avail. Lines" extends "Res. Gr. Availability Lines"
{
    layout
    {
        addafter("ResGr.""Qty. on Order (Job)""")
        {
#pragma warning disable AA0100
            field("ResGr.""Qty. on Service Order"""; Rec."Qty. on Service Order")
#pragma warning restore AA0100
            {
                ApplicationArea = Service;
                Caption = 'Qty. Allocated on Service Order';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the amount of measuring units allocated to service orders.';
            }
        }
    }
}