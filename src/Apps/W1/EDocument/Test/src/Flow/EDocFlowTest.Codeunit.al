// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Foundation.Reporting;
using Microsoft.Sales.Customer;
using System.Automation;
using System.IO;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 139631 "E-Doc. Flow Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;

    var

        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";
        WrongValueErr: Label 'Wrong value';
        WorkflowEmptyErr: Label 'Must return false for an empty workflow';
        NoWorkflowArgumentErr: Label 'E-Document Service must be specified in Workflow Argument';

    [Test]
    procedure EDocFlowGetServiceInFlowSuccess26()
    var
        EDocService: Record "E-Document Service";
        EDocWorkflowProcessing: Codeunit "E-Document WorkFlow Processing";
        CustomerNo, DocSendProfileNo, WorkflowCode, ServiceCode : Code[20];
    begin
        // [FEATURE] [E-Document] [Flow]
        // [SCENARIO] Get services from workflow

        // [GIVEN] Created posting a document
        Initialize();

        // [WHEN] Creating worfklow with Service A
        CustomerNo := LibrarySales.CreateCustomerNo();
        DocSendProfileNo := LibraryEDoc.CreateDocumentSendingProfileForWorkflow(CustomerNo, '');
        ServiceCode := LibraryEDoc.CreateService(Enum::"Service Integration"::"Mock");
        WorkflowCode := LibraryEDoc.CreateFlowWithService(DocSendProfileNo, ServiceCode);

        // [THEN] Team Member DoesFlowHasEDocService returns Service A
        LibraryLowerPermission.SetTeamMember();
        EDocWorkflowProcessing.DoesFlowHasEDocService(EDocService, WorkflowCode);
        EDocService.FindSet();
        Assert.AreEqual(1, EDocService.Count(), WrongValueErr);
        Assert.AreEqual(ServiceCode, EDocService.Code, WrongValueErr);
    end;

    [Test]
    procedure EDocFlowGetServicesInFlowSuccess26()
    var
        EDocService: Record "E-Document Service";
        EDocWorkflowProcessing: Codeunit "E-Document WorkFlow Processing";
        CustomerNo, DocSendProfileNo, WorkflowCode, ServiceCodeA, ServiceCodeB : Code[20];
    begin
        // [FEATURE] [E-Document] [Flow]
        // [SCENARIO] Get services from workflow with multiple services

        // [GIVEN] Created posting a document
        Initialize();

        // [WHEN] Creating worfklow with Service A and B
        CustomerNo := LibrarySales.CreateCustomerNo();
        DocSendProfileNo := LibraryEDoc.CreateDocumentSendingProfileForWorkflow(CustomerNo, '');
        ServiceCodeA := LibraryEDoc.CreateService(Enum::"Service Integration"::"Mock");
        ServiceCodeB := LibraryEDoc.CreateService(Enum::"Service Integration"::"Mock");
        WorkflowCode := LibraryEDoc.CreateFlowWithServices(DocSendProfileNo, ServiceCodeA, ServiceCodeB);

        // [THEN] DoesFlowHasEDocService returns service A and B
        EDocWorkflowProcessing.DoesFlowHasEDocService(EDocService, WorkflowCode);
        Assert.AreEqual(2, EDocService.Count(), WrongValueErr);
        EDocService.FindSet();
        Assert.AreEqual(ServiceCodeA, EDocService.Code, WrongValueErr);
        EDocService.Next();
        Assert.AreEqual(ServiceCodeB, EDocService.Code, WrongValueErr);
    end;

    [Test]
    procedure EDocFlowNoServiceInWorkFlowSuccess()
    var
        EDocService: Record "E-Document Service";
        EDocWorkflowProcessing: Codeunit "E-Document WorkFlow Processing";
        WorkflowCode: Code[20];
    begin
        // [FEATURE] [E-Document] [Flow]
        // [SCENARIO] Get services from empty workflow

        // [GIVEN] Empty workflow
        Initialize();
        WorkflowCode := LibraryEDoc.CreateEmptyFlow();

        // [WHEN] Checking the services in a the workflow
        // [THEN] The method must return false if no services available in the flow.
        Assert.IsFalse(EDocWorkflowProcessing.DoesFlowHasEDocService(EDocService, WorkflowCode), WorkflowEmptyErr);
    end;

    [Test]
    procedure EDocFLowSendWithoutServiceFailure()
    var
        EDocument: Record "E-Document";
        ErrorMessage: Record "Error Message";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        EDocWorkflowProcessing: Codeunit "E-Document WorkFlow Processing";
        RecordRef: RecordRef;
        CustomerNo, DocSendProfileNo : Code[20];
    begin
        // [FEATURE] [E-Document] [Flow]
        // [SCENARIO] Call SendEDocument with no service specified as argument

        // [GIVEN]
        Initialize();

        EDocument."Entry No" := 0;
        EDocument.Insert();
        CustomerNo := LibrarySales.CreateCustomerNo();
        DocSendProfileNo := LibraryEDoc.CreateDocumentSendingProfileForWorkflow(CustomerNo, '');

        // [WHEN] Creating worfklow without service
        LibraryEDoc.CreateFlowWithService(DocSendProfileNo, '');
        WorkflowStepArgument.FindLast();
        WorkflowStepInstance.Argument := WorkflowStepArgument.ID;

        // [THEN] An error message has been logged for the e-document
        ErrorMessage.DeleteAll();
        LibraryLowerPermission.SetTeamMember();
        RecordRef.GetTable(EDocument);
        EDocWorkflowProcessing.SendEDocument(RecordRef, WorkflowStepInstance);
        Assert.IsFalse(ErrorMessage.IsEmpty(), WrongValueErr);
        ErrorMessage.FindLast();
        Assert.AreEqual(NoWorkflowArgumentErr, ErrorMessage.Message, WrongValueErr);
        Assert.AreEqual(EDocument.RecordId, ErrorMessage."Context Record ID", WrongValueErr);
    end;

