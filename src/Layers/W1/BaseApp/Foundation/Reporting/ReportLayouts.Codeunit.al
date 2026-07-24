// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Shared.Report;

using System.Reflection;
using System.Utilities;

codeunit 9661 "Report Layouts"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        ReportLayoutsImpl: Codeunit "Report Layouts Impl.";

    /// <summary>
    /// Sets the specified report layout as the default layout for its report without displaying messages.
    /// Updates both the Tenant Report Layout Selection and Report Layout Selection tables.
    /// </summary>
    /// <param name="ReportLayoutList">The report layout to set as default.</param>
    procedure SetDefaultReportLayoutSelection(ReportLayoutList: Record "Report Layout List")
    begin
        ReportLayoutsImpl.SetSelectedCompany(CompanyName());
        ReportLayoutsImpl.SetDefaultReportLayoutSelection(ReportLayoutList, false);
    end;

    /// <summary>
    /// Converts a Report Layout List layout format option to the corresponding Report Layout Selection type enumeration.
    /// </summary>
    /// <param name="LayoutFormat">The layout format from Report Layout List (RDLC, Word, Excel, or Custom).</param>
    /// <returns>The corresponding Report Layout Selection type option.</returns>
    procedure GetReportLayoutSelectionTypeFromReportLayoutListLayoutFormat(LayoutFormat: Option RDLC,Word,Excel,Custom): Option "RDLC (built-in)","Word (built-in)","Custom Layout","Excel Layout","External Layout"
    begin
        exit(ReportLayoutsImpl.GetReportLayoutSelectionCorrespondingEnum(LayoutFormat));
    end;

    /// <summary>
    /// Adds or updates a report layout selection in the Tenant Report Layout Selection table for the current company.
    /// </summary>
    /// <param name="ReportLayoutList">The report layout to add to the selection.</param>
    procedure AddLayoutSelection(ReportLayoutList: Record "Report Layout List")
    begin
        ReportLayoutsImpl.SetSelectedCompany(CompanyName());
        ReportLayoutsImpl.AddLayoutSelection(ReportLayoutList);
    end;

    /// <summary>
    /// Adds or updates a report layout selection in the Tenant Report Layout Selection table for a specific user.
    /// </summary>
    /// <param name="ReportLayoutList">The report layout to add to the selection.</param>
    /// <param name="ForUserId">The GUID of the user for whom the layout selection is being set.</param>
    procedure AddLayoutSelection(ReportLayoutList: Record "Report Layout List"; ForUserId: Guid)
    begin
        ReportLayoutsImpl.SetSelectedCompany(CompanyName());
        ReportLayoutsImpl.AddLayoutSelection(ReportLayoutList, ForUserId);
    end;

    /// <summary>
    /// Exports a report layout to a temporary BLOB without displaying messages.
    /// </summary>
    /// <param name="ReportLayoutList">The report layout to export.</param>
    /// <param name="UpdateOnExport">Specifies whether to update the layout using the OnBeforeDocumentReady event before exporting.</param>
    /// <param name="LayoutTempBlob">Returns the exported layout content as a temporary BLOB.</param>
    procedure ExportReportLayout(ReportLayoutList: Record "Report Layout List"; UpdateOnExport: Boolean; var LayoutTempBlob: Codeunit "Temp Blob")
    begin
        ReportLayoutsImpl.ExportReportLayout(ReportLayoutList, UpdateOnExport, true, LayoutTempBlob);
    end;

    /// <summary>
    /// Validates a report layout and returns the result without displaying messages.
    /// Performs format-specific validation for RDLC, Word, and Excel layouts.
    /// For custom or unsupported layout formats, triggers the OnValidateLayoutOnElseCase event to allow extension subscribers to provide validation logic.
    /// </summary>
    /// <param name="ReportLayoutList">The report layout to validate.</param>
    /// <param name="ErrorMessage">Returns the validation error message if the layout is invalid.</param>
    /// <returns>True if the layout is valid, false otherwise.</returns>
    procedure ValidateReportLayout(ReportLayoutList: Record "Report Layout List"; var ErrorMessage: Text): Boolean
    begin
        exit(ReportLayoutsImpl.ValidateReportLayout(ReportLayoutList, ErrorMessage));
    end;

    /// <summary>
    /// Integration event raised during report layout validation when the layout format is custom or not one of the standard types (RDLC, Word, Excel).
    /// Subscribers can implement custom validation logic for unsupported layout formats.
    /// </summary>
    /// <param name="ReportLayoutList">The report layout being validated.</param>
    /// <param name="IsValid">Set to true if the layout is valid, false otherwise.</param>
    /// <param name="ErrorMessage">Set to the validation error message if the layout is invalid.</param>
    /// <param name="IsHandled">Set to true if the subscriber handled the validation.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnValidateLayoutOnElseCase(ReportLayoutList: Record "Report Layout List"; var IsValid: Boolean; var ErrorMessage: Text; var IsHandled: Boolean)
    begin
    end;

}