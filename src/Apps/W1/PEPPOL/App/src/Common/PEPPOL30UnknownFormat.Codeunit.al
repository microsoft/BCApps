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
        UnknownFormatErr: Label 'The selected PEPPOL 3.0 format is no longer available. Open the PEPPOL 3.0 Setup page and select an available format.';

    procedure ValidateDocument(RecordVariant: Variant)
    begin
        Error(UnknownFormatErr);
    end;

    procedure ValidateDocumentLines(RecordVariant: Variant)
    begin
        Error(UnknownFormatErr);
    end;

    procedure ValidateDocumentLine(RecordVariant: Variant)
    begin
        Error(UnknownFormatErr);
    end;

    procedure ValidateLineTypeAndDescription(RecordVariant: Variant): Boolean
    begin
        Error(UnknownFormatErr);
    end;

    procedure ValidatePostedDocument(RecordVariant: Variant)
    begin
        Error(UnknownFormatErr);
    end;

    procedure GetNextPostedHeaderAsSalesHeader(var PostedRecRef: RecordRef; var SalesHeader: Record "Sales Header") Found: Boolean
    begin
        Error(UnknownFormatErr);
    end;

    procedure GetNextPostedLineAsSalesLine(var PostedLineRecRef: RecordRef; var SalesLine: Record "Sales Line") Found: Boolean
    begin
        Error(UnknownFormatErr);
    end;
}
