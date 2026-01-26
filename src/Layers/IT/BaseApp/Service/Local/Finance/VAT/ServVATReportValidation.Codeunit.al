// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Service.Document;

codeunit 12193 "Serv. VAT Report Validation"
{
    var
        IncludeinVATReportErrorLog: Record "Incl. in VAT Report Error Log";
        InclInVATReportValidation: Codeunit "Incl. in VAT Report Validation";

        Text005: Label 'You must specify a value for the %1 field in the document header when the %2 field is selected and the %3 field is set to %4.';
        Text006: Label 'You must specify a value for the %1 field in the document header when the %2 field is not selected.';
        Text007: Label 'You must specify a value for the %1 field in the document header when the %2 field is set to %3.';
        Text011: Label 'You cannot select the %1 field when the %2 field is set to %3 and the %4 field is set to %5.';

    procedure ValidateServiceHeader(ServiceHeader: Record "Service Header"; var IncludeVATReportErrorLogParam: Record "Incl. in VAT Report Error Log" temporary)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.Reset();
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetFilter(Quantity, '<>0');
        ServiceLine.SetRange("Include in VAT Transac. Rep.", true);
        if ServiceLine.IsEmpty() then
            exit;

        // Clear Log
        IncludeinVATReportErrorLog.DeleteAll();
        CheckFiscalCodeInServiceHeader(ServiceHeader);
        CheckNRFirstNameInServiceHeader(ServiceHeader);
        CheckNRLastNameInServiceHeader(ServiceHeader);
        CheckNRDOBInServiceHeader(ServiceHeader);
        CheckNRPlaceofBirthInServiceHeader(ServiceHeader);
        CheckNRCountryCodeInServiceHeader(ServiceHeader);
        CheckVATRegistrationNoInServiceHeader(ServiceHeader);

        ServiceLine.FindSet();
        repeat
            CheckIncludeInVATReportInServiceLine(ServiceLine);
        until ServiceLine.Next() = 0;

        if IncludeinVATReportErrorLog.FindSet() then
            repeat
                IncludeVATReportErrorLogParam := IncludeinVATReportErrorLog;
                IncludeVATReportErrorLogParam.Insert();
            until IncludeinVATReportErrorLog.Next() = 0;
    end;

    local procedure CheckIncludeInVATReportInServiceLine(ServiceLine: Record "Service Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.IncludeInVATTransReport(ServiceLine."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group") then
            IncludeinVATReportErrorLog.InsertError(
                DATABASE::"Service Line", ServiceLine.FieldNo("Include in VAT Transac. Rep."),
                StrSubstNo(Text011, ServiceLine.FieldCaption("Include in VAT Transac. Rep."), ServiceLine.FieldCaption("VAT Bus. Posting Group"),
                ServiceLine."VAT Bus. Posting Group", ServiceLine.FieldCaption("VAT Prod. Posting Group"),
                ServiceLine."VAT Prod. Posting Group"), ServiceLine."Line No.");
    end;

    local procedure CheckFiscalCodeInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Individual Person" and (ServiceHeader.Resident = ServiceHeader.Resident::Resident) then
            if ServiceHeader."Fiscal Code" = '' then
                IncludeinVATReportErrorLog.InsertError(
                    DATABASE::"Service Header", ServiceHeader.FieldNo("Fiscal Code"),
                    StrSubstNo(Text005, ServiceHeader.FieldCaption("Fiscal Code"), ServiceHeader.FieldCaption("Individual Person"),
                    ServiceHeader.FieldCaption(Resident), ServiceHeader.Resident), 0);
    end;

    local procedure CheckNRFirstNameInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Individual Person" and (ServiceHeader.Resident = ServiceHeader.Resident::"Non-Resident") then
            if ServiceHeader."First Name" = '' then
                IncludeinVATReportErrorLog.InsertError(
                    DATABASE::"Service Header", ServiceHeader.FieldNo("First Name"),
                    StrSubstNo(Text005, ServiceHeader.FieldCaption("First Name"), ServiceHeader.FieldCaption("Individual Person"),
                    ServiceHeader.FieldCaption(Resident), ServiceHeader.Resident), 0);
    end;

    local procedure CheckNRLastNameInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Individual Person" and (ServiceHeader.Resident = ServiceHeader.Resident::"Non-Resident") then
            if ServiceHeader."Last Name" = '' then
                IncludeinVATReportErrorLog.InsertError(
                    DATABASE::"Service Header", ServiceHeader.FieldNo("Last Name"),
                    StrSubstNo(Text005, ServiceHeader.FieldCaption("Last Name"), ServiceHeader.FieldCaption("Individual Person"),
                    ServiceHeader.FieldCaption(Resident), ServiceHeader.Resident), 0);
    end;

    local procedure CheckNRDOBInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Individual Person" and (ServiceHeader.Resident = ServiceHeader.Resident::"Non-Resident") then
            if ServiceHeader."Date of Birth" = 0D then
                IncludeinVATReportErrorLog.InsertError(
                    DATABASE::"Service Header", ServiceHeader.FieldNo("Date of Birth"),
                    StrSubstNo(Text005, ServiceHeader.FieldCaption("Date of Birth"), ServiceHeader.FieldCaption("Individual Person"),
                    ServiceHeader.FieldCaption(Resident), ServiceHeader.Resident), 0);
    end;

    local procedure CheckNRPlaceofBirthInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader."Individual Person" and (ServiceHeader.Resident = ServiceHeader.Resident::"Non-Resident") then
            if ServiceHeader."Place of Birth" = '' then
                IncludeinVATReportErrorLog.InsertError(
                    DATABASE::"Service Header", ServiceHeader.FieldNo("Place of Birth"),
                    StrSubstNo(Text005, ServiceHeader.FieldCaption("Place of Birth"), ServiceHeader.FieldCaption("Individual Person"),
                    ServiceHeader.FieldCaption(Resident), ServiceHeader.Resident), 0);
    end;

    local procedure CheckNRCountryCodeInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if ServiceHeader.Resident = ServiceHeader.Resident::"Non-Resident" then
            if ServiceHeader."Country/Region Code" = '' then
                IncludeinVATReportErrorLog.InsertError(
                    DATABASE::"Service Header", ServiceHeader.FieldNo("Country/Region Code"),
                    StrSubstNo(Text007, ServiceHeader.FieldCaption("Country/Region Code"), ServiceHeader.FieldCaption(Resident),
                    ServiceHeader.Resident), 0);
    end;

    local procedure CheckVATRegistrationNoInServiceHeader(ServiceHeader: Record "Service Header")
    begin
        if InclInVATReportValidation.IsVATRegNoNeeded(
            ServiceHeader."Country/Region Code", ServiceHeader."Individual Person", ServiceHeader."Tax Representative No.") and
           (ServiceHeader."VAT Registration No." = '')
        then
            IncludeinVATReportErrorLog.InsertError(
                DATABASE::"Service Header", ServiceHeader.FieldNo("VAT Registration No."),
                StrSubstNo(Text006, ServiceHeader.FieldCaption("VAT Registration No."), ServiceHeader.FieldCaption("Individual Person")), 0);
    end;
}