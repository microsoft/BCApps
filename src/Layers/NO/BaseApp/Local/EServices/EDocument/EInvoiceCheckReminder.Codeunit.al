// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Sales.Reminder;

codeunit 10614 "E-Invoice Check Reminder"
{
    TableNo = "Reminder Header";

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

            CheckReminderLines(Rec);
        end;
    end;

    var
        CompanyInfo: Record "Company Information";
        GLSetup: Record "General Ledger Setup";
        EInvoiceDocumentEncode: Codeunit "E-Invoice Document Encode";
        GLSetupRead: Boolean;
        CompanyInfoRead: Boolean;
        EmptyDescErr: Label 'The Reminder %1 contains lines in which the Type and the No. are specified, but the Description is empty. This is not allowed for an E-Invoice document which might be created from the posted document.';
        EmptyFieldsQst: Label 'The Reminder %1 contains lines in which either the Type or the No. is empty. Lines that contain these empty fields are not taken into account when you create an E-Invoice document. Do you want to continue?';
        InterruptedIssuanceErr: Label 'The issuing has been interrupted to respect the warning.';

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

    local procedure CheckReminderLines(ReminderHeader: Record "Reminder Header")
    var
        ReminderLine: Record "Reminder Line";
        EmptyLineFound: Boolean;
    begin
        EmptyLineFound := false;
        ReminderLine.Reset();
        ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        if ReminderLine.FindSet() then
            repeat
                if ReminderLine.Description = '' then
                    if (ReminderLine.Type <> ReminderLine.Type::" ") and (ReminderLine."No." <> '') then
                        Error(EmptyDescErr, ReminderLine."Reminder No.");
                if (ReminderLine.Type = ReminderLine.Type::" ") or (ReminderLine."No." = '') then
                    EmptyLineFound := true;
            until (ReminderLine.Next() = 0);

        if EmptyLineFound then
            if not Confirm(EmptyFieldsQst, true, ReminderLine."Reminder No.") then
                Error(InterruptedIssuanceErr);
    end;
}

