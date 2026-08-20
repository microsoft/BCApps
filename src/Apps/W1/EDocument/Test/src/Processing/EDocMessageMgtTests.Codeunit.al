// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Sales.Customer;
using System.Threading;
using System.Utilities;

codeunit 139899 "E-Doc. Message Mgt. Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        IsInitialized: Boolean;

    [Test]
    procedure QueueMessageSchedulesBackgroundSend()
    var
        Customer: Record Customer;
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        MessageEntryNo: Integer;
    begin
        // [FEATURE] [AI test]
        // [SCENARIO] Queueing an outgoing E-Document message schedules its background send job
        Initialize(Customer);

        // [GIVEN] A created outgoing E-Document message
        CreateOutgoingEDocument(EDocument);
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Message />');
        MessageEntryNo := EDocMessageMgt.CreateMessage(
            EDocument, "E-Document Message Type"::"Unspecified", "E-Document Direction"::Outgoing,
            "E-Doc. Response Type"::None, TempBlob);

        // [WHEN] The message is queued
        EDocMessageMgt.QueueMessage(MessageEntryNo);

        // [THEN] The message is marked Queued and a send job is scheduled for it
        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual("E-Doc. Message Status"::Queued, EDocMessage.Status, 'The message must be queued.');
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"E-Doc. Message Send Job");
        JobQueueEntry.SetRange("Record ID to Process", EDocMessage.RecordId());
        Assert.RecordCount(JobQueueEntry, 1);
    end;

    local procedure Initialize(var Customer: Record Customer)
    var
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        JobQueueEntry: Record "Job Queue Entry";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"E-Doc. Message Send Job");
        JobQueueEntry.DeleteAll();
        EDocMessage.DeleteAll();
        EDocument.DeleteAll();

        if IsInitialized then
            exit;

        LibraryEDoc.SetupStandardVAT();
        EDocumentService.DeleteAll();
        LibraryEDoc.SetupStandardSalesScenario(
            Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::Mock);
        IsInitialized := true;
    end;

    local procedure CreateOutgoingEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Service := EDocumentService.Code;
        EDocument.Insert();
    end;
}
