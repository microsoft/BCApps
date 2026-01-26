// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Archive;

using Microsoft.Bank.BankAccount;
using Microsoft.CRM.Team;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Document;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using System.Email;
using System.Globalization;
using System.Utilities;

report 418 "Arch. Sales Return Order"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Archive/ArchSalesReturnOrder.rdlc';
    Caption = 'Arch. Sales Return Order';
    WordMergeDataItem = "Sales Header Archive";

    dataset
    {
        dataitem("Sales Header Archive"; "Sales Header Archive")
        {
            DataItemTableView = sorting("Document Type", "No.", "Doc. No. Occurrence", "Version No.") where("Document Type" = const("Return Order"));
            RequestFilterFields = "No.", "Sell-to Customer No.", "No. Printed", "Version No.";
            RequestFilterHeading = 'Archived Sales Order';
            column(No_SalesHeaderArchive; "No.")
            {
            }
            column(VersionNo_SalesHeaderArchive; "Version No.")
            {
            }
            column(AllowInvoiceCaption; AllowInvoiceCaptionLbl)
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyInfo2Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(CompanyInfo3Picture; CompanyInfo3.Picture)
                    {
                    }
                    column(CompanyInfo1Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(SalesReturnOrderArchivedCopyText; StrSubstNo(Text004, CopyText))
                    {
                    }
                    column(CustAddr1; CustAddr[1])
                    {
                    }
                    column(CompanyAddr1; CompanyAddr[1])
                    {
                    }
                    column(CustAddr2; CustAddr[2])
                    {
                    }
                    column(CompanyAddr2; CompanyAddr[2])
                    {
                    }
                    column(CustAddr3; CustAddr[3])
                    {
                    }
                    column(CompanyAddr3; CompanyAddr[3])
                    {
                    }
                    column(CustAddr4; CustAddr[4])
                    {
                    }
                    column(CompanyAddr4; CompanyAddr[4])
                    {
                    }
                    column(CustAddr5; CustAddr[5])
                    {
                    }
                    column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
                    {
                    }
                    column(CustAddr6; CustAddr[6])
                    {
                    }
                    column(CompanyInfoEmail; CompanyInfo."E-Mail")
                    {
                    }
                    column(CompanyInfoHomePage; CompanyInfo."Home Page")
                    {
                    }
                    column(CompanyInfoVATRegNo; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
                    {
                    }
                    column(CompanyInfoBankName; CompanyBankAccount.Name)
                    {
                    }
                    column(CompanyInfoBankAccNo; CompanyBankAccount."Bank Account No.")
                    {
                    }
                    column(BilltoCustNo_SalesHeaderArchive; "Sales Header Archive"."Bill-to Customer No.")
                    {
                    }
                    column(BilltoCustNo_SalesHeaderArchiveCaption; "Sales Header Archive".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(SalesHeaderArchiveDocDate; Format("Sales Header Archive"."Document Date", 0, 4))
                    {
                    }
                    column(PaymentTermsDesc; PaymentTerms.Description)
                    {
                    }
                    column(ShipmentMethodDes; ShipmentMethod.Description)
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(VATRegNo_SalesHeaderArchive; "Sales Header Archive"."VAT Registration No.")
                    {
                    }
                    column(ShipmentDate_SalesHeaderArchive; Format("Sales Header Archive"."Shipment Date"))
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPersonName; SalesPurchPerson.Name)
                    {
                    }
                    column(No1_SalesHeaderArchive; "Sales Header Archive"."No.")
                    {
                    }
                    column(RefText; ReferenceText)
                    {
                    }
                    column(YourReference_SalesHeaderArchive; "Sales Header Archive"."Your Reference")
                    {
                    }
                    column(CustAddr7; CustAddr[7])
                    {
                    }
                    column(CustAddr8; CustAddr[8])
                    {
                    }
                    column(CompanyAddr5; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr6; CompanyAddr[6])
                    {
                    }
                    column(CompanyAddr7; CompanyAddr[7])
                    {
                    }
                    column(CompanyAddr8; CompanyAddr[8])
                    {
                    }
                    column(PricesIncVAT_SalesHeaderArchive; "Sales Header Archive"."Prices Including VAT")
                    {
                    }
                    column(PricesIncVAT_SalesHeaderArchiveCaption; "Sales Header Archive".FieldCaption("Prices Including VAT"))
                    {
                    }
                    column(SalesHdrArchNoArchVer; StrSubstNo(Text010, "Sales Header Archive"."Version No.", "Sales Header Archive"."No. of Archived Versions"))
                    {
                    }
                    column(PageCaption; StrSubstNo(Text005, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(PricesInclVATYesNo_SalesHeaderArchive; Format("Sales Header Archive"."Prices Including VAT"))
                    {
                    }
                    column(PhoneNoCaption; PhoneNoCaptionLbl)
                    {
                    }
                    column(VATRegNoCaption; VATRegNoCaptionLbl)
                    {
                    }
                    column(GiroNoCaption; GiroNoCaptionLbl)
                    {
                    }
                    column(BankNameCaption; BankNameCaptionLbl)
                    {
                    }
                    column(BankAccNoCaption; BankAccNoCaptionLbl)
                    {
                    }
                    column(ShipmentDateCaption; ShipmentDateCaptionLbl)
                    {
                    }
                    column(OrderNoCaption; OrderNoCaptionLbl)
                    {
                    }
                    column(PaymentTermsCaption; PaymentTermsCaptionLbl)
                    {
                    }
                    column(ShipmentMethodCaption; ShipmentMethodCaptionLbl)
                    {
                    }
                    column(HomePageCaption; HomePageCaptionLbl)
                    {
                    }
                    column(EmailCaption; EmailCaptionLbl)
                    {
                    }
                    column(DocumentDateCaption; DocumentDateCaptionLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Sales Header Archive";
                        DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                        column(DimText; DimText)
                        {
                        }
                        column(Number_IntegerLine; DimensionLoop1.Number)
                        {
                        }
                        column(HeaderDimCaption; HeaderDimCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then begin
                                if not DimSetEntry1.FindSet() then
                                    CurrReport.Break();
                            end else
                                if not Continue then
                                    CurrReport.Break();

                            Clear(DimText);
                            Continue := false;
                            repeat
                                OldDimText := DimText;
                                if DimText = '' then
                                    DimText := StrSubstNo('%1 %2', DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code")
                                else
                                    DimText :=
                                      StrSubstNo(
                                        '%1, %2 %3', DimText,
                                        DimSetEntry1."Dimension Code", DimSetEntry1."Dimension Value Code");
                                if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                    DimText := OldDimText;
                                    Continue := true;
                                    exit;
                                end;
                            until DimSetEntry1.Next() = 0;
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                        end;
                    }
                    dataitem("Sales Line Archive"; "Sales Line Archive")
                    {
                        DataItemLink = "Document Type" = field("Document Type"), "Document No." = field("No.");
                        DataItemLinkReference = "Sales Header Archive";
                        DataItemTableView = sorting("Document Type", "Document No.", "Line No.");

                        trigger OnPreDataItem()
                        begin
                            CurrReport.Break();
                        end;
                    }
                    dataitem(RoundLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(TypeInt; TypeInt)
                        {
                        }
                        column(SalesLineArchNo; SalesLineArchNo)
                        {
                        }
                        column(SalesLineArchLineNo; SalesLineArchLineNo)
                        {
                        }
                        column(SalesLineArchLineAmt; TempSalesLineArchive."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Description_SalesLineArchive; "Sales Line Archive".Description)
                        {
                        }
                        column(No_SalesLineArchive; "Sales Line Archive"."No.")
                        {
                        }
                        column(Quantity_SalesLineArchive; "Sales Line Archive".Quantity)
                        {
                        }
                        column(UOM_SalesLineArchive; "Sales Line Archive"."Unit of Measure")
                        {
                        }
                        column(No_SalesLineArchiveCaption; "Sales Line Archive".FieldCaption("No."))
                        {
                        }
                        column(Description_SalesLineArchiveCaption; "Sales Line Archive".FieldCaption(Description))
                        {
                        }
                        column(Quantity_SalesLineArchiveCaption; "Sales Line Archive".FieldCaption(Quantity))
                        {
                        }
                        column(UOM_SalesLineArchiveCaption; "Sales Line Archive".FieldCaption("Unit of Measure"))
                        {
                        }
                        column(UnitPrice_SalesLineArchive; "Sales Line Archive"."Unit Price")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 2;
                        }
                        column(Discount_SalesLineArchiveLine; "Sales Line Archive"."Line Discount %")
                        {
                        }
                        column(AllowInvDisc_SalesLineArchive; "Sales Line Archive"."Allow Invoice Disc.")
                        {
                        }
                        column(VATIdentifier_SalesLineArchive; "Sales Line Archive"."VAT Identifier")
                        {
                        }
                        column(VATIdentifier_SalesLineArchiveCaption; "Sales Line Archive".FieldCaption("VAT Identifier"))
                        {
                        }
                        column(AllowInvDisc_SalesLineArchiveCaption; "Sales Line Archive".FieldCaption("Allow Invoice Disc."))
                        {
                        }
                        column(AllowInvDiscYesNo_SalesLineArchive; Format("Sales Line Archive"."Allow Invoice Disc."))
                        {
                        }
                        column(SalesLineArchInvDiscAmt; -TempSalesLineArchive."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(AmtSalesLineArchInvDiscAmt; TempSalesLineArchive."Line Amount" - TempSalesLineArchive."Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(VATAmtLineText; TempVATAmountLine.VATAmountText())
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(VATAmount; VATAmount)
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATDiscountAmount; -VATDiscountAmount)
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATBaseDisc_SalesHeaderArchive; "Sales Header Archive"."VAT Base Discount %")
                        {
                        }
                        column(VATBaseAmount; VATBaseAmount)
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalAmountInclVAT; TotalAmountInclVAT)
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalSubTotal; TotalSubTotal)
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalInvDisAmt; TotalInvoiceDiscountAmount)
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalAmount; TotalAmount)
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(UnitPriceCaption; UnitPriceCaptionLbl)
                        {
                        }
                        column(DiscountCaption; DiscountCaptionLbl)
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(InvDiscountAmtCaption; InvDiscountAmtCaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(PaymentDiscCaption; PaymentDiscCaptionLbl)
                        {
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number) where(Number = filter(1 ..));
                            column(DimText1; DimText)
                            {
                            }
                            column(Number_IntegerLine1; DimensionLoop2.Number)
                            {
                            }
                            column(LineDimCaption; LineDimCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then begin
                                    if not DimSetEntry2.FindSet() then
                                        CurrReport.Break();
                                end else
                                    if not Continue then
                                        CurrReport.Break();

                                Clear(DimText);
                                Continue := false;
                                repeat
                                    OldDimText := DimText;
                                    if DimText = '' then
                                        DimText := StrSubstNo('%1 %2', DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code")
                                    else
                                        DimText :=
                                          StrSubstNo(
                                            '%1, %2 %3', DimText,
                                            DimSetEntry2."Dimension Code", DimSetEntry2."Dimension Value Code");
                                    if StrLen(DimText) > MaxStrLen(OldDimText) then begin
                                        DimText := OldDimText;
                                        Continue := true;
                                        exit;
                                    end;
                                until DimSetEntry2.Next() = 0;
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();

                                DimSetEntry2.SetRange("Dimension Set ID", "Sales Line Archive"."Dimension Set ID");
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            if Number = 1 then
                                TempSalesLineArchive.Find('-')
                            else
                                TempSalesLineArchive.Next();
                            "Sales Line Archive" := TempSalesLineArchive;

                            if not "Sales Header Archive"."Prices Including VAT" and
                               (TempSalesLineArchive."VAT Calculation Type" = TempSalesLineArchive."VAT Calculation Type"::"Full VAT")
                            then
                                TempSalesLineArchive."Line Amount" := 0;

                            if (TempSalesLineArchive.Type = TempSalesLineArchive.Type::"G/L Account") and (not ShowInternalInfo) then begin
                                SalesLineArchNo := "Sales Line Archive"."No.";
                                "Sales Line Archive"."No." := '';
                            end;

                            TypeInt := "Sales Line Archive".Type.AsInteger();
                            SalesLineArchLineNo := "Sales Line Archive"."Line No.";

                            TotalSubTotal += "Sales Line Archive"."Line Amount";
                            TotalInvoiceDiscountAmount -= "Sales Line Archive"."Inv. Discount Amount";
                            TotalAmount += "Sales Line Archive".Amount;
                        end;

                        trigger OnPostDataItem()
                        begin
                            TempSalesLineArchive.DeleteAll();
                        end;

                        trigger OnPreDataItem()
                        begin
                            MoreLines := TempSalesLineArchive.Find('+');
                            while MoreLines and (TempSalesLineArchive.Description = '') and (TempSalesLineArchive."Description 2" = '') and
                                  (TempSalesLineArchive."No." = '') and (TempSalesLineArchive.Quantity = 0) and
                                  (TempSalesLineArchive.Amount = 0)
                            do
                                MoreLines := TempSalesLineArchive.Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            TempSalesLineArchive.SetRange("Line No.", 0, TempSalesLineArchive."Line No.");
                            SetRange(Number, 1, TempSalesLineArchive.Count);
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATAmountLineVATBase; TempVATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount_; TempVATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineLineAmount; TempVATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineInvDiscBaseAmount; TempVATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineInvDisAmount; TempVATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Sales Header Archive"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLineVAT; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLine__VAT_Identifier_; TempVATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATPercentageCaption; VATPercentageCaptionLbl)
                        {
                        }
                        column(VATBaseCaption; VATBaseCaptionLbl)
                        {
                        }
                        column(VATAmountCaption; VATAmountCaptionLbl)
                        {
                        }
                        column(VATAmountSpecCaption; VATAmountSpecCaptionLbl)
                        {
                        }
                        column(InvDiscBaseAmtCaption; InvDiscBaseAmtCaptionLbl)
                        {
                        }
                        column(LineAmountCaption; LineAmountCaptionLbl)
                        {
                        }
                        column(InvoiceDisAmountCaption; InvoiceDisAmountCaptionLbl)
                        {
                        }
                        column(VATIdentifierCaption; VATIdentifierCaptionLbl)
                        {
                        }
                        column(TotalCaption; TotalCaptionLbl)
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
                        column(VALVATBaseLCY; VALVATBaseLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VALVATAmountLCY; VALVATAmountLCY)
                        {
                            AutoFormatType = 1;
                        }
                        column(VATAmtLineVAT1; TempVATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmtLineVATIdentifier1; TempVATAmountLine."VAT Identifier")
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            TempVATAmountLine.GetLine(Number);
                            VALVATBaseLCY :=
                              TempVATAmountLine.GetBaseLCY(
                                "Sales Header Archive"."Posting Date", "Sales Header Archive"."Currency Code",
                                "Sales Header Archive"."Currency Factor");
                            VALVATAmountLCY :=
                              TempVATAmountLine.GetAmountLCY(
                                "Sales Header Archive"."Posting Date", "Sales Header Archive"."Currency Code",
                                "Sales Header Archive"."Currency Factor");
                        end;

                        trigger OnPreDataItem()
                        begin
                            if (not GLSetup."Print VAT specification in LCY") or
                               ("Sales Header Archive"."Currency Code" = '') or
                               (TempVATAmountLine.GetTotalVATAmount() = 0)
                            then
                                CurrReport.Break();

                            SetRange(Number, 1, TempVATAmountLine.Count);
                            Clear(VALVATBaseLCY);
                            Clear(VALVATAmountLCY);

                            if GLSetup."LCY Code" = '' then
                                VALSpecLCYHeader := Text007 + Text008
                            else
                                VALSpecLCYHeader := Text007 + Format(GLSetup."LCY Code");

                            CurrExchRate.FindCurrency("Sales Header Archive"."Posting Date", "Sales Header Archive"."Currency Code", 1);
                            VALExchRate := StrSubstNo(Text009, CurrExchRate."Relational Exch. Rate Amount", CurrExchRate."Exchange Rate Amount");
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(SelltoCustNo_SalesHeaderArchive; "Sales Header Archive"."Sell-to Customer No.")
                        {
                        }
                        column(SelltoCustNo_SalesHeaderArchiveCaption; "Sales Header Archive".FieldCaption("Sell-to Customer No."))
                        {
                        }
                        column(ShipToAddr8; ShipToAddr[8])
                        {
                        }
                        column(ShipToAddr7; ShipToAddr[7])
                        {
                        }
                        column(ShipToAddr6; ShipToAddr[6])
                        {
                        }
                        column(ShipToAddr5; ShipToAddr[5])
                        {
                        }
                        column(ShipToAddr4; ShipToAddr[4])
                        {
                        }
                        column(ShipToAddr3; ShipToAddr[3])
                        {
                        }
                        column(ShipToAddr2; ShipToAddr[2])
                        {
                        }
                        column(ShipToAddr1; ShipToAddr[1])
                        {
                        }
                        column(ShowShippingAddr; ShowShippingAddr)
                        {
                        }
                        column(ShiptoAddressCaption; ShiptoAddressCaptionLbl)
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                var
                    TempSalesHeader: Record "Sales Header" temporary;
                    TempSalesLine: Record "Sales Line" temporary;
                begin
                    InitTempLines(TempSalesHeader, TempSalesLine);

                    VATAmount := TempVATAmountLine.GetTotalVATAmount();
                    VATBaseAmount := TempVATAmountLine.GetTotalVATBase();
                    VATDiscountAmount :=
                      TempVATAmountLine.GetTotalVATDiscount(TempSalesHeader."Currency Code", TempSalesHeader."Prices Including VAT");
                    TotalAmountInclVAT := TempVATAmountLine.GetTotalAmountInclVAT();

                    if Number > 1 then begin
                        CopyText := FormatDocument.GetCOPYText();
                        OutputNo += 1;
                    end;

                    TotalSubTotal := 0;
                    TotalInvoiceDiscountAmount := 0;
                    TotalAmount := 0;
                end;

                trigger OnPostDataItem()
                begin
                    if not IsReportInPreviewMode() then
                        CODEUNIT.Run(CODEUNIT::"SalesCount-PrintedArch", "Sales Header Archive");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);
                    OutputNo := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");
                FormatAddr.SetLanguageCode("Language Code");

                FormatAddressFields("Sales Header Archive");
                FormatDocumentFields("Sales Header Archive");

                if not CompanyBankAccount.Get("Sales Header Archive"."Company Bank Account Code") then
                    CompanyBankAccount.CopyBankFieldsFromCompanyInfo(CompanyInfo);

                DimSetEntry1.SetRange("Dimension Set ID", "Dimension Set ID");

                if "Shipment Method Code" = '' then
                    ShipmentMethod.Init()
                else begin
                    ShipmentMethod.Get("Shipment Method Code");
                    ShipmentMethod.TranslateDescription(ShipmentMethod, "Language Code");
                end;

                CalcFields("No. of Archived Versions");
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
                    field(NoOfCopies; NoOfCopies)
                    {
                        ApplicationArea = Suite;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies how many copies of the document to print.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
        CompanyInfo.Get();
        SalesSetup.Get();

        case SalesSetup."Logo Position on Documents" of
            SalesSetup."Logo Position on Documents"::"No Logo":
                ;
            SalesSetup."Logo Position on Documents"::Left:
                begin
                    CompanyInfo3.Get();
                    CompanyInfo3.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            SalesSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ShipmentMethod: Record "Shipment Method";
        PaymentTerms: Record "Payment Terms";
        PrepmtPaymentTerms: Record "Payment Terms";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyBankAccount: Record "Bank Account";
        CompanyInfo3: Record "Company Information";
        SalesSetup: Record "Sales & Receivables Setup";
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        TempSalesLineArchive: Record "Sales Line Archive" temporary;
        DimSetEntry1: Record "Dimension Set Entry";
        DimSetEntry2: Record "Dimension Set Entry";
        RespCenter: Record "Responsibility Center";
        CurrExchRate: Record "Currency Exchange Rate";
        LanguageMgt: Codeunit Language;
        FormatAddr: Codeunit "Format Address";
        FormatDocument: Codeunit "Format Document";
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        SalesPersonText: Text[50];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        CopyText: Text[30];
        ShowShippingAddr: Boolean;
        DimText: Text[120];
        OldDimText: Text[75];
        ShowInternalInfo: Boolean;
        Continue: Boolean;
        VATAmount: Decimal;
        VATBaseAmount: Decimal;
        VATDiscountAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        VALVATBaseLCY: Decimal;
        VALVATAmountLCY: Decimal;
        VALSpecLCYHeader: Text[80];
        VALExchRate: Text[50];
        OutputNo: Integer;
        TypeInt: Integer;
        SalesLineArchLineNo: Integer;
        SalesLineArchNo: Code[20];
        TotalSubTotal: Decimal;
        TotalAmount: Decimal;
        TotalInvoiceDiscountAmount: Decimal;
#pragma warning disable AA0074
        Text004: Label 'Sales Return Order Archived %1', Comment = '%1 = Document No.';
#pragma warning disable AA0470
        Text005: Label 'Page %1';
#pragma warning restore AA0470
        Text007: Label 'VAT Amount Specification in ';
        Text008: Label 'Local Currency';
#pragma warning disable AA0470
        Text009: Label 'Exchange rate: %1/%2';
        Text010: Label 'Version %1 of %2 ';
#pragma warning restore AA0470
#pragma warning restore AA0074
        PhoneNoCaptionLbl: Label 'Phone No.';
        VATRegNoCaptionLbl: Label 'VAT Registration No.';
        GiroNoCaptionLbl: Label 'Giro No.';
        BankNameCaptionLbl: Label 'Bank';
        BankAccNoCaptionLbl: Label 'Account No.';
        ShipmentDateCaptionLbl: Label 'Shipment Date';
        OrderNoCaptionLbl: Label 'Order No.';
        PaymentTermsCaptionLbl: Label 'Payment Terms';
        ShipmentMethodCaptionLbl: Label 'Shipment Method';
        HomePageCaptionLbl: Label 'Home Page';
        EmailCaptionLbl: Label 'E-Mail';
        DocumentDateCaptionLbl: Label 'Document Date';
        HeaderDimCaptionLbl: Label 'Header Dimensions';
        UnitPriceCaptionLbl: Label 'Unit Price';
        DiscountCaptionLbl: Label 'Discount %';
        AmountCaptionLbl: Label 'Amount';
        InvDiscountAmtCaptionLbl: Label 'Invoice Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        PaymentDiscCaptionLbl: Label 'Payment Discount on VAT';
        LineDimCaptionLbl: Label 'Line Dimensions';
        VATPercentageCaptionLbl: Label 'VAT %';
        VATBaseCaptionLbl: Label 'VAT Base';
        VATAmountCaptionLbl: Label 'VAT Amount';
        VATAmountSpecCaptionLbl: Label 'VAT Amount Specification';
        InvDiscBaseAmtCaptionLbl: Label 'Invoice Discount Base Amount';
        LineAmountCaptionLbl: Label 'Line Amount';
        InvoiceDisAmountCaptionLbl: Label 'Invoice Discount Amount';
        VATIdentifierCaptionLbl: Label 'VAT Identifier';
        TotalCaptionLbl: Label 'Total';
        ShiptoAddressCaptionLbl: Label 'Ship-to Address';
        AllowInvoiceCaptionLbl: Label 'Allow Invoice Discount';

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";

    local procedure IsReportInPreviewMode(): Boolean
    var
        MailManagement: Codeunit "Mail Management";
    begin
        exit(CurrReport.Preview or MailManagement.IsHandlingGetEmailBody());
    end;

    local procedure FormatAddressFields(var SalesHeaderArchive: Record "Sales Header Archive")
    begin
        FormatAddr.GetCompanyAddr(SalesHeaderArchive."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        FormatAddr.SalesHeaderArchBillTo(CustAddr, SalesHeaderArchive);
        FormatAddr.SalesHeaderArchShipTo(ShipToAddr, CustAddr, SalesHeaderArchive);
    end;

    local procedure FormatDocumentFields(SalesHeaderArchive: Record "Sales Header Archive")
    begin
        FormatDocument.SetTotalLabels(SalesHeaderArchive."Currency Code", TotalText, TotalInclVATText, TotalExclVATText);
        FormatDocument.SetSalesPerson(SalesPurchPerson, SalesHeaderArchive."Salesperson Code", SalesPersonText);
        FormatDocument.SetPaymentTerms(PaymentTerms, SalesHeaderArchive."Payment Terms Code", SalesHeaderArchive."Language Code");
        FormatDocument.SetPaymentTerms(PrepmtPaymentTerms, SalesHeaderArchive."Prepmt. Payment Terms Code", SalesHeaderArchive."Language Code");
        FormatDocument.SetShipmentMethod(ShipmentMethod, SalesHeaderArchive."Shipment Method Code", SalesHeaderArchive."Language Code");

        ReferenceText := FormatDocument.SetText(SalesHeaderArchive."Your Reference" <> '', SalesHeaderArchive.FieldCaption("Your Reference"));
        VATNoText := FormatDocument.SetText(SalesHeaderArchive."VAT Registration No." <> '', SalesHeaderArchive.FieldCaption("VAT Registration No."));
    end;

    local procedure InitTempLines(var TempSalesHeader: Record "Sales Header" temporary; var TempSalesLine: Record "Sales Line" temporary)
    begin
        TempSalesLineArchive.CopyTempLines("Sales Header Archive", TempSalesLine);

        TempVATAmountLine.DeleteAll();
        TempSalesHeader.TransferFields("Sales Header Archive");
        TempSalesLine."Prepayment Line" := true;  // used as flag in CalcVATAmountLines -> not invoice rounding
        TempSalesLine.CalcVATAmountLines(0, TempSalesHeader, TempSalesLine, TempVATAmountLine);
    end;
}

