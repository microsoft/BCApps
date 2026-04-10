// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;

page 99000884 "Create Order From Sales"
{
    Caption = 'Create Order From Sales';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    InstructionalText = 'Do you want to create production orders for this sales order?';
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ConfirmationDialog;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field(Status; CreateStatus)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Prod. Order Status';

                trigger OnValidate()
                begin

                end;
            }
            field(OrderType; OrderType)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Order Type';
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CreateStatus := CreateStatus::"Firm Planned";
        OrderStatus := CreateStatus;
    end;

    var
        OrderStatus: Enum "Production Order Status";
        CreateStatus: Enum "Create Production Order Status";
        OrderType: Enum "Create Production Order Type";

    procedure GetParameters(var NewStatus: Enum "Production Order Status"; var NewOrderType: Enum "Create Production Order Type")
    begin
        NewStatus := CreateStatus;
        NewOrderType := OrderType;
    end;

    procedure SetParameters(NewStatus: Enum "Create Production Order Status"; NewOrderType: Enum "Create Production Order Type")
    begin
        OrderStatus := NewStatus;
        CreateStatus := OrderStatus;
        OrderType := NewOrderType;
    end;
}

