// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;

codeunit 139748 "E-Doc. Log File Extension Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        IsInitialized: Boolean;

    [Test]
    procedure ExportDataStorageFallsBackToDefaultFileExtension()
    var
        EDocument: Record "E-Document";
        EDocLogRecord: Record "E-Document Log";
        EDocumentService: Record "E-Document Service";
        EDocumentLog: Codeunit "E-Document Log";
    begin
        // [SCENARIO] ExportDataStorage falls back to the E-Document Service default file extension
        // when no subscriber has added an extension to the file name.
        Initialize();

        // [GIVEN] An E-Document Service using the "Data Exchange" format, which has no dedicated
        // OnBeforeExportDataStorage subscriber to set a file extension.
        EDocumentService.Get(LibraryEDoc.CreateService(Enum::"E-Document Format"::"Data Exchange", Enum::"Service Integration"::"Mock"));
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        // [GIVEN] An E-Document Log entry with data storage content
        EDocumentLog.SetBlob('Test', Enum::"E-Doc. File Format"::XML, 'Data');
        EDocumentLog.SetFields(EDocument, EDocumentService);
        EDocLogRecord := EDocumentLog.InsertLog(Enum::"E-Document Service Status"::Exported);

        // [WHEN] Exporting the data storage
        EDocLogRecord.ExportDataStorage();

        // [THEN] The downloaded file name has the default '.xml' extension applied
        Assert.IsTrue(
            LibraryFileMgtHandler.GetDownloadFromSreamToFileName().EndsWith('.xml'),
            'Expected the exported file to fall back to the default file extension.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        LibraryFileMgtHandler.SetBeforeDownloadFromStreamHandlerActivated(true);
        BindSubscription(LibraryFileMgtHandler);
        IsInitialized := true;
    end;
}
