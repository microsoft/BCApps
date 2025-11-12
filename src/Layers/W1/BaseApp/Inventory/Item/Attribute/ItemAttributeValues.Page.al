// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

page 7501 "Item Attribute Values"
{
    Caption = 'Item Attribute Values';
    DataCaptionFields = "Attribute ID";
    PageType = List;
    SourceTable = "Item Attribute Value";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the item attribute.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the attribute value cannot be assigned to an item. Items to which the attribute value is already assigned are not affected.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Process)
            {
                Caption = 'Process';
                action(ItemAttributeValueTranslations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Translations';
                    Image = Translations;
                    RunObject = Page "Item Attr. Value Translations";
                    RunPageLink = "Attribute ID" = field("Attribute ID"),
                                  ID = field(ID);
                    ToolTip = 'Opens a window in which you can specify the translations of the selected item attribute value.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ItemAttributeValueTranslations_Promoted; ItemAttributeValueTranslations)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AttributeID: Integer;
    begin
        if Rec.GetFilter("Attribute ID") <> '' then
            AttributeID := Rec.GetRangeMin("Attribute ID");
        if AttributeID <> 0 then begin
            Rec.FilterGroup(2);
            Rec.SetRange("Attribute ID", AttributeID);
            Rec.FilterGroup(0);
        end;
    end;
}

