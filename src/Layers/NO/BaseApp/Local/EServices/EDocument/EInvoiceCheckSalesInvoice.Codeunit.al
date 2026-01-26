// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Company;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;

codeunit 10615 "E-Invoice Check Sales Invoice"
{
    TableNo = "Sales Invoice Header";

    trigger OnRun()
    var
        EInvoiceCheckCommon: Codeunit "E-Invoice Check Common";
    begin
        CheckCompanyInfo();
        CheckSalesSetup();
        EInvoiceCheckCommon.CheckCurrencyCode(Rec."Currency Code", Rec."No.", Rec."Posting Date");
    end;

    [Scope('OnPrem')]
    procedure CheckCompanyInfo()
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        CompanyInfo.TestField(Name);
        CompanyInfo.TestField(Address);
        CompanyInfo.TestField(City);
        CompanyInfo.TestField("Post Code");
        CompanyInfo.TestField("Country/Region Code");
        CompanyInfo.TestField("VAT Registration No.");
        CompanyInfo.TestField("SWIFT Code");
        if CompanyInfo.IBAN = '' then
            CompanyInfo.TestField("Bank Account No.");
        CompanyInfo.TestField("Bank Branch No.");
    end;

    local procedure CheckSalesSetup()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        // If it's RTC, is there a location for storing the file? If not, don't create the e-invoice
        SalesSetup.Get();
        SalesSetup.TestField("E-Invoice Sales Invoice Path");
    end;
}

