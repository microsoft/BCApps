// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Sales.History;

/// <summary>
/// PageExtension Shpfy Post. Sales Shipments (ID 30110) extends Record Posted Sales Shipments.
/// </summary>
pageextension 30110 "Shpfy Post. Sales Shipments" extends "Posted Sales Shipments"
{
    layout
    {
        addafter("Package Tracking No.")
        {
            field(ShpfyOrderNo; Rec."Shpfy Order No.")
            {
                ApplicationArea = All;
                DrillDown = true;
                ToolTip = 'Specifies the order number from Shopify';
                Visible = false;

                trigger OnDrillDown()
                var
                    ShopifyOrderMgt: Codeunit "Shpfy Order Mgt.";
                    VariantRec: Variant;
                begin
                    VariantRec := Rec;
                    ShopifyOrderMgt.ShowShopifyOrder(VariantRec);
                end;
            }
        }
    }
    views
    {
        addlast
        {
            view(UnprocessedShipments)
            {
                Caption = 'Unprocessed Shipments to Shopify';
                Filters = where("Shpfy Order Id" = filter(<> 0), "Shpfy Fulfillment Id" = filter(= 0));
            }
            view(SkippedShipments)
            {
                Caption = 'Skipped Shipments to Shopify';
                Filters = where("Shpfy Order Id" = filter(<> 0), "Shpfy Fulfillment Id" = filter(= -1 | -2));
            }
        }
    }
}