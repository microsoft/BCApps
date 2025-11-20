// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

using Microsoft.Purchases.Pricing;
using Microsoft.Sales.Pricing;

page 7003 "Duplicate Price Lines"
{
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = Worksheet;
    SourceTable = "Duplicate Price Line";
    SourceTableView = sorting("Duplicate To Line No.", "Line No.");
    Caption = 'Duplicate Price Lines';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Remove; Rec.Remove)
                {
                    Caption = 'Remove';
                    ApplicationArea = All;
                    Editable = true;
                    ToolTip = 'Specifies if the price list line should be removed to resolve duplication.';
                }
                field("Price List Code"; Rec."Price List Code")
                {
                    Caption = 'Price List Code';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the unique identifier of the price list.';

                    trigger OnDrillDown()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.EditPriceList(Rec."Price List Code");
                    end;
                }
                field("Price List Line No."; Rec."Price List Line No.")
                {
                    Caption = 'Price List Line No.';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the number of the price list line.';
                }
                field("Source Type"; CurrPriceListLine."Source Type")
                {
                    Caption = 'Assign-to Type';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the type of entity to which the price list is assigned. The options are relevant to the entity you are currently viewing.';
                }
                field("Source No."; CurrPriceListLine."Source No.")
                {
                    Caption = 'Assign-to';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the entity to which the prices are assigned. The options depend on the selection in the Assign-to Type field. If you choose an entity, the price list will be used only for that entity.';
                }
                field("Asset Type"; CurrPriceListLine."Asset Type")
                {
                    Caption = 'Product Type';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the type of the product.';
                }
                field("Asset No."; CurrPriceListLine."Asset No.")
                {
                    Caption = 'Product No.';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the number of the product.';
                }
                field(Description; CurrPriceListLine.Description)
                {
                    Caption = 'Description';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the description of the product.';
                }
                field("Variant Code"; CurrPriceListLine."Variant Code")
                {
                    Caption = 'Variant Code';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the item variant.';
                }
                field("Work Type Code"; CurrPriceListLine."Work Type Code")
                {
                    Caption = 'Work Type Code';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the work type code for the resource.';
                }
                field("Unit of Measure Code"; CurrPriceListLine."Unit of Measure Code")
                {
                    Caption = 'Unit of Measure Code';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the unit of measure for the product.';
                }
                field("Minimum Quantity"; CurrPriceListLine."Minimum Quantity")
                {
                    Caption = 'Minimum Quantity';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the minimum quantity of the product.';
                }
                field("Amount Type"; CurrPriceListLine."Amount Type")
                {
                    Caption = 'Defines';
                    ApplicationArea = All;
                    Importance = Standard;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the data that is defined in the price list line. It can be either price or discount, or both';
                }
                field("Currency Code"; CurrPriceListLine."Currency Code")
                {
                    Caption = 'Currency Code';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the currency code of the price list.';
                }
                field("Unit Price"; CurrPriceListLine."Unit Price")
                {
                    Caption = 'Unit Price';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = PriceVisible and IsSalesPrice;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the unit price of the product.';
                }
                field("Cost Factor"; CurrPriceListLine."Cost Factor")
                {
                    Caption = 'Cost Factor';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = PriceVisible and IsSalesPrice;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the unit cost factor for project-related prices, if you have agreed with your customer that he should pay certain item usage by cost value plus a certain percent value to cover your overhead expenses.';
                }
                field("Unit Cost"; CurrPriceListLine."Unit Cost")
                {
                    Caption = 'Unit Cost';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = PriceVisible and not IsSalesPrice;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the unit cost of the product.';
                }
                field(DirectUnitCost; CurrPriceListLine."Direct Unit Cost")
                {
                    Caption = 'Direct Unit Cost';
                    ApplicationArea = All;
                    Editable = false;
                    Visible = PriceVisible and not IsSalesPrice;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the direct unit cost of the product.';
                }
                field("Allow Line Disc."; CurrPriceListLine."Allow Line Disc.")
                {
                    Caption = 'Allow Line Disc.';
                    ApplicationArea = All;
                    Visible = PriceVisible;
                    Editable = false;
                    ToolTip = 'Specifies if a line discount will be calculated when the price is offered.';
                }
                field("Line Discount %"; CurrPriceListLine."Line Discount %")
                {
                    Caption = 'Line Discount %';
                    AccessByPermission = tabledata "Sales Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible and IsSalesPrice;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field(PurchLineDiscountPct; CurrPriceListLine."Line Discount %")
                {
                    Caption = 'Line Discount %';
                    AccessByPermission = tabledata "Purchase Discount Access" = R;
                    ApplicationArea = All;
                    Visible = DiscountVisible and not IsSalesPrice;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the line discount percentage for the product.';
                }
                field("Allow Invoice Disc."; CurrPriceListLine."Allow Invoice Disc.")
                {
                    Caption = 'Allow Invoice Disc.';
                    ApplicationArea = All;
                    Visible = PriceVisible and IsSalesPrice;
                    Editable = false;
                    ToolTip = 'Specifies if an invoice discount will be calculated when the price is offered.';
                }
                field("Starting Date"; CurrPriceListLine."Starting Date")
                {
                    Caption = 'Starting Date';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the date from which the price is valid.';
                }
                field("Ending Date"; CurrPriceListLine."Ending Date")
                {
                    Caption = 'Ending Date';
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = not Rec.Remove;
                    Style = Strong;
                    ToolTip = 'Specifies the date when the price agreement ends.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if CurrPriceListLine.Get(Rec."Price List Code", Rec."Price List Line No.") then;
    end;

    protected var
        CurrPriceListLine: Record "Price List Line";
        DiscountVisible: Boolean;
        PriceVisible: Boolean;
        IsSalesPrice: Boolean;

    procedure Set(PriceType: Enum "Price Type"; AmountType: Enum "Price Amount Type"; var DuplicatePriceLine: Record "Duplicate Price Line")
    begin
        Rec.Copy(DuplicatePriceLine, true);
        DiscountVisible := AmountType in ["Price Amount Type"::Any, "Price Amount Type"::Discount];
        PriceVisible := AmountType in ["Price Amount Type"::Any, "Price Amount Type"::Price];
        IsSalesPrice := PriceType = "Price Type"::Sale;
    end;

    procedure GetLines(var DuplicatePriceLine: Record "Duplicate Price Line")
    begin
        DuplicatePriceLine.Copy(Rec, true);
    end;
}