// // ------------------------------------------------------------------------------------------------
// // Copyright (c) Microsoft Corporation. All rights reserved.
// // Licensed under the MIT License. See License.txt in the project root for license information.
// // ------------------------------------------------------------------------------------------------
// namespace Microsoft.Peppol;

// using Microsoft.Service.Document;

// codeunit 37218 "PEPPOL30 Serv. Inv. Validation" implements "PEPPOL30 Validation1"
// {
//     TableNo = "Service Header";

//     trigger OnRun()
//     begin
//         CheckDocument(Rec);
//         CheckDocumentLines(Rec);
//     end;

//     /// <summary>
//     /// Validates a sales document header against PEPPOL 3.0 requirements.
//     /// Checks mandatory fields, formats, and business rules at the document level.
//     /// </summary>
//     /// <param name="RecordVariant">The sales header record to validate.</param>
//     procedure CheckDocument(RecordVariant: Variant)
//     var
//         PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
//     begin
//         PEPPOL30ValidationImpl.CheckServiceDocument(RecordVariant);
//     end;

//     /// <summary>
//     /// Validates all sales document lines associated with a sales header against PEPPOL 3.0 requirements.
//     /// Iterates through all lines and performs line-level validation checks.
//     /// </summary>
//     /// <param name="RecordVariant">The sales header record whose lines should be validated.</param>
//     procedure CheckDocumentLines(RecordVariant: Variant)
//     var
//         PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
//     begin
//         PEPPOL30ValidationImpl.CheckServiceDocumentLines(RecordVariant);
//     end;

//     /// <summary>
//     /// Validates a single sales document line against PEPPOL 3.0 requirements.
//     /// Performs validation checks on individual line fields and business rules.
//     /// </summary>
//     /// <param name="RecordVariant">The sales line record to validate.</param>
//     procedure CheckDocumentLine(RecordVariant: Variant)
//     var
//         PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
//     begin
//         PEPPOL30ValidationImpl.CheckServiceDocumentLine(RecordVariant);
//     end;

//     /// <summary>
//     /// Validates a posted sales invoice against PEPPOL 3.0 requirements.
//     /// Checks the posted document for compliance before export or transmission.
//     /// </summary>
//     /// <param name="RecordVariant">The posted sales invoice record to validate.</param>
//     procedure CheckPostedDocument(RecordVariant: Variant)
//     var
//         PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
//     begin
//         PEPPOL30ValidationImpl.CheckServiceInvoice(RecordVariant);
//     end;

// }
