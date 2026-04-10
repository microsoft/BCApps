// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

page 7508 "Select Item Attribute Value"
{
    Caption = 'Select Item Attribute Value';
    DataCaptionExpression = '';
    PageType = StandardDialog;
    SourceTable = "Item Attribute Value";

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the option.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Clear(DummySelectedItemAttributeValue);
        CurrPage.SetSelectionFilter(DummySelectedItemAttributeValue);
    end;

    var
        DummySelectedItemAttributeValue: Record "Item Attribute Value";

    procedure GetSelectedValue(var ItemAttributeValue: Record "Item Attribute Value")
    begin
        ItemAttributeValue.Copy(DummySelectedItemAttributeValue);
    end;
}

