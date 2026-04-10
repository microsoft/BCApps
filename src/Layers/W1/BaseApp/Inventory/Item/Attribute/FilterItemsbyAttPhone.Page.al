// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

page 7509 "Filter Items by Att. Phone"
{
    Caption = 'Filter Items by Attribute';
    DataCaptionExpression = '';
    PageType = List;
    SourceTable = "Filter Item Attributes Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Attribute; Rec.Attribute)
                {
                    ApplicationArea = Basic, Suite;
                    TableRelation = "Item Attribute".Name;
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = true;

                    trigger OnAssistEdit()
                    begin
                        Rec.ValueAssistEdit();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        Rec.SetRange(Value, '');
        Rec.DeleteAll();
    end;
}

