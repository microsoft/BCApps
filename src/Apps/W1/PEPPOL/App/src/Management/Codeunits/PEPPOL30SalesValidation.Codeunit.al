// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Sales.Document;

codeunit 37216 "PEPPOL30 Sales Validation" implements "PEPPOL30 Validation"
{
    TableNo = "Sales Header";

    trigger OnRun()
    begin
        ValidateDocument(Rec);
        ValidateDocumentLines(Rec);
    end;

    /// <summary>
    /// Validates a sales document header against PEPPOL 3.0 requirements.
    /// Validates mandatory fields, formats, and business rules at the document level.
    /// </summary>
    /// <param name="RecordVariant">The sales header record to validate.</param>
    procedure ValidateDocument(RecordVariant: Variant)
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesDocument(RecordVariant);
    end;

    /// <summary>
    /// Validates all sales document lines associated with a sales header against PEPPOL 3.0 requirements.
    /// Iterates through all lines and performs line-level validation Validates.
    /// </summary>
    /// <param name="RecordVariant">The sales header record whose lines should be validated.</param>
    procedure ValidateDocumentLines(RecordVariant: Variant)
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesDocumentLines(RecordVariant);
    end;

    /// <summary>
    /// Validates a single sales document line against PEPPOL 3.0 requirements.
    /// Performs validation Validates on individual line fields and business rules.
    /// </summary>
    /// <param name="RecordVariant">The sales line record to validate.</param>
    procedure ValidateDocumentLine(RecordVariant: Variant)
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesDocumentLine(RecordVariant);
    end;

    /// <summary>
    /// Validates a posted sales invoice against PEPPOL 3.0 requirements.
    /// Validates the posted document for compliance before export or transmission.
    /// </summary>
    /// <param name="RecordVariant">The posted sales invoice record to validate.</param>
    procedure ValidatePostedDocument(RecordVariant: Variant)
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesInvoice(RecordVariant);
    end;

    procedure ValidateInvoice(RecordVariant: Variant)
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesInvoice(RecordVariant);
    end;

    procedure ValidateCreditMemo(RecordVariant: Variant)
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckSalesCreditMemo(RecordVariant);
    end;

    /// <summary>
    /// Validates the sales line
    /// </summary>
    /// <param name="RecordVariant"></param>
    /// <returns></returns>
    procedure ValidateLineTypeAndDescription(RecordVariant: Variant): Boolean
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        exit(PEPPOL30ValidationImpl.CheckSalesLineTypeAndDescription(RecordVariant));
    end;
}
