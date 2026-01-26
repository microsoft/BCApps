// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using Microsoft.Service.Document;

codeunit 10623 "E-Invoice Check Serv. Document"
{
    TableNo = "Service Header";

    trigger OnRun()
    var
        ResponsibilityCenter: Record "Responsibility Center";
        Customer: Record Customer;
    begin
        if not Rec."E-Invoice" then
            exit;

        ReadCompanyInfo();
        ReadGLSetup();

        EInvoiceDocumentEncode.GetEInvoiceCurrencyCode(Rec."Currency Code");

        if Rec."Responsibility Center" <> '' then begin
            ResponsibilityCenter.Get(Rec."Responsibility Center");
            ResponsibilityCenter.TestField(Name);
            ResponsibilityCenter.TestField(Address);
            ResponsibilityCenter.TestField(City);
            ResponsibilityCenter.TestField("Post Code");
            ResponsibilityCenter.TestField("Country/Region Code");
        end else begin
            CompanyInfo.TestField(Name);
            CompanyInfo.TestField(Address);
            CompanyInfo.TestField(City);
            CompanyInfo.TestField("Post Code");
        end;
        CompanyInfo.TestField("Country/Region Code");
        EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(CompanyInfo."Country/Region Code");

        CompanyInfo.TestField("VAT Registration No.");

        Rec.TestField("Bill-to Name");
        Rec.TestField("Bill-to Address");
        Rec.TestField("Bill-to City");
        Rec.TestField("Bill-to Post Code");
        Rec.TestField("Bill-to Country/Region Code");
        EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(Rec."Bill-to Country/Region Code");
        if (Rec."Document Type" in [Rec."Document Type"::Invoice, Rec."Document Type"::Order, Rec."Document Type"::"Credit Memo"]) and
           Customer.Get(Rec."Bill-to Customer No.")
        then
            Customer.TestField("VAT Registration No.");

        if Rec."Document Type" = Rec."Document Type"::"Credit Memo" then
            if Rec."Applies-to Doc. Type" = Rec."Applies-to Doc. Type"::Invoice then
                Rec.TestField("Applies-to Doc. No.")
            else
                if Rec."External Document No." = '' then
                    Error(MissingExternalDocNumberErr, Rec."Document Type");

        Rec.TestField("VAT Registration No.");
        Rec.TestField("Your Reference");
        Rec.TestField("Ship-to Address");
        Rec.TestField("Ship-to City");
        Rec.TestField("Ship-to Post Code");
        Rec.TestField("Ship-to Country/Region Code");
        EInvoiceDocumentEncode.GetEInvoiceCountryRegionCode(Rec."Ship-to Country/Region Code");
        Rec.TestField("Due Date");

        if CompanyInfo.IBAN = '' then
            CompanyInfo.TestField("Bank Account No.");
        CompanyInfo.TestField("Bank Branch No.");

        CheckServiceLines(Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
        GLSetupRead: Boolean;
        CompanyInfoRead: Boolean;
        EmptyFieldsQst: Label 'The %1 %2 contains lines in which either the Type, the No. or the Description is empty. Lines that contain these empty fields are not taken into account when you create an E-Invoice document. Do you want to continue?', Comment = 'Parameter 1 - document type (Quote,Order,Invoice,Credit Memo), 2 - document number';
        EmptyUnitOfMeasureErr: Label 'The %1 %2 contains lines in which the Unit of Measure is empty. This is not allowed for an E-Invoice document which might be created from the posted document.', Comment = 'Parameter 1 - document type (Quote,Order,Invoice,Credit Memo), 2 - document number';
        MissingDescriptionErr: Label 'The %1 %2 contains lines in which the Type and the No. are specified, but the Description is empty. This is not allowed for an E-Invoice document which might be created from the posted document.', Comment = 'Parameter 1 - document type (Quote,Order,Invoice,Credit Memo), 2 - document number';
        MissingExternalDocNumberErr: Label 'You must specify an External document number in Document Type  = %1.  If you use E-Invoice, this field is required regardless of the value in the External Document No. field of the Service Mgt. Setup table.';
        MissingUnitOfMeasureCodeErr: Label 'You must specify a valid %2 for the %3 for %1.';
        PostingWasInterruptedErr: Label 'The posting has been interrupted.';

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

    local procedure CheckServiceLines(ServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
        UnitOfMeasure: Record "Unit of Measure";
        EmptyLineFound: Boolean;
    begin
        EmptyLineFound := false;
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        if ServiceLine.FindSet() then
            repeat
                if (ServiceLine.Type <> ServiceLine.Type::" ") and (ServiceLine."No." <> '') and (ServiceLine."Unit of Measure" = '') then
                    Error(EmptyUnitOfMeasureErr, ServiceLine."Document Type", ServiceLine."Document No.");
                if ServiceLine.Description = '' then
                    if (ServiceLine.Type <> ServiceLine.Type::" ") and (ServiceLine."No." <> '') then
                        Error(MissingDescriptionErr, ServiceLine."Document Type", ServiceLine."Document No.");
                if (ServiceLine.Type = ServiceLine.Type::" ") or (ServiceLine."No." = '') then
                    EmptyLineFound := true;
                if ServiceLine."Document Type" in [ServiceLine."Document Type"::Invoice, ServiceLine."Document Type"::Order, ServiceLine."Document Type"::"Credit Memo"] then begin
                    ServiceLine.TestField("Unit of Measure Code");
                    UnitOfMeasure.Get(ServiceLine."Unit of Measure Code");
                    if UnitOfMeasure."International Standard Code" = '' then
                        Error(
                          MissingUnitOfMeasureCodeErr, ServiceLine."Unit of Measure Code", UnitOfMeasure.FieldCaption("International Standard Code"),
                          UnitOfMeasure.TableCaption());
                end;
            until (ServiceLine.Next() = 0);

        if EmptyLineFound then
            if not Confirm(EmptyFieldsQst, true, ServiceLine."Document Type", ServiceLine."Document No.") then
                Error(PostingWasInterruptedErr);
    end;
}

