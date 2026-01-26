// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Company;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Setup;

codeunit 10617 "E-Invoice Check Iss. Fin.Chrg."
{
    TableNo = "Issued Fin. Charge Memo Header";

    trigger OnRun()
    begin
        CheckCompanyInfo();
        CheckSalesSetup();
        CheckFinChargeMemoHeader(Rec);
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
    end;

    local procedure CheckSalesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.TestField("E-Invoice Fin. Charge Path");
    end;

    local procedure CheckFinChargeMemoHeader(IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    begin
        IssuedFinChargeMemoHeader.TestField(Name);
        IssuedFinChargeMemoHeader.TestField(Address);
        IssuedFinChargeMemoHeader.TestField(City);
        IssuedFinChargeMemoHeader.TestField("Post Code");
        IssuedFinChargeMemoHeader.TestField("Country/Region Code");
        EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(IssuedFinChargeMemoHeader."Country/Region Code");
    end;
}

