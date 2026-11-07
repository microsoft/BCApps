codeunit 136208 "Marketing Interaction"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Interaction] [Marketing]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryEmail: Codeunit "Library - Email";
        LibraryPermissions: Codeunit "Library - Permissions";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        isInitialized: Boolean;
        FieldEmptyErr: Label 'You must fill in the %1 field.';
        UnknownErr: Label 'Unknown error.';
        RollbackErr: Label 'Rollback.';
        DialogTxt: Label 'Dialog';
        CanNotBeSpecifiedErr: Label '%1 = %2 can not be specified for %3 %4.';
        WordAppExist: Boolean;
        WizardAction: Enum "Interaction Template Wizard Action";
        FinishWizardLaterQst: Label 'Do you want to finish this interaction later?';
        SelectContactErr: Label 'You must select a contact to interact with.';
        IsNotFoundOnPageErr: Label 'is not found on the page.';
        FirstContentBodyTxt: Label 'First Content Body Text';
        FilePathsAreNotEqualErr: Label 'Export file path is not equal to file path of the attachment.';
        WordTemplateUsedErr: Label 'You cannot use an attachment when a Word template has been specified.';
        NoAttachmentErr: Label 'No attachment found. You must either add an attachment or choose a template in the Word Template Code field on the Interaction Template page.';
        TitleFromLbl: Label '%1 - from %2', Comment = '%1 - document description, %2 - name';
        TitleByLbl: Label '%1 - by %2', Comment = '%1 - document description, %2 - name';
        SegmentSendContactEmailFaxMissingErr: Label 'Make sure that the %1 field is specified for either contact no. %2 or the contact alternative address.', Comment = '%1 - Email or Fax No. field caption, %2 - Contact No.';
        NoOfInteractionEntriesMustMatchErr: Label 'No. of Interaction Entries must match.';
        LoggedSegemntEntriesCreateMsg: Label 'Logged Segment entry was created';
        AttachmentFileShouldNotBeBlankErr: Label 'Attachment File should not be blank.';
        TxtFileExt: Label 'txt';
        EvaluationErr: Label '%1 must be %2 in %3', Comment = '%1 = Evaluation, %2 = Positive, %3 = Interaction Log Entry';

    [Test]
    [Scope('OnPrem')]
    procedure CreationInteractionGroup()
    var
        InteractionGroup: Record "Interaction Group";
    begin
        // Test that it is possible to create a new Interaction Group.

        // 1. Setup:
        Initialize();

        // 2. Exercise: Create Interaction Group.
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);

        // 3. Verify: Check that Interaction Group created.
        InteractionGroup.Get(InteractionGroup.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreationInteractionTemplate()
    var
        InteractionGroup: Record "Interaction Group";
        InteractionTemplate: Record "Interaction Template";
    begin
        // Test that it is possible to create a new Interaction Template.

        // 1. Setup: Create Interaction Group.
        Initialize();
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);

        // 2. Exercise: Create Interaction Template with Interaction Group Code.
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate.Validate("Interaction Group Code", InteractionGroup.Code);
        InteractionTemplate.Modify(true);

        // 3. Verify: Check that Interaction Template created with Interaction Group Code.
        InteractionTemplate.Get(InteractionTemplate.Code);
        InteractionTemplate.TestField("Interaction Group Code", InteractionGroup.Code);
    end;

    [Test]
    [HandlerFunctions('ModalFormInteractionGroupStat')]
    [Scope('OnPrem')]
    procedure OpenInteractionGroupStatistics()
    var
        InteractionGroup: Record "Interaction Group";
        InteractionTemplate: Record "Interaction Template";
        SegmentHeader: Record "Segment Header";
        InteractionGroupStatistics: Page "Interaction Group Statistics";
    begin
        // Test that it is possible to open Interaction Group Statistics with correct values.

        // 1. Setup: Create Interaction Group, Interaction Template. Create a Segment.
        Initialize();
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);

        UpdateInteractionTemplate(InteractionTemplate, InteractionGroup.Code);
        CreateSegment(SegmentHeader, InteractionTemplate.Code);

        // 2. Exercise: Run Log Segment Batch Job for Created Segment.
        RunLogSegment(SegmentHeader."No.");

        // 3. Verify: Check that Interaction Group Statistics opens with correct values.
        LibraryVariableStorage.Enqueue(InteractionTemplate."Unit Cost (LCY)");
        LibraryVariableStorage.Enqueue(InteractionTemplate."Unit Duration (Min.)");
        Clear(InteractionGroupStatistics);
        InteractionGroupStatistics.SetRecord(InteractionGroup);
        InteractionGroupStatistics.RunModal();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RemoveAttachment()
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        // Test that it is possible to Remove Attachment from Interaction Template.

        // 1. Setup: Find the Interaction Template with Attachment.
        Initialize();
        InteractionTemplate.SetFilter("Attachment No.", '<>0');  // Check for an Template that has some attachment.
        InteractionTemplate.FindFirst();

        // 2. Exercise: Remove the Attachment.
        InteractionTmplLanguage.Get(InteractionTemplate.Code, InteractionTemplate."Language Code (Default)");
        InteractionTmplLanguage.RemoveAttachment(true);

        // 3. Verify: Check the Attachment has been removed.
        InteractionTemplate.CalcFields("Attachment No.");
        InteractionTemplate.TestField("Attachment No.", 0);  // Checks that there are no attachment.

        // 4. TearDown:
        TransactionRollback();
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerCreateInteract')]
    [Scope('OnPrem')]
    procedure InteractionWithoutTemplate()
    var
        Contact: Record Contact;
        SegmentLine: Record "Segment Line";
        LibraryMarketing: Codeunit "Library - Marketing";
    begin
        // Test that application generates an error on creating Interaction without Interaction Template code in Interaction Wizard.

        // 1. Setup: Create a Contact.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Create Interaction without Interaction Template code in Interaction Wizard.
        asserterror CreateInteractionFromContact(Contact, '');

        // 3. Verify: Check application generates an error on creating Interaction without Interaction Template code in Interaction Wizard.
        Assert.AreEqual(StrSubstNo(FieldEmptyErr, SegmentLine.FieldCaption("Interaction Template Code")), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerCreateInteract')]
    [Scope('OnPrem')]
    procedure InteractionWithoutDescription()
    var
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        SegmentLine: Record "Segment Line";
        LibraryMarketing: Codeunit "Library - Marketing";
    begin
        // [SCENARIO] Application generates an error on creating Interaction without Description in "Create Interaction" page.
        Initialize();
        // [GIVEN] Create a Contact.
        LibraryMarketing.CreateCompanyContact(Contact);
        // [GIVEN] Create Interaction Template, where Description is <blank>
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate.Description := '';
        InteractionTemplate.Modify();
        // [GIVEN] Run "Create Interaction" page from Contact

        // [WHEN] Enter "Interaction Template Code" and close the page
        // by ModalFormHandlerCreateInteract
        asserterror CreateInteractionFromContact(Contact, InteractionTemplate.Code);

        // [THEN] The error : "You must fill in the Description"
        Assert.AreEqual(StrSubstNo(FieldEmptyErr, SegmentLine.FieldCaption(Description)), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('CreateInteractPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionForContact()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        TemplateCode: Code[10];
    begin
        // Test for successful Contact Interaction.

        // 1. Setup: Create Interaction Group, Create Interaction Template, Create Contact, Save Template Code in Global Variable.
        Initialize();
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        TemplateCode := CreateAndUpdateTemplate(InteractionGroup.Code);
        LibraryMarketing.CreateCompanyContact(Contact);

        // 2. Exercise: Create Interaction for Contact.
        CreateInteractionFromContact(Contact, TemplateCode);

        // 3. Verify: Verify that Interaction successfully logged in Interaction Log Entry.
        VerifyInteractionLogEntry(Contact."No.", TemplateCode);
    end;

    [Test]
    [HandlerFunctions('CreateInteractPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionFromLogEntries()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        InteractionLogEntry: Record "Interaction Log Entry";
        TemplateCode: array[2] of Code[10];
    begin
        // Test to check that it is possible to create Interaction for a Contact from Interaction Log Entries.

        // 1. Setup: Create Interaction Group, Interaction Templates, Create Contact and Interaction for the Contact.
        Initialize();
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        TemplateCode[1] := CreateAndUpdateTemplate(InteractionGroup.Code);
        TemplateCode[2] := CreateAndUpdateTemplate(InteractionGroup.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateInteractionFromContact(Contact, TemplateCode[1]);

        // 2. Exercise: Create Interaction From Interaction Log Entries.
        FindInteractionLogEntry(InteractionLogEntry, Contact."No.", InteractionGroup.Code, TemplateCode[1]);
        CreateInteractionFromLogEntry(InteractionLogEntry, TemplateCode[2], false, 0, 0);

        // 3. Verify: Verify Interaction Log Entry for the Second Interaction Template.
        VerifyInteractionLogEntry(Contact."No.", TemplateCode[2]);
    end;

    [Test]
    [HandlerFunctions('CreateInteractPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionForNewCostAndAmount()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplate: Record "Interaction Template";
        CostLCY: Decimal;
        DurationMin: Decimal;
    begin
        // Test to check Interaction Details can be successfully updated while creating Interaction for Contact.
        Initialize();

        // 1. Setup: Create Interaction Group, Interaction Template, Create Contact and Interaction for the Contact.
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        InteractionTemplate.Get(CreateAndUpdateTemplate(InteractionGroup.Code));
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateInteractionFromContact(Contact, InteractionTemplate.Code);

        // Take Random Cost LCY and Duration greater than Interaction Template's Cost LCY and Duration and store in Global Variable.
        CostLCY := InteractionTemplate."Unit Cost (LCY)" + LibraryRandom.RandInt(10);
        DurationMin := InteractionTemplate."Unit Duration (Min.)" + LibraryRandom.RandInt(10);

        // 2. Exercise: Create Interaction From Interaction Log Entries.
        FindInteractionLogEntry(InteractionLogEntry, Contact."No.", InteractionGroup.Code, InteractionTemplate.Code);
        CreateInteractionFromLogEntry(InteractionLogEntry, InteractionTemplate.Code, true, CostLCY, DurationMin);

        // 3. Verify: Verify that new Cost and Duration updated in Interaction Log Entry.
        InteractionLogEntry.FindLast();
        InteractionLogEntry.TestField("Cost (LCY)", CostLCY);
        InteractionLogEntry.TestField("Duration (Min.)", DurationMin);
    end;

    [Test]
    [HandlerFunctions('CreateInteractPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionTemplateStatistics()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplate: Record "Interaction Template";
        CostLCY: Decimal;
        DurationMin: Decimal;
    begin
        // Test to verify Interaction Template Statistics after creating Interaction.
        Initialize();

        // 1. Setup: Create Interaction Group, Interaction Template, Create Contact and Interaction for the Contact.
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        InteractionTemplate.Get(CreateAndUpdateTemplate(InteractionGroup.Code));
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateInteractionFromContact(Contact, InteractionTemplate.Code);

        // Take Random Cost LCY and Duration greater than Interaction Template's Cost LCY and Duration and store in Global Variable.
        DurationMin := InteractionTemplate."Unit Duration (Min.)" + LibraryRandom.RandInt(10);
        CostLCY := InteractionTemplate."Unit Cost (LCY)" + LibraryRandom.RandInt(10);

        // 2. Exercise: Create Interaction From Interaction Log Entries.
        FindInteractionLogEntry(InteractionLogEntry, Contact."No.", InteractionGroup.Code, InteractionTemplate.Code);
        CreateInteractionFromLogEntry(InteractionLogEntry, InteractionTemplate.Code, true, CostLCY, DurationMin);

        // 3. Verify: Verify Values on Interaction Template Statistics Page.
        InteractionTemplate.CalcFields("No. of Interactions", "Cost (LCY)", "Duration (Min.)");
        VerifyTemplateStatistics(InteractionTemplate);
    end;

    [Test]
    [HandlerFunctions('CreateInteractPageHandler')]
    [Scope('OnPrem')]
    procedure InteractionGroupStatistics()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        InteractionLogEntry: Record "Interaction Log Entry";
        TemplateCode: array[2] of Code[10];
    begin
        // Test to verify Interaction Group Statistics after creating Interaction.

        // 1. Setup: Create Interaction Group, Interaction Templates, Create Contact and Interaction for the Contact.
        Initialize();
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        TemplateCode[1] := CreateAndUpdateTemplate(InteractionGroup.Code);  // Set value in global variable.
        TemplateCode[2] := CreateAndUpdateTemplate(InteractionGroup.Code);
        LibraryMarketing.CreateCompanyContact(Contact);
        CreateInteractionFromContact(Contact, TemplateCode[1]);

        // 2. Exercise: Create Interaction From Interaction Log Entries.
        FindInteractionLogEntry(InteractionLogEntry, Contact."No.", InteractionGroup.Code, TemplateCode[1]);
        CreateInteractionFromLogEntry(InteractionLogEntry, TemplateCode[2], false, 0, 0);

        // 3. Verify: Verify Entries on Interaction Group Statistics Page.
        InteractionGroup.CalcFields("No. of Interactions", "Cost (LCY)", "Duration (Min.)");
        VerifyTemplateGroupStatistics(InteractionGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWizardActionWithoutLangCode()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" can be validated with any value for an Interaction Template without Interaction Tmpl. Language
        Initialize();
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);

        for WizardAction := WizardAction::" " to WizardAction::Merge do begin
            InteractionTemplate.Validate("Wizard Action", WizardAction);
            Assert.AreEqual(WizardAction, InteractionTemplate."Wizard Action", InteractionTemplate.FieldCaption("Wizard Action"));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWizardActionWithLangCodeWithoutAttachment()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" can not be validated with "Merge" value for an Interaction Template with Interaction Tmpl. Language without attachment
        Initialize();
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateInteractionTmplLangWithoutAttachment(InteractionTmplLanguage, InteractionTemplate.Code);

        InteractionTemplate.Validate("Language Code (Default)", InteractionTmplLanguage."Language Code");
        for WizardAction := WizardAction::" " to WizardAction::Import do begin
            InteractionTemplate.Validate("Wizard Action", WizardAction);
            Assert.AreEqual(WizardAction, InteractionTemplate."Wizard Action", InteractionTemplate.FieldCaption("Wizard Action"));
        end;

        asserterror InteractionTemplate.Validate("Wizard Action", WizardAction::Merge);
        Assert.ExpectedErrorCode(DialogTxt);
        Assert.ExpectedError(
          StrSubstNo(CanNotBeSpecifiedErr, InteractionTemplate.FieldCaption("Wizard Action"), WizardAction::Merge, InteractionTemplate.TableCaption(), InteractionTemplate.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWizardActionWithLangCodeWithWordAttachment()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
        SavedWizardAction: Enum "Interaction Template Wizard Action";
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" value can not be validated with "Merge" value for an Interaction Template with Interaction Tmpl. Language with Word attachment
        Initialize();

        InteractionTmplLanguage.SetRange("Attachment No.", FindWordAttachment());
        InteractionTmplLanguage.FindFirst();
        InteractionTemplate.Get(InteractionTmplLanguage."Interaction Template Code");
        SavedWizardAction := InteractionTemplate."Wizard Action";

        for WizardAction := WizardAction::" " to WizardAction::Import do begin
            InteractionTemplate.Validate("Wizard Action", WizardAction);
            Assert.AreEqual(WizardAction, InteractionTemplate."Wizard Action", InteractionTemplate.FieldCaption("Wizard Action"));
        end;

        WizardAction := WizardAction::Merge;
        asserterror InteractionTemplate.Validate("Wizard Action", WizardAction);
        Assert.ExpectedErrorCode(DialogTxt);
        Assert.ExpectedError(
          StrSubstNo(CanNotBeSpecifiedErr, InteractionTemplate.FieldCaption("Wizard Action"), WizardAction, InteractionTemplate.TableCaption(), InteractionTemplate.Code));

        // Tear Down
        InteractionTemplate.Validate("Wizard Action", SavedWizardAction);
        InteractionTemplate.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateWizardActionWithLangCodeWithEmailMergeAttachment()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" value can be only "Merge" for an Interaction Template with Interaction Tmpl. Language with Email Merge attachment
        Initialize();
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateInteractionTmplLangWithEmailMergeAttachment(InteractionTmplLanguage, InteractionTemplate.Code, '');
        Commit();

        InteractionTemplate.Validate("Language Code (Default)", InteractionTmplLanguage."Language Code");
        Assert.AreEqual(WizardAction::Merge, InteractionTemplate."Wizard Action", InteractionTemplate.FieldCaption("Wizard Action"));

        for WizardAction := WizardAction::" " to WizardAction::Import do begin
            asserterror InteractionTemplate.Validate("Wizard Action", WizardAction);
            Assert.ExpectedErrorCode(DialogTxt);
            Assert.ExpectedError(
              StrSubstNo(CanNotBeSpecifiedErr, InteractionTemplate.FieldCaption("Wizard Action"), WizardAction, InteractionTemplate.TableCaption(), InteractionTemplate.Code));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WizardActionIsChangedFromEmptyToMergeAfterValidateEmailMergeAttachment()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
        LanguageCode: array[2] of Code[10];
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" value is changed from "" to "Merge" after validate Interaction Tmpl. Language with Email Merge attachment
        Initialize();
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        LanguageCode[1] :=
          CreateInteractionTmplLangWithoutAttachment(InteractionTmplLanguage, InteractionTemplate.Code);
        LanguageCode[2] :=
          CreateInteractionTmplLangWithEmailMergeAttachment(
            InteractionTmplLanguage, InteractionTemplate.Code, StrSubstNo('<>%1', LanguageCode[1]));

        InteractionTemplate.Validate("Language Code (Default)", LanguageCode[1]);
        InteractionTemplate.Validate("Language Code (Default)", LanguageCode[2]);
        Assert.AreEqual(WizardAction::Merge, InteractionTemplate."Wizard Action", InteractionTemplate.FieldCaption("Wizard Action"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WizardActionIsChangedFromMergeToEmptyAfterValidateLangCodeWithoutAttachment()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
        LanguageCode: array[2] of Code[10];
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" value is changed from "Merge" to "" after validate Interaction Tmpl. Language without attachment
        Initialize();
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        LanguageCode[1] :=
          CreateInteractionTmplLangWithoutAttachment(InteractionTmplLanguage, InteractionTemplate.Code);
        LanguageCode[2] :=
          CreateInteractionTmplLangWithEmailMergeAttachment(
            InteractionTmplLanguage, InteractionTemplate.Code, StrSubstNo('<>%1', LanguageCode[1]));

        InteractionTemplate.Validate("Language Code (Default)", LanguageCode[2]);
        InteractionTemplate.Validate("Language Code (Default)", LanguageCode[1]);
        Assert.AreEqual(WizardAction::" ", InteractionTemplate."Wizard Action", InteractionTemplate.FieldCaption("Wizard Action"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateCustomLayoutFromInterTmplLangPage()
    var
        DummyAttachment: Record Attachment;
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractTmplLanguages: TestPage "Interact. Tmpl. Languages";
    begin
        // [FEATURE] [UT] [UI] [Interaction Template] [Email Merge]
        // [SCENARIO] Email Merge attachment is created when validate "Custom Layout No." field on "Interact. Tmpl. Languages" page
        Initialize();
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);

        InteractTmplLanguages.OpenView();
        InteractTmplLanguages.GotoRecord(InteractionTmplLanguage);
        InteractTmplLanguages.ReportLayoutName.SetValue(LibraryMarketing.FindEmailMergeCustomLayoutName());
        InteractTmplLanguages.Close();

        InteractionTmplLanguage.Find();
        DummyAttachment.SetRange("No.", InteractionTmplLanguage."Attachment No.");
        Assert.RecordIsNotEmpty(DummyAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure RevalidateCustomLayoutFromInterTmplLangPage()
    var
        DummyAttachment: Record Attachment;
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractTmplLanguages: TestPage "Interact. Tmpl. Languages";
        AttachmentNo: array[2] of Integer;
    begin
        // [FEATURE] [UT] [UI] [Interaction Template] [Email Merge]
        // [SCENARIO] Email Merge attachment is created when validate a new "Custom Layout No." field on "Interact. Tmpl. Languages" page
        Initialize();
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);

        InteractTmplLanguages.OpenView();
        InteractTmplLanguages.GotoRecord(InteractionTmplLanguage);

        InteractTmplLanguages.ReportLayoutName.SetValue(LibraryMarketing.FindEmailMergeCustomLayoutName());
        InteractionTmplLanguage.Find();
        AttachmentNo[1] := InteractionTmplLanguage."Attachment No.";

        InteractTmplLanguages.ReportLayoutName.SetValue(LibraryMarketing.FindEmailMergeCustomLayoutName());
        InteractionTmplLanguage.Find();
        AttachmentNo[2] := InteractionTmplLanguage."Attachment No.";

        InteractTmplLanguages.Close();

        DummyAttachment.SetRange("No.", AttachmentNo[1]);
        Assert.RecordIsEmpty(DummyAttachment);

        DummyAttachment.SetRange("No.", AttachmentNo[2]);
        Assert.RecordIsNotEmpty(DummyAttachment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroCustomLayoutFromInterTmplLangPage()
    var
        DummyAttachment: Record Attachment;
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractTmplLanguages: TestPage "Interact. Tmpl. Languages";
        "Count": Integer;
    begin
        // [FEATURE] [UT] [UI] [Interaction Template] [Email Merge]
        // [SCENARIO] Email Merge attachment is deleted after validate "Custom Layout No." = 0 "Interact. Tmpl. Languages" page
        Initialize();
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);
        Count := DummyAttachment.Count();

        InteractTmplLanguages.OpenView();
        InteractTmplLanguages.GotoRecord(InteractionTmplLanguage);
        InteractTmplLanguages.ReportLayoutName.SetValue(LibraryMarketing.FindEmailMergeCustomLayoutName());
        InteractTmplLanguages.ReportLayoutName.SetValue('');
        InteractTmplLanguages.Close();

        InteractionTmplLanguage.Find();
        Assert.AreEqual(0, InteractionTmplLanguage."Attachment No.", InteractionTmplLanguage.FieldCaption("Attachment No."));
        Assert.RecordCount(DummyAttachment, Count);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteInteractionTmplWithEmailMergeAttachment()
    var
        DummyAttachment: Record Attachment;
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
        "Count": Integer;
        i: Integer;
    begin
        // [FEATURE] [UT] [UI] [Interaction Template] [Email Merge]
        // [SCENARIO] Email Merge attachments are removed when delete Interaction Template with several attachments
        Initialize();
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        Count := DummyAttachment.Count();

        for i := 2 to LibraryRandom.RandIntInRange(2, 5) do
            CreateInteractionTmplLangWithEmailMergeAttachment(InteractionTmplLanguage, InteractionTemplate.Code, '');

        InteractionTemplate.Delete(true);

        Assert.RecordCount(DummyAttachment, Count);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteInteractionLogEntryWithAttachment()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Attachment: Record Attachment;
    begin
        // [FEATURE] [UT] [Attachment]
        // [SCENARIO] Attachment is removed when delete "Interaction Log Entry" record with attachment
        Initialize();
        LibraryMarketing.CreateAttachment(Attachment);
        MockInterLogEntryWithAttachment(InteractionLogEntry, Attachment."No.");

        InteractionLogEntry.Delete(true);

        Attachment.SetRecFilter();
        Assert.RecordIsEmpty(Attachment);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteTwoCanceledInteractionLogEntriesWithOneAttachment()
    var
        Attachment: Record Attachment;
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [FEATURE] [Attachment]
        // [SCENARIO 285790] Attachment is removed when delete all canceled Interaction Log Entries
        // [SCENARIO 285790] with one related attachment
        Initialize();
        InteractionLogEntry.ModifyAll(Canceled, false);

        // [GIVEN] Two canceled Interaction Log Entries with one attachment
        LibraryMarketing.CreateAttachment(Attachment);
        MockCanceledInterLogEntryWithAttachment(Attachment."No.");
        MockCanceledInterLogEntryWithAttachment(Attachment."No.");
        // [WHEN] Delete all canceled Interaction Log Entries
        Commit();
        REPORT.Run(REPORT::"Delete Interaction Log Entries", false);
        // [THEN] Attachment is removed
        Attachment.SetRecFilter();
        Assert.RecordIsEmpty(Attachment);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DeleteOneOfTwoCanceledInteractionLogEntriesWithOneAttachment()
    var
        Attachment: Record Attachment;
        InteractionLogEntry: Record "Interaction Log Entry";
        EntryNo: Integer;
    begin
        // [FEATURE] [Attachment]
        // [SCENARIO 285790] Attachment is not removed when delete one of canceled Interaction Log Entries
        // [SCENARIO 285790] with one related attachment
        Initialize();
        InteractionLogEntry.ModifyAll(Canceled, false);

        // [GIVEN] Two canceled Interaction Log Entries with one attachment
        LibraryMarketing.CreateAttachment(Attachment);
        EntryNo := MockCanceledInterLogEntryWithAttachment(Attachment."No.");
        MockCanceledInterLogEntryWithAttachment(Attachment."No.");
        // [WHEN] Delete first of two canceled Interaction Log Entries
        InteractionLogEntry.SetRange("Entry No.", EntryNo);
        Commit();
        REPORT.Run(REPORT::"Delete Interaction Log Entries", false, false, InteractionLogEntry);
        // [THEN] Attachment is not removed
        Attachment.SetRecFilter();
        Assert.RecordIsNotEmpty(Attachment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_IsHTML_Negative_EmptyRecord()
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.IsHTMLAttachment() returns FALSE for empty record
        Initialize();
        TempSegmentLine.LoadSegLineAttachment(false);
        Assert.IsFalse(TempSegmentLine.IsHTMLAttachment(), TempSegmentLine.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_IsHTML_Negative_NotHTMLAttachment()
    var
        TempSegmentLine: Record "Segment Line" temporary;
        Attachment: Record Attachment;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.IsHTMLAttachment() returns FALSE for the record with not a HTML attachment
        Initialize();
        LibraryMarketing.CreateAttachment(Attachment);
        TempSegmentLine."Attachment No." := Attachment."No.";

        TempSegmentLine.LoadSegLineAttachment(false);

        Assert.IsFalse(TempSegmentLine.IsHTMLAttachment(), TempSegmentLine.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_IsHTML_Positive()
    var
        Attachment: Record Attachment;
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment] [Email Merge]
        // [SCENARIO] SegmentLine.IsHTMLAttachment() returns TRUE for the record with Email Merge attachment
        Initialize();
        LibraryMarketing.CreateEmailMergeAttachment(Attachment);
        TempSegmentLine."Attachment No." := Attachment."No.";

        TempSegmentLine.LoadSegLineAttachment(false);

        Assert.IsTrue(TempSegmentLine.IsHTMLAttachment(), TempSegmentLine.TableCaption());

        // Tear Down
        Attachment.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ContentPreviewMPH')]
    [Scope('OnPrem')]
    procedure SegmentLine_PreviewHTMLContent()
    var
        Attachment: Record Attachment;
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment] [Email Merge]
        // [SCENARIO] SegmentLine.PreviewHTMLContent() opens "Content Preview" page for Email Merge attachment
        Initialize();
        LibraryMarketing.CreateEmailMergeAttachment(Attachment);
        TempSegmentLine."Attachment No." := Attachment."No.";
        TempSegmentLine.LoadSegLineAttachment(false);
        TempSegmentLine.PreviewSegLineHTMLContent();

        // Verify "Content Preview" page is opened in ContentPreviewMPH handler

        // Tear Down
        Attachment.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_LoadContentBodyText()
    var
        Attachment: Record Attachment;
        TempSegmentLine: Record "Segment Line" temporary;
        ContentBodyText: Text;
    begin
        // [FEATURE] [UT] [Segment] [Email Merge]
        // [SCENARIO] SegmentLine.LoadContentBodyTextFromCustomLayoutAttachment() returns content text
        Initialize();
        ContentBodyText := LibraryMarketing.CreateEmailMergeAttachment(Attachment);
        TempSegmentLine."Attachment No." := Attachment."No.";
        TempSegmentLine.LoadSegLineAttachment(false);

        Assert.AreEqual(
          ContentBodyText,
          TempSegmentLine.LoadContentBodyTextFromCustomLayoutAttachment(),
          TempSegmentLine.FieldCaption("Attachment No."));

        // Tear Down
        Attachment.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_UpdateContentBodyText()
    var
        Attachment: Record Attachment;
        TempSegmentLine: Record "Segment Line" temporary;
        NewContentBodyText: Text;
    begin
        // [FEATURE] [UT] [Segment] [Email Merge]
        // [SCENARIO] SegmentLine.UpdateContentBodyTextInCustomLayoutAttachment() updates content text
        Initialize();
        LibraryMarketing.CreateEmailMergeAttachment(Attachment);
        NewContentBodyText := LibraryUtility.GenerateRandomAlphabeticText(LibraryRandom.RandIntInRange(2000, 3000), 0);
        TempSegmentLine."Attachment No." := Attachment."No.";
        TempSegmentLine.LoadSegLineAttachment(false);

        TempSegmentLine.UpdateContentBodyTextInCustomLayoutAttachment(NewContentBodyText);

        Assert.AreEqual(
          NewContentBodyText,
          TempSegmentLine.LoadContentBodyTextFromCustomLayoutAttachment(),
          TempSegmentLine.FieldCaption("Attachment No."));

        // Tear Down
        Attachment.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AttachmentNotLoadedWhenItAlreadyExists()
    var
        Attachment: array[2] of Record Attachment;
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment] [Email Merge]
        // [SCENARIO 220243] When using Attachment loading with optimization new attachment is not loaded if attachment already exists

        // [GIVEN] Create Attachment "A1" and load it to Segment Line "SL"
        Initialize();
        CreateSegmentLineWithAttachment(TempSegmentLine, Attachment[1], FirstContentBodyTxt);

        // [GIVEN] Create Attachment "A2"
        LibraryMarketing.CreateEmailMergeAttachment(Attachment[2]);
        TempSegmentLine."Attachment No." := Attachment[2]."No.";

        // [WHEN] Load attachment to "SL" with optimization (check if attachment already exists).
        TempSegmentLine.LoadSegLineAttachment(false);

        // [THEN] Attachment was not loaded ("SL" Attachment = "A1")
        Assert.AreEqual(
          FirstContentBodyTxt,
          TempSegmentLine.LoadContentBodyTextFromCustomLayoutAttachment(),
          TempSegmentLine.FieldCaption("Attachment No."));

        // Tear Down
        Attachment[1].Delete(true);
        Attachment[2].Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AttachmentLoadedWhenLoadWithForceAttachment()
    var
        Attachment: array[2] of Record Attachment;
        TempSegmentLine: Record "Segment Line" temporary;
        ContentBodyText: Text;
    begin
        // [FEATURE] [UT] [Segment] [Email Merge]
        // [SCENARIO 220243] When using Attachment loading with reload forcing new attachment is loaded even if attachment already exists

        // [GIVEN] Create Attachment "A1" and load it to Segment Line "SL"
        Initialize();
        CreateSegmentLineWithAttachment(TempSegmentLine, Attachment[1], FirstContentBodyTxt);

        // [GIVEN] Create Attachment "A2"
        ContentBodyText := LibraryMarketing.CreateEmailMergeAttachment(Attachment[2]);
        TempSegmentLine."Attachment No." := Attachment[2]."No.";

        // [WHEN] Load attachment to "SL" with Reload forcing
        TempSegmentLine.LoadSegLineAttachment(true);

        // [THEN] Attachment was loaded ("SL" Attachment = "A2")
        Assert.AreEqual(
          ContentBodyText,
          TempSegmentLine.LoadContentBodyTextFromCustomLayoutAttachment(),
          TempSegmentLine.FieldCaption("Attachment No."));

        // Tear Down
        Attachment[1].Delete(true);
        Attachment[2].Delete(true);
    end;

    [Test]
    [HandlerFunctions('InteractTmplLanguagesMPH')]
    [Scope('OnPrem')]
    procedure SegmentLine_LanguageCodeOnLookup()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.LanguageCodeOnLookup() opens "Interact. Tmpl. Languages" page
        Initialize();
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateInteractionTmplLangWithEmailMergeAttachment(InteractionTmplLanguage, InteractionTemplate.Code, '');

        MockSegmentLine(TempSegmentLine, InteractionTmplLanguage, '', '', 0D, '');
        TempSegmentLine.LoadSegLineAttachment(false);

        LibraryVariableStorage.Enqueue(TempSegmentLine."Interaction Template Code");
        LibraryVariableStorage.Enqueue(TempSegmentLine."Language Code");
        TempSegmentLine.LanguageCodeOnLookup();

        // Verify "Interact. Tmpl. Languages" page is opened in InteractTmplLanguagesMPH handler

        // Tear Down
        InteractionTemplate.Delete(true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_ConfirmNo()
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(FALSE): asks for confirm action
        Initialize();

        TempSegmentLine.FinishSegLineWizard(false);

        // Verify finish later confirm question in ConfirmHandlerNo handler
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_ConfirmYes_InterTmplIsMandatory()
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(FALSE): "Contact No." field is mandatory for empty Segment Line
        Initialize();

        asserterror TempSegmentLine.FinishSegLineWizard(false);

        // Verify finish later confirm question in ConfirmHandlerNo handler
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(SelectContactErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_ContactIsMandatory()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(TRUE): "Contact No." field is mandatory
        Initialize();
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);

        MockSegmentLine(TempSegmentLine, InteractionTmplLanguage, '', '', 0D, '');

        asserterror TempSegmentLine.FinishSegLineWizard(true);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(SelectContactErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_SalesPersonIsMandatory()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(TRUE): "Salesperson Code" field is mandatory
        Initialize();
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);

        MockSegmentLine(TempSegmentLine, InteractionTmplLanguage, MockContactNo(''), '', 0D, '');

        asserterror TempSegmentLine.FinishSegLineWizard(true);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(FieldEmptyErr, TempSegmentLine.FieldCaption("Salesperson Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_DateIsMandatory()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(TRUE): Date field is mandatory
        Initialize();

        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);
        MockSegmentLine(TempSegmentLine, InteractionTmplLanguage, MockContactNo(''), MockSalesPersonCode(), 0D, '');

        asserterror TempSegmentLine.FinishSegLineWizard(true);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(FieldEmptyErr, TempSegmentLine.FieldCaption(Date)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_DescriptionIsMandatory()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
        ContactCode: Code[20];
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(TRUE): Description field is mandatory
        Initialize();

        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);
        ContactCode := MockContactNo('');
        MockSegmentLine(TempSegmentLine, InteractionTmplLanguage, ContactCode, MockSalesPersonCode(), WorkDate(), '');

        asserterror TempSegmentLine.FinishSegLineWizard(true);
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(FieldEmptyErr, TempSegmentLine.FieldCaption(Description)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLine_FinishWizard_InteractionLogEntry_NotEmail()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [FEATURE] [UT] [Segment]
        // [SCENARIO] SegmentLine.FinishWizard(TRUE): Interaction Log Entry is created in case of not Email Correspondence Type
        Initialize();
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);
        MockSegmentLine(
          TempSegmentLine, InteractionTmplLanguage, MockContactNo(InteractionTmplLanguage."Language Code"),
          MockSalesPersonCode(), WorkDate(), LibraryUtility.GenerateGUID());

        InteractionLogEntry.FindLast();
        TempSegmentLine.FinishSegLineWizard(true);

        VerifyInteractionLogEntryDetails(InteractionLogEntry."Entry No." + 1, TempSegmentLine);
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_VerifyHTMLContentVisibility_MPH')]
    [Scope('OnPrem')]
    procedure CreateInteraction_HTMLContentIsNotVisible_NotEmailMergeTemplate()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Email Merge]
        // [SCENARIO] "Create Interaction" page is opened with not visible HTML content for not Email Merge template
        Initialize();
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage);
        MockFullSegmentLine(TempSegmentLine, InteractionTmplLanguage);

        LibraryVariableStorage.Enqueue(false);
        CreateInteractionFromContact_EmailMerge(TempSegmentLine);

        // Verify html content visibility in CreateInteraction_VerifyHTMLContentVisibility_MPH handler
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_VerifyHTMLContentVisibility_MPH')]
    [Scope('OnPrem')]
    procedure CreateInteraction_HTMLContentIsVisibleFor_EmailMergeTemplate()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Email Merge]
        // [SCENARIO] "Create Interaction" page is opened with visible HTML content for Email Merge template
        Initialize();
        PrepareInteractionTmplLangCodeWithEmailMergeAttachment(InteractionTmplLanguage);
        MockFullSegmentLine(TempSegmentLine, InteractionTmplLanguage);

        LibraryVariableStorage.Enqueue(true);
        CreateInteractionFromContact_EmailMerge(TempSegmentLine);

        // Verify html content visibility in CreateInteraction_VerifyHTMLContentVisibility_MPH handler
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_ValidateLanguageCode_MPH')]
    [Scope('OnPrem')]
    procedure CreateInteraction_HTMLContentIsNotVisible_NotEmailMergeLangTmpl()
    var
        InteractionTmplLanguage: array[2] of Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Email Merge]
        // [SCENARIO] "Create Interaction" page: html content is hide when validate Language Code for not Email Merge template
        Initialize();
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage[1]);
        CreateInteractionTmplLangWithEmailMergeAttachment(
          InteractionTmplLanguage[2], InteractionTmplLanguage[1]."Interaction Template Code",
          StrSubstNo('<>%1', InteractionTmplLanguage[1]."Language Code"));

        MockFullSegmentLine(TempSegmentLine, InteractionTmplLanguage[2]);

        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(InteractionTmplLanguage[1]."Language Code");
        CreateInteractionFromContact_EmailMerge(TempSegmentLine);

        // Verify html content visibility in CreateInteraction_ValidateLanguageCode_MPH handler
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_ValidateLanguageCode_MPH')]
    [Scope('OnPrem')]
    procedure CreateInteraction_HTMLContentIsVisible_EmailMergeLangTmpl()
    var
        InteractionTmplLanguage: array[2] of Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Email Merge]
        // [SCENARIO] "Create Interaction" page: html content is shown when validate Language Code for Email Merge template
        Initialize();
        PrepareInteractionTmplLangCodeWithoutAttachment(InteractionTmplLanguage[1]);
        CreateInteractionTmplLangWithEmailMergeAttachment(
          InteractionTmplLanguage[2], InteractionTmplLanguage[1]."Interaction Template Code",
          StrSubstNo('<>%1', InteractionTmplLanguage[1]."Language Code"));

        MockFullSegmentLine(TempSegmentLine, InteractionTmplLanguage[1]);

        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(InteractionTmplLanguage[2]."Language Code");
        CreateInteractionFromContact_EmailMerge(TempSegmentLine);

        // Verify html content visibility in CreateInteraction_ValidateLanguageCode_MPH handler
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_ValidateHTMLContent_MPH,ContentPreviewMPH')]
    [Scope('OnPrem')]
    procedure CreateInteraction_ValidateAndPreviewHTMLContent()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        // [FEATURE] [UT] [Email Merge]
        // [SCENARIO] "Create Interaction" page: validate and preview html content
        Initialize();
        PrepareInteractionTmplLangCodeWithEmailMergeAttachment(InteractionTmplLanguage);
        MockFullSegmentLine(TempSegmentLine, InteractionTmplLanguage);

        CreateInteractionFromContact_EmailMerge(TempSegmentLine);

        // Validate and preview html content in CreateInteraction_ValidateHTMLContent_MPH
    end;

    [Test]
    [HandlerFunctions('ModalReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LogSegmentWithEmailWordAttachment()
    begin
        LogSegmentWithEmailWordAttachmentInternal();
    end;

    procedure LogSegmentWithEmailWordAttachmentInternal()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        SegmentHeader: Record "Segment Header";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        Segment: TestPage Segment;
        FileExtension: Text[250];
        ExpectedCount: Integer;
    begin
        // [SCENARIO 178203] User sends email with Word document as attachment in Web client
        Initialize();
        LibraryEmail.SetUpEmailAccount();
        ExpectedCount := InteractionLogEntry.Count() + 1;
        Clear(InteractionLogEntry);

        // [GIVEN] Interaction Template with Word attachment
        FileExtension := 'DOC';

        // [GIVEN] Segment for email
        PrepareSegmentForEmail(SegmentHeader, FileExtension);

        // [GIVEN] Emulate Web client
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);

        // [WHEN] Log Segment
        Segment.OpenView();
        Segment.GotoRecord(SegmentHeader);
        Segment.LogSegment.Invoke();

        // [THEN] Verify that a new log entry was added.
        InteractionLogEntry.FindLast();
        Assert.AreEqual(ExpectedCount, InteractionLogEntry.Count(), 'One new interaction log entry should have been added.');
        ClearVariables(SegmentHeader);
    end;

    [Test]
    [HandlerFunctions('ModalReportHandler,MessageHandler,EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure LogSegmentWithEmailTextAttachment()
    begin
        LogSegmentWithEmailTextAttachmentInternal();
    end;

    procedure LogSegmentWithEmailTextAttachmentInternal()
    var
        SegmentHeader: Record "Segment Header";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
        Segment: TestPage Segment;
        FileExtension: Text[250];
    begin
        // [SCENARIO 178203] User sends email with text document as attachment in Web client
        Initialize();
        LibraryEmail.SetUpEmailAccount();
        // [GIVEN] Interaction Template with text attachment
        FileExtension := 'TXT';
        // [GIVEN] Segment for email
        PrepareSegmentForEmail(SegmentHeader, FileExtension);
        // [GIVEN] Emulate Web client
        BindSubscription(TestClientTypeSubscriber);
        TestClientTypeSubscriber.SetClientType(CLIENTTYPE::Web);
        // [WHEN] Log Segment
        Segment.OpenView();
        Segment.GotoRecord(SegmentHeader);
        Segment.LogSegment.Invoke();
        // [THEN] Email dialog launched (verification in handler)
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_Cancel_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure InteractionLogEntry_ResumeInteraction_LongFilters()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252197] TAB 5065 "Interaction Log Entry".ResumeInteraction() in case of long field filters
        // [SCENARIO 255837]
        Initialize();

        // [GIVEN] Interaction Log Entry with "Salesperson Code" = "A" (and applied field filter =  "A"), where "A" - 20-char length value
        // [WHEN] Perform "Interaction Log Entry".ResumeInteraction()
        // [THEN] Page 5077 "Create Interaction" is opened with "Salesperson Code" = "A" (and applied field filter =  "A")
        // Cancel "Create Interaction" (CreateInteraction_Cancel_MPH) and decline save (ConfirmHandlerNo)
        MockInterLogEntryWithRandomDetails(InteractionLogEntry);
        InteractionLogEntry.SetFilter("To-do No.", InteractionLogEntry."To-do No." + '|' + InteractionLogEntry."To-do No.");
        InteractionLogEntry.SetFilter("Contact Company No.", InteractionLogEntry."Contact Company No." + '|' + InteractionLogEntry."Contact Company No.");
        InteractionLogEntry.SetFilter("Contact No.", InteractionLogEntry."Contact No." + '|' + InteractionLogEntry."Contact No.");
        InteractionLogEntry.SetFilter("Salesperson Code", InteractionLogEntry."Salesperson Code" + '|' + InteractionLogEntry."Salesperson Code");
        InteractionLogEntry.SetFilter("Campaign No.", InteractionLogEntry."Campaign No." + '|' + InteractionLogEntry."Campaign No.");
        InteractionLogEntry.SetFilter("Opportunity No.", InteractionLogEntry."Opportunity No." + '|' + InteractionLogEntry."Opportunity No.");

        InteractionLogEntry.ResumeInteraction();

        InteractionLogEntry.Find();
        VerifyFilterValuesAfterResumeInteraction(
          InteractionLogEntry."To-do No.", InteractionLogEntry."Contact Company No.", InteractionLogEntry."Contact No.", InteractionLogEntry."Salesperson Code", InteractionLogEntry."Campaign No.", InteractionLogEntry."Opportunity No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_Cancel_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure InteractionLogEntry_ResumeInteraction_BlankedFilters()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252197] TAB 5065 "Interaction Log Entry".ResumeInteraction() in case of blanked field filters
        // [SCENARIO 255837]
        Initialize();

        // [GIVEN] Interaction Log Entry with "Salesperson Code" = "A" (and no applied field filter)
        // [WHEN] Perform "Interaction Log Entry".ResumeInteraction()
        // [THEN] Page 5077 "Create Interaction" is opened with "Salesperson Code" = "A" (and applied field filter =  "A")
        // Cancel "Create Interaction" (CreateInteraction_Cancel_MPH) and decline save (ConfirmHandlerNo)
        MockInterLogEntryWithRandomDetails(InteractionLogEntry);
        InteractionLogEntry.ResumeInteraction();

        InteractionLogEntry.Find();
        VerifyFilterValuesAfterResumeInteraction(
          InteractionLogEntry."To-do No.", InteractionLogEntry."Contact Company No.", InteractionLogEntry."Contact No.", InteractionLogEntry."Salesperson Code", InteractionLogEntry."Campaign No.", InteractionLogEntry."Opportunity No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_Cancel_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure InteractionLogEntry_ResumeInteraction_BlankedValues()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252197] TAB 5065 "Interaction Log Entry".ResumeInteraction() in case of blanked field values
        // [SCENARIO 255837]
        Initialize();
        // [GIVEN] Interaction Log Entry with "Salesperson Code" = ""
        // [WHEN] Perform "Interaction Log Entry".ResumeInteraction()
        // [THEN] Page 5077 "Create Interaction" is opened with "Salesperson Code" = "" (and no applied field filter)
        // Cancel "Create Interaction" (CreateInteraction_Cancel_MPH) and decline save (ConfirmHandlerNo)
        InteractionLogEntry.Init();
        InteractionLogEntry.ResumeInteraction();
        VerifyFilterValuesAfterResumeInteraction('', '', '', '', '', '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_Cancel_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure InteractionLogEntry_ResumeInteraction_FiltersOrderAB()
    var
        InteractionLogEntry: array[2] of Record "Interaction Log Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252197] TAB 5065 "Interaction Log Entry".ResumeInteraction() in case of "Salesperson Code" = "A", filter "A|B" and two records
        // [SCENARIO 255837]
        Initialize();

        // [GIVEN] Interaction Log Entry "X" with "Salesperson Code" = "A"
        // [GIVEN] Interaction Log Entry "Y" with "Salesperson Code" = "B"
        // [GIVEN] Select Interaction Log Entry "X", apply "Salesperson Code" filter "A|B"
        // [WHEN] Perform "Interaction Log Entry".ResumeInteraction()
        // [THEN] Page 5077 "Create Interaction" is opened with "Salesperson Code" = "A" (and applied field filter =  "A")
        // Cancel "Create Interaction" (CreateInteraction_Cancel_MPH) and decline save (ConfirmHandlerNo)
        MockInterLogEntryWithGivenSalesPersonCode(InteractionLogEntry[1], LibraryUtility.GenerateGUID());
        MockInterLogEntryWithGivenSalesPersonCode(InteractionLogEntry[2], LibraryUtility.GenerateGUID());
        InteractionLogEntry[1].SetFilter("Salesperson Code", InteractionLogEntry[1]."Salesperson Code" + '|' + InteractionLogEntry[2]."Salesperson Code");

        InteractionLogEntry[1].ResumeInteraction();

        InteractionLogEntry[1].Find();
        VerifyFilterValuesAfterResumeInteraction('', '', '', InteractionLogEntry[1]."Salesperson Code", '', '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CreateInteraction_Cancel_MPH,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure InteractionLogEntry_ResumeInteraction_FiltersOrderBA()
    var
        InteractionLogEntry: array[2] of Record "Interaction Log Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252197] TAB 5065 "Interaction Log Entry".ResumeInteraction() in case of "Salesperson Code" "B", filter "A|B" and two records
        // [SCENARIO 255837]
        Initialize();

        // [GIVEN] Interaction Log Entry "X" with "Salesperson Code" = "A"
        // [GIVEN] Interaction Log Entry "Y" with "Salesperson Code" = "B"
        // [GIVEN] Select Interaction Log Entry "Y", apply "Salesperson Code" filter "A|B"
        // [WHEN] Perform "Interaction Log Entry".ResumeInteraction()
        // [THEN] Page 5077 "Create Interaction" is opened with "Salesperson Code" = "B" (and applied field filter =  "B")
        // Cancel "Create Interaction" (CreateInteraction_Cancel_MPH) and decline save (ConfirmHandlerNo)
        MockInterLogEntryWithGivenSalesPersonCode(InteractionLogEntry[1], LibraryUtility.GenerateGUID());
        MockInterLogEntryWithGivenSalesPersonCode(InteractionLogEntry[2], LibraryUtility.GenerateGUID());
        InteractionLogEntry[2].SetFilter("Salesperson Code", InteractionLogEntry[1]."Salesperson Code" + '|' + InteractionLogEntry[2]."Salesperson Code");

        InteractionLogEntry[2].ResumeInteraction();

        InteractionLogEntry[2].Find();
        VerifyFilterValuesAfterResumeInteraction('', '', '', InteractionLogEntry[2]."Salesperson Code", '', '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LogDocumentNoEmail()
    var
        SalesHeader: Record "Sales Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        SegManagement: Codeunit SegManagement;
    begin
        // [SCENARIO] Create a sales invoice for a customer that has a contact with correspondence type email but no email address
        Initialize();
        // [GIVEN] Marketing setup with default correspondence type of email
        SetDefaultCorrespondenceType(InteractionLogEntry."Correspondence Type"::Email);
        // [GIVEN] A Sales Invoice to a customer with a contact without email
        CreateSalesInvoiceForCustomerWithContact(SalesHeader);

        // [WHEN] A document creation is logged
        SegManagement.LogDocument("Interaction Log Entry Document Type"::"Sales Inv.".AsInteger(), SalesHeader."No.", 0, 0, DATABASE::Contact,
          SalesHeader."Bill-to Contact No.", SalesHeader."Salesperson Code", SalesHeader."Campaign No.",
          SalesHeader."Posting Description", '');

        // [THEN] The correspondence is logged with blank correspondence type
        VerifyBlankCorrespondenceTypeOnInteractionLogEntryForContact(SalesHeader."Bill-to Contact No.", SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderShowInteractionLogEntriesSuiteAppArea()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        InteractionLogEntries: TestPage "Interaction Log Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199812] Action "Interaction log entries" on sales order page opens list of related interaciton log entries if #Suite app area enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Create sales order XXX
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Mock interaction log entry related to created sales order XXX
        MockInterLogEntryRelatedToSalesDocument(SalesHeader);

        // [WHEN] Action "Interaction log entries" is being pushed on sales order card page
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        InteractionLogEntries.Trap();
        SalesOrder.PageInteractionLogEntries.Invoke();

        // [THEN] Opened Interaction log entries page contains entry related to order XXX
        VerifyInterLogEntry(
          InteractionLogEntries."Entry No.".AsInteger(), SalesHeader."No.", GetInterLogEntryDocTypeFromSalesDoc(SalesHeader));

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderShowInteractionLogEntriesBasicAppArea()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199812] Action "Interaction log entries" is not available on sales order page if only #Basic app area enabled
        Initialize();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] Create sales order XXX
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Order card page is being opened
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [THEN] Action "Interaction log entries" is hidden
        asserterror SalesOrder.PageInteractionLogEntries.Invoke();
        Assert.ExpectedError(IsNotFoundOnPageErr);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteShowInteractionLogEntriesSuiteAppArea()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
        InteractionLogEntries: TestPage "Interaction Log Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199812] Action "Interaction log entries" on sales quote page opens list of related interaciton log entries if #Suite app area enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Create sales quote XXX
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        // [GIVEN] Mock interaction log entry related to created sales quote XXX
        MockInterLogEntryRelatedToSalesDocument(SalesHeader);

        // [WHEN] Action "Interaction log entries" is being pushed on sales quote card page
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        InteractionLogEntries.Trap();
        SalesQuote.PageInteractionLogEntries.Invoke();

        // [THEN] Opened Interaction log entries page contains entry related to quote XXX
        InteractionLogEntries.First();
        VerifyInterLogEntry(
          InteractionLogEntries."Entry No.".AsInteger(), SalesHeader."No.", GetInterLogEntryDocTypeFromSalesDoc(SalesHeader));

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteShowInteractionLogEntriesBasicAppArea()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199812] Action "Interaction log entries" is not available on sales quote page if only #Basic app area enabled
        Initialize();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] Create sales quote XXX
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        // [WHEN] quote card page is being opened
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [THEN] Action "Interaction log entries" is hidden
        asserterror SalesQuote.PageInteractionLogEntries.Invoke();
        Assert.ExpectedError(IsNotFoundOnPageErr);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CommentsFromInteractionLogEntriesPageForSuitUserExperience()
    var
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionLogEntries: TestPage "Interaction Log Entries";
        InterLogEntryCommentSheet: TestPage "Inter. Log Entry Comment Sheet";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199903] User is able to add comments for interaction log entry when user experience is Suite
        Initialize();

        // [GIVEN] User experience set to Suite
        LibraryApplicationArea.EnableRelationshipMgtSetup();

        // [GIVEN] Mock interaction log entry XXX
        MockInterLogEntry(InteractionLogEntry);

        // [GIVEN] Create comment YYY for interaction log entry XXX
        CreateInteractionLogEntryComment(InterLogEntryCommentLine, InteractionLogEntry."Entry No.");

        // [GIVEN] Open page Interaction Log Entries with entry XXX
        InteractionLogEntries.OpenView();
        InteractionLogEntries.GotoRecord(InteractionLogEntry);

        // [WHEN] Action Comments is being hit
        InterLogEntryCommentSheet.Trap();
        InteractionLogEntries."Co&mments".Invoke();

        // [THEN] Comment YYY is displayed in the opened Inter. Log Entry Comment Sheet
        InterLogEntryCommentSheet.Date.AssertEquals(InterLogEntryCommentLine.Date);
        InterLogEntryCommentSheet.Comment.AssertEquals(InterLogEntryCommentLine.Comment);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IntLogCommentCopiedToCreatedOpportunity()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
    begin
        // [SCENARIO 202036] Creating opportunity from interaction log copies comments to opportunity
        Initialize();

        // [GIVEN] Mock interaction log entry XXX
        MockInterLogEntry(InteractionLogEntry);

        // [GIVEN] Create comment YYY for interaction log entry XXX
        CreateInteractionLogEntryComment(InterLogEntryCommentLine, InteractionLogEntry."Entry No.");

        // [WHEN] Opportunity is being created from interaction log entry
        InteractionLogEntry.AssignNewOpportunity();

        // [THEN] Comment YYY is copied to opportunity's comment
        FindOpportunityCommentLine(InteractionLogEntry."Opportunity No.", RlshpMgtCommentLine);
        VerifyOpporunityCommentLine(InterLogEntryCommentLine, RlshpMgtCommentLine);
    end;

    [Test]
    [HandlerFunctions('MakePhoneCall_MPH,InterLogEntryCommentSheet_MPH,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CommentsForMakePhoneCallPage()
    var
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
        ContactList: TestPage "Contact List";
        CommentDate: Date;
        CommentText: Text;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 202034] Comments entered from Make Phone Call page saved into interaction log entries comments
        Initialize();

        // [GIVEN] User experience set to Suite
        LibraryApplicationArea.EnableRelationshipMgtSetup();

        // [GIVEN] Create contact XXX wiht phone number
        CreateContactWithPhoneNo(Contact);

        // [GIVEN] Open contact card with contact XXX
        ContactList.OpenView();
        ContactList.GotoRecord(Contact);

        // [GIVEN] Run Make Phone Call action
        // [GIVEN] Run Comments action
        // [WHEN] Comment YYY is being entered, comments page is being closed, and Phone call completed
        CommentDate := LibraryUtility.GenerateRandomDate(WorkDate(), CalcDate('<1Y>', WorkDate()));
        CommentText :=
          LibraryUtility.GenerateRandomCode(
            InterLogEntryCommentLine.FieldNo(Comment),
            DATABASE::"Inter. Log Entry Comment Line");
        LibraryVariableStorage.Enqueue(CommentDate);
        LibraryVariableStorage.Enqueue(CommentText);
        ContactList.MakePhoneCall.Invoke();

        // [THEN] Comment YYY saved into interacton log entry comments
        FindContactInteractionLogEntry(InteractionLogEntry, Contact."No.");
        FindIntLogEntryCommentLine(InteractionLogEntry."Entry No.", InterLogEntryCommentLine);
        InterLogEntryCommentLine.TestField(Date, CommentDate);
        InterLogEntryCommentLine.TestField(Comment, CommentText);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('SimpleEmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure EmailDraftInteractionLogEntryFromSalesOrder()
    begin
        PopulateCompanyInformation();
        ResetReportSelection();

        EmailDraftInteractionLogEntryFromSalesOrderInternal();
    end;

    procedure EmailDraftInteractionLogEntryFromSalesOrderInternal()
    var
        InteractionTemplate: Record "Interaction Template";
        SalesHeader: Record "Sales Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        DocumentPrint: Codeunit "Document-Print";
    begin
        // [SCENARIO 199993] Sending by mail sales order confirmation does not lead to generation of interaction log entry with Email Draft template
        Initialize();
        LibraryEmail.SetUpEmailAccount();

        // [GIVEN] New interaction template XXX
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        // [GIVEN] Set template XXX as Email Draft in the Intraction Template Setup
        SetEmailDraftInteractionTemplate(InteractionTemplate.Code);
        // [GIVEN] New Sales order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Sales order confirmation is being sent by email
        DocumentPrint.EmailSalesHeader(SalesHeader);

        // [THEN] Interaction log entry created created once
        FindInteractionLogEntryByDocument(
          InteractionLogEntry, SalesHeader."No.", InteractionLogEntry."Document Type"::"Sales Ord. Cnfrmn.");
        Assert.RecordCount(InteractionLogEntry, 1);
        // [THEN] Interaction log entry "Interaction Template Code" is not equal to "XXX"
        Assert.AreNotEqual(InteractionTemplate.Code, InteractionLogEntry."Interaction Template Code", '')
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsModalPageHandler,SimpleEmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure EmailDraftInteractionLogEntryFromPurchOrder()
    begin
        EmailDraftInteractionLogEntryFromPurchOrderInternal();
    end;

    procedure EmailDraftInteractionLogEntryFromPurchOrderInternal()
    var
        InteractionTemplate: Record "Interaction Template";
        PurchaseHeader: Record "Purchase Header";
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // [SCENARIO 199993] Sending by mail Purchase order does not lead to generation of interaction log entry with Email Draft template
        Initialize();
        LibraryEmail.SetUpEmailAccount();

        // [GIVEN] New interaction template XXX
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        // [GIVEN] Set template XXX as Email Draft in the Intraction Template Setup
        SetEmailDraftInteractionTemplate(InteractionTemplate.Code);
        // [GIVEN] New Purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [WHEN] Purchase order confirmation is being sent by email
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.SendRecords();

        // [THEN] Interaction log entry created once
        FindInteractionLogEntryByDocument(
          InteractionLogEntry, PurchaseHeader."No.", InteractionLogEntry."Document Type"::"Purch. Ord.");
        Assert.RecordCount(InteractionLogEntry, 1);
        // [THEN] Interaction log entry "Interaction Template Code" is not equal to "XXX"
        Assert.AreNotEqual(InteractionTemplate.Code, InteractionLogEntry."Interaction Template Code", '')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmailDraftEnabledForSuitUserExperience()
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionTemplateSetupPage: TestPage "Interaction Template Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 199993] Email Draft Template field enabled on the page Interaction Template Setup with Suit user experience
        Initialize();

        // [GIVEN] User experience set to Suite
        LibraryApplicationArea.EnableRelationshipMgtSetup();

        // [GIVEN] New interaction template XXX
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        // [GIVEN] Set template XXX as Email Draft in the Intraction Template Setup
        SetEmailDraftInteractionTemplate(InteractionTemplate.Code);

        // [WHEN] Interaction Template Setup is being opened
        InteractionTemplateSetupPage.OpenEdit();

        // [THEN] Field Email Draft has value XXX
        InteractionTemplateSetupPage."E-Mail Draft".AssertEquals(InteractionTemplate.Code);

        // TearDown
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportInteractionTemplates()
    var
        MarketingSetup: Record "Marketing Setup";
        InteractionGroup: Record "Interaction Group";
        InteractionTemplate: Record "Interaction Template";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        NameValueBuffer: Record "Name/Value Buffer";
        MarketingInteraction: Codeunit "Marketing Interaction";
        FilePath: Text;
        ExportFilePath: Text;
    begin
        // [SCENARIO 323680] Attachment file path is valid when export Interaction Template.
        Initialize();

        // [GIVEN] Marketing Setup stores attachments on disk.
        MarketingSetup.Validate("Attachment Storage Type", MarketingSetup."Attachment Storage Type"::"Disk File");
        MarketingSetup.Validate("Attachment Storage Location", DelChr(TemporaryPath, '>', '\'));
        MarketingSetup.Modify(true);

        // [GIVEN] Interaction Template with *.docx file attachment.
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate.Validate("Interaction Group Code", InteractionGroup.Code);
        InteractionTemplate.Validate("Wizard Action", InteractionTemplate."Wizard Action"::Open);
        InteractionTemplate.Modify(true);
        CreateInteractionTmplLanguage(InteractionTmplLanguage, InteractionTemplate.Code, FindLanguageCode(''), '');
        InteractionTmplLanguage.Validate("Attachment No.", CreateAttachmentWithFileValue('docx'));
        InteractionTmplLanguage.Modify();
        FilePath := GetAttachmentFilePath(InteractionTmplLanguage."Attachment No.");

        // [WHEN] Invoke export attachment from Interaction Tmpl. Language.
        BindSubscription(MarketingInteraction);
        InteractionTmplLanguage.ExportAttachment();
        NameValueBuffer.Get(SessionId());
        ExportFilePath := NameValueBuffer.Value;
        UnbindSubscription(MarketingInteraction);

        // [THEN] The path of exported file is equal to path stored in attachment of Interaction Tmpl. Language.
        Assert.AreEqual(FilePath, ExportFilePath, FilePathsAreNotEqualErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InboundFlowEntryTitle()
    var
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 390586] Contact Interaction Subform shows title for Inbound interaction template
        Initialize();

        // [GIVEN] Interaction Template "X" with "Information Flow" = Inbound and Description "TD"
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate."Information Flow" := InteractionTemplate."Information Flow"::Inbound;
        InteractionTemplate.Modify();

        // [GIVEN] Contact with Name = "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Mock interaction log entry for contact "C" and template "X"
        MockInterLogEntry(InteractionLogEntry);
        InteractionLogEntry."Contact No." := Contact."No.";
        InteractionLogEntry."Contact Company No." := Contact."Company No.";
        InteractionLogEntry."Interaction Template Code" := InteractionTemplate.Code;
        InteractionLogEntry.Modify();

        // [WHEN] GetEntryTitle function run for interaction entry
        // [THEN] Contact Interaction Subform shows "Title" = "TD - from C"
        Assert.AreEqual(StrSubstNo(TitleFromLbl, InteractionTemplate.Description, Contact.Name), InteractionLogEntry.GetEntryTitle(), 'Invalid Title');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutboundFlowEntryTitle()
    var
        Contact: Record Contact;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 390586] Contact Interaction Subform shows title for Outbound interaction template
        Initialize();

        // [GIVEN] Interaction Template "X" with "Information Flow" = Outbound and Description "TD"
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate."Information Flow" := InteractionTemplate."Information Flow"::Outbound;
        InteractionTemplate.Modify();

        // [GIVEN] Salespersone with Name = "S"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] Contact with Name = "C" and salespersone "S"
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact."Salesperson Code" := SalespersonPurchaser.Code;
        Contact.Modify();

        // [GIVEN] Mock interaction log entry for contact "C" and template "X"
        MockInterLogEntry(InteractionLogEntry);
        InteractionLogEntry."Contact No." := Contact."No.";
        InteractionLogEntry."Contact Company No." := Contact."Company No.";
        InteractionLogEntry."Salesperson Code" := SalespersonPurchaser.Code;
        InteractionLogEntry."Interaction Template Code" := InteractionTemplate.Code;
        InteractionLogEntry.Modify();

        // [WHEN] GetEntryTitle function run for interaction entry
        // [THEN] Contact Interaction Subform shows "Title" = "TD - by S"
        Assert.AreEqual(StrSubstNo(TitleByLbl, InteractionTemplate.Description, SalespersonPurchaser.Name), InteractionLogEntry.GetEntryTitle(), 'Invalid Title');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyFlowEntryTitle()
    var
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 390586] Contact Interaction Subform shows title for Empty flow interaction template
        Initialize();

        // [GIVEN] Interaction Template "X" with "Information Flow" = " " and Description "TD"
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate."Information Flow" := InteractionTemplate."Information Flow"::" ";
        InteractionTemplate.Modify();

        // [GIVEN] Contact with Name = "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Mock interaction log entry for contact "C" and template "X"
        MockInterLogEntry(InteractionLogEntry);
        InteractionLogEntry."Contact No." := Contact."No.";
        InteractionLogEntry."Contact Company No." := Contact."Company No.";
        InteractionLogEntry."Interaction Template Code" := InteractionTemplate.Code;
        InteractionLogEntry.Modify();

        // [WHEN] GetEntryTitle function run for interaction entry
        // [THEN] Contact Interaction Subform shows "Title" = "TD"
        Assert.AreEqual(InteractionTemplate.Description, InteractionLogEntry.GetEntryTitle(), 'Invalid Title');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateOpportunityForInteractionLogEntry()
    var
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [UI] [Contact Interaction Subform]
        // [SCENARIO 386492] Action "Create Opportunity" of Contact Interaction Subform
        Initialize();

        // [GIVEN] Contact "C"
        LibraryMarketing.CreatePersonContact(Contact);
        // [GIVEN] Interaction Log Entry, where "Opportunity No." is <blank>
        InteractionLogEntry.DeleteAll();
        InteractionLogEntry.Init();
        InteractionLogEntry."Contact No." := Contact."No.";
        InteractionLogEntry."Salesperson Code" := Contact."Salesperson Code";
        InteractionLogEntry.Insert();

        // [GIVEN] Open contact card for Contact "C"
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");

        // [WHEN] Run "Create opportunity" from Contact Interaction Subform
        ContactCard.ContactIntEntriesSubform.CreateOpportunity.Invoke();

        // [THEN] Interaction Log Entry, where "Opportunity No." is defined
        InteractionLogEntry.Find();
        InteractionLogEntry.TestField("Opportunity No.");
        // [THEN] New opportunity is created
        VerifyOpportunity(Contact, InteractionLogEntry."Opportunity No.");
    end;

    [Test]
    [HandlerFunctions('ContentPreviewMPH')]
    [Scope('OnPrem')]
    procedure ContactInteractionSubformShowAttachments()
    var
        Contact: Record Contact;
        Attachment: Record Attachment;
        InteractionLogEntry: Record "Interaction Log Entry";
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [UI] [Contact Interaction Subform]
        // [SCENARIO 386492] Action "Show Attachments" of Contact Interaction Subform opens entry attachment
        Initialize();

        // [GIVEN] Contact "C"
        LibraryMarketing.CreatePersonContact(Contact);
        // [GIVEN] Mock Interaction Log Entry with Attachment
        LibraryMarketing.CreateEmailMergeAttachment(Attachment);
        InteractionLogEntry.DeleteAll();
        InteractionLogEntry.Init();
        InteractionLogEntry."Contact No." := Contact."No.";
        InteractionLogEntry."Salesperson Code" := Contact."Salesperson Code";
        InteractionLogEntry."Attachment No." := Attachment."No.";
        InteractionLogEntry.Insert();

        // [GIVEN] Open contact card for Contact "C"
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");

        // [WHEN] Run "Show Attachments" from Contact Interaction Subform
        ContactCard.ContactIntEntriesSubform."Show Attachments".Invoke();

        // [THEN] "Content Preview" page opened

        Attachment.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactInteractionSubformShowDocument()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        SalesOrderCard: TestPage "Sales Order";
        SegMgt: Codeunit SegManagement;
    begin
        // [FEATURE] [UI] [Contact Interaction Subform]
        // [SCENARIO 386492] Action "Show Attachments" of Contact Interaction Subform opens related document
        Initialize();

        // [GIVEN] Customer "CUST" with Contact "C"
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Sales order "SO" with customer "S"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Mock interaction log entry for sales order "SO"
        SegMgt.LogDocument(3, SalesHeader."No.", 0, 0, Database::Customer, SalesHeader."Bill-to Customer No.", SalesHeader."Salesperson Code",
                        '', SalesHeader."Posting Description", '');

        // [GIVEN] Open contact card for Contact "C"
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");

        // [WHEN] Run "Show Attachments" from Contact Interaction Subform
        SalesOrderCard.Trap();
        ContactCard.ContactIntEntriesSubform."Show Attachments".Invoke();

        // [THEN] "Sales Order Card" page opened with sales order "SO"
        SalesOrderCard."No.".AssertEquals(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ContactInteractionSubformShowDocumentFromTitle()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
        SalesOrderCard: TestPage "Sales Order";
        SegMgt: Codeunit SegManagement;
    begin
        // [FEATURE] [UI] [Contact Interaction Subform]
        // [SCENARIO 386492] AssistEdit for "Title" field of Contact Interaction Subform opens related document
        Initialize();

        // [GIVEN] Customer "CUST" with Contact "C"
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Sales order "SO" with customer "S"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Mock interaction log entry for sales order "SO"
        SegMgt.LogDocument(3, SalesHeader."No.", 0, 0, Database::Customer, SalesHeader."Bill-to Customer No.", SalesHeader."Salesperson Code",
                        '', SalesHeader."Posting Description", '');

        // [GIVEN] Open contact card for Contact "C"
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");

        // [WHEN] Run AssistEdit for "Title" field from Contact Interaction Subform
        SalesOrderCard.Trap();
        ContactCard.ContactIntEntriesSubform.Title.AssistEdit();

        // [THEN] "Sales Order Card" page opened with sales order "SO"
        SalesOrderCard."No.".AssertEquals(SalesHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('EvaluateInteractionHandler')]
    procedure ContactInteractionSubformEvaluateInteraction()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [UI] [Contact Interaction Subform]
        // [SCENARIO 386492] Action "Evaluate Interaction" of Contact Interaction Subform
        Initialize();

        // [GIVEN] Contact "C"
        LibraryMarketing.CreatePersonContact(Contact);
        // [GIVEN] Interaction Log Entry
        InteractionLogEntry.DeleteAll();
        InteractionLogEntry.Init();
        InteractionLogEntry."Contact No." := Contact."No.";
        InteractionLogEntry."Salesperson Code" := Contact."Salesperson Code";
        InteractionLogEntry.Insert();

        // [GIVEN] Open contact card for Contact "C"
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");

        // [WHEN] Run "Evaluate Interaction" action from Contact Interaction Subform and press "Positive"
        LibraryVariableStorage.Enqueue(2);
        ContactCard.ContactIntEntriesSubform."Evaluate Interaction".Invoke();

        // [THEN] Interaction log entry has "Evaluation" = "Positive"
        InteractionLogEntry.Find();
        InteractionLogEntry.TestField(Evaluation, InteractionLogEntry.Evaluation::Positive);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandler')]
    procedure ContactInteractionSubformToggleCanceled()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [UI] [Contact Interaction Subform]
        // [SCENARIO 386492] Action "Switch Checkmark in Canceled" of Contact Interaction Subform
        Initialize();

        // [GIVEN] Contact "C"
        LibraryMarketing.CreatePersonContact(Contact);
        // [GIVEN] Interaction Log Entry
        InteractionLogEntry.DeleteAll();
        InteractionLogEntry.Init();
        InteractionLogEntry."Contact No." := Contact."No.";
        InteractionLogEntry."Salesperson Code" := Contact."Salesperson Code";
        InteractionLogEntry.Insert();

        // [GIVEN] Open contact card for Contact "C"
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");

        // [WHEN] Run action "Switch Checkmark in Canceled" from Contact Interaction Subform and press "Positive"
        ContactCard.ContactIntEntriesSubform."Switch Check&mark in Canceled".Invoke();

        // [THEN] Interaction log entry has "Canceled" = "Yes"
        InteractionLogEntry.Find();
        InteractionLogEntry.TestField(Canceled, true);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CreateInteraction_GetContactName_MPH,ConfirmHandlerNo')]
    procedure ContactInteractionSubformCreateInteractionPersonContact()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [UI] [Contact Interaction Subform]
        // [SCENARIO 390586] Action "Create Interaction" of Contact Interaction Subform for person contact
        Initialize();

        // [GIVEN] Contact "C"
        LibraryMarketing.CreatePersonContact(Contact);

        // [GIVEN] Open contact card for Contact "C"
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");

        // [WHEN] Run action "Create Interaction" from Contact Interaction Subform and press "Positive"
        ContactCard.ContactIntEntriesSubform."Create &Interaction".Invoke();

        // [THEN] Create Interaction Wizard has "Contact Name" = "C"
        Assert.AreEqual(Contact.Name, LibraryVariableStorage.DequeueText(), 'Invalid contact name');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CreateInteraction_GetContactName_MPH,ConfirmHandlerNo')]
    procedure ContactInteractionSubformCreateInteractionCompanyContact()
    var
        Contact: Record Contact;
        ContactCard: TestPage "Contact Card";
    begin
        // [FEATURE] [UI] [Contact Interaction Subform]
        // [SCENARIO 390586] Action "Create Interaction" of Contact Interaction Subform for company contact
        Initialize();

        // [GIVEN] Contact "C"
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Open contact card for Contact "C"
        ContactCard.OpenEdit();
        ContactCard.Filter.SetFilter("No.", Contact."No.");

        // [WHEN] Run action "Create Interaction" from Contact Interaction Subform and press "Positive"
        ContactCard.ContactIntEntriesSubform."Create &Interaction".Invoke();

        // [THEN] Create Interaction Wizard has "Contact Name" = "C"
        Assert.AreEqual(Contact.Name, LibraryVariableStorage.DequeueText(), 'Invalid contact name');
    end;

    [Test]
    [HandlerFunctions('WordTemplateCreationWizardHandler')]
    procedure InteractionCreateInteractionWordTemplateAction()
    var
        InteractionTemplates: TestPage "Interaction Templates";
    begin
        // [SCENARIO] Action "Create Interaction Word Template" creates a Word template with correct tables.
        Initialize();

        // [WHEN] Run action
        InteractionTemplates.OpenEdit();
        InteractionTemplates.WordTemplate.Invoke();

        // [THEN] Handler function verifies that related tables are set in Wizard.
    end;

    [Test]
    procedure InteractionEditAttachmentWhenWordTemplateUsedError()
    var
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        InteractionTemplates: TestPage "Interaction Templates";
    begin
        // [SCENARIO] When editing the attachment, if a Word template is specified, an error is thrown.
        Initialize();

        // [GIVEN] Create a Contact.
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Create Interaction Template with Word Template code
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate."Word Template Code" := 'CODE';
        InteractionTemplate.Modify();
        Commit();

        // [WHEN] Editing the attachment
        InteractionTemplates.OpenEdit();
        InteractionTemplates.GoToRecord(InteractionTemplate);
        asserterror InteractionTemplates.Attachment.AssistEdit();

        // [THEN] An error is shown that a Word Template is currently in use.
        Assert.ExpectedError(WordTemplateUsedErr);
    end;

    [Test]
    [HandlerFunctions('ModalFormHandlerCreateInteract')]
    procedure InteractionWithoutWordTemplateAndAttachmentError()
    var
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
    begin
        // [SCENARIO] When creating an interaction from Contact, where template has no attachment and no Word template, an error is thrown.
        Initialize();

        // [GIVEN] Create a Contact.
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Create Interaction Template, where attachment and word template is blank.
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate."Attachment No." := 0;
        InteractionTemplate."Wizard Action" := WizardAction::Open;
        InteractionTemplate.Modify();

        // [GIVEN] Run "Create Interaction" page from Contact

        // [WHEN] Enter "Interaction Template Code" and close the page by ModalFormHandlerCreateInteract
        asserterror CreateInteractionFromContact(Contact, InteractionTemplate.Code);

        // [THEN] Error.
        Assert.ExpectedError(NoAttachmentErr);
    end;

    [Test]
    procedure ValidateWizardActionWithLangCodeWithoutWordAttachmentWithWordTemplate()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" value can not be validated with "Import" value for an Interaction Template with Interaction Tmpl. Language with Word Template, any other value validates succesfully.
        Initialize();

        // [GIVEN] Create Interaction Template, where attachment is blank and word template is filled.
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate."Word Template Code" := 'CODE';
        InteractionTemplate.Modify();
        CreateInteractionTmplLangWithoutAttachment(InteractionTmplLanguage, InteractionTemplate.Code);
        InteractionTmplLanguage."Word Template Code" := 'CODE';
        InteractionTmplLanguage.Modify();
        Commit();

        InteractionTemplate.Validate("Language Code (Default)", InteractionTmplLanguage."Language Code");
        // [WHEN] Wizard action is set to blank
        WizardAction := WizardAction::" ";
        // [THEN] Action is validated
        InteractionTemplate.Validate("Wizard Action", WizardAction);
        Assert.AreEqual(WizardAction, InteractionTemplate."Wizard Action", InteractionTemplate.FieldCaption("Wizard Action"));
        // [WHEN] Wizard action is set to open
        WizardAction := WizardAction::Open;
        // [THEN] Action is validated
        InteractionTemplate.Validate("Wizard Action", WizardAction);
        Assert.AreEqual(WizardAction, InteractionTemplate."Wizard Action", InteractionTemplate.FieldCaption("Wizard Action"));
        // [WHEN] Wizard action is set to merge
        WizardAction := WizardAction::Merge;
        // [THEN] Action is validated
        InteractionTemplate.Validate("Wizard Action", WizardAction);
        Assert.AreEqual(WizardAction, InteractionTemplate."Wizard Action", InteractionTemplate.FieldCaption("Wizard Action"));
        // [WHEN] Wizard action is set to import
        WizardAction := WizardAction::Import;
        // [THEN] Validation error
        asserterror InteractionTemplate.Validate("Wizard Action", WizardAction);
        Assert.ExpectedErrorCode(DialogTxt);
        Assert.ExpectedError(StrSubstNo(CanNotBeSpecifiedErr, InteractionTemplate.FieldCaption("Wizard Action"), WizardAction, InteractionTemplate.TableCaption(), InteractionTemplate.Code));
    end;

    [Test]
    procedure ValidateWizardActionWithLangCodeWithWordTemplate()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
        InteractionTemplate: Record "Interaction Template";
    begin
        // [FEATURE] [UT] [Interaction Template]
        // [SCENARIO] "Wizard Action" value can not be validated with "Import" value for an Interaction Template with Interaction Tmpl. Language with Word Template AND attachment, any other value validates succesfully.
        Initialize();

        // [GIVEN] Create Interaction Template, where attachment is filled and word template is filled.
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate."Word Template Code" := 'CODE';
        InteractionTemplate.Modify();
        CreateInteractionTmplLangWithEmailMergeAttachment(InteractionTmplLanguage, InteractionTemplate.Code, '');
        InteractionTmplLanguage."Word Template Code" := 'CODE';
        InteractionTmplLanguage.Modify();
        Commit();

        InteractionTemplate.Validate("Language Code (Default)", InteractionTmplLanguage."Language Code");
        // [WHEN] Wizard action is set to blank
        WizardAction := WizardAction::" ";
        // [THEN] Action is validated
        InteractionTemplate.Validate("Wizard Action", WizardAction);
        Assert.AreEqual(WizardAction, InteractionTemplate."Wizard Action", InteractionTemplate.FieldCaption("Wizard Action"));
        // [WHEN] Wizard action is set to open
        WizardAction := WizardAction::Open;
        // [THEN] Action is validated
        InteractionTemplate.Validate("Wizard Action", WizardAction);
        Assert.AreEqual(WizardAction, InteractionTemplate."Wizard Action", InteractionTemplate.FieldCaption("Wizard Action"));
        // [WHEN] Wizard action is set to merge
        WizardAction := WizardAction::Merge;
        // [THEN] Action is validated
        InteractionTemplate.Validate("Wizard Action", WizardAction);
        Assert.AreEqual(WizardAction, InteractionTemplate."Wizard Action", InteractionTemplate.FieldCaption("Wizard Action"));
        // [WHEN] Wizard action is set to import
        WizardAction := WizardAction::Import;
        // [THEN] Validation error
        asserterror InteractionTemplate.Validate("Wizard Action", WizardAction);
        Assert.ExpectedErrorCode(DialogTxt);
        Assert.ExpectedError(StrSubstNo(CanNotBeSpecifiedErr, InteractionTemplate.FieldCaption("Wizard Action"), WizardAction, InteractionTemplate.TableCaption(), InteractionTemplate.Code));
    end;

    [Test]
    [HandlerFunctions('ModalReportHandler')]
    [Scope('OnPrem')]
    procedure LogSegmentEmailCorrTypeContNoEmail()
    var
        SegmentHeader: Record "Segment Header";
        InteractionTemplate: Record "Interaction Template";
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        Segment: TestPage Segment;
        FileExtension: Text[250];
    begin
        // [SCENARIO 412541] Segment with Correspondence Type = Email, Contact with no Email, Deliver = true should not be logged
        Initialize();

        // [GIVEN] Interaction Template with Word attachment
        FileExtension := 'DOC';
        CreateInteractionTemplateWithCorrespondenceType(
          InteractionTemplate, InteractionTemplate."Correspondence Type (Default)"::Email);
        CreateInteractionTmplLanguageWithAttachmentNo(InteractionTemplate.Code, CreateAttachmentWithFileValue(FileExtension));

        // [GIVEN] Contact "C" with no email specified
        LibraryMarketing.CreatePersonContact(Contact);
        Contact."E-Mail" := '';  // clear email field just to be sure
        Contact.Modify();

        // [GIVEN] Segment with Correspondence Type = Email and Contact "C" specified
        CreateSegmentWithInteractionTemplateAndContact(
          SegmentHeader, InteractionTemplate.Code, Contact."No.",
          SegmentHeader."Correspondence Type (Default)"::Email);
        Commit();

        // [WHEN] Log Segment with "Deliver" = true
        Segment.OpenView();
        Segment.GotoRecord(SegmentHeader);
        asserterror Segment.LogSegment.Invoke();

        // [THEN] Error message appears stating "Contact or Contact Alt. Address should specify Email"
        Assert.ExpectedError(StrSubstNo(SegmentSendContactEmailFaxMissingErr, Contact.FieldCaption("E-Mail"), Contact."No."));

        // [THEN] No Interaction Log Entries created
        InteractionLogEntry.SetRange("Contact No.", Contact."No.");
        Assert.RecordCount(InteractionLogEntry, 0);
    end;

    [Test]
    [HandlerFunctions('LogSegmentDeliverFalseHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LogSegmentEmailCorrTypeContNoEmailNoDeliver()
    var
        SegmentHeader: Record "Segment Header";
        InteractionTemplate: Record "Interaction Template";
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        Segment: TestPage Segment;
        FileExtension: Text[250];
    begin
        // [SCENARIO 412541] Segment with Correspondence Type = Email, Contact with empty "Email", Deliver = false should be logged
        Initialize();

        // [GIVEN] Interaction Template with Word attachment
        FileExtension := 'DOC';

        CreateInteractionTemplateWithCorrespondenceType(
          InteractionTemplate, InteractionTemplate."Correspondence Type (Default)"::Email);
        CreateInteractionTmplLanguageWithAttachmentNo(InteractionTemplate.Code, CreateAttachmentWithFileValue(FileExtension));

        // [GIVEN] Contact "C" with no email specified
        LibraryMarketing.CreatePersonContact(Contact);
        Contact."E-Mail" := '';  // clear email field just to be sure
        Contact.Modify();

        // [GIVEN] Segment with Correspondence Type = Email and Contact "C" specified
        CreateSegmentWithInteractionTemplateAndContact(
          SegmentHeader, InteractionTemplate.Code, Contact."No.",
          SegmentHeader."Correspondence Type (Default)"::Email);
        Commit();

        // [WHEN] Log Segment with Deliver = False
        Segment.OpenView();
        Segment.GotoRecord(SegmentHeader);
        Segment.LogSegment.Invoke();

        // [THEN] Segment is logged and Interaction Log Entry created
        InteractionLogEntry.SetRange("Contact No.", Contact."No.");
        Assert.RecordCount(InteractionLogEntry, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OutboundFlowEntryTitleUserName()
    var
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionTemplate: Record "Interaction Template";
        User: Record User;
        UserName: Code[50];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 434823] Contact Interaction Subform shows title for Outbound interaction template with actual User Name
        Initialize();

        // [GIVEN] User "U" with User Name "UN"
        User.Get(LibraryPermissions.CreateUserWithName(''));
        UserName := User."User Name";

        // [GIVEN] Interaction Template "X" with "Information Flow" = Outbound
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate."Information Flow" := InteractionTemplate."Information Flow"::Outbound;
        InteractionTemplate.Modify();

        // [GIVEN] Contact with Name = "C"
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Modify();

        // [GIVEN] Mock interaction log entry for contact "C" and template "X" and "User Id" = "UN"
        MockInterLogEntry(InteractionLogEntry);
        InteractionLogEntry."Contact No." := Contact."No.";
        InteractionLogEntry."Contact Company No." := Contact."Company No.";
        InteractionLogEntry."Interaction Template Code" := InteractionTemplate.Code;
        InteractionLogEntry."User ID" := UserName;
        InteractionLogEntry.Modify();

        // [WHEN] GetEntryTitle function run for interaction entry
        // [THEN] Contact Interaction Subform shows "Title" = "TD - by UN" (not current user)
        Assert.AreEqual(StrSubstNo(TitleByLbl, InteractionTemplate.Description, UserName), InteractionLogEntry.GetEntryTitle(), 'Invalid Title');

        User.Delete();
    end;

    [Test]
    [HandlerFunctions('ModalReportHandler,MessageHandler')]
    procedure LogSegmentWithWordTemplateAndSendAsAttachmentToggle()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        SegmentHeader: Record "Segment Header";
        Segment: TestPage Segment;
        ExpectedCount: Integer;
    begin
        // [SCENARIO] Log a segment with a Word template using Send As Attachment toggle, will attach document to email and not insert in body.
        Initialize();
        LibraryEmail.SetUpEmailAccount();
        ExpectedCount := InteractionLogEntry.Count() + 1;
        Clear(InteractionLogEntry);

        // [GIVEN] Segment for email and Interaction Template with Word template and given wizard action
        PrepareSegmentForEmail(SegmentHeader, WizardAction::Open);
        SegmentHeader.Validate("Send Word Docs. as Attmt.", true);
        SegmentHeader.Modify();
        Commit(); // Commit as LogSegment is run as modal

        // [WHEN] Log Segment
        Segment.OpenView();
        Segment.GotoRecord(SegmentHeader);
        Segment.LogSegment.Invoke();
        ClearVariables(SegmentHeader);

        // [THEN] Verify that a new log entry was added.
        InteractionLogEntry.FindLast();
        Assert.AreEqual(ExpectedCount, InteractionLogEntry.Count(), 'One new interaction log entry should have been added.');
        ClearVariables(SegmentHeader);
    end;

    [Test]
    [HandlerFunctions('ModalReportHandler,MessageHandler')]
    procedure LogSegmentWithWordTemplateAndWizardActionOpen()
    begin
        LogSegmentWithWordTemplateAndWizardAction(WizardAction::Open);
    end;

    [Test]
    [HandlerFunctions('ModalReportHandler,MessageHandler')]
    procedure LogSegmentWithWordTemplateAndWizardActionMerge()
    begin
        LogSegmentWithWordTemplateAndWizardAction(WizardAction::"Merge");
    end;

    [Test]
    [HandlerFunctions('ModalReportHandler,MessageHandler')]
    procedure LogSegmentWithWordTemplateAndWizardActionEmpty()
    begin
        LogSegmentWithWordTemplateAndWizardAction(WizardAction::" ");
    end;

    procedure LogSegmentWithWordTemplateAndWizardAction(WizardAction: Enum "Interaction Template Wizard Action")
    var
        SegmentHeader: Record "Segment Header";
        InteractionLogEntry: Record "Interaction Log Entry";
        Segment: TestPage Segment;
        ExpectedCount: Integer;
    begin
        // [SCENARIO] User log segment and sends email with Word template using given wizard action
        Initialize();
        LibraryEmail.SetUpEmailAccount();

        ExpectedCount := InteractionLogEntry.Count() + 1;
        Clear(InteractionLogEntry);

        // [GIVEN] Segment for email and Interaction Template with Word template and given wizard action
        PrepareSegmentForEmail(SegmentHeader, WizardAction);

        // [WHEN] Log Segment
        Segment.OpenView();
        Segment.GotoRecord(SegmentHeader);
        Segment.LogSegment.Invoke();

        // [THEN] Verify that a new log entry was added.
        InteractionLogEntry.FindLast();
        Assert.AreEqual(ExpectedCount, InteractionLogEntry.Count(), 'One new interaction log entry should have been added.');
        ClearVariables(SegmentHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler,ModalReportHandler,ConfirmHandler')]
    procedure LogSegmentWithWordTemplate2Lines1PZip()
    var
        SegmentHeader: Record "Segment Header";
        Contact: Array[2] of Record Contact;
        DataCompression: Codeunit "Data Compression";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        TempBlob: Codeunit "Temp Blob";
        Segment: TestPage Segment;
        WizardAction: Enum "Interaction Template Wizard Action";
        InStreamVar: InStream;
        ZipEntryList: List of [Text];
    begin
        // [SCENARIO] Segment with Word Template when logged for 2 contacts generates 1 pdf file
        Initialize();

        // [GIVEN] Segment for Interaction Template with Word template and given wizard action and 2 Contacts
        PrepareSegmentWordTemplate(SegmentHeader, WizardAction::"Merge", Contact);

        // [WHEN] Log Segment
        Segment.OpenView();
        Segment.GotoRecord(SegmentHeader);
        LibraryFileMgtHandler.SetBeforeDownloadFromStreamHandlerActivated(true);
        BindSubscription(LibraryFileMgtHandler);
        Segment.LogSegment.Invoke();

        // [THEN] 1 zip file with name = SegmentHeader.'No.'
        Assert.TextEndsWith(LibraryFileMgtHandler.GetDownloadFromSreamToFileName(), SegmentHeader."No." + '.zip');
        LibraryFileMgtHandler.GetTempBlob(TempBlob);
        TempBlob.CreateInStream(InStreamVar);
        DataCompression.OpenZipArchive(InStreamVar, false);
        DataCompression.GetEntryList(ZipEntryList);

        // [THEN] Zip file contains 2 pdf files.
        Assert.AreEqual(2, ZipEntryList.Count, '');
        Assert.IsTrue(ZipEntryList.Contains(Contact[1]."No." + '.pdf'), '');
        Assert.IsTrue(ZipEntryList.Contains(Contact[2]."No." + '.pdf'), '');
        DataCompression.CloseZipArchive();
        ClearVariables(SegmentHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ModalReportHandler,MessageHandler,ConfirmHandler')]
    procedure LogSegmentWithWordAttachment2Lines1Zip()
    var
        SegmentHeader: Record "Segment Header";
        Contact: Array[2] of Record Contact;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        DataCompression: Codeunit "Data Compression";
        Segment: TestPage Segment;
        FileExtension: Text[250];
        TempBlob: Codeunit "Temp Blob";
        InStreamVar: InStream;
        ZipEntryList: List of [Text];
    begin
        // [SCENARIO 428476] Segment with Attachment when logged for 2 contacts generates zip file with 2 pdfs inside
        Initialize();

        // [GIVEN] Segment with Attachment for 2 Contacts (Company Contact "CC1" and Person Contact "CC2")
        FileExtension := 'DOC';
        CreateContactWithEmail(Contact[1]);
        LibraryMarketing.CreatePersonContactWithCompanyNo(Contact[2]);
        PrepareSegmentWithAttachment(SegmentHeader, FileExtension, Contact[1]);
        CreateSalespersonPurchaserWithEmailAndPhoneNo(SalespersonPurchaser);
        CreateSegmentLineWithContactSalesPerson(SegmentHeader."No.", Contact[2]."No.", SalespersonPurchaser.Code);
        Commit();

        // [WHEN] Log Segment
        Segment.OpenView();
        Segment.GotoRecord(SegmentHeader);

        LibraryFileMgtHandler.SetBeforeDownloadFromStreamHandlerActivated(true);
        BindSubscription(LibraryFileMgtHandler);
        Segment.LogSegment.Invoke();

        // [THEN] 1 zip file with name = SegmentHeader.'No.'
        Assert.TextEndsWith(LibraryFileMgtHandler.GetDownloadFromSreamToFileName(), SegmentHeader."No." + '.zip');
        LibraryFileMgtHandler.GetTempBlob(TempBlob);
        TempBlob.CreateInStream(InStreamVar);
        DataCompression.OpenZipArchive(InStreamVar, false);
        DataCompression.GetEntryList(ZipEntryList);

        // [THEN] Zip file contains 2 pdf files.
        // 1st file name = Contact[1]."No." + '.pdf'
        // 2nd file name = "Contact[2].Company Name - Contact[2]."No." + '.pdf'
        Assert.AreEqual(2, ZipEntryList.Count, '');
        Assert.IsTrue(ZipEntryList.Contains(Contact[1]."No." + '.pdf'), '');
        Assert.IsTrue(ZipEntryList.Contains(Contact[2]."Company Name" + ' - ' + Contact[2]."No." + '.pdf'), '');
        DataCompression.CloseZipArchive();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ModalReportHandler,MessageHandler,ConfirmHandler')]
    procedure LogSegmentWithWordAttachment1Line1Pdf()
    var
        SegmentHeader: Record "Segment Header";
        Contact: Record Contact;
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        Segment: TestPage Segment;
        FileExtension: Text[250];
    begin
        // [SCENARIO 428476] Segment with Attachment when logged for 1 contacts generates 1 pdf file
        Initialize();

        // [GIVEN] Segment with Attachment for 1 Contact
        FileExtension := 'DOC';
        CreateContactWithEmail(Contact);
        PrepareSegmentWithAttachment(SegmentHeader, FileExtension, Contact);
        Commit();

        // [WHEN] Log Segment
        Segment.OpenView();
        Segment.GotoRecord(SegmentHeader);
        LibraryFileMgtHandler.SetBeforeDownloadFromStreamHandlerActivated(true);
        BindSubscription(LibraryFileMgtHandler);
        Segment.LogSegment.Invoke();

        // [THEN] One file with name = Segment.Subject and 'pdf' extensions downloaded
        Assert.TextEndsWith(LibraryFileMgtHandler.GetDownloadFromSreamToFileName(), SegmentHeader."Subject (Default)" + '.pdf');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CreateInteractionPageHandler')]
    procedure VerifyEmailAccountIsBlankAndInteractionLogEntryIsNotCreatedFromContact()
    var
        Contact: Record Contact;
        TestEmailAccount: Record "Test Email Account";
        InteractionGroup: Record "Interaction Group";
        InteractionTemplate: Record "Interaction Template";
        InteractionLogEntry1: Record "Interaction Log Entry";
        InteractionLogEntry2: Record "Interaction Log Entry";
        ContactList: TestPage "Contact List";
        WordTemplateCode: Code[30];
        InteractionLogEntryCount1: Integer;
        InteractionLogEntryCount2: Integer;
    begin
        // [SCENARIO 484280] Verify that Email Account not define then Interaction Log Entry was not created.
        Initialize();

        // [GIVEN] No Email Accounts are present.
        TestEmailAccount.DeleteAll();

        // [GIVEN] Create a Contact with Email ID.
        CreateContactWithEmail(Contact);

        // [GIVEN] Create a Word Template.
        WordTemplateCode := CreateWordTemplateWithRelatedTables();

        // [GIVEN] Create an Interaction Group.
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);

        // [GIVEN] Create an Interaction Template Code.
        CreateInteractionTemplateWithCorrespondenceTypeAndWizardAction(
            InteractionTemplate,
            InteractionTemplate."Correspondence Type (Default)"::Email,
            InteractionTemplate."Wizard Action"::" ",
            WordTemplateCode);

        // [GIVEN] Validate Interaction Group Code.
        InteractionTemplate.Validate("Interaction Group Code", InteractionGroup.Code);
        InteractionTemplate.Modify(true);

        // [GIVEN] Count Interaction Log Entries & save it in a Variable.
        InteractionLogEntry1.SetRange("Contact No.", Contact."No.");
        InteractionLogEntryCount1 := InteractionLogEntry1.Count;

        // [GIVEN] Open Contact List Page & Run Create Interaction Action.
        ContactList.OpenEdit();
        ContactList.GoToRecord(Contact);
        LibraryVariableStorage.Enqueue(InteractionTemplate.Code);
        ContactList."Create &Interaction".Invoke();

        // [WHEN] Count Interaction Log Entries & save it in a Variable.
        InteractionLogEntry2.SetRange("Contact No.", Contact."No.");
        InteractionLogEntryCount2 := InteractionLogEntry2.Count;

        // [VERIFY] Verify No extra Interaction Log Entry is created.
        Assert.AreEqual(InteractionLogEntryCount1, InteractionLogEntryCount2, NoOfInteractionEntriesMustMatchErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAttachmentNoOnSegemntLineIfRevalidateContactNo()
    var
        InteractionTemplate: Record "Interaction Template";
        Contact: Record Contact;
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        LoggedSegment: Record "Logged Segment";
        SegManagement: Codeunit SegManagement;
    begin
        // [SCENARIO 488221] Verify that if Revalidated "Contact No." on an existing segment line, the attachment was not deleted.
        Initialize();

        // [GIVEN] Create Interaction Template.
        CreateInteractionTemplateWithCorrespondenceType(
          InteractionTemplate, InteractionTemplate."Correspondence Type (Default)"::"Hard Copy");

        // [GIVEN] Modify Interaction Template Fields.
        ModifyInteractionTemplate(InteractionTemplate);

        // [GIVEN] Create Interaction Template Language with Attachment
        CreateInteractionTmplLanguageWithAttachmentNo(InteractionTemplate.Code, CreateAttachmentWithFileValue('DOC'));

        // [GIVEN] Create a contact.
        CreateContactWithEmail(Contact);

        //[GIVEN] Create a Segment.
        CreateSegmentWithInteractionTemplateAndContact(
          SegmentHeader, InteractionTemplate.Code, Contact."No.",
          SegmentHeader."Correspondence Type (Default)"::"Hard Copy");

        // [GIVEN] Revalidate the Contact No.
        SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
        SegmentLine.FindFirst();
        SegmentLine.Validate("Contact No.", Contact."No.");
        SegmentLine.Modify(true);

        // [VERIFY] The attachment was not deleted after Revalidating "Contact No." on the existing segment line.
        Assert.Equal(SegmentHeader."Attachment No.", SegmentLine."Attachment No.");

        // [WHEN] Click on Log Segment.
        SegManagement.LogSegment(SegmentHeader, true, false);

        // [VERIFY] A Logged Segment entry was created.
        LoggedSegment.SetRange("Segment No.", SegmentHeader."No.");
        Assert.IsTrue(LoggedSegment.FindFirst(), LoggedSegemntEntriesCreateMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyChangingContactNoOnSegmentLineNotDeletingAttachment()
    var
        InteractionTemplate: Record "Interaction Template";
        Contact: Record Contact;
        Contact1: Record Contact;
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
    begin
        // [SCENARIO 490864] Attachment is deleted after changing (selecting different) "Contact No." on existing Segment Line: Error "The Attachment does not exist. Identification fields and values: No.='1'"
        Initialize();

        // [GIVEN] Create Interaction Template.
        CreateInteractionTemplateWithCorrespondenceType(
            InteractionTemplate,
            InteractionTemplate."Correspondence Type (Default)"::"Hard Copy");

        // [GIVEN] Modify Interaction Template Fields.
        ModifyInteractionTemplate(InteractionTemplate);

        // [GIVEN] Create Interaction Template Language with Attachment
        CreateInteractionTmplLanguageWithAttachmentNo(
            InteractionTemplate.Code,
            CreateAttachmentWithFileValue('DOC'));

        // [GIVEN] Create two different contacts.
        CreateContactWithEmail(Contact);
        CreateContactWithEmail(Contact1);

        //[GIVEN] Create a Segment.
        CreateSegmentWithInteractionTemplateAndContact(
            SegmentHeader,
            InteractionTemplate.Code,
            Contact."No.",
            SegmentHeader."Correspondence Type (Default)"::"Hard Copy");

        // [GIVEN] Revalidate the Contact No.
        SegmentLine.SetRange("Segment No.", SegmentHeader."No.");
        SegmentLine.FindFirst();
        SegmentLine.Validate("Contact No.", Contact1."No.");
        SegmentLine.Modify(true);

        // [VERIFY] The attachment was not deleted after changing the "Contact No." on the existing segment line.
        Assert.Equal(SegmentHeader."Attachment No.", SegmentLine."Attachment No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler,ModalReportHandler')]
    procedure VerifyAttachmentExistsOnInteractionWhenSegmentPostedWithWordTemplatAndTwoContacts()
    var
        SegmentHeader: Record "Segment Header";
        Segment: TestPage Segment;
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
    begin
        // [SCENARIO 491599] Segment Merge Attachment not attached to all segment line contacts
        Initialize();

        // [GIVEN] Segment for Interaction Template with Word template and given wizard action and 2 Contacts
        PrepareSegmentWordTemplateWithTwoContacts(SegmentHeader, WizardAction::"Merge");

        // [WHEN] Log Segment
        Segment.OpenView();
        Segment.GotoRecord(SegmentHeader);
        LibraryFileMgtHandler.SetBeforeDownloadFromStreamHandlerActivated(true);
        BindSubscription(LibraryFileMgtHandler);
        Segment.LogSegment.Invoke();

        // [VERIFY]: Verify Attachment exists on all posted interaction after segment logged
        VerifyAttachmentExistOnPostedInteractionLog(SegmentHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CreateInteractionModalPageHandler')]
    procedure AttachmentShouldNotBeEmptyWhenCreateInteractionFromContact()
    var
        Contact: Record Contact;
        MarketingSetup: Record "Marketing Setup";
        ContactCard: TestPage "Contact Card";
        NewDirName: Text;
        InteractionTemplateCode: Code[10];
        AttachmentNo: Integer;
    begin
        // [SCENARIO 492204] Attachment from Interaction Log entries are empty
        Initialize();

        // [GIVEN] Create Contact
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Change the Attachment Storage Type to "Disk File" and attachment address
        RelocateAttachments(MarketingSetup."Attachment Storage Type"::"Disk File", CreateOrClearTempDirectory(NewDirName));
        MarketingSetup.Get();

        // [GIVEN] Create Attachment
        AttachmentNo := CreateAttachmentFileOnDirectory(MarketingSetup."Attachment Storage Location", TxtFileExt);

        // [GIVEN] Create Interaction Template
        InteractionTemplateCode := CreateInteractionTemplateWithLanguageAndAttachment('', AttachmentNo);

        // [GIVEN] Enqueue Interaction Template Code
        LibraryVariableStorage.Enqueue(InteractionTemplateCode);

        // [WHEN] Open Contact Card and create Interaction.
        ContactCard.OpenEdit();
        ContactCard.GoToRecord(Contact);
        ContactCard."Create &Interaction".Invoke();

        // [VERIFY] Verify Attachment File is not blank on created Interaction.
        VerifyAttachmentFileIsNotBlankOnInteractionLogEntry(Contact."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CreateInteractionFromContactPageHandler')]
    procedure PopulateEvaluationFieldInInteractionLogEntry()
    var
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
        InteractionLogEntry: Record "Interaction Log Entry";
        ContactCard: TestPage "Contact Card";
        InteractionEvaluation: Enum "Interaction Evaluation";
    begin
        // [SCENARIO 498395] When stan creates an Interaction using Create Interaction action from Contact, Evaluation field should be populated in Interaction Log Entry.
        Initialize();

        // [GIVEN] Create a Contact.
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Create an Interaction Template and Validate Information Flow.
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate.Validate("Information Flow", InteractionTemplate."Information Flow"::Outbound);
        InteractionTemplate.Modify(true);

        // [GIVEN] Open Contact Card and Create Interaction.
        ContactCard.OpenEdit();
        ContactCard.GoToRecord(Contact);
        LibraryVariableStorage.Enqueue(InteractionTemplate.Code);
        LibraryVariableStorage.Enqueue(Format(InteractionEvaluation::Positive));
        ContactCard."Create &Interaction".Invoke();

        // [WHEN] Find Interaction Log Entry.
        InteractionLogEntry.SetRange("Contact No.", Contact."No.");
        InteractionLogEntry.FindFirst();

        // [VERIFY] Interaction Log Entry has Evaluation field populated as Positive.
        Assert.AreEqual(
            InteractionEvaluation::Positive,
            InteractionLogEntry.Evaluation,
            StrSubstNo(
                EvaluationErr,
                InteractionLogEntry.FieldCaption(Evaluation),
                InteractionEvaluation::Positive,
                InteractionLogEntry.TableCaption));
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerCreateInteraction,ModalPageHandlerCreateInteractionComments')]
    [Scope('OnPrem')]
    procedure CreateInteractionFromInteractionLogEntriesPageWithComments()
    var
        Contact: Record Contact;
        InteractionGroup: Record "Interaction Group";
        InteractionLogEntry: Record "Interaction Log Entry";
        InteractionLogEntries: TestPage "Interaction Log Entries";
    begin
        // [SCENARIO 492286] When Adding comments to Interaction, all of the comments are displayed/saved
        Initialize();

        // [GIVEN] Create Interaction Group and Contact
        LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryVariableStorage.Enqueue(Contact."No.");

        // [GIVEN] Open Interaction Log Entries page and Invoke Create Interaction Action
        InteractionLogEntries.OpenNew();
        InteractionLogEntries."Create &Interaction".Invoke();

        // [WHEN] Interaction log entry is created
        InteractionLogEntry.SetFilter("Contact No.", Contact."No.");
        InteractionLogEntry.FindFirst();
        Assert.RecordIsNotEmpty(InteractionLogEntry);

        // [THEN] Three comments created for Interaction Log Entry
        VerifyInterLogEntryCommentCount(InteractionLogEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandlerCreateInteraction,ModalPageHandlerCreateInteractionComments')]
    [Scope('OnPrem')]
    procedure CreateInteractionLogWithCommentsForOpportunity()
    var
        Contact: Record Contact;
        InteractionLogEntry: Record "Interaction Log Entry";
        Opportunity: Record Opportunity;
        OpportunityCard: TestPage "Opportunity Card";
    begin
        // [SCENARIO 492286] When Adding comments to an Interaction of opportunity, all of the comments are displayed/saved
        Initialize();

        // [GIVEN] Create opportunity XXX
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateOpportunity(Opportunity, Contact."No.");
        LibraryVariableStorage.Enqueue(Contact."No.");

        // [GIVEN] Open opportunity card page and Invoke Create Interaction Action
        OpportunityCard.OpenEdit();
        OpportunityCard.GotoRecord(Opportunity);
        OpportunityCard."Create &Interaction".Invoke();

        // [WHEN] Interaction log entry is created
        InteractionLogEntry.SetFilter("Contact No.", Contact."No.");
        InteractionLogEntry.FindFirst();
        Assert.RecordIsNotEmpty(InteractionLogEntry);

        // [THEN] Verify: 3 comments created for Interaction Log Entry
        VerifyInterLogEntryCommentCount(InteractionLogEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ModalPageHandlerCreateInteraction,ModalPageHandlerCreateInteractionComments')]
    [Scope('OnPrem')]
    procedure CreateInteractionLogWithCommentsForTask()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        Task: Record "To-do";
        TaskCard: TestPage "Task Card";
    begin
        // [SCENARIO 492286] When Adding comments to an Interction of Task, all of the comments are displayed/saved
        Initialize();

        // [GIVEN] Task with Type 'Meeting'
        LibraryMarketing.CreateCompanyContactTask(Task, Task.Type::Meeting.AsInteger());

        // [GIVEN] Task Card page opened
        TaskCard.OpenEdit();
        TaskCard.FILTER.SetFilter("No.", Task."No.");
        LibraryVariableStorage.Enqueue(Task."Contact No.");

        // [WHEN] Task Status is set to Complete
        TaskCard.Status.SetValue(Task.Status::Completed);

        // [WHEN] Interaction log entry is created
        InteractionLogEntry.SetFilter("Contact No.", Task."Contact No.");
        InteractionLogEntry.FindFirst();
        Assert.RecordIsNotEmpty(InteractionLogEntry);

        // [THEN] Verify: 3 comments created for Interaction Log Entry
        VerifyInterLogEntryCommentCount(InteractionLogEntry."Entry No.");
    end;

    local procedure Initialize()
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Interaction");
        BindActiveDirectoryMockEvents();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Marketing Interaction");

        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Marketing Setup");
        LibrarySetupStorage.Save(DATABASE::"Interaction Template Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Marketing Interaction");
    end;

    local procedure PopulateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation."Bank Name" := 'BankName';
        CompanyInformation."Bank Branch No." := 'BranchNo';
        CompanyInformation."Bank Account No." := 'BankAccountNo';
        CompanyInformation.IBAN := 'IBAN';
        CompanyInformation.Modify();
    end;

    local procedure ResetReportSelection()
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.SetRange("Report ID", 1305);
        if ReportSelections.FindFirst() then begin
            ReportSelections."Email Body Layout Code" := '';
            ReportSelections.Modify();
        end;
    end;

    local procedure CreateAttachmentWithFileValue(FileExtension: Text[250]): Integer
    var
        Attachment: Record Attachment;
        OStream: OutStream;
    begin
        LibraryMarketing.CreateAttachment(Attachment);
        Attachment.Validate("File Extension", FileExtension);
        Attachment."Attachment File".CreateOutStream(OStream);
        OStream.WriteText(LibraryUtility.GenerateRandomText(10));
        Attachment.Modify();
        exit(Attachment."No.");
    end;

    local procedure CreateAndUpdateTemplate(InteractionGroupCode: Code[10]): Code[10]
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        UpdateInteractionTemplate(InteractionTemplate, InteractionGroupCode);
        exit(InteractionTemplate.Code);
    end;

    local procedure CreateSalespersonPurchaserWithEmailAndPhoneNo(var SalespersonPurchaser: Record "Salesperson/Purchaser")
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Validate("E-Mail", 'salesperson@example.com');
        SalespersonPurchaser.Validate("Phone No.", '0987654321');
        SalespersonPurchaser.Modify(true);
    end;

    local procedure CreateContactWithEmail(var Contact: Record Contact)
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("E-Mail", 'someone@example.com');
        Contact.Modify(true);
    end;

    local procedure CreateContactWithPhoneNo(var Contact: Record Contact)
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Phone No.", '1234567890');
        Contact.Modify(true);
    end;

    local procedure CreateContactWithEmailAndPhoneNo(var Contact: Record Contact)
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("E-Mail", 'contact@example.com');
        Contact.Validate("Phone No.", '1234567890');
        Contact.Modify(true);
    end;

    local procedure CreateInteractionFromContact(Contact: Record Contact; TemplateCode: Code[10])
    begin
        LibraryVariableStorage.Enqueue(TemplateCode);
        LibraryVariableStorage.Enqueue(false);
        Contact.CreateInteraction();
    end;

    local procedure CreateInteractionFromContact_EmailMerge(SegmentLine: Record "Segment Line")
    var
        Contact: Record Contact;
    begin
        LibraryVariableStorage.Enqueue(SegmentLine."Interaction Template Code");
        Contact.Get(SegmentLine."Contact No.");
        Contact.CreateInteraction();
    end;

    local procedure CreateInteractionFromLogEntry(var InteractionLogEntry: Record "Interaction Log Entry"; TemplateCode: Code[10]; AdditionalValuesinPageHandler: Boolean; CostLCY: Decimal; DurationMin: Decimal)
    begin
        LibraryVariableStorage.Enqueue(TemplateCode);
        LibraryVariableStorage.Enqueue(AdditionalValuesinPageHandler);
        LibraryVariableStorage.Enqueue(CostLCY);
        LibraryVariableStorage.Enqueue(DurationMin);
        InteractionLogEntry.CreateInteraction();
    end;

    local procedure CreateInteractionTmplLangWithoutAttachment(var InteractionTmplLanguage: Record "Interaction Tmpl. Language"; InteractionTemplateCode: Code[10]): Code[10]
    begin
        exit(
          CreateInteractionTmplLanguage(
            InteractionTmplLanguage, InteractionTemplateCode, FindLanguageCode(''), ''));
    end;

    local procedure CreateInteractionTmplLangWithEmailMergeAttachment(var InteractionTmplLanguage: Record "Interaction Tmpl. Language"; InteractionTemplateCode: Code[10]; LanguageFilter: Text): Code[10]
    var
        LanguageCode: Code[10];
    begin
        LanguageCode := CreateInteractionTmplLanguage(
            InteractionTmplLanguage, InteractionTemplateCode, FindLanguageCode(LanguageFilter),
            LibraryMarketing.FindEmailMergeCustomLayoutName());
        InteractionTmplLanguage.CreateAttachment();
        exit(LanguageCode);
    end;

    local procedure CreateInteractionTmplLanguage(var InteractionTmplLanguage: Record "Interaction Tmpl. Language"; InteractionTemplateCode: Code[10]; LanguageCode: Code[10]; ReportLayoutName: Text[250]): Code[10]
    begin
        InteractionTmplLanguage.Init();
        InteractionTmplLanguage.Validate("Interaction Template Code", InteractionTemplateCode);
        InteractionTmplLanguage.Validate("Language Code", LanguageCode);
        InteractionTmplLanguage.Validate("Report Layout Name", ReportLayoutName);
        InteractionTmplLanguage.Insert();
        exit(InteractionTmplLanguage."Language Code");
    end;

    local procedure CreateInteractionTmplLanguageWithAttachmentNo(TemplateCode: Code[10]; AttachmentNo: Integer)
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        InteractionTmplLanguage.Init();
        InteractionTmplLanguage."Interaction Template Code" := TemplateCode;
        InteractionTmplLanguage."Language Code" := '';
        InteractionTmplLanguage."Attachment No." := AttachmentNo;
        InteractionTmplLanguage.Insert();
    end;

    local procedure CreateInteractionTmplLanguageWithWordTemplate(TemplateCode: Code[10]; WordTemplateCode: Code[30])
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        InteractionTmplLanguage.Init();
        InteractionTmplLanguage."Interaction Template Code" := TemplateCode;
        InteractionTmplLanguage."Language Code" := '';
        InteractionTmplLanguage."Word Template Code" := WordTemplateCode;
        InteractionTmplLanguage.Insert();
    end;

    local procedure CreateWordTemplateWithRelatedTables(): Code[30]
    var
        WordTemplateRec: Record "Word Template";
        InteractionMergeData: Record "Interaction Merge Data";
        WordTemplate: Codeunit "Word Template";
        Base64: Codeunit "Base64 Convert";
        Document: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
    begin
        Document.CreateOutStream(OutStream, TextEncoding::UTF8);
        Base64.FromBase64(GetWordTemplate(), OutStream);
        Document.CreateInStream(InStream, TextEncoding::UTF8);

        WordTemplateRec.Code := LibraryUtility.GenerateRandomAlphabeticText(10, 0);
        WordTemplateRec."Table ID" := Database::"Interaction Merge Data";
        WordTemplateRec.Template.ImportStream(InStream, 'Template');
        WordTemplateRec.Insert();

        WordTemplate.AddRelatedTable(WordTemplateRec.Code, 'CONTA', Database::"Interaction Merge Data", Database::"Contact", InteractionMergeData.FieldNo("Contact No."));
        WordTemplate.AddRelatedTable(WordTemplateRec.Code, 'SALES', Database::"Interaction Merge Data", Database::"Salesperson/Purchaser", InteractionMergeData.FieldNo("Salesperson Code"));
        exit(WordTemplateRec.Code);
    end;

    local procedure CreateInteractionTemplateWithCorrespondenceType(var InteractionTemplate: Record "Interaction Template"; CorrespondenceType: Enum "Correspondence Type")
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate."Correspondence Type (Default)" := CorrespondenceType;
        InteractionTemplate."Wizard Action" := WizardAction::Open;
        InteractionTemplate.Modify(true);
    end;

    local procedure CreateInteractionTemplateWithCorrespondenceTypeAndWizardAction(var InteractionTemplate: Record "Interaction Template"; CorrespondenceType: Enum "Correspondence Type"; WizardAction: Enum "Interaction Template Wizard Action"; WordTemplateCode: Code[30])
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        InteractionTemplate."Correspondence Type (Default)" := CorrespondenceType;
        InteractionTemplate."Wizard Action" := WizardAction;
        InteractionTemplate."Word Template Code" := WordTemplateCode;
        InteractionTemplate.Modify(true);
    end;

    local procedure CreateInteractionLogEntryComment(var InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line"; EntryNo: Integer)
    begin
        InterLogEntryCommentLine.Init();
        InterLogEntryCommentLine."Entry No." := EntryNo;
        InterLogEntryCommentLine."Line No." := 10000;
        InterLogEntryCommentLine.Date := WorkDate();
        InterLogEntryCommentLine.Comment := LibraryUtility.GenerateRandomCode(InterLogEntryCommentLine.FieldNo(Comment), DATABASE::"Inter. Log Entry Comment Line");
        InterLogEntryCommentLine.Insert(true);
    end;

    local procedure CreateSegment(var SegmentHeader: Record "Segment Header"; InteractionTemplateCode: Code[10])
    var
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
    begin
        // Create Segment Header with Interaction Template and Segment Line with Contact No.
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Interaction Template Code", InteractionTemplateCode);
        SegmentHeader.Modify(true);

        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        Contact.SetFilter("Salesperson Code", '<>''''');
        Contact.FindFirst();
        SegmentLine.Validate("Contact No.", Contact."No.");
        SegmentLine.Modify(true);
    end;

    local procedure CreateSegmentWithInteractionTemplateAndContact(var SegmentHeader: Record "Segment Header"; InteractionTemplateCode: Code[10]; ContactNo: Code[20]; CorrespondenceType: Enum "Correspondence Type")
    var
        SegmentLine: Record "Segment Line";
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Interaction Template Code", InteractionTemplateCode);
        SegmentHeader.Validate("Correspondence Type (Default)", CorrespondenceType);
        SegmentHeader.Validate("Subject (Default)", LibraryUtility.GenerateRandomText(MaxStrLen(SegmentHeader."Subject (Default)")));
        SegmentHeader.Modify(true);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentLine.Validate("Contact No.", ContactNo);
        SegmentLine.Modify(true);
    end;

    local procedure CreateSegmentWithInteractionTemplateAndContactAndSalesperson(var SegmentHeader: Record "Segment Header"; InteractionTemplateCode: Code[10]; ContactNo: Code[20]; SalespersonCode: Code[20]; CorrespondenceType: Enum "Correspondence Type")
    begin
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Interaction Template Code", InteractionTemplateCode);
        SegmentHeader.Validate("Correspondence Type (Default)", CorrespondenceType);
        SegmentHeader.Validate("Subject (Default)", LibraryUtility.GenerateRandomText(MaxStrLen(SegmentHeader."Subject (Default)")));
        SegmentHeader.Validate("Salesperson Code", SalespersonCode);
        SegmentHeader.Modify(true);
        CreateSegmentLineWithContactSalesPerson(SegmentHeader."No.", ContactNo, SalespersonCode);
    end;

    local procedure CreateSegmentLineWithContactSalesPerson(SegmentHeaderNo: Code[20]; ContactNo: Code[20]; SalespersonCode: Code[20])
    var
        SegmentLine: Record "Segment Line";
    begin
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeaderNo);
        SegmentLine.Validate("Contact No.", ContactNo);
        SegmentLine.Validate("Salesperson Code", SalespersonCode);
        SegmentLine.Modify(true);
    end;

    local procedure CreateSegmentLineWithAttachment(var TempSegmentLine: Record "Segment Line" temporary; var Attachment: Record Attachment; ContentBodyText: Text)
    begin
        LibraryMarketing.CreateEmailMergeAttachment(Attachment);
        TempSegmentLine."Attachment No." := Attachment."No.";
        TempSegmentLine.LoadSegLineAttachment(false);
        TempSegmentLine.UpdateContentBodyTextInCustomLayoutAttachment(ContentBodyText);
    end;

    local procedure CreateSalutation(LanguageCode: Code[10]): Code[10]
    var
        Salutation: Record Salutation;
    begin
        LibraryMarketing.CreateSalutation(Salutation);
        CreateSalutationFormula(Salutation.Code, LanguageCode, "Salutation Formula Salutation Type"::Formal);
        CreateSalutationFormula(Salutation.Code, LanguageCode, "Salutation Formula Salutation Type"::Informal);
        exit(Salutation.Code);
    end;

    local procedure CreateSalutationFormula(SalutationCode: Code[10]; LanguageCode: Code[10]; SalutationType: Enum "Salutation Formula Salutation Type")
    var
        SalutationFormula: Record "Salutation Formula";
    begin
        LibraryMarketing.CreateSalutationFormula(SalutationFormula, SalutationCode, LanguageCode, SalutationType);
        SalutationFormula.Validate(Salutation, LibraryUtility.GenerateGUID());
        SalutationFormula.Modify();
    end;

    local procedure EnqueueVariablesForEmailDialog(Email: Text; Subject: Text; FileExtension: Text)
    begin
        LibraryVariableStorage.Enqueue(Email);
        LibraryVariableStorage.Enqueue(Subject);
        LibraryVariableStorage.Enqueue(FileExtension);
    end;

    local procedure FindInteractionLogEntry(var InteractionLogEntry: Record "Interaction Log Entry"; ContactNo: Code[20]; InteractionGroupCode: Code[10]; InteractionTemplateCode: Code[10])
    begin
        InteractionLogEntry.SetRange("Contact No.", ContactNo);
        InteractionLogEntry.SetRange("Interaction Group Code", InteractionGroupCode);
        InteractionLogEntry.SetRange("Interaction Template Code", InteractionTemplateCode);
        InteractionLogEntry.FindFirst();
    end;

    local procedure FindInteractionLogEntryByDocument(var InteractionLogEntry: Record "Interaction Log Entry"; DocumentNo: Code[20]; DocumentType: Enum "Interaction Log Entry Document Type")
    begin
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        InteractionLogEntry.SetRange("Document Type", DocumentType);
        InteractionLogEntry.FindFirst();
    end;

    local procedure FindWordAttachment(): Integer
    var
        Attachment: Record Attachment;
    begin
        Attachment.SetRange("Storage Type", Attachment."Storage Type"::Embedded);
        Attachment.SetFilter("File Extension", StrSubstNo('%1|%2', 'DOC', 'DOCX'));
        Attachment.FindFirst();
        exit(Attachment."No.");
    end;

    local procedure FindLanguageCode(CodeFilter: Text): Code[10]
    var
        Language: Record Language;
    begin
        Language.SetFilter(Code, CodeFilter);
        Language.FindFirst();
        exit(Language.Code);
    end;

    local procedure FindOpportunityCommentLine(OpportunityNo: Code[20]; var RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line")
    begin
        RlshpMgtCommentLine.SetRange("Table Name", RlshpMgtCommentLine."Table Name"::Opportunity);
        RlshpMgtCommentLine.SetRange("No.", OpportunityNo);
        RlshpMgtCommentLine.FindSet();
    end;

    local procedure FindContactInteractionLogEntry(var InteractionLogEntry: Record "Interaction Log Entry"; ContactNo: Code[20])
    begin
        InteractionLogEntry.SetRange("Contact No.", ContactNo);
        InteractionLogEntry.FindFirst();
    end;

    local procedure FindIntLogEntryCommentLine(EntryNo: Integer; var InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line")
    begin
        InterLogEntryCommentLine.SetRange("Entry No.", EntryNo);
        InterLogEntryCommentLine.FindFirst();
    end;

    local procedure GetAttachmentFilePath(AttachmentNo: Integer): Text
    var
        Attachment: Record Attachment;
    begin
        Attachment.Get(AttachmentNo);
        exit(Attachment."Storage Pointer" + '\' + Format(Attachment."No.") + '.' + Attachment."File Extension");
    end;

    local procedure GetInterLogEntryDocTypeFromSalesDoc(SalesHeader: Record "Sales Header"): Enum "Interaction Log Entry Document Type"
    var
        DummyInteractionLogEntry: Record "Interaction Log Entry";
    begin
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                exit(DummyInteractionLogEntry."Document Type"::"Sales Ord. Cnfrmn.");
            SalesHeader."Document Type"::Quote:
                exit(DummyInteractionLogEntry."Document Type"::"Sales Qte.");
        end;
    end;

    local procedure MockContactNo(LanguageCode: Code[10]): Code[20]
    var
        Contact: Record Contact;
    begin
        Contact.Init();
        Contact."No." := LibraryUtility.GenerateRandomCode(Contact.FieldNo("No."), DATABASE::Contact);
        Contact."Salutation Code" := CreateSalutation(LanguageCode);
        Contact."E-Mail" := LibraryUtility.GenerateRandomEmail();
        Contact.Insert();
        exit(Contact."No.");
    end;

    local procedure MockInterLogEntryWithAttachment(var InteractionLogEntry: Record "Interaction Log Entry"; AttachmentNo: Integer)
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        InteractionLogEntry.Init();
        InteractionLogEntry."Entry No." := SequenceNoMgt.GetNextSeqNo(DATABASE::"Interaction Log Entry");
        InteractionLogEntry."Attachment No." := AttachmentNo;
        InteractionLogEntry.InsertRecord();
    end;

    local procedure MockCanceledInterLogEntryWithAttachment(AttachmentNo: Integer): Integer
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        MockInterLogEntryWithAttachment(InteractionLogEntry, AttachmentNo);
        InteractionLogEntry.Canceled := true;
        InteractionLogEntry.Modify();
        exit(InteractionLogEntry."Entry No.");
    end;

    local procedure MockInterLogEntry(var InteractionLogEntry: Record "Interaction Log Entry")
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        InteractionLogEntry.Init();
        InteractionLogEntry."Entry No." := SequenceNoMgt.GetNextSeqNo(DATABASE::"Interaction Log Entry");
        InteractionLogEntry.InsertRecord();
    end;

    local procedure MockInterLogEntryWithRandomDetails(var InteractionLogEntry: Record "Interaction Log Entry")
    begin
        MockInterLogEntry(InteractionLogEntry);
        InteractionLogEntry."To-do No." :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(InteractionLogEntry."To-do No."), 0), 1, MaxStrLen(InteractionLogEntry."To-do No."));
        InteractionLogEntry."Contact Company No." :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(InteractionLogEntry."Contact Company No."), 0), 1, MaxStrLen(InteractionLogEntry."Contact Company No."));
        InteractionLogEntry."Contact No." :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(InteractionLogEntry."Contact No."), 0), 1, MaxStrLen(InteractionLogEntry."Contact No."));
        InteractionLogEntry."Salesperson Code" :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(InteractionLogEntry."Salesperson Code"), 0), 1, MaxStrLen(InteractionLogEntry."Salesperson Code"));
        InteractionLogEntry."Campaign No." :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(InteractionLogEntry."Campaign No."), 0), 1, MaxStrLen(InteractionLogEntry."Campaign No."));
        InteractionLogEntry."Opportunity No." :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(InteractionLogEntry."Opportunity No."), 0), 1, MaxStrLen(InteractionLogEntry."Opportunity No."));
        InteractionLogEntry.Modify();
    end;

    local procedure MockInterLogEntryWithGivenSalesPersonCode(var InteractionLogEntry: Record "Interaction Log Entry"; SalespersonCode: Code[20])
    begin
        MockInterLogEntry(InteractionLogEntry);
        InteractionLogEntry."Salesperson Code" := SalespersonCode;
        InteractionLogEntry.Modify();
    end;

    local procedure MockInterLogEntryRelatedToSalesDocument(SalesHeader: Record "Sales Header")
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        InteractionLogEntry.Init();
        InteractionLogEntry."Entry No." := SequenceNoMgt.GetNextSeqNo(DATABASE::"Interaction Log Entry");
        InteractionLogEntry."Document No." := SalesHeader."No.";
        InteractionLogEntry."Document Type" := GetInterLogEntryDocTypeFromSalesDoc(SalesHeader);
        InteractionLogEntry."Contact No." := SalesHeader."Bill-to Contact No.";
        InteractionLogEntry.InsertRecord();
    end;

    local procedure MockFullSegmentLine(var SegmentLine: Record "Segment Line"; InteractionTmplLanguage: Record "Interaction Tmpl. Language")
    begin
        MockSegmentLine(
          SegmentLine, InteractionTmplLanguage, MockContactNo(InteractionTmplLanguage."Language Code"),
          MockSalesPersonCode(), WorkDate(), LibraryUtility.GenerateGUID());
    end;

    local procedure MockSegmentLine(var SegmentLine: Record "Segment Line"; InteractionTmplLanguage: Record "Interaction Tmpl. Language"; ContactNo: Code[20]; SalespersonCode: Code[10]; NewDate: Date; NewDescription: Text[50])
    begin
        SegmentLine.Init();
        if not SegmentLine.IsTemporary then
            SegmentLine."Line No." := LibraryUtility.GetNewRecNo(SegmentLine, SegmentLine.FieldNo("Line No."));
        SegmentLine."Interaction Template Code" := InteractionTmplLanguage."Interaction Template Code";
        SegmentLine."Language Code" := InteractionTmplLanguage."Language Code";
        SegmentLine."Attachment No." := InteractionTmplLanguage."Attachment No.";
        SegmentLine."Contact No." := ContactNo;
        SegmentLine."Salesperson Code" := SalespersonCode;
        SegmentLine.Date := NewDate;
        SegmentLine.Description := NewDescription;
        SegmentLine.Insert();
    end;

    local procedure MockSalesPersonCode(): Code[10]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalespersonPurchaser.Init();
        SalespersonPurchaser.Code := LibraryUtility.GenerateRandomCode(SalespersonPurchaser.FieldNo(Code), DATABASE::"Salesperson/Purchaser");
        SalespersonPurchaser.Insert();
        exit(SalespersonPurchaser.Code);
    end;

    local procedure PrepareInteractionTmplLangCodeWithoutAttachment(var InteractionTmplLanguage: Record "Interaction Tmpl. Language")
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateInteractionTmplLangWithoutAttachment(InteractionTmplLanguage, InteractionTemplate.Code);
        InteractionTemplate."Wizard Action" := InteractionTemplate."Wizard Action"::Merge;
        InteractionTemplate.Modify();
    end;

    local procedure PrepareInteractionTmplLangCodeWithEmailMergeAttachment(var InteractionTmplLanguage: Record "Interaction Tmpl. Language")
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        CreateInteractionTmplLangWithEmailMergeAttachment(InteractionTmplLanguage, InteractionTemplate.Code, '');
        InteractionTemplate.Validate("Language Code (Default)", InteractionTmplLanguage."Language Code");
        InteractionTemplate.Modify();
    end;

    local procedure PrepareSegmentForEmail(var SegmentHeader: Record "Segment Header"; FileExtension: Text[250])
    var
        Contact: Record Contact;
        InteractionTemplate: Record "Interaction Template";
    begin
        CreateInteractionTemplateWithCorrespondenceType(
          InteractionTemplate, InteractionTemplate."Correspondence Type (Default)"::Email);
        CreateInteractionTmplLanguageWithAttachmentNo(InteractionTemplate.Code, CreateAttachmentWithFileValue(FileExtension));

        CreateContactWithEmail(Contact);

        CreateSegmentWithInteractionTemplateAndContact(
          SegmentHeader, InteractionTemplate.Code, Contact."No.",
          SegmentHeader."Correspondence Type (Default)"::Email);
        Commit();
        EnqueueVariablesForEmailDialog(Contact."E-Mail", SegmentHeader."Subject (Default)", '.' + FileExtension);
    end;

    local procedure PrepareSegmentForEmail(var SegmentHeader: Record "Segment Header"; WizardAction: Enum "Interaction Template Wizard Action")
    var
        Contact: Record Contact;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        InteractionTemplate: Record "Interaction Template";
        WordTemplateCode: Code[30];
    begin
        WordTemplateCode := CreateWordTemplateWithRelatedTables();
        CreateInteractionTemplateWithCorrespondenceTypeAndWizardAction(InteractionTemplate, InteractionTemplate."Correspondence Type (Default)"::Email, WizardAction, WordTemplateCode);
        CreateInteractionTmplLanguageWithWordTemplate(InteractionTemplate.Code, WordTemplateCode);

        CreateContactWithEmailAndPhoneNo(Contact);
        CreateSalespersonPurchaserWithEmailAndPhoneNo(SalespersonPurchaser);

        CreateSegmentWithInteractionTemplateAndContactAndSalesperson(SegmentHeader, InteractionTemplate.Code, Contact."No.", SalespersonPurchaser.Code, SegmentHeader."Correspondence Type (Default)"::Email);

        Commit();
        LibraryVariableStorage.Enqueue(Contact."E-Mail");
        LibraryVariableStorage.Enqueue(Contact."Phone No.");
        LibraryVariableStorage.Enqueue(SalespersonPurchaser."E-Mail");
        LibraryVariableStorage.Enqueue(SalespersonPurchaser."Phone No.");
        LibraryVariableStorage.Enqueue(SegmentHeader."Subject (Default)");
    end;

    local procedure PrepareSegmentWordTemplate(var SegmentHeader: Record "Segment Header"; WizardAction: Enum "Interaction Template Wizard Action"; var Contact: Array[2] of Record Contact)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        InteractionTemplate: Record "Interaction Template";
        WordTemplateCode: Code[30];
    begin
        WordTemplateCode := CreateWordTemplateWithRelatedTables();
        CreateInteractionTemplateWithCorrespondenceTypeAndWizardAction(InteractionTemplate, InteractionTemplate."Correspondence Type (Default)"::"Hard Copy", WizardAction, WordTemplateCode);
        CreateInteractionTmplLanguageWithWordTemplate(InteractionTemplate.Code, WordTemplateCode);

        CreateContactWithEmailAndPhoneNo(Contact[1]);
        CreateContactWithEmailAndPhoneNo(Contact[2]);
        CreateSalespersonPurchaserWithEmailAndPhoneNo(SalespersonPurchaser);

        CreateSegmentWithInteractionTemplateAndContactAndSalesperson(SegmentHeader, InteractionTemplate.Code, Contact[1]."No.", SalespersonPurchaser.Code, SegmentHeader."Correspondence Type (Default)"::Email);
        SegmentHeader.Validate("Subject (Default)", LibraryUtility.GenerateRandomAlphabeticText(10, 0));
        SegmentHeader.Modify();
        CreateSegmentLineWithContactSalesPerson(SegmentHeader."No.", Contact[2]."No.", SalespersonPurchaser.Code);
        Commit();
    end;

    local procedure PrepareSegmentWithAttachment(var SegmentHeader: Record "Segment Header"; FileExtension: Text[250]; Contact: Record Contact)
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        InteractionTemplate: Record "Interaction Template";
    begin
        CreateInteractionTemplateWithCorrespondenceType(
          InteractionTemplate, InteractionTemplate."Correspondence Type (Default)"::"Hard Copy");
        CreateInteractionTmplLanguageWithAttachmentNo(InteractionTemplate.Code, CreateAttachmentWithFileValue(FileExtension));
        CreateSalespersonPurchaserWithEmailAndPhoneNo(SalespersonPurchaser);
        CreateSegmentWithInteractionTemplateAndContact(
          SegmentHeader, InteractionTemplate.Code, Contact."No.",
          SegmentHeader."Correspondence Type (Default)"::"Hard Copy");
        SegmentHeader.Validate("Subject (Default)", LibraryUtility.GenerateRandomAlphabeticText(10, 0));
        SegmentHeader.Modify();
    end;

    local procedure RunLogSegment(SegmentNo: Code[20])
    var
        LogSegment: Report "Log Segment";
    begin
        LogSegment.SetSegmentNo(SegmentNo);
        LogSegment.UseRequestPage(false);
        LogSegment.RunModal();
    end;

    local procedure SetEmailDraftInteractionTemplate(TemplateCode: Code[10])
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
    begin
        InteractionTemplateSetup.Get();
        InteractionTemplateSetup.Validate("E-Mail Draft", TemplateCode);
        InteractionTemplateSetup.Modify();
    end;

    [Scope('OnPrem')]
    procedure SetWordAppExists(NewWordAppExists: Boolean)
    begin
        WordAppExist := NewWordAppExists;
    end;

    local procedure TransactionRollback()
    begin
        asserterror Error(RollbackErr);
    end;

    local procedure UpdateInteractionTemplate(var InteractionTemplate: Record "Interaction Template"; InteractionGroupCode: Code[10])
    begin
        InteractionTemplate.Validate("Interaction Group Code", InteractionGroupCode);
        // Use Random for Unit Cost (LCY) and Unit Duration (Min.) because value is not important.
        InteractionTemplate.Validate("Unit Cost (LCY)", LibraryRandom.RandDec(10, 2));
        InteractionTemplate.Validate("Unit Duration (Min.)", LibraryRandom.RandDec(10, 2));
        InteractionTemplate.Modify(true);
    end;

    local procedure VerifyInteractionLogEntry(ContactNo: Code[20]; InteractionTemplateCode: Code[10])
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionTemplate.Get(InteractionTemplateCode);
        FindInteractionLogEntry(InteractionLogEntry, ContactNo, InteractionTemplate."Interaction Group Code", InteractionTemplateCode);
        InteractionLogEntry.TestField("Cost (LCY)", InteractionTemplate."Unit Cost (LCY)");
        InteractionLogEntry.TestField("Duration (Min.)", InteractionTemplate."Unit Duration (Min.)");
    end;

    local procedure VerifyInteractionLogEntryDetails(ExpectedEntryNo: Integer; SegmentLine: Record "Segment Line")
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.FindLast();
        Assert.AreEqual(ExpectedEntryNo, InteractionLogEntry."Entry No.", InteractionLogEntry.FieldCaption("Entry No."));
        Assert.AreEqual(SegmentLine."Contact No.", InteractionLogEntry."Contact No.", InteractionLogEntry.FieldCaption("Contact No."));
        Assert.AreEqual(SegmentLine."Salesperson Code", InteractionLogEntry."Salesperson Code", InteractionLogEntry.FieldCaption("Salesperson Code"));
        Assert.AreEqual(SegmentLine.Date, InteractionLogEntry.Date, InteractionLogEntry.FieldCaption(Date));
        Assert.AreEqual(SegmentLine.Description, InteractionLogEntry.Description, InteractionLogEntry.FieldCaption(Description));
        Assert.AreEqual(SegmentLine."Interaction Template Code", InteractionLogEntry."Interaction Template Code", InteractionLogEntry.FieldCaption("Interaction Template Code"));
        Assert.AreEqual(SegmentLine."Language Code", InteractionLogEntry."Interaction Language Code", InteractionLogEntry.FieldCaption("Interaction Language Code"));
    end;

    local procedure VerifyTemplateGroupStatistics(InteractionGroup: Record "Interaction Group")
    var
        InteractionGroups: TestPage "Interaction Groups";
        InteractionGroupStatistics: TestPage "Interaction Group Statistics";
    begin
        // Open Interaction Group Statistics Page and verify values.
        InteractionGroups.OpenEdit();
        InteractionGroups.FILTER.SetFilter(Code, InteractionGroup.Code);
        InteractionGroupStatistics.Trap();
        InteractionGroups.Statistics.Invoke();

        InteractionGroupStatistics."No. of Interactions".AssertEquals(InteractionGroup."No. of Interactions");
        InteractionGroupStatistics."Cost (LCY)".AssertEquals(InteractionGroup."Cost (LCY)");
        InteractionGroupStatistics."Duration (Min.)".AssertEquals(InteractionGroup."Duration (Min.)");
    end;

    local procedure VerifyTemplateStatistics(InteractionTemplate: Record "Interaction Template")
    var
        InteractionTemplates: TestPage "Interaction Templates";
        InteractionTmplStatistics: TestPage "Interaction Tmpl. Statistics";
    begin
        // Open Interaction Template Statistics Page and verify values.
        InteractionTemplates.OpenEdit();
        InteractionTemplates.FILTER.SetFilter(Code, InteractionTemplate.Code);
        InteractionTmplStatistics.Trap();
        InteractionTemplates.Statistics.Invoke();

        InteractionTmplStatistics."No. of Interactions".AssertEquals(InteractionTemplate."No. of Interactions");
        InteractionTmplStatistics."Cost (LCY)".AssertEquals(InteractionTemplate."Cost (LCY)");
        InteractionTmplStatistics."Duration (Min.)".AssertEquals(InteractionTemplate."Duration (Min.)");
    end;

    local procedure VerifyFilterValuesAfterResumeInteraction(TodoNo: Code[20]; ContactCompanyNo: Code[20]; ContactNo: Code[20]; SalespersonCode: Code[20]; CampaignNo: Code[20]; OpportunityNo: Code[20])
    begin
        // "Salesperson Code" field value
        Assert.AreEqual(SalespersonCode, LibraryVariableStorage.DequeueText(), '');
        // Filter values:
        Assert.AreEqual(TodoNo, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(ContactCompanyNo, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(ContactNo, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(SalespersonCode, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(CampaignNo, LibraryVariableStorage.DequeueText(), '');
        Assert.AreEqual(OpportunityNo, LibraryVariableStorage.DequeueText(), '');
    end;

    local procedure GetWordTemplate(): Text
    begin
        exit('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');
    end;

    local procedure ModifyInteractionTemplate(var InteractionTemplate: Record "Interaction Template")
    begin
        InteractionTemplate.Validate("Ignore Contact Corres. Type", true);
        InteractionTemplate.Validate("Information Flow", InteractionTemplate."Information Flow"::Outbound);
        InteractionTemplate.Validate("Unit Cost (LCY)", LibraryRandom.RandInt(100));
        InteractionTemplate.Validate("Unit Duration (Min.)", LibraryRandom.RandInt(20));
        InteractionTemplate.Validate("Initiated By", InteractionTemplate."Initiated By"::Us);
        InteractionTemplate.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(FinishWizardLaterQst, Question);
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(FinishWizardLaterQst, Question);
        Reply := false;
    end;


    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerExportAttachment(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryVariableStorage.Enqueue(Question);
        Reply := false;
    end;


    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContentPreviewMPH(var ContentPreview: TestPage "Content Preview")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteractPageHandler(var CreateInteraction: Page "Create Interaction"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
    begin
        TempSegmentLine.Init();
        CreateInteraction.GetRecord(TempSegmentLine);
        TempSegmentLine.Insert();

        TempSegmentLine.Validate("Interaction Template Code",
          CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(TempSegmentLine."Interaction Template Code")));
        TempSegmentLine.Validate(Description, TempSegmentLine."Interaction Template Code");  // Validating Description as TemplateCode as using for contact search.
        TempSegmentLine.Modify();

        if LibraryVariableStorage.DequeueBoolean() then begin
            TempSegmentLine.Validate("Cost (LCY)", LibraryVariableStorage.DequeueDecimal());
            TempSegmentLine.Validate("Duration (Min.)", LibraryVariableStorage.DequeueDecimal());
        end;

        TempSegmentLine.CheckStatus();
        TempSegmentLine.FinishSegLineWizard(true);
    end;

    [ModalPageHandler]
    procedure WordTemplateCreationWizardHandler(var WordTemplateCreationWizard: TestPage "Word Template Creation Wizard")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteraction_VerifyHTMLContentVisibility_MPH(var CreateInteraction: TestPage "Create Interaction")
    var
        HTMLMode: Boolean;
    begin
        HTMLMode := LibraryVariableStorage.DequeueBoolean();
        CreateInteraction."Interaction Template Code".SetValue(LibraryVariableStorage.DequeueText());
        CreateInteraction.NextInteraction.Invoke();

        Assert.AreEqual(HTMLMode, CreateInteraction.HTMLContentBodyText.Visible(), CreateInteraction.Caption);
        Assert.AreEqual(HTMLMode, CreateInteraction.Preview.Visible(), CreateInteraction.Caption);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteraction_ValidateLanguageCode_MPH(var CreateInteraction: TestPage "Create Interaction")
    var
        HTMLMode: Boolean;
        NewLanguageCode: Code[10];
    begin
        HTMLMode := LibraryVariableStorage.DequeueBoolean();
        NewLanguageCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(NewLanguageCode));
        CreateInteraction."Interaction Template Code".SetValue(LibraryVariableStorage.DequeueText());
        CreateInteraction."Language Code".SetValue(NewLanguageCode);
        CreateInteraction.NextInteraction.Invoke();

        Assert.AreEqual(HTMLMode, CreateInteraction.HTMLContentBodyText.Visible(), CreateInteraction.Caption);
        Assert.AreEqual(HTMLMode, CreateInteraction.Preview.Visible(), CreateInteraction.Caption);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteraction_ValidateHTMLContent_MPH(var CreateInteraction: TestPage "Create Interaction")
    var
        ContentText: Text;
    begin
        CreateInteraction."Interaction Template Code".SetValue(LibraryVariableStorage.DequeueText());
        ContentText := LibraryUtility.GenerateRandomAlphabeticText(LibraryRandom.RandIntInRange(2000, 3000), 0);
        CreateInteraction.HTMLContentBodyText.SetValue(ContentText);
        CreateInteraction.Preview.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InteractTmplLanguagesMPH(var InteractTmplLanguages: TestPage "Interact. Tmpl. Languages")
    begin
        InteractTmplLanguages."Interaction Template Code".AssertEquals(LibraryVariableStorage.DequeueText());
        InteractTmplLanguages."Language Code".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormHandlerCreateInteract(var CreateInteraction: Page "Create Interaction"; var Response: Action)
    var
        TempSegmentLine: Record "Segment Line" temporary;
        TemplateCode: Code[10];
    begin
        TempSegmentLine.Init();
        CreateInteraction.GetRecord(TempSegmentLine);
        TempSegmentLine.Insert();
        TemplateCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(TemplateCode));
        if TemplateCode <> '' then begin
            TempSegmentLine.Validate("Interaction Template Code", TemplateCode);
            TempSegmentLine.Modify();
        end;

        TempSegmentLine.CheckStatus();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalFormInteractionGroupStat(var InteractionGroupStatistics: Page "Interaction Group Statistics"; var Response: Action)
    var
        InteractionGroup: Record "Interaction Group";
    begin
        InteractionGroupStatistics.GetRecord(InteractionGroup);
        InteractionGroup.CalcFields("Cost (LCY)", "Duration (Min.)");
        InteractionGroup.TestField("Cost (LCY)", LibraryVariableStorage.DequeueDecimal());
        InteractionGroup.TestField("Duration (Min.)", LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MakePhoneCall_MPH(var MakePhoneCall: TestPage "Make Phone Call")
    begin
        // OpenCommentsPage action is visible on all three steps
        Assert.IsTrue(MakePhoneCall.OpenCommentsPage.Visible(), 'OpenCommentsPage. not Visible #1');
        MakePhoneCall.OpenCommentsPage.Invoke();
        MakePhoneCall.Next.Invoke(); // step 2
        Assert.IsTrue(MakePhoneCall.OpenCommentsPage.Visible(), 'OpenCommentsPage. not Visible #2');
        MakePhoneCall.Next.Invoke(); // step 3
        Assert.IsTrue(MakePhoneCall.OpenCommentsPage.Visible(), 'OpenCommentsPage. not Visible #3');
        MakePhoneCall.Finish.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InterLogEntryCommentSheet_MPH(var InterLogEntryCommentSheet: TestPage "Inter. Log Entry Comment Sheet")
    begin
        InterLogEntryCommentSheet.Date.SetValue(LibraryVariableStorage.DequeueDate());
        InterLogEntryCommentSheet.Comment.SetValue(LibraryVariableStorage.DequeueText());
        InterLogEntryCommentSheet.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ModalReportHandler(var LogSegment: TestRequestPage "Log Segment")
    begin
        LogSegment.Deliver.SetValue(true);
        LogSegment.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure LogSegmentDeliverFalseHandler(var LogSegment: TestRequestPage "Log Segment")
    begin
        LogSegment.Deliver.SetValue(false);
        LogSegment.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageText: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
        EmailEditor.ToField.AssertEquals(LibraryVariableStorage.DequeueText());
        EmailEditor.SubjectField.AssertEquals(LibraryVariableStorage.DequeueText());
        // Assert.IsSubstring(EmailEditor.Attachments.FileName.Value, LibraryVariableStorage.DequeueText()); // bug 397659
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure EvaluateInteractionHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteraction_Cancel_MPH(var CreateInteraction: TestPage "Create Interaction")
    begin
        LibraryVariableStorage.Enqueue(CreateInteraction."Salesperson Code".Value);
        LibraryVariableStorage.Enqueue(CreateInteraction.FILTER.GetFilter("To-do No."));
        LibraryVariableStorage.Enqueue(CreateInteraction.FILTER.GetFilter("Contact Company No."));
        LibraryVariableStorage.Enqueue(CreateInteraction.FILTER.GetFilter("Contact No."));
        LibraryVariableStorage.Enqueue(CreateInteraction.FILTER.GetFilter("Salesperson Code"));
        LibraryVariableStorage.Enqueue(CreateInteraction.FILTER.GetFilter("Campaign No."));
        LibraryVariableStorage.Enqueue(CreateInteraction.FILTER.GetFilter("Opportunity No."));
        CreateInteraction.CancelInteraction.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteraction_GetContactName_MPH(var CreateInteraction: TestPage "Create Interaction")
    begin
        LibraryVariableStorage.Enqueue(CreateInteraction."Wizard Contact Name".Value);
        CreateInteraction.CancelInteraction.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SimpleEmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectSendingOptionsModalPageHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    var
        DummyDocumentSendingProfile: Record "Document Sending Profile";
    begin
        SelectSendingOptions."E-Mail".SetValue(DummyDocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)");
        SelectSendingOptions.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteractionPageHandler(var CreateInteraction: TestPage "Create Interaction")
    begin
        CreateInteraction."Interaction Template Code".SetValue(LibraryVariableStorage.DequeueText());
        CreateInteraction.NextInteraction.Invoke();
        asserterror CreateInteraction.NextInteraction.Invoke(); // Email settings error.
    end;

    local procedure SetDefaultCorrespondenceType(CorrespondenceType: Enum "Correspondence Type")
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Default Correspondence Type", CorrespondenceType);
        MarketingSetup.Modify(true);
    end;

    local procedure CreateSalesInvoiceForCustomerWithContact(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Contact, LibraryUtility.GenerateRandomText(30));
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", '', LibraryRandom.RandDec(100, 2), '', 0D);
    end;

    local procedure VerifyBlankCorrespondenceTypeOnInteractionLogEntryForContact(ContactNo: Code[20]; DocumentNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Contact No.", ContactNo);
        Assert.RecordCount(InteractionLogEntry, 1);
        InteractionLogEntry.FindFirst();
        InteractionLogEntry.TestField("Correspondence Type", InteractionLogEntry."Correspondence Type"::" ");
        InteractionLogEntry.TestField("Document No.", DocumentNo);
    end;

    local procedure VerifyInterLogEntry(EntryNo: Integer; ExpectedDocNo: Code[20]; ExpectedDocType: Enum "Interaction Log Entry Document Type")
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.Get(EntryNo);
        InteractionLogEntry.TestField("Document No.", ExpectedDocNo);
        InteractionLogEntry.TestField("Document Type", ExpectedDocType);
    end;

    local procedure VerifyOpporunityCommentLine(InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line"; RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line")
    begin
        RlshpMgtCommentLine.TestField(Date, InterLogEntryCommentLine.Date);
        RlshpMgtCommentLine.TestField(Comment, InterLogEntryCommentLine.Comment);
    end;

    local procedure VerifyOpportunity(Contact: Record Contact; OpportunityNo: Code[20])
    var
        Opportunity: Record Opportunity;
    begin
        Opportunity.SetRange("Contact No.", Contact."No.");
        Opportunity.SetRange("Salesperson Code", Contact."Salesperson Code");
        Opportunity.FindLast();
        Opportunity.TestField("No.", OpportunityNo);
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;

    local procedure ClearVariables(SegmentHeader: Record "Segment Header")
    var
        WordTemplateRec: Record "Word Template";
        WordTemplate: Codeunit "Word Template";
    begin
        LibraryVariableStorage.Clear();

        if WordTemplateRec.Get(SegmentHeader."Word Template Code") then begin
            WordTemplate.RemoveTable(WordTemplateRec.Code, Database::Contact);
            WordTemplate.RemoveTable(WordTemplateRec.Code, Database::"Salesperson/Purchaser");
            WordTemplateRec.Delete();
            Commit();
        end;
    end;

    local procedure PrepareSegmentWordTemplateWithTwoContacts(
        var SegmentHeader: Record "Segment Header";
        InteractionTemplateWizardAction: Enum "Interaction Template Wizard Action")
    var
        Contact: array[2] of Record Contact;
        InteractionTemplate: Record "Interaction Template";
        WordTemplateCode: Code[30];
    begin
        WordTemplateCode := CreateWordTemplateWithRelatedTables();
        CreateInteractionTemplateWithCorrespondenceTypeAndWizardAction(
            InteractionTemplate,
            InteractionTemplate."Correspondence Type (Default)"::"Hard Copy",
            InteractionTemplateWizardAction,
            WordTemplateCode);
        ModifyInteractionTemplate(InteractionTemplate);

        CreateInteractionTmplLanguageWithWordTemplate(InteractionTemplate.Code, WordTemplateCode);
        CreateContactWithEmailAndPhoneNo(Contact[1]);
        CreateContactWithEmailAndPhoneNo(Contact[2]);

        CreateSegmentWithTwoLinesInteractionTemplateAndContactAndSalesperson(
            SegmentHeader,
            InteractionTemplate.Code,
            Contact[1]."No.",
            Contact[2]."No.",
            SegmentHeader."Correspondence Type (Default)"::"Hard Copy");
        Commit();
    end;

    local procedure CreateSegmentWithTwoLinesInteractionTemplateAndContactAndSalesperson(
        var SegmentHeader: Record "Segment Header";
        InteractionTemplateCode: Code[10];
        ContactNo: Code[20];
        ContactNo2: Code[20];
        CorrespondenceType: Enum "Correspondence Type")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        CreateSalespersonPurchaserWithEmailAndPhoneNo(SalespersonPurchaser);
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        SegmentHeader.Validate("Interaction Template Code", InteractionTemplateCode);
        SegmentHeader.Validate("Correspondence Type (Default)", CorrespondenceType);
        SegmentHeader.Validate("Subject (Default)", LibraryUtility.GenerateRandomText(MaxStrLen(SegmentHeader."Subject (Default)")));
        SegmentHeader.Validate("Salesperson Code", SalespersonPurchaser.Code);
        SegmentHeader.Modify(true);

        CreateSegmentLineWithContactSalesPerson(SegmentHeader."No.", ContactNo, SalespersonPurchaser.Code);
        CreateSegmentLineWithContactSalesPerson(SegmentHeader."No.", ContactNo2, SalespersonPurchaser.Code);
    end;

    local procedure VerifyAttachmentExistOnPostedInteractionLog(SegmentNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Segment No.", SegmentNo);
        InteractionLogEntry.FindSet();
        repeat
            Assert.IsTrue(InteractionLogEntry."Attachment No." <> 0, LoggedSegemntEntriesCreateMsg);
        until InteractionLogEntry.Next() = 0;
    end;

    local procedure RelocateAttachments(StorageType: Enum "Setup Attachment Storage Type"; Path: Text)
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        MarketingSetup.Validate("Attachment Storage Type", StorageType);
        MarketingSetup.Validate("Attachment Storage Location", CopyStr(Path, 1, 250) + '\');
        MarketingSetup.Modify(true);
    end;

    local procedure CreateInteractionTemplateWithLanguageAndAttachment(LanguageCode: Code[10]; AttachmentNo: Integer): Code[10]
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);

        InteractionTmplLanguage.Init();
        InteractionTmplLanguage.Validate("Interaction Template Code", InteractionTemplate.Code);
        InteractionTmplLanguage.Validate("Language Code", LanguageCode);
        InteractionTmplLanguage.Validate("Attachment No.", AttachmentNo);
        InteractionTmplLanguage.Insert(true);

        InteractionTemplate.Validate("Language Code (Default)", InteractionTmplLanguage."Language Code");
        InteractionTemplate.Modify(true);

        exit(InteractionTemplate.Code);
    end;

    local procedure CreateOrClearTempDirectory(var NewDirName: Text): Text
    var
        Directory: DotNet Directory;
    begin
        if NewDirName = '' then
            NewDirName := TemporaryPath + LibraryUtility.GenerateGUID();

        if Directory.Exists(NewDirName) then begin
            Directory.Delete(NewDirName, true);
            Directory.CreateDirectory(NewDirName);
        end else
            Directory.CreateDirectory(NewDirName);

        exit(NewDirName);
    end;

    local procedure CreateAttachmentFileOnDirectory(ServerFileAdd: Text; FileExtension: Text[250]): Integer
    var
        Attachment: Record Attachment;
        ExportFile: File;
        OStream: OutStream;
        FileAddress: Text;
    begin
        LibraryMarketing.CreateAttachment(Attachment);
        Attachment.Validate("File Extension", FileExtension);
        Attachment."Attachment File".CreateOutStream(OStream);
        OStream.WriteText(LibraryUtility.GenerateRandomText(10));
        Attachment.Modify();

        FileAddress := ServerFileAdd + Format(Attachment."No.") + '.' + Attachment."File Extension";

        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(FileAddress);
        ExportFile.CreateOutStream(OStream);
        ExportFile.Close();

        exit(Attachment."No.");
    end;

    local procedure VerifyAttachmentFileIsNotBlankOnInteractionLogEntry(ContactNo: Code[20])
    var
        Attachment: Record Attachment;
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Contact No.", ContactNo);
        InteractionLogEntry.FindFirst();

        Attachment.Get(InteractionLogEntry."Attachment No.");
        Assert.AreNotEqual('', Format(Attachment."Attachment File"), AttachmentFileShouldNotBeBlankErr);
    end;

    local procedure VerifyInterLogEntryCommentCount(InteractionLogEntryNo: Integer)
    var
        InterLogEntryCommentLine: Record "Inter. Log Entry Comment Line";
    begin
        InterLogEntryCommentLine.SetRange("Entry No.", InteractionLogEntryNo);
        Assert.IsTrue(InterLogEntryCommentLine.Count() = 3, '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandlerCreateInteraction(var CreateInteraction: TestPage "Create Interaction")
    var
        InteractionTemplate: Record "Interaction Template";
        InterLogEntryCommentSheet: TestPage "Inter. Log Entry Comment Sheet";
        ContactNo: Code[20];
    begin
        InterLogEntryCommentSheet.Trap();
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);
        ContactNo := LibraryVariableStorage.DequeueText();
        CreateInteraction."Wizard Contact Name".SetValue(ContactNo);
        CreateInteraction."Interaction Template Code".SetValue(InteractionTemplate.Code);
        CreateInteraction.Description.SetValue(InteractionTemplate.Code);

        // Invoke Comments on each step
        CreateInteraction."Co&mments".Invoke();
        CreateInteraction.NextInteraction.Invoke();
        CreateInteraction."Co&mments".Invoke();
        CreateInteraction.NextInteraction.Invoke();
        CreateInteraction."Co&mments".Invoke();
        CreateInteraction.FinishInteraction.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandlerCreateInteractionComments(var InterLogEntryCommentSheet: TestPage "Inter. Log Entry Comment Sheet")
    begin
        InterLogEntryCommentSheet.Last();
        InterLogEntryCommentSheet.Next();
        InterLogEntryCommentSheet.Date.SetValue(WorkDate());
        InterLogEntryCommentSheet.Comment.SetValue(LibraryRandom.RandText(20));
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure OnBeforeDownloadHandler(var ToFolder: Text; ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    var
        NameValueBuffer: Record "Name/Value Buffer";
    begin
        NameValueBuffer.Init();
        NameValueBuffer.ID := SessionId();
        NameValueBuffer.Value := FromFileName;
        NameValueBuffer.Insert(true);
        IsHandled := true;
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteractionModalPageHandler(var CreateInteraction: TestPage "Create Interaction")
    begin
        CreateInteraction."Interaction Template Code".SetValue(LibraryVariableStorage.DequeueText());
        CreateInteraction.NextInteraction.Invoke();
        CreateInteraction.NextInteraction.Invoke();
        CreateInteraction.Finish.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CreateInteractionFromContactPageHandler(var CreateInteraction: TestPage "Create Interaction")
    begin
        CreateInteraction."Interaction Template Code".SetValue(LibraryVariableStorage.DequeueText());
        CreateInteraction.NextInteraction.Invoke();
        CreateInteraction.NextInteraction.Invoke();
        CreateInteraction.Evaluation.SetValue(LibraryVariableStorage.DequeueText());
        CreateInteraction.FinishInteraction.Invoke();
    end;
}
