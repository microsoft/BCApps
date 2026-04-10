// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

using Microsoft.Inventory.Item;

page 7511 "Item Variant Attribute Editor"
{
    Caption = 'Item Variant Attribute Values';
    PageType = StandardDialog;
    SourceTable = "Item Variant";

    layout
    {
        area(content)
        {
            part(ItemVariantAttributeValueList; "Item Variant Attr. Value List")
            {
                ApplicationArea = Basic, Suite;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.ItemVariantAttributeValueList.PAGE.LoadAttributes(Rec."Item No.", Rec.Code);
    end;
}
