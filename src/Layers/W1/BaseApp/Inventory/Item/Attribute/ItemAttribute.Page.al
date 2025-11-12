// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

page 7503 "Item Attribute"
{
    Caption = 'Item Attribute';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Item Attribute";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            group(Control9)
            {
                ShowCaption = false;
                group(Control2)
                {
                    ShowCaption = false;
                    field(Name; Rec.Name)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the name of the item attribute.';
                    }
                    field(Type; Rec.Type)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the type of the item attribute.';

                        trigger OnValidate()
                        begin
                            UpdateControlVisibility();
                        end;
                    }
                    field(Blocked; Rec.Blocked)
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies that the attribute cannot be assigned to an item. Items to which the attribute is already assigned are not affected.';
                    }
                }
                group(Control11)
                {
                    ShowCaption = false;
                    Visible = ValuesDrillDownVisible;
                    field(Values; Rec.GetValues())
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Values';
                        Editable = false;
                        ToolTip = 'Specifies the values of the item attribute.';

                        trigger OnDrillDown()
                        begin
                            Rec.OpenItemAttributeValues();
                        end;
                    }
                }
                group(Control13)
                {
                    ShowCaption = false;
                    Visible = UnitOfMeasureVisible;
                    field("Unit of Measure"; Rec."Unit of Measure")
                    {
                        ApplicationArea = Basic, Suite;
                        DrillDown = false;
                        ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';

                        trigger OnDrillDown()
                        begin
                            Rec.OpenItemAttributeValues();
                        end;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ItemAttributeValues)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Attribute &Values';
                Enabled = ValuesDrillDownVisible;
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

    trigger OnAfterGetCurrRecord()
    begin
        UpdateControlVisibility();
    end;

    trigger OnOpenPage()
    begin
        UpdateControlVisibility();
    end;

    var
        ValuesDrillDownVisible: Boolean;
        UnitOfMeasureVisible: Boolean;

    local procedure UpdateControlVisibility()
    begin
        ValuesDrillDownVisible := (Rec.Type = Rec.Type::Option);
        UnitOfMeasureVisible := (Rec.Type = Rec.Type::Decimal) or (Rec.Type = Rec.Type::Integer);
    end;
}

