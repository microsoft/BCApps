// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Attachment;

/// <summary>
/// Orchestrates VAT report operations by routing requests to appropriate configuration-defined codeunits.
/// Provides centralized control over VAT report lifecycle including line generation, export, submission, and response handling.
/// </summary>
codeunit 740 "VAT Report Mediator"
{

    trigger OnRun()
    begin
    end;

    var
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
#pragma warning disable AA0074
        Text001: Label 'This action will also mark the report as released. Are you sure you want to continue?';
#pragma warning restore AA0074

    /// <summary>
    /// Generates VAT statement lines for the report using configured suggest lines codeunit.
    /// Validates report is open and routes to appropriate line generation logic.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to generate lines for</param>
    procedure GetLines(VATReportHeader: Record "VAT Report Header")
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
        VATReportHeader.TestOriginalReportNo();

        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);

        VATReportHeader.FilterGroup(2);
        VATReportHeader.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        CODEUNIT.Run(VATReportsConfiguration."Suggest Lines Codeunit ID", VATReportHeader);
    end;

    /// <summary>
    /// Generates VAT report content using configured content codeunit.
    /// Creates formatted output for printing or electronic submission.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to generate content for</param>
    procedure Generate(VATReportHeader: Record "VAT Report Header")
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        VATReportsConfiguration.TestField("Content Codeunit ID");
        CODEUNIT.Run(VATReportsConfiguration."Content Codeunit ID", VATReportHeader);
    end;

    /// <summary>
    /// Determines if Generate action should be visible for the VAT report.
    /// Checks configuration for content codeunit without submission codeunit.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to check visibility for</param>
    /// <returns>True if Generate action should be shown</returns>
    procedure ShowGenerate(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        exit((VATReportsConfiguration."Content Codeunit ID" <> 0) and (VATReportsConfiguration."Submission Codeunit ID" = 0));
    end;

    /// <summary>
    /// Exports VAT report using configured content and submission codeunits.
    /// Handles both content generation and electronic submission processes.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to export</param>
    procedure Export(VATReportHeader: Record "VAT Report Header")
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        if VATReportsConfiguration."Content Codeunit ID" <> 0 then
            CODEUNIT.Run(VATReportsConfiguration."Content Codeunit ID", VATReportHeader);
        if VATReportsConfiguration."Submission Codeunit ID" <> 0 then
            CODEUNIT.Run(VATReportsConfiguration."Submission Codeunit ID", VATReportHeader);
    end;

    /// <summary>
    /// Determines if Export action should be visible for the VAT report.
    /// Checks configuration for submission codeunit availability.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to check visibility for</param>
    /// <returns>True if Export action should be shown</returns>
    procedure ShowExport(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        exit(VATReportsConfiguration."Submission Codeunit ID" <> 0);
    end;

    /// <summary>
    /// Receives and processes responses from tax authority using configured response handler codeunit.
    /// Updates VAT report status based on submission response.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to receive response for</param>
    procedure ReceiveResponse(VATReportHeader: Record "VAT Report Header")
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        VATReportsConfiguration.TestField("Response Handler Codeunit ID");
        CODEUNIT.Run(VATReportsConfiguration."Response Handler Codeunit ID", VATReportHeader);
    end;

    /// <summary>
    /// Determines if Receive Response action should be visible for the VAT report.
    /// Checks report status and response handler configuration.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to check visibility for</param>
    /// <returns>True if Receive Response action should be shown</returns>
    procedure ShowReceiveResponse(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        exit(
          (VATReportHeader.Status = VATReportHeader.Status::Submitted) and
          (VATReportsConfiguration."Response Handler Codeunit ID" <> 0));
    end;

    /// <summary>
    /// Releases VAT report from open to released status with validation.
    /// Delegates to VAT Report Release/Reopen codeunit for processing.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to release</param>
    procedure Release(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportReleaseReopen.Release(VATReportHeader);
    end;

    /// <summary>
    /// Reopens released VAT report back to open status for modifications.
    /// Delegates to VAT Report Release/Reopen codeunit for processing.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to reopen</param>
    procedure Reopen(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportReleaseReopen.Reopen(VATReportHeader);
    end;

    /// <summary>
    /// Prints VAT report based on current status with automatic release if needed.
    /// Routes to appropriate print method based on report status.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to print</param>
    procedure Print(VATReportHeader: Record "VAT Report Header")
    begin
        case VATReportHeader.Status of
            VATReportHeader.Status::Open:
                PrintOpen(VATReportHeader);
            VATReportHeader.Status::Released:
                PrintReleased(VATReportHeader);
            VATReportHeader.Status::Submitted:
                PrintReleased(VATReportHeader);
        end;
    end;

    local procedure PrintOpen(var VATReportHeader: Record "VAT Report Header")
    var
        VATReportReleaseReopen: Codeunit "VAT Report Release/Reopen";
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
        if Confirm(Text001, true) then begin
            VATReportReleaseReopen.Release(VATReportHeader);
            PrintReleased(VATReportHeader);
        end
    end;

    local procedure PrintReleased(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        REPORT.RunModal(REPORT::"VAT Report Print", false, false, VATReportHeader);
    end;

    /// <summary>
    /// Submits released VAT report to submitted status for tax authority processing.
    /// Delegates to VAT Report Release/Reopen codeunit for status management.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to submit</param>
    procedure Submit(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportReleaseReopen.Submit(VATReportHeader);
    end;

    /// <summary>
    /// Determines if submission message should be displayed based on report status and attachments.
    /// Checks for existing submission attachments and configuration settings.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to check submission message visibility for</param>
    /// <returns>True if submission message should be shown</returns>
    procedure ShowSubmissionMessage(VATReportHeader: Record "VAT Report Header") ShowSubmissionMessage: Boolean
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
        DocumentAttachment: Record "Document Attachment";
    begin
        if DocumentAttachment.VATReturnSubmissionAttachmentsExist(VATReportHeader) then
            exit(true);
        GetVATReportConfiguration(VATReportsConfiguration, VATReportHeader);
        if VATReportsConfiguration."Submission Codeunit ID" = 0 then
            ShowSubmissionMessage := VATReportHeader.Status = VATReportHeader.Status::Released
        else
            ShowSubmissionMessage := (VATReportHeader.Status = VATReportHeader.Status::Submitted) or
              (VATReportHeader.Status = VATReportHeader.Status::Rejected) or
              (VATReportHeader.Status = VATReportHeader.Status::Accepted) or
              (VATReportHeader.Status = VATReportHeader.Status::Closed);
        exit(ShowSubmissionMessage);
    end;

    /// <summary>
    /// Retrieves VAT report configuration based on report type and version.
    /// Applies filters and finds matching configuration record for report processing.
    /// </summary>
    /// <param name="VATReportsConfiguration">Configuration record to populate</param>
    /// <param name="VATReportHeader">VAT report header to get configuration for</param>
    procedure GetVATReportConfiguration(var VATReportsConfiguration: Record "VAT Reports Configuration"; VATReportHeader: Record "VAT Report Header")
    begin
        if VATReportHeader."VAT Report Config. Code" in
            [VATReportHeader."VAT Report Config. Code"::"VAT Return", VATReportHeader."VAT Report Config. Code"::"EC Sales List"]
        then
            VATReportsConfiguration.SetRange("VAT Report Type", VATReportHeader."VAT Report Config. Code");
        if VATReportHeader."VAT Report Version" <> '' then
            VATReportsConfiguration.SetRange("VAT Report Version", VATReportHeader."VAT Report Version");
        OnGetVATReportConfigurationOnAfterVATReportsConfigurationSetFilters(VATReportsConfiguration, VATReportHeader);
        VATReportsConfiguration.FindFirst();
    end;

    /// <summary>
    /// Integration event raised after setting filters on VAT reports configuration.
    /// Allows customization of configuration filtering logic for specific scenarios.
    /// </summary>
    /// <param name="VATReportsConfiguration">VAT reports configuration with filters applied</param>
    /// <param name="VATReportHeader">VAT report header being processed</param>
    [IntegrationEvent(false, false)]
    local procedure OnGetVATReportConfigurationOnAfterVATReportsConfigurationSetFilters(var VATReportsConfiguration: Record "VAT Reports Configuration"; VATReportHeader: Record "VAT Report Header")
    begin
    end;
}

