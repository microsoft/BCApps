// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

page 7500 "Item Attributes"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item Attributes';
    CardPageID = "Item Attribute";
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "Item Attribute";
    UsageCategory = Lists;
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Values; Rec.GetValues())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Values';
                    ToolTip = 'Specifies the values of the item attribute.';

                    trigger OnDrillDown()
                    begin
                        Rec.OpenItemAttributeValues();
                    end;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Attribute")
            {
                Caption = '&Attribute';
                action(ItemAttributeValues)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Attribute &Values';
                    Enabled = (Rec.Type = Rec.Type::Option);
                    Image = CalculateInventory;
                    RunObject = Page "Item Attribute Values";
                    RunPageLink = "Attribute ID" = field(ID);
                    ToolTip = 'Opens a window in which you can define the values for the selected item attribute.';
                }
                action(ItemAttributeTranslations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Translations';
                    Image = Translations;
                    RunObject = Page "Item Attribute Translations";
                    RunPageLink = "Attribute ID" = field(ID);
                    ToolTip = 'Opens a window in which you can define the translations for the selected item attribute.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ItemAttributeValues_Promoted; ItemAttributeValues)
                {
                }
                actionref(ItemAttributeTranslations_Promoted; ItemAttributeTranslations)
                {
                }
            }
        }
    }
}

