// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using Microsoft.Integration.Graph;

codeunit 5440 "Default PDF Doc.Handler" implements IPdfDocumentHandler
{

    /// <summary>
    /// Default handler procedure with integration event.
    /// </summary>
    /// <param name="DocumentId">Document ID</param>
    /// <param name="DocumentType">Document Type</param>
    /// <param name="TempAttachmentEntityBuffer">The buffer to store successfully generated report</param>
    /// <returns>True if the generated report successfully added to the buffer, otherwise false.</returns>
    procedure GeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary) DocumentFound: Boolean
    var
        Handled: Boolean;
    begin
        OnBeforeGeneratePdfBlobWithDocumentType(DocumentId, DocumentType, TempAttachmentEntityBuffer, DocumentFound, Handled);
        if Handled then
            exit(DocumentFound);

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGeneratePdfBlobWithDocumentType(DocumentId: Guid; DocumentType: Enum "Attachment Entity Buffer Document Type"; var TempAttachmentEntityBuffer: Record "Attachment Entity Buffer" temporary; var DocumentFound: Boolean; var Handled: Boolean)
    begin
    end;
}