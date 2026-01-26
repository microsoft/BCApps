codeunit 134096 "ERM VAT Return"
{
    Subtype = Test;
    TestPermissions = Restrictive;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Return] [Suggest Lines]
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryVATReport: Codeunit "Library - VAT Report";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        IsInitialized: Boolean;
        IfEmptyErr: Label '''%1'' in ''%2'' must not be blank.', Comment = '%1=caption of a field, %2=key of record';
        GeneratedMsg: Label 'The report has been successfully generated.';
        SubmittedMsg: Label 'The report has been successfully submitted.';
        AttachedDocumentsListErr: Label 'Attached Documents List must be enabled.';

    [Test]
    [HandlerFunctions('SuggestLinesRPH')]
    [Scope('OnPrem')]
    procedure TestVATReturnSuggestLines()
    var
        VATReportHdr: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
    begin
        // [SCENARIO] Get VAT data for government reporting
        // [GIVEN] Demodata - VAT Report Suggest Lines Codeunit is setup in the VAT Report configuration table
        // [GIVEN] Demodata - VAT Entries
        // [GIVEN] VAT Report header of type VAT Return
        CreateVATReturn(VATReportHdr, DATE2DMY(WorkDate(), 3));

        // [GIVEN] VAT Statememt for VAT Return calculation
        SetupVATStatementLineForVATReturn();
        Commit();

        // [WHEN] Stan is running "Suggest Lines"
        LibraryLowerPermissions.SetO365BusFull();
        SuggestLines(
          VATReportHdr, Selection::Open, PeriodSelection::"Before and Within Period", VATReportHdr."Period Year", false);

        // [THEN] VAT Values are calculated from the VAT Entries
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHdr."No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code");
        VATStatementReportLine.FindSet();
        Assert.RecordCount(VATStatementReportLine, 9);
        Assert.AreNotEqual(0, VATStatementReportLine.Amount, 'Should have a value from the VAT Entries');
        VATStatementReportLine.Next();
        Assert.AreNotEqual(0, VATStatementReportLine.Amount, 'Should have a value from the VAT Entries');
    end;

    [Test]
    [HandlerFunctions('SuggestLinesRPH')]
    [Scope('OnPrem')]
    procedure TestVATReturnSuggestLinesWithDifferentFilter()
    var
        VATReportHdr: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
    begin
        // [SCENARIO] Suggest lines for different filters
        // [GIVEN] Demodata - VAT Report Suggest Lines Codeunit is setup in the VAT Report configuration table
        // [GIVEN] Demodata - VAT Entries
        // [GIVEN] VAT Report header of type VAT Return
        CreateVATReturn(VATReportHdr, DATE2DMY(WorkDate(), 3));

        // [GIVEN] VAT Statememt for VAT Return calculation
        SetupVATStatementLineForVATReturn();
        Commit();

        // [WHEN] Stan is running "Suggest Lines"
        // [WHEN] Handler is setting periode to 2000 (no VAT Entries)
        LibraryLowerPermissions.SetO365BusFull();
        SuggestLines(
          VATReportHdr, Selection::Open, PeriodSelection::"Before and Within Period", VATReportHdr."Period Year" - 5, false);

        // [THEN] VAT Values are calculated from the VAT Entries
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHdr."No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code");
        VATStatementReportLine.FindSet();
        Assert.RecordCount(VATStatementReportLine, 9);
        Assert.AreEqual(0, VATStatementReportLine.Amount, 'No VAT Entries should exist in 2000');
        VATStatementReportLine.Next();
        Assert.AreEqual(0, VATStatementReportLine.Amount, 'No VAT Entries should exist in 2000');
    end;

    [Test]
    [HandlerFunctions('SuggestLinesRPH')]
    [Scope('OnPrem')]
    procedure TestVATStatementReportLineModification()
    var
        VATReportHdr: Record "VAT Report Header";
        VATStatementReportLine: Record "VAT Statement Report Line";
        TempDescription: Text;
    begin
        // [SCENARIO] VAT Statement Report Line modification is allowed
        // [GIVEN] VAT Report Header with VAT Statement Report Line "L1"
        CreateVATReturn(VATReportHdr, DATE2DMY(WorkDate(), 3));
        SetupVATStatementLineForVATReturn();
        Commit();
        LibraryLowerPermissions.SetO365BusFull();
        SuggestLines(
          VATReportHdr, Selection::Open, PeriodSelection::"Before and Within Period", VATReportHdr."Period Year", false);
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHdr."No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHdr."VAT Report Config. Code");
        VATStatementReportLine.FindFirst();

        // [WHEN] Line "L1" is modified
        TempDescription := LibraryUtility.GenerateRandomText(MaxStrLen(VATStatementReportLine.Description));
        VATStatementReportLine.Description := CopyStr(TempDescription, 1, MaxStrLen(VATStatementReportLine.Description));
        VATStatementReportLine.Modify(true);

        // [THEN] Modification is done
        VATStatementReportLine.TestField(Description, TempDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReturnAddRepCurrField()
    var
        VATReport: TestPage "VAT Report";
    begin
        // [FEATURE] [UT] [UI] [ACY]
        // [SCENARIO 311850] VAT Return "Amounts in Add. Rep. Currency" field should not be editable
        LibraryApplicationArea.EnableBasicSetup();
        LibraryLowerPermissions.SetO365BusFull();
        VATReport.OpenEdit();
        Assert.IsTrue(
          VATReport."Amounts in Add. Rep. Currency".Visible(),
          'VATReport."Amounts in Add. Rep. Currency" should be visible');
        Assert.IsFalse(
          VATReport."Amounts in Add. Rep. Currency".Editable(),
          'VATReport."Amounts in Add. Rep. Currency" should not be editable');
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('SuggestLinesRPH')]
    [Scope('OnPrem')]
    procedure SuggestLinesLCY()
    var
        VATReportHeader: Record "VAT Report Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 311850] Suggest Lines for VAT Return in case of "Amounts in Add. Rep. Currency" = false
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] VAT Return for the period
        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3) + 1);

        // [GIVEN] VAT Entries for the period with Amount\Base, unrealized Amount\Base LCY and ACY values
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        SetupFourVATStatementLines(VATPostingSetup);
        MockVATEntry(VATEntry, VATPostingSetup, VATReportHeader."Start Date");

        // [WHEN] Suggest Lines for the VAT Return using "Amounts in Add. Reporting Currency" = false
        LibraryLowerPermissions.SetO365BusFull();
        SuggestLines(
          VATReportHeader, Selection::Open, PeriodSelection::"Within Period", VATReportHeader."Period Year", false);

        // [THEN] VAT Return header "Amounts in Add. Rep. Currency" = false
        VATReportHeader.Find();
        Assert.IsFalse(VATReportHeader."Amounts in Add. Rep. Currency", 'VATReportHeader."Amounts in Add. Rep. Currency"');

        // [THEN] VAT Return lines have been suggested for the correspondent VAT Entries with LCY values
        VerifyVATStatementReportLine(VATReportHeader, '1', VATEntry.Amount);
        VerifyVATStatementReportLine(VATReportHeader, '2', VATEntry.Base);
        VerifyVATStatementReportLine(VATReportHeader, '3', VATEntry."Remaining Unrealized Amount");
        VerifyVATStatementReportLine(VATReportHeader, '4', VATEntry."Remaining Unrealized Base");

        // Tear Down
        LibraryLowerPermissions.SetOutsideO365Scope();
        VATEntry.Delete();
    end;

    [Test]
    [HandlerFunctions('SuggestLinesRPH')]
    [Scope('OnPrem')]
    procedure SuggestLinesACY()
    var
        VATReportHeader: Record "VAT Report Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [UT] [ACY]
        // [SCENARIO 311850] Suggest Lines for VAT Return in case of "Amounts in Add. Rep. Currency" = true
        LibraryLowerPermissions.SetOutsideO365Scope();

        // [GIVEN] VAT Return for the period
        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3) + 1);

        // [GIVEN] VAT Entries for the period with Amount\Base, unrealized Amount\Base LCY and ACY values
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        SetupFourVATStatementLines(VATPostingSetup);
        MockVATEntry(VATEntry, VATPostingSetup, VATReportHeader."Start Date");

        // [WHEN] Suggest Lines for the VAT Return using "Amounts in Add. Reporting Currency" = true
        LibraryLowerPermissions.SetO365BusFull();
        SuggestLines(
          VATReportHeader, Selection::Open, PeriodSelection::"Within Period", VATReportHeader."Period Year", true);

        // [THEN] VAT Return header "Amounts in Add. Rep. Currency" = true
        VATReportHeader.Find();
        Assert.IsTrue(VATReportHeader."Amounts in Add. Rep. Currency", 'VATReportHeader."Amounts in Add. Rep. Currency"');

        // [THEN] VAT Return lines have been suggested for the correspondent VAT Entries with ACY values
        VerifyVATStatementReportLine(VATReportHeader, '1', VATEntry."Additional-Currency Amount");
        VerifyVATStatementReportLine(VATReportHeader, '2', VATEntry."Additional-Currency Base");
        VerifyVATStatementReportLine(VATReportHeader, '3', VATEntry."Add.-Curr. Rem. Unreal. Amount");
        VerifyVATStatementReportLine(VATReportHeader, '4', VATEntry."Add.-Curr. Rem. Unreal. Base");

        // Tear Down
        LibraryLowerPermissions.SetOutsideO365Scope();
        VATEntry.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportSetupAutoUpdatePeriodUI()
    var
        VATReportSetup: Record "VAT Report Setup";
        ERMVATReturn: Codeunit "ERM VAT Return";
        VATReportSetupPage: TestPage "VAT Report Setup";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 309370] PAG 743 "VAT Report Setup" field "Auto Receive Period CU ID"
        // [SCENARIO 309370] is only editable in case of "Update Period Job Frequency" = Never
        LibraryLowerPermissions.SetO365BusFull();
        VATReportSetup.Get();
        VATReportSetupPage.OpenEdit();

        VATReportSetupPage."Update Period Job Frequency".SetValue(VATReportSetup."Update Period Job Frequency"::Never);
        Assert.IsTrue(VATReportSetupPage."Auto Receive Period CU ID".Editable(), '');

        BindSubscription(ERMVATReturn); // suppress job queue
        VATReportSetupPage."Auto Receive Period CU ID".SetValue(Codeunit::"Gen. Jnl.-Check Line");
        VATReportSetupPage."Update Period Job Frequency".SetValue(VATReportSetup."Update Period Job Frequency"::Daily);
        Assert.IsFalse(VATReportSetupPage."Auto Receive Period CU ID".Editable(), '');

        VATReportSetupPage."Update Period Job Frequency".SetValue(VATReportSetup."Update Period Job Frequency"::Weekly);
        Assert.IsFalse(VATReportSetupPage."Auto Receive Period CU ID".Editable(), '');

        VATReportSetupPage."Update Period Job Frequency".SetValue(VATReportSetup."Update Period Job Frequency"::Never);
        Assert.IsTrue(VATReportSetupPage."Auto Receive Period CU ID".Editable(), '');
        VATReportSetupPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateActionVisibleWhenNoSubmissionCodeunitSpecified()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] "Generate" action is visible when no "Submission Codeunit ID" specified

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with "Content Codeunit ID" specified and "Submission Codeunit ID" not specified
        SetupVATReportsConfiguration(0);

        // [GIVEN] VAT Report with VAT Reports Configuration
        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3));

        // [WHEN] Open VAT Report page
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");

        // [THEN] "Generate" action is visible but not enabled
        Assert.IsTrue(VATReportPage.Generate.Visible(), '');
        Assert.IsFalse(VATReportPage.Generate.Enabled(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SubmitActionVisibleWhenSubmissionCodeunitSpecified()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] "Submit" action is visible when "Submission Codeunit ID" specified

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with "Submission Codeunit ID" specified
        SetupVATReportsConfiguration(Codeunit::"Test VAT Submission");

        // [GIVEN] VAT Report with VAT Reports Configuration
        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3));

        // [WHEN] Open VAT Report page
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");

        // [THEN] "Submit" action is visible but not enabled
        Assert.IsTrue(VATReportPage.Submit.Visible(), '');
        Assert.IsFalse(VATReportPage.Submit.Enabled(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotReleaseVATReportWhenValidateCodeunitFails()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] Stan cannot release VAT report when "Validate Codeunit" fails on execution

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with "Validate Codeunit ID" which verifies "Additional Information" mandatory
        SetupVATReportsConfiguration(0);

        // [GIVEN] VAT Return with blank "Additional Information"
        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3));

        // [GIVEN] VAT Report page opens and focused on VAT Return
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");

        // [WHEN] Stan click "Release" action
        VATReportPage.Release.Invoke();

        // [THEN] Messages factbox shown on the "VAT Report" page with the "Additional Information must not be blank" error
        VATReportPage.ErrorMessagesPart.Description.AssertEquals(
            StrSubstNo(IfEmptyErr, VATReportHeader.FieldCaption("Additional Information"), Format(VATReportHeader.RecordId)));

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportStatusChangesToReleasedWhenValidationCodeunitPassed()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] Stan can release VAT report when "Validate Codeunit" passes

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with "Validate Codeunit ID" which verifies "Additional Information" mandatory
        SetupVATReportsConfiguration(0);

        // [GIVEN] VAT Return with "Additional Information" specified
        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3));
        VATReportHeader."Additional Information" := LibraryUtility.GenerateGUID();
        VATReportHeader.Modify(true);

        // [GIVEN] VAT Report page opens and focused on VAT Return
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");

        // [WHEN] Stan click "Release" action
        VATReportPage.Release.Invoke();

        // [THEN] VAT Report's status is released
        VATReportPage.Status.AssertEquals(VATReportHeader.Status::Released);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DownloadSubmissionMessageEnabledhenReleasedAndSubmissionCodeunitNotSpecified()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] "Download Submission Message" action is enabled when report is released but submission codeunit not specified

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with "Validate Codeunit ID" which verifies "Additional Information" mandatory
        SetupVATReportsConfiguration(0);

        // [GIVEN] VAT Return with Release status
        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3));
        VATReportHeader.Status := VATReportHeader.Status::Released;
        VATReportHeader.Modify(true);

        // [WHEN] VAT Report page opens and focused on VAT Return
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");

        // [THEN] "Download Submission Message" action is enabled
        Assert.IsTrue(VATReportPage."Download Submission Message".Enabled(), '');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure DownloadSubmissionMessageAfterContentGeneration()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportArchive: Record "VAT Report Archive";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] Submission message generates after using action "Generate" when no submission codeunit ID specified

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with no "Submission Codeunit ID" specified
        SetupVATReportsConfiguration(0);

        // [GIVEN] VAT Return with Status = Released
        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3));
        VATReportHeader.Status := VATReportHeader.Status::Released;
        VATReportHeader.Modify(true);

        // [GIVEN] VAT Report page opens and focused on VAT Return
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");
        LibraryVariableStorage.Enqueue(GeneratedMsg);

        // [WHEN] Stan click "Generate" action
        VATReportPage.Generate.Invoke();

        // [THEN] Submission message generated
        VATReportArchive.Get(VATReportHeader."VAT Report Config. Code", VATReportHeader."No.");
        VATReportArchive.CalcFields("Submission Message BLOB");
        VATReportArchive.TestField("Submission Message BLOB");

        LibraryVariableStorage.AssertEmpty();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('MessageHandler')]
    procedure SubmitVATReportChanges()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 329990] Stan can submit VAT report when "Submission Codeunit ID" specified

        LibraryLowerPermissions.SetO365BusFull();
        LibraryApplicationArea.EnableBasicSetup();

        // [GIVEN] VAT Reports Configuration with "Submission Codeunit ID" specified
        SetupVATReportsConfiguration(Codeunit::"Test VAT Submission");

        // [GIVEN] VAT Return
        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3));
        VATReportHeader.Status := VATReportHeader.Status::Released;
        VATReportHeader.Modify(true);

        // [GIVEN] VAT Report page opens and focused on VAT Return
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");
        LibraryVariableStorage.Enqueue(SubmittedMsg);

        // [WHEN] Stan click "Submit" action
        VATReportPage.Submit.Invoke();

        // [THEN] VAT Report's status is submitted
        VATReportPage.Status.AssertEquals(VATReportHeader.Status::Submitted);

        // [THEN] "Message ID" is assigned to VAT Report
        VATReportHeader.Find();
        VATReportHeader.TestField("Message Id");

        LibraryVariableStorage.AssertEmpty();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATNoteFieldIsVisibleInVATReturnSubformPageWhenReportVATNoteOptionEnabled()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 433237] The VAT Note field is visible in the VAT return subform page when "Report VAT Note" option is enabled

        Initialize();
        SetReportNoteInVATReportSetup();

        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3));

        LibraryLowerPermissions.SetO365BusFull();
        VATReportPage.OpenEdit();
        VATReportPage.Filter.SetFilter("No.", VATReportHeader."No.");
        Assert.IsTrue(VATReportPage.VATReportLines.Note.Visible(), 'VAT Note field is not visible');

        VATReportPage.Close();
    end;

    [Test]
    [HandlerFunctions('VATReportRequestPageHandler,CountriesRegionsModalPageHandler')]
    procedure CountryRegionFilterOnVATRepReqPageAllowsLookupFromCountryRegionListPage()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportRequestPage: Report "VAT Report Request Page";
    begin
        // [SCENARIO 525644] Country/Region filter on VAT report request page allows to lookup from Country/Region List page

        Initialize();
        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3));
        Commit();
        VATReportHeader.SetRecFilter();
        LibraryLowerPermissions.SetO365BusFull();
        // [GIVEN] VAT Report Request Page is opened
        VATReportRequestPage.SetTableView(VATReportHeader);
        // [WHEN] Click "Lookup" on the "Country/Region Filter" field
        // Done in the VATReportRequestPageHandler
        VATReportRequestPage.Run();
        // [THEN] Country/Region List page is opened
        // Done in the CountriesRegionsPageHandler
    end;

    [Test]
    [HandlerFunctions('SuggestLinesCountryRegionFilterRPH')]
    procedure SuggestLinesInVATReturnWithCountryRegionFilter()
    var
        VATReportHeader: Record "VAT Report Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        CountryRegion: array[2] of Record "Country/Region";
        CountryRegionFilter: Text[250];
        i: Integer;
    begin
        // [SCENARIO 525644] Stan can suggest lines for VAT return based on the country/region filter

        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        // [GIVEN] VAT Return for the period
        CreateVATReturn(VATReportHeader, DATE2DMY(WorkDate(), 3) + 1);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        SetupFourVATStatementLines(VATPostingSetup);
        // [GIVEN] VAT entry "X" with country/region ES
        // [GIVEN] VAT entry "Y" with country/region DE
        for i := 1 to ArrayLen(CountryRegion) do begin
            LibraryERM.CreateCountryRegion(CountryRegion[i]);
            MockVATEntry(VATEntry, VATPostingSetup, VATReportHeader."Start Date");
            VATEntry."Country/Region Code" := CountryRegion[i].Code;
            VATEntry.Modify();
        end;
        CountryRegionFilter := '<>' + CountryRegion[1].Code;
        LibraryLowerPermissions.SetO365BusFull();
        // [WHEN] Suggest lines with "Country/Region Filter" = "<>ES"
        SuggestLines(
          VATReportHeader, Selection::Open, PeriodSelection::"Within Period", VATReportHeader."Period Year", false, CountryRegionFilter);
        // [THEN] "Country/Region Filter" has the value that was set in the VAT report request page
        VATReportHeader.Find();
        VATReportHeader.TestField("Country/Region Filter", CountryRegionFilter);
        // [THEN] VAT Return lines have been suggested for the correspondent VAT Entry with country/region DE
        VerifyVATStatementReportLine(VATReportHeader, '1', VATEntry.Amount);
        VerifyVATStatementReportLine(VATReportHeader, '2', VATEntry.Base);
        VerifyVATStatementReportLine(VATReportHeader, '3', VATEntry."Remaining Unrealized Amount");
        VerifyVATStatementReportLine(VATReportHeader, '4', VATEntry."Remaining Unrealized Base");

        LibraryLowerPermissions.SetOutsideO365Scope();
    end;

    [Test]
    procedure EnsureVATReturnPeriodDocumentAttachmentMgmtSupport()
    var
        DocumentAttachment: Record "Document Attachment";
        VATReportHeader: Record "VAT Report Header";
        VATReturnPeriod: Record "VAT Return Period";
        RecordRef: RecordRef;
        VATReportList: TestPage "VAT Report List";
        VATReport: TestPage "VAT Report";
    begin
        // [SCENARIO 597641] Ensure VAT Return Period supports Documents in Attached Documents List FactBox.
        // [GIVEN] Initialized VAT Return Period.
        VATReturnPeriod.Init();
        VATReturnPeriod."No." := LibraryUtility.GenerateGUID();
        VATReturnPeriod.Status := VATReturnPeriod.Status::Open;
        VATReturnPeriod."Start Date" := DMY2Date(1, 1, Date2DMY(WorkDate(), 3));
        VATReturnPeriod."End Date" := DMY2Date(31, 3, Date2DMY(WorkDate(), 3));
        VATReturnPeriod."Due Date" := WorkDate();
        VATReturnPeriod.Insert();

        // [GIVEN] Open VAT Report List page and create VAT Report for the VAT Return Period.
        LibraryLowerPermissions.SetO365BusFull();
        VATReport.OpenNew();
        VATReport.Status.SetValue(VATReportHeader.Status::Open);

        // [GIVEN] Set VAT Return Period No. in VAT Report page and save the record.
        VATReportHeader.SetRange("No.", VATReport."No.".Value());
        VATReportHeader.FindFirst();

        // [GIVEN] Open VAT Report List page and go to the created VAT Report record.
        VATReportList.OpenEdit();
        VATReportList.GoToRecord(VATReportHeader);

        // [GIVEN] Document Attachment record for VAT Return Period.
        RecordRef.GetTable(VATReportHeader);

        // [GIVEN] Create and attach document to VAT Report Header.
        CreateDocumentAttachment(DocumentAttachment, RecordRef, 'foo.jpeg');

        // [THEN] Verify that Document Attachment record is created.
        Assert.IsTrue(VATReportList."Attached Documents List".Enabled(), AttachedDocumentsListErr);
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibrarySetupStorage.Save(Database::"VAT Report Setup");
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateVATReturn(var VATReportHeader: Record "VAT Report Header"; PeriodYear: Integer);
    begin
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        VATReportHeader.Insert(true);
        VATReportHeader.Validate("Period Year", PeriodYear);
        VATReportHeader.Modify();
    end;

    local procedure SetupVATStatementLineForVATReturn()
    var
        VATStatementLine: Record "VAT Statement Line";
        i: Integer;
    begin
        VATStatementLine.ModifyAll("Box No.", '');
        VATStatementLine.FindFirst();
        for i := 1 to 9 do begin
            VATStatementLine."Box No." := Format(i);
            VATStatementLine.Modify();
            VATStatementLine.Next();
        end;
    end;

    local procedure SetupFourVATStatementLines(VATPostingSetup: Record "VAT Posting Setup")
    var
        VATStatementName: Record "VAT Statement Name";
        VATStatementLine: Record "VAT Statement Line";
        i: Integer;
    begin
        GetVATStatementNameW1(VATStatementName);
        VATStatementLine.SetRange("Statement Template Name", VATStatementName."Statement Template Name");
        VATStatementLine.SetRange("Statement Name", VATStatementName.Name);
        VATStatementLine.ModifyAll("Box No.", '');
        VATStatementLine.FindLast();

        VATStatementLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATStatementLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";

        InsertVATStatementLine(VATStatementLine, '1', VATStatementLine."Amount Type"::Amount);
        InsertVATStatementLine(VATStatementLine, '2', VATStatementLine."Amount Type"::Base);
        InsertVATStatementLine(VATStatementLine, '3', VATStatementLine."Amount Type"::"Unrealized Amount");
        InsertVATStatementLine(VATStatementLine, '4', VATStatementLine."Amount Type"::"Unrealized Base");

        for i := 5 to 9 do
            InsertVATStatementLine(VATStatementLine, Format(i), VATStatementLine."Amount Type"::Amount);
    end;

    local procedure InsertVATStatementLine(var VATStatementLine: Record "VAT Statement Line"; BoxNo: Text[30]; AmountType: Enum "VAT Statement Line Amount Type")
    begin
        VATStatementLine."Line No." += 10000;
        VATStatementLine."Box No." := BoxNo;
        VATStatementLine."Gen. Posting Type" := VATStatementLine."Gen. Posting Type"::Sale;
        VATStatementLine.Type := VATStatementLine.Type::"VAT Entry Totaling";
        VATStatementLine."Amount Type" := AmountType;
        VATStatementLine."Print with" := VATStatementLine."Print with"::Sign;
        VATStatementLine.Insert();
    end;

    local procedure MockVATEntry(var VATEntry: Record "VAT Entry"; VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date)
    begin
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FIELDNO("Entry No."));
        VATEntry.Type := VATEntry.Type::Sale;
        VATEntry."Posting Date" := PostingDate;
        VATEntry."VAT Reporting Date" := PostingDate;
        VATEntry.Closed := false;
        VATEntry."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        VATEntry."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        VATEntry.Amount := LibraryRandom.RandDec(1000, 2);
        VATEntry.Base := LibraryRandom.RandDec(1000, 2);
        VATEntry."Remaining Unrealized Amount" := LibraryRandom.RandDec(1000, 2);
        VATEntry."Remaining Unrealized Base" := LibraryRandom.RandDec(1000, 2);
        VATEntry."Additional-Currency Amount" := LibraryRandom.RandDec(1000, 2);
        VATEntry."Additional-Currency Base" := LibraryRandom.RandDec(1000, 2);
        VATEntry."Add.-Curr. Rem. Unreal. Amount" := LibraryRandom.RandDec(1000, 2);
        VATEntry."Add.-Curr. Rem. Unreal. Base" := LibraryRandom.RandDec(1000, 2);
        VATEntry.Insert();
    end;

    local procedure SuggestLines(VATReportHeader: Record "VAT Report Header"; Selection: Enum "VAT Statement Report Selection"; PeriodSelection: Enum "VAT Statement Report Period Selection"; PeriodYear: Integer; AmountInACY: Boolean);
    var
        VATReportMediator: Codeunit "VAT Report Mediator";
    begin
        Commit();
        LibraryVariableStorage.Enqueue(Selection);
        LibraryVariableStorage.Enqueue(PeriodSelection);
        LibraryVariableStorage.Enqueue(PeriodYear);
        LibraryVariableStorage.Enqueue(AmountInACY);
        VATReportMediator.GetLines(VATReportHeader);
    end;

    local procedure SuggestLines(VATReportHeader: Record "VAT Report Header"; Selection: Enum "VAT Statement Report Selection"; PeriodSelection: Enum "VAT Statement Report Period Selection"; PeriodYear: Integer; AmountInACY: Boolean; CountryRegionFilter: Text[250]);
    var
        VATReportMediator: Codeunit "VAT Report Mediator";
    begin
        Commit();
        LibraryVariableStorage.Enqueue(Selection);
        LibraryVariableStorage.Enqueue(PeriodSelection);
        LibraryVariableStorage.Enqueue(PeriodYear);
        LibraryVariableStorage.Enqueue(AmountInACY);
        LibraryVariableStorage.Enqueue(CountryRegionFilter);
        VATReportMediator.GetLines(VATReportHeader);
    end;

    local procedure GetVATStatementNameW1(var VATStatementName: Record "VAT Statement Name");
    begin
        VATStatementName.GET('VAT', 'DEFAULT');
    end;

    local procedure SetupVATReportsConfiguration(SubmissionCodeunitID: Integer)
    begin
        InitVATReportsConfiguration(Codeunit::"VAT Report Suggest Lines", Codeunit::"Test VAT Content", Codeunit::"Test VAT Validate", SubmissionCodeunitID, Codeunit::"Test VAT Response");
    end;

    local procedure InitVATReportsConfiguration(SuggestLinesCodeunitID: Integer; ContentCodeunitID: Integer; ValidateCodeunitID: Integer; SubmissionCodeunitID: Integer; ResponseHandlerCodeunitID: Integer)
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"VAT Return");
        VATReportsConfiguration.DeleteAll();
        VATReportHeader.DeleteAll();
        LibraryVATReport.CreateVATReportConfigurationNo(
            SuggestLinesCodeunitID, ContentCodeunitID, ValidateCodeunitID, SubmissionCodeunitID, ResponseHandlerCodeunitID);
    end;

    local procedure SetReportNoteInVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        VATReportSetup.Get();
        VATReportSetup.Validate("Report VAT Note", true);
        VATReportSetup.Modify(true);
    end;

    local procedure VerifyVATStatementReportLine(VATReportHeader: Record "VAT Report Header"; BoxNo: Text[30]; ExpectedAmount: Decimal)
    begin
        VerifyVATStatementReportLineBaseAndAmount(VATReportHeader, BoxNo, 0, ExpectedAmount)
    end;

    local procedure VerifyVATStatementReportLineBaseAndAmount(VATReportHeader: Record "VAT Report Header"; BoxNo: Text[30]; ExpectedBase: Decimal; ExpectedAmount: Decimal)
    var
        VATStatementReportLine: Record "VAT Statement Report Line";
    begin
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
        VATStatementReportLine.SetRange("Box No.", BoxNo);
        VATStatementReportLine.FindFirst();
        VATStatementReportLine.TestField(Base, ExpectedBase);
        VATStatementReportLine.TestField(Amount, ExpectedAmount);
    end;

    local procedure CreateDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; RecRef: RecordRef; FileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
    begin
        DocumentAttachment.Init();
        CreateTempBLOBWithImageOfType(TempBlob);
        DocumentAttachment.SaveAttachment(RecRef, FileName, TempBlob);
        Clear(DocumentAttachment);
    end;

    local procedure CreateTempBLOBWithImageOfType(var TempBlob: Codeunit "Temp Blob")
    var
        ImageFormat: DotNet ImageFormat;
        Bitmap: DotNet Bitmap;
        InStr: InStream;
    begin
        TempBlob.CreateInStream(InStr);
        Bitmap := Bitmap.Bitmap(1, 1);
        Bitmap.Save(InStr, ImageFormat.Jpeg);
        Bitmap.Dispose();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestLinesRPH(var VATReportRequestPage: TestRequestPage "VAT Report Request Page")
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        GetVATStatementNameW1(VATStatementName);
        VATReportRequestPage.VATStatementTemplate.SETVALUE(VATStatementName."Statement Template Name");
        VATReportRequestPage.VATStatementName.SETVALUE(VATStatementName.Name);

        Selection := "VAT Statement Report Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage.Selection.SETVALUE(Format(Selection));

        PeriodSelection := "VAT Statement Report Period Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage.PeriodSelection.SETVALUE(Format(PeriodSelection));

        VATReportRequestPage."Period Year".SETVALUE(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage."Amounts in ACY".SETVALUE(LibraryVariableStorage.DequeueBoolean());
        VATReportRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestLinesCustomVATStatementRPH(var VATReportRequestPage: TestRequestPage "VAT Report Request Page")
    begin
        VATReportRequestPage.VATStatementTemplate.SETVALUE(LibraryVariableStorage.DequeueText());
        VATReportRequestPage.VATStatementName.SETVALUE(LibraryVariableStorage.DequeueText());

        Selection := "VAT Statement Report Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage.Selection.SETVALUE(Format(Selection));

        PeriodSelection := "VAT Statement Report Period Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage.PeriodSelection.SETVALUE(Format(PeriodSelection));

        VATReportRequestPage."Period Year".SETVALUE(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage."Period No.".SetValue(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage."Amounts in ACY".SETVALUE(LibraryVariableStorage.DequeueBoolean());
        VATReportRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestLinesCountryRegionFilterRPH(var VATReportRequestPage: TestRequestPage "VAT Report Request Page")
    var
        VATStatementName: Record "VAT Statement Name";
    begin
        GetVATStatementNameW1(VATStatementName);
        VATReportRequestPage.VATStatementTemplate.SETVALUE(VATStatementName."Statement Template Name");
        VATReportRequestPage.VATStatementName.SETVALUE(VATStatementName.Name);

        Selection := "VAT Statement Report Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage.Selection.SETVALUE(Format(Selection));

        PeriodSelection := "VAT Statement Report Period Selection".FromInteger(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage.PeriodSelection.SETVALUE(Format(PeriodSelection));

        VATReportRequestPage."Period Year".SETVALUE(LibraryVariableStorage.DequeueInteger());
        VATReportRequestPage."Amounts in ACY".SETVALUE(LibraryVariableStorage.DequeueBoolean());
        VATReportRequestPage."Country/Region Filter".SETVALUE(LibraryVariableStorage.DequeueText());
        VATReportRequestPage.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;

    [RequestPageHandler]
    procedure VATReportRequestPageHandler(var VATReportRequestPage: TestRequestPage "VAT Report Request Page")
    begin
        VATReportRequestPage."Country/Region Filter".Lookup();
    end;

    [ModalPageHandler]
    procedure CountriesRegionsModalPageHandler(var CountryRegionListPage: TestPage "Countries/Regions")
    begin
    end;

    [EventSubscriber(ObjectType::Table, database::"Job Queue Entry", 'OnBeforeScheduleTask', '', true, true)]
    local procedure OnBeforeScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var TaskGUID: Guid)
    begin
        TaskGUID := CreateGuid();
    end;
}
