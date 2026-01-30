codeunit 6373 Maintenance
{
    var
        // Error messages
        DocumentDownloadFailedMsg: Label 'Failed to download document %1 for E-Document %2', Comment = '%1 = Document ID, %2 = E-Document Entry No';
        ProcessingCompletedMsg: Label 'Processed %1 E-Documents, successfully downloaded %2', Comment = '%1 = Total processed, %2 = Successful downloads';

    trigger OnRun()
    begin
        ProcessEDocuments();
    end;

    local procedure ProcessEDocuments()
    var
        EDocument: Record "E-Document";
        ProcessedCount: Integer;
        SuccessCount: Integer;
    begin
        if not FindEDocumentsToProcess(EDocument) then
            exit;

        repeat
            if ProcessSingleEDocument(EDocument) then
                SuccessCount += 1;
            ProcessedCount += 1;
        until EDocument.Next() = 0;

        Session.LogMessage('0000AVL015',
            StrSubstNo(ProcessingCompletedMsg, ProcessedCount, SuccessCount),
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            'Category', 'Avalara Maintenance');
    end;

    local procedure FindEDocumentsToProcess(var EDocument: Record "E-Document"): Boolean
    begin
        // Only e-documents that have been sent to Avalara and are not in error status
        EDocument.SetFilter("Avalara Document Id", '<>%1', '');
        EDocument.SetFilter(Status, '<>%1', EDocument.Status::Error.AsInteger());

        exit(EDocument.FindSet());
    end;

    local procedure ProcessSingleEDocument(var EDocument: Record "E-Document"): Boolean
    var
        EDocumentService: Record "E-Document Service";
        AvalaraDocumentManagement: Codeunit "Avalara Document Management";
        DocumentId: Text;
    begin
        if EDocument."Avalara Document Id" = '' then
            exit(false);

        EDocumentService := EDocument.GetEDocumentService();
        if EDocumentService.Code = '' then
            exit(false);

        DocumentId := EDocument."Avalara Document Id";

        // Use the new comprehensive download function that handles all media types
        // and attachments to both E-Document and source document
        if AvalaraDocumentManagement.DownloadDocumentWithAllMediaTypes(EDocument, EDocumentService, DocumentId) then begin
            Session.LogMessage('0000AVL016',
                StrSubstNo('Successfully downloaded document %1 for E-Document %2', DocumentId, EDocument."Entry No"),
                Verbosity::Normal,
                DataClassification::SystemMetadata,
                TelemetryScope::ExtensionPublisher,
                'Category', 'Avalara Maintenance');
            exit(true);
        end;

        LogDownloadError(EDocument, DocumentId);
        exit(false);
    end;

    local procedure LogDownloadError(EDocument: Record "E-Document"; DocumentId: Text)
    var
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        ErrorText: Text;
    begin
        ErrorText := StrSubstNo(DocumentDownloadFailedMsg, DocumentId, EDocument."Entry No");

        if ErrorAlreadyLogged(EDocument, ErrorText) then
            exit;

        EDocumentErrorHelper.LogSimpleErrorMessage(EDocument, ErrorText);

        Session.LogMessage('0000AVL017',
            StrSubstNo('Document download failed for E-Document %1, Document ID: %2', EDocument."Entry No", DocumentId),
            Verbosity::Warning,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            'Category', 'Avalara Maintenance');
    end;

    local procedure ErrorAlreadyLogged(EDocument: Record "E-Document"; ErrorText: Text): Boolean
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId);
        ErrorMessage.SetRange(Message, ErrorText);

        exit(not ErrorMessage.IsEmpty());
    end;
}
