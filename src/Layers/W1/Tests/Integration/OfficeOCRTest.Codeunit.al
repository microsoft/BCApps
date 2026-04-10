codeunit 139058 "Office OCR Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [OCR] [Outlook Add-in]
    end;

    var
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        LibraryOfficeHostProvider: Codeunit "Library - Office Host Provider";
        LibraryWorkflow: Codeunit "Library - Workflow";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        OfficeHostType: DotNet OfficeHostType;
        IsInitialized: Boolean;
        SendToOCRActionNotVisibleMsg: Label 'SendToOCR Action is not visible when OCR set up is Disabled';
        SendToOCRActionOfficeMobileVisibleMsg: Label 'SendToOCR Action is not visible when in Outlook Moblie App Add-in';
        SendToOCRActionVisibleMsg: Label 'SendToOCR Action is visible when OCR set up is Enabled';
        SendToOCRActionEnabledMsg: Label 'SendToOCR Action is enabled when attachments exist';
        SendToOCRActionDisabledMsg: Label 'SendToOCR Action is disabled when attachments do not exist';
        SendToOCRMsg: Label 'The attachment was not successfully send to OCR';
        SendAttachmentToIncomingDocumentMsg: Label 'The attachment was not successfully sent to Incoming Documents';
        SendDocumentToAttachmentsMsg: Label 'The document was not successfully attached to Attachments';
        SendIncomingDocApprovalRequestMsg: Label 'The Incoming Document Approval request for attachment was not successfully send';
        SendToOCRActionNotVisible_WorkflowExistsMsg: Label 'SendToOCR Action is not visible when there is an approval workflow for incoming documents';
        PurchaseInvoiceCreateFromFileVisibleMsg: Label 'Create from File is not visible when in Outlook Mobile App Add-in';
        PurchaseInvoiceCreateFromAttachmentVisibleMsg: Label 'Create from Attachment is not visible when in the Outlook Mobile App Add-in';

    [Test]
    [Scope('OnPrem')]
    procedure SendToOCRActionNotVisible_OCRNotEnabled()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        VendorCard: TestPage "Vendor Card";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [SCENARIO] The SendToOCRAction is not visible when OCR is not enabled.
        Initialize(OfficeHostType.OutlookItemRead);

        // [GIVEN] A Vendor in a system with OCR set up disabled.
        DisableOCRSetup();
        TestEmail := RandomEmail();
        CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);

        // [WHEN] The vendor card is opened up in Office Addin.
        OfficeAddinContext.SetRange(Email, TestEmail);
        VendorCard.Trap();
        RunMailEngine(OfficeAddinContext, OfficeHostType.OutlookItemRead);

        // [THEN] SendToOCR action in the addin is not visible.
        Assert.IsFalse(VendorCard.SendToOCR.Visible(), SendToOCRActionNotVisibleMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendToOCRActionVisible()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        VendorCard: TestPage "Vendor Card";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [SCENARIO] The SendToOCRAction is visible when OCR is enabled.
        Initialize(OfficeHostType.OutlookItemRead);

        // [GIVEN] A Vendor in a system with OCR set up enabled.
        TestEmail := RandomEmail();
        CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);

        // [WHEN] The vendor card is opened up in Office Addin.
        OfficeAddinContext.SetRange(Email, TestEmail);
        VendorCard.Trap();
        RunMailEngine(OfficeAddinContext, OfficeHostType.OutlookItemRead);

        // [THEN] SendToOCR action in the addin is visible.
        Assert.IsTrue(VendorCard.SendToOCR.Visible(), SendToOCRActionVisibleMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendToOCRActionEnabled()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Vendor: Record Vendor;
        ExchangeObject: Record "Exchange Object";
        VendorCard: TestPage "Vendor Card";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        VendorNo: Code[20];
        TestEmail: Text[80];
    begin
        // [SCENARIO] The SendToOCRAction is enabled when an outlook email has attachments
        Initialize(OfficeHostType.OutlookItemRead);

        // [GIVEN] A Vendor in a system with OCR set up enabled and an email with attachments exists
        TestEmail := RandomEmail();
        VendorNo := CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);
        Vendor.SetRange("No.", VendorNo);
        Vendor.Get(VendorNo);
        LibraryOfficeHostProvider.CreateEmailAttachments('application/pdf', 1,
          ExchangeObject.InitiatedAction::InitiateSendToOCR, GetRecRefFromVendorNo(VendorNo));

        // [WHEN] The vendor card is opened up in Office Addin.
        OfficeAddinContext.SetRange(Email, TestEmail);
        VendorCard.Trap();
        RunMailEngine(OfficeAddinContext, OfficeHostType.OutlookItemRead);

        // [THEN] SendToOCR action in the addin is enabled.
        Assert.IsTrue(VendorCard.SendToOCR.Enabled(), SendToOCRActionEnabledMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendToOCRActionDisabled_NoAttachments()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        VendorCard: TestPage "Vendor Card";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [SCENARIO] The SendToOCRAction is disabled when an outlook email has no attachments
        Initialize(OfficeHostType.OutlookItemRead);

        // [GIVEN] A Vendor in a system with OCR set up enabled and an email with no attachments exists
        TestEmail := RandomEmail();
        CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);

        // [WHEN] The vendor card is opened up in Office Addin.
        OfficeAddinContext.SetRange(Email, TestEmail);
        VendorCard.Trap();
        RunMailEngine(OfficeAddinContext, OfficeHostType.OutlookItemRead);

        // [THEN] SendToOCR action in the addin is disabled.
        Assert.IsFalse(VendorCard.SendToOCR.Enabled(), SendToOCRActionDisabledMsg);
    end;

    [Test]
    [HandlerFunctions('MsgHandler')]
    [Scope('OnPrem')]
    procedure SendToOCR()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Vendor: Record Vendor;
        ExchangeObject: Record "Exchange Object";
        IncomingDocument: Record "Incoming Document";
        VendorCard: TestPage "Vendor Card";
        OfficeOCRIncomingDocuments: TestPage "Office OCR Incoming Documents";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        VendorNo: Code[20];
        TestEmail: Text[80];
    begin
        // [SCENARIO] Stan is able to send an attachment in an outlook email to OCR
        Initialize(OfficeHostType.OutlookItemRead);

        // [GIVEN] A Vendor in a system with OCR set up enabled and an email with attachments exists
        TestEmail := RandomEmail();
        VendorNo := CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);
        Vendor.SetRange("No.", VendorNo);
        Vendor.Get(VendorNo);
        OfficeAddinContext.SetRange(Email, TestEmail);
        LibraryOfficeHostProvider.CreateEmailAttachments('application/pdf', 1,
          ExchangeObject.InitiatedAction::InitiateSendToOCR, GetRecRefFromVendorNo(VendorNo));
        // [WHEN] The vendor card is opened up in Office Addin.
        VendorCard.Trap();
        RunMailEngine(OfficeAddinContext, OfficeHostType.OutlookItemRead);

        // [THEN] SendToOCR action in the addin is enabled.
        // [WHEN] SendToOCR action is invoked.
        OfficeOCRIncomingDocuments.Trap();
        VendorCard.SendToOCR.Invoke();
        OfficeOCRIncomingDocuments.OK().Invoke();
        IncomingDocument.SetRange("Vendor Name", VendorNo);

        // [THEN] The attachment is sent to OCR and an incoming document created
        Assert.IsTrue(IncomingDocument.FindFirst(), SendToOCRMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MsgHandler')]
    procedure SendAttachmentToIncomingDocument()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Vendor: Record Vendor;
        ExchangeObject: Record "Exchange Object";
        IncomingDocument: Record "Incoming Document";
        VendorCard: TestPage "Vendor Card";
        OfficeOCRIncomingDocuments: TestPage "Office OCR Incoming Documents";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        VendorNo: Code[20];
        TestEmail: Text[80];
        InitialIncomingDocCount: Integer;
    begin
        // [SCENARIO] Stan is able to send an attachment in an outlook email to Incoming Document
        Initialize(OfficeHostType.OutlookItemRead);

        // [GIVEN] A Vendor in a system with or without OCR set up enabled and an email with attachments exists
        TestEmail := RandomEmail();
        VendorNo := CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);
        Vendor.SetRange("No.", VendorNo);
        Vendor.Get(VendorNo);
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [WHEN] The vendor card is opened up in Office Addin.
        VendorCard.Trap();
        LibraryOfficeHostProvider.CreateEmailAttachments('application/pdf', 1,
          ExchangeObject.InitiatedAction::InitiateSendToIncomingDocuments, GetRecRefFromVendorNo(VendorNo));
        RunMailEngine(OfficeAddinContext, OfficeHostType.OutlookItemRead);

        // [THEN] SendToIncomingDocuments action in the addin is enabled.
        // [WHEN] SendToIncomingDocuments action is invoked.
        IncomingDocument.SetFilter("Vendor No.", VendorNo);
        InitialIncomingDocCount := IncomingDocument.Count();
        OfficeOCRIncomingDocuments.Trap();
        VendorCard.SendToIncomingDocuments.Invoke();
        OfficeOCRIncomingDocuments.OK().Invoke();

        // [THEN] The attachment is sent to incoming documents
        Assert.AreEqual(InitialIncomingDocCount + 1, IncomingDocument.Count, SendAttachmentToIncomingDocumentMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendIncomingDocApprovalRequest()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Vendor: Record Vendor;
        ExchangeObject: Record "Exchange Object";
        IncomingDocument: Record "Incoming Document";
        VendorCard: TestPage "Vendor Card";
        OfficeOCRIncomingDocuments: TestPage "Office OCR Incoming Documents";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        VendorNo: Code[20];
        TestEmail: Text[80];
    begin
        // [SCENARIO] Stan is able to send an approval request for attachment in an outlook email when there is an approval request workflow
        Initialize(OfficeHostType.OutlookItemRead);

        // [GIVEN] A Vendor in a system with or without OCR set up enabled and an email with attachments exists
        TestEmail := RandomEmail();
        VendorNo := CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);
        Vendor.SetRange("No.", VendorNo);
        Vendor.Get(VendorNo);
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [WHEN] The vendor card is opened up in Office Addin and there is an approval request workflow.
        VendorCard.Trap();
        OfficeOCRIncomingDocuments.Trap();
        CreateIncomingDocumentWorkflow();
        LibraryOfficeHostProvider.CreateEmailAttachments('application/pdf', 1,
          ExchangeObject.InitiatedAction::InitiateSendToWorkFlow, GetRecRefFromVendorNo(VendorNo));
        RunMailEngine(OfficeAddinContext, OfficeHostType.OutlookItemRead);

        // [THEN] SendIncomingDocApprovalRequest action in the addin is enabled.
        // [WHEN] SendIncomingDocApprovalRequest action is invoked.
        OfficeOCRIncomingDocuments.Trap();
        VendorCard.SendIncomingDocApprovalRequest.Invoke();
        OfficeOCRIncomingDocuments.OK().Invoke();
        IncomingDocument.SetRange("Vendor Name", VendorNo);

        // [THEN] The attachment is sent to incoming documents
        Assert.IsTrue(IncomingDocument.FindFirst(), SendIncomingDocApprovalRequestMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendToOCRActionNotVisible_WorkflowExists()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Vendor: Record Vendor;
        ExchangeObject: Record "Exchange Object";
        VendorCard: TestPage "Vendor Card";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        VendorNo: Code[20];
        TestEmail: Text[80];
    begin
        // [SCENARIO] SendToOCR action is not visible when there is a incoming document approval request workflow.
        Initialize(OfficeHostType.OutlookItemRead);

        // [GIVEN] A Vendor in a system with or without OCR set up enabled and an email with attachments exists
        TestEmail := RandomEmail();
        VendorNo := CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);
        Vendor.SetRange("No.", VendorNo);
        Vendor.Get(VendorNo);
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [WHEN] The vendor card is opened up in Office Addin and there is an approval request workflow.
        VendorCard.Trap();
        CreateIncomingDocumentWorkflow();
        LibraryOfficeHostProvider.CreateEmailAttachments('application/pdf', 1,
          ExchangeObject.InitiatedAction::InitiateSendToOCR, GetRecRefFromVendorNo(VendorNo));
        RunMailEngine(OfficeAddinContext, OfficeHostType.OutlookItemRead);

        // [THEN] SendToOCR action in the addin is not visible.
        Assert.IsFalse(VendorCard.SendToOCR.Visible(), SendToOCRActionNotVisible_WorkflowExistsMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateFromFileAndAttachmentNotVisibleOnPurchaseInvoiceInOutlookMobileApp()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        ExchangeObject: Record "Exchange Object";
        VendorCard: TestPage "Vendor Card";
        PurchaseInvoice: TestPage "Purchase Invoice";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        VendorNo: Code[20];
        TestEmail: Text[80];
    begin
        // [SCENARIO] Stan is unable to send an attachment in the Outlook Mobilie app add-in
        Initialize(OfficeHostType.OutlookMobileApp);

        // [GIVEN] A Vendor in a system with or without OCR set up enabled and an email with attachments exists
        TestEmail := RandomEmail();
        VendorNo := CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [WHEN] The vendor card is opened up in Office Addin.
        VendorCard.Trap();
        LibraryOfficeHostProvider.CreateEmailAttachments('application/pdf', 1,
          ExchangeObject.InitiatedAction::InitiateSendToIncomingDocuments, GetRecRefFromVendorNo(VendorNo));
        RunMailEngine(OfficeAddinContext, OfficeHostType.OutlookMobileApp);

        // [WHEN] A New Purchase Invoice is created from the vendor card
        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();

        // [THEN] A Purchase invoice card is opened with "Create from Attachment" action not visible, "Create from File" action is not visible
        Assert.IsFalse(PurchaseInvoice.IncomingDocEmailAttachment.Visible(), PurchaseInvoiceCreateFromAttachmentVisibleMsg);
        Assert.IsFalse(PurchaseInvoice.IncomingDocAttachFile.Visible(), PurchaseInvoiceCreateFromFileVisibleMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendToOCRActionNotVisibleInOutlookMobileApp()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        VendorCard: TestPage "Vendor Card";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        TestEmail: Text[80];
    begin
        // [SCENARIO] The SendToOCRAction is not visible when in Outlook Mobile app add-in.
        Initialize(OfficeHostType.OutlookMobileApp);

        // [GIVEN] A Vendor in a system with OCR set up enabled.
        TestEmail := RandomEmail();
        CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);

        // [WHEN] The vendor card is opened up in Office Addin.
        OfficeAddinContext.SetRange(Email, TestEmail);
        VendorCard.Trap();
        RunMailEngine(OfficeAddinContext, OfficeHostType.OutlookMobileApp);

        // [THEN] SendToOCR action in the addin is not visible.
        Assert.IsFalse(VendorCard.SendToOCR.Visible(), SendToOCRActionOfficeMobileVisibleMsg);
    end;

    [Test]
    [HandlerFunctions('DocumentAttachmentDetailsPageHandler,InstructionsMenuHandler')]
    [Scope('OnPrem')]
    procedure SendDocumentsToAttachmentFromAttachmentDetailPage()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Vendor: Record Vendor;
        ExchangeObject: Record "Exchange Object";
        DocumentAttachment: Record "Document Attachment";
        VendorCard: TestPage "Vendor Card";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        VendorNo: Code[20];
        TestEmail: Text[80];
        InitialDocumentCount: Integer;
    begin
        // [SCENARIO] Stan is able to attach a document in an outlook email to Attachments 
        Initialize(OfficeHostType.OutlookItemRead);

        // [GIVEN] A Vendor in a system exists
        TestEmail := RandomEmail();
        VendorNo := CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);
        Vendor.SetRange("No.", VendorNo);
        Vendor.Get(VendorNo);
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [WHEN] The vendor card is opened up in Office Addin.
        VendorCard.Trap();
        LibraryOfficeHostProvider.CreateEmailAttachments('application/pdf', 1,
          ExchangeObject.InitiatedAction::InitiateSendToIncomingDocuments, GetRecRefFromVendorNo(VendorNo));
        RunMailEngine(OfficeAddinContext, OfficeHostType.OutlookItemRead);

        DocumentAttachment.SetRange("Table ID", Database::Vendor);
        DocumentAttachment.SetRange("No.", VendorNo);
        InitialDocumentCount := DocumentAttachment.Count();
        // [WHEN] OpenInDetail Action in Factbox is clicked and several handlers are invoked
        VendorCard."Attached Documents List".OpenInDetail.Invoke();

        // [THEN] The attachment is sent to Attachments
        Assert.AreEqual(InitialDocumentCount + 1, DocumentAttachment.Count, SendDocumentToAttachmentsMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendDocumentsToAttachmentFromDocAttachmentListFactbox()
    var
        OfficeAddinContext: Record "Office Add-in Context";
        Vendor: Record Vendor;
        ExchangeObject: Record "Exchange Object";
        DocumentAttachment: Record "Document Attachment";
        VendorCard: TestPage "Vendor Card";
        ContactNo: Code[20];
        NewBusRelCode: Code[10];
        VendorNo: Code[20];
        TestEmail: Text[80];
        InitialDocumentCount: Integer;
    begin
        // [SCENARIO] Stan is able to attach a document in an outlook email to Attachments from DocAttachmetnList Factbox
        Initialize(OfficeHostType.OutlookItemRead);

        // [GIVEN] A Vendor in a system exists
        TestEmail := RandomEmail();
        VendorNo := CreateContactFromVendor(TestEmail, ContactNo, NewBusRelCode, true);
        Vendor.SetRange("No.", VendorNo);
        Vendor.Get(VendorNo);
        OfficeAddinContext.SetRange(Email, TestEmail);

        // [WHEN] The vendor card is opened up in Office Addin.
        VendorCard.Trap();
        LibraryOfficeHostProvider.CreateEmailAttachments('application/pdf', 1,
          ExchangeObject.InitiatedAction::InitiateSendToIncomingDocuments, GetRecRefFromVendorNo(VendorNo));
        RunMailEngine(OfficeAddinContext, OfficeHostType.OutlookItemRead);

        DocumentAttachment.SetRange("Table ID", Database::Vendor);
        DocumentAttachment.SetRange("No.", VendorNo);
        InitialDocumentCount := DocumentAttachment.Count();
        // [WHEN] OpenInDetail Action in Factbox is clicked and several handlers are invoked
        VendorCard."Attached Documents List".AttachFromEmail.Invoke();

        // [THEN] The attachment is sent to Attachments
        Assert.AreEqual(InitialDocumentCount + 1, DocumentAttachment.Count, SendDocumentToAttachmentsMsg);
    end;

    local procedure Initialize(HostType: Text)
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
        CryptographyManagement: Codeunit "Cryptography Management";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Office OCR Test");

        LibraryApplicationArea.EnableFoundationSetup();
        if CryptographyManagement.IsEncryptionEnabled() then
            DeleteEncryptionKey();
        ResetOCRSetup();
        InitializeWithHostType(HostType);
    end;

    local procedure InitializeWithHostType(HostType: Text)
    var
        OfficeAddin: Record "Office Add-in";
        Workflow: Record Workflow;
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
    begin
        Clear(LibraryOfficeHostProvider);

        Workflow.SetRange(Template, false);
        Workflow.ModifyAll(Enabled, false, true);

        BindSubscription(LibraryOfficeHostProvider);
        InitializeOfficeHostProvider(HostType);

        // Lazy Step
        if IsInitialized then
            exit;

        AddinManifestManagement.CreateDefaultAddins(OfficeAddin);
        IsInitialized := true;
        Commit();
    end;

    local procedure InitializeOfficeHostProvider(HostType: Text)
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeManagement: Codeunit "Office Management";
        OfficeHost: DotNet OfficeHost;
    begin
        OfficeAddinContext.DeleteAll();
        SetOfficeHostUnAvailable();

        SetOfficeHostProvider(CODEUNIT::"Library - Office Host Provider");

        OfficeManagement.InitializeHost(OfficeHost, HostType);
    end;

    local procedure SetOfficeHostUnAvailable()
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        // Test Providers checks whether we have registered Host in NameValueBuffer or not
        if NameValueBuffer.Get(SessionId()) then begin
            NameValueBuffer.Delete();
            Commit();
        end;
    end;

    local procedure SetOfficeHostProvider(ProviderId: Integer)
    var
        OfficeAddinSetup: Record "Office Add-in Setup";
    begin
        OfficeAddinSetup.Get();
        OfficeAddinSetup."Office Host Codeunit ID" := ProviderId;
        OfficeAddinSetup.Modify();
    end;

    local procedure RandomEmail(): Text[80]
    begin
        exit(StrSubstNo('%1@%2', CreateGuid(), 'contoso.com'));
    end;

    [Scope('OnPrem')]
    procedure CreateContactFromVendor(Email: Text[80]; var ContactNo: Code[20]; var NewBusinessRelationCode: Code[10]; SetPerson: Boolean): Code[20]
    var
        Vendor: Record Vendor;
        BusinessRelation: Record "Business Relation";
        ContactBusinessRelation: Record "Contact Business Relation";
        CreateContsFromVendors: Report "Create Conts. from Vendors";
    begin
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);
        NewBusinessRelationCode := BusinessRelation.Code;
        LibraryPurchase.CreateVendor(Vendor);

        // Create Contact from Vendor by running the report Create Conts. from Vendors.
        CreateContsFromVendors.UseRequestPage(false);
        CreateContsFromVendors.SetTableView(Vendor);
        CreateContsFromVendors.Run();

        ContactNo := UpdateContactEmail(BusinessRelation.Code, ContactBusinessRelation."Link to Table"::Vendor, Vendor."No.", Email,
            SetPerson);
        exit(Vendor."No.");
    end;

    local procedure ChangeBusinessRelationCodeForVendors(BusRelCodeForVendors: Code[10])
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Bus. Rel. Code for Vendors", BusRelCodeForVendors);
        MarketingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure UpdateContactEmail(BusinessRelationCode: Code[10]; LinkToTable: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20]; Email: Text[80]; SetPerson: Boolean) ContactNo: Code[20]
    var
        Contact: Record Contact;
    begin
        ContactNo := FindContactNo(BusinessRelationCode, LinkToTable, LinkNo);
        Contact.Get(ContactNo);
        Contact."E-Mail" := Email;
        Contact."Search E-Mail" := UpperCase(Email);

        // Need to set the type to person, default of company will cause issues...
        if SetPerson = true then
            Contact.Type := Contact.Type::Person;

        Contact.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure FindContactNo(BusinessRelationCode: Code[10]; LinkToTable: Enum "Contact Business Relation Link To Table"; LinkNo: Code[20]): Code[20]
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        ContactBusinessRelation.SetRange("Business Relation Code", BusinessRelationCode);
        ContactBusinessRelation.SetRange("Link to Table", LinkToTable);
        ContactBusinessRelation.SetRange("No.", LinkNo);
        ContactBusinessRelation.FindFirst();
        exit(ContactBusinessRelation."Contact No.");
    end;

    local procedure RunMailEngine(var OfficeAddinContext: Record "Office Add-in Context"; OfficeHostType: Text)
    var
        OfficeAddin: Record "Office Add-in";
        AddinManifestManagement: Codeunit "Add-in Manifest Management";
        OutlookMailEngine: TestPage "Outlook Mail Engine";
    begin
        AddinManifestManagement.GetAddinByHostType(OfficeAddin, OfficeHostType);
        OfficeAddinContext.SetRange(Version, OfficeAddin.Version);

        OutlookMailEngine.Trap();
        PAGE.Run(PAGE::"Outlook Mail Engine", OfficeAddinContext);
    end;

    local procedure ResetOCRSetup()
    var
        OCRServiceSetup: Record "OCR Service Setup";
        DummySecretValue: Text;
    begin
        OCRServiceSetup.DeleteAll();
        OCRServiceSetup.Init();
        OCRServiceSetup.Insert(true);

        OCRServiceSetup."User Name" := 'cronus.admin';
        DummySecretValue := '#Ey^VDI$B$53.8';
        OCRServiceSetup.SavePassword(OCRServiceSetup."Password Key", DummySecretValue);

        DummySecretValue := '2e9dfdaf60ee4569a2444a1fc3d16685';
        OCRServiceSetup.SavePassword(OCRServiceSetup."Authorization Key", DummySecretValue);
        OCRServiceSetup.Enabled := true;

        OCRServiceSetup."Service URL" := 'https://localhost:8080/OCR';
        OCRServiceSetup."Default OCR Doc. Template" := 'BLANK';
        OCRServiceSetup.Modify();

        Commit();
    end;

    local procedure DisableOCRSetup()
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        OCRServiceSetup.Init();
        OCRServiceSetup.Enabled := false;
        OCRServiceSetup.Modify();

        Commit();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MsgHandler(Text: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DocumentAttachmentDetailsPageHandler(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        DocumentAttachmentDetails.Name.Drilldown();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure InstructionsMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OfficeAttachmentsPageHandler(var OfficeAttachments: TestPage "Office Attachments")
    begin
        OfficeAttachments.OK().Invoke();
    end;

    local procedure CreateIncomingDocumentWorkflow()
    var
        Workflow: Record Workflow;
        GenJournalBatch: Record "Gen. Journal Batch";
        WorkflowEventHandling: Codeunit "Workflow Event Handling";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
        SecondEvent: Integer;
        SecondResponse: Integer;
        ThirdResponse: Integer;
        ThirdEvent: Integer;
        FourthResponse: Integer;
    begin
        Workflow.SetRange(Template, false);
        Workflow.ModifyAll(Enabled, false, true);

        LibraryWorkflow.CreateWorkflow(Workflow);

        SecondEvent :=
          LibraryWorkflow.InsertEntryPointEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendIncomingDocForApprovalCode());
        SecondResponse :=
          LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.ApproveAllApprovalRequestsCode(), SecondEvent);
        ThirdResponse := LibraryWorkflow.InsertResponseStep(Workflow, WorkflowResponseHandling.DoNothingCode(), SecondResponse);

        ThirdEvent :=
          LibraryWorkflow.InsertEventStep(Workflow, WorkflowEventHandling.RunWorkflowOnSendIncomingDocForApprovalCode(), ThirdResponse);
        FourthResponse := LibraryWorkflow.InsertResponseStep(Workflow,
            WorkflowResponseHandling.CreateApprovalRequestsCode(), ThirdEvent);

        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryWorkflow.InsertPmtLineCreationArgument(FourthResponse, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);

        Workflow.Validate(Enabled, true);
        Workflow.Modify(true);
    end;

    local procedure GetRecRefFromVendorNo(VendorNumber: Code[20]): RecordRef
    var
        Vendor: Record Vendor;
        RecRef: RecordRef;
    begin
        Vendor.Validate("No.", VendorNumber);
        Vendor.Get(VendorNumber);
        RecRef.Get(Vendor.RecordId());
        exit(RecRef);
    end;
}

