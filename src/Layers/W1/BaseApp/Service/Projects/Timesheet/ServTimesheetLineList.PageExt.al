// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

pageextension 6484 "Serv. Time Sheet Line List" extends "Time Sheet Line List"
{
    layout
    {
        addafter("Work Type Code")
        {
            field("Service Order No."; Rec."Service Order No.")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies the service order number that is associated with the time sheet line.';
                Visible = ServiceOrderNoVisible;
            }
        }
    }
}