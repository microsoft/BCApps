// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Processing.Import.Purchase;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using System.Utilities;

/// <summary>
/// Report for generating sample purchase invoice PDFs
/// </summary>
report 6102 "E-Doc Sample Purchase Invoice"
{
    Caption = 'E-Doc Sample Purchase Invoice';
    DefaultRenderingLayout = SampleInvoiceLayout1;

    dataset
    {
        dataitem(Header; "E-Document Purchase Header")
        {
            UseTemporary = true;
            column(No_; "Sales Invoice No.")
            {
            }
            column(InvoiceCaption; InvoiceCaptionLbl)
            {
            }
            column(InvoiceNoCaption; InvoiceNoCaptionLbl)
            {
            }
            column(BuyFromVendorNo; "[BC] Vendor No.")
            {
            }
            column(VendorInvoiceNo_Lbl; VendorInvoiceNoLbl)
            {
            }
            column(VendorInvoiceNo; "Sales Invoice No.")
            {
            }
            column(PostingDate; "Document Date")
            {
            }
            column(PostingDateCaption; PostingDateCaptionLbl)
            {
            }
            column(DueDate; "Due Date")
            {
            }
            column(DueDateCaption; DueDateCaptionLbl)
            {
            }
            column(FromCaption; FromCaptionLbl)
            {
            }
            column(BillToCaption; BillToCaptionLbl)
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
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
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
            column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
            {
            }
            column(CompanyInfoPhoneNoCaption; PhoneNoCaptionLbl)
            {
            }
            column(CompanyInfoVATRegistrationNo; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompanyInfoVATRegistrationNoCaption; VATRegistrationNoCaptionLbl)
            {
            }
            column(CompanyInfoGiroNo; CompanyInfo."Giro No.")
            {
            }
            column(CompanyInfoGiroNoCaption; GiroNoCaptionLbl)
            {
            }
            column(CompanyInfoBankName; CompanyInfo."Bank Name")
            {
            }
            column(CompanyInfoBankNameCaption; BankNameCaptionLbl)
            {
            }
            column(CompanyInfoBankAccountNo; CompanyInfo."Bank Account No.")
            {
            }
            column(CompanyInfoBankAccountNoCaption; BankAccountNoCaptionLbl)
            {
            }
            column(CompanyInfoHomePage; CompanyInfo."Home Page")
            {
            }
            column(CompanyInfoHomePageCaption; HomePageCaptionLbl)
            {
            }
            column(CompanyInfoEMail; CompanyInfo."E-Mail")
            {
            }
            column(CompanyInfoEMailCaption; EMailCaptionLbl)
            {
            }
            column(SubTotalCaption; SubTotalLbl)
            {
            }
            column(TaxCaption; TaxLbl)
            {
            }
            column(TotalCaption; TotalLbl)
            {
            }

            dataitem(Line; "E-Document Purchase Line")
            {
                UseTemporary = true;
                DataItemLink = "E-Document Entry No." = field("E-Document Entry No.");
                column(LineNo; "Line No.")
                {
                }
                column(Type; "[BC] Purchase Line Type")
                {
                }
                column(NoCaptionLbl; NoCaptionLbl)
                {
                }
                column(No; "[BC] Purchase Type No.")
                {
                }
                column(ItemDescription_Lbl; ItemDescriptionCaptionLbl)
                {
                }
                column(Description; Description)
                {
                }
                column(ItemQuantity_Lbl; ItemQuantityCaptionLbl)
                {
                }
                column(Quantity; Quantity)
                {
                }
                column(DirectUnitCost; "Unit Price")
                {
                }
                column(DirectUnitCostCaption; DirectUnitCostCaptionLbl)
                {
                }
                column(DeferralCode; "[BC] Deferral Code")
                {
                }
                column(UOM_PurchLine_Lbl; ItemUnitOfMeasureCaptionLbl)
                {
                }
                column(UnitOfMeasureCode; "Unit of Measure")
                {
                }
                column(LineAmount; "Sub Total")
                {
                }
                column(LineAmountCaption; LineAmountCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TotalAmount += Line."Sub Total";
                    TotalAmtInclVAT += Line."Sub Total";
                end;
            }

            dataitem(Totals; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));
                column(TotalAmountExclVAT; TotalAmount)
                {
                }
                column(VATAmount; VATAmount)
                {
                }
                column(TotalAmountInclVAT; TotalAmtInclVAT)
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                FormatAddressFields(Header);
                VATAmount := Header."Total VAT";
                TotalAmtInclVAT += VATAmount;
            end;
        }
    }

    rendering
    {
        layout(SampleInvoiceLayout1)
        {
            Type = Word;
            Caption = 'First sample invoice layout';
            Summary = 'First sample invoice layout';
            LayoutFile = './src/SampleInvoice/EDocSamplePurchInvoice.docx';
        }
        layout(SampleInvoiceLayout2)
        {
            Type = Word;
            Caption = 'Second sample invoice layout';
            Summary = 'Second sample invoice layout';
            LayoutFile = './src/SampleInvoice/EDocSamplePurchInvoice2.docx';
        }
        layout(SampleInvoiceLayout3)
        {
            Type = Word;
            Caption = 'Third sample invoice layout';
            Summary = 'Third sample invoice layout';
            LayoutFile = './src/SampleInvoice/EDocSamplePurchInvoice3.docx';
        }
    }

    var

        CompanyInfo: Record "Company Information";
        RespCenter: Record "Responsibility Center";
        FormatAddr: Codeunit "Format Address";
        TotalAmount, VATAmount, TotalAmtInclVAT : Decimal;
        VendAddr, CompanyAddr : array[8] of Text[100];
        PhoneNoCaptionLbl: Label 'Phone No.';
        HomePageCaptionLbl: Label 'Home Page';
        EMailCaptionLbl: Label 'Email';
        VATRegistrationNoCaptionLbl: Label 'VAT Registration No.';
        GiroNoCaptionLbl: Label 'Giro No.';
        BankNameCaptionLbl: Label 'Bank';
        BankAccountNoCaptionLbl: Label 'Account No.';
        PostingDateCaptionLbl: Label 'Invoice Date';
        DueDateCaptionLbl: Label 'Due Date';
        InvoiceCaptionLbl: Label 'INVOICE';
        InvoiceNoCaptionLbl: Label 'Invoice No.';
        NoCaptionLbl: Label 'No.';
        DirectUnitCostCaptionLbl: Label 'Unit Cost';
        ItemQuantityCaptionLbl: Label 'Quantity';
        LineAmountCaptionLbl: Label 'Amount';
        ItemDescriptionCaptionLbl: Label 'Description';
        ItemUnitOfMeasureCaptionLbl: Label 'Unit';
        SubTotalLbl: Label 'Subtotal';
        TaxLbl: Label 'Tax';
        TotalLbl: Label 'Total';
        FromCaptionLbl: Label 'From:';
        BillToCaptionLbl: Label 'Bill To:';
        VendorInvoiceNoLbl: Label 'Vendor Invoice No.';

    /// <summary>
    /// Sets the data for the report from temporary tables.
    /// </summary>
    internal procedure SetData(var TempHeader: Record "E-Document Purchase Header" temporary; var TempLine: Record "E-Document Purchase Line" temporary)
    begin
        Header.Copy(TempHeader, true);
        Line.Copy(TempLine, true);
    end;

    local procedure FormatAddressFields(var EDocPurchHeader: Record "E-Document Purchase Header")
    var
        Vendor: Record Vendor;
    begin
        CompanyInfo.Get();
        FormatAddr.GetCompanyAddr('', RespCenter, CompanyInfo, CompanyAddr);
        Vendor.Get(EDocPurchHeader."[BC] Vendor No.");
        FormatAddr.FormatAddr(
            VendAddr, Vendor.Name, '', Vendor.Contact, Vendor.Address, Vendor."Address 2", Vendor.City, Vendor."Post Code", Vendor.County, Vendor."Country/Region Code");
    end;
}
