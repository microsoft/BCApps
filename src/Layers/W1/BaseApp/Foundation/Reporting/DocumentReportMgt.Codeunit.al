// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System;
using System.Environment;
using System.Reflection;
using System.Utilities;
using System.Xml;

codeunit 9651 "Document Report Mgt."
{

    trigger OnRun()
    begin
    end;

    var
        ClientTypeMgt: Codeunit "Client Type Management";

        UpgradeNotSupportedErr: Label 'Upgrade is not supported after version 20.';
#pragma warning disable AA0470
        TemplateValidationQst: Label 'The Word layout does not comply with the current report design (for example, fields are missing or the report ID is wrong).\The following errors were detected during the layout validation:\%1\Do you want to continue?';
        TemplateValidationErr: Label 'The Word layout does not comply with the current report design (for example, fields are missing or the report ID is wrong).\The following errors were detected during the document validation:\%1\You must update the layout to match the current report design.';
#pragma warning restore AA0470
        AbortWithValidationErr: Label 'The Word layout action has been canceled because of validation errors.';
#pragma warning disable AA0470
        TemplateAfterUpdateValidationErr: Label 'The automatic update could not resolve all the conflicts in the current Word layout. For example, the layout uses fields that are missing in the report design or the report ID is wrong.\The following errors were detected:\%1\You must manually update the layout to match the current report design.';
        UpgradeMessageMsg: Label 'The report upgrade process returned the following log messages:\%1.';
#pragma warning restore AA0470
        NoReportLayoutUpgradeRequiredMsg: Label 'The layout upgrade process completed without detecting any required changes in the current application.';
        CompanyInformationPicErr: Label 'The document contains elements that cannot be converted to PDF. This may be caused by missing image data in the document.';

    procedure ValidateWordLayout(ReportID: Integer; DocumentStream: InStream; useConfirm: Boolean; updateContext: Boolean): Boolean
    var
        NAVWordXMLMerger: DotNet WordReportManager;
        ValidationErrors: Text;
        ValidationErrorFormat: Text;
    begin
        ValidationErrors := NAVWordXMLMerger.ValidateWordDocumentTemplate(DocumentStream, REPORT.WordXmlPart(ReportID, true));
        if ValidationErrors <> '' then begin
            if useConfirm then begin
                if not Confirm(TemplateValidationQst, false, ValidationErrors) then
                    Error(AbortWithValidationErr);
            end else begin
                if updateContext then
                    ValidationErrorFormat := TemplateAfterUpdateValidationErr
                else
                    ValidationErrorFormat := TemplateValidationErr;

                Error(ValidationErrorFormat, ValidationErrors);
            end;

            exit(false);
        end;
        exit(true);
    end;

    procedure TryUpdateWordLayout(DocumentStream: InStream; var UpdateStream: OutStream; CachedCustomPart: Text; CurrentCustomPart: Text): Text
    var
        NAVWordXMLMerger: DotNet WordReportManager;
    begin
        NAVWordXMLMerger := NAVWordXMLMerger.WordReportManager();
        NAVWordXMLMerger.UpdateWordDocumentLayout(DocumentStream, UpdateStream, CachedCustomPart, CurrentCustomPart, true);
        exit(NAVWordXMLMerger.LastUpdateError);
    end;

    procedure TryUpdateRdlcLayout(reportId: Integer; RdlcStream: InStream; RdlcUpdatedStream: OutStream; CachedCustomPart: Text; CurrentCustomPart: Text; IgnoreDelete: Boolean): Text
    var
        RdlcReportManager: DotNet RdlcReportManager;
    begin
        exit(RdlcReportManager.TryUpdateRdlcLayout(reportId, RdlcStream, RdlcUpdatedStream,
            CachedCustomPart, CurrentCustomPart, IgnoreDelete));
    end;

    procedure NewWordLayout(ReportId: Integer; var DocumentStream: OutStream)
    var
        NAVWordXmlMerger: DotNet WordReportManager;
    begin
        NAVWordXmlMerger.NewWordDocumentLayout(DocumentStream, REPORT.WordXmlPart(ReportId));
    end;

    procedure NewRdlcLayout(ReportId: Integer; var DocumentStream: OutStream)
    var
        RdlcReportManager: DotNet RdlcReportManager;
    begin
        RdlcReportManager.NewRdlcLayout(DocumentStream, ReportId);
    end;

    procedure NewExcelLayout(ReportId: Integer; var DocumentStream: OutStream)
    begin
        NewExcelLayout(ReportId, "Excel Sheet Configuration"::Default, DocumentStream);
    end;

    procedure NewExcelLayout(ReportId: Integer; ExcelSheetConfiguration: enum "Excel Sheet Configuration"; var DocumentStream: OutStream)
    var
        ExcelReportManager: DotNet ExcelReportManager;
    begin
        ExcelReportManager.NewExcelLayout(DocumentStream, ReportId, ExcelSheetConfiguration.AsInteger());
    end;

    procedure ConvertWordToPdf(var TempBlob: Codeunit "Temp Blob"; ReportID: Integer)
    begin
        if not TryConvertWordBlobToPdf(TempBlob) then
            Error(CompanyInformationPicErr);
    end;

    [TryFunction]
    local procedure TryConvertWordBlobToPdf(var TempBlobWord: Codeunit "Temp Blob")
    var
        TempBlobPdf: Codeunit "Temp Blob";
        InStreamWordDoc: InStream;
        OutStreamPdfDoc: OutStream;
        WordTransformation: DotNet WordTransformation;
    begin
        TempBlobWord.CreateInStream(InStreamWordDoc);
        TempBlobPdf.CreateOutStream(OutStreamPdfDoc);
        WordTransformation.ConvertToPdf(InStreamWordDoc, OutStreamPdfDoc);
        TempBlobWord := TempBlobPdf;
    end;

    procedure ConvertWordToHtml(var TempBlob: Codeunit "Temp Blob")
    var
        TempBlobHtml: Codeunit "Temp Blob";
        TempBlobWord: Codeunit "Temp Blob";
        InStreamWordDoc: InStream;
        OutStreamHtmlDoc: OutStream;
        WordTransformation: DotNet WordTransformation;
    begin
        TempBlobWord := TempBlob;
        TempBlobWord.CreateInStream(InStreamWordDoc);
        TempBlobHtml.CreateOutStream(OutStreamHtmlDoc);
        WordTransformation.ConvertToHtml(InStreamWordDoc, OutStreamHtmlDoc);
        TempBlob := TempBlobHtml
    end;

    [Scope('OnPrem')]
    procedure IsStreamHasDataset(InStrXmlData: InStream): Boolean
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlNode: DotNet XmlNode;
        XmlHasDataset: Boolean;
    begin
        XmlHasDataset := XMLDOMManagement.LoadXMLNodeFromInStream(InStrXmlData, XmlNode);

        if XmlHasDataset then
            XmlHasDataset := XMLDOMManagement.FindNode(XmlNode, 'DataItems', XmlNode);

        if XmlHasDataset then
            XmlHasDataset := XmlNode.ChildNodes.Count > 0;

        exit(XmlHasDataset);
    end;

    [Scope('OnPrem')]
    procedure ApplyUpgradeToReports(var ReportUpgradeCollection: DotNet ReportUpgradeCollection; testOnly: Boolean): Boolean
    var
        CustomReportLayout: Record "Custom Report Layout";
        ReportUpgrade: DotNet ReportUpgradeSet;
        ReportChangeLogCollection: DotNet IReportChangeLogCollection;
    begin
        foreach ReportUpgrade in ReportUpgradeCollection do begin
            CustomReportLayout.SetFilter("Report ID", Format(ReportUpgrade.ReportId));
            if CustomReportLayout.Find('-') then
                repeat
                    CustomReportLayout.ApplyUpgrade(ReportUpgrade, ReportChangeLogCollection, testOnly);
                until CustomReportLayout.Next() = 0;
        end;

        if IsNull(ReportChangeLogCollection) then begin // Don't break upgrade process with user information
            if (ClientTypeMgt.GetCurrentClientType() <> CLIENTTYPE::Background) and
               (ClientTypeMgt.GetCurrentClientType() <> CLIENTTYPE::Management)
            then
                Message(NoReportLayoutUpgradeRequiredMsg);

            exit(false);
        end;

        ProcessUpgradeLog(ReportChangeLogCollection);
        exit(ReportChangeLogCollection.Count > 0);
    end;

    local procedure ProcessUpgradeLog(var ReportChangeLogCollection: DotNet IReportChangeLogCollection)
    var
        ReportLayoutUpdateLog: Codeunit "Report Layout Update Log";
    begin
        if IsNull(ReportChangeLogCollection) then
            exit;

        if (ClientTypeMgt.GetCurrentClientType() <> CLIENTTYPE::Background) and
           (ClientTypeMgt.GetCurrentClientType() <> CLIENTTYPE::Management)
        then
            ReportLayoutUpdateLog.ViewLog(ReportChangeLogCollection)
        else
            Message(UpgradeMessageMsg, Format(ReportChangeLogCollection));
    end;

    [Scope('OnPrem')]
    procedure BulkUpgrade(testMode: Boolean)
    begin
        Message(UpgradeNotSupportedErr);
    end;
}

