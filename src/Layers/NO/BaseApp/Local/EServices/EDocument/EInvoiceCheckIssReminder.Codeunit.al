// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Company;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Setup;

codeunit 10618 "E-Invoice Check Iss. Reminder"
{
    TableNo = "Issued Reminder Header";

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
        SalesSetup.TestField("E-Invoice Reminder Path");
    end;

    local procedure CheckFinChargeMemoHeader(IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        IssuedReminderHeader.TestField(Name);
        IssuedReminderHeader.TestField(Address);
        IssuedReminderHeader.TestField(City);
        IssuedReminderHeader.TestField("Post Code");
        IssuedReminderHeader.TestField("Country/Region Code");
        EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(IssuedReminderHeader."Country/Region Code");
    end;
}

