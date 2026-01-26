// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.FinanceCharge;

codeunit 10613 "E-Invoice Check Fin. Chrg.Memo"
{
    TableNo = "Finance Charge Memo Header";

    trigger OnRun()
    begin
        if Rec."E-Invoice" then begin
            ReadCompanyInfo();
            ReadGLSetup();

            Rec."Currency Code" := EInvoiceDocumentEncode.GetEInvoiceCurrencyCode(Rec."Currency Code");

            CompanyInfo.TestField(Name);
            CompanyInfo.TestField(Address);
            CompanyInfo.TestField(City);
            CompanyInfo.TestField("Post Code");
            CompanyInfo.TestField("Country/Region Code");
            EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(CompanyInfo."Country/Region Code");

            CompanyInfo.TestField("VAT Registration No.");

            Rec.TestField(Name);
            Rec.TestField(Address);
            Rec.TestField(City);
            Rec.TestField("Post Code");
            Rec.TestField("Country/Region Code");
            EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(Rec."Country/Region Code");
            Rec.TestField("VAT Registration No.");
            Rec.TestField("Your Reference");

            CheckFinChargeMemoLines(Rec);
        end;
    end;

    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
        CompanyInfoRead: Boolean;
        GLSetupRead: Boolean;
        EmptyDescErr: Label 'The Finance Charge Memo %1 contains lines in which the Type and the No. are specified, but the Description is empty. This is not allowed for an E-Invoice document which might be created from the posted document.';
        EmptyFieldsQst: Label 'The Finance Charge Memo %1 contains lines in which either the Type or the No. is empty. Lines that contain these empty fields are not taken into account when you create an E-Invoice document. Do you want to continue?';
        InterruptedIssuanceErr: Label 'The issuance of the document has been interrupted.';

    local procedure ReadCompanyInfo()
    begin
        if not CompanyInfoRead then begin
            CompanyInfo.Get();
            CompanyInfoRead := true;
        end;
    end;

    local procedure ReadGLSetup()
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
    end;

    local procedure CheckFinChargeMemoLines(FinChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        FinChargeMemoLine: Record "Finance Charge Memo Line";
        EmptyLineFound: Boolean;
    begin
        EmptyLineFound := false;
        FinChargeMemoLine.Reset();
        FinChargeMemoLine.SetRange("Finance Charge Memo No.", FinChargeMemoHeader."No.");
        if FinChargeMemoLine.FindSet() then
            repeat
                if FinChargeMemoLine.Description = '' then
                    if (FinChargeMemoLine.Type <> FinChargeMemoLine.Type::" ") and (FinChargeMemoLine."No." <> '') then
                        Error(EmptyDescErr, FinChargeMemoLine."Finance Charge Memo No.");
                if (FinChargeMemoLine.Type = FinChargeMemoLine.Type::" ") or (FinChargeMemoLine."No." = '') then
                    EmptyLineFound := true;
            until (FinChargeMemoLine.Next() = 0);

        if EmptyLineFound then
            if not Confirm(EmptyFieldsQst, true, FinChargeMemoLine."Finance Charge Memo No.") then
                Error(InterruptedIssuanceErr);
    end;
}

