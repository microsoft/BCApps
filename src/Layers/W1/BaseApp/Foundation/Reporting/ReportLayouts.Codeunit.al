// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Shared.Report;

using System.Reflection;
using System.Utilities;

/// <summary>
/// Exposes the report layout functionality of the Report Layouts page to extensions. None of the procedures show messages or dialogs.
/// </summary>
codeunit 9661 "Report Layouts"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ReportLayoutsImpl: Codeunit "Report Layouts Impl.";

    /// <summary>
    /// Sets the report layout as the default layout of its report in the current company.
    /// Updates both the Tenant Report Layout Selection and the Report Layout Selection tables.
    /// </summary>
    /// <param name="ReportLayoutList">The report layout to set as default.</param>
    /// <error>The layout is a theme or header/footer part. Parts are assigned to reports through the report layout configuration and cannot be selected as a report layout.</error>
    procedure SetDefaultReportLayoutSelection(ReportLayoutList: Record "Report Layout List")
    begin
        ReportLayoutsImpl.ErrorIfLayoutIsCompositePart(ReportLayoutList);
        ReportLayoutsImpl.SetSelectedCompany(CompanyName());
        ReportLayoutsImpl.SetDefaultReportLayoutSelection(ReportLayoutList, false);
    end;

    /// <summary>
    /// Converts the layout format of a Report Layout List record to the corresponding Type option of the Report Layout Selection table.
    /// </summary>
    /// <param name="LayoutFormat">The layout format from the Report Layout List table.</param>
    /// <returns>The corresponding Type of the Report Layout Selection table.</returns>
    procedure GetReportLayoutSelectionTypeFromReportLayoutListLayoutFormat(LayoutFormat: Option RDLC,Word,Excel,Custom): Option "RDLC (built-in)","Word (built-in)","Custom Layout","Excel Layout","External Layout"
    begin
        exit(ReportLayoutsImpl.GetReportLayoutSelectionCorrespondingEnum(LayoutFormat));
    end;

    /// <summary>
    /// Adds or updates the selection of the report layout in the Tenant Report Layout Selection table for the current company.
    /// </summary>
    /// <param name="ReportLayoutList">The report layout to select.</param>
    /// <error>The layout is a theme or header/footer part. Parts are assigned to reports through the report layout configuration and cannot be selected as a report layout.</error>
    procedure AddLayoutSelection(ReportLayoutList: Record "Report Layout List")
    begin
        ReportLayoutsImpl.ErrorIfLayoutIsCompositePart(ReportLayoutList);
        ReportLayoutsImpl.SetSelectedCompany(CompanyName());
        ReportLayoutsImpl.AddLayoutSelection(ReportLayoutList);
    end;

    /// <summary>
    /// Adds or updates the selection of the report layout in the Tenant Report Layout Selection table for a user in the current company.
    /// </summary>
    /// <param name="ReportLayoutList">The report layout to select.</param>
    /// <param name="ForUserId">The security ID of the user that the layout is selected for.</param>
    /// <error>The layout is a theme or header/footer part. Parts are assigned to reports through the report layout configuration and cannot be selected as a report layout.</error>
    procedure AddLayoutSelection(ReportLayoutList: Record "Report Layout List"; ForUserId: Guid)
    begin
        ReportLayoutsImpl.ErrorIfLayoutIsCompositePart(ReportLayoutList);
        ReportLayoutsImpl.SetSelectedCompany(CompanyName());
        ReportLayoutsImpl.AddLayoutSelection(ReportLayoutList, ForUserId);
    end;

    /// <summary>
    /// Exports a report layout to a Temp Blob.
    /// </summary>
    /// <param name="ReportLayoutList">The report layout to export.</param>
    /// <param name="UpdateOnExport">Specifies whether the layout is updated to the current report dataset before it is exported.</param>
    /// <param name="LayoutTempBlob">Returns the exported layout.</param>
    /// <returns>False if the update was requested but could not be applied. LayoutTempBlob then contains the original layout.</returns>
    procedure ExportReportLayout(ReportLayoutList: Record "Report Layout List"; UpdateOnExport: Boolean; var LayoutTempBlob: Codeunit "Temp Blob"): Boolean
    begin
        exit(ReportLayoutsImpl.ExportReportLayout(ReportLayoutList, UpdateOnExport, LayoutTempBlob));
    end;

    /// <summary>
    /// Validates a report layout. RDLC, Word and Excel layouts are validated against the report.
    /// For other layout formats the OnValidateReportLayoutOnCaseElse event is raised so that subscribers can validate the layout.
    /// A layout that passes is then checked for theme and header/footer parts that are missing or obsolete.
    /// </summary>
    /// <param name="ReportLayoutList">The report layout to validate.</param>
    /// <param name="ValidationMessage">Empty when the layout is valid, the theme and header/footer part warnings when it is valid with warnings, and the reason otherwise.</param>
    /// <returns>The result of the validation.</returns>
    procedure ValidateReportLayout(ReportLayoutList: Record "Report Layout List"; var ValidationMessage: Text): Enum "Layout Validation Result"
    begin
        exit(ReportLayoutsImpl.ValidateReportLayout(ReportLayoutList, ValidationMessage));
    end;

    /// <summary>
    /// Raised when a report layout is validated whose layout format is not RDLC, Word or Excel.
    /// Subscribers can validate the layout formats they own.
    /// </summary>
    /// <param name="ReportLayoutList">The report layout that is validated.</param>
    /// <param name="ValidationResult">Set to the result of the validation.</param>
    /// <param name="ValidationMessage">Set to the reason when the layout is not valid.</param>
    /// <param name="IsHandled">Set to true when the subscriber validated the layout.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnValidateReportLayoutOnCaseElse(ReportLayoutList: Record "Report Layout List"; var ValidationResult: Enum "Layout Validation Result"; var ValidationMessage: Text; var IsHandled: Boolean)
    begin
    end;
}
