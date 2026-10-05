// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.EServices.EDocument.Interfactura;
using Microsoft.Foundation.Company;
using Microsoft.eServices.EDocument;
using System.Utilities;

codeunit 148751 "CFDI Cancellation Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    Permissions = tabledata "E-Document" = rimd,
                  tabledata "Company Information" = rm;

    var
        Assert: Codeunit Assert;
        CFDICancellation: Codeunit "CFDI Cancellation MX";

    [Test]
    procedure CreateCancellationXMLContainsUUIDRFCAndReason()
    var
        CompanyInformation: Record "Company Information";
        TempBlob: Codeunit "Temp Blob";
        XMLText: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A cancellation request contains the UUID, issuer RFC and cancellation reason
        Initialize();

        // [GIVEN] Company Information with an issuer RFC
        CompanyInformation.Get();
        CompanyInformation.Validate("RFC Number", 'MME910620Q85');
        CompanyInformation.Modify();

        // [WHEN] A cancellation XML is created
        CFDICancellation.CreateCancellationXML('2026-01-02T13:14:15', '2026-01-01T10:00:00', '00000000-0000-0000-0000-000000000001', '01', '', TempBlob);
        XMLText := ReadBlob(TempBlob);

        // [THEN] The request contains the expected SAT cancellation data
        Assert.IsTrue(StrPos(XMLText, 'RfcEmisor="MME910620Q85"') > 0, 'The issuer RFC is missing.');
        Assert.IsTrue(StrPos(XMLText, 'UUID="00000000-0000-0000-0000-000000000001"') > 0, 'The UUID is missing.');
        Assert.IsTrue(StrPos(XMLText, 'MotivoCancelacion="01"') > 0, 'The cancellation reason is missing.');
    end;

    [Test]
    procedure CreateCancelStatusRequestXMLContainsCancellationId()
    var
        CompanyInformation: Record "Company Information";
        TempBlob: Codeunit "Temp Blob";
        XMLText: Text;
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A cancellation status request contains the cancellation identifier
        Initialize();

        // [GIVEN] Company Information with an issuer RFC
        CompanyInformation.Get();
        CompanyInformation.Validate("RFC Number", 'MME910620Q85');
        CompanyInformation.Modify();

        // [WHEN] A status request is created
        CFDICancellation.CreateCancelStatusRequestXML('CANCEL-001', TempBlob);
        XMLText := ReadBlob(TempBlob);

        // [THEN] The request contains the issuer RFC and cancellation identifier
        Assert.IsTrue(StrPos(XMLText, 'RfcEmisor="MME910620Q85"') > 0, 'The issuer RFC is missing.');
        Assert.IsTrue(StrPos(XMLText, 'ConsultaCancelacionId="CANCEL-001"') > 0, 'The cancellation identifier is missing.');
    end;

    [Test]
    procedure CancellationResponseWithCanceledStatusSetsCanceled()
    var
        EDocument: Record "E-Document";
        ResultStatus: Enum "E-Document Service Status";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A cancellation response with a canceled status updates the document
        Initialize();

        // [GIVEN] A persisted E-Document
        EDocument.Insert(true);

        // [WHEN] A canceled response is processed
        CFDICancellation.ProcessCancellationResponse('<Resultado IdRespuesta="1" Estatus="Cancelado" Resultado="Cancelado"/>', EDocument, ResultStatus);

        // [THEN] The result status is Canceled
        Assert.AreEqual(Enum::"E-Document Service Status"::Canceled, ResultStatus, 'The cancellation status is incorrect.');
    end;

    [Test]
    procedure CancellationResponseWithInProgressStatusSetsPendingResponse()
    var
        EDocument: Record "E-Document";
        ResultStatus: Enum "E-Document Service Status";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A cancellation response in progress remains pending
        Initialize();

        // [GIVEN] A persisted E-Document
        EDocument.Insert(true);

        // [WHEN] An in-progress response is processed
        CFDICancellation.ProcessCancellationResponse('<Resultado IdRespuesta="1" Estatus="EnProceso" ConsultaCancelacionId="CANCEL-001"/>', EDocument, ResultStatus);

        // [THEN] The result status is Pending Response
        Assert.AreEqual(Enum::"E-Document Service Status"::"Pending Response", ResultStatus, 'The cancellation status is incorrect.');
    end;

    [Test]
    procedure CancellationResponseWithRejectedResultSetsRejected()
    var
        EDocument: Record "E-Document";
        ResultStatus: Enum "E-Document Service Status";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A rejected cancellation response sets the rejected status
        Initialize();

        // [GIVEN] A persisted E-Document
        EDocument.Insert(true);

        // [WHEN] A rejected response is processed
        CFDICancellation.ProcessCancellationResponse('<Resultado IdRespuesta="0" Resultado="Rechazado"/>', EDocument, ResultStatus);

        // [THEN] The result status is Rejected
        Assert.AreEqual(Enum::"E-Document Service Status"::Rejected, ResultStatus, 'The cancellation status is incorrect.');
    end;

    local procedure Initialize()
    begin
    end;

    local procedure ReadBlob(var TempBlob: Codeunit "Temp Blob") XMLText: Text
    var
        InStream: InStream;
        Line: Text;
    begin
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        while not InStream.EOS do begin
            InStream.ReadText(Line);
            XMLText += Line;
        end;
    end;
}
