// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Company;
using Microsoft.Purchases.Vendor;
using Microsoft.Utilities;
using System.Utilities;

codeunit 12183 "Datifattura Validate"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    begin
        ErrorMessage.SetContext(Rec);
        ErrorMessage.ClearLog();

        ValidateVATReportHeader(Rec);
        ValidateVATReportLines(Rec);

        if ErrorMessage.HasErrors(false) then
            ErrorMessage.ShowErrorMessages(true);
    end;

    var
        ErrorMessage: Record "Error Message";
        SpesometroAppointmentErr: Label 'Cannot find Spesometro Appointment within the given start and end date.';

    local procedure ValidateVATReportHeader(VATReportHeader: Record "VAT Report Header")
    var
        OrgVATReportHeader: Record "VAT Report Header";
        SpesometroAppointment: Record "Spesometro Appointment";
    begin
        ErrorMessage.LogIfEmpty(VATReportHeader, VATReportHeader.FieldNo("VAT Report Config. Code"), ErrorMessage."Message Type"::Error);

        if VATReportHeader."VAT Report Type" <> VATReportHeader."VAT Report Type"::Standard then
            if ErrorMessage.LogIfEmpty(VATReportHeader, VATReportHeader.FieldNo("Original Report No."), ErrorMessage."Message Type"::Error) =
               0
            then begin
                OrgVATReportHeader.Get(VATReportHeader."Original Report No.");
                ErrorMessage.LogIfEmpty(
                  OrgVATReportHeader, OrgVATReportHeader.FieldNo("Tax Auth. Receipt No."), ErrorMessage."Message Type"::Error);
                ErrorMessage.LogIfEmpty(
                  OrgVATReportHeader, OrgVATReportHeader.FieldNo("Tax Auth. Document No."), ErrorMessage."Message Type"::Error);
            end;

        if not SpesometroAppointment.FindAppointmentByDate(VATReportHeader."Start Date", VATReportHeader."End Date") then
            ErrorMessage.LogMessage(
              VATReportHeader, VATReportHeader.FieldNo("Start Date"), ErrorMessage."Message Type"::Warning, SpesometroAppointmentErr);
    end;

    local procedure ValidateVATReportLines(VATReportHeader: Record "VAT Report Header")
    var
        VATReportLine: Record "VAT Report Line";
    begin
        CheckCompanyInfo();

        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.SetRange("Incl. in Report", true);
        if VATReportLine.FindSet() then
            repeat
                ValidateVATReportLine(VATReportLine);
            until VATReportLine.Next() = 0
    end;

    local procedure ValidateVATReportLine(var VATReportLine: Record "VAT Report Line")
    begin
        ErrorMessage.LogIfEmpty(VATReportLine, VATReportLine.FieldNo("Posting Date"), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(VATReportLine, VATReportLine.FieldNo("Document No."), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(VATReportLine, VATReportLine.FieldNo("Bill-to/Pay-to No."), ErrorMessage."Message Type"::Error);
        if VATReportLine.Amount = 0 then
            ErrorMessage.LogIfEmpty(VATReportLine, VATReportLine.FieldNo("VAT Transaction Nature"), ErrorMessage."Message Type"::Error);

        OnAfterValidateVATReportLine(VATReportLine, ErrorMessage);
    end;

    local procedure CheckCompanyInfo()
    var
        CompanyInfo: Record "Company Information";
        Vendor: Record Vendor;
    begin
        CompanyInfo.Get();

        // validate tax details for the company
        ErrorMessage.LogIfEmpty(CompanyInfo, CompanyInfo.FieldNo("VAT Registration No."), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(CompanyInfo, CompanyInfo.FieldNo("Fiscal Code"), ErrorMessage."Message Type"::Warning);

        // validate company address
        ErrorMessage.LogIfEmpty(CompanyInfo, CompanyInfo.FieldNo(Address), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(CompanyInfo, CompanyInfo.FieldNo(City), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(CompanyInfo, CompanyInfo.FieldNo(County), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(CompanyInfo, CompanyInfo.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);

        // validate if the company has a tax representative, then all values exists
        if CompanyInfo."Tax Representative No." = '' then
            exit;

        if not Vendor.Get(CompanyInfo."Tax Representative No.") then
            exit;

        ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("Country/Region Code"), ErrorMessage."Message Type"::Error);
        ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("VAT Registration No."), ErrorMessage."Message Type"::Error);
        if not Vendor."Individual Person" then
            ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo(Name), ErrorMessage."Message Type"::Error)
        else begin
            ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("First Name"), ErrorMessage."Message Type"::Error);
            ErrorMessage.LogIfEmpty(Vendor, Vendor.FieldNo("Last Name"), ErrorMessage."Message Type"::Error);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateVATReportLine(VATReportLine: Record "VAT Report Line"; var ErrorMessage: Record "Error Message")
    begin
    end;
}

