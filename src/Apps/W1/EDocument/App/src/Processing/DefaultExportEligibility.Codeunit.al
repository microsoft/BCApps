// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.eServices.EDocument.Processing.Interfaces;

codeunit 6198 "Default Export Eligibility" implements IExportEligibilityEvaluator
{
    /// <summary>
    /// Default implementation that allows all documents to be exported.
    /// This maintains backward compatibility with the standard behavior.
    /// </summary>
    procedure ShouldExport(EDocumentService: Record "E-Document Service"; SourceDocumentHeader: RecordRef; DocumentType: Enum "E-Document Type"): Boolean
    begin
        exit(true);
    end;

}
