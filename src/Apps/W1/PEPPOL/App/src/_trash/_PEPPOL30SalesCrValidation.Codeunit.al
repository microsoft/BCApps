// // ------------------------------------------------------------------------------------------------
// // Copyright (c) Microsoft Corporation. All rights reserved.
// // Licensed under the MIT License. See License.txt in the project root for license information.
// // ------------------------------------------------------------------------------------------------
// namespace Microsoft.Peppol;

// using Microsoft.Sales.Document;

// codeunit 37217 "PEPPOL30 Sales Cr. Validation" implements "PEPPOL30 Validation1"
// {
//     TableNo = "Sales Header";

//     trigger OnRun()
//     begin
//         CheckDocument(Rec);
//         CheckDocumentLines(Rec);
//     end;

//     /// <summary>
//     /// Validates a sales credit memo header against PEPPOL 3.0 requirements.
//     /// Checks mandatory fields, formats, and business rules at the document level.
//     /// </summary>
//     /// <param name="RecordVariant">The sales credit memo header record to validate.</param>
//     procedure CheckDocument(RecordVariant: Variant)
//     var
//         PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
//     begin
//         PEPPOL30ValidationImpl.CheckSalesDocument(RecordVariant);
//     end;

//     /// <summary>
//     /// Validates all sales credit memo lines associated with a sales header against PEPPOL 3.0 requirements.
//     /// Iterates through all lines and performs line-level validation checks.
//     /// </summary>
//     /// <param name="RecordVariant">The sales credit memo header record whose lines should be validated.</param>
//     procedure CheckDocumentLines(RecordVariant: Variant)
//     var
//         PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
//     begin
//         PEPPOL30ValidationImpl.CheckSalesDocumentLines(RecordVariant);
//     end;

//     /// <summary>
//     /// Validates a single sales credit memo line against PEPPOL 3.0 requirements.
//     /// Performs validation checks on individual line fields and business rules.
//     /// </summary>
//     /// <param name="RecordVariant">The sales credit memo line record to validate.</param>
//     procedure CheckDocumentLine(RecordVariant: Variant)
//     var
//         PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
//     begin
//         PEPPOL30ValidationImpl.CheckSalesDocumentLine(RecordVariant);
//     end;

//     /// <summary>
//     /// Validates a posted sales credit memo against PEPPOL 3.0 requirements.
//     /// Checks the posted credit memo for compliance before export or transmission.
//     /// </summary>
//     /// <param name="RecordVariant">The posted sales credit memo record to validate.</param>
//     procedure CheckPostedDocument(RecordVariant: Variant)
//     var
//         PEPPOL30ValidationImpl: Codeunit "PEPPOL30 Validation Impl.";
//     begin
//         PEPPOL30ValidationImpl.CheckSalesCreditMemo(RecordVariant);
//     end;

// }
