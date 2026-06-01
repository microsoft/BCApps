// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item;

page 30175 "Shpfy Product Collections"
{
    ApplicationArea = All;
    Caption = 'Shopify Custom Product Collections';
    PageType = List;
    SourceTable = "Shpfy Product Collection";
    InsertAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(Id; Rec.Id) { }
                field(Name; Rec.Name) { }
                field(Default; Rec.Default) { }
                field(ItemFilter; ItemFilter)
                {
                    Caption = 'Item Filter';
                    ToolTip = 'Specifies the filter criteria for the items in the product collection.';

                    trigger OnAssistEdit()
                    var
                        Item: Record Item;
                        FilterPageBuilder: FilterPageBuilder;
                    begin
                        FilterPageBuilder.AddTable(Item.TableCaption(), Database::Item);
                        if ItemFilter <> '' then
                            FilterPageBuilder.SetView(Item.TableCaption(), ItemFilter);
                        if FilterPageBuilder.RunModal() then begin
                            ItemFilter := FilterPageBuilder.GetView(Item.TableCaption(), false);
                            Rec.SetItemFilter(ItemFilter);
                        end;
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(GetProductCollections)
            {
                Caption = 'Get Custom Product Collections';
                Image = UpdateDescription;
                ToolTip = 'Retrieves the custom product collections from Shopify.';

                trigger OnAction()
                var
                    ProductCollectionAPI: Codeunit "Shpfy Product Collection API";
                begin
                    ProductCollectionAPI.RetrieveCustomProductCollectionsFromShopify(CopyStr(Rec.GetFilter("Shop Code"), 1, 20));
                end;
            }
        }
        area(Promoted)
        {
            actionref(PromotedGetProductCollections; GetProductCollections) { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ItemFilter := Rec.GetItemFilter();
    end;

    var
        ItemFilter: Text;
}