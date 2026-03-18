codeunit 136450 "Attachment Storage Type"
{
    // // This test codeunit assumes that attachments exist in demo data and they are embeded

    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Attachment] [UT]
    end;

    var
        MarketingSetup: Record "Marketing Setup";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryRandom: Codeunit "Library - Random";
        FileManagement: Codeunit "File Management";
        AttachmentManagement: Codeunit AttachmentManagement;
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        IsInitialized: Boolean;
        FileExtensionTxt: Label 'TXT', Locked = true;
        HtmlFileExtensionTxt: Label 'HTML';
        AttachmentErr: Label 'Wrong attachment''s details';
        HTMLContentErr: Label 'Wrong attachment''s html content';
        SendAttachmentErr: Label 'The interaction template has no attachment for the selected language code.';

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RelocateAttachmentsEmbededToDisk()
    var
        NewDirName: Text;
    begin
        // Setup:
        Initialize();

        // Exercise: Relocate Attachments to disk
        RelocateAttachments(MarketingSetup."Attachment Storage Type"::"Disk File",
          CreateOrClearTempDirectory(NewDirName));

        // Verify: Check that location has been changed for attachments.
        VerifyAttachmentsOnDisk(NewDirName);

        Rollback(NewDirName);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RelocateAttachmentsDiskToDisk()
    var
        NewDirName: Text;
        NewDirName2: Text;
    begin
        // Setup:
        Initialize();

        // Create new directory on server
        RelocateAttachments(MarketingSetup."Attachment Storage Type"::"Disk File",
          CreateOrClearTempDirectory(NewDirName));

        // Exercise
        RelocateAttachments(MarketingSetup."Attachment Storage Type"::"Disk File",
          CreateOrClearTempDirectory(NewDirName2));

        // Verify
        VerifyAttachmentsOnDisk(NewDirName2);

        Rollback(NewDirName2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RemoveAttachmentFromDisk()
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        Attachment: Record Attachment;
        NewDirName: Text;
        AttachmentFileName: Text;
    begin
        // Setup:
        Initialize();

        // Create new directory on server
        RelocateAttachments(MarketingSetup."Attachment Storage Type"::"Disk File",
          CreateOrClearTempDirectory(NewDirName));

        // Exercise: Remove attachment from interaction template
        InteractionTmplLanguage.SetFilter("Attachment No.", '<>0');
        InteractionTmplLanguage.FindFirst();
        InteractionTemplate.Get(InteractionTmplLanguage."Interaction Template Code");
        Attachment.Get(InteractionTmplLanguage."Attachment No.");
        AttachmentFileName := Attachment.ConstDiskFileName();
        InteractionTmplLanguage.RemoveAttachment(false); // don't prompt

        // Verify attachment removed
        InteractionTemplate.CalcFields("Attachment No.");
        Assert.IsTrue(InteractionTemplate."Attachment No." = 0, 'Attachment not removed from interaction template.');
        Assert.IsFalse(Exists(AttachmentFileName), 'Attachment file not removed from disk.');

        // Rollback
        Rollback(NewDirName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemoveEmbededAttachment()
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        Attachment: Record Attachment;
    begin
        // Setup:
        Initialize();

        // Exercise: Remove attachment from interaction template
        InteractionTmplLanguage.SetFilter("Attachment No.", '<>0');
        InteractionTmplLanguage.FindFirst();
        InteractionTemplate.Get(InteractionTmplLanguage."Interaction Template Code");
        Attachment.Get(InteractionTmplLanguage."Attachment No.");
        InteractionTmplLanguage.RemoveAttachment(false); // don't prompt

        // Verify attachment removed
        InteractionTemplate.CalcFields("Attachment No.");
        Assert.IsTrue(InteractionTemplate."Attachment No." = 0, 'Attachment not removed from interaction template.');
        Assert.IsFalse(Attachment.Get(Attachment."No."), 'Attachment not removed from DB.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WizSaveEmbededAttachment()
    var
        Attachment: Record Attachment;
        FromAttachment: Record Attachment;
    begin
        // Setup:
        Initialize();

        // Exercise: Copy
        FindNonEmptyAttachment(FromAttachment);
        Attachment.WizEmbeddAttachment(FromAttachment);

        // Verify attachment
        Assert.IsTrue(Attachment."Attachment File".HasValue(), 'Attachment file not imported to DB.');
        Assert.IsTrue(Attachment."Storage Type" = Attachment."Storage Type"::Embedded, 'Wrong storage type');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure WizSaveDiskAttachment()
    var
        Attachment: Record Attachment;
        FromAttachment: Record Attachment;
        NewDirName: Text;
    begin
        // Setup:
        Initialize();

        FindNonEmptyAttachment(FromAttachment);
        RelocateAttachments(MarketingSetup."Attachment Storage Type"::"Disk File",
          CreateOrClearTempDirectory(NewDirName));

        // Exercise: Copy
        FromAttachment.Get(FromAttachment."No.");
        Attachment.WizEmbeddAttachment(FromAttachment);

        // Verify attachment - is saved as temporary - in DB
        Assert.IsTrue(Attachment."Attachment File".HasValue, 'Attachment file not imported to DB.');
        Assert.IsTrue(Attachment."Storage Type" = Attachment."Storage Type"::Embedded, 'Wrong storage type');

        // Rollback
        Rollback(NewDirName);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportAttachmentFromServerToDisk()
    var
        Attachment: Record Attachment;
        NewDirName: Text;
        ImportFromFile: Text;
    begin
        // Setup:
        Initialize();

        RelocateAttachments(MarketingSetup."Attachment Storage Type"::"Disk File",
          CreateOrClearTempDirectory(NewDirName));

        // Exercise: Create & Import attachment
        ImportFromFile := CreateServerTxtFile(FileExtensionTxt);

        LibraryMarketing.CreateAttachment(Attachment);
        Attachment.ImportAttachmentFromServerFile(ImportFromFile, false, false);

        // Verify attachment
        Assert.IsTrue(Exists(Attachment.ConstDiskFileName()), 'Attachment file not imported to disk.');
        Assert.IsTrue(Attachment."Storage Type" = Attachment."Storage Type"::"Disk File", 'Wrong storage type');

        // Rollback
        Rollback(NewDirName);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportAttachmentFromServerTemporary()
    var
        Attachment: Record Attachment;
        NewDirName: Text;
        ImportFromFile: Text;
    begin
        // Setup:
        Initialize();

        RelocateAttachments(MarketingSetup."Attachment Storage Type"::"Disk File",
          CreateOrClearTempDirectory(NewDirName));

        // Exercise: Create & Import attachment
        ImportFromFile := CreateServerTxtFile(FileExtensionTxt);

        LibraryMarketing.CreateAttachment(Attachment);
        Attachment.ImportAttachmentFromServerFile(ImportFromFile, true, false);
        Attachment.Modify(true);

        // Verify attachment
        Attachment.CalcFields("Attachment File");
        Assert.IsTrue(Attachment."Attachment File".HasValue(), 'Attachment file not imported to DB.');
        Assert.IsTrue(Attachment."Storage Type" = Attachment."Storage Type"::Embedded, 'Wrong storage type');

        Rollback(NewDirName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ImportAttachmentFromServerToDB()
    var
        Attachment: Record Attachment;
        ImportFromFile: Text;
    begin
        // Setup:
        Initialize();

        // Exercise: Create & Import attachment
        ImportFromFile := CreateServerTxtFile(FileExtensionTxt);

        LibraryMarketing.CreateAttachment(Attachment);
        Attachment.ImportAttachmentFromServerFile(ImportFromFile, false, false);

        // Verify attachment
        Attachment.CalcFields("Attachment File");
        Assert.IsTrue(Attachment."Attachment File".HasValue(), 'Attachment file not imported to DB.');
        Assert.IsTrue(Attachment."Storage Type" = Attachment."Storage Type"::Embedded, 'Wrong storage type');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ExportAttachmentFromDiskToServerFile()
    var
        Attachment: Record Attachment;
        NewDirName: Text;
        ExportToFile: Text;
    begin
        // Setup:
        Initialize();

        FindNonEmptyAttachment(Attachment);
        RelocateAttachments(MarketingSetup."Attachment Storage Type"::"Disk File",
          CreateOrClearTempDirectory(NewDirName));

        // Exercise: Export attachment
        ExportToFile := FileManagement.ServerTempFileName(FileExtensionTxt);

        Attachment.Get(Attachment."No.");
        Attachment.ExportAttachmentToServerFile(ExportToFile);

        // Verify attachment
        LibraryUtilityOnPrem.CheckFileNotEmpty(ExportToFile);

        // Rollback
        Rollback(NewDirName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportAttachmentFromDBToServerFiler()
    var
        Attachment: Record Attachment;
        ExportToFile: Text;
    begin
        // Setup:
        Initialize();

        // Exercise: Export attachment
        ExportToFile := FileManagement.ServerTempFileName(FileExtensionTxt);

        FindNonEmptyAttachment(Attachment);
        Attachment.ExportAttachmentToServerFile(ExportToFile);

        // Verify attachment
        LibraryUtilityOnPrem.CheckFileNotEmpty(ExportToFile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Attachment_Write()
    var
        TempAttachment: Record Attachment temporary;
        DataText: Text;
    begin
        // [SCENARIO] Attachment.Write() correctly writes BLOB text
        Initialize();
        LibraryMarketing.CreateAttachment(TempAttachment);

        DataText := GenerateContentBodyText();
        TempAttachment.Write(DataText);

        Assert.IsTrue(TempAttachment."Attachment File".HasValue(), AttachmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Attachment_Read()
    var
        TempAttachment: Record Attachment temporary;
        DataText: Text;
    begin
        // [SCENARIO] Attachment.Read() correctly returns BLOB text
        Initialize();
        LibraryMarketing.CreateAttachment(TempAttachment);

        DataText := GenerateContentBodyText();
        TempAttachment.Write(DataText);

        Assert.AreEqual(DataText, TempAttachment.Read(), AttachmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Attachment_Read_Negative()
    var
        TempAttachment: Record Attachment temporary;
    begin
        // [SCENARIO] Attachment.Read() returns empty string for empty attachment
        Initialize();
        LibraryMarketing.CreateAttachment(TempAttachment);

        Assert.IsFalse(TempAttachment."Attachment File".HasValue, AttachmentErr);
        Assert.AreEqual('', TempAttachment.Read(), AttachmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Attachment_Delete_InterLogEntry()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Attachment: Record Attachment;
    begin
        // [SCENARIO] Attachment is deleted after delete "Interaction Log Entry" record
        Initialize();
        LibraryMarketing.CreateAttachment(Attachment);
        MockInterLogEntry(InteractionLogEntry, InteractionLogEntry."Correspondence Type"::" ", Attachment."No.");

        InteractionLogEntry.Delete(true);

        Attachment.SetRecFilter();
        Assert.RecordIsEmpty(Attachment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WordAttachmentDetails()
    var
        Attachment: Record Attachment;
    begin
        // [SCENARIO] Word Attachment has no HTML details
        Initialize();
        FindWordAttachment(Attachment);

        Assert.IsTrue(Attachment."Attachment File".HasValue(), AttachmentErr);
        Assert.IsFalse(Attachment.IsHTML(), AttachmentErr);
        Assert.IsFalse(Attachment.IsHTMLCustomLayout(), AttachmentErr);
        Assert.IsFalse(Attachment.IsHTMLReady(), AttachmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_Negative()
    var
        TempAttachment: Record Attachment temporary;
        ContentBodyText: Text;
        CustomLayoutCode: Code[20];
    begin
        // [FEATURE] [Email Merge]
        // [SCENARIO] Empty Email Merge attachment has IsHTML=TRUE, IsHTMLReady=FALSE, IsHTMLCustomLayout=FALSE
        CreateEmptyHTMLAttachment(TempAttachment);

        Assert.IsTrue(TempAttachment.IsHTML(), AttachmentErr);
        Assert.IsFalse(TempAttachment.IsHTMLReady(), AttachmentErr);
        Assert.IsFalse(TempAttachment.IsHTMLCustomLayout(), AttachmentErr);
        Assert.IsFalse(TempAttachment.ReadHTMLCustomLayoutAttachment(ContentBodyText, CustomLayoutCode), AttachmentErr);

        TempAttachment.Write('ABCDEF');
        Assert.IsFalse(TempAttachment.IsHTMLCustomLayout(), AttachmentErr);
        Assert.IsFalse(TempAttachment.ReadHTMLCustomLayoutAttachment(ContentBodyText, CustomLayoutCode), AttachmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_Delete_InterTmplLang()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        Attachment: Record Attachment;
    begin
        // [FEATURE] [Email Merge]
        // [SCENARIO] Email Merge attachment is deleted after delete "Interaction Tmpl. Language" record
        Initialize();
        Attachment.Get(CreateInterLangCodeWithEmailMergeAttachment(InteractionTmplLanguage, ''));

        InteractionTmplLanguage.Delete(true);

        Attachment.SetRecFilter();
        Assert.RecordIsEmpty(Attachment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_Remove()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        Attachment: Record Attachment;
    begin
        // [FEATURE] [Email Merge]
        // [SCENARIO] Email Merge attachment is deleted after "Remove" action on Interaction Tmpl. Language record
        Initialize();
        Attachment.Get(CreateInterLangCodeWithEmailMergeAttachment(InteractionTmplLanguage, ''));

        InteractionTmplLanguage.RemoveAttachment(false);

        Attachment.SetRecFilter();
        Assert.RecordIsEmpty(Attachment);
    end;

    [Test]
    [HandlerFunctions('ContentPreviewMPH')]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_Open()
    var
        Attachment: Record Attachment;
    begin
        // [FEATURE] [Email Merge]
        // [SCENARIO] "Content Preview" page is opened for Email Merge attachment "OpenAttachment" record method
        Initialize();
        LibraryMarketing.CreateEmailMergeAttachment(Attachment);

        Attachment.OpenAttachment('', false, '');

        Attachment.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ContentPreviewMPH')]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_Open_InterTmplLang_OnAssistEdit()
    var
        Attachment: Record Attachment;
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractTmplLanguages: TestPage "Interact. Tmpl. Languages";
    begin
        // [FEATURE] [Email Merge]
        // [SCENARIO] "Content Preview" page is opened for AssistEdit action on "Attachment" field from "Interact. Tmpl. Languages" page
        Initialize();
        Attachment.Get(CreateInterLangCodeWithEmailMergeAttachment(InteractionTmplLanguage, ''));

        InteractTmplLanguages.OpenView();
        InteractTmplLanguages.GotoRecord(InteractionTmplLanguage);
        InteractTmplLanguages.Attachment.AssistEdit();
        InteractTmplLanguages.Close();

        InteractionTmplLanguage.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ContentPreviewMPH')]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_Open_InteractionTemplate_OnAssistEdit()
    var
        Attachment: Record Attachment;
        InteractionTemplate: Record "Interaction Template";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplates: TestPage "Interaction Templates";
    begin
        // [FEATURE] [Email Merge]
        // [SCENARIO] "Content Preview" page is opened for AssistEdit action on "Attachment" field from "Interaction Templates" page
        Initialize();
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        Attachment.Get(CreateInterLangCodeWithEmailMergeAttachment(InteractionTmplLanguage, InteractionTemplate.Code));
        InteractionTemplate.Get(InteractionTmplLanguage."Interaction Template Code");

        InteractionTemplates.OpenView();
        InteractionTemplates.GotoRecord(InteractionTemplate);
        InteractionTemplates.Attachment.AssistEdit();
        InteractionTemplates.Close();

        InteractionTemplate.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ContentPreviewMPH')]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_Open_InteractionLogEntries_OnAssistEdit()
    var
        Attachment: Record Attachment;
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionLogEntries: TestPage "Interaction Log Entries";
    begin
        // [FEATURE] [Email Merge]
        // [SCENARIO] "Content Preview" page is opened for AssistEdit action on "Attachment" field from "Interaction Log Entries" page
        Initialize();
        CreateHTMLReadyAttachment(Attachment);
        MockInterLogEntry(InteractionLogEntry, InteractionLogEntry."Correspondence Type"::Email, Attachment."No.");

        InteractionLogEntries.OpenView();
        InteractionLogEntries.GotoRecord(InteractionLogEntry);
        InteractionLogEntries.Attachment.AssistEdit();
        InteractionLogEntries.Close();

        InteractionLogEntry.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ContentPreviewMPH')]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_Show()
    var
        Attachment: Record Attachment;
        DummySegmentLine: Record "Segment Line";
    begin
        // [FEATURE] [Email Merge]
        // [SCENARIO] "Content Preview" page is opened for Email Merge attachment "ShowAttachment" record method
        Initialize();
        LibraryMarketing.CreateEmailMergeAttachment(Attachment);

        Attachment.ShowAttachment(DummySegmentLine, '');

        Attachment.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_Details()
    var
        Attachment: Record Attachment;
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        // [FEATURE] [Email Merge]
        // [SCENARIO] A new Email Merge Attachment is created with correct HTML details
        Initialize();
        Attachment.Get(CreateInterLangCodeWithEmailMergeAttachment(InteractionTmplLanguage, ''));

        Assert.IsTrue(Attachment."Attachment File".HasValue(), AttachmentErr);
        Assert.AreEqual(Attachment."Storage Type"::Embedded, Attachment."Storage Type", AttachmentErr);
        Assert.AreEqual(HtmlFileExtensionTxt, Attachment."File Extension", AttachmentErr);
        Assert.IsTrue(Attachment.IsHTML(), AttachmentErr);
        Assert.IsTrue(Attachment.IsHTMLCustomLayout(), AttachmentErr);
        Assert.IsFalse(Attachment.IsHTMLReady(), AttachmentErr);

        // Tear Down
        InteractionTmplLanguage.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_New()
    var
        Attachment: Record Attachment;
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        ContentBodyText: Text;
        CustomLayoutCode: Code[20];
        ExpectedLayoutCode: Code[20];
        CustomLayoutCodeLength: Integer;
        DataText: Text;
    begin
        // [FEATURE] [Email Merge]
        // [SCENARIO] A new Email Merge Attachment is created with correct BLOB
        Initialize();
        Attachment.Get(CreateInterLangCodeWithEmailMergeAttachment(InteractionTmplLanguage, ''));

        CustomLayoutCodeLength := StrLen(InteractionTmplLanguage."Custom Layout Code");
        ExpectedLayoutCode :=
          PadStr('', MaxStrLen(InteractionTmplLanguage."Custom Layout Code") - CustomLayoutCodeLength, '0') +
          InteractionTmplLanguage."Custom Layout Code";

        DataText := Attachment.Read();
        if DataText[1] <> '<' then  // build-in layout?
            Assert.AreEqual(ExpectedLayoutCode, DataText, AttachmentErr);
        Assert.IsTrue(Attachment.ReadHTMLCustomLayoutAttachment(ContentBodyText, CustomLayoutCode), AttachmentErr);

        // Tear Down
        InteractionTmplLanguage.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_Write()
    var
        TempAttachment: Record Attachment temporary;
        ExpectedData: Text;
        ContentBodyText: Text;
        CustomLayoutCode: Code[20];
    begin
        // [FEATURE] [Email Merge]
        // [SCENARIO] Attachment.WriteHTMLCustomLayoutAttachment() writes custom layout data
        Initialize();
        CreateEmptyHTMLAttachment(TempAttachment);

        ContentBodyText := GenerateContentBodyText();
        CustomLayoutCode := Format(LibraryRandom.RandIntInRange(100, 999));
        TempAttachment.WriteHTMLCustomLayoutAttachment(ContentBodyText, CustomLayoutCode);

        CustomLayoutCode := PadStr('', MaxStrLen(CustomLayoutCode) - StrLen(CustomLayoutCode), '0') + CustomLayoutCode;

        ExpectedData := CustomLayoutCode + ContentBodyText;
        Assert.AreEqual(ExpectedData, TempAttachment.Read(), AttachmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_Read()
    var
        TempAttachment: Record Attachment temporary;
        ExpectedContentBodyText: Text;
        ContentBodyText: Text;
        CustomLayoutCode: Code[20];
        ExpectedCustomLayoutCode: Code[20];
    begin
        // [FEATURE] [Email Merge]
        // [SCENARIO] Attachment.ReadHTMLCustomLayoutAttachment() reads custom layout data
        Initialize();
        CreateEmptyHTMLAttachment(TempAttachment);

        ExpectedContentBodyText := GenerateContentBodyText();
        ExpectedCustomLayoutCode := Format(LibraryRandom.RandIntInRange(100, 999));
        TempAttachment.WriteHTMLCustomLayoutAttachment(ExpectedContentBodyText, ExpectedCustomLayoutCode);

        Assert.IsTrue(TempAttachment.ReadHTMLCustomLayoutAttachment(ContentBodyText, CustomLayoutCode), AttachmentErr);
        Assert.AreEqual(ExpectedContentBodyText, ContentBodyText, AttachmentErr);
        Assert.AreEqual(ExpectedCustomLayoutCode, CustomLayoutCode, AttachmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_LoadHTMLContent_Negative()
    var
        TempAttachment: Record Attachment temporary;
        DummySegmentLine: Record "Segment Line";
    begin
        // [FEATURE] [Email Merge]
        // [SCENATIO] AttachmentManagement.LoadHTMLContent() returns empty text for empty attachment
        Initialize();
        LibraryMarketing.CreateAttachment(TempAttachment);
        Assert.AreEqual('', AttachmentManagement.LoadHTMLContent(TempAttachment, DummySegmentLine), HTMLContentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_LoadHTMLContent_HTMLReady()
    var
        TempAttachment: Record Attachment temporary;
        DummySegmentLine: Record "Segment Line";
        HTMLContent: Text;
    begin
        // [FEATURE] [Email Merge]
        // [SCENATIO] AttachmentManagement.LoadHTMLContent() returns html content string for html-ready attachment
        Initialize();
        CreateEmptyHTMLAttachment(TempAttachment);
        HTMLContent := GetSimpleHTMLContent();
        TempAttachment.Write(HTMLContent);

        Assert.IsTrue(TempAttachment.IsHTMLReady(), AttachmentErr);
        Assert.AreEqual(
          HTMLContent,
          AttachmentManagement.LoadHTMLContent(TempAttachment, DummySegmentLine),
          HTMLContentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_LoadHTMLContent_CustomLayout()
    var
        TempAttachment: Record Attachment temporary;
        DummySegmentLine: Record "Segment Line";
        HTMLContent: Text;
        HTMLContentLowerCase: Text;
        ContentBodyText: Text;
    begin
        // [FEATURE] [Email Merge]
        // [SCENATIO] AttachmentManagement.LoadHTMLContent() returns html content string for custom layout attachment
        Initialize();
        ContentBodyText := LibraryMarketing.CreateEmailMergeAttachment(TempAttachment);

        HTMLContent := AttachmentManagement.LoadHTMLContent(TempAttachment, DummySegmentLine);
        HTMLContentLowerCase := LowerCase(HTMLContent);

        Assert.AreEqual(1, StrPos(HTMLContentLowerCase, '<html>'), HTMLContentErr);
        Assert.AreEqual(StrLen(HTMLContent) - StrLen('</html>') + 1, StrPos(HTMLContentLowerCase, '</html>'), HTMLContentErr);
        Assert.IsTrue(StrPos(HTMLContent, ContentBodyText) > 1, HTMLContentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_GenerateHTMLContent_Negative()
    var
        TempAttachment: Record Attachment temporary;
        DummySegmentLine: Record "Segment Line";
    begin
        // [FEATURE] [Email Merge]
        // [SCENATIO] AttachmentManagement.GenerateHTMLContent() doesn't create html content for empty attachment
        LibraryMarketing.CreateAttachment(TempAttachment);

        Assert.IsFalse(
          AttachmentManagement.GenerateHTMLContent(TempAttachment, DummySegmentLine),
          HTMLContentErr);
        Assert.IsFalse(TempAttachment."Attachment File".HasValue(), HTMLContentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_GenerateHTMLContent_HTMLReady()
    var
        TempAttachment: Record Attachment temporary;
        DummySegmentLine: Record "Segment Line";
        HTMLContent: Text;
    begin
        // [FEATURE] [Email Merge]
        // [SCENATIO] AttachmentManagement.GenerateHTMLContent() returns html content string for html-ready attachment
        HTMLContent := CreateHTMLReadyAttachment(TempAttachment);

        Assert.IsTrue(TempAttachment.IsHTMLReady(), AttachmentErr);
        Assert.IsTrue(
          AttachmentManagement.GenerateHTMLContent(TempAttachment, DummySegmentLine),
          HTMLContentErr);
        Assert.IsTrue(TempAttachment."Attachment File".HasValue, HTMLContentErr);
        Assert.AreEqual(HTMLContent, TempAttachment.Read(), HTMLContentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailMergeAttachment_GenerateHTMLContent_CustomLayout()
    var
        TempAttachment: Record Attachment temporary;
        DummySegmentLine: Record "Segment Line";
        HTMLContent: Text;
    begin
        // [FEATURE] [Email Merge]
        // [SCENATIO] AttachmentManagement.GenerateHTMLContent() returns html content string for custom layout attachment
        LibraryMarketing.CreateEmailMergeAttachment(TempAttachment);
        HTMLContent := AttachmentManagement.LoadHTMLContent(TempAttachment, DummySegmentLine);

        Assert.IsTrue(
          AttachmentManagement.GenerateHTMLContent(TempAttachment, DummySegmentLine),
          HTMLContentErr);
        Assert.IsTrue(TempAttachment."Attachment File".HasValue(), HTMLContentErr);
        Assert.AreEqual(HTMLContent, TempAttachment.Read(), HTMLContentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendAttachment_EmptyBuffer()
    var
        TempDeliverySorter: Record "Delivery Sorter" temporary;
    begin
        // [FEATURE] [Send]
        // [SCENARIO] AttachmentManagement.Send(): no error when called with empty buffer
        AttachmentManagement.Send(TempDeliverySorter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendAttachment_Negative_CorrespondenceTypeMandatory()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        TempDeliverySorter: Record "Delivery Sorter" temporary;
    begin
        // [FEATURE] [Send]
        // [SCENARIO] AttachmentManagement.Send(): "Correspondence Type" is a mandatory field
        MockInterLogEntry(InteractionLogEntry, InteractionLogEntry."Correspondence Type"::" ", 0);
        MockDeliverySorter(TempDeliverySorter, InteractionLogEntry);

        asserterror AttachmentManagement.Send(TempDeliverySorter);
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedError(TempDeliverySorter.FieldCaption("Correspondence Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendAttachment_Negative_AttachmentDoesntExist()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        TempDeliverySorter: Record "Delivery Sorter" temporary;
        AttachmentManagement: Codeunit AttachmentManagement;
    begin
        // [FEATURE] [Send]
        // [SCENARIO] AttachmentManagement.Send(): "Attachment No." should exist
        MockInterLogEntry(InteractionLogEntry, InteractionLogEntry."Correspondence Type"::Email, 0);
        MockDeliverySorter(TempDeliverySorter, InteractionLogEntry);

        asserterror AttachmentManagement.Send(TempDeliverySorter);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(SendAttachmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendAttachment_HTML_NotEmail()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Attachment: Record Attachment;
        TempDeliverySorter: Record "Delivery Sorter" temporary;
        AttachmentManagement: Codeunit AttachmentManagement;
    begin
        // [FEATURE] [Send]
        // [SCENARIO] AttachmentManagement.Send() with "html" attachment: InteractLogEntry."Delivery Status" = Error in case of "Correspondence Type" = "Hard Copy"
        CreateHTMLReadyAttachment(Attachment);
        MockInterLogEntry(InteractionLogEntry, InteractionLogEntry."Correspondence Type"::"Hard Copy", Attachment."No.");
        MockDeliverySorter(TempDeliverySorter, InteractionLogEntry);

        AttachmentManagement.Send(TempDeliverySorter);

        InteractionLogEntry.Find();
        Assert.AreEqual(
          InteractionLogEntry."Delivery Status"::Error,
          InteractionLogEntry."Delivery Status",
          InteractionLogEntry.FieldCaption("Delivery Status"));

        // Tear Down
        InteractionLogEntry.Delete(true);
    end;

    [Test]
    [HandlerFunctions('EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure SendAttachment_HTML_Cancel()
    begin
        SendAttachment_HTML_Cancel_Internal();
    end;

    procedure SendAttachment_HTML_Cancel_Internal()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Attachment: Record Attachment;
        TempDeliverySorter: Record "Delivery Sorter" temporary;
        LibraryEmail: Codeunit "Library - Email";
    begin
        // [FEATURE] [Send]
        // [SCENARIO] AttachmentManagement.Send() with "html" attachment: InteractLogEntry."Delivery Status" = Error in case of canceling "Email Dialog"
        Initialize();
        LibraryEmail.SetUpEmailAccount();

        LibraryVariableStorage.Enqueue(CreateHTMLReadyAttachment(Attachment));
        MockInterLogEntry(InteractionLogEntry, InteractionLogEntry."Correspondence Type"::Email, Attachment."No.");
        MockDeliverySorter(TempDeliverySorter, InteractionLogEntry);

        AttachmentManagement.Send(TempDeliverySorter);

        // Verify email html content in EmailDialog_Cancel_MPH handler
        InteractionLogEntry.Find();
        Assert.AreEqual(
          InteractionLogEntry."Delivery Status"::Error,
          InteractionLogEntry."Delivery Status",
          InteractionLogEntry.FieldCaption("Delivery Status"));

        // Tear Down
        InteractionLogEntry.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendAttachment_Other_NotEmail()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Attachment: Record Attachment;
        TempDeliverySorter: Record "Delivery Sorter" temporary;
        AttachmentManagement: Codeunit AttachmentManagement;
    begin
        // [FEATURE] [Send]
        // [SCENARIO] AttachmentManagement.Send() with "other" attachment: InteractLogEntry."Delivery Status" = Error in case of "Correspondence Type" = "Hard Copy"
        LibraryMarketing.CreateAttachment(Attachment);
        MockInterLogEntry(InteractionLogEntry, InteractionLogEntry."Correspondence Type"::"Hard Copy", Attachment."No.");
        MockDeliverySorter(TempDeliverySorter, InteractionLogEntry);

        AttachmentManagement.Send(TempDeliverySorter);

        InteractionLogEntry.Find();
        Assert.AreEqual(
          InteractionLogEntry."Delivery Status"::Error,
          InteractionLogEntry."Delivery Status",
          InteractionLogEntry.FieldCaption("Delivery Status"));

        // Tear Down
        InteractionLogEntry.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SendAttachment_Other_ContactIsMandatory()
    var
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        Attachment: Record Attachment;
        TempDeliverySorter: Record "Delivery Sorter" temporary;
    begin
        // [FEATURE] [Send]
        // [SCENARIO] AttachmentManagement.Send() with "other" attachment: "Contact No." field is mandatory
        CreateAttachment(Attachment);
        FindTXTAttachment(Attachment);
        MockInterLogEntry(InteractionLogEntry, InteractionLogEntry."Correspondence Type"::Email, Attachment."No.");
        MockDeliverySorter(TempDeliverySorter, InteractionLogEntry);

        InteractionLogEntry."Contact No." := '';
        InteractionLogEntry.Modify();

        asserterror AttachmentManagement.Send(TempDeliverySorter);
        Assert.ExpectedErrorCode('DB:RecordNotFound');
        Assert.ExpectedError(Contact.TableCaption());
    end;

    [Test]
    [HandlerFunctions('ActionHandler')]
    [Scope('OnPrem')]
    procedure SendAttachment_HTML_Email()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Attachment: Record Attachment;
        TempDeliverySorter: Record "Delivery Sorter" temporary;
        AttachmentManagement: Codeunit AttachmentManagement;
        LibraryOfficeHostProvider: Codeunit "Library - Office Host Provider";
        OfficeHostType: DotNet OfficeHostType;
    begin
        CreateHTMLReadyAttachment(Attachment);
        MockInterLogEntry(InteractionLogEntry, InteractionLogEntry."Correspondence Type"::Email, Attachment."No.");
        MockDeliverySorter(TempDeliverySorter, InteractionLogEntry);

        Clear(LibraryOfficeHostProvider);
        BindSubscription(LibraryOfficeHostProvider);
        InitializeOfficeHostProvider(OfficeHostType.OutlookItemEdit);

        LibraryVariableStorage.Enqueue('sendAttachment');
        LibraryVariableStorage.Enqueue(TempDeliverySorter.Subject);
        AttachmentManagement.Send(TempDeliverySorter);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DiskAttachmentWithoutExtension()
    var
        Attachment: Record Attachment;
        NewDirName: Text;
    begin
        // [SCENARIO 222748] Import/Show old exported attachment without extension
        Initialize();

        // [GIVEN] TXT attachment
        CreateAttachment(Attachment);
        // [GIVEN] Relocated to disk attachments, mock old exported attachment without extension
        RelocateAttachments(MarketingSetup."Attachment Storage Type"::"Disk File", CreateOrClearTempDirectory(NewDirName));
        Rename(
          NewDirName + '\' + Format(Attachment."No.") + '.' + Attachment."File Extension",
          NewDirName + '\' + Format(Attachment."No."));
        // [WHEN] Relocate attachments back to database
        Rollback(NewDirName);
        // [THEN] Attachment without extension relocated to database (verification in Rollback)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_AttachmentSetMessageIDClean()
    var
        Attachment: Record Attachment;
        NewMessageId: Text;
    begin
        // [SCENARIO] Attachment SetMessageID clears "Email Message ID" before rewrite
        Initialize();
        // [GIVE] Attachment record
        LibraryMarketing.CreateAttachment(Attachment);
        // [GIVEN] Email Message ID = 'ABC'
        Attachment.SetMessageID('ABC');
        Attachment.Modify();
        // [WHEN] Assign 'AB' to Email Message ID using SetMessageID
        NewMessageId := 'AB';
        Attachment.SetMessageID(NewMessageId);
        Attachment.Modify();
        // [THEN] The value of Email Message ID = 'AB'
        Assert.AreEqual(NewMessageId, Attachment.GetMessageID(), AttachmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_AttachmentSetEntryIDClean()
    var
        Attachment: Record Attachment;
        Stream: InStream;
        NewEntryId: Text;
        FromEmailEntryID: Text;
    begin
        // [SCENARIO] Attachment SetEntryID clears "Email Entry ID" before rewrite
        Initialize();
        // [GIVE] Attachment record
        LibraryMarketing.CreateAttachment(Attachment);
        // [GIVEN] Email Entry ID = 'ABC'
        Attachment.SetEntryID('ABC');
        Attachment.Modify();
        // [WHEN] Assign 'AB' to Email Entry ID using SetMessageID
        NewEntryId := 'AB';
        Attachment.SetEntryID(NewEntryId);
        Attachment.Modify();
        // [THEN] The value of Email Entry ID = 'AB'
        Attachment.CalcFields("Email Entry ID");
        Attachment."Email Entry ID".CreateInStream(Stream);
        Stream.ReadText(FromEmailEntryID);
        Assert.AreEqual(NewEntryId, FromEmailEntryID, AttachmentErr);
    end;

    local procedure Initialize()
    var
        DataTypeBuffer: Record "Data Type Buffer";
    begin
        BindActiveDirectoryMockEvents();
        LibraryVariableStorage.Clear();
        DataTypeBuffer.DeleteAll();
        if IsInitialized then
            exit;

        InitializeAttachments();

        IsInitialized := true;

        Commit();
    end;

    local procedure RelocateAttachments(StorageType: Enum "Setup Attachment Storage Type"; Path: Text)
    var
        MarketingSetupPage: Page "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Attachment Storage Type", StorageType);
        MarketingSetup.Validate("Attachment Storage Location", CopyStr(Path, 1, 250));
        MarketingSetup.Modify(true);

        MarketingSetup.Get();
        MarketingSetupPage.SetRecord(MarketingSetup);
        MarketingSetupPage.SetAttachmentStorageType();
    end;

    local procedure Rollback(DirName: Text)
    begin
        // "Embed" attachments back into DB
        RelocateAttachments(MarketingSetup."Attachment Storage Type"::Embedded, '');

        VerifyAttachmentsEmbeded();

        if DirName <> '' then
            CreateOrClearTempDirectory(DirName);
    end;

    local procedure InitializeAttachments()
    var
        Attachment: Record Attachment;
    begin
        // Make sure Attachment storage type is Embeded
        MarketingSetup.Get();
        MarketingSetup.Validate("Attachment Storage Type", MarketingSetup."Attachment Storage Type"::Embedded);
        MarketingSetup.Modify();

        EmbedAttachments();
        CreateAttachment(Attachment);
    end;

    local procedure EmbedAttachments()
    var
        Attachment: Record Attachment;
    begin
        if Attachment.FindSet() then
            repeat
                if Attachment."Storage Type" <> Attachment."Storage Type"::Embedded then begin
                    Attachment."Storage Type" := Attachment."Storage Type"::Embedded;
                    Attachment."Storage Pointer" := '';
                end;

                Attachment.CalcFields("Attachment File");
                if not Attachment."Attachment File".HasValue() then begin
                    Attachment."Attachment File".Import(CreateServerTxtFile(FileExtensionTxt));
                    Attachment."File Extension" := FileExtensionTxt;
                end;
                Attachment.Modify();
            until Attachment.Next() = 0;
    end;

    local procedure CreateAttachment(var Attachment: Record Attachment)
    begin
        LibraryMarketing.CreateAttachment(Attachment);
        Attachment."Attachment File".Import(CreateServerTxtFile(FileExtensionTxt));
        Attachment."File Extension" := FileExtensionTxt;
        Attachment."Read Only" := true;
        Attachment.Modify();
    end;

    local procedure CreateOrClearTempDirectory(var NewDirName: Text): Text
    var
        Directory: DotNet Directory;
    begin
        // Create new directory on server
        if NewDirName = '' then
            NewDirName := TemporaryPath + '\' + LibraryUtility.GenerateGUID();

        if Directory.Exists(NewDirName) then begin
            Directory.Delete(NewDirName, true);
            Directory.CreateDirectory(NewDirName);
        end else
            Directory.CreateDirectory(NewDirName);

        exit(NewDirName);
    end;

    [Scope('OnPrem')]
    procedure CreateEmptyHTMLAttachment(var Attachment: Record Attachment)
    begin
        LibraryMarketing.CreateAttachment(Attachment);
        Attachment."Storage Type" := Attachment."Storage Type"::Embedded;
        Attachment."File Extension" := HtmlFileExtensionTxt;
        Attachment.Modify(true);
    end;

    local procedure CreateInterLangCodeWithEmailMergeAttachment(var InteractionTmplLanguage: Record "Interaction Tmpl. Language"; InteractionTemplateCode: Code[10]): Integer
    begin
        InteractionTmplLanguage.Init();
        InteractionTmplLanguage."Interaction Template Code" := InteractionTemplateCode;
        InteractionTmplLanguage."Report Layout Name" := LibraryMarketing.FindEmailMergeCustomLayoutName();
        InteractionTmplLanguage.CreateAttachment();
        exit(InteractionTmplLanguage."Attachment No.");
    end;

    local procedure CreateHTMLReadyAttachment(var Attachment: Record Attachment) HTMLContent: Text
    begin
        CreateEmptyHTMLAttachment(Attachment);
        HTMLContent := GetSimpleHTMLContent();
        Attachment.Write(HTMLContent);
        Attachment.Modify();
    end;

    local procedure MockInterLogEntry(var InteractionLogEntry: Record "Interaction Log Entry"; CorrespondenceType: Enum "Correspondence Type"; AttachmentNo: Integer): Integer
    var
        Contact: Record Contact;
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        InteractionLogEntry.Init();
        InteractionLogEntry."Entry No." := LibraryUtility.GetNewRecNo(InteractionLogEntry, InteractionLogEntry.FieldNo("Entry No."));
        InteractionLogEntry."Contact No." := Contact."No.";
        InteractionLogEntry."Correspondence Type" := CorrespondenceType;
        InteractionLogEntry."Attachment No." := AttachmentNo;
        InteractionLogEntry.Insert(true);
        exit(InteractionLogEntry."Entry No.");
    end;

    local procedure MockDeliverySorter(var DeliverySorter: Record "Delivery Sorter"; InteractionLogEntry: Record "Interaction Log Entry")
    begin
        DeliverySorter.Init();
        DeliverySorter."No." := InteractionLogEntry."Entry No.";
        DeliverySorter."Correspondence Type" := InteractionLogEntry."Correspondence Type";
        DeliverySorter."Attachment No." := InteractionLogEntry."Attachment No.";
        DeliverySorter.Insert(true);
    end;

    local procedure GenerateContentBodyText(): Text
    begin
        // make sure text length > 1024
        exit(LibraryUtility.GenerateRandomAlphabeticText(LibraryRandom.RandIntInRange(2000, 3000), 0));
    end;

    local procedure VerifyAttachmentsOnDisk(Path: Text)
    var
        Attachment: Record Attachment;
    begin
        Attachment.FindSet();
        repeat
            Assert.IsTrue(Attachment."Storage Type" = Attachment."Storage Type"::"Disk File",
              StrSubstNo('Attachment %1 not relocated to disk', Attachment."No."));
            Assert.IsTrue(Attachment."Storage Pointer" = Path,
              StrSubstNo('Attachment %1 not relocated to disk', Attachment."No."));
            LibraryUtilityOnPrem.CheckFileNotEmpty(Attachment.ConstDiskFileName());
        until Attachment.Next() = 0;
    end;

    local procedure VerifyAttachmentsEmbeded()
    var
        Attachment: Record Attachment;
    begin
        Attachment.FindSet();
        repeat
            Assert.IsTrue(Attachment."Storage Type" = Attachment."Storage Type"::Embedded,
              StrSubstNo('Attachment %1 not relocated to DB', Attachment."No."));
            Assert.IsTrue(Attachment."Storage Pointer" = '',
              StrSubstNo('Attachment %1 not relocated to DB', Attachment."No."));
            Attachment.CalcFields("Attachment File");
            Assert.IsTrue(Attachment."Attachment File".HasValue,
              StrSubstNo('Attachment %1 is empty in DB', Attachment."No."));
        until Attachment.Next() = 0;
    end;

    local procedure FindNonEmptyAttachment(var Attachment: Record Attachment)
    begin
        Clear(Attachment);

        Attachment.FindSet();
        repeat
            Attachment.CalcFields("Attachment File");
            if Attachment."Attachment File".HasValue() then
                exit;
        until Attachment.Next() = 0;
    end;

    local procedure FindWordAttachment(var Attachment: Record Attachment)
    begin
        Attachment.SetRange("Storage Type", Attachment."Storage Type"::Embedded);
        Attachment.SetFilter("File Extension", StrSubstNo('%1|%2', 'DOC', 'DOCX'));
        Attachment.FindFirst();
    end;

    local procedure FindTXTAttachment(var Attachment: Record Attachment)
    begin
        Attachment.SetRange("Storage Type", Attachment."Storage Type"::Embedded);
        Attachment.SetRange("File Extension", FileExtensionTxt);
        Attachment.FindFirst();
    end;

    local procedure CreateServerTxtFile(FileExtension: Text) FileName: Text
    var
        TxtFile: File;
        StreamT: OutStream;
    begin
        FileName := FileManagement.ServerTempFileName(FileExtension);

        TxtFile.TextMode(true);
        TxtFile.Create(FileName);
        TxtFile.CreateOutStream(StreamT);
        StreamT.WriteText('Text');
        StreamT.WriteText();
        TxtFile.Close();

        exit(FileName);
    end;

    local procedure GetSimpleHTMLContent(): Text
    begin
        exit(
          '<html><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" />' +
          '<meta http-equiv="Content-Style-Type" content="text/css" />' +
          '<meta name="generator" content="Aspose.Words for .NET 16.1.0.0" />' +
          '<title></title></head><body><div><p style="font-size:11pt; line-height:115%; margin:0pt 0pt 10pt">' +
          '<span style="font-family:''Times New Roman''; font-size:11pt">&#xa0;</span></p></div></body></html>');
    end;

    local procedure InitializeOfficeHostProvider(HostType: Text)
    var
        OfficeAddinContext: Record "Office Add-in Context";
        OfficeManagement: Codeunit "Office Management";
        OfficeHost: DotNet OfficeHost;
    begin
        OfficeAddinContext.DeleteAll();
        SetOfficeHostUnAvailable();
        SetOfficeHostProvider(Codeunit::"Library - Office Host Provider");
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

    local procedure ExtractComponent(var String: Text; var Component: Text)
    var
        DelimiterPos: Integer;
    begin
        DelimiterPos := StrPos(String, '|');
        Component := CopyStr(String, 1, DelimiterPos - 1);
        String := CopyStr(String, DelimiterPos + 1);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContentPreviewMPH(var ContentPreview: TestPage "Content Preview")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), EmailEditor.BodyField.Value);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ActionHandler(Message: Text[1024])
    var
        ActualAction: Text;
        DummyText: Text;
        ActualSubject: Text;
    begin
        ExtractComponent(Message, ActualAction);
        ExtractComponent(Message, DummyText);
        ExtractComponent(Message, DummyText);
        ExtractComponent(Message, DummyText);
        ActualSubject := Message;

        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ActualAction, 'Incorrect JavaScript action called from C/AL.');
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ActualSubject, 'Unexpected subject passed to JS function.');
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;
}

