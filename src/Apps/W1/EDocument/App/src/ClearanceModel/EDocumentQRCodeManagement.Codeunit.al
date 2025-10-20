// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.eServices.EDocument;

using Microsoft.Sales.History;
using System.IO;
using System.Text;
using System.Utilities;
codeunit 6197 "EDocument QR Code Management"
{
    internal procedure InitializeAndRunQRCodeViewer(SourceTable: RecordRef)
    var
        TempQRBuf: Record "EDoc QR Buffer" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SrcInStr: InStream;
        DstOutStr: OutStream;
        DocumentType: Text[30];
    begin
        case SourceTable.Number of
            DATABASE::"Sales Invoice Header":
                begin
                    DocumentType := 'Sales Invoice';
                    SourceTable.SetTable(SalesInvoiceHeader);
                    SalesInvoiceHeader.CalcFields("QR Code Base64");

                    if not SalesInvoiceHeader."QR Code Base64".HasValue then begin
                        Message(NoQRDCodeAvailableLbl, DocumentType, SalesInvoiceHeader."No.");
                        exit;
                    end;

                    TempQRBuf.Init();
                    TempQRBuf."Document Type" := DocumentType;
                    TempQRBuf."Document No." := SalesInvoiceHeader."No.";

                    SalesInvoiceHeader."QR Code Base64".CreateInStream(SrcInStr);
                end;

            DATABASE::"Sales Cr.Memo Header":
                begin
                    DocumentType := 'Sales Credit Memo';
                    SourceTable.SetTable(SalesCrMemoHeader);
                    SalesCrMemoHeader.CalcFields("QR Code Base64");

                    if not SalesCrMemoHeader."QR Code Base64".HasValue then begin
                        Message(NoQRDCodeAvailableLbl, DocumentType, SalesCrMemoHeader."No.");
                        exit;
                    end;

                    TempQRBuf.Init();
                    TempQRBuf."Document Type" := DocumentType;
                    TempQRBuf."Document No." := SalesCrMemoHeader."No.";

                    SalesCrMemoHeader."QR Code Base64".CreateInStream(SrcInStr);
                end;

            else
                Error(UnsupportedTableSourceLbl, SourceTable.Caption);
        end;

        TempQRBuf."QR Code Base64".CreateOutStream(DstOutStr);
        CopyStream(DstOutStr, SrcInStr);
        TempQRBuf.Insert();

        PAGE.RunModal(PAGE::"E-Document QR Viewer", TempQRBuf);
    end;

    internal procedure ExportQRCodeToFile(var EDocQRBuffer: Record "EDoc QR Buffer")
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        OutStream: OutStream;
        InStream: InStream;
        Base64Txt: Text;
        FileNameLbl: Label '%1_%2_QRCode.png', Locked = true;
    begin
        EDocQRBuffer.CalcFields("QR Code Base64");
        if not EDocQRBuffer."QR Code Base64".HasValue then
            exit;

        EDocQRBuffer."QR Code Base64".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(Base64Txt);

        if Base64Txt = '' then
            exit;

        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(Base64Txt, OutStream);

        FileMgt.BLOBExport(TempBlob, StrSubstNo(FileNameLbl, EDocQRBuffer."Document Type", EDocQRBuffer."Document No."), true);
    end;

    internal procedure SetQRCodeImageFromBase64(var EDocQRBuffer: Record "EDoc QR Buffer")
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        Base64Txt: Text;
    begin
        EDocQRBuffer.CalcFields("QR Code Base64");
        if not EDocQRBuffer."QR Code Base64".HasValue then
            exit;

        EDocQRBuffer."QR Code Base64".CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(Base64Txt);

        if Base64Txt = '' then
            exit;

        TempBlob.CreateOutStream(OutStream);
        Base64Convert.FromBase64(Base64Txt, OutStream);

        TempBlob.CreateInStream(InStream);
        EDocQRBuffer."QR Code Image".ImportStream(InStream, 'image/png');
        EDocQRBuffer.Modify();
    end;

    var
        UnsupportedTableSourceLbl: Label 'Unsupported source table: %1.', Comment = '%1 The name of the table';
        NoQRDCodeAvailableLbl: Label 'No QR Base64 content available for %1 %2.', Comment = '%1 the document type, %2 the document number';
}
