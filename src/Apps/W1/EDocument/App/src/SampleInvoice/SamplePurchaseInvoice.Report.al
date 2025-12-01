// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Location;

/// <summary>
/// Report for generating sample purchase invoice PDFs using temporary tables.
/// This report is independent from the standard Purchase - Invoice report (Report 406).
/// </summary>
report 6102 "Sample Purchase Invoice"
{
    Caption = 'Sample Purchase Invoice';
    DefaultLayout = Word;
    WordLayout = './src/SampleInvoice/SamplePurchInvoice.docx';

    dataset
    {
        dataitem(Header; "Sample Purch. Inv. Header")
        {
            UseTemporary = true;
            column(No_; "No.")
            {
            }
            column(InvoiceCaption; InvoiceCaptionLbl)
            {
            }
            column(InvoiceNoCaption; InvoiceNoCaptionLbl)
            {
            }
            column(BuyFromVendorNo; "Buy-from Vendor No.")
            {
            }
            column(VendorInvoiceNo_Lbl; VendorInvoiceNoLbl)
            {
            }
            column(VendorInvoiceNo; "Vendor Invoice No.")
            {
            }
            column(PostingDate; "Posting Date")
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
            column(TotalAmountExclVAT; TotalAmount)
            {
            }
            column(VATAmount; VATAmount)
            {
            }
            column(TotalAmountInclVAT; TotalAmtInclVAT)
            {
            }
            dataitem(Line; "Sample Purch. Inv. Line")
            {
                UseTemporary = true;
                DataItemLink = "Document No." = field("No.");
                column(DocumentNo; "Document No.")
                {
                }
                column(LineNo; "Line No.")
                {
                }
                column(Type; Type)
                {
                }
                column(No; "No.")
                {
                }
                column(TaxGroupCode; "Tax Group Code")
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
                column(DirectUnitCost; "Direct Unit Cost")
                {
                }
                column(DirectUnitCostCaption; DirectUnitCostCaptionLbl)
                {
                }
                column(DeferralCode; "Deferral Code")
                {
                }
                column(UOM_PurchLine_Lbl; ItemUnitOfMeasureCaptionLbl)
                {
                }
                column(UnitOfMeasureCode; "Unit of Measure")
                {
                }
                column(LineAmount; Amount)
                {
                }
                column(LineAmountCaption; LineAmountCaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TotalAmount += Line.Amount;
                    VATAmount += Line."Amount Including VAT" - Line.Amount;
                    TotalAmtInclVAT += Line."Amount Including VAT";
                end;
            }

            trigger OnPreDataItem()
            begin
                Header.Copy(TempSamplePurchInvHeader, true);
            end;

            trigger OnAfterGetRecord()
            begin
                FormatAddressFields(Header);
            end;
        }
    }

    var
        TempSamplePurchInvHeader: Record "Sample Purch. Inv. Header" temporary;
        TempSamplePurchInvLine: Record "Sample Purch. Inv. Line" temporary;
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
    /// Sets the data for the report from external temporary tables.
    /// </summary>
    /// <param name="TempHeader">Temporary header record to use.</param>
    /// <param name="TempLines">Temporary line records to use.</param>
    procedure SetData(var TempHeader: Record "Sample Purch. Inv. Header" temporary; var TempLines: Record "Sample Purch. Inv. Line" temporary)
    begin
        TempSamplePurchInvHeader.Copy(TempHeader, true);
        TempSamplePurchInvLine.Copy(TempLines, true);
        Line.Copy(TempSamplePurchInvLine, true);
    end;

    local procedure FormatAddressFields(var SamplePurchInvHeader: Record "Sample Purch. Inv. Header")
    begin
        CompanyInfo.Get();
        FormatAddr.GetCompanyAddr(SamplePurchInvHeader."Responsibility Center", RespCenter, CompanyInfo, CompanyAddr);
        FormatAddr.FormatAddr(
            VendAddr,
            SamplePurchInvHeader."Pay-to Name",
            '',
            SamplePurchInvHeader."Pay-to Contact",
            SamplePurchInvHeader."Pay-to Address",
            SamplePurchInvHeader."Pay-to Address 2",
            SamplePurchInvHeader."Pay-to City",
            SamplePurchInvHeader."Pay-to Post Code",
            SamplePurchInvHeader."Pay-to County",
            SamplePurchInvHeader."Pay-to Country/Region Code");
    end;
}
