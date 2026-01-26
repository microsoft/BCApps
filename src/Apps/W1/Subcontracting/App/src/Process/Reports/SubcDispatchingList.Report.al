// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 99001504 "Subc. Dispatching List"
{
    ApplicationArea = Manufacturing;
    Caption = 'Subcontractor - Dispatch List';
    DefaultLayout = Word;
    PreviewMode = PrintLayout;
    UsageCategory = Administration;
    WordLayout = '.\src\Process\Reports\SubcDispatchingList.docx';
    WordMergeDataItem = "Purchase Header";

    dataset
    {
        dataitem("Purchase Header"; "Purchase Header")
        {
            DataItemTableView = sorting("Document Type", "Buy-from Vendor No.", "No.") where("Subcontracting Order" = const(true));
            RequestFilterFields = "No.", "Buy-from Vendor No.", "No. Printed";
            RequestFilterHeading = 'Subcontractor - Dispatch List';
            column(AllowInvoiceDisc_Lbl; AllowInvoiceDiscCaptionLbl)
            {
            }
            column(Amount_Lbl; AmountCaptionLbl)
            {
            }
            column(Buyer_Lbl; BuyerCaptionLbl)
            {
            }
            column(BuyFrmVendNo_PurchHeader; "Buy-from Vendor No.")
            {
            }
            column(BuyFrmVendNo_PurchHeader_Lbl; FieldCaption("Buy-from Vendor No."))
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
            column(BuyFromContactEmail; BuyFromContact."E-Mail")
            {
            }
            column(BuyFromContactEmailLbl; BuyFromContactEmailLbl)
            {
            }
            column(BuyFromContactMobilePhoneNo; BuyFromContact."Mobile Phone No.")
            {
            }
            column(BuyFromContactMobilePhoneNoLbl; BuyFromContactMobilePhoneNoLbl)
            {
            }
            column(BuyFromContactPhoneNo; BuyFromContact."Phone No.")
            {
            }
            column(BuyFromContactPhoneNoLbl; BuyFromContactPhoneNoLbl)
            {
            }
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
            column(CompanyBankAccountNo; CompanyInformation."Bank Account No.")
            {
            }
            column(CompanyBankAccountNo_Lbl; CompanyInfoBankAccNoCaptionLbl)
            {
            }
            column(CompanyBankBranchNo; CompanyInformation."Bank Branch No.")
            {
            }
            column(CompanyBankBranchNo_Lbl; CompanyInformation.FieldCaption("Bank Branch No."))
            {
            }
            column(CompanyBankName; CompanyInformation."Bank Name")
            {
            }
            column(CompanyBankName_Lbl; CompanyInfoBankNameCaptionLbl)
            {
            }
            column(CompanyCustomGiro; CustomGiroTxt)
            {
            }
            column(CompanyCustomGiro_Lbl; CustomGiroLbl)
            {
            }
            column(CompanyEMail; CompanyInformation."E-Mail")
            {
            }
            column(CompanyEmail_Lbl; EmailIDCaptionLbl)
            {
            }
            column(CompanyGiroNo; CompanyInformation."Giro No.")
            {
            }
            column(CompanyGiroNo_Lbl; CompanyInfoGiroNoCaptionLbl)
            {
            }
            column(CompanyHomePage; CompanyInformation."Home Page")
            {
            }
            column(CompanyHomePage_Lbl; HomePageCaptionLbl)
            {
            }
            column(CompanyIBAN; CompanyInformation.IBAN)
            {
            }
            column(CompanyIBAN_Lbl; CompanyInformation.FieldCaption(IBAN))
            {
            }
            column(CompanyLegalOffice; LegalOfficeTxt)
            {
            }
            column(CompanyLegalOffice_Lbl; LegalOfficeLbl)
            {
            }
            column(CompanyLogoPosition; CompanyLogoPosition)
            {
            }
            column(CompanyPhoneNo; CompanyInformation."Phone No.")
            {
            }
            column(CompanyPhoneNo_Lbl; CompanyInfoPhoneNoCaptionLbl)
            {
            }
            column(CompanyPicture; CompanyInformation.Picture)
            {
            }
            column(CompanyRegistrationNumber; CompanyInformation.GetRegistrationNumber())
            {
            }
            column(CompanyRegistrationNumber_Lbl; CompanyInformation.GetRegistrationNumberLbl())
            {
            }
            column(CompanySWIFT; CompanyInformation."SWIFT Code")
            {
            }
            column(CompanySWIFT_Lbl; CompanyInformation.FieldCaption("SWIFT Code"))
            {
            }
            column(CompanyVATRegistrationNo; CompanyInformation.GetVATRegistrationNumber())
            {
            }
            column(CompanyVATRegistrationNo_Lbl; CompanyInformation.GetVATRegistrationNumberLbl())
            {
            }
            column(CompanyVATRegNo; CompanyInformation.GetVATRegistrationNumber())
            {
            }
            column(CompanyVATRegNo_Lbl; CompanyInformation.GetVATRegistrationNumberLbl())
            {
            }
            column(ConfirmToCaption_Lbl; ConfirmToCaptionLbl)
            {
            }
            column(ContinuedCaptionLbl; ContinuedCaptionLbl)
            { }
            column(DimText; DimText)
            {
            }
            column(DocType_PurchHeader; "Document Type")
            {
            }
            column(DocumentDate; Format("Document Date", 0, 4))
            {
            }
            column(DocumentDate_Lbl; DocumentDateCaptionLbl)
            {
            }
            column(DocumentTitle_Lbl; DocumentTitleLbl)
            {
            }
            column(DueDate; Format("Due Date", 0, 4))
            {
            }
            column(EmailID_Lbl; EmailIDCaptionLbl)
            {
            }
            column(ExptRecptDt_PurchaseHeader; Format("Expected Receipt Date", 0, 4))
            {
            }
            column(SubcAddrInfoLine; AddrInfoLine)
            {
            }
            column(SubcAmountCaptionLbl; SubAmountCaptionLbl)
            {
            }
            column(SubcBarcodeBase; TempCompanyInformation.Picture)
            {
            }
            column(SubcCompanyAddress1; CompanyAddress1Footer)
            {
            }
            column(SubcCompanyAddress2; CompanyAddress2Footer)
            {
            }
            column(SubcCompanyAddress3; CompanyAddress3Footer)
            {
            }
            column(SubcCompanyAddress4; CompanyAddress4Footer)
            {
            }
            column(SubcCompanyBankName; CompanyInfoBankNameFooter)
            {
            }
            column(SubcCompanyBankName_Lbl; CompanyInfoBankNameLblFooter)
            {
            }
            column(SubcCompanyEMail; CompanyInfoEmailFooter)
            {
            }
            column(SubcCompanyHomePage; CompanyInfoHomepageFooter)
            {
            }
            column(SubcCompanyIBAN; CompanyInfoIBANFooter)
            {
            }
            column(SubcCompanyIBAN_Lbl; CompanyInfoIBANLblFooter)
            {
            }
            column(SubcCompanyInfo1Picture; CompanyInformation1.Picture)
            {
            }
            column(SubcCompanyInfo2Picture; CompanyInformation2.Picture)
            {
            }
            column(SubcCompanyInfoCourtLocation; CompanyInfoCourtLocationFooter)
            {
            }
            column(SubcCompanyInfoExecutiveDirector1; CompanyInfoExecutiveDirector1Footer)
            {
            }
            column(SubcCompanyInfoExecutiveDirector2; CompanyInfoExecutiveDirector2Footer)
            {
            }
            column(SubcCompanyInfoExecutiveDirector3; CompanyInfoExecutiveDirector3Footer)
            {
            }
            column(SubcCompanyInfoExecutiveDirector4; CompanyInfoExecutiveDirector4Footer)
            {
            }
            column(SubcCompanyInfoFaxLbl; CompanyInfoFaxNoLblFooter)
            {
            }
            column(SubcCompanyInfoFaxNo; CompanyInfoFaxNoFooter)
            {
            }
            column(SubcCompanyInfoPhoneNoLbl; CompanyInfoPhoneNoLblFooter)
            {
            }
            column(SubcCompanyInfoPicture; SubCompanyInformation.Picture)
            {
            }
            column(SubcCompanyInfoRegisterCourtNo; CompanyInfoRegisterCourtNoFooter)
            {
            }
            column(SubcCompanyPhoneNo; CompanyInfoPhoneNoFooter)
            {
            }
            column(SubcCompanyPhoneNo_Lbl; CompanyInfoPhoneNoLblFooter)
            {
            }
            column(SubcCompanySWIFT; CompanyInfoSWIFTFooter)
            {
            }
            column(SubcCompanySWIFT_Lbl; CompanyInfoSWIFTLblFooter)
            {
            }
            column(SubcCompanyVATRegistrationNo; CompanyVATRegNoFooter)
            {
            }
            column(SubcCompanyVATRegistrationNo_Lbl; CompanyVATRegNoLblFooter)
            {
            }
            column(SubcCompanyVATRegNo_Lbl; CompanyVATRegNoLblFooter)
            {
            }
            column(SubcCourtLocationLbl; CourtLocationLblFooter)
            {
            }
            column(SubcDocCaptionLbl; DocCaptionLbl)
            {
            }
            column(SubcDocumentDate; Format("Document Date", 0, HeaderDateFormatExpression))
            {
            }
            column(SubcDocumentDateLbl; DocumentDateLbl)
            {
            }
            column(SubcDueDate; Format("Due Date", 0, HeaderDateFormatExpression))
            {
            }
            column(SubcEMail_Lbl; CompanyInfoEMailAddressLblFooter)
            {
            }
            column(SubcExecutiveDirectorsLbl; ExecutiveDirectorsLblFooter)
            {
            }
            column(SubcExternalDocumentNoCaptionLbl; ExternalDocumentNoCaptionLbl)
            {
            }
            column(SubcFooterMark; FooterMark)
            {
            }
            column(SubcHeaderMark; HeaderMark)
            {
            }
            column(SubcHeaderPhoneNo; HeaderPhoneNo)
            {
            }
            column(SubcHeaderPhoneNoLbl; CompanyInfoPhoneNoCaptionLbl)
            {
            }
            column(SubcHomePage_Lbl; CompanyInfoHomepageLblFooter)
            {
            }
            column(SubcInvDiscAmount; InvDiscAmount)
            {
            }
            column(SubcInvDiscAmtCaptionLbl; InvDiscAmtCaptionLbl)
            {
            }
            column(SubcOfForPageLbl; OfForPageLbl)
            {
            }
            column(SubcOrder_Date; Format("Order Date", 0, HeaderDateFormatExpression))
            {
            }
            column(SubcOrderNoCaptionLbl; SubOrderNoCaptionLbl)
            {
            }
            column(SubcPageLbl; SubcPageLbl)
            {
            }
            column(SubcPaymentTermsDescriptionLbl; PaymentTermsDescriptionTxt)
            {
            }
            column(SubcPrintAddressLine; PrintAddressLine)
            {
            }
            column(SubcPrintBarCode; PrintBarCode)
            {
            }
            column(SubcPrintFooterLine; PrintFooterLine)
            {
            }
            column(SubcPromisedDeliveryDateLbl; PromisedDeliveryDateLbl)
            {
            }
            column(SubcPurchDocNum; "No.")
            {
            }
            column(SubcPurchDocNumLbl; PurchOrderNumCaptionLbl)
            {
            }
            column(SubcRegisterCourtNoLbl; RegisterCourtLblFooter)
            {
            }
            column(SubcSalesLineLineDiscountLbl; SalesLineLineDiscountLbl)
            {
            }
            column(SubcSalesperson; SalespersonPurchaser.Name)
            {
            }
            column(SubcSalesPersonEmail; SalespersonPurchaser."E-Mail")
            {
            }
            column(SubcSalespersonLbl; SalespersonLbl)
            {
            }
            column(SubcSalesPersonPurchaserEmailLbl; SalesPersonPurchaserEmailLbl)
            {
            }
            column(SubcSellToCustomerNoCaptionLbl; SellToCustomerNoCaption)
            {
            }
            column(SubcSellToCustomerNoShipToAddr; SellToCustomerNoShipToAddr)
            {
            }
            column(SubcSeperator2Lbl; Seperator2Lbl)
            {
            }
            column(SubcSeperator3Lbl; Seperator3Lbl)
            {
            }
            column(SubcSeperatorLbl; SeperatorLbl)
            {
            }
            column(SubcShipToAddressCaptionLbl; ShipToAddressCaption)
            {
            }
            column(SubcShptMethodDesc; ShipmentMethod.Description)
            {
            }
            column(SubcShptMethodDescLbl; ShptMethodDescTxt)
            {
            }
            column(SubcTotalAmountInclVAT; Format(TotalAmountInclVAT, 0, DecimalAmountFormatExpression))
            {
            }
            column(SubcTotalText; SubTotalText)
            {
            }
            column(SubcUnit_PriceCaptionLbl; Unit_PriceCaptionLbl)
            {
            }
            column(SubcUnitOfMeasureLbl; UnitOfMeasureLbl)
            {
            }
            column(SubcVATAmount; Format(SubVATAmount, 0, DecimalAmountFormatExpression))
            {
            }
            column(SubcVATAmountSpecificationCaptionLbl; VATAmountSpecificationCaptionLbl)
            {
            }
            column(SubcVATBaseAmount; Format(SubVATBaseAmount, 0, DecimalAmountFormatExpression))
            {
            }
            column(SubcVATClauseCaptionLbl; VATClauseCaptionLbl)
            {
            }
            column(SubcVATDiscountAmount; Format(SubVATDiscountAmount, 0, DecimalAmountFormatExpression))
            {
            }
            column(SubcVATNo; "VAT Registration No.")
            {
            }
            column(SubcVATNoLbl; VATNoLbl)
            {
            }
            column(SubcVendorNo; "Buy-from Vendor No.")
            {
            }
            column(SubcVendorNoLbl; VendorNoLbl)
            {
            }
            column(SubcYourReferenceLbl; YourReferenceLbl)
            {
            }
            column(HomePage_Lbl; HomePageCaptionLbl)
            {
            }
            column(ItemDescription_Lbl; ItemDescriptionCaptionLbl)
            {
            }
            column(ItemLineAmount_Lbl; ItemLineAmountCaptionLbl)
            {
            }
            column(ItemNumber_Lbl; ItemNumberCaptionLbl)
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
            column(No_PurchHeader; "No.")
            {
            }
            column(OrderDate_Lbl; OrderDateLbl)
            {
            }
            column(OrderDate_PurchaseHeader; Format("Order Date", 0, 4))
            {
            }
            column(OrderDatenLbl; OrderDatenLbl)
            { }
            column(OrderNo_Lbl; OrderNoCaptionLbl)
            {
            }
            column(OutputNo; OutputNo)
            {
            }
            column(OutstandingLbl; OutstandingLbl)
            { }
            column(Page_Lbl; PageCaptionLbl)
            {
            }
            column(PageLbl; PageLbl)
            { }
            column(PaymentDetails_Lbl; PaymentDetailsCaptionLbl)
            {
            }
            column(PaymentTermsDesc_Lbl; PaymentTermsDescCaptionLbl)
            {
            }
            column(PayToContactEmail; PayToContact."E-Mail")
            {
            }
            column(PayToContactEmailLbl; PayToContactEmailLbl)
            {
            }
            column(PayToContactMobilePhoneNo; PayToContact."Mobile Phone No.")
            {
            }
            column(PayToContactMobilePhoneNoLbl; PayToContactMobilePhoneNoLbl)
            {
            }
            column(PayToContactPhoneNo; PayToContact."Phone No.")
            {
            }
            column(PayToContactPhoneNoLbl; PayToContactPhoneNoLbl)
            {
            }
            column(PayToVendNo_PurchHeader; "Pay-to Vendor No.")
            {
            }
            column(PrepmtPaymentTermsDesc; PrepmtPaymentTerms.Description)
            {
            }
            column(PrepymtTermsDesc_Lbl; PrepymtTermsDescCaptionLbl)
            {
            }
            column(PricesIncludingVAT_Lbl; PricesIncludingVATCaptionLbl)
            {
            }
            column(PricesInclVAT_PurchHeader; "Prices Including VAT")
            {
            }
            column(PricesInclVAT_PurchHeader_Lbl; FieldCaption("Prices Including VAT"))
            {
            }
            column(PricesInclVATtxt; PricesInclVATtxtLbl)
            {
            }
            column(PurchaserText; PurchaserText)
            {
            }
            column(PurchLineInvDiscAmt_Lbl; PurchLineInvDiscAmtCaptionLbl)
            {
            }
            column(PurchOrderCaption_Lbl; PurchOrderCaptionLbl)
            {
            }
            column(PurchOrderDateCaption_Lbl; PurchOrderDateCaptionLbl)
            {
            }
            column(PurchOrderNumCaption_Lbl; PurchOrderNumCaptionLbl)
            {
            }
            column(Receiveby_Lbl; ReceivebyCaptionLbl)
            {
            }
            column(ReferenceText; ReferenceText)
            {
            }
            column(SalesPurchPersonName; SalespersonPurchaser.Name)
            {
            }
            column(SellToCustNo_PurchHeader; "Sell-to Customer No.")
            {
            }
            column(SellToCustNo_PurchHeader_Lbl; FieldCaption("Sell-to Customer No."))
            {
            }
            column(ShipmentMethodDesc; ShipmentMethod.Description)
            {
            }
            column(ShipmentMethodDesc_Lbl; ShipmentMethodDescCaptionLbl)
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
            column(SubcontractorDispatchListLbl; SubcontractorDispatchListLbl)
            { }
            column(SubcontractorLbl; SubcontractorLbl)
            { }
            column(SubcOrdNoLbl; SubcOrdNoLbl)
            { }
            column(Subtotal_Lbl; SubtotalCaptionLbl)
            {
            }
            column(TaxIdentTypeCaption_Lbl; TaxIdentTypeCaptionLbl)
            {
            }
            column(ToCaption_Lbl; ToCaptionLbl)
            {
            }
            column(Total_Lbl; TotalCaptionLbl)
            {
            }
            column(VALVATBaseLCY_Lbl; VALVATBaseLCYCaptionLbl)
            {
            }
            column(VATAmtLineInvDiscBaseAmt_Lbl; VATAmtLineInvDiscBaseAmtCaptionLbl)
            {
            }
            column(VATAmtLineLineAmt_Lbl; VATAmtLineLineAmtCaptionLbl)
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
            column(VATBaseDisc_PurchHeader; "VAT Base Discount %")
            {
            }
            column(VATIdentifier_Lbl; VATIdentifierCaptionLbl)
            {
            }
            column(VATNoText; VATNoText)
            {
            }
            column(VATRegNo_PurchHeader; "VAT Registration No.")
            {
            }
            column(VendAddr1; VendAddr[1])
            {
            }
            column(VendAddr2; VendAddr[2])
            {
            }
            column(VendAddr3; VendAddr[3])
            {
            }
            column(VendAddr4; VendAddr[4])
            {
            }
            column(VendAddr5; VendAddr[5])
            {
            }
            column(VendAddr6; VendAddr[6])
            {
            }
            column(VendAddr7; VendAddr[7])
            {
            }
            column(VendAddr8; VendAddr[8])
            {
            }
            column(VendNo_Lbl; VendNoCaptionLbl)
            {
            }
            column(Vendor__Subcontracting_Location_Code_; Vendor."Subcontr. Location Code")
            {
            }
            column(Vendor__Subcontracting_Location_Code_Caption; Vendor.FieldCaption("Subcontr. Location Code"))
            {
            }
            column(VendorIDCaption_Lbl; VendorIDCaptionLbl)
            {
            }
            column(VendorInvoiceNo; "Vendor Invoice No.")
            {
            }
            column(VendorInvoiceNo_Lbl; VendorInvoiceNoLbl)
            {
            }
            column(VendorOrderNo; "Vendor Order No.")
            {
            }
            column(VendorOrderNo_Lbl; VendorOrderNoLbl)
            {
            }
            column(YourRef_PurchHeader; "Your Reference")
            {
            }
            dataitem("Purchase Line"; "Purchase Line")
            {
                DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                DataItemTableView = sorting("Document Type", "Document No.", "Line No.") where("Prod. Order No." = filter(<> ''));
                column(AllowInvDisc_PurchLine; "Allow Invoice Disc.")
                {
                }
                column(AllowInvDisctxt; AllowInvDisctxt)
                {
                }
                column(AmountIncludingVAT; "Amount Including VAT")
                {
                }
                column(Desc_PurchLine; Description)
                {
                }
                column(Desc_PurchLine_Lbl; FieldCaption(Description))
                {
                }
                column(DirectUniCost_Lbl; DirectUniCostCaptionLbl)
                {
                }
                column(DirUnitCost_PurchLine; FormattedDirectUnitCost)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 2;
                }
                column(ExpectedReceiptDate; Format("Expected Receipt Date", 0, 4))
                {
                }
                column(ExpectedReceiptDateLbl; ExpectedReceiptDateLbl)
                {
                }
                column(SubcDescriptionCaption; "Purchase Line".FieldCaption(Description))
                {
                }
                column(SubcExpectedReceiptDate; Format("Expected Receipt Date", 0, LineDateFormatExpression))
                {
                }
                column(SubcLineDescription2; "Purchase Line"."Description 2")
                {
                }
                column(SubcLineDisc; LineDiscountPctText)
                {
                }
                column(SubcLineMark; LineMark)
                {
                }
                column(SubcNoCaption; "Purchase Line".FieldCaption("No."))
                {
                }
                column(SubcPosNoText; PosNoText)
                {
                }
                column(SubcPUoM; PricingUoMCode)
                {
                }
                column(SubcPurchQty; "Purchase Line".Quantity)
                {
                }
                column(SubcPUS; PriceUnit)
                {
                }
                column(SubcQuantityCaption; "Purchase Line".FieldCaption(Quantity))
                {
                }
                column(SubcSalesLineLineAmount; LineAmount)
                {
                }
                column(SubcUnitCost; UnitCost)
                {
                }
                column(InvDiscAmt_PurchLine; -"Inv. Discount Amount")
                {
                    AutoFormatExpression = "Currency Code";
                    AutoFormatType = 1;
                }
                column(InvDiscCaption_Lbl; InvDiscCaptionLbl)
                {
                }
                column(ItemNo_PurchLine; "No.")
                {
                }
                column(ItemReferenceNo_PurchLine; "Item Reference No.")
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
                column(LineAmt_PurchLine; FormattedLineAmount)
                {
                }
                column(LineDisc_PurchLine; "Line Discount %")
                {
                }
                column(LineNo_PurchLine; "Line No.")
                {
                }
                column(No_PurchLine; ItemNo)
                {
                }
                column(No_PurchLine_Lbl; FieldCaption("No."))
                {
                }
                column(PlannedReceiptDate; Format("Planned Receipt Date", 0, 4))
                {
                }
                column(PlannedReceiptDateLbl; PlannedReceiptDateLbl)
                {
                }
                column(PromisedReceiptDate; Format("Promised Receipt Date", 0, 4))
                {
                }
                column(PromisedReceiptDateLbl; PromisedReceiptDateLbl)
                {
                }
                column(Purchase_Line_Operation_No_; "Purchase Line"."Subc. Operation No.")
                {
                }
                column(Purchase_Line_Outstanding_Qty; "Purchase Line"."Outstanding Quantity")
                { }
                column(Purchase_Line_Prod__Order_Line_No_; "Purchase Line"."Subc. Prod. Order Line No.")
                {
                }
                column(Purchase_Line_Prod__Order_No_; "Purchase Line"."Subc. Prod. Order No.")
                {
                }
                column(Purchase_Line_Routing_No_; "Purchase Line"."Subc. Routing No.")
                {
                }
                column(Purchase_Line_Routing_Reference_No_; "Purchase Line"."Subc. Rtng Reference No.")
                {
                }
                column(PurchLineLineDisc_Lbl; PurchLineLineDiscCaptionLbl)
                {
                }
                column(Qty_PurchLine; FormattedQuanitity)
                {
                }
                column(Qty_PurchLine_Lbl; FieldCaption(Quantity))
                {
                }
                column(RequestedReceiptDate; Format("Requested Receipt Date", 0, 4))
                {
                }
                column(RequestedReceiptDateLbl; RequestedReceiptDateLbl)
                {
                }
                column(TotalInclVAT; "Line Amount" - "Inv. Discount Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalPriceCaption_Lbl; TotalPriceCaptionLbl)
                {
                }
                column(Type_PurchLine; Format(Type, 0, 2))
                {
                }
                column(UnitPrice_PurchLine; "Unit Price (LCY)")
                {
                }
                column(UnitPrice_PurchLine_Lbl; UnitPriceLbl)
                {
                }
                column(UOM_PurchLine; "Unit of Measure")
                {
                }
                column(UOM_PurchLine_Lbl; ItemUnitOfMeasureCaptionLbl)
                {
                }
                column(VATDiscountAmount_Lbl; VATDiscountAmountCaptionLbl)
                {
                }
                column(VATIdentifier_PurchLine; "VAT Identifier")
                {
                }
                column(VATIdentifier_PurchLine_Lbl; FieldCaption("VAT Identifier"))
                {
                }
                column(VendorItemNo_PurchLine; "Vendor Item No.")
                {
                }
                dataitem("Prod. Order Line"; "Prod. Order Line")
                {
                    DataItemLink = "Prod. Order No." = field("Prod. Order No."), "Line No." = field("Prod. Order Line No.");
                    DataItemTableView = sorting(Status, "Prod. Order No.", "Line No.") where(Status = const(Released));
                }
                dataitem("Prod. Order Routing Line"; "Prod. Order Routing Line")
                {
                    DataItemLink = "Prod. Order No." = field("Prod. Order No."), "Routing No." = field("Routing No."), "Routing Reference No." = field("Routing Reference No."), "Operation No." = field("Operation No.");
                    DataItemTableView = sorting(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.") where(Status = const(Released));
                    column(ComponentsToShipLbl; ComponentsToShipLbl)
                    { }
                    column(EndingDateLbl; EndingDateLbl)
                    { }
                    column(ItemLbl; ItemLbl)
                    { }
                    column(Prod__Order_Line___Item_No__; "Prod. Order Line"."Item No.")
                    {
                    }
                    column(Prod__Order_Line___Quantity__Base__; "Prod. Order Line"."Quantity (Base)")
                    {
                    }
                    column(Prod__Order_Line___Remaining_Quantity_; Format("Prod. Order Line"."Remaining Quantity"))
                    {
                    }
                    column(Prod__Order_Line___Unit_of_Measure_Code_; "Prod. Order Line"."Unit of Measure Code")
                    {
                    }
                    column(Prod__Order_Line__Quantity; Format("Prod. Order Line".Quantity))
                    {
                    }
                    column(Prod__Order_Routing_Line__Ending_Date_; Format("Ending Date", 0, 4))
                    {
                    }
                    column(Prod__Order_Routing_Line__Operation_No__; "Operation No.")
                    {
                    }
                    column(Prod__Order_Routing_Line__Operation_No__Caption; FieldCaption("Operation No."))
                    {
                    }
                    column(Prod__Order_Routing_Line__Prod__Order_No__; "Prod. Order No.")
                    {
                    }
                    column(Prod__Order_Routing_Line__Starting_Date_; Format("Starting Date", 0, 4))
                    {
                    }
                    column(Prod__Order_Routing_Line_Description; Description)
                    {
                    }
                    column(Prod__Order_Routing_Line_Description_Control1130538; Description)
                    {
                    }
                    column(Prod__Order_Routing_Line_Routing_Link_Code; "Routing Link Code")
                    {
                    }
                    column(Prod__Order_Routing_Line_Routing_No_; "Routing No.")
                    {
                    }
                    column(Prod__Order_Routing_Line_Routing_Reference_No_; "Routing Reference No.")
                    {
                    }
                    column(Prod__Order_Routing_Line_Status; Status)
                    {
                    }
                    column(ProdOrderLbl; ProdOrderLbl)
                    { }
                    column(QtyToShipLbl; QtyToShipLbl)
                    { }
                    column(QuantityBaseLbl; QuantityBaseLbl)
                    { }
                    column(QuantityLbl; QuantityLbl)
                    { }
                    column(RemainingQuantityLbl; RemainingQuantityLbl)
                    { }
                    column(StartingDateLbl; StartingDateLbl)
                    { }
                    column(UoMLbl; UoMLbl)
                    { }
                    dataitem("Prod. Order Component"; "Prod. Order Component")
                    {
                        DataItemLink = Status = field(Status), "Prod. Order No." = field("Prod. Order No."), "Prod. Order Line No." = field("Routing Reference No."), "Routing Link Code" = field("Routing Link Code");
                        DataItemTableView = sorting(Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.");
                        column(Expected_Qty___Base______Qty__transf__to_Subcontractor______Qty__in_Transit__Base__; "Expected Qty. (Base)" - "Qty. transf. to Subcontr" - "Qty. in Transit (Base)")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(Prod__Order_Component__Expected_Qty___Base__; "Expected Qty. (Base)")
                        {
                        }
                        column(Prod__Order_Component__Expected_Qty___Base__Caption; FieldCaption("Expected Qty. (Base)"))
                        {
                        }
                        column(Prod__Order_Component__Item_No__; "Item No.")
                        {
                        }
                        column(Prod__Order_Component__Qty__in_Transit__Base__; "Qty. in Transit (Base)")
                        {
                        }
                        column(Prod__Order_Component__Qty__in_Transit__Base__Caption; FieldCaption("Qty. in Transit (Base)"))
                        {
                        }
                        column(Prod__Order_Component__Qty__transf__to_Subcontractor_; "Qty. transf. to Subcontr")
                        {
                        }
                        column(Prod__Order_Component__Qty__transf__to_Subcontractor_Caption; FieldCaption("Qty. transf. to Subcontr"))
                        {
                        }
                        column(Prod__Order_Component_Description; Description)
                        {
                        }
                        column(Prod__Order_Component_Line_No_; "Line No.")
                        {
                        }
                        column(Prod__Order_Component_Prod__Order_Line_No_; "Prod. Order Line No.")
                        {
                        }
                        column(Prod__Order_Component_Prod__Order_No_; "Prod. Order No.")
                        {
                        }
                        column(Prod__Order_Component_Routing_Link_Code; "Routing Link Code")
                        {
                        }
                        column(Prod__Order_Component_Status; Status)
                        {
                        }
                        trigger OnPreDataItem()
                        begin
                            SetRange("Purchase Order Filter", "Purchase Header"."No.");
                        end;
                    }
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

                    BlankZero("Purchase Line");
                end;
            }
            dataitem(Totals; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(SubcTotalAmountIncludingVAT; TotalAmountIncludingVATTxt)
                {
                }
                column(SubcTotalInvoiceDiscountAmount; Format(VATDiscountAmount, 0, DecimalAmountFormatExpression))
                {
                }
                column(SubcTotalNetAmount; Format(TotalAmount, 0, DecimalAmountFormatExpression))
                {
                }
                column(SubcTotalSubTotal; Format(TotalSubTotal, 0, DecimalAmountFormatExpression))
                {
                }
                column(SubcTotalVATAmount; Format(VATAmount, 0, DecimalAmountFormatExpression))
                {
                }
                column(SubcTotalVATBaseLCY; Format(VATBaseAmount, 0, DecimalAmountFormatExpression))
                {
                }
                column(TotalAmount; TotalAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalAmountInclVAT; TotalAmountInclVAT)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalExclVATText; TotalExclVATText)
                {
                }
                column(TotalInclVATText; TotalInclVATText)
                {
                }
                column(TotalInvoiceDiscountAmount; TotalInvoiceDiscountAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalSubTotal; TotalSubTotal)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalText; TotalText)
                {
                }
                column(TotalVATAmount; VATAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalVATBaseAmount; VATBaseAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalVATDiscountAmount; -VATDiscountAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmountText; TempVATAmountLine.VATAmountText())
                {
                }
                trigger OnAfterGetRecord()
                var
                    TempPrepmtPurchaseLine: Record "Purchase Line" temporary;
                begin
                    Clear(TempPurchaseLine);
                    Clear(PurchPost);
                    if not TempPurchaseLine.IsEmpty() then
                        TempPurchaseLine.DeleteAll();
                    if not TempVATAmountLine.IsEmpty() then
                        TempVATAmountLine.DeleteAll();
                    PurchPost.GetPurchLines("Purchase Header", TempPurchaseLine, 0);
                    TempPurchaseLine.CalcVATAmountLines(0, "Purchase Header", TempPurchaseLine, TempVATAmountLine);
                    TempPurchaseLine.UpdateVATOnLines(0, "Purchase Header", TempPurchaseLine, TempVATAmountLine);
                    VATAmount := TempVATAmountLine.GetTotalVATAmount();
                    VATBaseAmount := TempVATAmountLine.GetTotalVATBase();
                    VATDiscountAmount :=
                      TempVATAmountLine.GetTotalVATDiscount("Purchase Header"."Currency Code", "Purchase Header"."Prices Including VAT");
                    TotalAmountInclVAT := TempVATAmountLine.GetTotalAmountInclVAT();

                    if not TempPrepaymentInvLineBuffer.IsEmpty() then
                        TempPrepaymentInvLineBuffer.DeleteAll();
                    PurchasePostPrepayments.GetPurchLines("Purchase Header", 0, TempPurchaseLine);
                    if not TempPrepmtPurchaseLine.IsEmpty() then begin
                        PurchasePostPrepayments.GetPurchLinesToDeduct("Purchase Header", TempPurchaseLine);
                        if not TempPurchaseLine.IsEmpty() then
                            PurchasePostPrepayments.CalcVATAmountLines("Purchase Header", TempPurchaseLine, TempPrePmtVATAmountLineDeduct, 1);
                    end;
                    PurchasePostPrepayments.CalcVATAmountLines("Purchase Header", TempPrepmtPurchaseLine, TempPrepmtVATAmountLine, 0);
                    TempPrepmtVATAmountLine.DeductVATAmountLine(TempPrePmtVATAmountLineDeduct);
                    PurchasePostPrepayments.UpdateVATOnLines("Purchase Header", TempPrepmtPurchaseLine, TempPrepmtVATAmountLine, 0);
                    PurchasePostPrepayments.BuildInvLineBuffer("Purchase Header", TempPrepmtPurchaseLine, 0, TempPrepaymentInvLineBuffer);
                    PrepmtVATAmount := TempPrepmtVATAmountLine.GetTotalVATAmount();
                    PrepmtVATBaseAmount := TempPrepmtVATAmountLine.GetTotalVATBase();
                    PrepmtTotalAmountInclVAT := TempPrepmtVATAmountLine.GetTotalAmountInclVAT();

                    if TotalAmount <> TotalAmountInclVAT then begin
                        TotalAmountIncludingVATTxt := Format(TotalAmountInclVAT, 0, DecimalAmountFormatExpression);
                        SubFormatDocument.SetTotalLabels("Purchase Header"."Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
                    end else begin
                        TotalAmountIncludingVATTxt := '';
                        TotalInclVATText := '';
                    end;
                end;
            }
            dataitem(VATCounter; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(VATAmtLineInvDiscAmt; TempVATAmountLine."Invoice Discount Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineInvDiscBaseAmt; TempVATAmountLine."Inv. Disc. Base Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineLineAmt; TempVATAmountLine."Line Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineVAT; TempVATAmountLine."VAT %")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(VATAmtLineVATAmt; TempVATAmountLine."VAT Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(VATAmtLineVATBase; TempVATAmountLine."VAT Base")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
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
                        VALSpecLCYHeader := VATAmountSpecificationLbl + LocalCurrencyLbl
                    else
                        VALSpecLCYHeader := VATAmountSpecificationLbl + Format(GLSetup."LCY Code");

                    CurrencyExchangeRate.FindCurrency("Purchase Header"."Posting Date", "Purchase Header"."Currency Code", 1);
                    VALExchRate := StrSubstNo(ExchangeRateLbl, CurrencyExchangeRate."Relational Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
                end;
            }
            dataitem(PrepmtLoop; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                column(PrepaymentSpecCaption; PrepaymentSpecCaptionLbl)
                {
                }
                column(PrepmtInvBuDescCaption; PrepmtInvBuDescCaptionLbl)
                {
                }
                column(PrepmtInvBufAmt; TempPrepaymentInvLineBuffer.Amount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtInvBufDesc; TempPrepaymentInvLineBuffer.Description)
                {
                }
                column(PrepmtInvBufGLAccNo; TempPrepaymentInvLineBuffer."G/L Account No.")
                {
                }
                column(PrepmtInvBufGLAccNoCaption; PrepmtInvBufGLAccNoCaptionLbl)
                {
                }
                column(PrepmtLineAmount; PrepmtLineAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtTotalAmountInclVAT; PrepmtTotalAmountInclVAT)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtVATAmount; PrepmtVATAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtVATAmountText; TempPrepmtVATAmountLine.VATAmountText())
                {
                }
                column(PrepmtVATBaseAmount; PrepmtVATBaseAmount)
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(TotalExclVATText2; TotalExclVATText)
                {
                }
                column(TotalInclVATText2; TotalInclVATText)
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
                column(PrepmtVATAmtLineLineAmt; TempPrepmtVATAmountLine."Line Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(PrepmtVATAmtLineVAT; TempPrepmtVATAmountLine."VAT %")
                {
                    DecimalPlaces = 0 : 5;
                }
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
                column(BodyText; BodyLbl)
                {
                }
                column(ClosingText; ClosingLbl)
                {
                }
                column(GreetingText; GreetingLbl)
                {
                }
            }
            dataitem(SubcVATAmountLine; "VAT Amount Line")
            {
                DataItemTableView = sorting("VAT Identifier", "VAT Calculation Type", "Tax Group Code", "Use Tax", Positive);
                UseTemporary = true;
                column(SubcInvoiceDiscountAmount_VATAmountLine; "Invoice Discount Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(SubcInvoiceDiscountAmount_VATAmountLine_Lbl; FieldCaption("Invoice Discount Amount"))
                {
                }
                column(SubcInvoiceDiscountBaseAmount_VATAmountLine; "Inv. Disc. Base Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(SubcInvoiceDiscountBaseAmount_VATAmountLine_Lbl; FieldCaption("Inv. Disc. Base Amount"))
                {
                }
                column(SubcLineAmount_VatAmountLine; "Line Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(SubcLineAmount_VatAmountLine_Lbl; FieldCaption("Line Amount"))
                {
                }
                column(SubcNoOfVATIdentifiers; Count)
                {
                }
                column(SubcOfLbl; OfLbl)
                {
                }
                column(SubcTotalExclVATText; SubTotalExclVATText)
                {
                }
                column(SubcTotalInclVATText; SubTotalInclVATText)
                {
                }
                column(SubcVATAmount_VatAmountLine; "VAT Amount")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(SubcVATAmount_VatAmountLine_Lbl; FieldCaption("VAT Amount"))
                {
                }
                column(SubcVATBase_VatAmountLine; "VAT Base")
                {
                    AutoFormatExpression = "Purchase Header"."Currency Code";
                    AutoFormatType = 1;
                }
                column(SubcVATBase_VatAmountLine_Lbl; FieldCaption("VAT Base"))
                {
                }
                column(SubcVATClause2Description; VATClause2.Description)
                {
                }
                column(SubcVATClause2Description2; VATClause2."Description 2")
                {
                }
                column(SubcVATIdentifier_VatAmountLine; "VAT Identifier")
                {
                }
                column(SubcVATIdentifier_VatAmountLine_Lbl; FieldCaption("VAT Identifier"))
                {
                }
                column(SubcVATPct_VatAmountLine; "VAT %")
                {
                    DecimalPlaces = 0 : 5;
                }
                column(SubcVATPct_VatAmountLine_Lbl; FieldCaption("VAT %"))
                {
                }
                column(SubcVATPercentCaptionLbl; VATPercentCaptionLbl)
                {
                }
            }
            trigger OnAfterGetRecord()
            begin
                TotalAmount := 0;
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                FormatAddress.SetLanguageCode("Language Code");

                FormatAddressFields("Purchase Header");
                FormatDocumentFields("Purchase Header");
                if BuyFromContact.Get("Buy-from Contact No.") then;
                if PayToContact.Get("Pay-to Contact No.") then;

                if not IsReportInPreviewMode() then begin
                    Codeunit.Run(Codeunit::"Purch.Header-Printed", "Purchase Header");
                    if ShouldArchiveDocument then
                        ArchiveManagement.StorePurchDocument("Purchase Header", ShouldLogInteraction);
                end;

                SubFormatAddress.PurchHeaderShipTo(ShipToAddr, "Purchase Header");

                if not SubcVATAmountLine.IsEmpty() then
                    SubcVATAmountLine.DeleteAll();
                "Purchase Line".CalcVATAmountLines(0, "Purchase Header", "Purchase Line", SubcVATAmountLine);
                "Purchase Line".UpdateVATOnLines(0, "Purchase Header", "Purchase Line", SubcVATAmountLine);
                ShowShippingAddr := ("Purchase Header"."Buy-from Vendor No." <> "Purchase Header"."Sell-to Customer No.");
                if not ShowShippingAddr then
                    Clear(ShipToAddr);

                SetTotalLabels("Currency Code", SubTotalText);
                SetInvDisAmountLbl("Currency Code", InvDiscAmtCaptionLbl);

                FormatFooter();

                SubVATAmount := SubcVATAmountLine.GetTotalVATAmount();
                SubVATBaseAmount := SubcVATAmountLine.GetTotalVATBase();
                SubVATDiscountAmount := SubcVATAmountLine.GetTotalVATDiscount("Purchase Header"."Currency Code", "Purchase Header"."Prices Including VAT");

                SetLabels();

                Vendor.Get("Purchase Header"."Buy-from Vendor No.");
            end;
        }
        dataitem(SubcShipToAddr; Integer)
        {
            DataItemTableView = sorting(Number);
            column(TempSUBShipToAddr__Address; TempShiptoAddress.Address)
            {
            }
            trigger OnPreDataItem()
            begin
                SetRange(Number, 1, TempShiptoAddress.Count);
            end;

            trigger OnAfterGetRecord()
            begin
                if Number = 1 then
                    TempShiptoAddress.Find('-')
                else
                    TempShiptoAddress.Next();
            end;
        }
    }
    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ArchiveDocument; ShouldArchiveDocument)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Archive Document';
                        ToolTip = 'Specifies whether to archive the order.';
                        Visible = false;
                    }
                    field(LogInteraction; ShouldLogInteraction)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Log Interaction';
                        Enabled = LogInteractionEnable;
                        ToolTip = 'Specifies if you want to log this interaction.';
                    }
                    field(SubcPrintAddressLine; PrintAddressLine)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Show Address Line';
                        ToolTip = 'Specifies if the address line is shown.';
                    }
                    field(SubcPrintFooterLine; PrintFooterLine)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Show Footer Line';
                        ToolTip = 'Specifies if the footer line is shown.';
                    }
                    field(SubcPrintBarCode; PrintBarCode)
                    {
                        ApplicationArea = Manufacturing;
                        Caption = 'Show Bar Code';
                        ToolTip = 'Specifies if the Barcode is shown.';
                    }
                }
            }
        }
        trigger OnInit()
        begin
            LogInteractionEnable := true;
            ShouldArchiveDocument := PurchasesPayablesSetup."Archive Orders";
        end;

        trigger OnOpenPage()
        begin
            LogInteractionEnable := ShouldLogInteraction;
        end;
    }
    trigger OnInitReport()
    begin
        GLSetup.Get();
        CompanyInformation.Get();
        PurchasesPayablesSetup.Get();
        CompanyInformation.CalcFields(Picture);

        SalesReceivablesSetup.Get();
        SubFormatDocument.SetLogoPosition(SalesReceivablesSetup."Logo Position on Documents", CompanyInformation1, CompanyInformation2, SubCompanyInformation);
    end;

    trigger OnPostReport()
    begin
        if ShouldLogInteraction and not IsReportInPreviewMode() then
            if "Purchase Header".FindSet() then
                repeat
                    SegManagement.LogDocument(
                      13, "Purchase Header"."No.", 0, 0, Database::Vendor, "Purchase Header"."Buy-from Vendor No.",
                      "Purchase Header"."Purchaser Code", '', "Purchase Header"."Posting Description", '');
                until "Purchase Header".Next() = 0;
    end;

    trigger OnPreReport()
    begin
        if not CurrReport.UseRequestPage then
            InitLogInteraction();
    end;

    var
        CompanyInformation: Record "Company Information";
        SubCompanyInformation: Record "Company Information";
        CompanyInformation1: Record "Company Information";
        CompanyInformation2: Record "Company Information";
        TempCompanyInformation: Record "Company Information" temporary;
        BuyFromContact: Record Contact;
        PayToContact: Record Contact;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GLSetup: Record "General Ledger Setup";
        PaymentTerms: Record "Payment Terms";
        PrepmtPaymentTerms: Record "Payment Terms";
        TempPrepaymentInvLineBuffer: Record "Prepayment Inv. Line Buffer" temporary;
        TempPurchaseLine: Record "Purchase Line" temporary;
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        ResponsibilityCenter: Record "Responsibility Center";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        TempShiptoAddress: Record "Ship-to Address" temporary;
        ShipmentMethod: Record "Shipment Method";
        TempPrepmtVATAmountLine: Record "VAT Amount Line" temporary;
        TempPrePmtVATAmountLineDeduct: Record "VAT Amount Line" temporary;
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        VATClause2: Record "VAT Clause";
        Vendor: Record Vendor;
        ArchiveManagement: Codeunit ArchiveManagement;
        SubFormatAddress: Codeunit "Format Address";
        FormatAddress: Codeunit "Format Address";
        SubFormatDocument: Codeunit "Format Document";
        FormatDocument: Codeunit "Format Document";
        LanguageMgt: Codeunit Language;
        PurchPost: Codeunit "Purch.-Post";
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        SegManagement: Codeunit SegManagement;
        ShouldArchiveDocument: Boolean;
        PrintAddressLine: Boolean;
        PrintBarCode: Boolean;
        PrintFooterLine: Boolean;
        PrintPaymentTerms: Boolean;
        ShowShippingAddr: Boolean;
        ShouldLogInteraction: Boolean;
        LogInteractionEnable: Boolean;
        VATAmount, VATBaseAmount, VATDiscountAmount : Decimal;
        PrepmtLineAmount: Decimal;
        PrepmtTotalAmountInclVAT: Decimal;
        PrepmtVATAmount: Decimal;
        PrepmtVATBaseAmount: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalInvoiceDiscountAmount: Decimal;
        TotalSubTotal: Decimal;
        VALVATAmountLCY: Decimal;
        VALVATBaseLCY: Decimal;
        SubVATAmount: Decimal;
        SubVATBaseAmount: Decimal;
        SubVATDiscountAmount: Decimal;
        CompanyLogoPosition: Integer;
        OutputNo: Integer;
        AllowInvoiceDiscCaptionLbl: Label 'Allow Invoice Discount';
        AmountCaptionLbl: Label 'Amount';
        BodyLbl: Label 'The purchase order is attached to this message.';
        BuyerCaptionLbl: Label 'Buyer';
        BuyFromContactEmailLbl: Label 'Buy-from Contact E-Mail';
        BuyFromContactMobilePhoneNoLbl: Label 'Buy-from Contact Mobile Phone No.';
        BuyFromContactPhoneNoLbl: Label 'Buy-from Contact Phone No.';
        ClosingLbl: Label 'Sincerely';
        CompanyInfoBankAccNoCaptionLbl: Label 'Account No.';
        CompanyInfoBankNameCaptionLbl: Label 'Bank';
        CompanyInfoGiroNoCaptionLbl: Label 'Giro No.';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        ComponentsToShipLbl: Label 'Components to ship';
        ConfirmToCaptionLbl: Label 'Confirm To';
        ContinuedCaptionLbl: Label 'Continued';
        DirectUniCostCaptionLbl: Label 'Direct Unit Cost';
        DocumentDateCaptionLbl: Label 'Document Date';
        DocumentTitleLbl: Label 'Purchase Order';
        EmailIDCaptionLbl: Label 'Email';
        EndingDateLbl: Label 'Ending Date';
        ExchangeRateLbl: Label 'Exchange rate: %1/%2', Comment = '%1=Currency Code, %2=Currency Code';
        ExpectedReceiptDateLbl: Label 'Expected Receipt Date';
        SubAmountCaptionLbl: Label 'Amount';
        CompanyInfoBankNameLbl: Label 'Bank';
        CompanyInfoFaxLbl: Label 'Fax No.';
        CompanyInfoPhoneNoLbl: Label 'Phone No.';
        CourtLocationLbl: Label 'Court Location: ';
        DocCaptionLbl: Label 'Subcontractor - Dispatch List';
        DocumentDateLbl: Label 'Document Date';
        EMailLbl: Label 'Email';
        ExternalDocumentNoCaptionLbl: Label 'Ext. Doc. No.';
        HomePageLbl: Label 'Home Page';
        OfForPageLbl: Label 'of';
        OfLbl: Label 'of';
        SubOrderNoCaptionLbl: Label 'Order No.';
        PageLbl: Label 'Page';
        PaymentTermsDescriptionLbl: Label 'Payment Terms:';
        PromisedDeliveryDateLbl: Label 'Deliv. Date';
        RegisterCourtNoLbl: Label 'Register Court: ';
        SalesLineLineDiscountLbl: Label 'Discount %';
        SalespersonLbl: Label 'Purchaser';
        SalesPersonPurchaserEmailLbl: Label 'E-Mail';
        ShptMethodDescLbl: Label 'Shipment Method:';
        Unit_PriceCaptionLbl: Label 'Unit Price';
        UnitOfMeasureLbl: Label 'Unit of Measure';
        VATAmountSpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATClauseCaptionLbl: Label 'VAT Clause';
        VATNoLbl: Label 'VAT Registration No.';
        VATPercentCaptionLbl: Label '% VAT';
        VendorNoLbl: Label 'Vendor No.';
        YourReferenceLbl: Label 'Your Reference';
        GreetingLbl: Label 'Hello';
        HomePageCaptionLbl: Label 'Home Page';
        InvDiscCaptionLbl: Label 'Invoice Discount:';
        ItemDescriptionCaptionLbl: Label 'Description';
        ItemLbl: Label 'Item';
        ItemLineAmountCaptionLbl: Label 'Line Amount';
        ItemNumberCaptionLbl: Label 'Item No.';
        ItemQuantityCaptionLbl: Label 'Quantity';
        ItemUnitCaptionLbl: Label 'Unit';
        ItemUnitOfMeasureCaptionLbl: Label 'Unit';
        ItemUnitPriceCaptionLbl: Label 'Unit Price';
        JobNoLbl: Label 'Job No.';
        JobTaskNoLbl: Label 'Job Task No.';
        LocalCurrencyLbl: Label 'Local Currency';
        OrderDateLbl: Label 'Order Date';
        OrderDatenLbl: Label 'Order Date';
        OrderNoCaptionLbl: Label 'Order No.';
        OutstandingLbl: Label 'Outstanding';
        PageCaptionLbl: Label 'Page';
        SubcPageLbl: Label 'Page';
        PaymentDetailsCaptionLbl: Label 'Payment Details';
        PaymentTermsDescCaptionLbl: Label 'Payment Terms';
        PayToContactEmailLbl: Label 'Pay-to Contact E-Mail';
        PayToContactMobilePhoneNoLbl: Label 'Pay-to Contact Mobile Phone No.';
        PayToContactPhoneNoLbl: Label 'Pay-to Contact Phone No.';
        PlannedReceiptDateLbl: Label 'Planned Receipt Date';
        PrepaymentSpecCaptionLbl: Label 'Prepayment Specification';
        PrepmtInvBuDescCaptionLbl: Label 'Description';
        PrepmtInvBufGLAccNoCaptionLbl: Label 'G/L Account No.';
        PrepymtTermsDescCaptionLbl: Label 'Prepmt. Payment Terms';
        PrepymtVATAmtSpecCaptionLbl: Label 'Prepayment VAT Amount Specification';
        PricesIncludingVATCaptionLbl: Label 'Prices Including VAT';
        PricesInclVATtxtLbl: Label 'Prices Including VAT';
        ProdOrderLbl: Label 'Prod. Order:';
        PromisedReceiptDateLbl: Label 'Promised Receipt Date';
        PurchLineInvDiscAmtCaptionLbl: Label 'Invoice Discount Amount';
        PurchLineLineDiscCaptionLbl: Label 'Discount %';
        PurchOrderCaptionLbl: Label 'PURCHASE ORDER';
        PurchOrderDateCaptionLbl: Label 'Purchase Order Date:';
        PurchOrderNumCaptionLbl: Label 'Order No.';
        QtyToShipLbl: Label 'Qty to ship';
        QuantityBaseLbl: Label 'Quantity (Base)';
        QuantityLbl: Label 'Quantity';
        ReceivebyCaptionLbl: Label 'Receive By';
        RemainingQuantityLbl: Label 'Remaining Qty';
        RequestedReceiptDateLbl: Label 'Requested Receipt Date';
        ShipmentMethodDescCaptionLbl: Label 'Shipment Method';
        ShiptoAddressCaptionLbl: Label 'Ship-to Address';
        StartingDateLbl: Label 'Starting Date';
        SubcontractorDispatchListLbl: Label 'Subcontractor Dispatch List';
        SubcontractorLbl: Label 'Subcontractor';
        SubcOrdNoLbl: Label 'Subc. Ord. No.';
        SubtotalCaptionLbl: Label 'Subtotal';
        TaxIdentTypeCaptionLbl: Label 'Tax Ident. Type';
        ToCaptionLbl: Label 'To:';
        TotalCaptionLbl: Label 'Total';
        TotalPriceCaptionLbl: Label 'Total Price';
        UnitPriceLbl: Label 'Unit Price (LCY)';
        UoMLbl: Label 'UoM';
        VALVATBaseLCYCaptionLbl: Label 'VAT Base';
        VATAmountSpecificationLbl: Label 'VAT Amount Specification in ';
        VATAmtLineInvDiscBaseAmtCaptionLbl: Label 'Invoice Discount Base Amount';
        VATAmtLineLineAmtCaptionLbl: Label 'Line Amount';
        VATAmtLineVATAmtCaptionLbl: Label 'VAT Amount';
        VATAmtLineVATCaptionLbl: Label 'VAT %';
        VATAmtSpecCaptionLbl: Label 'VAT Amount Specification';
        VATDiscountAmountCaptionLbl: Label 'Payment Discount on VAT';
        VATIdentifierCaptionLbl: Label 'VAT Identifier';
        VendNoCaptionLbl: Label 'Vendor No.';
        VendorIDCaptionLbl: Label 'Vendor ID';
        VendorInvoiceNoLbl: Label 'Vendor Invoice No.';
        VendorOrderNoLbl: Label 'Vendor Order No.';
        CustomGiroLbl, CustomGiroTxt, LegalOfficeLbl, LegalOfficeTxt : Text;
        FormattedDirectUnitCost: Text;
        FormattedLineAmount: Text;
        FormattedQuanitity: Text;
        FormattedVATPct: Text;
        AddrInfoLine: Text;
        CompanyInfoBankNameLblFooter, CompanyInfoIBANLblFooter, CompanyInfoSWIFTLblFooter : Text;
        CompanyInfoEMailAddressLblFooter, CompanyInfoFaxNoLblFooter, CompanyInfoHomepageLblFooter, CompanyInfoPhoneNoLblFooter : Text;
        CompanyVATRegNoFooter, CompanyVATRegNoLblFooter, SellToCustomerNoCaption, SellToCustomerNoShipToAddr, ShipToAddressCaption : Text;
        CourtLocationLblFooter, ExecutiveDirectorsLblFooter, RegisterCourtLblFooter : Text;
        DecimalAmountFormatExpression: Text;
        FooterMark: Text;
        HeaderDateFormatExpression: Text;
        HeaderMark: Text;
        InvDiscAmount: Text;
        LineAmount, PosNoText, UnitCost : Text;
        LineDateFormatExpression: Text;
        LineDiscountPctText: Text;
        LineMark: Text;
        PaymentTermsDescriptionTxt: Text;
        PriceUnit: Text;
        PricingUoMCode: Text;
        Seperator2Lbl, Seperator3Lbl, SeperatorLbl : Text;
        ShptMethodDescTxt: Text;
        TotalAmountIncludingVATTxt: Text;
        ItemNo: Text;
        CompanyInfoSWIFTFooter: Text[20];
        AllowInvDisctxt: Text[30];
        CompanyInfoCourtLocationFooter, CompanyInfoFaxNoFooter, CompanyInfoPhoneNoFooter, CompanyInfoRegisterCourtNoFooter : Text[30];
        HeaderPhoneNo: Text[30];

        CompanyInfoIBANFooter: Text[50];
        InvDiscAmtCaptionLbl: Text[50];
        SubTotalExclVATText, SubTotalInclVATText, SubTotalText : Text[50];
        PurchaserText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        TotalText: Text[50];
        VALExchRate: Text[50];
        CompanyInfoEmailFooter: Text[80];
        CompanyInfoExecutiveDirector1Footer, CompanyInfoExecutiveDirector2Footer, CompanyInfoExecutiveDirector3Footer, CompanyInfoExecutiveDirector4Footer : Text[80];
        ReferenceText: Text[80];
        VALSpecLCYHeader: Text[80];
        VATNoText: Text[80];
        BuyFromAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        CompanyAddress1Footer, CompanyAddress2Footer, CompanyAddress3Footer, CompanyAddress4Footer : Text[100];
        CompanyInfoBankNameFooter: Text[100];
        ShipToAddr: array[8] of Text[100];
        VendAddr: array[8] of Text[100];
        DimText: Text[120];
        CompanyInfoHomepageFooter: Text[255];

    procedure InitializeRequest(LogInteractionParam: Boolean)
    begin
        ShouldLogInteraction := LogInteractionParam;
    end;

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var PurchaseHeader: Record "Purchase Header")
    begin
        FormatAddress.GetCompanyAddr(PurchaseHeader."Responsibility Center", ResponsibilityCenter, CompanyInformation, CompanyAddr);
        FormatAddress.PurchHeaderBuyFrom(BuyFromAddr, PurchaseHeader);
        if PurchaseHeader."Buy-from Vendor No." <> PurchaseHeader."Pay-to Vendor No." then
            FormatAddress.PurchHeaderPayTo(VendAddr, PurchaseHeader);
        FormatAddress.PurchHeaderShipTo(ShipToAddr, PurchaseHeader);
    end;

    local procedure FormatDocumentFields(PurchaseHeader: Record "Purchase Header")
    begin
        FormatDocument.SetTotalLabels(PurchaseHeader."Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
        FormatDocument.SetPurchaser(SalespersonPurchaser, PurchaseHeader."Purchaser Code", PurchaserText);
        FormatDocument.SetPaymentTerms(PaymentTerms, PurchaseHeader."Payment Terms Code", PurchaseHeader."Language Code");
        FormatDocument.SetPaymentTerms(PrepmtPaymentTerms, PurchaseHeader."Prepmt. Payment Terms Code", PurchaseHeader."Language Code");
        FormatDocument.SetShipmentMethod(ShipmentMethod, PurchaseHeader."Shipment Method Code", PurchaseHeader."Language Code");

        ReferenceText := CopyStr(FormatDocument.SetText(PurchaseHeader."Your Reference" <> '', CopyStr(PurchaseHeader.FieldCaption("Your Reference"), 1, 80)), 1, MaxStrLen(ReferenceText));
        VATNoText := CopyStr(FormatDocument.SetText(PurchaseHeader."VAT Registration No." <> '', CopyStr(PurchaseHeader.FieldCaption("VAT Registration No."), 1, 80)), 1, MaxStrLen(VATNoText));
    end;

    local procedure InitLogInteraction()
    begin
        ShouldLogInteraction := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Purch. Ord.") <> '';
    end;

    local procedure BlankZero(PurchaseLine: Record "Purchase Line")
    var
        LineDiscountPctPlaceholderLbl: Label '%1%',
            Locked = true;
    begin
        if PurchaseLine."Line Discount %" = 0 then
            LineDiscountPctText := ''
        else
            LineDiscountPctText := StrSubstNo(LineDiscountPctPlaceholderLbl, Round(PurchaseLine."Line Discount %", 0.1));

        if PurchaseLine."Line Amount" = 0 then
            LineAmount := ''
        else
            LineAmount := Format(PurchaseLine."Line Amount", 0, DecimalAmountFormatExpression);

        if PurchaseLine."Unit Cost" = 0 then
            UnitCost := ''
        else
            UnitCost := FormattedDirectUnitCost;
    end;

    local procedure FormatFooter()
    begin
        if PrintFooterLine then begin
            CompanyAddress1Footer := CompanyAddr[1];
            CompanyAddress2Footer := CompanyAddr[2];
            CompanyAddress3Footer := CompanyAddr[3];
            CompanyAddress4Footer := CompanyAddr[4];

            CompanyInfoPhoneNoLblFooter := CompanyInfoPhoneNoLbl;
            CompanyInfoFaxNoLblFooter := CompanyInfoFaxLbl;
            CompanyInfoEMailAddressLblFooter := EMailLbl;
            CompanyInfoHomepageLblFooter := HomePageLbl;
            CompanyVATRegNoLblFooter := CompanyInformation.GetVATRegistrationNumberLbl();

            CompanyInfoPhoneNoFooter := CompanyInformation."Phone No.";
            CompanyInfoFaxNoFooter := CompanyInformation."Fax No.";
            CompanyInfoEmailFooter := CompanyInformation."E-Mail";
            CompanyVATRegNoFooter := CompanyInformation.GetVATRegistrationNumber();

            CourtLocationLblFooter := CourtLocationLbl;
            RegisterCourtLblFooter := RegisterCourtNoLbl;

            CompanyInfoBankNameLblFooter := CompanyInfoBankNameLbl;
            CompanyInfoIBANLblFooter := CompanyInformation.FieldCaption(IBAN);
            CompanyInfoSWIFTLblFooter := CompanyInformation.FieldCaption("SWIFT Code");

            CompanyInfoBankNameFooter := CompanyInformation."Bank Name";
            CompanyInfoIBANFooter := CompanyInformation.IBAN;
            CompanyInfoSWIFTFooter := CompanyInformation."SWIFT Code";
        end;
    end;

    local procedure SetInvDisAmountLbl(CurrencyCode: Code[10]; var SubInvDiscAmtCaptionLbl: Text[50])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        InvDiscAmtCapLbl: Label 'Invoice Discount Amount %1', Comment = '%1=Currency Code';
    begin
        if CurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetup.TestField("LCY Code");
            SubInvDiscAmtCaptionLbl := StrSubstNo(InvDiscAmtCapLbl, GeneralLedgerSetup."LCY Code");
        end else
            SubInvDiscAmtCaptionLbl := StrSubstNo(InvDiscAmtCapLbl, CurrencyCode);
    end;

    local procedure SetTotalLabels(CurrencyCode: Code[10]; var TotalAsText: Text[50])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalTxt: Label 'Net Amount %1', Comment = '%1=Currency Code';
    begin
        if CurrencyCode = '' then begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetup.TestField("LCY Code");
            TotalAsText := StrSubstNo(TotalTxt, GeneralLedgerSetup."LCY Code");
        end else
            TotalAsText := StrSubstNo(TotalTxt, CurrencyCode);
    end;

    local procedure SetLabels()
    begin
        if "Purchase Header"."Invoice Discount Value" = 0 then begin
            InvDiscAmount := '';
            InvDiscAmtCaptionLbl := '';
        end else
            InvDiscAmount := Format("Purchase Header"."Invoice Discount Value", 0, DecimalAmountFormatExpression);

        if ("Purchase Header"."Payment Terms Code" = '') or (not PrintPaymentTerms) then
            PaymentTermsDescriptionTxt := ''
        else
            PaymentTermsDescriptionTxt := PaymentTermsDescriptionLbl;

        if "Purchase Header"."Shipment Method Code" = '' then
            ShptMethodDescTxt := ''
        else
            ShptMethodDescTxt := ShptMethodDescLbl;
    end;
}