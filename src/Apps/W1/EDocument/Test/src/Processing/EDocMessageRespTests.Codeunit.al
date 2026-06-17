// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Peppol.Response;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 50200 "E-Doc. Message Response Tests"
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
    procedure CreateAcknowledgedMessage()
    var
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        PEPPOLRespBuilder: Codeunit "PEPPOL Order Resp. Builder";
        TempBlob: Codeunit "Temp Blob";
        MessageEntryNo: Integer;
    begin
        Initialize();
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        PEPPOLRespBuilder.Build(EDocument."Entry No", 'PO-001', 'Seller Corp.', 'Buyer Inc.', "E-Doc. Response Type"::Acknowledged, TempBlob);
        MessageEntryNo := EDocMessageMgt.CreateMessage(EDocument, "E-Document Message Type"::"PEPPOL Order Response", "E-Document Direction"::Incoming, "E-Doc. Response Type"::Acknowledged, TempBlob);

        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual("E-Doc. Response Type"::Acknowledged, EDocMessage."Response Type", 'Response type must be Acknowledged.');
        Assert.AreEqual("E-Document Message Type"::"PEPPOL Order Response", EDocMessage."Message Type", 'Message type must be PEPPOL Order Response.');
        Assert.AreEqual("E-Document Direction"::Incoming, EDocMessage.Direction, 'Direction must be Incoming.');
        Assert.AreEqual(EDocument."Entry No", EDocMessage."E-Document Entry No.", 'E-Document entry no. must match.');
        Assert.AreEqual("E-Doc. Message Status"::Created, EDocMessage.Status, 'Status must be Created.');
        Assert.IsTrue(EDocMessage."Data Storage Entry No." > 0, 'Data storage entry must be set.');
    end;

    [Test]
    procedure CreateAcceptedMessage()
    var
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        PEPPOLRespBuilder: Codeunit "PEPPOL Order Resp. Builder";
        TempBlob: Codeunit "Temp Blob";
        MessageEntryNo: Integer;
    begin
        Initialize();
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        PEPPOLRespBuilder.Build(EDocument."Entry No", 'PO-002', 'Seller Corp.', 'Buyer Inc.', "E-Doc. Response Type"::Accepted, TempBlob);
        MessageEntryNo := EDocMessageMgt.CreateMessage(EDocument, "E-Document Message Type"::"PEPPOL Order Response", "E-Document Direction"::Incoming, "E-Doc. Response Type"::Accepted, TempBlob);

        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual("E-Doc. Response Type"::Accepted, EDocMessage."Response Type", 'Response type must be Accepted.');
        Assert.AreEqual("E-Document Message Type"::"PEPPOL Order Response", EDocMessage."Message Type", 'Message type must be PEPPOL Order Response.');
        Assert.AreEqual("E-Document Direction"::Incoming, EDocMessage.Direction, 'Direction must be Incoming.');
        Assert.AreEqual(EDocument."Entry No", EDocMessage."E-Document Entry No.", 'E-Document entry no. must match.');
        Assert.AreEqual("E-Doc. Message Status"::Created, EDocMessage.Status, 'Status must be Created.');
        Assert.IsTrue(EDocMessage."Data Storage Entry No." > 0, 'Data storage entry must be set.');
    end;

    [Test]
    procedure CreateRejectedMessage()
    var
        EDocument: Record "E-Document";
        EDocMessage: Record "E-Document Message";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        PEPPOLRespBuilder: Codeunit "PEPPOL Order Resp. Builder";
        TempBlob: Codeunit "Temp Blob";
        MessageEntryNo: Integer;
    begin
        Initialize();
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);

        PEPPOLRespBuilder.Build(EDocument."Entry No", 'PO-003', 'Seller Corp.', 'Buyer Inc.', "E-Doc. Response Type"::Rejected, TempBlob);
        MessageEntryNo := EDocMessageMgt.CreateMessage(EDocument, "E-Document Message Type"::"PEPPOL Order Response", "E-Document Direction"::Incoming, "E-Doc. Response Type"::Rejected, TempBlob);

        EDocMessage.Get(MessageEntryNo);
        Assert.AreEqual("E-Doc. Response Type"::Rejected, EDocMessage."Response Type", 'Response type must be Rejected.');
        Assert.AreEqual("E-Document Message Type"::"PEPPOL Order Response", EDocMessage."Message Type", 'Message type must be PEPPOL Order Response.');
        Assert.AreEqual("E-Document Direction"::Incoming, EDocMessage.Direction, 'Direction must be Incoming.');
        Assert.AreEqual(EDocument."Entry No", EDocMessage."E-Document Entry No.", 'E-Document entry no. must match.');
        Assert.AreEqual("E-Doc. Message Status"::Created, EDocMessage.Status, 'Status must be Created.');
        Assert.IsTrue(EDocMessage."Data Storage Entry No." > 0, 'Data storage entry must be set.');
    end;

    local procedure Initialize()
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocMessage: Record "E-Document Message";
        EDocDataStorage: Record "E-Doc. Data Storage";
        Customer: Record Customer;
    begin
        LibraryLowerPermission.SetOutsideO365Scope();

        EDocMessage.DeleteAll();
        EDocumentServiceStatus.DeleteAll();
        EDocument.DeleteAll();
        EDocDataStorage.DeleteAll();

        if IsInitialized then
            exit;

        LibraryEDoc.SetupStandardVAT();
        EDocumentService.DeleteAll();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::"Mock");

        IsInitialized := true;
    end;
}
