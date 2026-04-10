// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.SyncEngine;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Picture;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.MarketingText;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Pricing;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.ADCS;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.Automation;
using System.Environment;
using System.Environment.Configuration;
using System.Privacy;
using System.Text;

#pragma warning disable AS0106 // Protected variable ItemReferenceVisible was removed before AS0106 was introduced.
#pragma warning disable AS0031 // Action Ref Update Variant Attributes_Promoted was removed before AS0031 was introduced.
page 30 "Item Card"
#pragma warning restore AS0106
#pragma warning restore AS0031
{
    Caption = 'Item Card';
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = Item;
    AdditionalSearchTerms = 'Product, Finished Good, Component, Raw Material, Assembly Item, Product Details, Merchandise Profile, Item Info, Commodity Info, Product Data, Article Details, Goods Profile, Item Detail';

    AboutTitle = 'About item details';
    AboutText = 'With the **Item Card** you manage the information that appears in sales and purchase documents when you buy or sell an item, such as line description and price. You can also find settings for how an item is priced, replenished, stocked, and for how costing and posting is done.';

    layout
    {
        area(content)
        {
            group(Item)
            {
                Caption = 'Item';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoFieldVisible;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit() then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ShowMandatory = true;
                    AboutTitle = 'Describe the product or service';
                    AboutText = 'This appears on the documents you create when buying or selling this item. You can create Extended Texts with additional item description available to insert in the document lines.';
                    Visible = DescriptionFieldVisible;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    Visible = false;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example an item that is placed in quarantine.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        EnableControls();
                    end;
                }
                field("Base Unit of Measure"; Rec."Base Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ShowMandatory = true;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                        Rec.Get(Rec."No.");
                    end;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field(GTIN; Rec.GTIN)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = not IsService;
                    Importance = Additional;
                    ToolTip = 'Specifies the Global Trade Item Number (GTIN) for the item. For example, the GTIN is used with bar codes to track items, and when sending and receiving documents electronically. The GTIN number typically contains a Universal Product Code (UPC), or European Article Number (EAN).';
                }
                field("Item Category Code"; Rec."Item Category Code")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        CurrPage.ItemAttributesFactbox.PAGE.LoadItemAttributesData(Rec."No.");
                        EnableCostingControls();
                    end;
                }
                field("Manufacturer Code"; Rec."Manufacturer Code")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Automatic Ext. Texts"; Rec."Automatic Ext. Texts")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Common Item No."; Rec."Common Item No.")
                {
                    ApplicationArea = Intercompany;
                    Importance = Additional;
                }
                field("Purchasing Code"; Rec."Purchasing Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field(VariantMandatoryDefaultYes; Rec."Variant Mandatory if Exists")
                {
                    ApplicationArea = Basic, Suite;
                    OptionCaption = 'Default (Yes),No,Yes';
                    ToolTip = 'Specifies whether a variant must be selected if variants exist for the item. ';
                    Visible = ShowVariantMandatoryDefaultYes;
                }
                field(VariantMandatoryDefaultNo; Rec."Variant Mandatory if Exists")
                {
                    ApplicationArea = Basic, Suite;
                    OptionCaption = 'Default (No),No,Yes';
                    ToolTip = 'Specifies whether a variant must be selected if variants exist for the item. ';
                    Visible = not ShowVariantMandatoryDefaultYes;
                }
                field("Statistics Group"; Rec."Statistics Group")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("No. 2"; Rec."No. 2")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    Importance = Additional;
                }
                field("Alternative Item No."; Rec."Alternative Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                    Importance = Additional;
                }
            }
            group(InventoryGrp)
            {
                Caption = 'Inventory';
                Visible = IsInventoriable;
                AboutTitle = 'For items on inventory';
                AboutText = 'Here are settings and information for an item that is kept on inventory. See or update the available inventory, current orders, physical volume and weight, and settings for low inventory handling.';

                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Created From Nonstock Item"; Rec."Created From Nonstock Item")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field(Inventory; Rec.Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    Enabled = IsInventoriable;
                    HideValue = IsNonInventoriable;
                    Importance = Promoted;
                    Visible = IsInventoryAdjmtAllowed;

                    trigger OnAssistEdit()
                    var
                        AdjustInventory: Page "Adjust Inventory";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);

                        if RecRef.IsDirty() then begin
                            Rec.Modify(true);
                            Commit();
                        end;

                        AdjustInventory.SetItem(Rec."No.");
                        if AdjustInventory.RunModal() in [ACTION::LookupOK, ACTION::OK] then
                            Rec.Get(Rec."No.");
                        CurrPage.Update()
                    end;
                }
                field(InventoryNonFoundation; Rec.Inventory)
                {
                    ApplicationArea = Basic, Suite;
                    AssistEdit = false;
                    Caption = 'Inventory';
                    Enabled = IsInventoriable;
                    Importance = Promoted;
                    ToolTip = 'Specifies how many units, such as pieces, boxes, or cans, of the item are in inventory.';
                    Visible = not IsInventoryAdjmtAllowed;
                }
                field("Qty. on Purch. Order"; Rec."Qty. on Purch. Order")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Qty. on Sales Order"; Rec."Qty. on Sales Order")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Qty. on Job Order"; Rec."Qty. on Job Order")
                {
                    ApplicationArea = Jobs;
                    Importance = Additional;
                }
                field("Qty. on Blanket Sales Order"; Rec."Qty. on Blanket Sales Order")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Qty. on Blanket Purch. Order"; Rec."Qty. on Blanket Purch. Order")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field(StockoutWarningDefaultYes; Rec."Stockout Warning")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsInventoriable;
                    OptionCaption = 'Default (Yes),No,Yes';
                    Visible = ShowStockoutWarningDefaultYes;
                }
                field(StockoutWarningDefaultNo; Rec."Stockout Warning")
                {
                    ApplicationArea = Basic, Suite;
                    OptionCaption = 'Default (No),No,Yes';
                    ToolTip = 'Specifies if a warning is displayed when you enter a quantity on a sales document that brings the item''s inventory below zero.';
                    Visible = ShowStockoutWarningDefaultNo;
                }
                field(PreventNegInventoryDefaultYes; Rec."Prevent Negative Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Prevent Negative Inventory';
                    Importance = Additional;
                    OptionCaption = 'Default (Yes),No,Yes';
                    Visible = ShowPreventNegInventoryDefaultYes;
                }
                field(PreventNegInventoryDefaultNo; Rec."Prevent Negative Inventory")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Prevent Negative Inventory';
                    Importance = Additional;
                    OptionCaption = 'Default (No),No,Yes';
                    ToolTip = 'Specifies if you can post a transaction that will bring the item''s inventory below zero.';
                    Visible = ShowPreventNegInventoryDefaultNo;
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Gross Weight"; Rec."Gross Weight")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Unit Volume"; Rec."Unit Volume")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Over-Receipt Code"; Rec."Over-Receipt Code")
                {
                    ApplicationArea = All;
                    Visible = OverReceiptAllowed;
                }
                field("Trans. Ord. Receipt (Qty.)"; Rec."Trans. Ord. Receipt (Qty.)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the items that remains to be received but are not yet shipped as the difference between the Quantity and the Quantity Shipped fields.';
                    Visible = false;
                }
                field("Trans. Ord. Shipment (Qty.)"; Rec."Trans. Ord. Shipment (Qty.)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of the items that remains to be shipped as the difference between the Quantity and the Quantity Shipped fields.';
                    Visible = false;
                }
                field("Qty. in Transit"; Rec."Qty. in Transit")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
            }
            group("Costs & Posting")
            {
                Caption = 'Costs & Posting';
                AboutTitle = 'Manage costs and posting';
                AboutText = 'Choose how the item costs are calculated, and assign posting groups to control how transactions with this item are grouped and posted.';

                group("Cost Details")
                {
                    Caption = 'Cost Details';
                    field("Costing Method"; Rec."Costing Method")
                    {
                        ApplicationArea = Basic, Suite;

                        trigger OnValidate()
                        begin
                            EnableCostingControls();
                        end;
                    }
                    field("Standard Cost"; Rec."Standard Cost")
                    {
                        ApplicationArea = Basic, Suite;
                        Enabled = StandardCostEnable;

                        trigger OnDrillDown()
                        var
                            ShowAvgCalcItem: Codeunit "Show Avg. Calc. - Item";
                        begin
                            ShowAvgCalcItem.DrillDownAvgCostAdjmtPoint(Rec)
                        end;
                    }
                    field("Unit Cost"; Rec."Unit Cost")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = UnitCostEditable;
                        Enabled = UnitCostEnable;
                        Importance = Promoted;

                        trigger OnDrillDown()
                        var
                            ShowAvgCalcItem: Codeunit "Show Avg. Calc. - Item";
                            IsHandled: Boolean;
                        begin
                            IsHandled := false;
                            OnBeforeUnitCostOnDrilldown(Rec, IsHandled);
                            if IsHandled then
                                exit;

                            ShowAvgCalcItem.DrillDownAvgCostAdjmtPoint(Rec)
                        end;
                    }
                    field("Indirect Cost %"; Rec."Indirect Cost %")
                    {
                        ApplicationArea = Basic, Suite;
                        Enabled = IsInventoriable;
                        Importance = Additional;
                    }
                    field("Last Direct Cost"; Rec."Last Direct Cost")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                    }
                    field("Net Invoiced Qty."; Rec."Net Invoiced Qty.")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Cost is Adjusted"; Rec."Cost is Adjusted")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Excluded from Cost Adjustment"; Rec."Excluded from Cost Adjustment")
                    {
                        ApplicationArea = Basic, Suite;
                        Visible = false;
                    }
                    field("Cost is Posted to G/L"; Rec."Cost is Posted to G/L")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                    }
                    field("Inventory Value Zero"; Rec."Inventory Value Zero")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        Visible = false;
                    }
                    field(SpecialPurchPriceListTxt; GetPurchPriceListsText())
                    {
                        ApplicationArea = Suite;
                        Caption = 'Purchase Prices & Discounts';
                        Editable = false;
                        Visible = ExtendedPriceEnabled;
                        ToolTip = 'Specifies purchase price lists for the item.';

                        trigger OnDrillDown()
                        var
                            AmountType: Enum "Price Amount Type";
                            PriceType: Enum "Price Type";
                        begin
                            if PurchPriceListsText = ViewExistingTxt then
                                Rec.ShowPriceListLines(PriceType::Purchase, AmountType::Any)
                            else
                                PAGE.RunModal(Page::"Purchase Price Lists");
                            UpdateSpecialPriceListsTxt(PriceType::Purchase);
                        end;
                    }
                    field(SpecialPurchPricesAndDiscountsTxt; SpecialPurchPricesAndDiscountsTxt)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Purchase Prices & Discounts';
                        Editable = false;
                        Visible = not ExtendedPriceEnabled;
                        ToolTip = 'Specifies purchase prices and line discounts for the item.';

                        trigger OnDrillDown()
                        var
                            PurchasePrice: Record "Purchase Price";
                            PurchaseLineDiscount: Record "Purchase Line Discount";
                            PurchasesPriceAndLineDisc: Page "Purchases Price and Line Disc.";
                        begin
                            if SpecialPurchPricesAndDiscountsTxt = ViewExistingTxt then begin
                                PurchasesPriceAndLineDisc.LoadItem(Rec);
                                PurchasesPriceAndLineDisc.RunModal();
                                exit;
                            end;

                            case StrMenu(StrSubstNo('%1,%2', CreateNewSpecialPriceTxt, CreateNewSpecialDiscountTxt), 1, '') of
                                1:
                                    begin
                                        PurchasePrice.SetRange("Item No.", Rec."No.");
                                        PAGE.RunModal(Page::"Purchase Prices", PurchasePrice);
                                    end;
                                2:
                                    begin
                                        PurchaseLineDiscount.SetRange("Item No.", Rec."No.");
                                        PAGE.RunModal(Page::"Purchase Line Discounts", PurchaseLineDiscount);
                                    end;
                            end;

                            UpdateSpecialPricesAndDiscountsTxt();
                        end;
                    }
                }
                group("Posting Details")
                {
                    Caption = 'Posting Details';
                    field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Promoted;
                        ShowMandatory = true;
                    }
                    field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                        ShowMandatory = true;
                        ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    }
                    field("Tax Group Code"; Rec."Tax Group Code")
                    {
                        ApplicationArea = SalesTax;
                        Importance = Promoted;
                    }
                    field("Inventory Posting Group"; Rec."Inventory Posting Group")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = IsInventoriable;
                        Importance = Promoted;
                        ShowMandatory = IsInventoriable;
                    }
                    field("Default Deferral Template Code"; Rec."Default Deferral Template Code")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Default Deferral Template';
                        ToolTip = 'Specifies how revenue or expenses for the item are deferred to other accounting periods by default.';
                    }
                }
                group(ForeignTrade)
                {
                    Caption = 'Foreign Trade';
                    field("Tariff No."; Rec."Tariff No.")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Country/Region of Origin Code"; Rec."Country/Region of Origin Code")
                    {
                        ApplicationArea = Basic, Suite;
                        Importance = Additional;
                    }
                }
            }
            group("Prices & Sales")
            {
                Caption = 'Prices & Sales';
                AboutTitle = 'Track prices and profits';
                AboutText = 'Specify a basic price and the related profit for this item, and define special prices and discounts to certain customers. In either case, the prices defined here can be overridden at the time a document is posted.';

                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = PriceEditable;
                    Importance = Promoted;
                }
                field(CalcUnitPriceExclVAT; Rec.CalcUnitPriceExclVAT())
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 2;
                    AutoFormatExpression = '';
                    CaptionClass = '2,0,' + Rec.FieldCaption("Unit Price");
                    Importance = Additional;
                    ToolTip = 'Specifies the unit price excluding VAT.';
                }
                field("Price Includes VAT"; Rec."Price Includes VAT")
                {
                    ApplicationArea = VAT;
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        if Rec."Price Includes VAT" = xRec."Price Includes VAT" then
                            exit;
                    end;
                }
                field("Price/Profit Calculation"; Rec."Price/Profit Calculation")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;

                    trigger OnValidate()
                    begin
                        EnableControls();
                    end;
                }
                field("Profit %"; Rec."Profit %")
                {
                    ApplicationArea = Basic, Suite;
                    DecimalPlaces = 2 : 2;
                    Editable = ProfitEditable;
                }
                field(SpecialSalesPriceListTxt; GetSalesPriceListsText())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices & Discounts';
                    Editable = false;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Specifies sales price lists for the item.';

                    trigger OnDrillDown()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        if SalesPriceListsText = ViewExistingTxt then
                            Rec.ShowPriceListLines(PriceType::Sale, AmountType::Any)
                        else
                            PAGE.RunModal(Page::"Sales Price Lists");
                        UpdateSpecialPriceListsTxt(PriceType::Sale);
                    end;
                }
                field(SpecialPricesAndDiscountsTxt; SpecialPricesAndDiscountsTxt)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices & Discounts';
                    Editable = false;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'Specifies sales prices and line discounts for the item.';

                    trigger OnDrillDown()
                    var
                        SalesPrice: Record "Sales Price";
                        SalesLineDiscount: Record "Sales Line Discount";
                        SalesPriceAndLineDiscounts: Page "Sales Price and Line Discounts";
                    begin
                        if SpecialPricesAndDiscountsTxt = ViewExistingTxt then begin
                            SalesPriceAndLineDiscounts.InitPage(true);
                            SalesPriceAndLineDiscounts.LoadItem(Rec);
                            SalesPriceAndLineDiscounts.RunModal();
                            exit;
                        end;

                        case StrMenu(StrSubstNo('%1,%2', CreateNewSpecialPriceTxt, CreateNewSpecialDiscountTxt), 1, '') of
                            1:
                                begin
                                    SalesPrice.SetRange("Item No.", Rec."No.");
                                    PAGE.RunModal(Page::"Sales Prices", SalesPrice);
                                end;
                            2:
                                begin
                                    SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::Item);
                                    SalesLineDiscount.SetRange(Code, Rec."No.");
                                    PAGE.RunModal(Page::"Sales Line Discounts", SalesLineDiscount);
                                end;
                        end;

                        UpdateSpecialPricesAndDiscountsTxt();
                    end;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Item Disc. Group"; Rec."Item Disc. Group")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Sales Unit of Measure"; Rec."Sales Unit of Measure")
                {
                    ApplicationArea = Suite;
                }
                field("Sales Blocked"; Rec."Sales Blocked")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the item cannot be entered on sales documents, except return orders and credit memos, and journals.';
                }
                field("Service Blocked"; Rec."Service Blocked")
                {
                    ApplicationArea = Service;
                }
                field("Application Wksh. User ID"; Rec."Application Wksh. User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    Visible = false;
                }
                field("VAT Bus. Posting Gr. (Price)"; Rec."VAT Bus. Posting Gr. (Price)")
                {
                    ApplicationArea = Advanced;
                    ToolTip = 'Specifies the VAT business posting group for customers for whom you want the sales price including VAT to apply.';
                }
            }
            group(Replenishment)
            {
                Caption = 'Replenishment';
                field("Replenishment System"; ItemReplenishmentSystem)
                {
                    ApplicationArea = Assembly, Planning;
                    Caption = 'Replenishment System';
                    Editable = ReplenishmentSystemEditable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of supply order created by the planning system when the item needs to be replenished.';

                    trigger OnValidate()
                    begin
                        Rec.Validate("Replenishment System", ItemReplenishmentSystem);
                    end;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Assembly, Planning;
                }
                group(Purchase)
                {
                    Caption = 'Purchase';
                    field("Vendor No."; Rec."Vendor No.")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("Vendor Item No."; Rec."Vendor Item No.")
                    {
                        ApplicationArea = Planning;
                    }
                    field("Purch. Unit of Measure"; Rec."Purch. Unit of Measure")
                    {
                        ApplicationArea = Planning;
                    }
                    field("Purchasing Blocked"; Rec."Purchasing Blocked")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                }
                group(Replenishment_Assembly)
                {
                    Caption = 'Assembly';
                    Visible = IsInventoriable;
                    field("Assembly Policy"; Rec."Assembly Policy")
                    {
                        ApplicationArea = Assembly;
                    }
                    field(AssemblyBOM; Rec."Assembly BOM")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;

                        trigger OnDrillDown()
                        var
                            BOMComponent: Record "BOM Component";
                        begin
                            Commit();
                            BOMComponent.SetRange("Parent Item No.", Rec."No.");
                            PAGE.Run(PAGE::"Assembly BOM", BOMComponent);
                            CurrPage.Update();
                        end;
                    }
                }
            }
            group(Planning)
            {
                Caption = 'Planning';
                Visible = IsInventoriable;
                field("Reordering Policy"; Rec."Reordering Policy")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                    ToolTip = 'Specifies the reordering policy.';

                    trigger OnValidate()
                    begin
                        EnablePlanningControls();
                    end;
                }
                field(Reserve; Rec.Reserve)
                {
                    ApplicationArea = Reservation;
                    Importance = Additional;
                }
                field("Order Tracking Policy"; Rec."Order Tracking Policy")
                {
                    ApplicationArea = Planning;
                    Importance = Promoted;
                }
                field("Stockkeeping Unit Exists"; Rec."Stockkeeping Unit Exists")
                {
                    ApplicationArea = Planning;
                }
                field("Dampener Period"; Rec."Dampener Period")
                {
                    ApplicationArea = Planning;
                    Enabled = DampenerPeriodEnable;
                    Importance = Additional;
                    ToolTip = 'Specifies a period of time during which you do not want the planning system to propose to reschedule existing supply orders forward. The dampener period limits the number of insignificant rescheduling of existing supply to a later date if that new date is within the dampener period. The dampener period function is only initiated if the supply can be rescheduled to a later date and not if the supply can be rescheduled to an earlier date. Accordingly, if the suggested new supply date is after the dampener period, then the rescheduling suggestion is not blocked. If the lot accumulation period is less than the dampener period, then the dampener period is dynamically set to equal the lot accumulation period. This is not shown in the value that you enter in the Dampener Period field. The last demand in the lot accumulation period is used to determine whether a potential supply date is in the dampener period. If this field is empty, then the value in the Default Dampener Period field in the Manufacturing Setup window applies. The value that you enter in the Dampener Period field must be a date formula, and one day (1D) is the shortest allowed period.';
                }
                field("Dampener Quantity"; Rec."Dampener Quantity")
                {
                    ApplicationArea = Planning;
                    Enabled = DampenerQtyEnable;
                    Importance = Additional;
                }
                field(Critical; Rec.Critical)
                {
                    ApplicationArea = OrderPromising;
                }
                field("Safety Lead Time"; Rec."Safety Lead Time")
                {
                    ApplicationArea = Planning;
                    Enabled = SafetyLeadTimeEnable;
                }
                field("Safety Stock Quantity"; Rec."Safety Stock Quantity")
                {
                    ApplicationArea = Planning;
                    Enabled = SafetyStockQtyEnable;
                }
                group(LotForLotParameters)
                {
                    Caption = 'Lot-for-Lot Parameters';
                    field("Include Inventory"; Rec."Include Inventory")
                    {
                        ApplicationArea = Planning;
                        Enabled = IncludeInventoryEnable;

                        trigger OnValidate()
                        begin
                            EnablePlanningControls();
                        end;
                    }
                    field("Lot Accumulation Period"; Rec."Lot Accumulation Period")
                    {
                        ApplicationArea = Planning;
                        Enabled = LotAccumulationPeriodEnable;
                    }
                    field("Rescheduling Period"; Rec."Rescheduling Period")
                    {
                        ApplicationArea = Planning;
                        Enabled = ReschedulingPeriodEnable;
                    }
                }
                group(ReorderPointParameters)
                {
                    Caption = 'Reorder-Point Parameters';
                    group(Control64)
                    {
                        ShowCaption = false;
                        field("Reorder Point"; Rec."Reorder Point")
                        {
                            ApplicationArea = Planning;
                            Enabled = ReorderPointEnable;
                        }
                        field("Reorder Quantity"; Rec."Reorder Quantity")
                        {
                            ApplicationArea = Planning;
                            Enabled = ReorderQtyEnable;
                        }
                        field("Maximum Inventory"; Rec."Maximum Inventory")
                        {
                            ApplicationArea = Planning;
                            Enabled = MaximumInventoryEnable;
                        }
                    }
                    field("Overflow Level"; Rec."Overflow Level")
                    {
                        ApplicationArea = Planning;
                        Enabled = OverflowLevelEnable;
                        Importance = Additional;
                    }
                    field("Time Bucket"; Rec."Time Bucket")
                    {
                        ApplicationArea = Planning;
                        Enabled = TimeBucketEnable;
                        Importance = Additional;
                    }
                }
                group(OrderModifiers)
                {
                    Caption = 'Order Modifiers';
                    group(Control61)
                    {
                        ShowCaption = false;
                        field("Minimum Order Quantity"; Rec."Minimum Order Quantity")
                        {
                            ApplicationArea = Planning;
                            Enabled = MinimumOrderQtyEnable;
                        }
                        field("Maximum Order Quantity"; Rec."Maximum Order Quantity")
                        {
                            ApplicationArea = Planning;
                            Enabled = MaximumOrderQtyEnable;
                        }
                        field("Order Multiple"; Rec."Order Multiple")
                        {
                            ApplicationArea = Planning;
                            Enabled = OrderMultipleEnable;
                        }
                    }
                }
            }
            group(ItemTracking)
            {
                Caption = 'Item Tracking';
                Visible = IsInventoriable;
                field("Item Tracking Code"; Rec."Item Tracking Code")
                {
                    ApplicationArea = ItemTracking;
                    Importance = Promoted;

                    trigger OnValidate()
                    begin
                        SetExpirationCalculationEditable();
                    end;
                }
                field("Serial Nos."; Rec."Serial Nos.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Lot Nos."; Rec."Lot Nos.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Expiration Calculation"; Rec."Expiration Calculation")
                {
                    ApplicationArea = ItemTracking;
                    Editable = ExpirationCalculationEditable;

                    trigger OnValidate()
                    begin
                        Rec.Validate("Item Tracking Code");
                    end;
                }
            }
            group(Warehouse)
            {
                Caption = 'Warehouse';
                Visible = IsInventoriable;
                field("Warehouse Class Code"; Rec."Warehouse Class Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Special Equipment Code"; Rec."Special Equipment Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                }
                field("Put-away Template Code"; Rec."Put-away Template Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Put-away Unit of Measure Code"; Rec."Put-away Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                }
                field("Phys Invt Counting Period Code"; Rec."Phys Invt Counting Period Code")
                {
                    ApplicationArea = Warehouse;
                    Importance = Promoted;
                }
                field("Last Phys. Invt. Date"; Rec."Last Phys. Invt. Date")
                {
                    ApplicationArea = Warehouse;
                }
                field("Last Counting Period Update"; Rec."Last Counting Period Update")
                {
                    ApplicationArea = Warehouse;
                }
                field("Next Counting Start Date"; Rec."Next Counting Start Date")
                {
                    ApplicationArea = Warehouse;
                }
                field("Next Counting End Date"; Rec."Next Counting End Date")
                {
                    ApplicationArea = Warehouse;
                }
                field("Identifier Code"; Rec."Identifier Code")
                {
                    ApplicationArea = Advanced;
                    Importance = Additional;
                }
                field("Use Cross-Docking"; Rec."Use Cross-Docking")
                {
                    ApplicationArea = Warehouse;
                    Importance = Additional;
                }
            }
        }
        area(factboxes)
        {
            part(ItemPicture; "Item Picture")
            {
                ApplicationArea = All;
                Caption = 'Picture';
                SubPageLink = "No." = field("No.");
            }
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documents';
                UpdatePropagation = Both;
                SubPageLink = "Table ID" = const(Database::Item),
                              "No." = field("No.");
            }
            part(EntityTextFactBox; "Entity Text Factbox Part")
            {
                ApplicationArea = Basic, Suite;
                Visible = EntityTextEnabled;
                Caption = 'Marketing Text';
            }
            part(ItemAttributesFactbox; "Item Attributes Factbox")
            {
                ApplicationArea = Basic, Suite;
            }
            part(WorkflowStatus; "Workflow Status FactBox")
            {
                ApplicationArea = Suite;
                Editable = false;
                Enabled = false;
                ShowFilter = false;
                Visible = ShowWorkflowStatus;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(PricesandDiscounts)
            {
                Caption = 'Sales Prices & Discounts';
                action("Set Special Prices")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    Image = Price;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'Set up sales prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        SalesPrice: Record "Sales Price";
                    begin
                        SalesPrice.SetRange("Item No.", Rec."No.");
                        Page.Run(Page::"Sales Prices", SalesPrice);
                    end;
                }
                action("Set Special Discounts")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Discounts';
                    Image = LineDiscount;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'Set up sales discounts for the item. An item discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        SalesLineDiscount: Record "Sales Line Discount";
                    begin
                        SalesLineDiscount.SetCurrentKey(Type, Code);
                        SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::Item);
                        SalesLineDiscount.SetRange(Code, Rec."No.");
                        Page.Run(Page::"Sales Line Discounts", SalesLineDiscount);
                    end;
                }
                action(PricesDiscountsOverview)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices & Discounts Overview';
                    Image = PriceWorksheet;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View the sales prices and line discounts that you grant for this item when certain criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        SalesPriceAndLineDiscounts: Page "Sales Price and Line Discounts";
                    begin
                        SalesPriceAndLineDiscounts.InitPage(true);
                        SalesPriceAndLineDiscounts.LoadItem(Rec);
                        SalesPriceAndLineDiscounts.RunModal();
                    end;
                }
                action(SalesPriceLists)
                {
                    AccessByPermission = TableData "Sales Price Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Set up sales prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        Rec.ShowPriceListLines(PriceType::Sale, AmountType::Price);
                        UpdateSpecialPriceListsTxt(PriceType::Sale);
                    end;
                }
                action(SalesPriceListsDiscounts)
                {
                    AccessByPermission = TableData "Sales Discount Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Discounts';
                    Image = LineDiscount;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Set up sales discounts for the item. An item discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        Rec.ShowPriceListLines(PriceType::Sale, AmountType::Discount);
                        UpdateSpecialPriceListsTxt(PriceType::Sale);
                    end;
                }
            }
            group(PurchPricesandDiscounts)
            {
                Caption = 'Purchase Prices & Discounts';
                action(Action86)
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Prices';
                    Image = Price;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Purchase Prices";
                    RunPageLink = "Item No." = field("No.");
                    RunPageView = sorting("Item No.");
                    ToolTip = 'Set up purchase prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                }
                action(Action85)
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Discounts';
                    Image = LineDiscount;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Purchase Line Discounts";
                    RunPageLink = "Item No." = field("No.");
                    ToolTip = 'Set up purchase discounts for the item. An item discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';
                }
                action(PurchPricesDiscountsOverview)
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Prices & Discounts Overview';
                    Image = PriceWorksheet;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View the purchase prices and line discounts that you grant for this item when certain criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PurchasesPriceAndLineDisc: Page "Purchases Price and Line Disc.";
                    begin
                        PurchasesPriceAndLineDisc.LoadItem(Rec);
                        PurchasesPriceAndLineDisc.RunModal();
                    end;
                }
                action(PurchPriceLists)
                {
                    AccessByPermission = TableData "Purchase Price Access" = R;
                    ApplicationArea = Suite;
                    Caption = 'Purchase Prices';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Set up purchase prices for the item. An item price is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin

                        Rec.ShowPriceListLines(PriceType::Purchase, AmountType::Price);
                        UpdateSpecialPriceListsTxt(PriceType::Purchase);
                    end;
                }
                action(PurchPriceListsDiscounts)
                {
                    AccessByPermission = TableData "Purchase Discount Access" = R;
                    ApplicationArea = Suite;
                    Caption = 'Purchase Discounts';
                    Image = LineDiscount;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Set up purchase discounts for the item. An item discount is automatically granted on invoice lines when the specified criteria are met, such as vendor, quantity, or ending date.';

                    trigger OnAction()
                    var
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        Rec.ShowPriceListLines(PriceType::Purchase, AmountType::Discount);
                        UpdateSpecialPriceListsTxt(PriceType::Purchase);
                    end;
                }
            }
            group(Approval)
            {
                Caption = 'Approval';
                action(Approve)
                {
                    ApplicationArea = All;
                    Caption = 'Approve';
                    Image = Approve;
                    ToolTip = 'Approve the requested changes.';
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ApproveRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = All;
                    Caption = 'Reject';
                    Image = Reject;
                    ToolTip = 'Reject the approval request.';
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.RejectRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(Delegate)
                {
                    ApplicationArea = All;
                    Caption = 'Delegate';
                    Image = Delegate;
                    ToolTip = 'Delegate the approval to a substitute approver.';
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.DelegateRecordApprovalRequest(Rec.RecordId);
                    end;
                }
                action(Comment)
                {
                    ApplicationArea = All;
                    Caption = 'Comments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';
                    Visible = OpenApprovalEntriesExistCurrUser;

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.GetApprovalComment(Rec);
                    end;
                }
            }
            group(RequestApproval)
            {
                Caption = 'Request Approval';
                Image = SendApprovalRequest;
                action(SendApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Send A&pproval Request';
                    Enabled = (not OpenApprovalEntriesExist) and EnabledApprovalWorkflowsExist and CanRequestApprovalForFlow;
                    Image = SendApprovalRequest;
                    ToolTip = 'Request approval to change the record.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        if ApprovalsMgmt.CheckItemApprovalsWorkflowEnabled(Rec) then
                            ApprovalsMgmt.OnSendItemForApproval(Rec);
                    end;
                }
                action(CancelApprovalRequest)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Approval Re&quest';
                    Enabled = OpenApprovalEntriesExist or CanCancelApprovalForFlow;
                    Image = CancelApprovalRequest;
                    ToolTip = 'Cancel the approval request.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
                    begin
                        ApprovalsMgmt.OnCancelItemApprovalRequest(Rec);
                        WorkflowWebhookManagement.FindAndCancel(Rec.RecordId);
                    end;
                }
                group(Flow)
                {
                    Caption = 'Power Automate';

                    customaction(CreateFlowFromTemplate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create approval flow';
                        ToolTip = 'Create a new flow in Power Automate from a list of relevant flow templates.';
                        Visible = IsSaaS and IsPowerAutomatePrivacyNoticeApproved;
                        CustomActionType = FlowTemplateGallery;
                        FlowTemplateCategoryName = 'd365bc_approval_item';
                    }
                }
            }
            group(Workflow)
            {
                Caption = 'Workflow';
                action(CreateApprovalWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Create Approval Workflow';
                    Enabled = not EnabledApprovalWorkflowsExist;
                    Image = CreateWorkflow;
                    ToolTip = 'Set up an approval workflow for creating or changing items, by going through a few pages that will guide you.';

                    trigger OnAction()
                    var
                        WorkflowManagement: Codeunit "Workflow Management";
                    begin
                        PAGE.RunModal(PAGE::"Item Approval WF Setup Wizard");
                        EnabledApprovalWorkflowsExist := WorkflowManagement.EnabledWorkflowExist(DATABASE::Item, EventFilter);
                    end;
                }
                action(ManageApprovalWorkflow)
                {
                    ApplicationArea = Suite;
                    Caption = 'Manage Approval Workflow';
                    Enabled = EnabledApprovalWorkflowsExist;
                    Image = WorkflowSetup;
                    ToolTip = 'View or edit existing approval workflows for creating or changing items.';

                    trigger OnAction()
                    var
                        WorkflowManagement: Codeunit "Workflow Management";
                    begin
                        WorkflowManagement.NavigateToWorkflows(DATABASE::Item, EventFilter);
                    end;
                }
            }
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Create Stockkeeping Unit")
                {
                    AccessByPermission = TableData "Stockkeeping Unit" = R;
                    ApplicationArea = Warehouse;
                    Caption = '&Create Stockkeeping Unit';
                    Image = CreateSKU;
                    ToolTip = 'Create an instance of the item at each location that is set up.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                    begin
                        Item.SetRange("No.", Rec."No.");
                        REPORT.RunModal(REPORT::"Create Stockkeeping Unit", true, false, Item);
                    end;
                }
                action(CalculateCountingPeriod)
                {
                    AccessByPermission = TableData "Phys. Invt. Item Selection" = R;
                    ApplicationArea = Warehouse;
                    Caption = 'C&alculate Counting Period';
                    Image = CalculateCalendar;
                    ToolTip = 'Prepare for a physical inventory by calculating which items or SKUs need to be counted in the current period.';

                    trigger OnAction()
                    var
                        Item: Record Item;
                        PhysInvtCountMgt: Codeunit "Phys. Invt. Count.-Management";
                    begin
                        Item.SetRange("No.", Rec."No.");
                        PhysInvtCountMgt.UpdateItemPhysInvtCount(Item);
                    end;
                }
                action(Templates)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Templates';
                    Image = Template;
                    ToolTip = 'View or edit item templates.';

                    trigger OnAction()
                    var
                        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
                    begin
                        ItemTemplMgt.ShowTemplates();
                    end;
                }
                action(CopyItem)
                {
                    AccessByPermission = TableData Item = I;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Item';
                    Image = Copy;
                    ToolTip = 'Create a copy of the current item.';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Copy Item", Rec);
                    end;
                }
                action(ApplyTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Template';
                    Image = ApplyTemplate;
                    ToolTip = 'Apply a template to update the entity with your standard settings for a certain type of entity.';

                    trigger OnAction()
                    var
                        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
                    begin
                        ItemTemplMgt.UpdateItemFromTemplate(Rec);
                        ItemReplenishmentSystem := Rec."Replenishment System";
                        EnableControls();
                        CurrPage.Update();
                    end;
                }
                action(SaveAsTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Save as Template';
                    Image = Save;
                    ToolTip = 'Save the item card as a template that can be reused to create new item cards. Item templates contain preset information to help you fill in fields on item cards.';

                    trigger OnAction()
                    var
                        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
                    begin
                        ItemTemplMgt.SaveAsTemplate(Rec);
                    end;
                }
                action(AdjustInventory)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Adjust Inventory';
                    Enabled = IsInventoriable;
                    Image = InventoryCalculation;
                    ToolTip = 'Increase or decrease the item''s inventory quantity manually by entering a new quantity. Adjusting the inventory quantity manually may be relevant after a physical count or if you do not record purchased quantities.';
                    Visible = IsInventoryAdjmtAllowed;

                    trigger OnAction()
                    var
                        AdjustInventory: Page "Adjust Inventory";
                    begin
                        Commit();
                        AdjustInventory.SetItem(Rec."No.");
                        AdjustInventory.RunModal();
                    end;
                }
                action("Update Variant Attributes")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Update Variant Attributes';
                    Image = Refresh;
                    ToolTip = 'Keep your item variants up to date with the item. It adds any missing details, updates changes, and removes info that''s no longer needed. Variant-specific details stay as they are';

                    trigger OnAction()
                    var
                        ItemAttributeManagement: Codeunit "Item Attribute Management";
                    begin
                        ItemAttributeManagement.UpdateItemVariantAttributeFromItem(Rec."No.");
                    end;
                }
            }
            action("Requisition Worksheet")
            {
                ApplicationArea = Planning;
                Caption = 'Requisition Worksheet';
                Image = Worksheet;
                RunObject = Page "Req. Worksheet";
                ToolTip = 'Calculate a supply plan to fulfill item demand with purchases or transfers.';
            }
            action("Item Journal")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Journal';
                Image = Journals;
                RunObject = Page "Item Journal";
                ToolTip = 'Open a list of journals where you can adjust the physical quantity of items on inventory.';
            }
            action("Item Reclassification Journal")
            {
                ApplicationArea = Warehouse;
                Caption = 'Item Reclassification Journal';
                Image = Journals;
                RunObject = Page "Item Reclass. Journal";
                ToolTip = 'Change information on item ledger entries, such as dimensions, location codes, bin codes, and serial, lot or package numbers.';
            }
            action("Item Tracing")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item Tracing';
                Image = ItemTracing;
                RunObject = Page "Item Tracing";
                ToolTip = 'Trace where a serial, lot or package number assigned to the item was used, for example, to find which lot a defective component came from or to find all the customers that have received items containing the defective component.';
            }
        }
        area(navigation)
        {
            group(History)
            {
                Caption = 'History';
                Image = History;
                group(Entries)
                {
                    Caption = 'E&ntries';
                    Image = Entries;
                    action("Ledger E&ntries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Ledger E&ntries';
                        Image = ItemLedger;
                        //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedCategory = Category5;
                        //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                        //PromotedIsBig = true;
                        RunObject = Page "Item Ledger Entries";
                        RunPageLink = "Item No." = field("No.");
                        RunPageView = sorting("Item No.")
                                      order(descending);
                        ShortCutKey = 'Ctrl+F7';
                        ToolTip = 'View the history of transactions that have been posted for the selected record.';
                    }
                    action("&Phys. Inventory Ledger Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Phys. Inventory Ledger Entries';
                        Image = PhysicalInventoryLedger;
                        RunObject = Page "Phys. Inventory Ledger Entries";
                        RunPageLink = "Item No." = field("No.");
                        RunPageView = sorting("Item No.");
                        ToolTip = 'View how many units of the item you had in stock at the last physical count.';
                    }
                    action("&Reservation Entries")
                    {
                        ApplicationArea = Reservation;
                        Caption = '&Reservation Entries';
                        Image = ReservationLedger;
                        RunObject = Page "Reservation Entries";
                        RunPageLink = "Reservation Status" = const(Reservation),
                                      "Item No." = field("No.");
                        RunPageView = sorting("Item No.", "Variant Code", "Location Code", "Reservation Status");
                        ToolTip = 'View all reservations that are made for the item, either manually or automatically.';
                    }
                    action("&Value Entries")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = '&Value Entries';
                        Image = ValueLedger;
                        RunObject = Page "Value Entries";
                        RunPageLink = "Item No." = field("No.");
                        RunPageView = sorting("Item No.");
                        ToolTip = 'View the history of posted amounts that affect the value of the item. Value entries are created for every transaction with the item.';
                    }
                    action("Item &Tracking Entries")
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Item &Tracking Entries';
                        Image = ItemTrackingLedger;
                        ToolTip = 'View serial, lot or package numbers that are assigned to items.';

                        trigger OnAction()
                        var
                            ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
                        begin
                            ItemTrackingDocMgt.ShowItemTrackingForEntity(3, '', Rec."No.", '', '');
                        end;
                    }
                    action("&Warehouse Entries")
                    {
                        ApplicationArea = Warehouse;
                        Caption = '&Warehouse Entries';
                        Image = BinLedger;
                        RunObject = Page "Warehouse Entries";
                        RunPageLink = "Item No." = field("No.");
                        RunPageView = sorting("Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Entry Type", Dedicated);
                        ToolTip = 'View the history of quantities that are registered for the item in warehouse activities. ';
                    }
                    action("Application Worksheet")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Application Worksheet';
                        Image = ApplicationWorksheet;
                        RunObject = Page "Application Worksheet";
                        RunPageLink = "Item No." = field("No.");
                        ToolTip = 'Edit item applications that are automatically created between item ledger entries during item transactions. Use special functions to manually undo or change item application entries.';
                    }
                    action("Export Item Data")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export Item Data';
                        Image = ExportFile;
                        ToolTip = 'Use this function to export item related data to text file (you can attach this file to support requests in case you may have issues with costing calculation).';

                        trigger OnAction()
                        var
                            Item: Record Item;
                        begin
                            Item.SetRange("No.", Rec."No.");
                            Xmlport.Run(XmlPort::"Export Item Data", false, false, Item);
                        end;
                    }
                }
            }
            group(Navigation_Item)
            {
                Caption = 'Item';
                action(Attributes)
                {
                    AccessByPermission = TableData "Item Attribute" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attributes';
                    Image = Category;
                    ToolTip = 'View or edit the item''s attributes, such as color, size, or other characteristics that help to describe the item.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Item Attribute Value Editor", Rec);
                        CurrPage.SaveRecord();
                        CurrPage.ItemAttributesFactbox.PAGE.LoadItemAttributesData(Rec."No.");
                    end;
                }
                action("Va&riants")
                {
                    ApplicationArea = Planning;
                    Caption = 'Va&riants';
                    Image = ItemVariant;
                    RunObject = Page "Item Variants";
                    RunPageLink = "Item No." = field("No.");
                    ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';
                }
                action(Identifiers)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Identifiers';
                    Image = BarCode;
                    RunObject = Page "Item Identifiers";
                    RunPageLink = "Item No." = field("No.");
                    RunPageView = sorting("Item No.", "Variant Code", "Unit of Measure Code");
                    ToolTip = 'View a unique identifier for each item that you want warehouse employees to keep track of within the warehouse when using handheld devices. The item identifier can include the item number, the variant code and the unit of measure.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const(Item),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Attachments)
                {
                    ApplicationArea = All;
                    Caption = 'Attachments';
                    Image = Attach;
                    ToolTip = 'Add a file as an attachment. You can attach images as well as documents.';

                    trigger OnAction()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category4;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(27),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("Item Re&ferences")
                {
                    AccessByPermission = tabledata "Item Reference" = R;
                    ApplicationArea = Suite, ItemReferences;
                    Caption = 'Item Re&ferences';
                    Image = Change;
                    RunObject = Page "Item Reference Entries";
                    RunPageLink = "Item No." = field("No.");
                    ToolTip = 'Set up a customer''s or vendor''s own identification of the item. Item references to the customer''s item number means that the item number is automatically shown on sales documents instead of the number that you use.';
                }
                action("&Units of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Units of Measure';
                    Image = UnitOfMeasure;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category4;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Item Units of Measure";
                    RunPageLink = "Item No." = field("No.");
                    ToolTip = 'Set up the different units that the item can be traded in, such as piece, box, or hour.';
                }
                action("E&xtended Texts")
                {
                    ApplicationArea = Suite;
                    Caption = 'E&xtended Texts';
                    Image = Text;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category4;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Extended Text List";
                    RunPageLink = "Table Name" = const(Item),
                                  "No." = field("No.");
                    RunPageView = sorting("Table Name", "No.", "Language Code", "All Language Codes", "Starting Date", "Ending Date");
                    ToolTip = 'Select or set up additional text for the description of the item. Extended text can be inserted under the Description field on document lines for the item.';
                }
                action("Marketing Text")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Marketing Text';
                    Image = TextFieldConfirm;
                    ToolTip = 'Review and edit the marketing text';
                    Visible = EntityTextEnabled;

                    trigger OnAction()
                    var
                        MarketingText: Codeunit "Marketing Text";
                    begin
                        MarketingText.EditMarketingText(Rec."No.");
                        CurrPage.Update();
                    end;
                }
                action(Translations)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Translations';
                    Image = Translations;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Category4;
                    //The property 'PromotedIsBig' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedIsBig = true;
                    RunObject = Page "Item Translations";
                    RunPageLink = "Item No." = field("No.");
                    ToolTip = 'View or edit translated item descriptions. Translated item descriptions are automatically inserted on documents according to the language code.';
                }
                action("Substituti&ons")
                {
                    ApplicationArea = Suite;
                    Caption = 'Substituti&ons';
                    Image = ItemSubstitution;
                    RunObject = Page "Item Substitution Entry";
                    RunPageLink = Type = const(Item),
                                  "No." = field("No.");
                    ToolTip = 'View or edit substitute items that are set up to be traded instead of the item in case it is not available.';
                }
                action(ApprovalEntries)
                {
                    AccessByPermission = TableData "Approval Entry" = R;
                    ApplicationArea = Suite;
                    Caption = 'Approvals';
                    Image = Approvals;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    begin
                        ApprovalsMgmt.OpenApprovalEntriesPage(Rec.RecordId);
                    end;
                }
            }
            group(ActionGroupCRM)
            {
                Caption = 'Dynamics 365 Sales';
                Visible = CRMIntegrationEnabled;
                Enabled = (BlockedFilterApplied and (not Rec.Blocked)) or not BlockedFilterApplied;
                action(CRMGoToProduct)
                {
                    ApplicationArea = Suite;
                    Caption = 'Product';
                    Image = CoupledItem;
                    ToolTip = 'Open the coupled Dynamics 365 Sales product.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Rec.RecordId);
                    end;
                }
                action("Unit Group")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit Group';
                    Image = UnitOfMeasure;
                    RunObject = Page "Item Unit Group List";
                    RunPageLink = "Source No." = field("No."), "Source Type" = const(Item);
                    ToolTip = 'View unit group associated with the item.';
                }
                action(CRMSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = Suite;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send updated data to Dynamics 365 Sales.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(Rec.RecordId);
                    end;
                }
                group(Coupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the Business Central record and a Dynamics 365 Sales record.';
                    action(ManageCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = Suite;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(DeleteCRMCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = Suite;
                        Caption = 'Delete Coupling';
                        Enabled = CRMIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dynamics 365 Sales product.';

                        trigger OnAction()
                        var
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        begin
                            CRMCouplingManagement.RemoveCoupling(Rec.RecordId);
                        end;
                    }
                }
                action(ShowLog)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the item table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
            group(StatisticsGroup)
            {
                Caption = 'Statistics';
                Image = Statistics;
                action(ItemStatistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Statistics';
                    Image = Statistics;
                    RunObject = Page "Item Statistics 2";
                    RunPageLink = "Item No." = field("No.");
                    ToolTip = 'View item statistics. Summarised sales, inventory value, turnover and aging based on the selected filters, with drill-down to related ledger and value entries.';
                }
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Advanced Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    var
                        ItemStatistics: Page "Item Statistics";
                    begin
                        ItemStatistics.SetItem(Rec);
                        ItemStatistics.RunModal();
                    end;
                }
                action("Entry Statistics")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Entry Statistics';
                    Image = EntryStatistics;
                    RunObject = Page "Item Entry Statistics";
                    RunPageLink = "No." = field("No."),
                                      "Date Filter" = field("Date Filter"),
                                      "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                      "Location Filter" = field("Location Filter"),
                                      "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                      "Variant Filter" = field("Variant Filter");
                    ToolTip = 'View statistics for item ledger entries.';
                }
                action("T&urnover")
                {
                    ApplicationArea = Suite;
                    Caption = 'T&urnover';
                    Image = Turnover;
                    RunObject = Page "Item Turnover";
                    RunPageLink = "No." = field("No."),
                                      "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                      "Location Filter" = field("Location Filter"),
                                      "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                      "Variant Filter" = field("Variant Filter");
                    ToolTip = 'View a detailed account of item turnover by periods after you have set the relevant filters for location and variant.';
                }
            }
            group(Availability)
            {
                Caption = 'Availability';
                Image = ItemAvailability;
                Enabled = IsInventoriable;

                action(ItemsByLocation)
                {
                    AccessByPermission = TableData Location = R;
                    ApplicationArea = Location;
                    Caption = 'Items b&y Location';
                    Image = ItemAvailbyLoc;
                    ToolTip = 'Show a list of items grouped by location.';

                    trigger OnAction()
                    begin
                        PAGE.Run(PAGE::"Items by Location", Rec);
                    end;
                }
                group(ItemAvailabilityBy)
                {
                    Caption = '&Item Availability by';
                    Image = ItemAvailability;
                    action("<Action110>")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailabilityFromItem(Rec, "Item Availability Type"::"Event");
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Period';
                        Image = Period;
                        RunObject = Page "Item Availability by Periods";
                        RunPageLink = "No." = field("No."),
                                      "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                      "Location Filter" = field("Location Filter"),
                                      "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                      "Variant Filter" = field("Variant Filter");
                        ToolTip = 'Show the projected quantity of the item over time according to time periods, such as day, week, or month.';
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        RunObject = Page "Item Availability by Variant";
                        RunPageLink = "No." = field("No."),
                                      "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                      "Location Filter" = field("Location Filter"),
                                      "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                      "Variant Filter" = field("Variant Filter");
                        ToolTip = 'View how the inventory level of an item will develop over time according to the variant that you select.';
                    }
                    action(Location)
                    {
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        RunObject = Page "Item Availability by Location";
                        RunPageLink = "No." = field("No."),
                                      "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                      "Location Filter" = field("Location Filter"),
                                      "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                      "Variant Filter" = field("Variant Filter");
                        ToolTip = 'View the actual and projected quantity of the item per location.';
                    }
                    action(Lot)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot';
                        Image = LotInfo;
                        RunObject = Page "Item Availability by Lot No.";
                        RunPageLink = "No." = field("No."),
                              "Location Filter" = field("Location Filter"),
                              "Variant Filter" = field("Variant Filter");
                        ToolTip = 'View the current and projected quantity of the item in each lot.';
                    }
                    action("BOM Level")
                    {
                        AccessByPermission = TableData "BOM Buffer" = R;
                        ApplicationArea = Assembly;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            ItemAvailFormsMgt.ShowItemAvailabilityFromItem(Rec, "Item Availability Type"::BOM);
                        end;
                    }
                    action("Unit of Measure")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Unit of Measure';
                        Image = UnitOfMeasure;
                        RunObject = Page "Item Availability by UOM";
                        RunPageLink = "No." = field("No."),
                                      "Global Dimension 1 Filter" = field("Global Dimension 1 Filter"),
                                      "Global Dimension 2 Filter" = field("Global Dimension 2 Filter"),
                                      "Location Filter" = field("Location Filter"),
                                      "Drop Shipment Filter" = field("Drop Shipment Filter"),
                                      "Variant Filter" = field("Variant Filter");
                        ToolTip = 'View the item''s availability by a unit of measure.';
                    }
                }
            }
            group(Purchases)
            {
                Caption = '&Purchases';
                Image = Purchasing;
                action("Ven&dors")
                {
                    ApplicationArea = Planning;
                    Caption = 'Ven&dors';
                    Image = Vendor;
                    RunObject = Page "Item Vendor Catalog";
                    RunPageLink = "Item No." = field("No.");
                    RunPageView = sorting("Item No.");
                    ToolTip = 'View the list of vendors who can supply the item, and at which lead time.';
                }
                action("Prepa&yment Percentages")
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Purchase Prepa&yment Percentages';
                    Image = PrepaymentPercentages;
                    RunObject = Page "Purchase Prepmt. Percentages";
                    RunPageLink = "Item No." = field("No.");
                    ToolTip = 'View or edit the percentages of the purchase price that can be paid as a prepayment.';
                }
                action(Orders)
                {
                    ApplicationArea = Suite;
                    Caption = 'Purchase Orders';
                    Image = Document;
                    RunObject = Page "Purchase Orders";
                    RunPageLink = Type = const(Item),
                                  "No." = field("No.");
                    RunPageView = sorting("Document Type", Type, "No.");
                    ToolTip = 'View a list of ongoing purchase orders for the item.';
                }
                action("Return Orders")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Purchase Return Orders';
                    Image = ReturnOrder;
                    RunObject = Page "Purchase Return Orders";
                    RunPageLink = Type = const(Item),
                                  "No." = field("No.");
                    RunPageView = sorting("Document Type", Type, "No.");
                    ToolTip = 'Open the list of ongoing purchase return orders for the item.';
                }
            }
            group(Sales)
            {
                Caption = 'S&ales';
                Image = Sales;
                action(Action300)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Sales Prepa&yment Percentages';
                    Image = PrepaymentPercentages;
                    RunObject = Page "Sales Prepayment Percentages";
                    RunPageLink = "Item No." = field("No.");
                    ToolTip = 'View or edit the percentages of the sales price that can be paid as a prepayment.';
                }
                action(Action83)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Orders';
                    Image = Document;
                    RunObject = Page "Sales Orders";
                    RunPageLink = Type = const(Item),
                                  "No." = field("No.");
                    RunPageView = sorting("Document Type", Type, "No.");
                    ToolTip = 'View a list of ongoing orders for the item.';
                }
                action(Action163)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Sales Return Orders';
                    Image = ReturnOrder;
                    RunObject = Page "Sales Return Orders";
                    RunPageLink = Type = const(Item),
                                  "No." = field("No.");
                    RunPageView = sorting("Document Type", Type, "No.");
                    ToolTip = 'Open the list of ongoing sales return orders for the item.';
                }
            }
            group(BillOfMaterials)
            {
                Caption = 'Bill of Materials';
                Image = Production;
                action(BOMStructure)
                {
                    ApplicationArea = Assembly;
                    Caption = 'Structure';
                    Image = Hierarchy;
                    ToolTip = 'View which child items are used in an item''s assembly BOM or production BOM. Each item level can be collapsed or expanded to obtain an overview or detailed view.';

                    trigger OnAction()
                    var
                        BOMStructure: Page "BOM Structure";
                    begin
                        BOMStructure.InitItem(Rec);
                        BOMStructure.Run();
                    end;
                }
                action("Cost Shares")
                {
                    ApplicationArea = Assembly;
                    Caption = 'Cost Shares';
                    Image = CostBudget;
                    ToolTip = 'View how the costs of underlying items in the BOM roll up to the parent item. The information is organized according to the BOM structure to reflect at which levels the individual costs apply. Each item level can be collapsed or expanded to obtain an overview or detailed view.';

                    trigger OnAction()
                    var
                        BOMCostShares: Page "BOM Cost Shares";
                    begin
                        BOMCostShares.InitItem(Rec);
                        BOMCostShares.Run();
                    end;
                }
                group(Assembly)
                {
                    Caption = 'Assemb&ly';
                    Image = AssemblyBOM;
                    action("Assembly BOM")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;
                        Caption = 'Assembly BOM';
                        Image = BOM;
                        RunObject = Page "Assembly BOM";
                        RunPageLink = "Parent Item No." = field("No.");
                        ToolTip = 'View or edit the bill of material that specifies which items and resources are required to assemble the assembly item.';
                    }
                    action("Where-Used")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;
                        Caption = 'Where-Used';
                        Image = Track;
                        RunObject = Page "Where-Used List";
                        RunPageLink = Type = const(Item),
                                      "No." = field("No.");
                        RunPageView = sorting(Type, "No.");
                        ToolTip = 'View a list of assembly BOMs in which the item is used.';
                    }
                }
            }
            group(Navigation_Warehouse)
            {
                Caption = 'Warehouse';
                Image = Warehouse;
                action("&Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Bin Contents';
                    Image = BinContent;
                    RunObject = Page "Bin Content";
                    RunPageLink = "Item No." = field("No.");
                    RunPageView = sorting("Item No.");
                    ToolTip = 'View the quantities of the item in each bin where it exists. You can see all the important parameters relating to bin content, and you can modify certain bin content parameters in this window.';
                }
                action("Stockkeepin&g Units")
                {
                    ApplicationArea = Planning;
                    Caption = 'Stockkeepin&g Units';
                    Image = SKU;
                    RunObject = Page "Stockkeeping Unit List";
                    RunPageLink = "Item No." = field("No.");
                    RunPageView = sorting("Item No.");
                    ToolTip = 'Open the item''s SKUs to view or edit instances of the item at different locations or with different variants. ';
                }
            }
        }
        area(reporting)
        {
            action(PrintLabel)
            {
                AccessByPermission = TableData Item = I;
                ApplicationArea = Basic, Suite;
                Image = Print;
                Caption = 'Print Label';
                ToolTip = 'Print Label';

                trigger OnAction()
                var
                    Item: Record Item;
                    ItemGTINLabel: Report "Item GTIN Label";
                begin
                    Item := Rec;
                    CurrPage.SetSelectionFilter(Item);
                    ItemGTINLabel.SetTableView(Item);
                    ItemGTINLabel.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(CopyItem_Promoted; CopyItem)
                {
                }
                actionref(AdjustInventory_Promoted; AdjustInventory)
                {
                }
                actionref("&Create Stockkeeping Unit_Promoted"; "&Create Stockkeeping Unit")
                {
                }
                actionref(ApplyTemplate_Promoted; ApplyTemplate)
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Approve', Comment = 'Generated from the PromotedActionCategories property index 6.';

                actionref(Approve_Promoted; Approve)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(Delegate_Promoted; Delegate)
                {
                }
                actionref(Comment_Promoted; Comment)
                {
                }
            }
            group(Category_Category8)
            {
                Caption = 'Request Approval', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref(SendApprovalRequest_Promoted; SendApprovalRequest)
                {
                }
                actionref(CancelApprovalRequest_Promoted; CancelApprovalRequest)
                {
                }
            }
            group(Category_Category4)
            {
                Caption = 'Item', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Attachments_Promoted; Attachments)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref(ApprovalEntries_Promoted; ApprovalEntries)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("&Phys. Inventory Ledger Entries_Promoted"; "&Phys. Inventory Ledger Entries")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(EditMarketingText_Promoted; "Marketing Text")
                {
                }

                separator(Navigate_Separator)
                {
                }

                group("Category_Item Availability by")
                {
                    Caption = 'Item Availability by';

                    actionref("<Action110>_Promoted"; "<Action110>")
                    {
                    }
                    actionref("BOM Level_Promoted"; "BOM Level")
                    {
                    }
                    actionref(Period_Promoted; Period)
                    {
                    }
                    actionref(Variant_Promoted; Variant)
                    {
                    }
                    actionref(Location_Promoted; Location)
                    {
                    }
                    actionref(Lot_Promoted; Lot)
                    {
                    }
                    actionref("Unit of Measure_Promoted"; "Unit of Measure")
                    {
                    }
                }
                actionref(Attributes_Promoted; Attributes)
                {
                }
                actionref(BOMStructure_Promoted; BOMStructure)
                {
                }
                actionref(ItemsByLocation_Promoted; ItemsByLocation)
                {
                }
                actionref("Cost Shares_Promoted"; "Cost Shares")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'History', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Category6)
            {
                Caption = 'Prices & Discounts', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("Set Special Prices_Promoted"; "Set Special Prices")
                {
                }
                actionref(SalesPriceLists_Promoted; SalesPriceLists)
                {
                }
                actionref(PurchPriceLists_Promoted; PurchPriceLists)
                {
                }
                actionref(PricesDiscountsOverview_Promoted; PricesDiscountsOverview)
                {
                }
                actionref("Set Special Discounts_Promoted"; "Set Special Discounts")
                {
                }
                actionref(PurchPricesDiscountsOverview_Promoted; PurchPricesDiscountsOverview)
                {
                }
                actionref(SalesPriceListsDiscounts_Promoted; SalesPriceListsDiscounts)
                {
                }
                actionref(PurchPriceListsDiscounts_Promoted; PurchPriceListsDiscounts)
                {
                }
                actionref(Action86_Promoted; Action86)
                {
                }
                actionref(Action85_Promoted; Action85)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Synchronize)
            {
                Caption = 'Synchronize';
                Visible = CRMIntegrationEnabled;

                group(Category_Coupling)
                {
                    Caption = 'Coupling';
                    ShowAs = SplitButton;

                    actionref(ManageCRMCoupling_Promoted; ManageCRMCoupling)
                    {
                    }
                    actionref(DeleteCRMCoupling_Promoted; DeleteCRMCoupling)
                    {
                    }
                }
                actionref(CRMSynchronizeNow_Promoted; CRMSynchronizeNow)
                {
                }
                actionref(CRMGoToProduct_Promoted; CRMGoToProduct)
                {
                }
                actionref(ShowLog_Promoted; ShowLog)
                {
                }
                actionref("Unit Group_Promoted"; "Unit Group")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EnableControls();
        ItemReplenishmentSystem := Rec."Replenishment System";
        if GuiAllowed() then
            OnAfterGetCurrRecordFunc();
    end;


    local procedure OnAfterGetCurrRecordFunc()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
        WorkflowWebhookManagement: Codeunit "Workflow Webhook Management";
    begin
        CreateItemFromTemplate();

        if CRMIntegrationEnabled then begin
            CRMIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
            if Rec."No." <> xRec."No." then
                CRMIntegrationManagement.SendResultNotification(Rec);
        end;
        OpenApprovalEntriesExist := ApprovalsMgmt.HasOpenApprovalEntries(Rec.RecordId);
        OpenApprovalEntriesExistCurrUser := false;
        if OpenApprovalEntriesExist then
            OpenApprovalEntriesExistCurrUser := ApprovalsMgmt.HasOpenApprovalEntriesForCurrentUser(Rec.RecordId);

        ShowWorkflowStatus := CurrPage.WorkflowStatus.PAGE.SetFilterOnWorkflowRecord(Rec.RecordId);
        WorkflowWebhookManagement.GetCanRequestAndCanCancel(Rec.RecordId, CanRequestApprovalForFlow, CanCancelApprovalForFlow);
        CurrPage.ItemAttributesFactbox.PAGE.LoadItemAttributesData(Rec."No.");
        if EntityTextEnabled then
            CurrPage.EntityTextFactBox.Page.SetContext(Database::Item, Rec.SystemId, Enum::"Entity Text Scenario"::"Marketing Text", MarketingTextPlaceholderTxt);
    end;

    trigger OnInit()
    var
        WorkflowManagement: Codeunit "Workflow Management";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
    begin
        if not GuiAllowed then
            exit;
        InitControls();
        EventFilter := WorkflowEventHandling.RunWorkflowOnSendItemForApprovalCode() + '|' +
          WorkflowEventHandling.RunWorkflowOnItemChangedCode();

        EnabledApprovalWorkflowsExist := WorkflowManagement.EnabledWorkflowExist(DATABASE::Item, EventFilter);

        IsPowerAutomatePrivacyNoticeApproved := PrivacyNotice.GetPrivacyNoticeApprovalState(FlowServiceManagement.GetPowerAutomatePrivacyNoticeId()) = "Privacy Notice Approval State"::Agreed;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        InsertItemUnitOfMeasure();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        OnNewRec();
    end;

    trigger OnOpenPage()
    begin
        OnBeforeOnOpenPage(Rec);
        if GuiAllowed() then
            OnOpenPageFunc()
        else
            EnableControls();
        OnAfterOnOpenPage();
    end;

    local procedure OnOpenPageFunc()
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        EnvironmentInfo: Codeunit "Environment Information";
        MarketingText: Codeunit "Marketing Text";
        AdjustItemInventory: Codeunit "Adjust Item Inventory";
    begin
        IsInventoryAdjmtAllowed := AdjustItemInventory.GetInventoryAdjustmentAllowed();
        SetNoFieldVisible();
        IsSaaS := EnvironmentInfo.IsSaaS();
        DescriptionFieldVisible := true;
        SetOverReceiptControlsVisibility();
        CRMIntegrationEnabled := CRMIntegrationManagement.IsCRMIntegrationEnabled();
        if CRMIntegrationEnabled then
            if IntegrationTableMapping.Get('ITEM-PRODUCT') then
                BlockedFilterApplied := IntegrationTableMapping.GetTableFilter().Contains('Field54=1(0)');
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
        EnableShowStockOutWarning();
        EnableShowShowEnforcePositivInventory();
        EnableShowVariantMandatory();
        EntityTextEnabled := MarketingText.IsMarketingTextVisible();
    end;

    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";
        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        PrivacyNotice: Codeunit "Privacy Notice";
        FlowServiceManagement: Codeunit "Flow Service Management";
        IsInventoryAdjmtAllowed: Boolean;
        ShowStockoutWarningDefaultYes: Boolean;
        ShowStockoutWarningDefaultNo: Boolean;
        ShowPreventNegInventoryDefaultYes: Boolean;
        ShowPreventNegInventoryDefaultNo: Boolean;
        IsPowerAutomatePrivacyNoticeApproved: Boolean;
        CRMIntegrationEnabled: Boolean;
        CRMIsCoupledToRecord: Boolean;
        BlockedFilterApplied: Boolean;
        OpenApprovalEntriesExistCurrUser: Boolean;
        OpenApprovalEntriesExist: Boolean;
        SalesPriceListsText: Text;
        SalesPriceListsTextIsInitForNo: Code[20];
        PurchPriceListsText: Text;
        PurchPriceListsTextIsInitForNo: Code[20];
        CreateNewTxt: Label 'Create New...';
        EntityTextEnabled: Boolean;
        MarketingTextPlaceholderTxt: Label '[Create draft]() based on this item''s attributes.', Comment = 'Text contained in [here]() will be clickable to invoke the generate action';
        ViewExistingTxt: Label 'View Existing Prices and Discounts...';
        ShowVariantMandatoryDefaultYes: Boolean;
        SpecialPricesAndDiscountsTxt: Text;
        CreateNewSpecialPriceTxt: Label 'Create New Special Price...';
        CreateNewSpecialDiscountTxt: Label 'Create New Special Discount...';
        SpecialPurchPricesAndDiscountsTxt: Text;

    protected var
        ItemReplenishmentSystem: Enum "Item Replenishment System";
        EnabledApprovalWorkflowsExist: Boolean;
        EventFilter: Text;
        NoFieldVisible: Boolean;
        DescriptionFieldVisible: Boolean;
        NewMode: Boolean;
        CanRequestApprovalForFlow: Boolean;
        CanCancelApprovalForFlow: Boolean;
        IsSaaS: Boolean;
        IsService: Boolean;
        IsNonInventoriable: Boolean;
        IsInventoriable: Boolean;
        ExpirationCalculationEditable: Boolean;
        OverReceiptAllowed: Boolean;
        ExtendedPriceEnabled: Boolean;
        TimeBucketEnable: Boolean;
        SafetyLeadTimeEnable: Boolean;
        SafetyStockQtyEnable: Boolean;
        ReorderPointEnable: Boolean;
        ReorderQtyEnable: Boolean;
        MaximumInventoryEnable: Boolean;
        MinimumOrderQtyEnable: Boolean;
        MaximumOrderQtyEnable: Boolean;
        OrderMultipleEnable: Boolean;
        IncludeInventoryEnable: Boolean;
        ReschedulingPeriodEnable: Boolean;
        LotAccumulationPeriodEnable: Boolean;
        DampenerPeriodEnable: Boolean;
        DampenerQtyEnable: Boolean;
        OverflowLevelEnable: Boolean;
        StandardCostEnable: Boolean;
        UnitCostEnable: Boolean;
        UnitCostEditable: Boolean;
        ReplenishmentSystemEditable: Boolean;
        ProfitEditable: Boolean;
        PriceEditable: Boolean;
        ShowWorkflowStatus: Boolean;

    procedure EnableControls()
    var
        AdjustItemInventory: Codeunit "Adjust Item Inventory";
    begin
        IsService := Rec.IsServiceType();
        IsNonInventoriable := Rec.IsNonInventoriableType();
        IsInventoriable := Rec.IsInventoriableType();
        ReplenishmentSystemEditable := CurrPage.Editable();
        IsInventoryAdjmtAllowed := AdjustItemInventory.GetInventoryAdjustmentAllowed();

        if IsNonInventoriable then
            Rec."Stockout Warning" := Rec."Stockout Warning"::No;

        ProfitEditable := Rec."Price/Profit Calculation" <> Rec."Price/Profit Calculation"::"Profit=Price-Cost";
        PriceEditable := Rec."Price/Profit Calculation" <> Rec."Price/Profit Calculation"::"Price=Cost+Profit";

        EnablePlanningControls();
        EnableCostingControls();

        if not ExtendedPriceEnabled then
            UpdateSpecialPricesAndDiscountsTxt();
        SetExpirationCalculationEditable();
    end;

    local procedure OnNewRec()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        if GuiAllowed then
            if Rec."No." = '' then
                if DocumentNoVisibility.ItemNoSeriesIsDefault() then
                    NewMode := true;
    end;

    local procedure EnableShowStockOutWarning()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        ShowStockoutWarningDefaultYes := SalesSetup."Stockout Warning";
        ShowStockoutWarningDefaultNo := not ShowStockoutWarningDefaultYes;

        EnableShowShowEnforcePositivInventory();
    end;

    local procedure EnableShowVariantMandatory()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        ShowVariantMandatoryDefaultYes := InventorySetup."Variant Mandatory if Exists";
    end;

    local procedure InsertItemUnitOfMeasure()
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if Rec."Base Unit of Measure" <> '' then begin
            ItemUnitOfMeasure.Init();
            ItemUnitOfMeasure."Item No." := Rec."No.";
            ItemUnitOfMeasure.Validate(Code, Rec."Base Unit of Measure");
            ItemUnitOfMeasure."Qty. per Unit of Measure" := 1;
            ItemUnitOfMeasure.Insert();
        end;
    end;

    local procedure EnableShowShowEnforcePositivInventory()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        ShowPreventNegInventoryDefaultYes := InventorySetup."Prevent Negative Inventory";
        ShowPreventNegInventoryDefaultNo := not ShowPreventNegInventoryDefaultYes;
    end;

    protected procedure EnablePlanningControls()
    var
        PlanningParameters: Record "Planning Parameters";
        PlanningGetParameters: Codeunit "Planning-Get Parameters";
    begin
        PlanningParameters."Reordering Policy" := Rec."Reordering Policy";
        PlanningParameters."Include Inventory" := Rec."Include Inventory";
        PlanningGetParameters.SetPlanningParameters(PlanningParameters);

        OnEnablePlanningControlsOnAfterGetParameters(PlanningParameters);

        TimeBucketEnable := PlanningParameters."Time Bucket Enabled";
        SafetyLeadTimeEnable := PlanningParameters."Safety Lead Time Enabled";
        SafetyStockQtyEnable := PlanningParameters."Safety Stock Qty Enabled";
        ReorderPointEnable := PlanningParameters."Reorder Point Enabled";
        ReorderQtyEnable := PlanningParameters."Reorder Quantity Enabled";
        MaximumInventoryEnable := PlanningParameters."Maximum Inventory Enabled";
        MinimumOrderQtyEnable := PlanningParameters."Minimum Order Qty Enabled";
        MaximumOrderQtyEnable := PlanningParameters."Maximum Order Qty Enabled";
        OrderMultipleEnable := PlanningParameters."Order Multiple Enabled";
        IncludeInventoryEnable := PlanningParameters."Include Inventory Enabled";
        ReschedulingPeriodEnable := PlanningParameters."Rescheduling Period Enabled";
        LotAccumulationPeriodEnable := PlanningParameters."Lot Accum. Period Enabled";
        DampenerPeriodEnable := PlanningParameters."Dampener Period Enabled";
        DampenerQtyEnable := PlanningParameters."Dampener Quantity Enabled";
        OverflowLevelEnable := PlanningParameters."Overflow Level Enabled";

        OnAfterEnablePlanningControls(PlanningParameters);
    end;

    protected procedure EnableCostingControls()
    begin
        StandardCostEnable := Rec."Costing Method" = Rec."Costing Method"::Standard;
        UnitCostEnable := not StandardCostEnable;
        if UnitCostEnable then
            if GuiAllowed() and Rec.IsInventoriableType() then
                UnitCostEditable := not Rec.ExistsItemLedgerEntry()
            else
                UnitCostEditable := true;
    end;

    local procedure InitControls()
    begin
        UnitCostEnable := true;
        StandardCostEnable := true;
        OverflowLevelEnable := true;
        DampenerQtyEnable := true;
        DampenerPeriodEnable := true;
        LotAccumulationPeriodEnable := true;
        ReschedulingPeriodEnable := true;
        IncludeInventoryEnable := true;
        OrderMultipleEnable := true;
        MaximumOrderQtyEnable := true;
        MinimumOrderQtyEnable := true;
        MaximumInventoryEnable := true;
        ReorderQtyEnable := true;
        ReorderPointEnable := true;
        SafetyStockQtyEnable := true;
        SafetyLeadTimeEnable := true;
        TimeBucketEnable := true;
        Rec."Costing Method" := Rec."Costing Method"::FIFO;
        UnitCostEditable := true;

        OnAfterInitControls();
    end;

    local procedure UpdateSpecialPricesAndDiscountsTxt()
    var
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        TempPurchPriceLineDiscBuff: Record "Purch. Price Line Disc. Buff." temporary;
    begin
        SpecialPricesAndDiscountsTxt := CreateNewTxt;
        if TempSalesPriceAndLineDiscBuff.ItemHasLines(Rec) then
            SpecialPricesAndDiscountsTxt := ViewExistingTxt;

        SpecialPurchPricesAndDiscountsTxt := CreateNewTxt;
        if TempPurchPriceLineDiscBuff.ItemHasLines(Rec) then
            SpecialPurchPricesAndDiscountsTxt := ViewExistingTxt;
    end;

    local procedure UpdateSpecialPriceListsTxt(PriceType: Enum "Price Type")
    begin
        if PriceType in [PriceType::Any, PriceType::Sale] then begin
            SalesPriceListsText := GetPriceActionText(PriceType::Sale);
            SalesPriceListsTextIsInitForNo := Rec."No.";
        end;
        if PriceType in [PriceType::Any, PriceType::Purchase] then begin
            PurchPriceListsText := GetPriceActionText(PriceType::Purchase);
            PurchPriceListsTextIsInitForNo := Rec."No."
        end;
    end;

    local procedure GetPriceActionText(PriceType: Enum "Price Type"): Text
    var
        PriceAssetList: Codeunit "Price Asset List";
        PriceUXManagement: Codeunit "Price UX Management";
        AssetType: Enum "Price Asset Type";
        AmountType: Enum "Price Amount Type";
    begin
        PriceAssetList.Add(AssetType::Item, Rec."No.");
        if PriceUXManagement.SetPriceListLineFilters(PriceAssetList, PriceType, AmountType::Any) then
            exit(ViewExistingTxt);
        exit(CreateNewTxt);
    end;

    local procedure CreateItemFromTemplate()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        ItemTemplMgt: Codeunit "Item Templ. Mgt.";
    begin
        OnBeforeCreateItemFromTemplate(NewMode, Rec, Item);

        if not NewMode then
            exit;
        NewMode := false;

        if ItemTemplMgt.InsertItemFromTemplate(Item) then begin
            Rec.Copy(Item);
            OnCreateItemFromTemplateOnBeforeCurrPageUpdate(Rec);
            ItemReplenishmentSystem := Rec."Replenishment System";
            EnableControls();
            CurrPage.Update();
            OnCreateItemFromTemplateOnAfterCurrPageUpdate(Rec);
        end else
            if ItemTemplMgt.TemplatesAreNotEmpty() then
                if not ItemTemplMgt.IsOpenBlankCardConfirmed() then begin
                    CurrPage.Close();
                    exit;
                end;

        OnCreateItemFromTemplateOnBeforeIsFoundationEnabled(Rec);

        if ApplicationAreaMgmtFacade.IsFoundationEnabled() then
            if (Item."No." = '') and InventorySetup.Get() then
                Rec.Validate("Costing Method", InventorySetup."Default Costing Method");
    end;

    local procedure SetNoFieldVisible()
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        NoFieldVisible := DocumentNoVisibility.ItemNoIsVisible();
    end;

    local procedure SetExpirationCalculationEditable()
    var
        EmptyDateFormula: DateFormula;
    begin
        // allow customers to edit expiration date to remove it if the item has no item tracking code
        ExpirationCalculationEditable := Rec."Expiration Calculation" <> EmptyDateFormula;
        if not ExpirationCalculationEditable then
            ExpirationCalculationEditable := Rec.ItemTrackingCodeUseExpirationDates();
    end;

    local procedure SetOverReceiptControlsVisibility()
    var
        OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
    begin
        OverReceiptAllowed := OverReceiptMgt.IsOverReceiptAllowed();
    end;

    local procedure GetSalesPriceListsText(): Text
    var
        PriceType: enum "Price Type";
    begin
        if SalesPriceListsTextIsInitForNo <> Rec."No." then begin
            SalesPriceListsText := GetPriceActionText(PriceType::Sale);
            SalesPriceListsTextIsInitForNo := Rec."No."
        end;
        exit(SalesPriceListsText);
    end;

    local procedure GetPurchPriceListsText(): Text
    var
        PriceType: enum "Price Type";
    begin
        if PurchPriceListsTextIsInitForNo <> Rec."No." then begin
            PurchPriceListsText := GetPriceActionText(PriceType::Purchase);
            PurchPriceListsTextIsInitForNo := Rec."No."
        end;
        exit(PurchPriceListsText);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitControls()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterOnOpenPage()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeOnOpenPage(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterEnablePlanningControls(var PlanningParameters: Record "Planning Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemFromTemplate(var NewMode: Boolean; var ItemRec: Record Item; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUnitCostOnDrillDown(var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemFromTemplateOnAfterCurrPageUpdate(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemFromTemplateOnBeforeCurrPageUpdate(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEnablePlanningControlsOnAfterGetParameters(var PlanningParameters: Record "Planning Parameters")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateItemFromTemplateOnBeforeIsFoundationEnabled(var Item: Record Item)
    begin
    end;
}