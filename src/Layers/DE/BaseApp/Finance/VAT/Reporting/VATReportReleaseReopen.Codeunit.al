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
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportHeader.CheckIfCanBeSubmitted();

        VATReportHeader.Status := VATReportHeader.Status::Submitted;
        VATReportHeader.Modify();

        UpdateLinesToCorrect(VATReportHeader."No.");

        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATReportLine.SetFilter("Line Type", '%1|%2', VATReportLine."Line Type"::New, VATReportLine."Line Type"::Correction);
        VATReportLine.ModifyAll("Able to Correct Line", true, false);
    end;

    local procedure UpdateLinesToCorrect(VATReportNo: Code[20])
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
        CorrVATReportLine: Record "VAT Report Line";
    begin
        VATReportHeader.Get(VATReportNo);

        if VATReportHeader."Original Report No." <> '' then begin
            CorrVATReportLine.SetRange("VAT Report No.", VATReportNo);
            CorrVATReportLine.SetRange("Line Type", CorrVATReportLine."Line Type"::Correction);
            if CorrVATReportLine.FindSet() then
                repeat
                    VATReportLine.Reset();
                    VATReportLine.SetRange("VAT Report to Correct", VATReportHeader."Original Report No.");
                    VATReportLine.SetRange("Related Line No.", CorrVATReportLine."Related Line No.");
                    VATReportLine.SetRange("Able to Correct Line", true);
                    VATReportLine.ModifyAll("Able to Correct Line", false, false);

                    VATReportLine.Reset();
                    VATReportLine.SetRange("VAT Report No.", VATReportHeader."Original Report No.");
                    VATReportLine.SetRange("Line No.", CorrVATReportLine."Related Line No.");
                    VATReportLine.SetRange("Able to Correct Line", true);
                    VATReportLine.ModifyAll("Able to Correct Line", false, false);
                until CorrVATReportLine.Next() = 0;
        end;
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

