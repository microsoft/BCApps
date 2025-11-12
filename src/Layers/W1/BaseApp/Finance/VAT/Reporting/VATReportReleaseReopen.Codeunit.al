// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Utilities;

codeunit 741 "VAT Report Release/Reopen"
{

    trigger OnRun()
    begin
    end;

    procedure Release(var VATReportHeader: Record "VAT Report Header")
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
        ErrorMessage: Record "Error Message";
        IsValidated: Boolean;
    begin
        VATReportHeader.CheckIfCanBeReleased(VATReportHeader);

        ErrorMessage.SetContext(VATReportHeader);
        ErrorMessage.ClearLog();

        IsValidated := false;
        OnBeforeValidate(VATReportHeader, IsValidated);
        if not IsValidated then begin
            VATReportsConfiguration.SetRange("VAT Report Type", VATReportHeader."VAT Report Config. Code");
            if VATReportHeader."VAT Report Version" <> '' then
                VATReportsConfiguration.SetRange("VAT Report Version", VATReportHeader."VAT Report Version");
            if VATReportsConfiguration.FindFirst() and (VATReportsConfiguration."Validate Codeunit ID" <> 0) then
                CODEUNIT.Run(VATReportsConfiguration."Validate Codeunit ID", VATReportHeader)
            else
                CODEUNIT.Run(CODEUNIT::"VAT Report Validate", VATReportHeader);
        end;

        if ErrorMessage.HasErrors(false) then
            exit;

        VATReportHeader.Status := VATReportHeader.Status::Released;
        VATReportHeader.Modify();
    end;

    procedure Reopen(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.CheckIfCanBeReopened(VATReportHeader);

        VATReportHeader.Status := VATReportHeader.Status::Open;
        VATReportHeader.Modify();
    end;

    procedure Submit(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.CheckIfCanBeSubmitted();

        VATReportHeader.Status := VATReportHeader.Status::Submitted;
        VATReportHeader.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidate(var VATReportHeader: Record "VAT Report Header"; var IsValidated: Boolean)
    begin
    end;
}

