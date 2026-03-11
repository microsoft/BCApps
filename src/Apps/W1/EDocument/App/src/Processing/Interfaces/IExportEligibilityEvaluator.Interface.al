// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Interfaces;

using Microsoft.eServices.EDocument;


/// <summary>
/// Interface to evaluate if a document is eligible for export via a given E-Document Service.
/// </summary>
interface IExportEligibilityEvaluator
{

    /// <summary>
    /// Determines if the given E-Document is eligible for export using the specified E-Document Service,
    /// based on the source document type and other criteria defined in the implementation.
    /// </summary>
    /// <param name="EDocument"></param>
    /// <param name="EDocumentService"></param>
    /// <param name="SourceDocumentHeader"></param>
    /// <param name="DocumentType"></param>
    /// <returns>True if the document is eligible for export; otherwise, false.</returns>
    procedure ShouldExport(EDocumentService: Record "E-Document Service";
        SourceDocumentHeader: RecordRef;
        DocumentType: Enum "E-Document Type"): Boolean;

}
