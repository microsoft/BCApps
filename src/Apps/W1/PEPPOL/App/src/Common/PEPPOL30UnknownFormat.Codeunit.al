// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;

codeunit 37223 "PEPPOL30 Unknown Format" implements "PEPPOL30 Validation", "PEPPOL Posted Document Iterator"
{
    Access = Internal;

    var
        UnknownFormatErr: Label 'The selected PEPPOL 3.0 format is no longer available. Select an available format.';
        UnknownFormatTitleErr: Label 'PEPPOL 3.0 format unavailable';
        OpenPEPPOLSetupLbl: Label 'Open PEPPOL 3.0 Setup';

    procedure ValidateDocument(RecordVariant: Variant)
    begin
        RaiseUnknownFormatError();
    end;

    procedure ValidateDocumentLines(RecordVariant: Variant)
    begin
        RaiseUnknownFormatError();
    end;

    procedure ValidateDocumentLine(RecordVariant: Variant)
    begin
        RaiseUnknownFormatError();
    end;

    procedure ValidateLineTypeAndDescription(RecordVariant: Variant): Boolean
    begin
        RaiseUnknownFormatError();
    end;

    procedure ValidatePostedDocument(RecordVariant: Variant)
    begin
        RaiseUnknownFormatError();
    end;

    procedure GetNextPostedHeaderAsSalesHeader(var PostedRecRef: RecordRef; var SalesHeader: Record "Sales Header") Found: Boolean
    begin
        RaiseUnknownFormatError();
    end;

    procedure GetNextPostedLineAsSalesLine(var PostedLineRecRef: RecordRef; var SalesLine: Record "Sales Line") Found: Boolean
    begin
        RaiseUnknownFormatError();
    end;

    local procedure RaiseUnknownFormatError()
    var
        UnknownFormatErrorInfo: ErrorInfo;
    begin
        UnknownFormatErrorInfo.Title := UnknownFormatTitleErr;
        UnknownFormatErrorInfo.Message := UnknownFormatErr;
        UnknownFormatErrorInfo.DataClassification := DataClassification::SystemMetadata;
        UnknownFormatErrorInfo.PageNo := Page::"PEPPOL 3.0 Setup";
        UnknownFormatErrorInfo.AddNavigationAction(OpenPEPPOLSetupLbl);
        Error(UnknownFormatErrorInfo);
    end;
}