#if not CLEAN26
#pragma warning disable AL0432
    [Test]
    [Obsolete('Obsolete in 26.0', '26.0')]
    procedure EDocFlowGetServiceInFlowSuccess()
    var
        EDocService: Record "E-Document Service";
        EDocWorkflowProcessing: Codeunit "E-Document WorkFlow Processing";
        CustomerNo, DocSendProfileNo, WorkflowCode, ServiceCode : Code[20];
    begin
        // [FEATURE] [E-Document] [Flow]
        // [SCENARIO] Get services from workflow

        // [GIVEN] Created posting a document
        Initialize();

        // [WHEN] Creating worfklow with Service A
        CustomerNo := LibrarySales.CreateCustomerNo();
        DocSendProfileNo := LibraryEDoc.CreateDocumentSendingProfileForWorkflow(CustomerNo, '');
        ServiceCode := LibraryEDoc.CreateService(Enum::"E-Document Integration"::Mock);
        WorkflowCode := LibraryEDoc.CreateFlowWithService(DocSendProfileNo, ServiceCode);

        // [THEN] Team Member DoesFlowHasEDocService returns Service A
        LibraryLowerPermission.SetTeamMember();
        EDocWorkflowProcessing.DoesFlowHasEDocService(EDocService, WorkflowCode);
        EDocService.FindSet();
        Assert.AreEqual(1, EDocService.Count(), WrongValueErr);
        Assert.AreEqual(ServiceCode, EDocService.Code, WrongValueErr);
    end;

    [Test]
    [Obsolete('Obsolete in 26.0', '26.0')]
    procedure EDocFlowGetServicesInFlowSuccess()
    var
        EDocService: Record "E-Document Service";
        EDocWorkflowProcessing: Codeunit "E-Document WorkFlow Processing";
        CustomerNo, DocSendProfileNo, WorkflowCode, ServiceCodeA, ServiceCodeB : Code[20];
    begin
        // [FEATURE] [E-Document] [Flow]
        // [SCENARIO] Get services from workflow with multiple services

        // [GIVEN] Created posting a document
        Initialize();

        // [WHEN] Creating worfklow with Service A and B
        CustomerNo := LibrarySales.CreateCustomerNo();
        DocSendProfileNo := LibraryEDoc.CreateDocumentSendingProfileForWorkflow(CustomerNo, '');
        ServiceCodeA := LibraryEDoc.CreateService(Enum::"E-Document Integration"::Mock);
        ServiceCodeB := LibraryEDoc.CreateService(Enum::"E-Document Integration"::Mock);
        WorkflowCode := LibraryEDoc.CreateFlowWithServices(DocSendProfileNo, ServiceCodeA, ServiceCodeB);

        // [THEN] DoesFlowHasEDocService returns service A and B
        EDocWorkflowProcessing.DoesFlowHasEDocService(EDocService, WorkflowCode);
        Assert.AreEqual(2, EDocService.Count(), WrongValueErr);
        EDocService.FindSet();
        Assert.AreEqual(ServiceCodeA, EDocService.Code, WrongValueErr);
        EDocService.Next();
        Assert.AreEqual(ServiceCodeB, EDocService.Code, WrongValueErr);
    end;
