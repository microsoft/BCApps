// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Provides export functionality for VAT reports with automatic release capability.
/// Handles export operations based on report status and ensures proper workflow progression.
/// </summary>
codeunit 743 "VAT Report Export"
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
    /// Exports VAT report based on current status with automatic release if needed.
    /// Routes to appropriate export method based on report status.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to export</param>
    procedure Export(VATReportHeader: Record "VAT Report Header")
    begin
        case VATReportHeader.Status of
            VATReportHeader.Status::Open:
                ExportOpen(VATReportHeader);
            VATReportHeader.Status::Released:
                ExportReleased(VATReportHeader);
            VATReportHeader.Status::Submitted:
                ExportReleased(VATReportHeader);
        end;
    end;

    local procedure ExportOpen(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);

        if Confirm(Text001, true) then begin
            VATReportReleaseReopen.Release(VATReportHeader);
            ExportReport(VATReportHeader, false);
        end;
    end;

    local procedure ExportReleased(var VATReportHeader: Record "VAT Report Header")
    begin
        ExportReport(VATReportHeader, true);
    end;

    local procedure ExportReport(var VATReportHeader: Record "VAT Report Header"; Validate: Boolean)
    var
        VATReportHeaderLocal: Record "VAT Report Header";
    begin
        if Validate then
            if VATReportHeader.isDatifattura() then
                CODEUNIT.Run(CODEUNIT::"Datifattura Validate", VATReportHeader)
            else
                CODEUNIT.Run(CODEUNIT::"VAT Report Validate", VATReportHeader);

        VATReportHeaderLocal.Copy(VATReportHeader);
        VATReportHeaderLocal.SetRange("No.", VATReportHeader."No.");
        Commit();
        if VATReportHeaderLocal.isDatifattura() then
            CODEUNIT.Run(CODEUNIT::"Datifattura Export", VATReportHeaderLocal)
        else
            REPORT.Run(REPORT::"Export VAT Transactions", true, false, VATReportHeaderLocal);
    end;
}

