codeunit 134189 "WF Demo Ready for OCR Inc.Doc."
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Workflow] [Incoming Document] [OCR]
    end;

    var
        Workflow: Record Workflow;
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryWorkflow: Codeunit "Library - Workflow";
        FileTypes: Text;

    [Test]
    [Scope('OnPrem')]
    procedure AttachFileToIncomingDocWithEnabledWorkflowAndEnabledOCR()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        FileType: Option;
        IsOCRSupportedFileType: Boolean;
    begin
        // WHEN the OCR service is enabled and OCR workflow is enabled
        // WHEN a file (that can be ocr'ed ) is attached to incoming document with status = new
        // THEN a workflow should mark the incoming document with status = Ready for OCR
        // OTHERWISE the incoming document should still have status = new

        // Setup
        Initialize();

        EnableDisableOCRSetup(true);

        FileTypes := 'jpg,jpeg,bmp,png,tiff,tif,gif,pdf,docx,doc,xlsx,xls,pptx,ppt,msg,xml,other';

        CreateEnabledWorkflow(Workflow);

        for FileType := 0 to 16 do begin
            CreateIncomingDoc(IncomingDocument);
            Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');

            // Exercise
            CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, SelectStr(FileType + 1, FileTypes));

            // Verify
            IncomingDocument.Find();
            IsOCRSupportedFileType :=
              IncomingDocumentAttachment.Type in
              [IncomingDocumentAttachment.Type::PDF,
               IncomingDocumentAttachment.Type::Image];

            if IsOCRSupportedFileType then
                Assert.AreEqual(IncomingDocument."OCR Status"::" ", IncomingDocument."OCR Status", '')
            else
                Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');
        end;

        // Tear down
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AttachPDFToIncomingDocWithDisabledWorkflowAndEnabledOCR()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        // WHEN the OCR service is enabled and OCR workflow is disabled
        // WHEN a file (that can be ocr'ed ) is attached to incoming document with status = new
        // THEN incoming document should have status = new

        // Setup
        Initialize();

        EnableDisableOCRSetup(false);

        CreateEnabledWorkflow(Workflow);
        CreateIncomingDoc(IncomingDocument);
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');

        // Exercise
        Workflow.Validate(Enabled, false);
        Workflow.Modify(true);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AttachPDFToIncomingDocWithEnabledWorkflowAndDisabledOCR()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
    begin
        // WHEN the OCR service is disabled and an OCR workflow is enabled
        // WHEN a pdf file is attached to incoming document with status = new
        // THEN the incoming document with should have status = new

        // Setup
        Initialize();

        CreateEnabledWorkflow(Workflow);

        CreateIncomingDoc(IncomingDocument);
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '');

        // Exercise
        EnableDisableOCRSetup(false);
        Workflow.Validate(Enabled, false);
        CreateIncomingDocAttachment(IncomingDocument, IncomingDocumentAttachment, 'pdf');

        // Verify
        IncomingDocument.Find();
        Assert.AreEqual(IncomingDocument.Status::New, IncomingDocument.Status, '')
    end;

    [Scope('OnPrem')]
    procedure EnableDisableOCRSetup(Enable: Boolean)
    var
        OCRServiceSetup: Record "OCR Service Setup";
    begin
        OCRServiceSetup.Init();
        OCRServiceSetup.SetURLsToDefault();
        OCRServiceSetup."Default OCR Doc. Template" := 'TEST';
        OCRServiceSetup.Enabled := Enable;
        if not OCRServiceSetup.Modify() then
            OCRServiceSetup.Insert();
    end;

    local procedure Initialize()
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.DeleteAll();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryWorkflow.DisableAllWorkflows();
    end;

    local procedure CreateIncomingDoc(var IncomingDocument: Record "Incoming Document")
    begin
        Clear(IncomingDocument);
        IncomingDocument.Init();
        IncomingDocument.Validate(Status, IncomingDocument.Status::New);
        IncomingDocument.Insert(true);
    end;

    local procedure CreateIncomingDocAttachment(IncomingDocument: Record "Incoming Document"; var IncomingDocumentAttachment: Record "Incoming Document Attachment"; AttachmentType: Text[10])
    var
        FileMgt: Codeunit "File Management";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        SystemIOFile: DotNet File;
        FileName: Text;
    begin
        IncomingDocumentAttachment.SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");

        FileName := FileMgt.ServerTempFileName(AttachmentType);

        SystemIOFile.WriteAllText(FileName, AttachmentType);
        ImportAttachmentIncDoc.ImportAttachment(IncomingDocumentAttachment, FileName);
    end;

    local procedure CreateEnabledWorkflow(var Workflow: Record Workflow)
    var
        WorkflowStep: Record "Workflow Step";
        WorkflowStepArgument: Record "Workflow Step Argument";
        WorkflowSetup: Codeunit "Workflow Setup";
        WorkflowResponseHandling: Codeunit "Workflow Response Handling";
    begin
        LibraryWorkflow.CopyWorkflow(
          Workflow, WorkflowSetup.GetWorkflowTemplateCode(WorkflowSetup.IncomingDocumentOCRWorkflowCode()));
        WorkflowStep.SetRange("Function Name", WorkflowResponseHandling.CreateNotificationEntryCode());
        if WorkflowStep.FindFirst() then
            if WorkflowStepArgument.Get(WorkflowStep.Argument) then begin
                WorkflowStepArgument."Notification User ID" := UserId;
                WorkflowStepArgument.Modify(true);
            end;
    end;
}

