codeunit 139152 DocSendingProfileCRUDTests
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Electronic Document] [Document Sending Profile]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        CannotDeleteDefaultErr: Label 'You cannot delete the default rule. Assign other rule to be default first.';
        TwoDefaultProfilesErr: Label 'Making document sending profile %1 default did not make document sending profile %2 non-default.';
        UnexpectedValueErr: Label 'Unexpected value found.';
        UncheckingDefaultErr: Label 'There must be one default rule in the system. To remove the default property from this rule, assign default to another rule. (Select Refresh to discard errors)';
        IsInitialized: Boolean;
        PeppolFormatNameTxt: Label 'PEPPOL', Locked = true;
        UnableToFindFormatErr: Label 'Unable to find electronic format with Code ''%1'' and Description ''%2''.';
        TooManyResultsErr: Label 'Too many results shown after filtering in Electronic Document Format page.';

    local procedure Initialize()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        ElectronicDocumentFormat.DeleteAll();
        InsertElectronicFormat();

        IsInitialized := true;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateDefaultDocumentSendingProfile()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [GIVEN] the empty Document Sending Profiles list
        // [WHEN] Annie creates a record in Document Sending Profile table, without specifying Default value
        // [THEN] the inserted record will be marked as Default = True.
        Initialize();

        DocumentSendingProfile.DeleteAll();
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile.Insert(true);
        DocumentSendingProfile.FindFirst();
        Assert.IsTrue(DocumentSendingProfile.Default, 'The first and only document sending profile is not marked as default.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteDefaultDocumentSendingProfileFails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [WHEN] Annie tries to delete a default Document Sending Profile
        // [THEN] an error is raised.
        Initialize();

        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile.Default := true;
        DocumentSendingProfile.Insert(true);
        asserterror DocumentSendingProfile.Delete(true);
        Assert.ExpectedError(CannotDeleteDefaultErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUncheckingDefaultFromDefaultDocumentSendingProfileFails()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        DocumentSendingProfileCard: TestPage "Document Sending Profile";
    begin
        // [WHEN] Annie opens a default Document Sending Profile card
        // [THEN] the default button is disabled.
        Initialize();

        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile.Default := true;
        DocumentSendingProfile.Insert(true);
        DocumentSendingProfileCard.OpenEdit();
        DocumentSendingProfileCard.GotoRecord(DocumentSendingProfile);
        asserterror DocumentSendingProfileCard.Default.SetValue(false);
        Assert.ExpectedError(UncheckingDefaultErr);
        Assert.IsTrue(DocumentSendingProfile.Default, 'The first and only document sending profile is not marked as default.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectingNewDefaultDocumentSendingProfile()
    var
        DocumentSendingProfile1: Record "Document Sending Profile";
        DocumentSendingProfile2: Record "Document Sending Profile";
        DocumentSendingProfileCard: TestPage "Document Sending Profile";
    begin
        // [WHEN] Annie selects a non-default document sending profile as a default
        // [THEN] the default is removed from the previous default document sending profile.
        Initialize();

        DocumentSendingProfile1.Init();
        DocumentSendingProfile1.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile1.Default := true;
        DocumentSendingProfile1.Insert(true);
        DocumentSendingProfile2.Init();
        DocumentSendingProfile2.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile2.Default := false;
        DocumentSendingProfile2.Insert(true);
        DocumentSendingProfileCard.OpenEdit();
        DocumentSendingProfileCard.GotoRecord(DocumentSendingProfile2);
        DocumentSendingProfileCard.Default.SetValue(true);
        Assert.IsTrue(
          DocumentSendingProfileCard.Default.AsBoolean(),
          'The user is unable to explicitly check the Default flag on a document sending profile.');
        DocumentSendingProfileCard.GotoRecord(DocumentSendingProfile1);
        Assert.IsFalse(
          DocumentSendingProfileCard.Default.AsBoolean(),
          StrSubstNo(TwoDefaultProfilesErr, DocumentSendingProfile2.Code, DocumentSendingProfile1.Code));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDeleteNonDefaultDocumentSendingProfile()
    var
        DocumentSendingProfile1: Record "Document Sending Profile";
        DocumentSendingProfile2: Record "Document Sending Profile";
    begin
        // [WHEN] Annie tries to delete a non-default document sending profile
        // [THEN] she succeeds
        Initialize();

        DocumentSendingProfile1.Init();
        DocumentSendingProfile1.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile1.Default := true;
        DocumentSendingProfile1.Insert(true);
        DocumentSendingProfile2.Init();
        DocumentSendingProfile2.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile2.Default := false;
        DocumentSendingProfile2.Insert(true);
        DocumentSendingProfile2.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectMultipleSendingMethods()
    var
        DocumentSendingProfile1: Record "Document Sending Profile";
        DocumentSendingProfile2: Record "Document Sending Profile";
    begin
        // [WHEN] Annie tries to update a document sending profile by selecting multiple sending options
        // [THEN] the changes are successfully persisted
        Initialize();
        DocumentSendingProfile1.Init();
        DocumentSendingProfile1.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile1.Default := true;
        DocumentSendingProfile1.Validate(Printer, DocumentSendingProfile1.Printer::"Yes (Use Default Settings)");
        DocumentSendingProfile1.Validate("E-Mail", DocumentSendingProfile1."E-Mail"::"Yes (Prompt for Settings)");
        DocumentSendingProfile1.Insert(true);
        DocumentSendingProfile2.Init();
        DocumentSendingProfile2.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile2.Default := true;
        DocumentSendingProfile2.Validate(
          "Electronic Document", DocumentSendingProfile1."Electronic Document"::"Through Document Exchange Service");
        DocumentSendingProfile2.Validate(Disk, DocumentSendingProfile1.Disk::PDF);
        DocumentSendingProfile2.Insert(true);
        Assert.AreEqual(
          DocumentSendingProfile1.Printer::"Yes (Use Default Settings)", DocumentSendingProfile1.Printer, UnexpectedValueErr);
        Assert.AreEqual(DocumentSendingProfile1."E-Mail"::"Yes (Prompt for Settings)", DocumentSendingProfile1."E-Mail",
          UnexpectedValueErr);
        Assert.AreEqual(
          DocumentSendingProfile1."Electronic Document"::No, DocumentSendingProfile1."Electronic Document", UnexpectedValueErr);
        Assert.AreEqual(DocumentSendingProfile1.Disk::No, DocumentSendingProfile1.Disk, UnexpectedValueErr);
        Assert.AreEqual(DocumentSendingProfile2.Printer::No, DocumentSendingProfile2.Printer, UnexpectedValueErr);
        Assert.AreEqual(DocumentSendingProfile2."E-Mail"::No, DocumentSendingProfile2."E-Mail", UnexpectedValueErr);
        Assert.AreEqual(
          DocumentSendingProfile2."Electronic Document"::"Through Document Exchange Service",
          DocumentSendingProfile2."Electronic Document",
          UnexpectedValueErr);
        Assert.AreEqual(
          DocumentSendingProfile2.Disk::PDF, DocumentSendingProfile2.Disk, UnexpectedValueErr);
    end;

    [Test]
    [HandlerFunctions('ElectronicDocumentFormatsHandler')]
    [Scope('OnPrem')]
    procedure TestFilterElectronicDocumentFormats()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ElectronicDocumentFormatPage: TestPage "Electronic Document Format";
        AdditionalElectronicFormatCode: Code[20];
        AdditionalElectronicFormatDescription: Text[250];
    begin
        // [WHEN] Annie opens the Electronic Document Format page and filters on the Code by choosing 'PEPPOL' document format and filters on Usage by choosing 'Sales Invoice'
        // [THEN] she finds exactly one entry for PEPPOL - Sales Invoice electronic document format
        Initialize();
        AdditionalElectronicFormatCode := PeppolFormatNameTxt + '1';
        AdditionalElectronicFormatDescription := LibraryUtility.GenerateGUID();

        ElectronicDocumentFormat.Init();
        ElectronicDocumentFormat.Code := AdditionalElectronicFormatCode;
        ElectronicDocumentFormat."Codeunit ID" := CODEUNIT::"Exp. Sales Inv. PEPPOL BIS3.0";
        ElectronicDocumentFormat.Usage := ElectronicDocumentFormat.Usage::"Sales Invoice";
        ElectronicDocumentFormat.Description := AdditionalElectronicFormatDescription;
        ElectronicDocumentFormat.Insert(true);

        ElectronicDocumentFormat.Get(PeppolFormatNameTxt, ElectronicDocumentFormat.Usage::"Sales Invoice");
        LibraryVariableStorage.Enqueue(ElectronicDocumentFormat);

        // open Electronic Document Format and filter on Code and Usage
        ElectronicDocumentFormatPage.OpenEdit();
        ElectronicDocumentFormatPage.CodeFilter.Lookup();
        ElectronicDocumentFormatPage.UsageFilter.SetValue(ElectronicDocumentFormat.Usage);

        // verify that you see only one electronic document format
        ElectronicDocumentFormatPage.First();
        Assert.AreEqual(ElectronicDocumentFormat.Code, ElectronicDocumentFormatPage.Code.Value,
          StrSubstNo(UnableToFindFormatErr, ElectronicDocumentFormat.Code, ElectronicDocumentFormat.Description));
        Assert.AreEqual(ElectronicDocumentFormat.Usage, ElectronicDocumentFormatPage.Usage.AsInteger(),
          StrSubstNo(UnableToFindFormatErr, ElectronicDocumentFormat.Code, ElectronicDocumentFormat.Description));
        Assert.AreEqual(ElectronicDocumentFormat.Description, ElectronicDocumentFormatPage.Description.Value,
          StrSubstNo(UnableToFindFormatErr, ElectronicDocumentFormat.Code, ElectronicDocumentFormat.Description));
        ElectronicDocumentFormatPage.Next();
        Assert.AreEqual(0, ElectronicDocumentFormatPage.Usage.AsInteger(), TooManyResultsErr);
        Assert.AreEqual('', ElectronicDocumentFormatPage.Description.Value, TooManyResultsErr);

        // remove Code filter from Electronic Document Format page
        ElectronicDocumentFormatPage.CodeFilter.SetValue('');
        ElectronicDocumentFormatPage.UsageFilter.SetValue(ElectronicDocumentFormat.Usage::"Sales Invoice");

        // verify that you see two electronic document formats
        ElectronicDocumentFormatPage.First();
        Assert.AreEqual(ElectronicDocumentFormat.Code, ElectronicDocumentFormatPage.Code.Value,
          StrSubstNo(UnableToFindFormatErr, ElectronicDocumentFormat.Code, ElectronicDocumentFormat.Description));
        ElectronicDocumentFormatPage.Next();
        Assert.AreEqual(AdditionalElectronicFormatCode, ElectronicDocumentFormatPage.Code.Value,
          StrSubstNo(UnableToFindFormatErr, AdditionalElectronicFormatCode, AdditionalElectronicFormatDescription));

        ElectronicDocumentFormatPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestElectronicDocumentFormatWithBadCodeunitID()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        // [WHEN] Annie tries to modify an electronic document format and set an inexistent codeunit ID for it
        // [THEN] she gets an error message that the object doesn't exist
        Initialize();
        ElectronicDocumentFormat.Get(PeppolFormatNameTxt);
        ElectronicDocumentFormat."Codeunit ID" := 0;
        asserterror ElectronicDocumentFormat.Modify(true);
        Assert.ExpectedErrorCannotFind(Database::AllObj);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingSendToMultipleCustomersRemovesTheCodeAndSendElectronically()
    var
        DocumentSendingProfile: Record "Document Sending Profile";
    begin
        // [WHEN] Sending to different customers
        // [THEN] send electronically must be removed to avoid promting errors to the user
        Initialize();

        DocumentSendingProfile.DeleteAll();
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile."Electronic Document" :=
          DocumentSendingProfile."Electronic Document"::"Through Document Exchange Service";
        DocumentSendingProfile."Electronic Format" := PeppolFormatNameTxt;
        DocumentSendingProfile.Insert(true);

        Assert.IsTrue(DocumentSendingProfile."One Related Party Selected", 'Send To Single rel. Party should be true.');

        // Execute
        DocumentSendingProfile.Validate("One Related Party Selected", false);

        // Verify
        Assert.AreEqual(DocumentSendingProfile."Electronic Document", DocumentSendingProfile."Electronic Document"::No,
          'Electronic document format should be set to None');

        Assert.AreEqual(DocumentSendingProfile."Electronic Format", '',
          'Electronic document format should be blanked');
    end;

    local procedure InsertElectronicFormat()
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
    begin
        ElectronicDocumentFormat.Init();
        ElectronicDocumentFormat.Code := PeppolFormatNameTxt;

        ElectronicDocumentFormat."Codeunit ID" := CODEUNIT::"Exp. Sales Inv. PEPPOL BIS3.0";
        ElectronicDocumentFormat.Usage := ElectronicDocumentFormat.Usage::"Sales Invoice";
        ElectronicDocumentFormat.Description := LibraryUtility.GenerateGUID();
        ElectronicDocumentFormat.Insert(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ElectronicDocumentFormatsHandler(var ElectronicDocumentFormats: TestPage "Electronic Document Formats")
    var
        ElectronicDocumentFormat: Record "Electronic Document Format";
        ElectronicDocumentFormatVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(ElectronicDocumentFormatVar);
        ElectronicDocumentFormat := ElectronicDocumentFormatVar;
        Assert.IsTrue(ElectronicDocumentFormats.FindFirstField(Code, ElectronicDocumentFormat.Code),
          StrSubstNo(UnableToFindFormatErr, ElectronicDocumentFormat.Code, ElectronicDocumentFormat.Description));
        while not (ElectronicDocumentFormats.Description.Value = ElectronicDocumentFormat.Description) do
            Assert.IsTrue(ElectronicDocumentFormats.FindNextField(Code, ElectronicDocumentFormat.Code),
              StrSubstNo(UnableToFindFormatErr, ElectronicDocumentFormat.Code, ElectronicDocumentFormat.Description));
        ElectronicDocumentFormats.OK().Invoke();
    end;
}

