// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Foundation.Company;
using Microsoft.Service.History;
using Microsoft.Service.Setup;

codeunit 10625 "E-Invoice Check Serv. Cr. Memo"
{
    TableNo = "Service Cr.Memo Header";

    trigger OnRun()
    var
        EInvoiceCheckCommon: Codeunit "E-Invoice Check Common";
    begin
        CheckCompanyInfo();
        CheckServiceMgtSetup();
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

    local procedure CheckServiceMgtSetup()
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        ServiceMgtSetup.Get();

        ServiceMgtSetup."E-Invoice Serv. Cr. Memo Path" := DelChr(ServiceMgtSetup."E-Invoice Serv. Cr. Memo Path", '>', '\');
        ServiceMgtSetup.TestField("E-Invoice Serv. Cr. Memo Path");
    end;
}

