codeunit 139001 "Inc Doc Attachment Overview UI"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Incoming Documents] [Attachment] [UI]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestFactBoxDrillDown()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentAttachment2: Record "Incoming Document Attachment";
        IncomingDocuments: TestPage "Incoming Documents";
        DocumentURL: Text;
    begin
        // Setup
        DocumentURL := LibraryUtility.GenerateRandomText(300);
        CreateIncomingDocument(IncomingDocument, DocumentURL);

        CreateIncomingDocument(IncomingDocument, '');
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment2);

        // Execute
        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(IncomingDocument);

        Assert.IsTrue(IncomingDocuments.IncomingDocAttachFactBox.First(), 'The record must be present');

        repeat
            IncomingDocuments.IncomingDocAttachFactBox.Name.DrillDown();
        until IncomingDocuments.IncomingDocAttachFactBox.Next();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestFactBoxExport()
    var
        IncomingDocument: Record "Incoming Document";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        IncomingDocumentAttachment2: Record "Incoming Document Attachment";
        IncomingDocuments: TestPage "Incoming Documents";
        DocumentURL: Text;
    begin
        // Setup
        DocumentURL := LibraryUtility.GenerateRandomText(300);
        CreateIncomingDocument(IncomingDocument, DocumentURL);

        CreateIncomingDocument(IncomingDocument, '');
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment);
        CreateIncomingDocumentAttachment(IncomingDocument, IncomingDocumentAttachment2);

        // Execute
        IncomingDocuments.OpenEdit();
        IncomingDocuments.GotoRecord(IncomingDocument);

        Assert.IsTrue(IncomingDocuments.IncomingDocAttachFactBox.First(), 'The record must be present');

        repeat
            IncomingDocuments.IncomingDocAttachFactBox.Export.Invoke();
        until IncomingDocuments.IncomingDocAttachFactBox.Next();
    end;

    local procedure CreateIncomingDocument(var IncomingDocument: Record "Incoming Document"; AttachmentURL: Text)
    begin
        Clear(IncomingDocument);
        IncomingDocument.Init();
        IncomingDocument.SetURL(AttachmentURL);
        IncomingDocument.Insert(true);
    end;

    local procedure CreateIncomingDocumentAttachment(var IncomingDocument: Record "Incoming Document"; var IncomingDocumentAttachment: Record "Incoming Document Attachment")
    var
        FileManagement: Codeunit "File Management";
        AnyXMLTxt: Text;
    begin
        AnyXMLTxt := '<test><test2 /></test>';
        IncomingDocument.AddXmlAttachmentFromXmlText(IncomingDocumentAttachment, FileManagement.CreateFileNameWithExtension(Format(CreateGuid()), 'XML'), AnyXMLTxt);
    end;
}

