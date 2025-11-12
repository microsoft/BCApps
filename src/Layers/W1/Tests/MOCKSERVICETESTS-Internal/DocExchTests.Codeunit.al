codeunit 139159 "Doc.Exch.Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Document Exchange Service]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInvt: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
        IsInitialized: Boolean;
        TestDocExchServiceServiceBaseURLTxt: Label 'https://localhost:8080/DocExchServiceService', Locked = true;
        ForceStatus500Txt: Label '/status500', Locked = true;
        ForceStatus404Txt: Label '/status404', Locked = true;
        ForceStatus403Txt: Label '/status403', Locked = true;
        ForceStatus200Txt: Label '/status200', Locked = true;
        ForcedErrorTxt: Label '/errforced', Locked = true;
        ForcedLongErrorTxt: Label '/longerrforced', Locked = true;
        DocumentSendFailureTxt: Label '/VANForceSendErr', Locked = true;
        ServiceErr: Label 'The remote server returned an error: %1', Locked = true;
        Service500Err: Label 'The remote service has returned the following error message:\\%1', Locked = true;
        ConnectionSuccessfulTxt: Label 'The connection test was successful. The settings are valid.';
        DocumentSentSuccessTxt: Label 'The document was successfully sent to the document exchange service for processing.', Comment = '%1=Posted document number';
        DocExchServiceServiceDisabledErr: Label 'The document exchange service is not enabled.';
        CheckConnectionLogMsg: Label 'Check connection.';
        SendDocumentLogMsg: Label 'Send document.';
        DispatchLogMsg: Label 'Dispatch document.';
        CheckLatestStatusQst: Label 'Do you want to check the latest status of the electronic document?';
        MalformedGuidErr: Label 'The document exchange service did not return a valid document identifier.';
        InvalidGuidErr: Label 'Invalid format of GUID string.';

    local procedure Initialize()
    var
        CompanyInfo: Record "Company Information";
    begin
        LibraryVariableStorage.Clear();
        SetupDocExch();

        if IsInitialized then
            exit;

        CompanyInfo.Get();
        CompanyInfo.Validate("SWIFT Code", 'MIDLGB22Z0K');
        CompanyInfo.Modify();

        ConfigureVATPostingSetup();
        ConfigureDocumentFormats();

        IsInitialized := true;
    end;

    local procedure SetupDocExch()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Set up DocExchService service
        if DocExchServiceSetup.Get() then
            DocExchServiceSetup.Delete();

        Clear(DocExchServiceSetup);
        DocExchServiceSetup.Insert();

        DocExchServiceSetup."Service URL" := TestDocExchServiceServiceBaseURLTxt;
        DocExchServiceSetup."Auth URL" := TestDocExchServiceServiceBaseURLTxt + '/auth/login';
        DocExchServiceSetup."Token URL" := TestDocExchServiceServiceBaseURLTxt + '/auth/token';
        DocExchServiceSetup."Sign-up URL" := TestDocExchServiceServiceBaseURLTxt + '/register';
        DocExchServiceSetup."Sign-in URL" := TestDocExchServiceServiceBaseURLTxt + '/login';
        DocExchServiceSetup."User Agent" := 'UserAgentTest';
        DocExchServiceSetup."Client Id" := Format(CreateGuid());
        DocExchServiceSetup.SetClientSecret(Format(CreateGuid()));
        DocExchServiceSetup.SetAccessToken(Format(CreateGuid()));
        DocExchServiceSetup.SetRefreshToken(Format(CreateGuid()));
        DocExchServiceSetup.SetDefaultRedirectUrl();
        DocExchServiceSetup.Enabled := true;
        DocExchServiceSetup.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHandles500()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Setup
        Initialize();
        DocExchServiceSetup.Get();
        DocExchServiceSetup."Service URL" := DocExchServiceSetup."Service URL" + ForceStatus500Txt;
        DocExchServiceSetup.Modify();

        // Exercise
        asserterror DocExchServiceSetup.CheckConnection();
        Assert.ExpectedError(StrSubstNo(Service500Err, StrSubstNo(ServiceErr, '(500) Server Error')));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHandles404()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Setup
        Initialize();
        DocExchServiceSetup.Get();
        DocExchServiceSetup."Service URL" := DocExchServiceSetup."Service URL" + ForceStatus404Txt;
        DocExchServiceSetup.Modify();

        // Exercise
        asserterror DocExchServiceSetup.CheckConnection();
        Assert.ExpectedError(StrSubstNo(ServiceErr, '(404) Not Found'));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestServiceHandles403()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Setup
        Initialize();
        DocExchServiceSetup.Get();
        DocExchServiceSetup."Service URL" := DocExchServiceSetup."Service URL" + ForceStatus403Txt;
        DocExchServiceSetup.Modify();

        // Exercise
        asserterror DocExchServiceSetup.CheckConnection();
        Assert.ExpectedError(StrSubstNo(ServiceErr, '(403) Forbidden'));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestServiceHandles200()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Setup
        Initialize();
        DocExchServiceSetup.Get();
        DocExchServiceSetup."Service URL" := DocExchServiceSetup."Service URL" + ForceStatus200Txt;
        DocExchServiceSetup.Modify();

        // Expected Message
        LibraryVariableStorage.Enqueue(ConnectionSuccessfulTxt);

        // Exercise
        DocExchServiceSetup.CheckConnection();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchSendWhenDisabled()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Setup
        Initialize();
        DocExchServiceSetup.Get();
        DocExchServiceSetup."Service URL" := DocExchServiceSetup."Service URL" + ForceStatus200Txt;
        DocExchServiceSetup.Validate(Enabled, false);
        DocExchServiceSetup.Modify();

        CreateGenericSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        // Exercise
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();
        asserterror ReportDistributionManagement.VANDocumentReport(SalesInvoiceHeader, TempDocumentSendingProfile);

        // Assert
        Assert.ExpectedError(DocExchServiceServiceDisabledErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchSendUBLSalesInvoice()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempBlob: Codeunit "Temp Blob";
        DocumentVariant: Variant;
        ClientFileName: Text[250];
    begin
        // Setup
        Initialize();

        // Exercise
        SetupDefaultDocExchServiceDocumentSendingProfilePostSalesInvoice(
          TempDocumentSendingProfile, SalesInvoiceHeader);

        // Expected Message
        LibraryVariableStorage.Enqueue(StrSubstNo(DocumentSentSuccessTxt, SalesInvoiceHeader."No."));

        DocumentVariant := SalesInvoiceHeader;
        ElectronicDocumentFormat.SendElectronically(
            TempBlob, ClientFileName, DocumentVariant, TempDocumentSendingProfile."Electronic Format");
        DocExchServiceMgt.SendUBLDocument(SalesInvoiceHeader, TempBlob);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchSendUBLSalesCrM()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        TempBlob: Codeunit "Temp Blob";
        DocumentVariant: Variant;
        ClientFileName: Text[250];
    begin
        // Setup
        Initialize();

        // Exercise
        SetupDefaultDocExchServiceDocumentSendingProfilePostSalesCrMemo(
          TempDocumentSendingProfile, SalesCrMemoHeader);

        // Expected Message
        LibraryVariableStorage.Enqueue(StrSubstNo(DocumentSentSuccessTxt, SalesCrMemoHeader."No."));

        DocumentVariant := SalesCrMemoHeader;
        ElectronicDocumentFormat.SendElectronically(
            TempBlob, ClientFileName, DocumentVariant, TempDocumentSendingProfile."Electronic Format");
        DocExchServiceMgt.SendUBLDocument(SalesCrMemoHeader, TempBlob);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchSendSalesInvSucces()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ActivityLog: Record "Activity Log";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        // Setup
        Initialize();

        // Exercise
        SetupDefaultDocExchServiceDocumentSendingProfilePostSalesInvoice(
          TempDocumentSendingProfile, SalesInvoiceHeader);

        // Expected Message
        LibraryVariableStorage.Enqueue(StrSubstNo(DocumentSentSuccessTxt, SalesInvoiceHeader."No."));

        ReportDistributionManagement.VANDocumentReport(SalesInvoiceHeader, TempDocumentSendingProfile);

        SalesInvoiceHeader.Find();
        // doc id is hardcoded in the HTPP response from the mock server
        Assert.AreEqual('21EC2020-3AEA-4069-A2DD-08002B30309D', SalesInvoiceHeader."Document Exchange Identifier",
          'Doc identifier is not the expected one.');
        Assert.AreEqual(SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service",
          SalesInvoiceHeader."Document Exchange Status", 'Document status is not the expected one.');

        // Assert Log Entry
        ActivityLog.SetRange(Status, ActivityLog.Status::Success);
        Assert.IsTrue(ActivityLog.FindLast(), 'No succeeded statuses have been logged');
        Assert.AreEqual(Format(DispatchLogMsg), ActivityLog.Description, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchSendSalesInvBadGuid()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        ActivityLog: Record "Activity Log";
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Setup
        Initialize();

        DocExchServiceSetup.Get();
        DocExchServiceSetup.Validate("Service URL", TestDocExchServiceServiceBaseURLTxt + '/badref');
        DocExchServiceSetup.Modify();

        CreateGenericSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        // Exercise
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();

        // Expected Message
        LibraryVariableStorage.Enqueue(StrSubstNo(DocumentSentSuccessTxt, SalesInvoiceHeader."No."));

        asserterror ReportDistributionManagement.VANDocumentReport(SalesInvoiceHeader, TempDocumentSendingProfile);
        Assert.ExpectedError(Format(InvalidGuidErr));

        // Assert Log Entry
        ActivityLog.SetRange(Status, ActivityLog.Status::Failed);
        Assert.IsTrue(ActivityLog.FindLast(), 'No failed statuses have been logged');
        Assert.AreEqual(Format(DispatchLogMsg), ActivityLog.Description, '');
    end;

    local procedure DocExchSendSalesInvDispatchError(var SalesInvoiceHeader: Record "Sales Invoice Header"; AddedURL: Text): Text
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        ReportDistributionManagement: Codeunit "Report Distribution Management";
        DocExchServiceMgt: Codeunit "Doc. Exch. Service Mgt.";
    begin
        // Setup
        Initialize();

        // Exercise
        SetupDefaultDocExchServiceDocumentSendingProfilePostSalesInvoice(
          TempDocumentSendingProfile, SalesInvoiceHeader);

        LibraryVariableStorage.Enqueue(StrSubstNo(DocumentSentSuccessTxt, SalesInvoiceHeader."No."));
        ReportDistributionManagement.VANDocumentReport(SalesInvoiceHeader, TempDocumentSendingProfile);

        DocExchServiceSetup.Get();
        DocExchServiceSetup."Service URL" :=
          CopyStr(DocExchServiceSetup."Service URL" + AddedURL, 1, MaxStrLen(DocExchServiceSetup."Service URL"));
        DocExchServiceSetup.Modify();

        SalesInvoiceHeader.Find();
        exit(DocExchServiceMgt.GetDocumentStatus(SalesInvoiceHeader.RecordId,
            SalesInvoiceHeader."Document Exchange Identifier",
            SalesInvoiceHeader."Doc. Exch. Original Identifier"));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchSendSalesInvDispatchErrs()
    var
        ActivityLog: Record "Activity Log";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Errors: Text;
    begin
        // Setup and initialize
        Errors := DocExchSendSalesInvDispatchError(SalesInvoiceHeader, ForcedErrorTxt);

        // Verify
        // the error msg is hardcoded in the HTPP response from the mock server
        // status will be failed and msg logged
        Assert.AreEqual('FAILED', Errors, '');
        ActivityLog.SetRange(Status, ActivityLog.Status::Success);
        ActivityLog.SetRange("Record ID", SalesInvoiceHeader.RecordId);
        Assert.IsTrue(ActivityLog.FindLast(), 'No success statuses have been logged');
        Assert.AreEqual('Dummy dispatch error', ActivityLog."Activity Message", '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchSendSalesInvDispatchLongError()
    var
        ActivityLog: Record "Activity Log";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Errors: Text;
    begin
        // Setup and initialize
        Errors := DocExchSendSalesInvDispatchError(SalesInvoiceHeader, ForcedLongErrorTxt);

        // Verify
        // the error msg is hardcoded in the HTPP response from the mock server
        // status will be failed and msg logged
        Assert.AreEqual('FAILED', Errors, '');
        ActivityLog.SetRange(Status, ActivityLog.Status::Success);
        ActivityLog.SetRange("Record ID", SalesInvoiceHeader.RecordId);
        Assert.IsTrue(ActivityLog.FindLast(), 'No success statuses have been logged');
        ActivityLog.CalcFields("Detailed Info");
        Assert.IsTrue(ActivityLog."Detailed Info".HasValue, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchResendInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        // Setup
        Initialize();

        SetupDefaultDocExchServiceDocumentSendingProfilePostSalesInvoice(
          TempDocumentSendingProfile, SalesInvoiceHeader);

        // Expected Message
        LibraryVariableStorage.Enqueue(StrSubstNo(DocumentSentSuccessTxt, SalesInvoiceHeader."No."));
        ReportDistributionManagement.VANDocumentReport(SalesInvoiceHeader, TempDocumentSendingProfile);

        // Exercise - resend
        SalesInvoiceHeader.Find();
        LibraryVariableStorage.Enqueue(StrSubstNo(DocumentSentSuccessTxt, SalesInvoiceHeader."No."));
        asserterror ReportDistributionManagement.VANDocumentReport(SalesInvoiceHeader, TempDocumentSendingProfile);

        // Verify
        Assert.ExpectedError('You cannot send this electronic document because it is already delivered or in progress.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchSendSalesCrMSucces()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ActivityLog: Record "Activity Log";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        // Setup
        Initialize();

        // Exercise
        SetupDefaultDocExchServiceDocumentSendingProfilePostSalesCrMemo(
          TempDocumentSendingProfile, SalesCrMemoHeader);

        // Expected Message
        LibraryVariableStorage.Enqueue(StrSubstNo(DocumentSentSuccessTxt, SalesCrMemoHeader."No."));

        ReportDistributionManagement.VANDocumentReport(SalesCrMemoHeader, TempDocumentSendingProfile);

        SalesCrMemoHeader.Find();
        // doc id is hardcoded in the HTPP response from the mock server
        Assert.AreEqual('21EC2020-3AEA-4069-A2DD-08002B30309D', SalesCrMemoHeader."Document Exchange Identifier",
          'Doc identifier is not the expected one.');
        Assert.AreEqual(SalesCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service",
          SalesCrMemoHeader."Document Exchange Status", 'Document status is not the expected one.');

        // Assert Log Entry
        ActivityLog.SetRange(Status, ActivityLog.Status::Success);
        Assert.IsTrue(ActivityLog.FindLast(), 'No succeeded statuses have been logged');
        Assert.AreEqual(Format(DispatchLogMsg), ActivityLog.Description, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchResendSalesCrM()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        // Setup
        Initialize();

        // Exercise
        SetupDefaultDocExchServiceDocumentSendingProfilePostSalesCrMemo(
          TempDocumentSendingProfile, SalesCrMemoHeader);

        LibraryVariableStorage.Enqueue(StrSubstNo(DocumentSentSuccessTxt, SalesCrMemoHeader."No."));
        ReportDistributionManagement.VANDocumentReport(SalesCrMemoHeader, TempDocumentSendingProfile);

        // Exercise - resend
        SalesCrMemoHeader.Find();
        LibraryVariableStorage.Enqueue(StrSubstNo(DocumentSentSuccessTxt, SalesCrMemoHeader."No."));
        asserterror ReportDistributionManagement.VANDocumentReport(SalesCrMemoHeader, TempDocumentSendingProfile);

        // Verify
        Assert.ExpectedError('You cannot send this electronic document because it is already delivered or in progress.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchSendServiceInvSucces()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ActivityLog: Record "Activity Log";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        // Setup
        Initialize();
        CreateServiceInvoiceAndPost(ServiceInvoiceHeader);

        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        // Expected Message
        LibraryVariableStorage.Enqueue(StrSubstNo(DocumentSentSuccessTxt, ServiceInvoiceHeader."No."));

        ReportDistributionManagement.VANDocumentReport(ServiceInvoiceHeader, TempDocumentSendingProfile);

        ServiceInvoiceHeader.Find();
        // doc id is hardcoded in the HTPP response from the mock server
        Assert.AreEqual('21EC2020-3AEA-4069-A2DD-08002B30309D', ServiceInvoiceHeader."Document Exchange Identifier",
          'Doc identifier is not the expected one.');
        Assert.AreEqual(ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service",
          ServiceInvoiceHeader."Document Exchange Status", 'Document status is not the expected one.');

        // Assert Log Entry
        ActivityLog.SetRange(Status, ActivityLog.Status::Success);
        Assert.IsTrue(ActivityLog.FindLast(), 'No succeeded statuses have been logged');
        Assert.AreEqual(Format(DispatchLogMsg), ActivityLog.Description, '');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchSendServiceCMSucces()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ActivityLog: Record "Activity Log";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        // Setup
        Initialize();
        CreateServiceCreditMemoAndPost(ServiceCrMemoHeader);

        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        // Expected Message
        LibraryVariableStorage.Enqueue(StrSubstNo(DocumentSentSuccessTxt, ServiceCrMemoHeader."No."));

        ReportDistributionManagement.VANDocumentReport(ServiceCrMemoHeader, TempDocumentSendingProfile);

        ServiceCrMemoHeader.Find();
        // doc id is hardcoded in the HTPP response from the mock server
        Assert.AreEqual('21EC2020-3AEA-4069-A2DD-08002B30309D', ServiceCrMemoHeader."Document Exchange Identifier",
          'Doc identifier is not the expected one.');
        Assert.AreEqual(ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service",
          ServiceCrMemoHeader."Document Exchange Status", 'Document status is not the expected one.');

        // Assert Log Entry
        ActivityLog.SetRange(Status, ActivityLog.Status::Success);
        Assert.IsTrue(ActivityLog.FindLast(), 'No succeeded statuses have been logged');
        Assert.AreEqual(Format(DispatchLogMsg), ActivityLog.Description, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLogErrorOnConnectionFailure()
    var
        ActivityLog: Record "Activity Log";
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Setup
        Initialize();
        DocExchServiceSetup.Get();
        DocExchServiceSetup."Service URL" := DocExchServiceSetup."Service URL" + ForceStatus500Txt;
        DocExchServiceSetup.Modify();

        // Clear Activity Log
        ActivityLog.DeleteAll();

        // Exercise
        asserterror DocExchServiceSetup.CheckConnection();
        Assert.ExpectedError(StrSubstNo(Service500Err, StrSubstNo(ServiceErr, '(500) Server Error')));

        // Assert Log Entry
        ActivityLog.SetRange(Status, ActivityLog.Status::Failed);
        Assert.IsTrue(ActivityLog.FindLast(), 'No failed statuses have been logged');
        Assert.AreEqual(Format(CheckConnectionLogMsg), ActivityLog.Description, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLogErrorOnDocumentSendFailure()
    var
        ActivityLog: Record "Activity Log";
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        ReportDistributionManagement: Codeunit "Report Distribution Management";
    begin
        // Setup
        Initialize();
        DocExchServiceSetup.Get();
        DocExchServiceSetup."Service URL" := DocExchServiceSetup."Service URL" + DocumentSendFailureTxt;
        DocExchServiceSetup.Modify();

        // Clear Activity Log
        ActivityLog.DeleteAll();

        // Create Sales Document
        // Exercise
        SetupDefaultDocExchServiceDocumentSendingProfilePostSalesInvoice(
          TempDocumentSendingProfile, SalesInvoiceHeader);

        asserterror ReportDistributionManagement.VANDocumentReport(SalesInvoiceHeader, TempDocumentSendingProfile);
        Assert.ExpectedError(StrSubstNo(Service500Err, StrSubstNo(ServiceErr, '(500) Server Error')));

        // Assert Log Entry
        ActivityLog.SetRange(Status, ActivityLog.Status::Failed);
        Assert.IsTrue(ActivityLog.FindLast(), 'No failed statuses have been logged');
        Assert.AreEqual(Format(SendDocumentLogMsg), ActivityLog.Description, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchReceive()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        // Setup
        Initialize();

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Doc. Exch. Serv. - Recv. Docs.");

        // Verify - responses are hardcoded in the mock service
        IncomingDocument.SetRange(Description, 'Invoice 103036');
        Assert.IsTrue(IncomingDocument.FindFirst(),
          'Incoming document with identifier "Invoice 103036" was not created.');
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
        IncomingDocumentAttachment.SetRange(Name, 'test');
        IncomingDocumentAttachment.SetRange("File Extension", 'jpg');
        IncomingDocumentAttachment.SetRange("Main Attachment", false);
        Assert.IsTrue(IncomingDocumentAttachment.FindFirst(),
          'Secondary attachment for Incoming document with identifier "Invoice 103036" has not been created.');
        IncomingDocument.SetRange(Description, 'Credit Memo 103037');
        Assert.IsTrue(IncomingDocument.FindFirst(),
          'Incoming document with identifier Credit Memo 103037 was not created.');
        IncomingDocument.SetRange(Description, 'Credit Memo 103038');
        Assert.IsTrue(IncomingDocument.FindFirst(),
          'Incoming document with identifier Credit Memo 103038 was not created.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchReceive_InvalidReference()
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
    begin
        // Setup
        Initialize();

        DocExchServiceSetup.Get();
        DocExchServiceSetup."Service URL" := TestDocExchServiceServiceBaseURLTxt + '/badref';
        DocExchServiceSetup.Modify();

        // Exercise
        asserterror CODEUNIT.Run(CODEUNIT::"Doc. Exch. Serv. - Recv. Docs.");
        Assert.ExpectedError(MalformedGuidErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchCUCheckStatusInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Setup
        Initialize();

        CreateGenericSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        // Exercise
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.Validate("Document Exchange Status",
          SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        SalesInvoiceHeader.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Doc. Exch. Serv.- Doc. Status");

        // Verify - response is hardcoded in the HTTP response in mock server
        SalesInvoiceHeader.Find();
        Assert.AreEqual(SalesInvoiceHeader."Document Exchange Status"::"Delivered to Recipient",
          SalesInvoiceHeader."Document Exchange Status", 'Status was not updated properly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchCUCheckStatusCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Setup
        Initialize();

        CreateGenericSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        // Exercise
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.Validate("Document Exchange Status",
          SalesCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        SalesCrMemoHeader.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Doc. Exch. Serv.- Doc. Status");

        // Verify - response is hardcoded in the HTTP response in mock server
        SalesCrMemoHeader.Find();
        Assert.AreEqual(SalesCrMemoHeader."Document Exchange Status"::"Delivered to Recipient",
          SalesCrMemoHeader."Document Exchange Status", 'Status was not updated properly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchCUCheckStatusServiceInvoice()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
    begin
        // Setup
        Initialize();

        CreateServiceInvoiceAndPost(ServiceInvoiceHeader);

        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        // Exercise
        ServiceInvoiceHeader.Validate("Document Exchange Status",
          ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        ServiceInvoiceHeader.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Doc. Exch. Serv.- Doc. Status");

        // Verify - response is hardcoded in the HTTP response in mock server
        ServiceInvoiceHeader.Find();
        Assert.AreEqual(ServiceInvoiceHeader."Document Exchange Status"::"Delivered to Recipient",
          ServiceInvoiceHeader."Document Exchange Status", 'Status was not updated properly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDocExchCUCheckStatusServiceCrMemo()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
    begin
        // Setup
        Initialize();

        CreateServiceCreditMemoAndPost(ServiceCrMemoHeader);

        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        // Exercise
        ServiceCrMemoHeader.Validate("Document Exchange Status",
          ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        ServiceCrMemoHeader.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Doc. Exch. Serv.- Doc. Status");

        // Verify - response is hardcoded in the HTTP response in mock server
        ServiceCrMemoHeader.Find();
        Assert.AreEqual(ServiceCrMemoHeader."Document Exchange Status"::"Delivered to Recipient",
          ServiceCrMemoHeader."Document Exchange Status", 'Status was not updated properly');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ActivityLogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchUICheckStatusInvoiceDelivered()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        TestDocExchUICheckStatusInvoice(SalesInvoiceHeader."Document Exchange Status"::"Delivered to Recipient");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ActivityLogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchUICheckStatusInvoicePendingConnection()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        TestDocExchUICheckStatusInvoice(SalesInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ActivityLogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchUICheckStatusCrMemoDelivered()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        TestDocExchUICheckStatusCrMemo(SalesCrMemoHeader."Document Exchange Status"::"Delivered to Recipient");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ActivityLogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchUICheckStatusCrMemoPendingConnection()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        TestDocExchUICheckStatusCrMemo(SalesCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ActivityLogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchUICheckStatusServiceInvoiceDelivered()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        TestDocExchUICheckStatusServiceInvoice(ServiceInvoiceHeader."Document Exchange Status"::"Delivered to Recipient");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ActivityLogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchUICheckStatusServiceInvoicePendingConnection()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        TestDocExchUICheckStatusServiceInvoice(ServiceInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ActivityLogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchUICheckStatusServiceCrMemoDelivered()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        TestDocExchUICheckStatusServiceCrMemo(ServiceCrMemoHeader."Document Exchange Status"::"Delivered to Recipient");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ActivityLogModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchUICheckStatusServiceCrMemoPendingConnection()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        TestDocExchUICheckStatusServiceCrMemo(ServiceCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient");
    end;

    local procedure TestDocExchUICheckStatusInvoice(DocState: Enum "Sales Document Exchange Status")
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        LibrarySales: Codeunit "Library - Sales";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        // Setup
        Initialize();

        if DocState = SalesInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient" then begin
            DocExchServiceSetup.Get();
            DocExchServiceSetup."Service URL" := StrSubstNo('%1/%2', TestDocExchServiceServiceBaseURLTxt, 'pending');
            DocExchServiceSetup.Modify();
        end;

        CreateGenericSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        // Exercise
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.Validate("Document Exchange Status",
          SalesInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        SalesInvoiceHeader.Modify(true);

        EnqueueConfirmMsgAndResponse(CheckLatestStatusQst, true);
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.GotoRecord(SalesInvoiceHeader);
        PostedSalesInvoice."Document Exchange Status".DrillDown();

        // Verify - in the modal page handler
        SalesInvoiceHeader.Find();
        Assert.AreEqual(DocState, SalesInvoiceHeader."Document Exchange Status", '');
    end;

    local procedure TestDocExchUICheckStatusCrMemo(DocState: Enum "Sales Document Exchange Status")
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        LibrarySales: Codeunit "Library - Sales";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // Setup
        Initialize();

        if DocState = SalesCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient" then begin
            DocExchServiceSetup.Get();
            DocExchServiceSetup."Service URL" := StrSubstNo('%1/%2', TestDocExchServiceServiceBaseURLTxt, 'pending');
            DocExchServiceSetup.Modify();
        end;

        CreateGenericSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        // Exercise
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.Validate("Document Exchange Status",
          SalesCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        SalesCrMemoHeader.Modify(true);

        EnqueueConfirmMsgAndResponse(CheckLatestStatusQst, true);
        PostedSalesCreditMemo.OpenView();
        PostedSalesCreditMemo.GotoRecord(SalesCrMemoHeader);
        PostedSalesCreditMemo."Document Exchange Status".DrillDown();

        // Verify - in the modal page handler
        SalesCrMemoHeader.Find();
        Assert.AreEqual(DocState, SalesCrMemoHeader."Document Exchange Status", '');
    end;

    local procedure TestDocExchUICheckStatusServiceInvoice(DocState: Enum "Service Document Exchange Status")
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        PostedServiceInvoice: TestPage "Posted Service Invoice";
    begin
        // Setup
        Initialize();

        if DocState = ServiceInvoiceHeader."Document Exchange Status"::"Pending Connection to Recipient" then begin
            DocExchServiceSetup.Get();
            DocExchServiceSetup."Service URL" := StrSubstNo('%1/%2', TestDocExchServiceServiceBaseURLTxt, 'pending');
            DocExchServiceSetup.Modify();
        end;

        CreateServiceInvoiceAndPost(ServiceInvoiceHeader);
        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        // Exercise
        ServiceInvoiceHeader.Validate("Document Exchange Status",
          ServiceInvoiceHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        ServiceInvoiceHeader.Modify(true);

        EnqueueConfirmMsgAndResponse(CheckLatestStatusQst, true);
        PostedServiceInvoice.OpenView();
        PostedServiceInvoice.GotoRecord(ServiceInvoiceHeader);
        PostedServiceInvoice."Document Exchange Status".DrillDown();

        // Verify - in the modal page handler
        ServiceInvoiceHeader.Find();
        Assert.AreEqual(DocState, ServiceInvoiceHeader."Document Exchange Status", '');
    end;

    local procedure TestDocExchUICheckStatusServiceCrMemo(DocState: Enum "Service Document Exchange Status")
    var
        DocExchServiceSetup: Record "Doc. Exch. Service Setup";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        TempDocumentSendingProfile: Record "Document Sending Profile" temporary;
        PostedServiceCreditMemos: TestPage "Posted Service Credit Memos";
    begin
        // Setup
        Initialize();

        if DocState = ServiceCrMemoHeader."Document Exchange Status"::"Pending Connection to Recipient" then begin
            DocExchServiceSetup.Get();
            DocExchServiceSetup."Service URL" := StrSubstNo('%1/%2', TestDocExchServiceServiceBaseURLTxt, 'pending');
            DocExchServiceSetup.Modify();
        end;

        CreateServiceCreditMemoAndPost(ServiceCrMemoHeader);
        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        // Exercise
        ServiceCrMemoHeader.Validate("Document Exchange Status",
          ServiceCrMemoHeader."Document Exchange Status"::"Sent to Document Exchange Service");
        ServiceCrMemoHeader.Modify(true);

        EnqueueConfirmMsgAndResponse(CheckLatestStatusQst, true);
        PostedServiceCreditMemos.OpenView();
        PostedServiceCreditMemos.GotoRecord(ServiceCrMemoHeader);
        PostedServiceCreditMemos."Document Exchange Status".DrillDown();

        // Verify - in the modal page handler
        ServiceCrMemoHeader.Find();
        Assert.AreEqual(DocState, ServiceCrMemoHeader."Document Exchange Status", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvoiceMapsToCorrectDataExchFormat()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        LibrarySales: Codeunit "Library - Sales";
        FileManagement: Codeunit "File Management";
        SalesInvoicePeppolBIS30: XMLport "Sales Invoice - PEPPOL BIS 3.0";
        TempFile: File;
        OutStream: OutStream;
        InStream: InStream;
    begin
        Initialize();

        // Setup
        CreateGenericSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        TempFile.Create(FileManagement.ServerTempFileName('.xml'));
        TempFile.CreateOutStream(OutStream);

        SalesInvoicePeppolBIS30.Initialize(SalesInvoiceHeader);
        SalesInvoicePeppolBIS30.SetDestination(OutStream);
        SalesInvoicePeppolBIS30.Export();

        TempFile.CreateInStream(InStream);

        IncomingDocument.Init();
        IncomingDocument.Validate(Description, 'Test');
        IncomingDocument.Insert(true);

        IncomingDocument.AddAttachmentFromStream(IncomingDocumentAttachment, 'test file', 'xml', InStream);

        // Validate
        Assert.AreEqual('', IncomingDocument."Data Exchange Type", '');

        // Exercise
        IncomingDocumentAttachment.Validate(Default, true);
        IncomingDocumentAttachment.Modify(true);

        // Validate
        IncomingDocument.Find();
        Assert.AreEqual('PEPPOLINVOICE', IncomingDocument."Data Exchange Type", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreditMemoMapsToCorrectDataExchFormat()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        LibrarySales: Codeunit "Library - Sales";
        FileManagement: Codeunit "File Management";
        SalesCrMemoPEPPOLBIS30: XMLport "Sales Cr.Memo - PEPPOL BIS 3.0";
        TempFile: File;
        OutStream: OutStream;
        InStream: InStream;
    begin
        Initialize();

        // Setup
        CreateGenericSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        TempFile.Create(FileManagement.ServerTempFileName('.xml'));
        TempFile.CreateOutStream(OutStream);

        SalesCrMemoPEPPOLBIS30.Initialize(SalesCrMemoHeader);
        SalesCrMemoPEPPOLBIS30.SetDestination(OutStream);
        SalesCrMemoPEPPOLBIS30.Export();

        TempFile.CreateInStream(InStream);

        IncomingDocument.Init();
        IncomingDocument.Validate(Description, 'Test');
        IncomingDocument.Insert(true);

        IncomingDocument.AddAttachmentFromStream(IncomingDocumentAttachment, 'test file', 'xml', InStream);

        // Validate
        Assert.AreEqual('', IncomingDocument."Data Exchange Type", '');

        // Exercise
        IncomingDocumentAttachment.Validate(Default, true);
        IncomingDocumentAttachment.Modify(true);

        // Validate
        IncomingDocument.Find();
        Assert.AreEqual('PEPPOLCREDITMEMO', IncomingDocument."Data Exchange Type", '');
    end;

    [Test]
    [HandlerFunctions('PostedSalesInvoicePageHandler,PostedSalesInvoicesPageHandler,PostedSalesCrMemoPageHandler,PostedSalesCrMemosPageHandler,PostedServiceInvoicePageHandler,PostedServiceInvoicesPageHandler,PostedServiceCrMemoPageHandler,PostedServiceCrMemosPageHandler')]
    [Scope('OnPrem')]
    procedure TestDocExchStatusFieldVisibility()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        // Setup
        ServiceCrMemoHeader.DeleteAll();
        ServiceInvoiceHeader.DeleteAll();
        SalesCrMemoHeader.DeleteAll();
        SalesInvoiceHeader.DeleteAll();

        CreateServiceCreditMemoAndPost(ServiceCrMemoHeader);
        CreateServiceInvoiceAndPost(ServiceInvoiceHeader);
        CreateSalesInvoiceAndPost(SalesInvoiceHeader);
        CreateSalesCreditMemoAndPost(SalesCrMemoHeader);

        // Exercise
        RunAllPagesThatHaveDocExchStatusField(false);

        // Add Diff doc Exch Status
        ServiceCrMemoHeader."Document Exchange Status" := ServiceCrMemoHeader."Document Exchange Status"::"Delivery Failed";
        ServiceCrMemoHeader.Modify();
        ServiceInvoiceHeader."Document Exchange Status" := ServiceInvoiceHeader."Document Exchange Status"::"Delivery Failed";
        ServiceInvoiceHeader.Modify();
        SalesCrMemoHeader."Document Exchange Status" := ServiceCrMemoHeader."Document Exchange Status"::"Delivery Failed";
        SalesCrMemoHeader.Modify();
        SalesInvoiceHeader."Document Exchange Status" := ServiceInvoiceHeader."Document Exchange Status"::"Delivery Failed";
        SalesInvoiceHeader.Modify();

        // Exercise
        RunAllPagesThatHaveDocExchStatusField(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        Response: Variant;
        Msg: Variant;
    begin
        LibraryVariableStorage.Dequeue(Msg);
        Assert.IsTrue(StrPos(Msg, Question) > 0, Question);
        LibraryVariableStorage.Dequeue(Response);
        Reply := Response;
    end;

    local procedure EnqueueConfirmMsgAndResponse(Msg: Text; Response: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Msg);
        LibraryVariableStorage.Enqueue(Response);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        Msg: Variant;
    begin
        LibraryVariableStorage.Dequeue(Msg);
        Assert.IsTrue(StrPos(Message, Msg) > 0, Message);
    end;

    local procedure CreateGenericSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        CreateGenericSalesHeader(SalesHeader, DocumentType);
        CreateGenericItem(Item);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreateGenericSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        Cust: Record Customer;
    begin
        CreateCustomer(Cust);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Cust."No.");
        SalesHeader.Validate("Your Reference",
          LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("Your Reference"), DATABASE::"Sales Header"));

        if DocumentType = SalesHeader."Document Type"::"Credit Memo" then
            SalesHeader.Validate("Shipment Date", WorkDate());

        SalesHeader.Modify(true);
    end;

    local procedure CreateGenericItem(var Item: Record Item)
    var
        UOM: Record "Unit of Measure";
        ItemUOM: Record "Item Unit of Measure";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInvt: Codeunit "Library - Inventory";
        QtyPerUnit: Integer;
    begin
        QtyPerUnit := LibraryRandom.RandInt(10);

        LibraryInvt.CreateUnitOfMeasureCode(UOM);
        UOM.Validate("International Standard Code",
          LibraryUtility.GenerateRandomCode(UOM.FieldNo("International Standard Code"), DATABASE::"Unit of Measure"));
        UOM.Modify(true);

        LibraryInvt.CreateItem(Item);
        Item."Unit Price" := LibraryRandom.RandInt(10);
        Item.Modify();

        LibraryInvt.CreateItemUnitOfMeasure(ItemUOM, Item."No.", UOM.Code, QtyPerUnit);

        Item.Validate("Sales Unit of Measure", UOM.Code);
        Item.Modify(true);
    end;

    local procedure CreateCustomer(var Cust: Record Customer)
    var
        CountryRegion: Record "Country/Region";
        CountryCode: Code[2];
    begin
        CountryCode := ConvertStr(LibraryUtility.GenerateRandomText(2), '', '');
        if not CountryRegion.Get(CountryCode) then begin
            CountryRegion.Validate(Code, CountryCode);
            CountryRegion."ISO Code" := CountryCode;
            CountryRegion.Insert(true);
        end;

        LibrarySales.CreateCustomer(Cust);
        Cust.Validate(Address, LibraryUtility.GenerateRandomCode(Cust.FieldNo(Address), DATABASE::Customer));
        Cust.Validate("Country/Region Code", CountryRegion.Code);
        Cust.Validate(City, LibraryUtility.GenerateRandomCode(Cust.FieldNo(City), DATABASE::Customer));
        Cust.Validate("Post Code", LibraryUtility.GenerateRandomCode(Cust.FieldNo("Post Code"), DATABASE::Customer));
        Cust."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code);
        Cust.Validate(GLN, '1234567890128');
        Cust.Modify(true);
    end;

    local procedure CreateServiceInvoiceAndPost(var ServiceInvoiceHeader: Record "Service Invoice Header")
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
    begin
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true); // Ship, Consume, Invoice

        ServiceInvoiceHeader.SetRange("Customer No.", Customer."No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceHeader.SetRecFilter();
    end;

    local procedure CreateSalesInvoiceAndPost(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibraryInvt.CreateItem(Item);
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreateServiceCreditMemoAndPost(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    var
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
    begin
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true); // Ship, Consume, Invoice

        ServiceCrMemoHeader.SetRange("Customer No.", Customer."No.");
        ServiceCrMemoHeader.FindFirst();
    end;

    local procedure CreateSalesCreditMemoAndPost(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Item: Record Item;
    begin
        LibraryInvt.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));

        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, false, false));
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; var Customer: Record Customer)
    var
        ServiceLine: Record "Service Line";
    begin
        CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInvt.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateElectrDocFormat(Type: Enum "Electronic Document Format Usage"; CodeunitID: Integer)
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.SetRange(Usage, Type);
        ElectronicDocumentFormat.SetRange(Code, 'PEPPOL');
        if not ElectronicDocumentFormat.FindFirst() then begin
            ElectronicDocumentFormat.Code := 'PEPPOL';
            ElectronicDocumentFormat.Usage := Type;
            ElectronicDocumentFormat.Validate("Codeunit ID", CodeunitID);
            ElectronicDocumentFormat.Insert();
        end;
    end;

    local procedure SetupDefaultDocExchServiceDocumentSendingProfile(var TempDocumentSendingProfile: Record "Document Sending Profile" temporary)
    begin
        TempDocumentSendingProfile.Init();
        TempDocumentSendingProfile."Electronic Document" :=
          TempDocumentSendingProfile."Electronic Document"::"Through Document Exchange Service";
        TempDocumentSendingProfile."Electronic Format" := 'PEPPOL';
    end;

    local procedure SetupDefaultDocExchServiceDocumentSendingProfilePostSalesCrMemo(var TempDocumentSendingProfile: Record "Document Sending Profile" temporary; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateGenericSalesDocument(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesCrMemoHeader.SetRecFilter();
    end;

    local procedure SetupDefaultDocExchServiceDocumentSendingProfilePostSalesInvoice(var TempDocumentSendingProfile: Record "Document Sending Profile" temporary; var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateGenericSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice);

        SetupDefaultDocExchServiceDocumentSendingProfile(TempDocumentSendingProfile);

        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.SetRecFilter();
    end;

    local procedure ConfigureVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetRange("Tax Category", '');
        VATPostingSetup.ModifyAll("Tax Category", 'AA');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ActivityLogModalPageHandler(var ActivityLog: TestPage "Activity Log")
    var
        ActivityLogRec: Record "Activity Log";
    begin
        ActivityLog.First();
        Assert.AreEqual(ActivityLog.Status.Value, Format(ActivityLogRec.Status::Success),
          'wrong status in the activity log page');
    end;

    local procedure ConfigureDocumentFormats()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        CreateElectrDocFormat(ElectronicDocumentFormat.Usage::"Sales Validation",
          CODEUNIT::"PEPPOL Validation");
        CreateElectrDocFormat(ElectronicDocumentFormat.Usage::"Service Validation",
          CODEUNIT::"PEPPOL Service Validation");
        CreateElectrDocFormat(ElectronicDocumentFormat.Usage::"Sales Invoice",
          CODEUNIT::"Exp. Sales Inv. PEPPOL BIS3.0");
        CreateElectrDocFormat(ElectronicDocumentFormat.Usage::"Sales Credit Memo",
          CODEUNIT::"Exp. Sales CrM. PEPPOL BIS3.0");
        CreateElectrDocFormat(ElectronicDocumentFormat.Usage::"Service Invoice",
          CODEUNIT::"Exp. Serv.Inv. PEPPOL BIS3.0");
        CreateElectrDocFormat(ElectronicDocumentFormat.Usage::"Service Credit Memo",
          CODEUNIT::"Exp. Serv.CrM. PEPPOL BIS3.0");
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemosPageHandler(var PostedServiceCreditMemos: TestPage "Posted Service Credit Memos")
    var
        IsVisible: Boolean;
    begin
        IsVisible := LibraryVariableStorage.DequeueBoolean();
        PostedServiceCreditMemos.First();
        Assert.AreEqual(IsVisible, PostedServiceCreditMemos."Document Exchange Status".Visible(),
          'The field has the wrong visibility setting');
        PostedServiceCreditMemos.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceCrMemoPageHandler(var PostedServiceCreditMemo: TestPage "Posted Service Credit Memo")
    var
        IsVisible: Boolean;
    begin
        IsVisible := LibraryVariableStorage.DequeueBoolean();
        PostedServiceCreditMemo.First();
        Assert.AreEqual(IsVisible, PostedServiceCreditMemo."Document Exchange Status".Visible(),
          'The field has the wrong visibility setting');
        PostedServiceCreditMemo.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoicesPageHandler(var PostedServiceInvoices: TestPage "Posted Service Invoices")
    var
        IsVisible: Boolean;
    begin
        IsVisible := LibraryVariableStorage.DequeueBoolean();
        PostedServiceInvoices.First();
        Assert.AreEqual(IsVisible, PostedServiceInvoices."Document Exchange Status".Visible(),
          'The field has the wrong visibility setting');
        PostedServiceInvoices.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoicePageHandler(var PostedServiceInvoice: TestPage "Posted Service Invoice")
    var
        IsVisible: Boolean;
    begin
        IsVisible := LibraryVariableStorage.DequeueBoolean();
        PostedServiceInvoice.First();
        Assert.AreEqual(IsVisible, PostedServiceInvoice."Document Exchange Status".Visible(),
          'The field has the wrong visibility setting');
        PostedServiceInvoice.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemosPageHandler(var PostedSalesCreditMemos: TestPage "Posted Sales Credit Memos")
    var
        IsVisible: Boolean;
    begin
        IsVisible := LibraryVariableStorage.DequeueBoolean();
        PostedSalesCreditMemos.First();
        Assert.AreEqual(IsVisible, PostedSalesCreditMemos."Document Exchange Status".Visible(),
          'The field has the wrong visibility setting');
        PostedSalesCreditMemos.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesCrMemoPageHandler(var PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo")
    var
        IsVisible: Boolean;
    begin
        IsVisible := LibraryVariableStorage.DequeueBoolean();
        PostedSalesCreditMemo.First();
        Assert.AreEqual(IsVisible, PostedSalesCreditMemo."Document Exchange Status".Visible(),
          'The field has the wrong visibility setting');
        PostedSalesCreditMemo.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicesPageHandler(var PostedSalesInvoices: TestPage "Posted Sales Invoices")
    var
        IsVisible: Boolean;
    begin
        IsVisible := LibraryVariableStorage.DequeueBoolean();
        PostedSalesInvoices.First();
        Assert.AreEqual(IsVisible, PostedSalesInvoices."Document Exchange Status".Visible(),
          'The field has the wrong visibility setting');
        PostedSalesInvoices.Close();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvoicePageHandler(var PostedSalesInvoice: TestPage "Posted Sales Invoice")
    var
        IsVisible: Boolean;
    begin
        IsVisible := LibraryVariableStorage.DequeueBoolean();
        PostedSalesInvoice.First();
        Assert.AreEqual(IsVisible, PostedSalesInvoice."Document Exchange Status".Visible(),
          'The field has the wrong visibility setting');
        PostedSalesInvoice.Close();
    end;

    local procedure RunAllPagesThatHaveDocExchStatusField(IsVisible: Boolean)
    begin
        LibraryVariableStorage.Enqueue(IsVisible);
        PAGE.Run(PAGE::"Posted Service Credit Memos");

        LibraryVariableStorage.Enqueue(IsVisible);
        PAGE.Run(PAGE::"Posted Service Credit Memo");

        LibraryVariableStorage.Enqueue(IsVisible);
        PAGE.Run(PAGE::"Posted Service Invoices");

        LibraryVariableStorage.Enqueue(IsVisible);
        PAGE.Run(PAGE::"Posted Service Invoice");

        LibraryVariableStorage.Enqueue(IsVisible);
        PAGE.Run(PAGE::"Posted Sales Credit Memos");

        LibraryVariableStorage.Enqueue(IsVisible);
        PAGE.Run(PAGE::"Posted Sales Credit Memo");

        LibraryVariableStorage.Enqueue(IsVisible);
        PAGE.Run(PAGE::"Posted Sales Invoices");

        LibraryVariableStorage.Enqueue(IsVisible);
        PAGE.Run(PAGE::"Posted Sales Invoice");
    end;
}
