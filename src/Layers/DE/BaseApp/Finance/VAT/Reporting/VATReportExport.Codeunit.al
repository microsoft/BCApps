// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.IO;
using System.Utilities;

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
        Text002: Label 'You cannot export already submitted report. Reopen report first.';
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
            VATReportHeader.Status::Exported:
                ExportReleased(VATReportHeader);
            VATReportHeader.Status::Submitted:
                Error(Text002);
        end;
    end;

    local procedure ExportOpen(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);

        if Confirm(Text001, true) then begin
            VATReportReleaseReopen.Release(VATReportHeader);
            ExportReleased(VATReportHeader);
        end;
    end;

    local procedure ExportReleased(VATReportHeader: Record "VAT Report Header")
    begin
        ExportVIESELMAReport(VATReportHeader);
    end;

    procedure CreateVIESELMAXml(VATReportHeader: Record "VAT Report Header"; var FileID: Text; var TempBlob: Codeunit "Temp Blob")
    var
        VIESELMAXml: Codeunit "VIES ELMA Xml";
    begin
        VIESELMAXml.Create(VATReportHeader, FileID, TempBlob);
    end;

#if not CLEAN29
    [Obsolete('Use the overload that returns FileID instead.', '29.0')]
    procedure CreateVIESELMAXml(VATReportHeader: Record "VAT Report Header"; var TempBlob: Codeunit "Temp Blob")
    var
        FileID: Text;
    begin
        CreateVIESELMAXml(VATReportHeader, FileID, TempBlob);
    end;
#endif

    procedure GetVIESELMAFileName(VATReportHeader: Record "VAT Report Header"; FileID: Text): Text
    var
        VIESELMAXml: Codeunit "VIES ELMA Xml";
    begin
        exit(VIESELMAXml.MakeFileName(VATReportHeader, FileID));
    end;

#if not CLEAN29
    [Obsolete('Use the overload with explicit FileID parameter instead.', '29.0')]
    procedure GetVIESELMAFileName(VATReportHeader: Record "VAT Report Header"): Text
    var
        VIESELMAXml: Codeunit "VIES ELMA Xml";
    begin
        exit(VIESELMAXml.MakeFileName(VATReportHeader));
    end;
#endif

    local procedure ExportVIESELMAReport(VATReportHeader: Record "VAT Report Header")
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        XmlInStream: InStream;
        FileName: Text;
        FileID: Text;
    begin
        CreateVIESELMAXml(VATReportHeader, FileID, TempBlob);
        TempBlob.CreateInStream(XmlInStream);
        FileName := GetVIESELMAFileName(VATReportHeader, FileID);
        FileMgt.DownloadFromStreamHandler(XmlInStream, '', '', '', FileName);
    end;

#if not CLEAN28
    local procedure ExportLegacyReport(VATReportHeader: Record "VAT Report Header")
    var
        VATReportHeader2: Record "VAT Report Header";
    begin
        VATReportHeader2.Copy(VATReportHeader);
        VATReportHeader2.SetRange("No.", VATReportHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Export VIES Report", true, false, VATReportHeader2);
    end;

    /// <summary>
    /// Exports VAT report using the legacy report format based on current status with automatic release if needed.
    /// </summary>
    /// <param name="VATReportHeader">VAT report to export</param>
    internal procedure ExportLegacy(VATReportHeader: Record "VAT Report Header")
    begin
        case VATReportHeader.Status of
            VATReportHeader.Status::Open:
                ExportLegacyOpen(VATReportHeader);
            VATReportHeader.Status::Released:
                ExportLegacyReport(VATReportHeader);
            VATReportHeader.Status::Exported:
                ExportLegacyReport(VATReportHeader);
            VATReportHeader.Status::Submitted:
                Error(Text002);
        end;
    end;

    local procedure ExportLegacyOpen(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);

        if Confirm(Text001, true) then begin
            VATReportReleaseReopen.Release(VATReportHeader);
            ExportLegacyReport(VATReportHeader);
        end;
    end;
#endif
}

