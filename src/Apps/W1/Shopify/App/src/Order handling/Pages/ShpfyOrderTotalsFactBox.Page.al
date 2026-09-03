// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Utilities;

page 30172 "Shpfy Order Totals FactBox"
{
    ApplicationArea = All;
    Caption = 'Order Totals';
    PageType = CardPart;
    SourceTable = "Shpfy Order Header";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(content)
        {
            group(Shopify)
            {
                Caption = 'Shopify';

                field("Shopify Order No."; Rec."Shopify Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Shopify Order Number.';

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"Shpfy Order", Rec);
                    end;
                }
                group(ShopifyTotals)
                {
                    Caption = 'Shopify Totals';
                    ShowCaption = false;
                    Visible = not PresentmentVisible;

                    field("Subtotal Amount"; ShopifySubtotalAmount)
                    {
                        ApplicationArea = All;
                        Caption = 'Subtotal Amount';
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        ToolTip = 'Specifies the subtotal amount of the order, excluding any exchange items that are invoiced separately.';
                    }
                    field("Shipping Charges Amount"; Rec."Shipping Charges Amount")
                    {
                        ApplicationArea = All;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        ToolTip = 'Specifies the shipping charges amount of the order.';
                    }
                    field("Total Amount"; ShopifyTotalAmount)
                    {
                        ApplicationArea = All;
                        Caption = 'Total Amount';
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        ToolTip = 'Specifies the total amount of the order, excluding any exchange items that are invoiced separately.';
                    }
                    field(VATAmount; ShopifyVATAmount)
                    {
                        ApplicationArea = All;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetTotalVATCaption(Rec."Currency Code");
                        ToolTip = 'Specifies the sum of tax amounts on all lines in the document, excluding any exchange items that are invoiced separately.';
                    }
                    field(RoundingAmount; Rec."Payment Rounding Amount")
                    {
                        ApplicationArea = All;
                        AutoFormatExpression = Rec."Currency Code";
                        AutoFormatType = 1;
                        ToolTip = 'Specifies the amount of rounding applied to the total amount of the document.';
                    }
                }
                group(ShopifyPresentmentTotals)
                {
                    Caption = 'Shopify Presentment Totals';
                    ShowCaption = false;
                    Visible = PresentmentVisible;

                    field("Presentment Subtotal Amount"; PresentmentSubtotalAmount)
                    {
                        ApplicationArea = All;
                        Caption = 'Presentment Subtotal Amount';
                        AutoFormatExpression = Rec."Presentment Currency Code";
                        AutoFormatType = 1;
                        ToolTip = 'Specifies the presentment subtotal amount of the order, excluding any exchange items that are invoiced separately.';
                    }
                    field("Presentment Shipping Charges Amount"; Rec."Pres. Shipping Charges Amount")
                    {
                        ApplicationArea = All;
                        AutoFormatExpression = Rec."Presentment Currency Code";
                        AutoFormatType = 1;
                        ToolTip = 'Specifies the presentment shipping charges amount of the order.';
                    }
                    field("Presentment Total Amount"; PresentmentTotalAmount)
                    {
                        ApplicationArea = All;
                        Caption = 'Presentment Total Amount';
                        AutoFormatExpression = Rec."Presentment Currency Code";
                        AutoFormatType = 1;
                        ToolTip = 'Specifies the presentment total amount of the order, excluding any exchange items that are invoiced separately.';
                    }
                    field("Presentment VAT Amount"; PresentmentVATAmount)
                    {
                        ApplicationArea = All;
                        AutoFormatExpression = Rec."Presentment Currency Code";
                        AutoFormatType = 1;
                        CaptionClass = DocumentTotals.GetTotalVATCaption(Rec."Presentment Currency Code");
                        ToolTip = 'Specifies the sum of presentment tax amounts on all lines in the document, excluding any exchange items that are invoiced separately.';
                    }
                    field("Presentment Payment Rounding Amount"; Rec."Pres. Payment Rounding Amount")
                    {
                        ApplicationArea = All;
                        AutoFormatExpression = Rec."Presentment Currency Code";
                        AutoFormatType = 1;
                        ToolTip = 'Specifies the amount of presentment rounding applied to the total amount of the document.';
                    }
                }
                field("VAT Included"; Rec."VAT Included")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if tax is included in the unit price.';
                }
                group(ShopifyCurrency)
                {
                    Caption = 'Currency';
                    ShowCaption = false;
                    Visible = not PresentmentVisible;

                    field("Currency Code"; Rec."Currency Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the currency of amounts on the document.';
                    }
                }
                group(ShopifyPresentmentCurrency)
                {
                    Caption = 'Presentment Currency';
                    ShowCaption = false;
                    Visible = PresentmentVisible;

                    field("Presentment Currency Code"; Rec."Presentment Currency Code")
                    {
                        ApplicationArea = All;
                        ToolTip = 'Specifies the presentment currency of amounts on the document.';
                    }
                }
            }
            group(SalesDocument)
            {
                Caption = 'Sales Document';

                field(SalesDocumentNo; DocumentNo)
                {
                    ApplicationArea = All;
                    Caption = 'Sales Document No.';
                    ToolTip = 'Specifies the sales document number.';

                    trigger OnDrillDown()
                    var
                        IOpenBCDocument: Interface "Shpfy IOpenBCDocument";
                    begin
                        if DocumentNo = '' then
                            exit;
                        IOpenBCDocument := SalesDocumentType;
                        IOpenBCDocument.OpenDocument(DocumentNo);
                    end;
                }
                field(TotalAmountExclVAT; TotalAmountExclVAT)
                {
                    ApplicationArea = All;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalExclVATCaption(CurrencyCode);
                    Caption = 'Total Amount Excl. VAT';
                    ToolTip = 'Specifies the sum of the value in the Line Amount Excl. VAT field on all lines in the document minus any discount amount in the Invoice Discount Amount field.';
                }
                field("Total VAT Amount"; VATAmount)
                {
                    ApplicationArea = All;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalVATCaption(CurrencyCode);
                    Caption = 'Total VAT';
                    ToolTip = 'Specifies the sum of VAT amounts on all lines in the document.';
                }
                field("Total Amount Incl. VAT"; TotalAmountInclVAT)
                {
                    ApplicationArea = All;
                    AutoFormatExpression = CurrencyCode;
                    AutoFormatType = 1;
                    CaptionClass = DocumentTotals.GetTotalInclVATCaption(CurrencyCode);
                    Caption = 'Total Amount Incl. VAT';
                    ToolTip = 'Specifies the sum of the value in the Line Amount Incl. VAT field on all lines in the document.';
                }
                field(PricesIncludingVAT; PricesIncludingVAT)
                {
                    ApplicationArea = All;
                    Caption = 'Prices Including VAT';
                    ToolTip = 'Specifies if tax is included in the unit price.';
                }
                field(NumberOfLines; NumberOfLines)
                {
                    ApplicationArea = All;
                    Caption = 'Number of Lines';
                    ToolTip = 'Specifies the number of lines in the sales document.';

                    trigger OnDrillDown()
                    var
                        SalesLine: Record "Sales Line";
                        SalesInvoiceLine: Record "Sales Invoice Line";
                    begin
                        if DocumentNo = '' then
                            exit;
                        case SalesDocumentType of
                            SalesDocumentType::"Sales Order",
                            SalesDocumentType::"Sales Invoice":
                                begin
                                    SalesLine.SetRange("Document Type", GetSalesDocumentType());
                                    SalesLine.SetRange("Document No.", DocumentNo);
                                    Page.Run(Page::"Sales Lines", SalesLine);
                                end;
                            SalesDocumentType::"Posted Sales Invoice":
                                begin
                                    SalesInvoiceLine.SetRange("Document No.", DocumentNo);
                                    Page.Run(Page::"Posted Sales Invoice Lines", SalesInvoiceLine);
                                end;
                        end;
                    end;
                }
                field(CurrencyCode; CurrencyCode)
                {
                    ApplicationArea = All;
                    Caption = 'Currency Code';
                    ToolTip = 'Specifies the currency of amounts on the sales document.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PresentmentVisible := Rec.IsPresentmentCurrencyOrder();
        CalcShopifyTotalsExcludingExchange();
        UpdateSalesDocumentInfo();
    end;

    local procedure UpdateSalesDocumentInfo()
    begin
        ClearSalesDocumentInfo();
        if not ResolveSalesDocument(SalesDocumentType, DocumentNo) then begin
            DocumentNo := '';
            exit;
        end;

        case SalesDocumentType of
            SalesDocumentType::"Sales Order",
            SalesDocumentType::"Sales Invoice":
                UpdateOpenSalesDocumentTotals();
            SalesDocumentType::"Posted Sales Invoice":
                UpdatePostedSalesInvoiceTotals();
        end;
    end;

    local procedure CalcShopifyTotalsExcludingExchange()
    var
        OrderLine: Record "Shpfy Order Line";
        OrderTaxLine: Record "Shpfy Order Tax Line";
        ExchangeSubtotal: Decimal;
        ExchangePresentmentSubtotal: Decimal;
        ExchangeTax: Decimal;
        ExchangePresentmentTax: Decimal;
    begin
        // Exclude exchange items from the shown Shopify totals; they are invoiced separately, not on the BC sales doc.
        OrderLine.SetRange("Shopify Order Id", Rec."Shopify Order Id");
        OrderLine.SetRange("Is Exchange Item", true);
        if OrderLine.FindSet() then
            repeat
                ExchangeSubtotal += (OrderLine."Unit Price" * OrderLine.Quantity) - OrderLine."Discount Amount";
                ExchangePresentmentSubtotal += (OrderLine."Presentment Unit Price" * OrderLine.Quantity) - OrderLine."Presentment Discount Amount";

                OrderTaxLine.SetRange("Parent Id", OrderLine."Line Id");
                OrderTaxLine.CalcSums(Amount, "Presentment Amount");
                ExchangeTax += OrderTaxLine.Amount;
                ExchangePresentmentTax += OrderTaxLine."Presentment Amount";
            until OrderLine.Next() = 0;

        ShopifySubtotalAmount := Rec."Subtotal Amount" - ExchangeSubtotal;
        ShopifyVATAmount := Rec."VAT Amount" - ExchangeTax;
        ShopifyTotalAmount := Rec."Total Amount" - (ExchangeSubtotal + ExchangeTax);
        PresentmentSubtotalAmount := Rec."Presentment Subtotal Amount" - ExchangePresentmentSubtotal;
        PresentmentVATAmount := Rec."Presentment VAT Amount" - ExchangePresentmentTax;
        PresentmentTotalAmount := Rec."Presentment Total Amount" - (ExchangePresentmentSubtotal + ExchangePresentmentTax);
    end;

    local procedure ResolveSalesDocument(var DocumentType: Enum "Shpfy Document Type"; var ResolvedDocumentNo: Code[20]): Boolean
    begin
        if FindLinkedDocument("Shpfy Document Type"::"Posted Sales Invoice", ResolvedDocumentNo) then begin
            DocumentType := "Shpfy Document Type"::"Posted Sales Invoice";
            exit(true);
        end;
        if FindLinkedDocument("Shpfy Document Type"::"Sales Invoice", ResolvedDocumentNo) then begin
            DocumentType := "Shpfy Document Type"::"Sales Invoice";
            exit(true);
        end;
        if FindLinkedDocument("Shpfy Document Type"::"Sales Order", ResolvedDocumentNo) then begin
            DocumentType := "Shpfy Document Type"::"Sales Order";
            exit(true);
        end;

        // Fallback for orders processed before the document link table was populated.
        if Rec."Sales Invoice No." <> '' then begin
            DocumentType := "Shpfy Document Type"::"Sales Invoice";
            ResolvedDocumentNo := Rec."Sales Invoice No.";
            exit(true);
        end;
        if Rec."Sales Order No." <> '' then begin
            DocumentType := "Shpfy Document Type"::"Sales Order";
            ResolvedDocumentNo := Rec."Sales Order No.";
            exit(true);
        end;
        exit(false);
    end;

    local procedure FindLinkedDocument(DocumentType: Enum "Shpfy Document Type"; var ResolvedDocumentNo: Code[20]): Boolean
    var
        DocLinkToBCDoc: Record "Shpfy Doc. Link To Doc.";
    begin
        DocLinkToBCDoc.SetRange("Shopify Document Type", "Shpfy Shop Document Type"::"Shopify Shop Order");
        DocLinkToBCDoc.SetRange("Shopify Document Id", Rec."Shopify Order Id");
        DocLinkToBCDoc.SetRange("Document Type", DocumentType);
        if DocLinkToBCDoc.FindLast() then begin
            ResolvedDocumentNo := DocLinkToBCDoc."Document No.";
            exit(true);
        end;
        exit(false);
    end;

    local procedure UpdateOpenSalesDocumentTotals()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TotalSalesLine: Record "Sales Line";
    begin
        if not SalesHeader.Get(GetSalesDocumentType(), DocumentNo) then begin
            ClearSalesDocumentInfo();
            exit;
        end;

        PricesIncludingVAT := SalesHeader."Prices Including VAT";
        CurrencyCode := GetCurrencyCode(SalesHeader."Currency Code");

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        NumberOfLines := SalesLine.Count();
        if SalesLine.FindLast() then begin
            DocumentTotals.CalculateSalesTotals(TotalSalesLine, VATAmount, SalesLine);
            TotalAmountExclVAT := TotalSalesLine.Amount;
            TotalAmountInclVAT := TotalSalesLine."Amount Including VAT";
        end;
    end;

    local procedure UpdatePostedSalesInvoiceTotals()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        if not SalesInvoiceHeader.Get(DocumentNo) then begin
            ClearSalesDocumentInfo();
            exit;
        end;

        PricesIncludingVAT := SalesInvoiceHeader."Prices Including VAT";
        CurrencyCode := GetCurrencyCode(SalesInvoiceHeader."Currency Code");

        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        NumberOfLines := SalesInvoiceLine.Count();
        if SalesInvoiceLine.FindFirst() then
            DocumentTotals.CalculatePostedSalesInvoiceTotals(SalesInvoiceHeader, VATAmount, SalesInvoiceLine);

        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        TotalAmountExclVAT := SalesInvoiceHeader.Amount;
        TotalAmountInclVAT := SalesInvoiceHeader."Amount Including VAT";
    end;

    local procedure ClearSalesDocumentInfo()
    begin
        Clear(SalesDocumentType);
        DocumentNo := '';
        PricesIncludingVAT := false;
        NumberOfLines := 0;
        CurrencyCode := '';
        VATAmount := 0;
        TotalAmountExclVAT := 0;
        TotalAmountInclVAT := 0;
    end;

    local procedure GetSalesDocumentType(): Enum "Sales Document Type"
    begin
        case SalesDocumentType of
            SalesDocumentType::"Sales Order":
                exit("Sales Document Type"::Order);
            SalesDocumentType::"Sales Invoice":
                exit("Sales Document Type"::Invoice);
        end;
    end;

    local procedure GetCurrencyCode(DocumentCurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if DocumentCurrencyCode <> '' then
            exit(DocumentCurrencyCode);
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."LCY Code");
    end;

    var
        DocumentTotals: Codeunit "Document Totals";
        SalesDocumentType: Enum "Shpfy Document Type";
        DocumentNo: Code[20];
        PricesIncludingVAT: Boolean;
        PresentmentVisible: Boolean;
        NumberOfLines: Integer;
        CurrencyCode: Code[10];
        VATAmount: Decimal;
        TotalAmountExclVAT: Decimal;
        TotalAmountInclVAT: Decimal;
        ShopifySubtotalAmount: Decimal;
        ShopifyTotalAmount: Decimal;
        ShopifyVATAmount: Decimal;
        PresentmentSubtotalAmount: Decimal;
        PresentmentTotalAmount: Decimal;
        PresentmentVATAmount: Decimal;
}
