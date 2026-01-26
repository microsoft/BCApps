// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Company;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;

codeunit 10616 "E-Invoice Check Sales Cr. Memo"
{
    TableNo = "Sales Cr.Memo Header";

    trigger OnRun()
    var
        EInvoiceCheckCommon: Codeunit "E-Invoice Check Common";
    begin
        CheckCompanyInfo();
        CheckSalesSetup();
        EInvoiceCheckCommon.CheckCurrencyCode(Rec."Currency Code", Rec."No.", Rec."Posting Date");
    end;

    var
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";

    local procedure CheckCompanyInfo()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField(Name);
        CompanyInfo.TestField(Address);
        CompanyInfo.TestField(City);
        CompanyInfo.TestField("Post Code");
        CompanyInfo.TestField("Country/Region Code");
        EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(CompanyInfo."Country/Region Code");

        CompanyInfo.TestField("VAT Registration No.");

        if CompanyInfo.IBAN = '' then
            CompanyInfo.TestField("Bank Account No.");
        CompanyInfo.TestField("Bank Branch No.");
    end;

    local procedure CheckSalesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."E-Invoice Sales Cr. Memo Path" := DelChr(SalesReceivablesSetup."E-Invoice Sales Cr. Memo Path", '>', '\');
        SalesReceivablesSetup.TestField("E-Invoice Sales Cr. Memo Path");
    end;
}

