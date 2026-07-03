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

                trigger OnValidate()
                begin
                    UpdateWizardEditable();
                end;
            }
            field(UseProductDefinitionWizard; UseProductDefinitionWizard)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Use Production Definition Wizard';
                Editable = UseWizardEditable;
                ToolTip = 'Prepare to create a production order for the selected sales demand. Optionally use the Production Definition Wizard to customize the order for a single line.';
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

    protected var
        OrderType: Enum "Create Production Order Type";

    var
        OrderStatus: Enum "Production Order Status";
        CreateStatus: Enum "Create Production Order Status";
        UseProductDefinitionWizard: Boolean;
        SingleLineSelected: Boolean;
        UseWizardEditable: Boolean;


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

    /// <summary>
    /// Returns whether the Production Definition Wizard should be used for order creation.
    /// </summary>
    internal procedure GetUseProductDefinitionWizard(): Boolean
    begin
        exit(UseProductDefinitionWizard and SingleLineSelected);
    end;

    /// <summary>
    /// Sets whether exactly one sales planning line is selected on the parent page.
    /// Controls editability of the UseProductDefinitionWizard toggle.
    /// </summary>
    internal procedure SetSingleLineSelected(IsSingleLine: Boolean)
    begin
        SingleLineSelected := IsSingleLine;
        UpdateWizardEditable();
    end;

    local procedure UpdateWizardEditable()
    begin
        UseWizardEditable := SingleLineSelected and (OrderType = "Create Production Order Type"::ItemOrder);
        if not UseWizardEditable then
            UseProductDefinitionWizard := false;
    end;
}