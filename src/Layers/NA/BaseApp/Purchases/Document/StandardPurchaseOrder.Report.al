// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 1322 "Standard Purchase - Order"
{
    Caption = 'Purchase - Order';
    DefaultRenderingLayout = "StandardPurchaseOrder.docx";
    EnableHyperlinks = true;
    PreviewMode = PrintLayout;
    WordMergeDataItem = "Purchase Header";

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "No.") where("Document Type" = const(Order));
            RequestFilterFields = "No.", "Buy-from Vendor No.", "No. Printed";
            RequestFilterHeading = 'Standard Purchase - Order';
            column(CompanyAddress1; CompanyAddr[1])
            {
            }
            column(CompanyAddress2; CompanyAddr[2])
            {
            }
            column(CompanyAddress3; CompanyAddr[3])
            {
            }
            column(CompanyAddress4; CompanyAddr[4])
            {
            }
            column(CompanyAddress5; CompanyAddr[5])
            {
            }
            column(CompanyAddress6; CompanyAddr[6])
            {
            }
            column(CompanyAddress7; CompanyAddr[7])
            {
            }
            column(CompanyAddress8; CompanyAddr[8])
            {
            }
            column(CompanyHomePage_Lbl; HomePageCaptionLbl)
            {
            }
            column(CompanyHomePage; CompanyInfo."Home Page")
            {
            }
            column(CompanyEmail_Lbl; EmailIDCaptionLbl)
            {
            }
            column(CompanyEMail; CompanyInfo."E-Mail")
            {
            }
            column(CompanyPicture; DummyCompanyInfo.Picture)
            {
            }
            column(CompanyPhoneNo; CompanyInfo."Phone No.")
            {
            }
            column(CompanyPhoneNo_Lbl; CompanyInfoPhoneNoCaptionLbl)
            {
            }
            column(CompanyGiroNo; CompanyInfo."Giro No.")
            {
            }
            column(CompanyGiroNo_Lbl; CompanyInfoGiroNoCaptionLbl)
            {
            }
            column(CompanyBankName; CompanyInfo."Bank Name")
            {
            }
            column(CompanyBankName_Lbl; CompanyInfoBankNameCaptionLbl)
            {
            }
            column(CompanyBankBranchNo; CompanyInfo."Bank Branch No.")
            {
            }
            column(CompanyBankBranchNo_Lbl; CompanyInfo.FieldCaption("Bank Branch No."))
            {
            }
            column(CompanyBankAccountNo; CompanyInfo."Bank Account No.")
            {
            }
            column(CompanyBankAccountNo_Lbl; CompanyInfoBankAccNoCaptionLbl)
            {
            }
            column(CompanyIBAN; CompanyInfo.IBAN)
            {
            }
            column(CompanyIBAN_Lbl; CompanyInfo.FieldCaption(IBAN))
            {
            }
            column(CompanySWIFT; CompanyInfo."SWIFT Code")
            {
            }
            column(CompanySWIFT_Lbl; CompanyInfo.FieldCaption("SWIFT Code"))
            {
            }
            column(CompanyLogoPosition; CompanyLogoPosition)
            {
            }
            column(CompanyRegistrationNumber; CompanyInfo.GetRegistrationNumber())
            {
            }
            column(CompanyRegistrationNumber_Lbl; CompanyInfo.GetRegistrationNumberLbl())
            {
            }
            column(CompanyVATRegNo; CompanyInfo.GetVATRegistrationNumber())
            {
            }
            column(CompanyVATRegNo_Lbl; CompanyInfo.GetVATRegistrationNumberLbl())
            {
            }
            column(CompanyVATRegistrationNo; CompanyInfo.GetVATRegistrationNumber())
            {
            }
            column(CompanyVATRegistrationNo_Lbl; CompanyInfo.GetVATRegistrationNumberLbl())
            {
            }
            column(CompanyLegalOffice; LegalOfficeTxt)
            {
            }
            column(CompanyLegalOffice_Lbl; LegalOfficeLbl)
            {
            }
            column(CompanyCustomGiro; CustomGiroTxt)
            {
            }
            column(CompanyCustomGiro_Lbl; CustomGiroLbl)
            {
            }
            column(DocType_PurchHeader; "Document Type")
            {
            }
            column(No_PurchHeader; "No.")
            {
            }
            column(DocumentTitle_Lbl; DocumentTitleLbl)
            {
            }
            column(Amount_Lbl; AmountCaptionLbl)
            {
            }
            column(PurchLineInvDiscAmt_Lbl; PurchLineInvDiscAmtCaptionLbl)
            {
            }
            column(Subtotal_Lbl; SubtotalCaptionLbl)
            {
            }
            column(VATAmtLineVAT_Lbl; VATAmtLineVATCaptionLbl)
            {
            }
            column(VATAmtLineVATAmt_Lbl; VATAmtLineVATAmtCaptionLbl)
            {
            }
            column(VATAmtSpec_Lbl; VATAmtSpecCaptionLbl)
            {
            }
            column(VATIdentifier_Lbl; VATIdentifierCaptionLbl)
            {
            }
            column(VATAmtLineInvDiscBaseAmt_Lbl; VATAmtLineInvDiscBaseAmtCaptionLbl)
            {
            }
            column(VATAmtLineLineAmt_Lbl; VATAmtLineLineAmtCaptionLbl)
            {
            }
            column(VALVATBaseLCY_Lbl; VALVATBaseLCYCaptionLbl)
            {
            }
            column(Total_Lbl; TotalCaptionLbl)
            {
            }
            column(PaymentTermsDesc_Lbl; PaymentTermsDescCaptionLbl)
            {
            }
            column(ShipmentMethodDesc_Lbl; ShipmentMethodDescCaptionLbl)
            {
            }
            column(PrepymtTermsDesc_Lbl; PrepymtTermsDescCaptionLbl)
            {
            }
            column(HomePage_Lbl; HomePageCaptionLbl)
            {
            }
            column(EmailID_Lbl; EmailIDCaptionLbl)
            {
            }
            column(AllowInvoiceDisc_Lbl; AllowInvoiceDiscCaptionLbl)
            {
            }
            column(DocumentDate; Format("Document Date", 0, 4))
            {
            }
            column(DueDate; Format("Due Date", 0, 4))
            {
            }
            column(ExptRecptDt_PurchaseHeader; Format("Expected Receipt Date", 0, 4))
            {
            }
            column(OrderDate_PurchaseHeader; Format("Order Date", 0, 4))
            {
            }
            column(VATNoText; VATNoText)
            {
            }
            column(VATRegNo_PurchHeader; "VAT Registration No.")
            {
            }
            column(PurchaserText; PurchaserText)
            {
            }
            column(SalesPurchPersonName; SalespersonPurchaser.Name)
            {
            }
            column(ReferenceText; ReferenceText)
            {
            }
            column(YourRef_PurchHeader; "Your Reference")
            {
            }
            column(BuyFrmVendNo_PurchHeader; "Buy-from Vendor No.")
            {
            }
            column(BuyFromAddr1; BuyFromAddr[1])
            {
            }
            column(BuyFromAddr2; BuyFromAddr[2])
            {
            }
            column(BuyFromAddr3; BuyFromAddr[3])
            {
            }
            column(BuyFromAddr4; BuyFromAddr[4])
            {
            }
            column(BuyFromAddr5; BuyFromAddr[5])
            {
            }
            column(BuyFromAddr6; BuyFromAddr[6])
            {
            }
            column(BuyFromAddr7; BuyFromAddr[7])
            {
            }
            column(BuyFromAddr8; BuyFromAddr[8])
            {
            }
            column(BuyFromContactPhoneNoLbl; BuyFromContactPhoneNoLbl)
            {
            }
            column(BuyFromContactMobilePhoneNoLbl; BuyFromContactMobilePhoneNoLbl)
            {
            }
            column(BuyFromContactEmailLbl; BuyFromContactEmailLbl)
            {
            }
            column(PayToContactPhoneNoLbl; PayToContactPhoneNoLbl)
            {
            }
            column(PayToContactMobilePhoneNoLbl; PayToContactMobilePhoneNoLbl)
            {
            }
            column(PayToContactEmailLbl; PayToContactEmailLbl)
            {
            }
            column(BuyFromContactPhoneNo; BuyFromContact."Phone No.")
            {
            }
            column(BuyFromContactMobilePhoneNo; BuyFromContact."Mobile Phone No.")
            {
            }
            column(BuyFromContactEmail; BuyFromContact."E-Mail")
            {
            }
            column(PayToContactPhoneNo; PayToContact."Phone No.")
            {
            }
            column(PayToContactMobilePhoneNo; PayToContact."Mobile Phone No.")
            {
            }
            column(PayToContactEmail; PayToContact."E-Mail")
            {
            }
            column(PricesIncludingVAT_Lbl; PricesIncludingVATCaptionLbl)
            {
            }
            column(PricesInclVAT_PurchHeader; "Prices Including VAT")
            {
            }
            column(OutputNo; OutputNo)
            {
            }
            column(VATBaseDisc_PurchHeader; "VAT Base Discount %")
            {
            }
            column(PricesInclVATtxt; PricesInclVATtxtLbl)
            {
            }
            column(PaymentTermsDesc; PaymentTerms.Description)
            {
            }
            column(ShipmentMethodDesc; ShipmentMethod.Description)
            {
            }
            column(PrepmtPaymentTermsDesc; PrepmtPaymentTerms.Description)
            {
            }
            column(DimText; DimText)
            {
            }
            column(OrderNo_Lbl; OrderNoCaptionLbl)
            {
            }
            column(Page_Lbl; PageCaptionLbl)
            {
            }
            column(DocumentDate_Lbl; DocumentDateCaptionLbl)
            {
            }
            column(BuyFrmVendNo_PurchHeader_Lbl; FieldCaption("Buy-from Vendor No."))
            {
            }
            column(PricesInclVAT_PurchHeader_Lbl; FieldCaption("Prices Including VAT"))
            {
            }
            column(Receiveby_Lbl; ReceivebyCaptionLbl)
            {
            }
            column(Buyer_Lbl; BuyerCaptionLbl)
            {
            }
            column(PayToVendNo_PurchHeader; "Pay-to Vendor No.")
            {
            }
            column(VendAddr8; VendAddr[8])
            {
            }
            column(VendAddr7; VendAddr[7])
            {
            }
            column(VendAddr6; VendAddr[6])
            {
            }
            column(VendAddr5; VendAddr[5])
            {
            }
            column(VendAddr4; VendAddr[4])
            {
            }
            column(VendAddr3; VendAddr[3])
            {
            }
            column(VendAddr2; VendAddr[2])
            {
            }
            column(VendAddr1; VendAddr[1])
            {
            }
            column(PaymentDetails_Lbl; PaymentDetailsCaptionLbl)
            {
            }
            column(VendNo_Lbl; VendNoCaptionLbl)
            {
            }
            column(SellToCustNo_PurchHeader; "Sell-to Customer No.")
            {
            }
            column(ShipToAddr1; ShipToAddr[1])
            {
            }
            column(ShipToAddr2; ShipToAddr[2])
            {
            }
            column(ShipToAddr3; ShipToAddr[3])
            {
            }
            column(ShipToAddr4; ShipToAddr[4])
            {
            }
            column(ShipToAddr5; ShipToAddr[5])
            {
            }
            column(ShipToAddr6; ShipToAddr[6])
            {
            }
            column(ShipToAddr7; ShipToAddr[7])
            {
            }
            column(ShipToAddr8; ShipToAddr[8])
            {
            }
            column(ShiptoAddress_Lbl; ShiptoAddressCaptionLbl)
            {
            }
            column(ShipToPhoneNo; "Purchase Header"."Ship-to Phone No.")
            {
            }
            column(SellToCustNo_PurchHeader_Lbl; FieldCaption("Sell-to Customer No."))
            {
            }
            column(ItemNumber_Lbl; ItemNumberCaptionLbl)
            {
            }
            column(ItemDescription_Lbl; ItemDescriptionCaptionLbl)
            {
            }
            column(ItemQuantity_Lbl; ItemQuantityCaptionLbl)
            {
            }
            column(ItemUnit_Lbl; ItemUnitCaptionLbl)
            {
            }
            column(ItemUnitPrice_Lbl; ItemUnitPriceCaptionLbl)
            {
            }
            column(ItemLineAmount_Lbl; ItemLineAmountCaptionLbl)
            {
            }
            column(ToCaption_Lbl; ToCaptionLbl)
            {
            }
            column(VendorIDCaption_Lbl; VendorIDCaptionLbl)
            {
            }
            column(ConfirmToCaption_Lbl; ConfirmToCaptionLbl)
            {
            }
            column(PurchOrderCaption_Lbl; PurchOrderCaptionLbl)
            {
            }
            column(PurchOrderNumCaption_Lbl; PurchOrderNumCaptionLbl)
            {
            }
            column(PurchOrderDateCaption_Lbl; PurchOrderDateCaptionLbl)
            {
            }
            column(TaxIdentTypeCaption_Lbl; TaxIdentTypeCaptionLbl)
            {
            }
            column(InvoiceDiscountCaption_Lbl; InvoiceDiscountCaptionLbl)
            {
            }
            column(TotalPriceCaption_Lbl; TotalPriceCaptionLbl)
            {
            }
            column(TotalTaxLabel; TotalTaxLabel)
            {
            }
            column(Tax_Lbl; TaxLbl)
            {
            }
            column(OrderDate_Lbl; OrderDateLbl)
            {
            }
            column(VendorInvoiceNo_Lbl; VendorInvoiceNoLbl)
            {
            }
            column(VendorInvoiceNo; "Vendor Invoice No.")
            {
            }
            column(VendorOrderNo_Lbl; VendorOrderNoLbl)
            {
            }
            column(VendorOrderNo; "Vendor Order No.")
            {
            }
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.");
                column(LineNo_PurchLine; "Line No.")
                {
                }
                column(AllowInvDisctxt; AllowInvDisctxt)
                {
                }
                column(Type_PurchLine; Format(Type, 0, 2))
                {
                }
                column(No_PurchLine; ItemNo)
                {
                }
                column(ItemNo_PurchLine; "No.")
                {
                }
                column(VendorItemNo_PurchLine; "Vendor Item No.")
                {
                }
                column(ItemReferenceNo_PurchLine; "Item Reference No.")
                {
                }
                column(Desc_PurchLine; Description)
                {
                }
                column(Qty_PurchLine; FormattedQuanitity)
                {
                }
                column(UOM_PurchLine; "Unit of Measure")
                {
                }
                column(DirUnitCost_PurchLine; FormattedDirectUnitCost)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 2;
                }
                column(LineDisc_PurchLine; "Line Discount %")
                {
                }
                column(LineAmt_PurchLine; FormattedLineAmount)
                {
                }
                column(AllowInvDisc_PurchLine; "Allow Invoice Disc.")
                {
                }
                column(VATIdentifier_PurchLine; "VAT Identifier")
                {
                }
                column(InvDiscAmt_PurchLine; -"Inv. Discount Amount")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalInclVAT; "Line Amount" - "Inv. Discount Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(DirectUniCost_Lbl; DirectUniCostCaptionLbl)
                {
                }
                column(PurchLineLineDisc_Lbl; PurchLineLineDiscCaptionLbl)
                {
                }
                column(VATDiscountAmount_Lbl; VATDiscountAmountCaptionLbl)
                {
                }
                column(No_PurchLine_Lbl; FieldCaption("No."))
                {
                }
                column(Desc_PurchLine_Lbl; FieldCaption(Description))
                {
                }
                column(Qty_PurchLine_Lbl; FieldCaption(Quantity))
                {
                }
                column(UOM_PurchLine_Lbl; ItemUnitOfMeasureCaptionLbl)
                {
                }
                column(VATIdentifier_PurchLine_Lbl; FieldCaption("VAT Identifier"))
                {
                }
                column(AmountIncludingVAT; "Amount Including VAT")
                {
                }
                column(LineAmtTaxAmtInvDiscountAmt; "Line Amount" + TaxAmount - "Inv. Discount Amount")
                {
                }
                column(UnitPrice_PurchLine; "Unit Price (LCY)")
                {
                }
                column(UnitPrice_PurchLine_Lbl; UnitPriceLbl)
                {
                }
                column(JobNo_PurchLine; "Job No.")
                {
                }
                column(JobNo_PurchLine_Lbl; JobNoLbl)
                {
                }
                column(JobTaskNo_PurchLine; "Job Task No.")
                {
                }
                column(JobTaskNo_PurchLine_Lbl; JobTaskNoLbl)
                {
                }
                column(PlannedReceiptDateLbl; PlannedReceiptDateLbl)
                {
                }
                column(PlannedReceiptDate; Format("Planned Receipt Date", 0, 4))
                {
                }
                column(ExpectedReceiptDateLbl; ExpectedReceiptDateLbl)
                {
                }
                column(ExpectedReceiptDate; Format("Expected Receipt Date", 0, 4))
                {
                }
                column(PromisedReceiptDateLbl; PromisedReceiptDateLbl)
                {
                }
                column(PromisedReceiptDate; Format("Promised Receipt Date", 0, 4))
                {
                }
                column(RequestedReceiptDateLbl; RequestedReceiptDateLbl)
                {
                }
                column(RequestedReceiptDate; Format("Requested Receipt Date", 0, 4))
                {
                }
                column(PurchLine_VATPct; "VAT %")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    AllowInvDisctxt := Format("Allow Invoice Disc.");
                    TotalSubTotal += "Line Amount";
                    TotalInvoiceDiscountAmount -= "Inv. Discount Amount";
                    TotalAmount += Amount;

                    ItemNo := "No.";

                    if "Vendor Item No." <> '' then
                        ItemNo := "Vendor Item No.";

                    if "Item Reference No." <> '' then
                        ItemNo := "Item Reference No.";

                    FormatDocument.SetPurchaseLine("Purchase Line", FormattedQuanitity, FormattedDirectUnitCost, FormattedVATPct, FormattedLineAmount);

                    OnLineNumber := OnLineNumber + 1;

                    if ("Purchase Header"."Tax Area Code" <> '') and not UseExternalTaxEngine then
                        SalesTaxCalc.AddPurchLine("Purchase Line");

                    if Type = Type::" " then begin
                        "Unit of Measure" := '';
                        "Line Amount" := 0;
                        "Inv. Discount Amount" := 0;
                        Quantity := 0;
                    end;

                    if OnLineNumber = NumberOfLines then
                        if "Purchase Header"."Tax Area Code" <> '' then begin
                            if UseExternalTaxEngine then
                                SalesTaxCalc.CallExternalTaxEngineForPurch("Purchase Header", true)
                            else
                                SalesTaxCalc.EndSalesTaxCalculation(UseDate);
                            SalesTaxCalc.GetSummarizedSalesTaxTable(TempSalesTaxAmtLine);
                            BrkIdx := 0;
                            PrevPrintOrder := 0;
                            PrevTaxPercent := 0;
                            TaxAmount := 0;

                            TempSalesTaxAmtLine.Reset();
                            TempSalesTaxAmtLine.SetCurrentKey("Print Order", "Tax Area Code for Key", "Tax Jurisdiction Code");
                            if TempSalesTaxAmtLine.Find('-') then
                                repeat
                                    if (TempSalesTaxAmtLine."Print Order" = 0) or
                                       (TempSalesTaxAmtLine."Print Order" <> PrevPrintOrder) or
                                       (TempSalesTaxAmtLine."Tax %" <> PrevTaxPercent)
                                    then begin
                                        BrkIdx := BrkIdx + 1;
                                        if BrkIdx > 1 then
                                            if TaxArea."Country/Region" = TaxArea."Country/Region"::CA then
                                                BreakdownTitle := TaxBreakdownLbl
                                            else
                                                BreakdownTitle := SalesTaxBreakdownLbl;
                                        if BrkIdx > ArrayLen(BreakdownAmt) then begin
                                            BrkIdx := BrkIdx - 1;
                                            BreakdownLabel[BrkIdx] := OtherTaxesLbl;
                                        end else
                                            BreakdownLabel[BrkIdx] := CopyStr(StrSubstNo(TempSalesTaxAmtLine."Print Description", TempSalesTaxAmtLine."Tax %"), 1, MaxStrLen(BreakdownLabel[BrkIdx]));
                                    end;
                                    BreakdownAmt[BrkIdx] := BreakdownAmt[BrkIdx] + TempSalesTaxAmtLine."Tax Amount";
                                    TaxAmount := TaxAmount + TempSalesTaxAmtLine."Tax Amount";
                                until TempSalesTaxAmtLine.Next() = 0;

                            if BrkIdx = 1 then begin
                                Clear(BreakdownLabel);
                                Clear(BreakdownAmt);
                            end;
                        end else begin
                            "Purchase Header".CalcFields("Amount Including VAT", Amount);
                            TaxAmount := "Purchase Header"."Amount Including VAT" - "Purchase Header".Amount;
                        end;
			
                    if FirstLineHasBeenOutput then
                        Clear(DummyCompanyInfo.Picture);
                    FirstLineHasBeenOutput := true;
                end;

                trigger OnPreDataItem()
                begin
                    NumberOfLines := Count;
                    OnLineNumber := 0;

                    FirstLineHasBeenOutput := false;
                    DummyCompanyInfo.Picture := CompanyInfo.Picture;
                end;
            }
            dataitem(Totals; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(VATAmountText; TempVATAmountLine.VATAmountText())
                {
                }
                column(TotalVATAmount; VATAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalVATDiscountAmount; -VATDiscountAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalVATBaseAmount; VATBaseAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalAmountInclVAT; TotalAmountInclVAT)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalInclVATText; TotalInclVATText)
                {
                }
                column(TotalExclVATText; TotalExclVATText)
                {
                }
                column(TotalSubTotal; TotalSubTotal)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalInvoiceDiscountAmount; TotalInvoiceDiscountAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalAmount; TotalAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalText; TotalText)
                {
                }
                column(TaxAmount; TaxAmount)
                {
                }

                trigger OnAfterGetRecord()
                var
                    TempPrepmtPurchLine: Record "Purchase Line" temporary;
                begin
                    FirstLineHasBeenOutput := false;
                    Clear(TempPurchLine);
                    Clear(PurchPost);
                    TempPurchLine.DeleteAll();
                    TempVATAmountLine.DeleteAll();
                    PurchPost.GetPurchLines("Purchase Header", TempPurchLine, 0);
                    TempPurchLine.CalcVATAmountLines(0, "Purchase Header", TempPurchLine, TempVATAmountLine);
                    TempPurchLine.UpdateVATOnLines(0, "Purchase Header", TempPurchLine, TempVATAmountLine);
                    VATAmount := TempVATAmountLine.GetTotalVATAmount();
                    VATBaseAmount := TempVATAmountLine.GetTotalVATBase();
                    VATDiscountAmount :=
                      TempVATAmountLine.GetTotalVATDiscount("Purchase Header"."Currency Code", "Purchase Header"."Prices Including VAT");
                    TotalAmountInclVAT := TempVATAmountLine.GetTotalAmountInclVAT();

                    TempPrepaymentInvLineBuffer.DeleteAll();
                    PurchasePostPrepayments.GetPurchLines("Purchase Header", 0, TempPrepmtPurchLine);
                    if not TempPrepmtPurchLine.IsEmpty() then begin
                        PurchasePostPrepayments.GetPurchLinesToDeduct("Purchase Header", TempPurchLine);
                        if not TempPurchLine.IsEmpty() then
                            PurchasePostPrepayments.CalcVATAmountLines("Purchase Header", TempPurchLine, TempPrePmtVATAmountLineDeduct, 1);
                    end;
                    PurchasePostPrepayments.CalcVATAmountLines("Purchase Header", TempPrepmtPurchLine, TempPrepmtVATAmountLine, 0);
                    TempPrepmtVATAmountLine.DeductVATAmountLine(TempPrePmtVATAmountLineDeduct);
                    PurchasePostPrepayments.UpdateVATOnLines("Purchase Header", TempPrepmtPurchLine, TempPrepmtVATAmountLine, 0);
                    PurchasePostPrepayments.BuildInvLineBuffer("Purchase Header", TempPrepmtPurchLine, 0, TempPrepaymentInvLineBuffer);
                    PrepmtVATAmount := TempPrepmtVATAmountLine.GetTotalVATAmount();
                    PrepmtVATBaseAmount := TempPrepmtVATAmountLine.GetTotalVATBase();
                    PrepmtTotalAmountInclVAT := TempPrepmtVATAmountLine.GetTotalAmountInclVAT();
                    TotalAmount := TotalSubTotal + TotalInvoiceDiscountAmount + TaxAmount;
                end;
            }
            dataitem(TaxBreakdown; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(BreakdownTitle; BreakdownTitle)
                {
                }
                column(BreakdownLabel1; BreakdownLabel[1])
                {
                }
                column(BreakdownAmt1; FormatBreakdownAmounts(BreakdownLabel[1], BreakdownAmt[1]))
                {
                }
                column(BreakdownLabel2; BreakdownLabel[2])
                {
                }
                column(BreakdownAmt2; FormatBreakdownAmounts(BreakdownLabel[2], BreakdownAmt[2]))
                {
                }
                column(BreakdownLabel3; BreakdownLabel[3])
                {
                }
                column(BreakdownAmt3; FormatBreakdownAmounts(BreakdownLabel[3], BreakdownAmt[3]))
                {
                }
                column(BreakdownAmt4; FormatBreakdownAmounts(BreakdownLabel[4], BreakdownAmt[4]))
                {
                }
                column(BreakdownLabel4; BreakdownLabel[4])
                {
                }
            }
            dataitem(VATCounter; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(VATAmtLineVATBase; TempVATAmountLine."VAT Base")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineVATAmt; TempVATAmountLine."VAT Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineLineAmt; TempVATAmountLine."Line Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineInvDiscBaseAmt; TempVATAmountLine."Inv. Disc. Base Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineInvDiscAmt; TempVATAmountLine."Invoice Discount Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineVAT; TempVATAmountLine."VAT %")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(VATAmtLineVATIdentifier; TempVATAmountLine."VAT Identifier")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TempVATAmountLine.GetLine(Number);
                end;

                trigger OnPreDataItem()
                begin
                    if VATAmount = 0 then
                        CurrReport.Break();
                    SetRange(Number, 1, TempVATAmountLine.Count);
                end;
            }
            dataitem(VATCounterLCY; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(VALExchRate; VALExchRate)
                {
                }
                column(VALSpecLCYHeader; VALSpecLCYHeader)
                {
                }
                column(VALVATAmountLCY; VALVATAmountLCY)
                {
                    AutoFormatType = 1;
                }
                column(VALVATBaseLCY; VALVATBaseLCY)
                {
                    AutoFormatType = 1;
                }

                trigger OnAfterGetRecord()
                begin
                    TempVATAmountLine.GetLine(Number);
                    VALVATBaseLCY :=
                      TempVATAmountLine.GetBaseLCY(
                        "Purchase Header"."Posting Date", "Purchase Header"."Currency Code", "Purchase Header"."Currency Factor");
                    VALVATAmountLCY :=
                      TempVATAmountLine.GetAmountLCY(
                        "Purchase Header"."Posting Date", "Purchase Header"."Currency Code", "Purchase Header"."Currency Factor");
                end;

                trigger OnPreDataItem()
                begin
                    if (not GLSetup."Print VAT specification in LCY") or
                       ("Purchase Header"."Currency Code" = '') or
                       (TempVATAmountLine.GetTotalVATAmount() = 0)
                    then
                        CurrReport.Break();

                    SetRange(Number, 1, TempVATAmountLine.Count);

                    if GLSetup."LCY Code" = '' then
                        VALSpecLCYHeader := VATAmountSpecificationLbl + LocalCurrentyLbl
                    else
                        VALSpecLCYHeader := VATAmountSpecificationLbl + Format(GLSetup."LCY Code");

                    CurrExchRate.FindCurrency("Purchase Header"."Posting Date", "Purchase Header"."Currency Code", 1);
                    VALExchRate := StrSubstNo(ExchangeRateLbl, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                end;
            }
            dataitem(PrepmtLoop; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(PrepmtLineAmount; PrepmtLineAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtInvBufGLAccNo; TempPrepaymentInvLineBuffer."G/L Account No.")
                {
                }
                column(PrepmtInvBufDesc; TempPrepaymentInvLineBuffer.Description)
                {
                }
                column(TotalInclVATText2; TotalInclVATText)
                {
                }
                column(TotalExclVATText2; TotalExclVATText)
                {
                }
                column(PrepmtInvBufAmt; TempPrepaymentInvLineBuffer.Amount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtVATAmountText; TempPrepmtVATAmountLine.VATAmountText())
                {
                }
                column(PrepmtVATAmount; PrepmtVATAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtTotalAmountInclVAT; PrepmtTotalAmountInclVAT)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtVATBaseAmount; PrepmtVATBaseAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtInvBuDescCaption; PrepmtInvBuDescCaptionLbl)
                {
                }
                column(PrepmtInvBufGLAccNoCaption; PrepmtInvBufGLAccNoCaptionLbl)
                {
                }
                column(PrepaymentSpecCaption; PrepaymentSpecCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number = 1 then begin
                        if not TempPrepaymentInvLineBuffer.Find('-') then
                            CurrReport.Break();
                    end else
                        if TempPrepaymentInvLineBuffer.Next() = 0 then
                            CurrReport.Break();

                    if "Purchase Header"."Prices Including VAT" then
                        PrepmtLineAmount := TempPrepaymentInvLineBuffer."Amount Incl. VAT"
                    else
                        PrepmtLineAmount := TempPrepaymentInvLineBuffer.Amount;
                end;
            }
            dataitem(PrepmtVATCounter; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(PrepmtVATAmtLineVATAmt; TempPrepmtVATAmountLine."VAT Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtVATAmtLineVATBase; TempPrepmtVATAmountLine."VAT Base")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtVATAmtLineLineAmt; TempPrepmtVATAmountLine."Line Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtVATAmtLineVAT; TempPrepmtVATAmountLine."VAT %")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(PrepmtVATAmtLineVATId; TempPrepmtVATAmountLine."VAT Identifier")
                {
                }
                column(PrepymtVATAmtSpecCaption; PrepymtVATAmtSpecCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TempPrepmtVATAmountLine.GetLine(Number);
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, TempPrepmtVATAmountLine.Count);
                end;
            }
            dataitem(LetterText; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(GreetingText; GreetingLbl)
                {
                }
                column(BodyText; BodyLbl)
                {
                }
                column(ClosingText; ClosingLbl)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                FirstLineHasBeenOutput := false;
                TotalAmount := 0;
                TotalSubTotal := 0;
                TaxAmount := 0;
                TotalSubTotal := 0;
                TotalInvoiceDiscountAmount := 0;
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                Clear(BreakdownTitle);
                Clear(BreakdownLabel);
                Clear(BreakdownAmt);

                FormatAddressFields("Purchase Header");
                FormatDocumentFields("Purchase Header");
                if BuyFromContact.Get("Buy-from Contact No.") then;
                if PayToContact.Get("Pay-to Contact No.") then;

                if not IsReportInPreviewMode() then begin
                    CODEUNIT.Run(CODEUNIT::"Purch.Header-Printed", "Purchase Header");
                    if ArchiveDocument then
                        ArchiveManagement.StorePurchDocument("Purchase Header", LogInteraction);
                end;

                TotalTaxLabel := TaxLbl;
                if "Tax Area Code" <> '' then begin
                    TaxArea.Get("Tax Area Code");
                    case TaxArea."Country/Region" of
                        TaxArea."Country/Region"::US:
                            TotalTaxLabel := TotalSalesTaxLbl;
                        TaxArea."Country/Region"::CA:
                            TotalTaxLabel := TotalTaxLbl;
                    end;
                    UseExternalTaxEngine := TaxArea."Use External Tax Engine";
                    SalesTaxCalc.StartSalesTaxCalculation();
                end;

                if "Posting Date" <> 0D then
                    UseDate := "Posting Date"
                else
                    UseDate := WorkDate();
            end;

            trigger OnPreDataItem()
            begin
                FirstLineHasBeenOutput := false;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ArchiveDocument; ArchiveDocument)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Archive Document';
                        ToolTip = 'Specifies whether to archive the order.';
                    }
                    field(LogInteraction; LogInteraction)
                    {
                        ApplicationArea = Suite;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want to log this interaction.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            InitLogInteraction();
            LogInteractionEnable := LogInteraction;
            ArchiveDocument := PurchSetup."Archive Orders";
        end;
    }

    rendering
    {
        layout("StandardPurchaseOrder.docx")
        {
            Type = Word;
            LayoutFile = './Purchases/Document/StandardPurchaseOrder.docx';
            Caption = 'Standard Purchase Order (Word)';
            Summary = 'The Standard Purchase Order (Word) provides a basic layout.';
        }
        layout("StandardPurchaseOrderThemable.docx")
        {
            Type = Word;
            LayoutFile = './Purchases/Document/StandardPurchaseOrderThemable.docx';
            Caption = 'Standard Purchase Order - themable Word layout';
            Summary = 'The Standard Purchase Order (Word) provides a Themable layout.';
        }
        layout("StandardPurchaseOrderEmail.docx")
        {
            Type = Word;
            LayoutFile = './Purchases/Document/StandardPurchaseOrderEmail.docx';
            Caption = 'Standard Purchase Order Email (Word)';
            Summary = 'The Standard Purchase Order Email (Word) provides an email body layout.';
        }
        layout("StandardPurchaseOrderBlue.docx")
        {
            Type = Word;
            LayoutFile = './Purchases/Document/StandardPurchaseOrderBlue.docx';
            Caption = 'Standard Purchase Order Blue (Word)';
            Summary = 'The Standard Purchase Order (Word) provides a basic layout with a blue theme.';
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    var
        IsHandled: Boolean;
    begin
        GLSetup.Get();
        CompanyInfo.SetAutoCalcFields(Picture);
        CompanyInfo.Get();
        PurchSetup.Get();

        IsHandled := false;
        OnInitReportForGlobalVariable(IsHandled, LegalOfficeTxt, LegalOfficeLbl, CustomGiroTxt, CustomGiroLbl);
    end;

    trigger OnPostReport()
    begin
        if LogInteraction and not IsReportInPreviewMode() then
            if "Purchase Header".FindSet() then
                repeat
                    SegManagement.LogDocument(
                      13, "Purchase Header"."No.", 0, 0, DATABASE::Vendor, "Purchase Header"."Buy-from Vendor No.",
                      "Purchase Header"."Purchaser Code", '', "Purchase Header"."Posting Description", '');
                until "Purchase Header".Next() = 0;
    end;

    var
        DummyCompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        TempPurchLine: Record "Purchase Line" temporary;
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        TaxArea: Record "Tax Area";
        CurrExchRate: Record "Currency Exchange Rate";
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        PurchPost: Codeunit "Purch.-Post";
        SegManagement: Codeunit SegManagement;
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        ArchiveManagement: Codeunit ArchiveManagement;
        SalesTaxCalc: Codeunit "Sales Tax Calculate";
        VATNoText: Text[80];
        ReferenceText: Text[80];
        OutputNo: Integer;
        DimText: Text[120];
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
        VATDiscountAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
        PrepmtVATAmount: Decimal;
        PrepmtVATBaseAmount: Decimal;
        PrepmtTotalAmountInclVAT: Decimal;
        PrepmtLineAmount: Decimal;
        AllowInvDisctxt: Text[30];
        CompanyLogoPosition: Integer;
        ItemNo: Text;
        TaxAmount: Decimal;
        VATAmountSpecificationLbl: Label 'VAT Amount Specification in ';
        LocalCurrentyLbl: Label 'Local Currency';
        ExchangeRateLbl: Label 'Exchange rate: %1/%2', Comment = '%1 = CurrExchRate."Relational Exch. Rate Amount", %2 = CurrExchRate."Exchange Rate Amount"';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoBankAccNoCaptionLbl: Label 'Account No.';
        OrderNoCaptionLbl: Label 'Order No.';
        PageCaptionLbl: Label 'Page';
        DocumentDateCaptionLbl: Label 'Document Date';
        DirectUniCostCaptionLbl: Label 'Direct Unit Cost';
        PurchLineLineDiscCaptionLbl: Label 'Discount %';
        VATDiscountAmountCaptionLbl: Label 'Payment Discount on VAT';
        PaymentDetailsCaptionLbl: Label 'Payment Details';
        VendNoCaptionLbl: Label 'Vendor No.';
        ShiptoAddressCaptionLbl: Label 'Ship-to Address';
        PrepmtInvBuDescCaptionLbl: Label 'Description';
        PrepmtInvBufGLAccNoCaptionLbl: Label 'G/L Account No.';
        PrepaymentSpecCaptionLbl: Label 'Prepayment Specification';
        PrepymtVATAmtSpecCaptionLbl: Label 'Prepayment VAT Amount Specification';
        AmountCaptionLbl: Label 'Amount';
        PurchLineInvDiscAmtCaptionLbl: Label 'Invoice Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        VATAmtLineVATCaptionLbl: Label 'VAT %';
        VATAmtLineVATAmtCaptionLbl: Label 'VAT Amount';
        VATAmtSpecCaptionLbl: Label 'VAT Amount Specification';
        VATIdentifierCaptionLbl: Label 'VAT Identifier';
        VATAmtLineInvDiscBaseAmtCaptionLbl: Label 'Invoice Discount Base Amount';
        VATAmtLineLineAmtCaptionLbl: Label 'Line Amount';
        VALVATBaseLCYCaptionLbl: Label 'VAT Base';
        PricesInclVATtxtLbl: Label 'Prices Including VAT';
        TotalCaptionLbl: Label 'Total';
        PaymentTermsDescCaptionLbl: Label 'Payment Terms';
        ShipmentMethodDescCaptionLbl: Label 'Shipment Method';
        PrepymtTermsDescCaptionLbl: Label 'Prepmt. Payment Terms';
        HomePageCaptionLbl: Label 'Home Page';
        EmailIDCaptionLbl: Label 'Email';
        AllowInvoiceDiscCaptionLbl: Label 'Allow Invoice Discount';
        BuyFromContactPhoneNoLbl: Label 'Buy-from Contact Phone No.';
        BuyFromContactMobilePhoneNoLbl: Label 'Buy-from Contact Mobile Phone No.';
        BuyFromContactEmailLbl: Label 'Buy-from Contact E-Mail';
        PayToContactPhoneNoLbl: Label 'Pay-to Contact Phone No.';
        PayToContactMobilePhoneNoLbl: Label 'Pay-to Contact Mobile Phone No.';
        PayToContactEmailLbl: Label 'Pay-to Contact E-Mail';
        DocumentTitleLbl: Label 'Purchase Order';
        ReceivebyCaptionLbl: Label 'Receive By';
        BuyerCaptionLbl: Label 'Buyer';
        ItemNumberCaptionLbl: Label 'Item No.';
        ItemDescriptionCaptionLbl: Label 'Description';
        ItemQuantityCaptionLbl: Label 'Quantity';
        ItemUnitCaptionLbl: Label 'Unit';
        ItemUnitPriceCaptionLbl: Label 'Unit Price';
        ItemLineAmountCaptionLbl: Label 'Line Amount';
        PricesIncludingVATCaptionLbl: Label 'Prices Including VAT';
        ItemUnitOfMeasureCaptionLbl: Label 'Unit';
        ToCaptionLbl: Label 'To:';
        VendorIDCaptionLbl: Label 'Vendor ID';
        ConfirmToCaptionLbl: Label 'Confirm To';
        PurchOrderCaptionLbl: Label 'PURCHASE ORDER';
        PurchOrderNumCaptionLbl: Label 'Purchase Order Number:';
        PurchOrderDateCaptionLbl: Label 'Purchase Order Date:';
        TaxIdentTypeCaptionLbl: Label 'Tax Ident. Type';
        TotalPriceCaptionLbl: Label 'Total Price';
        VendorOrderNoLbl: Label 'Vendor Order No.';
        VendorInvoiceNoLbl: Label 'Vendor Invoice No.';
        InvoiceDiscountCaptionLbl: Label 'Invoice Discount';
        SalesTaxBreakdownLbl: Label 'Sales Tax Breakdown';
        OtherTaxesLbl: Label 'Other Taxes';
        TotalSalesTaxLbl: Label 'Total Sales Tax';
        TotalTaxLbl: Label 'Total Tax';
        TaxLbl: Label 'Tax';
        TotalTaxLabel: Text[30];
        BreakdownTitle: Text[30];
        BreakdownLabel: array[4] of Text[30];
        UseExternalTaxEngine: Boolean;
        NumberOfLines: Integer;
        OnLineNumber: Integer;
        UseDate: Date;
        BrkIdx: Integer;
        PrevPrintOrder: Integer;
        PrevTaxPercent: Decimal;
        TaxBreakdownLbl: Label 'Tax Breakdown';
        BreakdownAmt: array[4] of Decimal;
        GreetingLbl: Label 'Hello';
        ClosingLbl: Label 'Sincerely';
        BodyLbl: Label 'The purchase order is attached to this message.';
        OrderDateLbl: Label 'Order Date';
        UnitPriceLbl: Label 'Unit Price (LCY)';
        JobNoLbl: Label 'Project No.';
        JobTaskNoLbl: Label 'Project Task No.';
        PromisedReceiptDateLbl: Label 'Promised Receipt Date';
        RequestedReceiptDateLbl: Label 'Requested Receipt Date';
        ExpectedReceiptDateLbl: Label 'Expected Receipt Date';
        PlannedReceiptDateLbl: Label 'Planned Receipt Date';
        LegalOfficeTxt, LegalOfficeLbl, CustomGiroTxt, CustomGiroLbl : Text;

    protected var
        ResponsibilityCenter: Record "Responsibility Center";
        BuyFromContact: Record Contact;
        PayToContact: Record Contact;
        CompanyInfo: Record "Company Information";
        PurchSetup: Record "Purchases & Payables Setup";
        ShipmentMethod: Record "Shipment Method";
        PaymentTerms: Record "Payment Terms";
        PrepmtPaymentTerms: Record "Payment Terms";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempPrepmtVATAmountLine: Record "VAT Amount Line" temporary;
        TempPrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary;
        TempPrePmtVATAmountLineDeduct: Record "VAT Amount Line" temporary;
        BuyFromAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        VendAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        FormattedQuanitity: Text;
        FormattedDirectUnitCost: Text;
        FormattedVATPct: Text;
        FormattedLineAmount: Text;
        PurchaserText: Text[50];
        TotalText: Text[50];
        TotalInclVATText: Text[50];
        TotalExclVATText: Text[50];
        ArchiveDocument: Boolean;
        LogInteraction: Boolean;
        LogInteractionEnable: Boolean;
        FirstLineHasBeenOutput: Boolean;
        TotalSubTotal, TotalAmount, TotalInvoiceDiscountAmount : Decimal;

    procedure InitializeRequest(LogInteractionParam: Boolean)
    begin
        LogInteraction := LogInteractionParam;
    end;

    protected procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview() or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var PurchaseHeader: Record "Purchase Header")
    begin
        FormatAddr.GetCompanyAddr(PurchaseHeader."Responsibility Center", ResponsibilityCenter, CompanyInfo, CompanyAddr);
        FormatAddr.PurchHeaderBuyFrom(BuyFromAddr, PurchaseHeader);
        if PurchaseHeader."Buy-from Vendor No." <> PurchaseHeader."Pay-to Vendor No." then
            FormatAddr.PurchHeaderPayTo(VendAddr, PurchaseHeader);
        FormatAddr.PurchHeaderShipTo(ShipToAddr, PurchaseHeader);
    end;

    local procedure FormatDocumentFields(PurchaseHeader: Record "Purchase Header")
    begin
        FormatDocument.SetTotalLabels(PurchaseHeader."Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
        FormatDocument.SetPurchaser(SalespersonPurchaser, PurchaseHeader."Purchaser Code", PurchaserText);
        FormatDocument.SetPaymentTerms(PaymentTerms, PurchaseHeader."Payment Terms Code", PurchaseHeader."Language Code");
        FormatDocument.SetPaymentTerms(PrepmtPaymentTerms, PurchaseHeader."Prepmt. Payment Terms Code", PurchaseHeader."Language Code");
        FormatDocument.SetShipmentMethod(ShipmentMethod, PurchaseHeader."Shipment Method Code", PurchaseHeader."Language Code");

        ReferenceText := FormatDocument.SetText(PurchaseHeader."Your Reference" <> '', PurchaseHeader.FieldCaption("Your Reference"));
        VATNoText := FormatDocument.SetText(PurchaseHeader."VAT Registration No." <> '', PurchaseHeader.FieldCaption("VAT Registration No."));

        OnAfterFormatDocumentFields(PurchaseHeader);
    end;

    local procedure InitLogInteraction()
    begin
        LogInteraction := SegManagement.FindInteractionTemplateCode(Enum::"Interaction Log Entry Document Type"::"Purch. Ord.") <> '';
    end;

    local procedure FormatBreakdownAmounts(BreakdownLabel: Text; BreakdownAmount: Decimal): Text
    var
        BreakdownTextAmount: Text;
    begin
        // If the breakdown label is blank, the breakdown amount should be blank too.
        // This enables the NA report layout to serve both CA and US.
        if BreakdownLabel <> '' then
            BreakdownTextAmount := Format(BreakdownAmount, 0, '<Precision,2><Standard Format,0>')
        else
            BreakdownTextAmount := '';

        exit(BreakdownTextAmount);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFormatDocumentFields(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitReportForGlobalVariable(var IsHandled: Boolean; var LegalOfficeTxt: Text; var LegalOfficeLbl: Text; var CustomGiroTxt: Text; var CustomGiroLbl: Text)
    begin
    end;
}

