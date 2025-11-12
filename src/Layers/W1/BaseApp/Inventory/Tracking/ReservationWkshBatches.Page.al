// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

page 329 "Reservation Wksh. Batches"
{
    PageType = List;
    ApplicationArea = Reservation;
    SourceTable = "Reservation Wksh. Batch";
    CardPageId = "Reservation Wksh. Batch Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the reservation worksheet you are creating.';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies a brief description of the reservation worksheet name you are creating.';
                }
            }
        }
    }
}
