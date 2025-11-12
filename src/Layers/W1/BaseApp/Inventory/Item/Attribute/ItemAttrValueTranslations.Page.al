// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

using System.Globalization;

page 7505 "Item Attr. Value Translations"
{
    Caption = 'Item Attribute Value Translations';
    DataCaptionExpression = DynamicCaption;
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Item Attr. Value Translation";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Languages;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the translated name of the item attribute value.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateWindowCaption();
    end;

    var
        DynamicCaption: Text;

    local procedure UpdateWindowCaption()
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        if ItemAttributeValue.Get(Rec."Attribute ID", Rec.ID) then
            DynamicCaption := ItemAttributeValue.Value
        else
            DynamicCaption := '';
    end;
}

