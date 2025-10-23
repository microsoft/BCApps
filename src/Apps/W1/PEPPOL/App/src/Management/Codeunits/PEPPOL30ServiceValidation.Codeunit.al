// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Peppol;

using Microsoft.Service.Document;

codeunit 37219 "PEPPOL30 Service Validation" implements "PEPPOL30 Validation1"
{
    TableNo = "Service Header";

    trigger OnRun()
    begin
        ValidateDocument(Rec);
        ValidateDocumentLines(Rec);
    end;

    /// <summary>
    /// Validates a service credit memo header against PEPPOL 3.0 requirements.
    /// Checks mandatory fields, formats, and business rules at the document level.
    /// </summary>
    /// <param name="RecordVariant">The service credit memo header record to validate.</param>
    procedure ValidateDocument(RecordVariant: Variant)
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckServiceDocument(RecordVariant);
    end;

    /// <summary>
    /// Validates all service credit memo lines associated with a service header against PEPPOL 3.0 requirements.
    /// Iterates through all lines and performs line-level validation checks.
    /// </summary>
    /// <param name="RecordVariant">The service credit memo header record whose lines should be validated.</param>
    procedure ValidateDocumentLines(RecordVariant: Variant)
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckServiceDocumentLines(RecordVariant);
    end;

    /// <summary>
    /// Validates a single service credit memo line against PEPPOL 3.0 requirements.
    /// Performs validation checks on individual line fields and business rules.
    /// </summary>
    /// <param name="RecordVariant">The service credit memo line record to validate.</param>
    procedure ValidateDocumentLine(RecordVariant: Variant)
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckServiceDocumentLine(RecordVariant);
    end;

    /// <summary>
    /// Validates a posted service credit memo against PEPPOL 3.0 requirements.
    /// Checks the posted credit memo for compliance before export or transmission.
    /// </summary>
    /// <param name="RecordVariant">The posted service credit memo record to validate.</param>
    procedure ValidateCreditMemo(RecordVariant: Variant)
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckServiceCreditMemo(RecordVariant);
    end;

    /// <summary>
    /// Validates a posted service invoice against PEPPOL 3.0 requirements.
    /// Checks the posted invoice for compliance before export or transmission.
    /// </summary>
    /// <param name="RecordVariant">The posted service invoice record to validate.</param>
    procedure ValidateInvoice(RecordVariant: Variant)
    var
        PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
    begin
        PEPPOL30ValidationImpl.CheckServiceInvoice(RecordVariant);
    end;


}
