// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

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
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
        VATReportHeader.TestOriginalReportNo();

        VATReportHeader.TestField("VAT Report Config. Code");

        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        if VATReportHeader.isDatifattura() then
            Report.RunModal(Report::"Datifattura Suggest Lines", ShowRequestPage(VATReportHeader), false, VATReportHeader)
        else
            Report.RunModal(Report::"VAT Report Suggest Lines", false, false, VATReportHeader);
    end;

    /// <summary>
    /// Exports VAT report using configured content and submission codeunits.
    /// Handles both content generation and electronic submission processes.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to export</param>
    procedure Export(VATReportHeader: Record "VAT Report Header")
    var
        VATReportExport: Codeunit "VAT Report Export";
    begin
        VATReportExport.Export(VATReportHeader);
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
            Commit();
            PrintReleased(VATReportHeader);
        end
    end;

    local procedure PrintReleased(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.SetRange("No.", VATReportHeader."No.");
        if not VATReportHeader.isDatifattura() then
            REPORT.RunModal(REPORT::"VAT Report Print", true, false, VATReportHeader);
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

    local procedure ShowRequestPage(VATReportHeader: Record "VAT Report Header"): Boolean
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        exit(VATReportSetup."Filter Datifattura Lines" and VATReportHeader.isDatifattura())
    end;

    /// <summary>
    /// Retrieves VAT report configuration based on report type and version.
    /// Applies filters and finds matching configuration record for report processing.
    /// </summary>
    /// <param name="VATReportsConfiguration">Configuration record to populate</param>
    /// <param name="VATReportHeader">VAT report header to get configuration for</param>
    procedure GetVATReportConfiguration(var VATReportsConfiguration: Record "VAT Reports Configuration"; VATReportHeader: Record "VAT Report Header")
    begin
        VATReportsConfiguration.SetRange("VAT Report Type", VATReportHeader."VAT Report Config. Code");
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

