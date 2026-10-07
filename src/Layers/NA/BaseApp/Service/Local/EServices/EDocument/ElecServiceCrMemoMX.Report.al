// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Service.History;
using Microsoft.Service.Setup;
using System.Globalization;
using System.Utilities;

report 10478 "Elec. Service Cr Memo MX"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Service/Local/eServices/EDocument/ElecServiceCrMemoMX.rdlc';
    Caption = 'Elec. Service Cr Memo MX';
    Permissions = TableData "Sales Shipment Buffer" = rimd;

    dataset
    {
        dataitem("Service Cr.Memo Header"; "Service Cr.Memo Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Customer No.", "No. Printed";
            RequestFilterHeading = 'Posted Service Credit Memo';
            column(Service_Cr_Memo_Header_No_; "No.")
            {
            }
            column(DocumentFooter; DocumentFooterLbl)
            {
            }
            dataitem(CopyLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                dataitem(PageLoop; "Integer")
                {
                    DataItemTableView = sorting(Number) where(Number = const(1));
                    column(CompanyInfo_Picture; CompanyInfo.Picture)
                    {
                    }
                    column(CompanyInfo1_Picture; CompanyInfo1.Picture)
                    {
                    }
                    column(CompanyInfo2_Picture; CompanyInfo2.Picture)
                    {
                    }
                    column(STRSUBSTNO_Text005_CopyText_; StrSubstNo(Text005, CopyText))
                    {
                    }
                    column(CustAddr_1_; CustAddr[1])
                    {
                    }
                    column(CompanyAddr_1_; CompanyAddr[1])
                    {
                    }
                    column(CustAddr_2_; CustAddr[2])
                    {
                    }
                    column(CompanyAddr_2_; CompanyAddr[2])
                    {
                    }
                    column(CustAddr_3_; CustAddr[3])
                    {
                    }
                    column(CompanyAddr_3_; CompanyAddr[3])
                    {
                    }
                    column(CustAddr_4_; CustAddr[4])
                    {
                    }
                    column(CompanyAddr_4_; CompanyAddr[4])
                    {
                    }
                    column(CustAddr_5_; CustAddr[5])
                    {
                    }
                    column(CompanyInfo__Phone_No__; CompanyInfo."Phone No.")
                    {
                    }
                    column(CustAddr_6_; CustAddr[6])
                    {
                    }
                    column(CompanyInfo__Fax_No__; CompanyInfo."Fax No.")
                    {
                    }
                    column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
                    {
                    }
                    column(CompanyInfo__Giro_No__; CompanyInfo."Giro No.")
                    {
                    }
                    column(CompanyInfo__Bank_Name_; CompanyBankAccount.Name)
                    {
                    }
                    column(CompanyInfo__Bank_Account_No__; CompanyBankAccount."Bank Account No.")
                    {
                    }
                    column(Service_Cr_Memo_Header___Bill_to_Customer_No__; "Service Cr.Memo Header"."Bill-to Customer No.")
                    {
                    }
                    column(Service_Cr_Memo_Header___Posting_Date_; Format("Service Cr.Memo Header"."Posting Date"))
                    {
                    }
                    column(VATNoText; VATNoText)
                    {
                    }
                    column(Service_Cr_Memo_Header___VAT_Registration_No__; "Service Cr.Memo Header"."VAT Registration No.")
                    {
                    }
                    column(Service_Cr_Memo_Header___No__; "Service Cr.Memo Header"."No.")
                    {
                    }
                    column(SalesPersonText; SalesPersonText)
                    {
                    }
                    column(SalesPurchPerson_Name; SalesPurchPerson.Name)
                    {
                    }
                    column(AppliedToText; AppliedToText)
                    {
                    }
                    column(ReferenceText; ReferenceText)
                    {
                    }
                    column(Service_Cr_Memo_Header___Your_Reference_; "Service Cr.Memo Header"."Your Reference")
                    {
                    }
                    column(CustAddr_7_; CustAddr[7])
                    {
                    }
                    column(CustAddr_8_; CustAddr[8])
                    {
                    }
                    column(CompanyAddr_5_; CompanyAddr[5])
                    {
                    }
                    column(CompanyAddr_6_; CompanyAddr[6])
                    {
                    }
                    column(FORMAT__Service_Cr_Memo_Header___Document_Date__0_4_; Format("Service Cr.Memo Header"."Document Date", 0, 4))
                    {
                    }
                    column(Service_Cr_Memo_Header___Prices_Including_VAT_; "Service Cr.Memo Header"."Prices Including VAT")
                    {
                    }
                    column(PageCaption; StrSubstNo(Text006, ''))
                    {
                    }
                    column(OutputNo; OutputNo)
                    {
                    }
                    column(Formatted_Service_Cr_Memo_Header___Prices_Including_VAT; Format("Service Cr.Memo Header"."Prices Including VAT"))
                    {
                    }
                    column(FORMAT_Cust__Tax_Identification_Type__; Format(Cust."Tax Identification Type"))
                    {
                    }
                    column(CompanyInfo__RFC_No__; CompanyInfo."RFC Number")
                    {
                    }
                    column(FolioText; "Service Cr.Memo Header"."Fiscal Invoice Number PAC")
                    {
                    }
                    column(Service_Cr_Memo_Header___Certificate_Serial_No__; "Service Cr.Memo Header"."Certificate Serial No.")
                    {
                    }
                    column(NoSeriesLine__Authorization_Code_; "Service Cr.Memo Header"."Date/Time Stamped")
                    {
                    }
                    column(NoSeriesLine__Authorization_Year_; StrSubstNo(Text009, "Service Cr.Memo Header"."Bill-to City", "Service Cr.Memo Header"."Document Date"))
                    {
                    }
                    column(Customer__RFC_No__; Customer."RFC No.")
                    {
                    }
                    column(Cust__Phone_No__; Cust."Phone No.")
                    {
                    }
                    column(PageLoop_Number; Number)
                    {
                    }
                    column(CompanyInfo__Phone_No__Caption; CompanyInfo__Phone_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Fax_No__Caption; CompanyInfo__Fax_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Giro_No__Caption; CompanyInfo__Giro_No__CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Bank_Name_Caption; CompanyInfo__Bank_Name_CaptionLbl)
                    {
                    }
                    column(CompanyInfo__Bank_Account_No__Caption; CompanyInfo__Bank_Account_No__CaptionLbl)
                    {
                    }
                    column(Service_Cr_Memo_Header___Bill_to_Customer_No__Caption; "Service Cr.Memo Header".FieldCaption("Bill-to Customer No."))
                    {
                    }
                    column(Service_Cr_Memo_Header___Posting_Date_Caption; Service_Cr_Memo_Header___Posting_Date_CaptionLbl)
                    {
                    }
                    column(Service_Cr_Memo_Header___Prices_Including_VAT_Caption; "Service Cr.Memo Header".FieldCaption("Prices Including VAT"))
                    {
                    }
                    column(Tax_Ident__TypeCaption; Tax_Ident__TypeCaptionLbl)
                    {
                    }
                    column(CompanyInfo__RFC_No__Caption; CompanyInfo__RFC_No__CaptionLbl)
                    {
                    }
                    column(FolioTextCaption; FolioTextCaptionLbl)
                    {
                    }
                    column(Service_Cr_Memo_Header___Certificate_Serial_No__Caption; "Service Cr.Memo Header".FieldCaption("Certificate Serial No."))
                    {
                    }
                    column(NoSeriesLine__Authorization_Code_Caption; NoSeriesLine__Authorization_Code_CaptionLbl)
                    {
                    }
                    column(NoSeriesLine__Authorization_Year_Caption; NoSeriesLine__Authorization_Year_CaptionLbl)
                    {
                    }
                    column(Customer__RFC_No__Caption; Customer__RFC_No__CaptionLbl)
                    {
                    }
                    column(Cust__Phone_No__Caption; Cust__Phone_No__CaptionLbl)
                    {
                    }
                    column(SATPaymentMethod; SATPaymentMethod)
                    {
                    }
                    column(SATPaymentTerm; SATPaymentTerm)
                    {
                    }
                    column(SATTaxRegimeClassification; SATTaxRegimeClassification)
                    {
                    }
                    column(TaxRegimeCaption; TaxRegimeLbl)
                    {
                    }
                    dataitem(DimensionLoop1; "Integer")
                    {
                        DataItemLinkReference = "Service Cr.Memo Header";
                        DataItemTableView = sorting(Number);
                        column(DimText; DimText)
                        {
                        }
                        column(DimText_Control81; DimText)
                        {
                        }
                        column(DimensionLoop1_Number; Number)
                        {
                        }
                        column(Header_DimensionsCaption; Header_DimensionsCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            DimText := DimTxtArr[Number];
                        end;

                        trigger OnPreDataItem()
                        begin
                            if not ShowInternalInfo then
                                CurrReport.Break();
                            FindDimTxt("Service Cr.Memo Header"."Dimension Set ID");
                            SetRange(Number, 1, DimTxtArrLength);
                        end;
                    }
                    dataitem("Service Cr.Memo Line"; "Service Cr.Memo Line")
                    {
                        DataItemLink = "Document No." = field("No.");
                        DataItemLinkReference = "Service Cr.Memo Header";
                        DataItemTableView = sorting("Document No.", "Line No.");
                        column(TypeInt; TypeInt)
                        {
                        }
                        column(TotalAmount; TotalAmount)
                        {
                        }
                        column(TotalAmountInclVAT; TotalAmountInclVAT)
                        {
                        }
                        column(TotalInvDiscAmount; TotalInvDiscAmount)
                        {
                        }
                        column(ServiceCrMemoLine__Line_No__; "Service Cr.Memo Line"."Line No.")
                        {
                        }
                        column(ServCrMemoHeader_VATBaseDisc; "Service Cr.Memo Header"."VAT Base Discount %")
                        {
                        }
                        column(TotalLineAmount; TotalLineAmount)
                        {
                        }
                        column(Service_Cr_Memo_Line__Line_Amount_; "Line Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Service_Cr_Memo_Line_Description; Description)
                        {
                        }
                        column(Service_Cr_Memo_Line__No__; "No.")
                        {
                        }
                        column(Service_Cr_Memo_Line_Description_Control62; Description)
                        {
                        }
                        column(Service_Cr_Memo_Line_Quantity; Quantity)
                        {
                        }
                        column(Service_Cr_Memo_Line__Unit_of_Measure_; "Unit of Measure")
                        {
                        }
                        column(Service_Cr_Memo_Line__Unit_Price_; "Unit Price")
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 2;
                        }
                        column(Service_Cr_Memo_Line__Line_Discount___; "Line Discount %")
                        {
                        }
                        column(Service_Cr_Memo_Line__Line_Amount__Control67; "Line Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Service_Cr_Memo_Line__VAT_Identifier_; "VAT Identifier")
                        {
                        }
                        column(PostedReceiptDate; Format(PostedReceiptDate))
                        {
                        }
                        column(Service_Cr_Memo_Line__Line_Amount__Control83; "Line Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Inv__Discount_Amount_; -"Inv. Discount Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Service_Cr_Memo_Line__Line_Amount__Control96; "Line Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(TotalText; TotalText)
                        {
                        }
                        column(Service_Cr_Memo_Line_Amount; Amount)
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmountInWords_1_; AmountInWords[1])
                        {
                        }
                        column(AmountInWords_2_; AmountInWords[2])
                        {
                        }
                        column(TotalExclVATText; TotalExclVATText)
                        {
                        }
                        column(TotalInclVATText; TotalInclVATText)
                        {
                        }
                        column(Service_Cr_Memo_Line__Amount_Including_VAT_; "Amount Including VAT")
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Amount_Including_VAT____Amount; "Amount Including VAT" - Amount)
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine_VATAmountText; VATAmountLine.VATAmountText())
                        {
                        }
                        column(Service_Cr_Memo_Line_Amount_Control69; Amount)
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(AmountInWords_1__Control1020021; AmountInWords[1])
                        {
                        }
                        column(AmountInWords_2__Control1020022; AmountInWords[2])
                        {
                        }
                        column(Line_Amount_____Inv__Discount_Amount_____Amount_Including_VAT__; -("Line Amount" - "Inv. Discount Amount" - "Amount Including VAT"))
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(Service_Cr_Memo_Line_Amount_Control87; Amount)
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Amount_Including_VAT____Amount_Control89; "Amount Including VAT" - Amount)
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(Service_Cr_Memo_Line__Amount_Including_VAT__Control91; "Amount Including VAT")
                        {
                            AutoFormatExpression = "Service Cr.Memo Line".GetCurrencyCode();
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine_VATAmountText_Control76; VATAmountLine.VATAmountText())
                        {
                        }
                        column(TotalExclVATText_Control77; TotalExclVATText)
                        {
                        }
                        column(TotalInclVATText_Control78; TotalInclVATText)
                        {
                        }
                        column(AmountInWords_1__Control1020018; AmountInWords[1])
                        {
                        }
                        column(AmountInWords_2__Control1020019; AmountInWords[2])
                        {
                        }
                        column(Service_Cr_Memo_Line_Document_No_; "Document No.")
                        {
                        }
                        column(Service_Cr_Memo_Line__No__Caption; FieldCaption("No."))
                        {
                        }
                        column(Service_Cr_Memo_Line_Description_Control62Caption; FieldCaption(Description))
                        {
                        }
                        column(Service_Cr_Memo_Line_QuantityCaption; FieldCaption(Quantity))
                        {
                        }
                        column(Service_Cr_Memo_Line__Unit_of_Measure_Caption; FieldCaption("Unit of Measure"))
                        {
                        }
                        column(Unit_PriceCaption; Unit_PriceCaptionLbl)
                        {
                        }
                        column(Service_Cr_Memo_Line__Line_Discount___Caption; Service_Cr_Memo_Line__Line_Discount___CaptionLbl)
                        {
                        }
                        column(AmountCaption; AmountCaptionLbl)
                        {
                        }
                        column(Service_Cr_Memo_Line__VAT_Identifier_Caption; FieldCaption("VAT Identifier"))
                        {
                        }
                        column(PostedReceiptDateCaption; PostedReceiptDateCaptionLbl)
                        {
                        }
                        column(ContinuedCaption; ContinuedCaptionLbl)
                        {
                        }
                        column(ContinuedCaption_Control82; ContinuedCaption_Control82Lbl)
                        {
                        }
                        column(Inv__Discount_Amount_Caption; Inv__Discount_Amount_CaptionLbl)
                        {
                        }
                        column(SubtotalCaption; SubtotalCaptionLbl)
                        {
                        }
                        column(Amount_in_words_Caption; Amount_in_words_CaptionLbl)
                        {
                        }
                        column(Amount_in_words_Caption_Control1020020; Amount_in_words_Caption_Control1020020Lbl)
                        {
                        }
                        column(Line_Amount_____Inv__Discount_Amount_____Amount_Including_VAT__Caption; Line_Amount_____Inv__Discount_Amount_____Amount_Including_VAT__CaptionLbl)
                        {
                        }
                        column(Amount_in_words_Caption_Control1020017; Amount_in_words_Caption_Control1020017Lbl)
                        {
                        }
                        dataitem("Service Shipment Buffer"; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(ServiceShipmentBuffer__Posting_Date_; Format(ServiceShipmentBuffer."Posting Date"))
                            {
                            }
                            column(ServiceShipmentBuffer_Quantity; ServiceShipmentBuffer.Quantity)
                            {
                                DecimalPlaces = 0 : 5;
                            }
                            column(Service_Shipment_Buffer_Number; Number)
                            {
                            }
                            column(Return_ReceiptCaption; Return_ReceiptCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                if Number = 1 then
                                    ServiceShipmentBuffer.Find('-')
                                else
                                    ServiceShipmentBuffer.Next();
                            end;

                            trigger OnPreDataItem()
                            begin
                                SetRange(Number, 1, ServiceShipmentBuffer.Count);
                            end;
                        }
                        dataitem(DimensionLoop2; "Integer")
                        {
                            DataItemTableView = sorting(Number);
                            column(DimText_Control88; DimText)
                            {
                            }
                            column(DimensionLoop2_Number; Number)
                            {
                            }
                            column(Line_DimensionsCaption; Line_DimensionsCaptionLbl)
                            {
                            }

                            trigger OnAfterGetRecord()
                            begin
                                DimText := DimTxtArr[Number];
                            end;

                            trigger OnPreDataItem()
                            begin
                                if not ShowInternalInfo then
                                    CurrReport.Break();

                                FindDimTxt("Service Cr.Memo Line"."Dimension Set ID");
                                SetRange(Number, 1, DimTxtArrLength);
                            end;
                        }

                        trigger OnAfterGetRecord()
                        begin
                            ServiceShipmentBuffer.DeleteAll();
                            PostedReceiptDate := 0D;
                            if Quantity <> 0 then
                                PostedReceiptDate := FindPostedShipmentDate();

                            if (Type = Type::"G/L Account") and not ShowInternalInfo then
                                "No." := '';

                            VATAmountLine.Init();
                            VATAmountLine."VAT Identifier" := "VAT Identifier";
                            VATAmountLine."VAT Calculation Type" := "VAT Calculation Type";
                            VATAmountLine."Tax Group Code" := "Tax Group Code";
                            VATAmountLine."VAT %" := "VAT %";
                            VATAmountLine."VAT Base" := Amount;
                            VATAmountLine."Amount Including VAT" := "Amount Including VAT";
                            VATAmountLine."Line Amount" := "Line Amount";
                            if "Allow Invoice Disc." then
                                VATAmountLine."Inv. Disc. Base Amount" := "Line Amount";
                            VATAmountLine."Invoice Discount Amount" := "Inv. Discount Amount";
                            VATAmountLine.InsertLine();

                            TotalAmount += Amount;
                            TotalAmountInclVAT += "Amount Including VAT";
                            TotalInvDiscAmount += "Inv. Discount Amount";
                            TotalLineAmount += "Line Amount";
                            TypeInt := Type.AsInteger();
                            CalculateAmountInWords(TotalAmountInclVAT);
                        end;

                        trigger OnPreDataItem()
                        begin
                            VATAmountLine.DeleteAll();
                            ServiceShipmentBuffer.Reset();
                            ServiceShipmentBuffer.DeleteAll();
                            FirstValueEntryNo := 0;
                            MoreLines := Find('+');
                            while MoreLines and (Description = '') and ("No." = '') and (Quantity = 0) and (Amount = 0) do
                                MoreLines := Next(-1) <> 0;
                            if not MoreLines then
                                CurrReport.Break();
                            SetRange("Line No.", 0, "Line No.");

                            TotalAmount := 0;
                            TotalAmountInclVAT := 0;
                            TotalInvDiscAmount := 0;
                            TotalLineAmount := 0;
                        end;
                    }
                    dataitem(VATCounter; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(VATAmountLine__VAT_Base_; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount_; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount_; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount_; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount_; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT___; VATAmountLine."VAT %")
                        {
                            DecimalPlaces = 0 : 5;
                        }
                        column(VATAmountLine__VAT_Base__Control105; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control106; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control135; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control136; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control137; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Identifier_; VATAmountLine."VAT Identifier")
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control109; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control110; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control129; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control130; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control131; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Base__Control113; VATAmountLine."VAT Base")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__VAT_Amount__Control114; VATAmountLine."VAT Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Line_Amount__Control126; VATAmountLine."Line Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control127; VATAmountLine."Inv. Disc. Base Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control128; VATAmountLine."Invoice Discount Amount")
                        {
                            AutoFormatExpression = "Service Cr.Memo Header"."Currency Code";
                            AutoFormatType = 1;
                        }
                        column(VATCounter_Number; Number)
                        {
                        }
                        column(VATAmountLine__VAT___Caption; VATAmountLine__VAT___CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control105Caption; VATAmountLine__VAT_Base__Control105CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Amount__Control106Caption; VATAmountLine__VAT_Amount__Control106CaptionLbl)
                        {
                        }
                        column(VAT_Amount_SpecificationCaption; VAT_Amount_SpecificationCaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Identifier_Caption; VATAmountLine__VAT_Identifier_CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Inv__Disc__Base_Amount__Control130Caption; VATAmountLine__Inv__Disc__Base_Amount__Control130CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Line_Amount__Control135Caption; VATAmountLine__Line_Amount__Control135CaptionLbl)
                        {
                        }
                        column(VATAmountLine__Invoice_Discount_Amount__Control137Caption; VATAmountLine__Invoice_Discount_Amount__Control137CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base_Caption; VATAmountLine__VAT_Base_CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control109Caption; VATAmountLine__VAT_Base__Control109CaptionLbl)
                        {
                        }
                        column(VATAmountLine__VAT_Base__Control113Caption; VATAmountLine__VAT_Base__Control113CaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            VATAmountLine.GetLine(Number);
                        end;

                        trigger OnPreDataItem()
                        begin
                            if VATAmountLine.GetTotalVATAmount() = 0 then
                                CurrReport.Break();
                            SetRange(Number, 1, VATAmountLine.Count);
                        end;
                    }
                    dataitem(Total; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                    }
                    dataitem(Total2; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(Service_Cr_Memo_Header___Customer_No__; "Service Cr.Memo Header"."Customer No.")
                        {
                        }
                        column(ShipToAddr_1_; ShipToAddr[1])
                        {
                        }
                        column(ShipToAddr_2_; ShipToAddr[2])
                        {
                        }
                        column(ShipToAddr_3_; ShipToAddr[3])
                        {
                        }
                        column(ShipToAddr_4_; ShipToAddr[4])
                        {
                        }
                        column(ShipToAddr_5_; ShipToAddr[5])
                        {
                        }
                        column(ShipToAddr_6_; ShipToAddr[6])
                        {
                        }
                        column(ShipToAddr_7_; ShipToAddr[7])
                        {
                        }
                        column(ShipToAddr_8_; ShipToAddr[8])
                        {
                        }
                        column(Total2_Number; Number)
                        {
                        }
                        column(Ship_to_AddressCaption; Ship_to_AddressCaptionLbl)
                        {
                        }
                        column(Service_Cr_Memo_Header___Customer_No__Caption; "Service Cr.Memo Header".FieldCaption("Customer No."))
                        {
                        }

                        trigger OnPreDataItem()
                        begin
                            if not ShowShippingAddr then
                                CurrReport.Break();
                        end;
                    }
                    dataitem(OriginalStringLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(OriginalStringText; OriginalStringText)
                        {
                        }
                        column(OriginalStringLoop_Number; Number)
                        {
                        }
                        column(Original_StringCaption; Original_StringCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Clear(OriginalStringText);
                            OriginalStringText := CopyStr(OriginalStringTextUnbounded, Position, MaxStrLen(OriginalStringText));
                            Position := Position + StrLen(OriginalStringText);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, Round(StrLen(OriginalStringTextUnbounded) / MaxStrLen(OriginalStringText), 1, '>'));
                            Position := 1;
                        end;
                    }
                    dataitem(DigitalSignaturePACLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(DigitalSignaturePACText; DigitalSignaturePACText)
                        {
                        }
                        column(DigitalSignaturePACLoop_Number; Number)
                        {
                        }
                        column(Digital_StampCaption; Digital_StampCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Clear(DigitalSignaturePACText);
                            DigitalSignaturePACText := CopyStr(DigitalSignaturePACTextUnbounded, Position, MaxStrLen(DigitalSignaturePACText));
                            Position := Position + StrLen(DigitalSignaturePACText);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, Round(StrLen(DigitalSignaturePACTextUnbounded) / MaxStrLen(DigitalSignaturePACText), 1, '>'));
                            Position := 1;
                        end;
                    }
                    dataitem(DigitalSignatureLoop; "Integer")
                    {
                        DataItemTableView = sorting(Number);
                        column(DigitalSignatureText; DigitalSignatureText)
                        {
                        }
                        column(DigitalSignatureLoop_Number; Number)
                        {
                        }
                        column(DigitalSignaturePACTextCaption; DigitalSignaturePACTextCaptionLbl)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            Clear(DigitalSignatureText);
                            DigitalSignatureText := CopyStr(DigitalSignatureTextUnbounded, Position, MaxStrLen(DigitalSignatureText));
                            Position := Position + StrLen(DigitalSignatureText);
                        end;

                        trigger OnPreDataItem()
                        begin
                            SetRange(Number, 1, Round(StrLen(DigitalSignatureTextUnbounded) / MaxStrLen(DigitalSignatureText), 1, '>'));
                            Position := 1;
                        end;
                    }
                    dataitem(QRCode; "Integer")
                    {
                        DataItemTableView = sorting(Number) where(Number = const(1));
                        column(Service_Cr_Memo_Header___QR_Code_; "Service Cr.Memo Header"."QR Code")
                        {
                        }
                        column(QRCode_Number; Number)
                        {
                        }

                        trigger OnAfterGetRecord()
                        begin
                            "Service Cr.Memo Header".CalcFields("QR Code");
                        end;
                    }
                }

                trigger OnAfterGetRecord()
                begin
                    if Number > 1 then begin
                        CopyText := Text004;
                        OutputNo += 1;
                    end;
                end;

                trigger OnPostDataItem()
                begin
                    if not CurrReport.Preview then
                        ServiceCrMemoCountPrinted.Run("Service Cr.Memo Header");
                end;

                trigger OnPreDataItem()
                begin
                    NoOfLoops := Abs(NoOfCopies) + 1;
                    CopyText := '';
                    SetRange(Number, 1, NoOfLoops);

                    OutputNo := 1;
                end;
            }

            trigger OnAfterGetRecord()
            var
                SATUtilities: Codeunit "SAT Utilities";
                InStream: InStream;
            begin
                if "Source Code" = SourceCodeSetup."Deleted Document" then
                    Error(Text008);

                CurrReport.Language := LanguageMgt.GetLanguageIdOrDefault("Language Code");
                CurrReport.FormatRegion := LanguageMgt.GetFormatRegionOrDefault("Format Region");

                if not CompanyBankAccount.Get("Service Cr.Memo Header"."Company Bank Account Code") then
                    CompanyBankAccount.CopyBankFieldsFromCompanyInfo(CompanyInfo);

                if RespCenter.Get("Responsibility Center") then begin
                    FormatAddr.RespCenter(CompanyAddr, RespCenter);
                    CompanyInfo."Phone No." := RespCenter."Phone No.";
                    CompanyInfo."Fax No." := RespCenter."Fax No.";
                end else
                    FormatAddr.Company(CompanyAddr, CompanyInfo);

                if "Salesperson Code" = '' then begin
                    SalesPurchPerson.Init();
                    SalesPersonText := '';
                end else begin
                    SalesPurchPerson.Get("Salesperson Code");
                    SalesPersonText := Text000;
                end;
                if "Your Reference" = '' then
                    ReferenceText := ''
                else
                    ReferenceText := FieldCaption("Your Reference");
                if "VAT Registration No." = '' then
                    VATNoText := ''
                else
                    VATNoText := FieldCaption("VAT Registration No.");
                if "Currency Code" = '' then begin
                    GLSetup.TestField("LCY Code");
                    TotalText := StrSubstNo(Text001, GLSetup."LCY Code");
                    TotalInclVATText := StrSubstNo(Text002, GLSetup."LCY Code");
                    TotalExclVATText := StrSubstNo(Text007, GLSetup."LCY Code");
                end else begin
                    TotalText := StrSubstNo(Text001, "Currency Code");
                    TotalInclVATText := StrSubstNo(Text002, "Currency Code");
                    TotalExclVATText := StrSubstNo(Text007, "Currency Code");
                end;
                ServiceFormatAddress.ServiceCrMemoBillTo(CustAddr, "Service Cr.Memo Header");
                if "Applies-to Doc. No." = '' then
                    AppliedToText := ''
                else
                    AppliedToText := StrSubstNo(Text003, "Applies-to Doc. Type", "Applies-to Doc. No.");

                ShowShippingAddr := ServiceFormatAddress.ServiceCrMemoShipTo(ShipToAddr, CustAddr, "Service Cr.Memo Header");

                if not Cust.Get("Bill-to Customer No.") then
                    Clear(Cust);

                if not Customer.Get("Bill-to Customer No.") then
                    Clear(Customer);

                "Service Cr.Memo Header".CalcFields("Original String", "Digital Stamp SAT", "Digital Stamp PAC");

                Clear(OriginalStringTextUnbounded);
                "Original String".CreateInStream(InStream);
                InStream.Read(OriginalStringTextUnbounded);

                Clear(DigitalSignatureTextUnbounded);
                "Digital Stamp SAT".CreateInStream(InStream);
                InStream.Read(DigitalSignatureTextUnbounded);

                Clear(DigitalSignaturePACTextUnbounded);
                "Digital Stamp PAC".CreateInStream(InStream);
                InStream.Read(DigitalSignaturePACTextUnbounded);

                SATPaymentMethod := SATUtilities.GetSATPaymentTermDescription("Payment Terms Code"); // MetodoPago
                SATPaymentTerm := SATUtilities.GetSATPaymentMethodDescription("Payment Method Code"); // FormaPago
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
                        ApplicationArea = BasicMX;
                        Caption = 'No. of Copies';
                        ToolTip = 'Specifies the number of copies to print of the document.';
                    }
                    field(ShowInternalInfo; ShowInternalInfo)
                    {
                        ApplicationArea = BasicMX;
                        Caption = 'Show Internal Information';
                        ToolTip = 'Specifies if the printed document includes dimensions that your company uses.';
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
    var
        SATUtilities: Codeunit "SAT Utilities";
    begin
        GLSetup.Get();
        CompanyInfo.Get();
        ServiceSetup.Get();
        SourceCodeSetup.Get();

        case ServiceSetup."Logo Position on Documents" of
            ServiceSetup."Logo Position on Documents"::"No Logo":
                ;
            ServiceSetup."Logo Position on Documents"::Left:
                CompanyInfo.CalcFields(Picture);
            ServiceSetup."Logo Position on Documents"::Center:
                begin
                    CompanyInfo1.Get();
                    CompanyInfo1.CalcFields(Picture);
                end;
            ServiceSetup."Logo Position on Documents"::Right:
                begin
                    CompanyInfo2.Get();
                    CompanyInfo2.CalcFields(Picture);
                end;
        end;

        SATTaxRegimeClassification := SATUtilities.GetSATTaxSchemeDescription(CompanyInfo."SAT Tax Regime Classification");
    end;

    var
        Text000: Label 'Salesperson';
        Text001: Label 'Total %1';
        Text002: Label 'Total %1 Incl. VAT';
        Text003: Label '(Applies to %1 %2)';
        Text004: Label 'COPY';
        Text005: Label 'Service - Credit Memo %1';
        Text006: Label 'Page %1';
        Text007: Label 'Total %1 Excl. VAT';
        GLSetup: Record "General Ledger Setup";
        SalesPurchPerson: Record "Salesperson/Purchaser";
        CompanyBankAccount: Record "Bank Account";
        ServiceSetup: Record "Service Mgt. Setup";
        VATAmountLine: Record "VAT Amount Line" temporary;
        DimSetEntry: Record "Dimension Set Entry";
        ServiceShipmentBuffer: Record "Service Shipment Buffer" temporary;
        RespCenter: Record "Responsibility Center";
        Cust: Record Customer;
        Customer: Record Customer;
        SourceCodeSetup: Record "Source Code Setup";
        LanguageMgt: Codeunit Language;
        ServiceCrMemoCountPrinted: Codeunit "Service Cr. Memo-Printed";
        FormatAddr: Codeunit "Format Address";
        ServiceFormatAddress: Codeunit "Service Format Address";
        CustAddr: array[8] of Text[100];
        ShipToAddr: array[8] of Text[100];
        CompanyAddr: array[8] of Text[100];
        SalesPersonText: Text[30];
        VATNoText: Text[80];
        ReferenceText: Text[80];
        AppliedToText: Text[40];
        TotalText: Text[50];
        TotalExclVATText: Text[50];
        TotalInclVATText: Text[50];
        OriginalStringText: Text[80];
        DigitalSignatureText: Text[80];
        DigitalSignaturePACText: Text[80];
        AmountInWords: array[2] of Text[80];
        MoreLines: Boolean;
        NoOfCopies: Integer;
        NoOfLoops: Integer;
        OutputNo: Integer;
        TypeInt: Integer;
        CopyText: Text[30];
        ShowShippingAddr: Boolean;
        DimText: Text[120];
        ShowInternalInfo: Boolean;
        FirstValueEntryNo: Integer;
        Position: Integer;
        PostedReceiptDate: Date;
        NextEntryNo: Integer;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalInvDiscAmount: Decimal;
        TotalLineAmount: Decimal;
        DimTxtArrLength: Integer;
        DimTxtArr: array[500] of Text[50];
        OriginalStringTextUnbounded: Text;
        DigitalSignatureTextUnbounded: Text;
        Text008: Label 'You can not sign or send or print a deleted document.';
        DigitalSignaturePACTextUnbounded: Text;
        Text009: Label '%1, %2';
        CompanyInfo__Phone_No__CaptionLbl: Label 'Phone No.';
        CompanyInfo__Fax_No__CaptionLbl: Label 'Fax No.';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        CompanyInfo__Giro_No__CaptionLbl: Label 'Giro No.';
        CompanyInfo__Bank_Name_CaptionLbl: Label 'Bank';
        CompanyInfo__Bank_Account_No__CaptionLbl: Label 'Account No.';
        Service_Cr_Memo_Header___Posting_Date_CaptionLbl: Label 'Posting Date';
        Tax_Ident__TypeCaptionLbl: Label 'Tax Ident. Type';
        CompanyInfo__RFC_No__CaptionLbl: Label 'Company RFC';
        FolioTextCaptionLbl: Label 'Folio:';
        NoSeriesLine__Authorization_Code_CaptionLbl: Label 'Date and time of certification:';
        NoSeriesLine__Authorization_Year_CaptionLbl: Label 'Location and Issue date:';
        Customer__RFC_No__CaptionLbl: Label 'Customer RFC';
        Cust__Phone_No__CaptionLbl: Label 'Phone number';
        Header_DimensionsCaptionLbl: Label 'Header Dimensions';
        Unit_PriceCaptionLbl: Label 'Unit Price';
        Service_Cr_Memo_Line__Line_Discount___CaptionLbl: Label 'Disc. %';
        AmountCaptionLbl: Label 'Amount';
        PostedReceiptDateCaptionLbl: Label 'Posted Return Receipt Date';
        ContinuedCaptionLbl: Label 'Continued';
        ContinuedCaption_Control82Lbl: Label 'Continued';
        Inv__Discount_Amount_CaptionLbl: Label 'Inv. Discount Amount';
        SubtotalCaptionLbl: Label 'Subtotal';
        Amount_in_words_CaptionLbl: Label 'Amount in words:';
        Amount_in_words_Caption_Control1020020Lbl: Label 'Amount in words:';
        Line_Amount_____Inv__Discount_Amount_____Amount_Including_VAT__CaptionLbl: Label 'Payment Discount on VAT';
        Amount_in_words_Caption_Control1020017Lbl: Label 'Amount in words:';
        Return_ReceiptCaptionLbl: Label 'Return Receipt';
        Line_DimensionsCaptionLbl: Label 'Line Dimensions';
        VATAmountLine__VAT___CaptionLbl: Label 'VAT %';
        VATAmountLine__VAT_Base__Control105CaptionLbl: Label 'VAT Base';
        VATAmountLine__VAT_Amount__Control106CaptionLbl: Label 'VAT Amount';
        VAT_Amount_SpecificationCaptionLbl: Label 'VAT Amount Specification';
        VATAmountLine__VAT_Identifier_CaptionLbl: Label 'VAT Identifier';
        VATAmountLine__Inv__Disc__Base_Amount__Control130CaptionLbl: Label 'Inv. Disc. Base Amount';
        VATAmountLine__Line_Amount__Control135CaptionLbl: Label 'Line Amount';
        VATAmountLine__Invoice_Discount_Amount__Control137CaptionLbl: Label 'Invoice Discount Amount';
        VATAmountLine__VAT_Base_CaptionLbl: Label 'Continued';
        VATAmountLine__VAT_Base__Control109CaptionLbl: Label 'Continued';
        VATAmountLine__VAT_Base__Control113CaptionLbl: Label 'Total';
        Ship_to_AddressCaptionLbl: Label 'Ship-to Address';
        Original_StringCaptionLbl: Label 'Original string of digital certificate complement from SAT';
        Digital_StampCaptionLbl: Label 'Digital stamp from SAT';
        DigitalSignaturePACTextCaptionLbl: Label 'Digital stamp';
        DocumentFooterLbl: Label 'This document is a printed version for electronic credit memo';
        TaxRegimeLbl: Label 'Regimen Fiscal:';
        SATPaymentMethod: Text[50];
        SATPaymentTerm: Text[50];
        SATTaxRegimeClassification: Text[100];

    protected var
        CompanyInfo: Record "Company Information";
        CompanyInfo1: Record "Company Information";
        CompanyInfo2: Record "Company Information";

    procedure FindPostedShipmentDate(): Date
    var
        ServiceShipmentBuffer2: Record "Service Shipment Buffer" temporary;
    begin
        NextEntryNo := 1;

        case "Service Cr.Memo Line".Type of
            "Service Cr.Memo Line".Type::Item:
                GenerateBufferFromValueEntry("Service Cr.Memo Line");
            "Service Cr.Memo Line".Type::" ":
                exit(0D);
        end;

        ServiceShipmentBuffer.Reset();
        ServiceShipmentBuffer.SetRange("Document No.", "Service Cr.Memo Line"."Document No.");
        ServiceShipmentBuffer.SetRange("Line No.", "Service Cr.Memo Line"."Line No.");

        if ServiceShipmentBuffer.Find('-') then begin
            ServiceShipmentBuffer2 := ServiceShipmentBuffer;
            if ServiceShipmentBuffer.Next() = 0 then begin
                ServiceShipmentBuffer.Get(ServiceShipmentBuffer2."Document No.", ServiceShipmentBuffer2."Line No.", ServiceShipmentBuffer2.
                  "Entry No.");
                ServiceShipmentBuffer.Delete();
                exit(ServiceShipmentBuffer2."Posting Date");
            end;
            ServiceShipmentBuffer.CalcSums(Quantity);
            if ServiceShipmentBuffer.Quantity <> "Service Cr.Memo Line".Quantity then begin
                ServiceShipmentBuffer.DeleteAll();
                exit("Service Cr.Memo Header"."Posting Date");
            end;
        end else
            exit("Service Cr.Memo Header"."Posting Date");
    end;

    procedure GenerateBufferFromValueEntry(ServiceCrMemoLine2: Record "Service Cr.Memo Line")
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        TotalQuantity: Decimal;
        Quantity: Decimal;
    begin
        TotalQuantity := ServiceCrMemoLine2."Quantity (Base)";
        ValueEntry.SetCurrentKey("Document No.");
        ValueEntry.SetRange("Document No.", ServiceCrMemoLine2."Document No.");
        ValueEntry.SetRange("Posting Date", "Service Cr.Memo Header"."Posting Date");
        ValueEntry.SetRange("Item Charge No.", '');
        ValueEntry.SetFilter("Entry No.", '%1..', FirstValueEntryNo);
        if ValueEntry.Find('-') then
            repeat
                if ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.") then begin
                    if ServiceCrMemoLine2."Qty. per Unit of Measure" <> 0 then
                        Quantity := ValueEntry."Invoiced Quantity" / ServiceCrMemoLine2."Qty. per Unit of Measure"
                    else
                        Quantity := ValueEntry."Invoiced Quantity";
                    AddBufferEntry(
                      ServiceCrMemoLine2,
                      -Quantity,
                      ItemLedgerEntry."Posting Date");
                    TotalQuantity := TotalQuantity - ValueEntry."Invoiced Quantity";
                end;
                FirstValueEntryNo := ValueEntry."Entry No." + 1;
            until (ValueEntry.Next() = 0) or (TotalQuantity = 0);
    end;

    procedure AddBufferEntry(ServiceCrMemoLine: Record "Service Cr.Memo Line"; QtyOnShipment: Decimal; PostingDate: Date)
    begin
        ServiceShipmentBuffer.SetRange("Document No.", ServiceCrMemoLine."Document No.");
        ServiceShipmentBuffer.SetRange("Line No.", ServiceCrMemoLine."Line No.");
        ServiceShipmentBuffer.SetRange("Posting Date", PostingDate);
        if ServiceShipmentBuffer.Find('-') then begin
            ServiceShipmentBuffer.Quantity := ServiceShipmentBuffer.Quantity - QtyOnShipment;
            ServiceShipmentBuffer.Modify();
            exit;
        end;

        ServiceShipmentBuffer.Init();
        ServiceShipmentBuffer."Document No." := ServiceCrMemoLine."Document No.";
        ServiceShipmentBuffer."Line No." := ServiceCrMemoLine."Line No.";
        ServiceShipmentBuffer."Entry No." := NextEntryNo;
        ServiceShipmentBuffer.Type := ServiceCrMemoLine.Type;
        ServiceShipmentBuffer."No." := ServiceCrMemoLine."No.";
        ServiceShipmentBuffer.Quantity := -QtyOnShipment;
        ServiceShipmentBuffer."Posting Date" := PostingDate;
        ServiceShipmentBuffer.Insert();
        NextEntryNo := NextEntryNo + 1
    end;

    procedure FindDimTxt(DimSetID: Integer)
    var
        Separation: Text[5];
        i: Integer;
        TxtToAdd: Text[120];
        StartNewLine: Boolean;
    begin
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        DimTxtArrLength := 0;
        for i := 1 to ArrayLen(DimTxtArr) do
            DimTxtArr[i] := '';
        if not DimSetEntry.Find('-') then
            exit;
        Separation := '; ';
        repeat
            TxtToAdd := DimSetEntry."Dimension Code" + ' - ' + DimSetEntry."Dimension Value Code";
            if DimTxtArrLength = 0 then
                StartNewLine := true
            else
                StartNewLine := StrLen(DimTxtArr[DimTxtArrLength]) + StrLen(Separation) + StrLen(TxtToAdd) > MaxStrLen(DimTxtArr[1]);
            if StartNewLine then begin
                DimTxtArrLength += 1;
                DimTxtArr[DimTxtArrLength] := TxtToAdd
            end else
                DimTxtArr[DimTxtArrLength] := DimTxtArr[DimTxtArrLength] + Separation + TxtToAdd;
        until DimSetEntry.Next() = 0;
    end;

    local procedure CalculateAmountInWords(AmountInclVAT: Decimal)
    var
        LanguageId: Integer;
        TranslationManagement: Report "Check Translation Management";
    begin
        if CurrReport.Language in [1033, 3084, 2058, 4105] then
            LanguageId := CurrReport.Language
        else
            LanguageId := GlobalLanguage;
        TranslationManagement.FormatNoText(AmountInWords, AmountInclVAT,
          LanguageId, "Service Cr.Memo Header"."Currency Code")
    end;
}

