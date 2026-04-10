// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Utilities;

/// <summary>
/// Manages VAT report status transitions between open, released, and submitted states.
/// Provides validation and state change operations for VAT report workflow management.
/// </summary>
codeunit 741 "VAT Report Release/Reopen"
{

    trigger OnRun()
    begin
    end;

    /// <summary>
    /// Releases VAT report from open to released status with validation.
    /// Runs configured validation codeunit before changing status.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header to release</param>
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

    /// <summary>
    /// Reopens released VAT report back to open status for modifications.
    /// Validates report can be reopened before changing status.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header to reopen</param>
    procedure Reopen(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.CheckIfCanBeReopened(VATReportHeader);

        VATReportHeader.Status := VATReportHeader.Status::Open;
        VATReportHeader.Modify();
    end;

    /// <summary>
    /// Submits released VAT report to submitted status for tax authority processing.
    /// Validates report can be submitted before changing status.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header to submit</param>
    procedure Submit(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.CheckIfCanBeSubmitted();

        VATReportHeader.Status := VATReportHeader.Status::Submitted;
        VATReportHeader.Modify();
    end;

    /// <summary>
    /// Integration event raised before VAT report validation during release process.
    /// Allows custom validation logic to be added before standard validation.
    /// </summary>
    /// <param name="VATReportHeader">VAT report header being validated</param>
    /// <param name="IsValidated">Set to true to skip standard validation</param>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidate(var VATReportHeader: Record "VAT Report Header"; var IsValidated: Boolean)
    begin
    end;
}