#pragma warning restore AL0432
#endif

    [Test]
    procedure EDocFlowShipmentCreatedWhenServiceDoesNotSupportTypeButEmailExists()
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        Customer: Record Customer;
        EDocService: Record "E-Document Service";
        DocumentSendingProfile: Record "Document Sending Profile";
        CustomerNo, DocSendProfileNo, WorkflowCode, ServiceCode : Code[20];
    begin
        // [FEATURE] [E-Document] [Flow]
        // [SCENARIO] E-Document is created for Sales Shipment when service does not support 
        // the type, but workflow contains email responses

        // [GIVEN] Service that supports Sales Invoice but NOT Sales Shipment, workflow with Send + Email
        Initialize();
        LibraryEDoc.SetupStandardVAT();

        CustomerNo := LibrarySales.CreateCustomerNo();
        DocSendProfileNo := LibraryEDoc.CreateDocumentSendingProfileForWorkflow(CustomerNo, '');
        ServiceCode := LibraryEDoc.CreateService(Enum::"Service Integration"::"Mock");
        // Standard service supports Sales Invoice, not Sales Shipment
        WorkflowCode := LibraryEDoc.CreateFlowWithServiceAndEmail(DocSendProfileNo, ServiceCode);
        LibraryEDoc.UpdateWorkflowOnDocumentSendingProfile(DocSendProfileNo, WorkflowCode);

        // [WHEN] Posting a Sales Shipment (type not supported by service)
        EDocService.Get(ServiceCode);
        Customer.Get(CustomerNo);
        LibraryLowerPermission.SetTeamMember();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        LibraryEDoc.PostSalesShipment(Customer);

        // [THEN] E-Document should be created for Sales Shipment
        EDocument.FindLast();
        Assert.AreEqual(Enum::"E-Document Type"::"Sales Shipment", EDocument."Document Type", WrongValueErr);
        Assert.AreEqual(WorkflowCode, EDocument."Workflow Code", WrongValueErr);

        // [THEN] No service status should exist (service does not support type)
        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        Assert.IsTrue(EDocumentServiceStatus.IsEmpty(), 'No service status should exist for unsupported document type');
    end;

    [Test]
    procedure EDocFlowSendSkippedForUnsupportedDocType()
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowStepInstance: Record "Workflow Step Instance";
        EDocWorkflowProcessing: Codeunit "E-Document WorkFlow Processing";
        RecordRef: RecordRef;
        CustomerNo, DocSendProfileNo, ServiceCode : Code[20];
    begin
        // [FEATURE] [E-Document] [Flow]
        // [SCENARIO] SendEDocument skips when service does not support the document type and sets Sent status

        // [GIVEN] E-Document with type Sales Shipment, service that only supports Sales Invoice
        Initialize();

        CustomerNo := LibrarySales.CreateCustomerNo();
        DocSendProfileNo := LibraryEDoc.CreateDocumentSendingProfileForWorkflow(CustomerNo, '');
        ServiceCode := LibraryEDoc.CreateService(Enum::"Service Integration"::"Mock");
        LibraryEDoc.CreateFlowWithService(DocSendProfileNo, ServiceCode);

        EDocument."Entry No" := 0;
        EDocument."Document Type" := Enum::"E-Document Type"::"Sales Shipment";
        EDocument.Insert();

        // [WHEN] Calling SendEDocument with a service that does not support the type
        WorkflowStepArgument.FindLast();
        WorkflowStepInstance.Argument := WorkflowStepArgument.ID;

        LibraryLowerPermission.SetTeamMember();
        RecordRef.GetTable(EDocument);
        EDocWorkflowProcessing.SendEDocument(RecordRef, WorkflowStepInstance);

        // [THEN] Service status is Sent (skipped sending, but workflow can continue)
        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        EDocumentServiceStatus.SetRange("E-Document Service Code", ServiceCode);
        Assert.IsTrue(EDocumentServiceStatus.FindFirst(), 'Service status should exist after skip');
        Assert.AreEqual(Enum::"E-Document Service Status"::Sent, EDocumentServiceStatus.Status, 'Service status should be Sent when type is not supported');
    end;

    [Test]
    procedure EDocFlowEmailOnlyWorkflowCreatesEDocument()
    var
        EDocument: Record "E-Document";
        Customer: Record Customer;
        CustomerNo, DocSendProfileNo, WorkflowCode : Code[20];
    begin
        // [FEATURE] [E-Document] [Flow]
        // [SCENARIO] E-Document created when workflow has only email response and no service responses

        // [GIVEN] Workflow with only email response (no service/send response)
        Initialize();
        LibraryEDoc.SetupStandardVAT();

        CustomerNo := LibrarySales.CreateCustomerNo();
        DocSendProfileNo := LibraryEDoc.CreateDocumentSendingProfileForWorkflow(CustomerNo, '');
        WorkflowCode := LibraryEDoc.CreateFlowWithEmailOnly(DocSendProfileNo);
        LibraryEDoc.UpdateWorkflowOnDocumentSendingProfile(DocSendProfileNo, WorkflowCode);

        // [WHEN] Posting a Sales Invoice
        Customer.Get(CustomerNo);
        LibraryLowerPermission.SetTeamMember();
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);
        LibraryEDoc.PostInvoice(Customer);

        // [THEN] E-Document should be created even without any service
        EDocument.FindLast();
        Assert.AreEqual(Enum::"E-Document Type"::"Sales Invoice", EDocument."Document Type", WrongValueErr);
        Assert.AreEqual(WorkflowCode, EDocument."Workflow Code", WrongValueErr);
    end;

    local procedure Initialize()
    var
        TransformationRule: Record "Transformation Rule";
    begin
        LibraryLowerPermission.SetOutsideO365Scope();
        LibraryVariableStorage.Clear();
        LibraryEDoc.Initialize();
        TransformationRule.DeleteAll();
        TransformationRule.CreateDefaultTransformations();
    end;

}
