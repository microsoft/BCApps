// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item;

/// <summary>
/// Page Shpfy Order Subform (ID 30122).
/// </summary>
page 30122 "Shpfy Order Subform"
{
    Caption = 'Shopify Order Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Shpfy Order Line";

    layout
    {
        area(content)
        {
            repeater(Group9)
            {
                field(ShopifyProductId; Rec."Shopify Product Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies a unique identifier for the product.';
                }
                field(ShopifyVariantId; Rec."Shopify Variant Id")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies a unique identifier for the variant.';
                }
                field(ItemNo; Rec."Item No.")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the item number.';

                    trigger OnValidate()
                    var
                        Item: Record Item;
                    begin
                        if Item.Get(Rec."Item No.") then
                            if Item."Sales Unit of Measure" <> '' then
                                Rec."Unit of Measure Code" := Item."Sales Unit of Measure"
                            else
                                Rec."Unit of Measure Code" := Item."Base Unit of Measure";
                    end;
                }
                field(UnitOfMeasureCode; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    ToolTip = 'Specifies how each unit of the item is measured.';
                }
                field(VariantCode; Rec."Variant Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the description of the product to be sold.';
                }
                field(VariantDescription; Rec."Variant Description")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the description of the variant to be sold.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies how many units are being sold.';
                }
                field(UnitPrice; Rec."Unit Price")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the prices for one unit on the line.';
                }
                field("Presentment Unit Price"; Rec."Presentment Unit Price")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = PresentmentCurrencyVisible;
                }
                field(DiscountAmount; Rec."Discount Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';

                }
                field("Presentment Discount Amount"; Rec."Presentment Discount Amount")
                {
                    ApplicationArea = All;
                    Editable = false;
                    Visible = PresentmentCurrencyVisible;
                }
                field(FullfillableQuantity; Rec."Fulfillable Quantity")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the quantity available to fulfill.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RetrievedShopifyData)
            {
                ApplicationArea = All;
                Caption = 'Retrieved Shopify Data';
                Image = Entry;
                ToolTip = 'View the data retrieved from Shopify.';

                trigger OnAction();
                var
                    DataCapture: Record "Shpfy Data Capture";
                begin
                    DataCapture.SetCurrentKey("Linked To Table", "Linked To Id");
                    DataCapture.SetRange("Linked To Table", Database::"Shpfy Order Line");
                    DataCapture.SetRange("Linked To Id", Rec.SystemId);
                    Page.Run(Page::"Shpfy Data Capture List", DataCapture);
                end;
            }
        }
    }

    var
        PresentmentCurrencyVisible: Boolean;

    internal procedure SetShowPresentmentCurrency(Show: Boolean)
    begin
        PresentmentCurrencyVisible := Show;
    end;
}
