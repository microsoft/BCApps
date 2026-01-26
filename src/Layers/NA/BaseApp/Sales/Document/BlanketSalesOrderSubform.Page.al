// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Assembly.Document;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Calculation;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Utilities;

page 508 "Blanket Sales Order Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Sales Line";
    SourceTableView = where("Document Type" = filter("Blanket Order"));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the line type.';

                    trigger OnValidate()
                    begin
                        NoOnAfterValidate();
                        DeltaUpdateTotals();
                    end;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        NoOnAfterValidate();
                        DeltaUpdateTotals();
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field("Item Reference No."; Rec."Item Reference No.")
                {
                    AccessByPermission = tabledata "Item Reference" = R;
                    ApplicationArea = Suite, ItemReferences;
                    QuickEntry = false;
                    ToolTip = 'Specifies the referenced item number.';
                    Visible = ItemReferenceVisible;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemReferenceMgt: Codeunit "Item Reference Management";
                    begin
                        ItemReferenceMgt.SalesReferenceNoLookup(Rec);
                        InsertExtendedText(false);
                        DeltaUpdateTotals();
                        OnCrossReferenceNoOnLookup(Rec);
                        CurrPage.Update();
                    end;

                    trigger OnValidate()
                    begin
                        InsertExtendedText(false);
                        DeltaUpdateTotals();
                        CurrPage.Update();
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                    ShowMandatory = VariantCodeMandatory;

                    trigger OnValidate()
                    var
                        Item: Record "Item";
                    begin
                        VariantCodeOnAfterValidate();
                        DeltaUpdateTotals();
                        if Rec."Variant Code" = '' then
                            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
                    end;
                }
                field(Nonstock; Rec.Nonstock)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that this item is a catalog item.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the vendor''s VAT specification to link transactions made for this vendor with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the VAT product posting group. Links business transactions made for the item, resource, or G/L account with the general ledger, to account for VAT amounts resulting from trade with that record.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the blanket sales order.';

                    trigger OnValidate()
                    begin
                        Rec.RestoreLookupSelection();
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                        DeltaUpdateTotals();
                    end;

                    trigger OnAfterLookup(Selected: RecordRef)
                    begin
                        Rec.SaveLookupSelection(Selected);
                    end;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';

                    trigger OnValidate()
                    begin
                        LocationCodeOnAfterValidate();
                        DeltaUpdateTotals();
                    end;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of the sales order line.';

                    trigger OnValidate()
                    begin
                        QuantityOnAfterValidate();
                        DeltaUpdateTotals();
                        if SalesReceivablesSetup."Calc. Inv. Discount" and (Rec.Quantity = 0) then
                            CurrPage.Update(false);
                    end;
                }
                field("Qty. to Assemble to Order"; Rec."Qty. to Assemble to Order")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the blanket sales line quantity that you want to supply by assembly.';
                    Visible = false;

                    trigger OnDrillDown()
                    begin
                        Rec.ShowAsmToOrderLines();
                    end;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                        CurrPage.Update(true);
                    end;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the work type code of the service line linked to this entry.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';

                    trigger OnValidate()
                    begin
                        UnitofMeasureCodeOnAfterValidate();
                        DeltaUpdateTotals();
                    end;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Visible = false;
                }
                field("Unit Cost (LCY)"; Rec."Unit Cost (LCY)")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the cost, in LCY, of one unit of the item or resource on the line.';
                    Visible = false;
                }
                field(PriceExists; Rec.PriceExists())
                {
                    ApplicationArea = Suite;
                    Caption = 'Sale Price Exists';
                    Editable = false;
                    ToolTip = 'Specifies that there is a specific price for this customer. The sales prices can be seen in the Sales Prices window.';
                    Visible = false;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("Tax Liable"; Rec."Tax Liable")
                {
                    ApplicationArea = SalesTax;
                    Editable = false;
                    ToolTip = 'Specifies if this vendor charges you sales tax for purchases.';
                    Visible = false;
                }
                field("Tax Area Code"; Rec."Tax Area Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax area that is used to calculate and post sales tax.';

                    trigger OnValidate()
                    begin
                        RedistributeTotalsOnAfterValidate();
                    end;
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the tax group code for the tax detail entry.';

                    trigger OnValidate()
                    begin
                        RedistributeTotalsOnAfterValidate();
                    end;
                }
                field("Line Discount %"; Rec."Line Discount %")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ToolTip = 'Specifies the sum of the amounts in the Amount Including VAT fields on the associated sales lines.';
                }
                field(LineDiscExists; Rec.LineDiscExists())
                {
                    ApplicationArea = Suite;
                    Caption = 'Sales Line Disc. Exists';
                    Editable = false;
                    ToolTip = 'Specifies that there is a specific discount for this customer. The sales line discounts can be seen in the Sales Line Discounts window.';
                    Visible = false;
                }
                field("Line Discount Amount"; Rec."Line Discount Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("Allow Invoice Disc."; Rec."Allow Invoice Disc.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the invoice line is included when the invoice discount is calculated.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        DeltaUpdateTotals();
                    end;
                }
                field("Qty. to Ship"; Rec."Qty. to Ship")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the quantity of items that remain to be shipped.';
                }
                field("Quantity Shipped"; Rec."Quantity Shipped")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as shipped.';
                }
                field("Quantity Invoiced"; Rec."Quantity Invoiced")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies how many units of the item on the line have been posted as invoiced.';
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible1;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = DimVisible2;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible3;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(3);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible4;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(4);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible5;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(5);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible6;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(6);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible7;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(7);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = DimVisible8;

                    trigger OnValidate()
                    begin
                        ValidateShortcutDimension(8);
                    end;
                }
                field("Gross Weight"; Rec."Gross Weight")
                {
                    Caption = 'Unit Gross Weight';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the gross weight of one unit of the item. In the sales statistics window, the gross weight on the line is included in the total gross weight of all the lines for the particular sales document.';
                    Visible = false;
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    Caption = 'Unit Net Weight';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the net weight of one unit of the item. In the sales statistics window, the net weight on the line is included in the total net weight of all the lines for the particular sales document.';
                    Visible = false;
                }
                field("Unit Volume"; Rec."Unit Volume")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the volume of one unit of the item. In the sales statistics window, the volume of one unit of the item on the line is included in the total volume of all the lines for the particular sales document.';
                    Visible = false;
                }
                field("Units per Parcel"; Rec."Units per Parcel")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of units per parcel of the item. In the sales statistics window, the number of units per parcel on the line helps to determine the total number of units for all the lines for the particular sales document.';
                    Visible = false;
                }
            }
            group(Control53)
            {
                ShowCaption = false;
                group(Control49)
                {
                    ShowCaption = false;
                    field(SubtotalExclVAT; TotalSalesLine."Line Amount")
                    {
                        ApplicationArea = Suite;
                        AutoFormatExpression = Currency.Code;
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetTotalLineAmountWithVATAndCurrencyCaption(Currency.Code, TotalSalesHeader."Prices Including VAT");
                        Caption = 'Subtotal Excl. VAT';
                        Editable = false;
                        ToolTip = 'Specifies the sum of the value in the Line Amount Excl. VAT field on all lines in the document.';
                    }
                    field("Invoice Discount Amount"; InvoiceDiscountAmount)
                    {
                        ApplicationArea = Suite;
                        AutoFormatExpression = Currency.Code;
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetInvoiceDiscAmountWithVATAndCurrencyCaption(Rec.FieldCaption("Inv. Discount Amount"), Currency.Code);
                        Caption = 'Invoice Discount Amount';
                        Editable = InvDiscAmountEditable;
                        ToolTip = 'Specifies a discount amount that is deducted from the value of the Total Incl. VAT field, based on sales lines where the Allow Invoice Disc. field is selected. You can enter or change the amount manually.';

                        trigger OnValidate()
                        begin
                            DocumentTotals.SalesDocTotalsNotUpToDate();
                            ValidateInvoiceDiscountAmount();
                        end;
                    }
                    field("Invoice Disc. Pct."; InvoiceDiscountPct)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Invoice Discount %';
                        DecimalPlaces = 0 : 2;
                        Editable = InvDiscAmountEditable;
                        ToolTip = 'Specifies a discount percentage that is applied to the invoice, based on sales lines where the Allow Invoice Disc. field is selected. The percentage and criteria are defined in the Customer Invoice Discounts page, but you can enter or change the percentage manually.';

                        trigger OnValidate()
                        begin
                            DocumentTotals.SalesDocTotalsNotUpToDate();
                            AmountWithDiscountAllowed := DocumentTotals.CalcTotalSalesAmountOnlyDiscountAllowed(Rec);
                            InvoiceDiscountAmount := Round(AmountWithDiscountAllowed * InvoiceDiscountPct / 100, Currency."Amount Rounding Precision");
                            ValidateInvoiceDiscountAmount();
                        end;
                    }
                }
                group(Control35)
                {
                    ShowCaption = false;
                    field("Total Amount Excl. VAT"; TotalSalesLine.Amount)
                    {
                        ApplicationArea = Suite;
                        AutoFormatExpression = Currency.Code;
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetTotalExclVATCaption(Currency.Code);
                        Caption = 'Total Amount Excl. VAT';
                        DrillDown = false;
                        Editable = false;
                        ToolTip = 'Specifies the sum of the value in the Line Amount Excl. VAT field on all lines in the document minus any discount amount in the Invoice Discount Amount field.';
                    }
                    field("Total VAT Amount"; VATAmount)
                    {
                        ApplicationArea = Suite;
                        AutoFormatExpression = Currency.Code;
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetTotalVATCaption(Currency.Code);
                        Caption = 'Total VAT';
                        Editable = false;
                        ToolTip = 'Specifies the sum of VAT amounts on all lines in the document.';
                    }
                    field("Total Amount Incl. VAT"; TotalSalesLine."Amount Including VAT")
                    {
                        ApplicationArea = Suite;
                        AutoFormatExpression = Currency.Code;
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetTotalInclVATCaption(Currency.Code);
                        Caption = 'Total Amount Incl. VAT';
                        Editable = false;
                        ToolTip = 'Specifies the sum of the value in the Line Amount Incl. VAT field on all lines in the document minus any discount amount in the Invoice Discount Amount field.';
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                group("Item Availability by")
                {
                    Caption = 'Item Availability by';
                    Image = ItemAvailability;
                    Enabled = Rec.Type = Rec.Type::Item;
                    action("Event")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Event';
                        Image = "Event";
                        ToolTip = 'View how the actual and the projected available balance of an item will develop over time according to supply and demand events.';

                        trigger OnAction()
                        begin
                            SalesAvailabilityMgt.ShowItemAvailabilityFromSalesLine(Rec, "Item Availability Type"::"Event");
                        end;
                    }
                    action(Period)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Period';
                        Image = Period;
                        ToolTip = 'View the projected quantity of the item over time according to time periods, such as day, week, or month.';

                        trigger OnAction()
                        begin
                            SalesAvailabilityMgt.ShowItemAvailabilityFromSalesLine(Rec, "Item Availability Type"::Period);
                        end;
                    }
                    action(Variant)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant';
                        Image = ItemVariant;
                        ToolTip = 'View or edit the item''s variants. Instead of setting up each color of an item as a separate item, you can set up the various colors as variants of the item.';

                        trigger OnAction()
                        begin
                            SalesAvailabilityMgt.ShowItemAvailabilityFromSalesLine(Rec, "Item Availability Type"::Variant);
                        end;
                    }
                    action(Location)
                    {
                        AccessByPermission = TableData Location = R;
                        ApplicationArea = Location;
                        Caption = 'Location';
                        Image = Warehouse;
                        ToolTip = 'View the actual and projected quantity of the item per location.';

                        trigger OnAction()
                        begin
                            SalesAvailabilityMgt.ShowItemAvailabilityFromSalesLine(Rec, "Item Availability Type"::Location);
                        end;
                    }
                    action(Lot)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Lot';
                        Image = LotInfo;
                        RunObject = Page "Item Availability by Lot No.";
                        RunPageLink = "No." = field("No."),
                            "Location Filter" = field("Location Code"),
                            "Variant Filter" = field("Variant Code");
                        ToolTip = 'View the current and projected quantity of the item in each lot.';
                    }
                    action("BOM Level")
                    {
                        ApplicationArea = Suite;
                        Caption = 'BOM Level';
                        Image = BOMLevel;
                        ToolTip = 'View availability figures for items on bills of materials that show how many units of a parent item you can make based on the availability of child items.';

                        trigger OnAction()
                        begin
                            SalesAvailabilityMgt.ShowItemAvailabilityFromSalesLine(Rec, "Item Availability Type"::BOM);
                        end;
                    }
                }
                group("Unposted Lines")
                {
                    Caption = 'Unposted Lines';
                    Image = "Order";
                    action(Orders)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Orders';
                        Image = Document;
                        ToolTip = 'View related sales orders.';

                        trigger OnAction()
                        begin
                            Rec.ShowBlanketOrderSalesLines(Enum::"Sales Document Type"::Order);
                        end;
                    }
                    action(Invoices)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Invoices';
                        Image = Invoice;
                        ToolTip = 'View a list of ongoing sales invoices for the order.';

                        trigger OnAction()
                        begin
                            Rec.ShowBlanketOrderSalesLines(Enum::"Sales Document Type"::Invoice);
                        end;
                    }
                    action("Return Orders")
                    {
                        AccessByPermission = TableData "Return Receipt Header" = R;
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Return Orders';
                        Image = ReturnOrder;
                        ToolTip = 'Open the list of ongoing return orders.';

                        trigger OnAction()
                        begin
                            Rec.ShowBlanketOrderSalesLines(Enum::"Sales Document Type"::"Return Order");
                        end;
                    }
                    action("Credit Memos")
                    {
                        ApplicationArea = Suite;
                        Caption = 'Credit Memos';
                        Image = CreditMemo;
                        ToolTip = 'View a list of ongoing credit memos for the order.';

                        trigger OnAction()
                        begin
                            Rec.ShowBlanketOrderSalesLines(Enum::"Sales Document Type"::"Credit Memo");
                        end;
                    }
                }
                group("Posted Lines")
                {
                    Caption = 'Posted Lines';
                    Image = Post;
                    action(Shipments)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Shipments';
                        Image = Shipment;
                        ToolTip = 'View a list of ongoing sales shipments for the order.';

                        trigger OnAction()
                        begin
                            Rec.ShowBlanketOrderPostedShipmentLines();
                        end;
                    }
                    action(Action1901092104)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Invoices';
                        Image = Invoice;
                        ToolTip = 'View a list of ongoing sales invoices for the order.';

                        trigger OnAction()
                        begin
                            Rec.ShowBlanketOrderPostedInvoiceLines();
                        end;
                    }
                    action("Return Receipts")
                    {
                        AccessByPermission = TableData "Return Receipt Header" = R;
                        ApplicationArea = Suite;
                        Caption = 'Return Receipts';
                        Image = ReturnReceipt;
                        ToolTip = 'View a list of posted return receipts for the order.';

                        trigger OnAction()
                        begin
                            Rec.ShowBlanketOrderPostedReturnReceiptLines();
                        end;
                    }
                    action(Action1901033504)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Credit Memos';
                        Image = CreditMemo;
                        ToolTip = 'View a list of ongoing credit memos for the order.';

                        trigger OnAction()
                        begin
                            Rec.ShowBlanketOrderPostedCreditMemoLines();
                        end;
                    }
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action(DocAttach)
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
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    ToolTip = 'View or add comments for the record.';

                    trigger OnAction()
                    begin
                        Rec.ShowLineComments();
                    end;
                }
                group("Assemble to Order")
                {
                    Caption = 'Assemble to Order';
                    Image = AssemblyBOM;
                    action("Assemble-to-Order Lines")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;
                        Caption = 'Assemble-to-Order Lines';
                        ToolTip = 'View any linked assembly order lines if the documents represents an assemble-to-order sale.';

                        trigger OnAction()
                        begin
                            Rec.ShowAsmToOrderLines();
                        end;
                    }
                    action("Roll Up &Price")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;
                        Caption = 'Roll Up &Price';
                        Ellipsis = true;
                        ToolTip = 'Update the unit price of the assembly item according to any changes that you have made to the assembly components.';

                        trigger OnAction()
                        begin
                            Rec.RollupAsmPrice();
                            CalculateTotals();
                        end;
                    }
                    action("Roll Up &Cost")
                    {
                        AccessByPermission = TableData "BOM Component" = R;
                        ApplicationArea = Assembly;
                        Caption = 'Roll Up &Cost';
                        Ellipsis = true;
                        ToolTip = 'Update the unit cost of the assembly item according to any changes that you have made to the assembly components.';

                        trigger OnAction()
                        begin
                            Rec.RollUpAsmCost();
                            CalculateTotals();
                        end;
                    }
                }
                action(DocumentLineTracking)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Document &Line Tracking';
                    Image = Navigate;
                    ToolTip = 'View related open, posted, or archived documents or document lines.';

                    trigger OnAction()
                    begin
                        ShowDocumentLineTracking();
                    end;
                }
            }
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Get &Price")
                {
                    AccessByPermission = TableData "Sales Price" = R;
                    ApplicationArea = Suite;
                    Caption = 'Get &Price';
                    Ellipsis = true;
                    Image = Price;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'Insert the lowest possible price in the Unit Price field according to any special price that you have set up.';

                    trigger OnAction()
                    begin
                        Rec.PickPrice();
                    end;
                }
                action("Get Li&ne Discount")
                {
                    AccessByPermission = TableData "Sales Line Discount" = R;
                    ApplicationArea = Suite;
                    Caption = 'Get Li&ne Discount';
                    Ellipsis = true;
                    Image = LineDiscount;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'Insert the best possible discount in the Line Discount field according to any special discounts that you have set up.';

                    trigger OnAction()
                    begin
                        Rec.PickDiscount();
                    end;
                }
                action(GetPrice)
                {
                    AccessByPermission = TableData "Sales Price Access" = R;
                    ApplicationArea = Suite;
                    Caption = 'Get &Price';
                    Ellipsis = true;
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Insert the lowest possible price in the Unit Price field according to any special price that you have set up.';

                    trigger OnAction()
                    begin
                        Rec.PickPrice();
                    end;
                }
                action(GetLineDiscount)
                {
                    AccessByPermission = TableData "Sales Discount Access" = R;
                    ApplicationArea = Suite;
                    Caption = 'Get Li&ne Discount';
                    Ellipsis = true;
                    Image = LineDiscount;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Insert the best possible discount in the Line Discount field according to any special discounts that you have set up.';

                    trigger OnAction()
                    begin
                        Rec.PickDiscount();
                    end;
                }
                action("E&xplode BOM")
                {
                    AccessByPermission = TableData "BOM Component" = R;
                    ApplicationArea = Suite;
                    Caption = 'E&xplode BOM';
                    Image = ExplodeBOM;
                    Enabled = Rec.Type = Rec.Type::Item;
                    ToolTip = 'Add a line for each component on the bill of materials for the selected item. For example, this is useful for selling the parent item as a kit. CAUTION: The line for the parent item will be deleted and only its description will display. To undo this action, delete the component lines and add a line for the parent item again. This action is available only for lines that contain an item.';

                    trigger OnAction()
                    begin
                        ExplodeBOM();
                    end;
                }
                action("Insert &Ext. Texts")
                {
                    AccessByPermission = TableData "Extended Text Header" = R;
                    ApplicationArea = Suite;
                    Caption = 'Insert &Ext. Texts';
                    Image = Text;
                    ToolTip = 'Insert the extended item description that is set up for the item that is being processed on the line.';

                    trigger OnAction()
                    begin
                        InsertExtendedText(true);
                    end;
                }
                action("Select Nonstoc&k Items")
                {
                    AccessByPermission = TableData "Nonstock Item" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Select Ca&talog Items';
                    Image = NonStockItem;
                    ToolTip = 'View the list of catalog items that exist in the system.';

                    trigger OnAction()
                    begin
                        Rec.ShowNonstock();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetTotalSalesHeader();
        CalculateTotals();
        UpdateEditableOnRow();
    end;

    trigger OnAfterGetRecord()
    var
        Item: Record Item;
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
        Clear(DocumentTotals);
        if Rec."Variant Code" = '' then
            VariantCodeMandatory := Item.IsVariantMandatory(Rec.Type = Rec.Type::Item, Rec."No.");
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        DocumentTotals.SalesDocTotalsNotUpToDate();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        DocumentTotals.SalesCheckAndClearTotals(Rec, xRec, TotalSalesLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
        exit(Rec.Find(Which));
    end;

    trigger OnInit()
    begin
        SalesReceivablesSetup.Get();
        Currency.InitRoundingPrecision();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        DocumentTotals.SalesCheckIfDocumentChanged(Rec, xRec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.InitType();
        SetDefaultType();
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        SetDimensionsVisibility();
        SetItemReferenceVisibility();
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        Currency: Record Currency;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        SalesAvailabilityMgt: Codeunit Microsoft.Sales.Document."Sales Availability Mgt.";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        DocumentTotals: Codeunit "Document Totals";
        AmountWithDiscountAllowed: Decimal;
        UpdateInvDiscountQst: Label 'One or more lines have been invoiced. The discount distributed to invoiced lines will not be taken into account.\\Do you want to update the invoice discount?';
        ExtendedPriceEnabled: Boolean;
        VariantCodeMandatory: Boolean;

    protected var
        TotalSalesHeader: Record "Sales Header";
        TotalSalesLine: Record "Sales Line";
        ShortcutDimCode: array[8] of Code[20];
        DimVisible1: Boolean;
        DimVisible2: Boolean;
        DimVisible3: Boolean;
        DimVisible4: Boolean;
        DimVisible5: Boolean;
        DimVisible6: Boolean;
        DimVisible7: Boolean;
        DimVisible8: Boolean;
        InvDiscAmountEditable: Boolean;
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountPct: Decimal;
        IsBlankNumber: Boolean;
        IsCommentLine: Boolean;
        ItemReferenceVisible: Boolean;
        VATAmount: Decimal;

    procedure ApproveCalcInvDisc()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Disc. (Yes/No)", Rec);
        DocumentTotals.SalesDocTotalsNotUpToDate();
    end;

    local procedure ValidateInvoiceDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        SalesHeader.Get(Rec."Document Type", Rec."Document No.");
        if SalesHeader.InvoicedLineExists() then
            if not ConfirmManagement.GetResponseOrDefault(UpdateInvDiscountQst, true) then
                exit;

        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvoiceDiscountAmount, SalesHeader);
        DocumentTotals.SalesDocTotalsNotUpToDate();
        CurrPage.Update(false);
    end;

    local procedure ExplodeBOM()
    begin
        CODEUNIT.Run(CODEUNIT::"Sales-Explode BOM", Rec);
        DocumentTotals.SalesDocTotalsNotUpToDate();
    end;

    procedure InsertExtendedText(Unconditionally: Boolean)
    begin
        OnBeforeInsertExtendedText(Rec);
        if TransferExtendedText.SalesCheckIfAnyExtText(Rec, Unconditionally) then begin
            CurrPage.SaveRecord();
            Commit();
            TransferExtendedText.InsertSalesExtText(Rec);
        end;
        if TransferExtendedText.MakeUpdate() then
            UpdateForm(true);
    end;

    procedure UpdateForm(SetSaveRecord: Boolean)
    begin
        CurrPage.Update(SetSaveRecord);
    end;

    local procedure GetTotalSalesHeader()
    begin
        DocumentTotals.GetTotalSalesHeaderAndCurrency(Rec, TotalSalesHeader, Currency);
    end;

    procedure ClearTotalSalesHeader();
    begin
        Clear(TotalSalesHeader);
    end;

    procedure CalculateTotals()
    begin
        DocumentTotals.SalesCheckIfDocumentChanged(Rec, xRec);
        DocumentTotals.CalculateSalesSubPageTotals(TotalSalesHeader, TotalSalesLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
        DocumentTotals.RefreshSalesLine(Rec);
    end;

    procedure CallDeltaUpdateTotals()
    begin
        DeltaUpdateTotals();
    end;

    procedure DeltaUpdateTotals()
    begin
        OnBeforeDeltaUpdateTotals(Rec, xRec);
        DocumentTotals.SalesDeltaUpdateTotals(Rec, xRec, TotalSalesLine, VATAmount, InvoiceDiscountAmount, InvoiceDiscountPct);
        if Rec."Line Amount" <> xRec."Line Amount" then
            Rec.SendLineInvoiceDiscountResetNotification();
    end;

    procedure ForceTotalsCalculation()
    begin
        DocumentTotals.SalesDocTotalsNotUpToDate();
    end;

    procedure UpdateEditableOnRow()
    begin
        IsCommentLine := not Rec.HasTypeToFillMandatoryFields();
        IsBlankNumber := IsCommentLine;

        InvDiscAmountEditable :=
            CurrPage.Editable and not SalesReceivablesSetup."Calc. Inv. Discount" and
            (TotalSalesHeader.Status = TotalSalesHeader.Status::Open);

        OnAfterUpdateEditableOnRow(Rec, IsCommentLine, IsBlankNumber);
    end;

    procedure NoOnAfterValidate()
    begin
        OnBeforeNoOnAfterValidate(Rec, xRec);

        InsertExtendedText(false);

        SaveAndAutoAsmToOrder();

        OnAfterNoOnAfterValidate(Rec, xRec);
    end;

    protected procedure LocationCodeOnAfterValidate()
    begin
        SaveAndAutoAsmToOrder();
    end;

    protected procedure VariantCodeOnAfterValidate()
    begin
        SaveAndAutoAsmToOrder();
    end;

    protected procedure QuantityOnAfterValidate()
    begin
        OnBeforeQuantityOnAfterValidate(Rec, xRec);

        if Rec.Reserve = Rec.Reserve::Always then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
        end;

        if (Rec.Type = Rec.Type::Item) and
           (Rec.Quantity <> xRec.Quantity)
        then
            CurrPage.Update(true);

        OnAfterQuantityOnAfterValidate(Rec, xRec);
    end;

    protected procedure UnitofMeasureCodeOnAfterValidate()
    begin
        if Rec.Reserve = Rec.Reserve::Always then begin
            CurrPage.SaveRecord();
            Rec.AutoReserve();
        end;
    end;

    protected procedure SaveAndAutoAsmToOrder()
    begin
        if (Rec.Type = Rec.Type::Item) and Rec.IsAsmToOrderRequired() then begin
            CurrPage.SaveRecord();
            Rec.AutoAsmToOrder();
            CurrPage.Update(false);
        end;
    end;

    procedure ShowDocumentLineTracking()
    var
        DocumentLineTrackingPage: Page "Document Line Tracking";
    begin
        Clear(DocumentLineTrackingPage);
        DocumentLineTrackingPage.SetSourceDoc(
            "Document Line Source Type"::"Blanket Sales Order", Rec."Document No.", Rec."Line No.", Rec."Blanket Order No.", Rec."Blanket Order Line No.", '', 0);
        DocumentLineTrackingPage.RunModal();
    end;

    procedure RedistributeTotalsOnAfterValidate()
    begin
        CurrPage.SaveRecord();

        DocumentTotals.SalesRedistributeInvoiceDiscountAmounts(Rec, VATAmount, TotalSalesLine);
        CurrPage.Update(false);
    end;

    local procedure SetDimensionsVisibility()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimVisible1 := false;
        DimVisible2 := false;
        DimVisible3 := false;
        DimVisible4 := false;
        DimVisible5 := false;
        DimVisible6 := false;
        DimVisible7 := false;
        DimVisible8 := false;

        DimMgt.UseShortcutDims(
          DimVisible1, DimVisible2, DimVisible3, DimVisible4, DimVisible5, DimVisible6, DimVisible7, DimVisible8);

        Clear(DimMgt);
    end;

    local procedure SetItemReferenceVisibility()
    var
        ItemReference: Record "Item Reference";
    begin
        ItemReferenceVisible := not ItemReference.IsEmpty();
    end;

    local procedure ValidateShortcutDimension(DimIndex: Integer)
    var
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        Rec.ValidateShortcutDimCode(DimIndex, ShortcutDimCode[DimIndex]);
        AssembleToOrderLink.UpdateAsmDimFromSalesLine(Rec);

        OnAfterValidateShortcutDimCode(Rec, ShortcutDimCode, DimIndex);
    end;

    local procedure SetDefaultType()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetDefaultType(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if xRec."Document No." = '' then
            Rec.Type := Rec.GetDefaultLineType();
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterNoOnAfterValidate(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeNoOnAfterValidate(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateEditableOnRow(SalesLine: Record "Sales Line"; var IsCommentLine: Boolean; var IsBlankNumber: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var SalesLine: Record "Sales Line"; var ShortcutDimCode: array[8] of Code[20]; DimIndex: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertExtendedText(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCrossReferenceNoOnLookup(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetDefaultType(var SalesLine: Record "Sales Line"; var xSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeDeltaUpdateTotals(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line");
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeQuantityOnAfterValidate(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterQuantityOnAfterValidate(var SalesLine: Record "Sales Line"; xSalesLine: Record "Sales Line")
    begin
    end;
}

