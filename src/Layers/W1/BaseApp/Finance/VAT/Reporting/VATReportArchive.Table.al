// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Attachment;
using System.IO;
using System.Security.AccessControl;
using System.Utilities;

/// <summary>
/// Stores archived VAT report submission and response messages with their associated metadata.
/// Provides long-term storage and retrieval capabilities for VAT report submission and response data.
/// </summary>
table 747 "VAT Report Archive"
{
    Caption = 'VAT Report Archive';
    Permissions = TableData "VAT Report Archive" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Type of VAT report being archived (VAT Return, EC Sales List, etc.).
        /// </summary>
        field(1; "VAT Report Type"; Enum "VAT Report Configuration")
        {
            Caption = 'VAT Report Type';
            ToolTip = 'Specifies if you want to create a new VAT report, or if you want to change a previously submitted report.';
        }
        /// <summary>
        /// Number of the VAT report being archived from the VAT Report Header.
        /// </summary>
        field(2; "VAT Report No."; Code[20])
        {
            Caption = 'VAT Report No.';
            ToolTip = 'Specifies the number of the VAT Report.';
            TableRelation = "VAT Report Header"."No.";
        }
        /// <summary>
        /// User who submitted the VAT report to the tax authorities.
        /// </summary>
        field(4; "Submitted By"; Code[50])
        {
            Caption = 'Submitted By';
            ToolTip = 'Specifies the name of the person who submitted the VAT Report.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Compressed submission message data sent to tax authorities.
        /// </summary>
        field(5; "Submission Message BLOB"; BLOB)
        {
            Caption = 'Submission Message BLOB';
        }
        /// <summary>
        /// Date when the VAT report was submitted to tax authorities.
        /// </summary>
        field(6; "Submittion Date"; Date)
        {
            Caption = 'Submittion Date';
            ToolTip = 'Specifies the date that the VAT Report was submitted.';
        }
        /// <summary>
        /// Compressed response message data received from tax authorities.
        /// </summary>
        field(7; "Response Message BLOB"; BLOB)
        {
            Caption = 'Response Message BLOB';
        }
        /// <summary>
        /// Date and time when response was received from tax authorities.
        /// </summary>
        field(8; "Response Received Date"; DateTime)
        {
            Caption = 'Response Received Date';
            ToolTip = 'Specifies the date when the response was received.';
        }
    }

    keys
    {
        key(Key1; "VAT Report Type", "VAT Report No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        DataCompression: Codeunit "Data Compression";

        NoSubmissionMessageAvailableErr: Label 'The submission message of the report is not available.';
        NoResponseMessageAvailableErr: Label 'The response message of the report is not available.';

    /// <summary>
    /// Archives the submission message for a VAT report with compression and user tracking.
    /// Creates new archive record with submission details and compressed message data.
    /// </summary>
    /// <param name="VATReportTypeValue">VAT report type option value</param>
    /// <param name="VATReportNoValue">VAT report number</param>
    /// <param name="TempBlobSubmissionMessage">Submission message data to archive</param>
    /// <returns>True if archiving succeeded, false if validation failed or record exists</returns>
    procedure ArchiveSubmissionMessage(VATReportTypeValue: Option; VATReportNoValue: Code[20]; TempBlobSubmissionMessage: Codeunit "Temp Blob"): Boolean
    var
        VATReportArchive: Record "VAT Report Archive";
    begin
        if VATReportNoValue = '' then
            exit(false);
        if not TempBlobSubmissionMessage.HasValue() then
            exit(false);
        if VATReportArchive.Get(VATReportTypeValue, VATReportNoValue) then
            exit(false);

        VATReportArchive.Init();
        OnAfterInitVATReportArchive(VATReportArchive, Rec);
        VATReportArchive."VAT Report No." := VATReportNoValue;
        VATReportArchive."VAT Report Type" := "VAT Report Configuration".FromInteger(VATReportTypeValue);
        VATReportArchive."Submitted By" := UserId;
        VATReportArchive."Submittion Date" := Today;
        VATReportArchive.SetSubmissionMessageBLOBFromBlob(TempBlobSubmissionMessage);
        VATReportArchive.Insert(true);
        exit(true);
    end;

    /// <summary>
    /// Archives the response message received from tax authorities for an existing VAT report submission.
    /// Updates existing archive record with response data and timestamp.
    /// </summary>
    /// <param name="VATReportTypeValue">VAT report type option value</param>
    /// <param name="VATReportNoValue">VAT report number</param>
    /// <param name="TempBlobResponseMessage">Response message data to archive</param>
    /// <returns>True if archiving succeeded, false if archive record not found or no response data</returns>
    procedure ArchiveResponseMessage(VATReportTypeValue: Option; VATReportNoValue: Code[20]; TempBlobResponseMessage: Codeunit "Temp Blob"): Boolean
    var
        VATReportArchive: Record "VAT Report Archive";
    begin
        if not VATReportArchive.Get(VATReportTypeValue, VATReportNoValue) then
            exit(false);
        if not TempBlobResponseMessage.HasValue() then
            exit(false);

        VATReportArchive."Response Received Date" := CurrentDateTime;
        VATReportArchive.SetResponseMessageBLOBFromBlob(TempBlobResponseMessage);
        VATReportArchive.Modify(true);

        exit(true);
    end;

    /// <summary>
    /// Downloads the archived submission message as a compressed ZIP file.
    /// Includes document attachments if available, otherwise downloads BLOB data.
    /// </summary>
    /// <param name="VATReportTypeValue">VAT report type option value</param>
    /// <param name="VATReportNoValue">VAT report number to download submission for</param>
    procedure DownloadSubmissionMessage(VATReportTypeValue: Option; VATReportNoValue: Code[20])
    var
        VATReportArchive: Record "VAT Report Archive";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        ZipFileName: Text[250];
    begin
        if DocumentAttachment.DownloadZipFileWithVATReturnSubmissionAttachments("VAT Report Configuration".FromInteger(VATReportTypeValue), VATReportNoValue) then
            exit;

        if not VATReportArchive.Get(VATReportTypeValue, VATReportNoValue) then
            Error(NoSubmissionMessageAvailableErr);

        OnAfterNoSubmissionMessageAvailableError(VATReportArchive, Rec, VATReportTypeValue, VATReportNoValue);
        if not VATReportArchive."Submission Message BLOB".HasValue() then
            Error(NoSubmissionMessageAvailableErr);

        VATReportArchive.CalcFields("Submission Message BLOB");
        TempBlob.FromRecord(VATReportArchive, VATReportArchive.FieldNo("Submission Message BLOB"));

        ZipFileName := VATReportNoValue + '_Submission.txt';
        DownloadZipFile(ZipFileName, TempBlob);
    end;

    /// <summary>
    /// Downloads the archived response message as a compressed ZIP file.
    /// Includes document attachments if available, otherwise downloads BLOB data.
    /// </summary>
    /// <param name="VATReportTypeValue">VAT report type option value</param>
    /// <param name="VATReportNoValue">VAT report number to download response for</param>
    procedure DownloadResponseMessage(VATReportTypeValue: Option; VATReportNoValue: Code[20])
    var
        VATReportArchive: Record "VAT Report Archive";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        ZipFileName: Text[250];
    begin
        if DocumentAttachment.DownloadZipFileWithVATReturnResponseAttachments("VAT Report Configuration".FromInteger(VATReportTypeValue), VATReportNoValue) then
            exit;

        if not VATReportArchive.Get(VATReportTypeValue, VATReportNoValue) then
            Error(NoResponseMessageAvailableErr);

        OnAfterNoResponseMessageAvailableError(VATReportArchive, Rec, VATReportTypeValue, VATReportNoValue);
        if not VATReportArchive."Response Message BLOB".HasValue() then
            Error(NoResponseMessageAvailableErr);

        VATReportArchive.CalcFields("Response Message BLOB");
        TempBlob.FromRecord(VATReportArchive, VATReportArchive.FieldNo("Response Message BLOB"));

        ZipFileName := VATReportNoValue + '_Response.txt';
        DownloadZipFile(ZipFileName, TempBlob);
    end;

    local procedure DownloadZipFile(ZipFileName: Text[250]; TempBlob: Codeunit "Temp Blob")
    var
        ZipTempBlob: Codeunit "Temp Blob";
        ServerFileInStream: InStream;
        ZipInStream: InStream;
        ZipOutStream: OutStream;
        ToFile: Text;
    begin
        DataCompression.CreateZipArchive();
        TempBlob.CreateInStream(ServerFileInStream);
        DataCompression.AddEntry(ServerFileInStream, ZipFileName);
        ZipTempBlob.CreateOutStream(ZipOutStream);
        DataCompression.SaveZipArchive(ZipOutStream);
        DataCompression.CloseZipArchive();
        ZipTempBlob.CreateInStream(ZipInStream);
        ToFile := ZipFileName + '.zip';
        DownloadFromStream(ZipInStream, '', '', '', ToFile);
    end;

    /// <summary>
    /// Sets the submission message BLOB field from a Temp Blob codeunit.
    /// Transfers BLOB data using RecordRef for field manipulation.
    /// </summary>
    /// <param name="TempBlob">Source Temp Blob containing submission message data</param>
    procedure SetSubmissionMessageBLOBFromBlob(TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo("Submission Message BLOB"));
        RecordRef.SetTable(Rec);
    end;

    /// <summary>
    /// Sets the response message BLOB field from a Temp Blob codeunit.
    /// Transfers BLOB data using RecordRef for field manipulation.
    /// </summary>
    /// <param name="TempBlob">Source Temp Blob containing response message data</param>
    procedure SetResponseMessageBLOBFromBlob(TempBlob: Codeunit "Temp Blob")
    var
        RecordRef: RecordRef;
    begin
        RecordRef.GetTable(Rec);
        TempBlob.ToRecordRef(RecordRef, FieldNo("Response Message BLOB"));
        RecordRef.SetTable(Rec);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitVATReportArchive(var VATReportArchive: Record "VAT Report Archive"; var Rec: Record "VAT Report Archive")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNoSubmissionMessageAvailableError(var VATReportArchive: Record "VAT Report Archive"; var Rec: Record "VAT Report Archive"; VATReportTypeValue: Option; VATReportNoValue: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterNoResponseMessageAvailableError(var VATReportArchive: Record "VAT Report Archive"; var Rec: Record "VAT Report Archive"; VATReportTypeValue: Option; VATReportNoValue: Code[20])
    begin
    end;
}

