codeunit 139004 "Test ApplicationArea Setup"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Application Area]
    end;

    var
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryJournals: Codeunit "Library - Journals";
        FieldShouldBeTrueMsg: Label 'Field %1 should be true', Locked = true;
        FieldShouldBeFalseMsg: Label 'Field %1 should be false', Locked = true;
        IsInitialized: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TestApplicationAreaCache()
    var
        AllProfile: Record "All Profile";
        ApplicationAreaSetup: Record "Application Area Setup";
        UserPersonalization: Record "User Personalization";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        Cache: Dictionary of [Text, Text];
    begin
        // Setup
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup.Basic := true;
        ApplicationAreaSetup.Insert();

        // Exersice
        ApplicationAreaMgmt.GetApplicationAreas();

        // Verify
        LibraryApplicationArea.GetApplicationAreaCache(Cache);
        Assert.IsTrue(Cache.ContainsKey(''), 'Cache was expected to have an entry for Cross Company Application Area');

        // Setup
        ApplicationAreaSetup.Init();
        ApplicationAreaSetup."Company Name" := CopyStr(CompanyName(), 1, 30);
        ApplicationAreaSetup.Basic := true;

        // Exercise
        ApplicationAreaSetup.Insert();

        // Verify
        LibraryApplicationArea.GetApplicationAreaCache(Cache);
        Assert.AreEqual(0, Cache.Count(), 'Cache Was expected to be cleared after inserting on Application Area');

        // Exersice
        ApplicationAreaMgmt.GetApplicationAreas();

        // Verify
        LibraryApplicationArea.GetApplicationAreaCache(Cache);
        Assert.IsTrue(Cache.ContainsKey('Company:' + CompanyName()), 'Cache was expected to have an entry for Company specific Application Area');

        // Setup
        AllProfile.FindSet();
        repeat
            AllProfile.Validate("Default Role Center", false);
            AllProfile.Modify(true)
        until AllProfile.Next() = 0;

        AllProfile.SetRange("Profile ID", 'BUSINESS MANAGER');
        AllProfile.FindFirst();
        AllProfile.Validate("Default Role Center", true);
        AllProfile.Modify(true);

        if UserPersonalization.Get(UserSecurityId()) then
            if UserPersonalization."Profile ID" <> AllProfile."Profile ID" then begin
                UserPersonalization."Profile ID" := AllProfile."Profile ID";
                UserPersonalization.Modify();
            end;

        // Exercise
        ApplicationAreaSetup.Rename('', 'BUSINESS MANAGER', '');

        // Verify
        LibraryApplicationArea.GetApplicationAreaCache(Cache);
        Assert.AreEqual(0, Cache.Count(), 'Cache Was expected to be cleared after Renaming on Application Area');

        // Exersice
        ApplicationAreaMgmt.GetApplicationAreas();

        // Verify
        LibraryApplicationArea.GetApplicationAreaCache(Cache);
        Assert.IsTrue(Cache.ContainsKey('Profile:BUSINESS MANAGER'), 'Cache was expected to have an entry for Profile specific Application Area');

        // Exercise
        ApplicationAreaSetup.Delete();

        // Verify
        LibraryApplicationArea.GetApplicationAreaCache(Cache);
        Assert.AreEqual(0, Cache.Count(), 'Cache Was expected to be cleared after Deleting on Application Area');

        // Setup
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup.Basic := true;
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Insert();

        // Exersice
        ApplicationAreaMgmt.GetApplicationAreas();

        // Verify
        LibraryApplicationArea.GetApplicationAreaCache(Cache);
        Assert.IsTrue(Cache.ContainsKey('User:' + UserId()), 'Cache was expected to have an entry for Profile specific Application Area');

        // Exersice
        ApplicationAreaSetup.Basic := false;
        ApplicationAreaSetup.Modify();

        // Verify
        LibraryApplicationArea.GetApplicationAreaCache(Cache);
        Assert.AreEqual(0, Cache.Count(), 'Cache Was expected to be cleared after Modyfying on Application Area');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetupApplicationAreaDefaulting()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        AllProfile: Record "All Profile";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        Initialize();

        // Setup
        ApplicationAreaSetup.Basic := true;
        ApplicationAreaSetup.Insert();
        AllProfile.SetRange("Profile ID", 'BUSINESS MANAGER');
        AllProfile.FindFirst();
        AllProfile.Validate("Default Role Center", true);
        AllProfile.Modify(true);

        // Exercise and Verify
        Assert.IsTrue(StrPos(ApplicationAreaMgmtFacade.GetApplicationAreaSetup(), '#Basic') > 0, 'Tenant setting expected');
        if ApplicationAreaMgmtFacade.IsVATEnabled() then
            Assert.IsTrue(StrPos(ApplicationAreaMgmtFacade.GetApplicationAreaSetup(), '#VAT') > 0, 'Tenant setting expected');
        if ApplicationAreaMgmtFacade.IsSalesTaxEnabled() then
            Assert.IsTrue(StrPos(ApplicationAreaMgmtFacade.GetApplicationAreaSetup(), '#SalesTax') > 0, 'Tenant setting expected');

        // Setup
        Clear(ApplicationAreaSetup);
        LibraryApplicationArea.CreateFoundationSetupForCurrentCompany(ApplicationAreaSetup);

        // Exercise and Verify
        Assert.IsTrue(StrPos(ApplicationAreaMgmtFacade.GetApplicationAreaSetup(), '#Suite') > 0, 'Company setting expected');

        // Setup
        Clear(ApplicationAreaSetup);
        ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        ApplicationAreaSetup."Profile ID" := AllProfile."Profile ID";
        ApplicationAreaSetup."Fixed Assets" := true;
        ApplicationAreaSetup.Insert();

        // Exercise and Verify
        Assert.AreEqual('#FixedAssets', ApplicationAreaMgmtFacade.GetApplicationAreaSetup(), 'Profile setting expected');

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Jobs := true;
        ApplicationAreaSetup.Insert();

        // Exercise and Verify
        Assert.AreEqual('#Jobs', ApplicationAreaMgmtFacade.GetApplicationAreaSetup(), 'User setting expected');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetupApplicationAreaMultipleValues()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        Initialize();

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Basic := true;
        ApplicationAreaSetup.Suite := true;
        ApplicationAreaSetup."Fixed Assets" := true;
        ApplicationAreaSetup.Jobs := true;
        ApplicationAreaSetup."Relationship Mgmt" := true;
        ApplicationAreaSetup.Location := true;
        ApplicationAreaSetup.BasicHR := true;
        ApplicationAreaSetup.Assembly := true;
        ApplicationAreaSetup.Insert();

        // Exercise and Verify
        Assert.AreEqual('#Basic,#Suite,#RelationshipMgmt,#Jobs,#FixedAssets,#Location,#BasicHR,#Assembly',
          ApplicationAreaMgmtFacade.GetApplicationAreaSetup(), '8 comma separated areas');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetupApplicationAreaBufferDefaulting()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        AllProfile: Record "All Profile";
        TempApplicationAreaBuffer: Record "Application Area Buffer" temporary;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        Initialize();

        // Setup
        LibraryApplicationArea.CreateFoundationSetupForCurrentCompany(ApplicationAreaSetup);

        // Exercise
        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Verify
        // TODO VerifyApplicationAreaBuffer(TempApplicationAreaBuffer,ApplicationAreaSetup.FIELDNO(Suite));
        TempApplicationAreaBuffer.DeleteAll();
        ApplicationAreaSetup.DeleteAll();

        // Setup
        Clear(ApplicationAreaSetup);

        ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        ApplicationAreaSetup."Profile ID" := AllProfile."Profile ID";
        ApplicationAreaSetup."Fixed Assets" := true;
        ApplicationAreaSetup.Insert();

        // Exercise
        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Verify
        VerifyApplicationAreaBuffer(TempApplicationAreaBuffer, ApplicationAreaSetup.FieldNo("Fixed Assets"));
        TempApplicationAreaBuffer.DeleteAll();
        ApplicationAreaSetup.DeleteAll();

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Jobs := true;
        ApplicationAreaSetup.Insert();

        // Exercise
        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Verify
        VerifyApplicationAreaBuffer(TempApplicationAreaBuffer, ApplicationAreaSetup.FieldNo(Jobs));
        TempApplicationAreaBuffer.DeleteAll();
        ApplicationAreaSetup.DeleteAll();

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup."Relationship Mgmt" := true;
        ApplicationAreaSetup.Insert();

        // Exercise
        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Verify
        VerifyApplicationAreaBuffer(TempApplicationAreaBuffer, ApplicationAreaSetup.FieldNo("Relationship Mgmt"));
        TempApplicationAreaBuffer.DeleteAll();
        ApplicationAreaSetup.DeleteAll();

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Location := true;
        ApplicationAreaSetup.Insert();

        // Exercise
        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Verify
        VerifyApplicationAreaBuffer(TempApplicationAreaBuffer, ApplicationAreaSetup.FieldNo(Location));
        TempApplicationAreaBuffer.DeleteAll();
        ApplicationAreaSetup.DeleteAll();

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.BasicHR := true;
        ApplicationAreaSetup.Insert();

        // Exercise
        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Verify
        VerifyApplicationAreaBuffer(TempApplicationAreaBuffer, ApplicationAreaSetup.FieldNo(BasicHR));
        TempApplicationAreaBuffer.DeleteAll();
        ApplicationAreaSetup.DeleteAll();

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Assembly := true;
        ApplicationAreaSetup.Insert();

        // Exercise
        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Verify
        VerifyApplicationAreaBuffer(TempApplicationAreaBuffer, ApplicationAreaSetup.FieldNo(Assembly));
        TempApplicationAreaBuffer.DeleteAll();
        ApplicationAreaSetup.DeleteAll();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetApplicationAreaBufferMultipleValues()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        TempApplicationAreaBuffer: Record "Application Area Buffer" temporary;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        Initialize();

        // Setup
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Suite := true;
        ApplicationAreaSetup.Jobs := true;
        ApplicationAreaSetup.Insert();

        // Exercise
        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Verify
        TempApplicationAreaBuffer.SetRange(Selected, true);
        Assert.RecordCount(TempApplicationAreaBuffer, 2);

        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(Basic));
        Assert.IsFalse(
          TempApplicationAreaBuffer.Selected, StrSubstNo(FieldShouldBeTrueMsg, ApplicationAreaSetup.FieldName(Basic)));

        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(Suite));
        Assert.IsTrue(
          TempApplicationAreaBuffer.Selected, StrSubstNo(FieldShouldBeTrueMsg, ApplicationAreaSetup.FieldName(Suite)));

        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo("Fixed Assets"));
        Assert.IsFalse(
          TempApplicationAreaBuffer.Selected, StrSubstNo(FieldShouldBeFalseMsg, ApplicationAreaSetup.FieldName("Fixed Assets")));

        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(Jobs));
        Assert.IsTrue(
          TempApplicationAreaBuffer.Selected, StrSubstNo(FieldShouldBeTrueMsg, ApplicationAreaSetup.FieldName(Jobs)));

        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo("Relationship Mgmt"));
        Assert.IsFalse(
          TempApplicationAreaBuffer.Selected, StrSubstNo(FieldShouldBeFalseMsg, ApplicationAreaSetup.FieldName("Relationship Mgmt")));

        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(Location));
        Assert.IsFalse(
          TempApplicationAreaBuffer.Selected, StrSubstNo(FieldShouldBeFalseMsg, ApplicationAreaSetup.FieldName(Location)));

        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(BasicHR));
        Assert.IsFalse(
          TempApplicationAreaBuffer.Selected, StrSubstNo(FieldShouldBeFalseMsg, ApplicationAreaSetup.FieldName(BasicHR)));

        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(Assembly));
        Assert.IsFalse(
          TempApplicationAreaBuffer.Selected, StrSubstNo(FieldShouldBeFalseMsg, ApplicationAreaSetup.FieldName(Assembly)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTrySaveApplicationArea()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        TempApplicationAreaBuffer: Record "Application Area Buffer" temporary;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        Initialize();

        // Setup
        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Exercise and Verify
        Assert.IsFalse(
          ApplicationAreaMgmt.TrySaveApplicationAreaCurrentCompany(TempApplicationAreaBuffer),
          'No change to ApplicationArea expected');
        Assert.TableIsEmpty(DATABASE::"Application Area Setup");
        TempApplicationAreaBuffer.DeleteAll();

        // Setup
        TempApplicationAreaBuffer.Init();
        TempApplicationAreaBuffer."Field No." := ApplicationAreaSetup.FieldNo(Suite);
        TempApplicationAreaBuffer.Selected := true;
        TempApplicationAreaBuffer.Insert();

        // Exercise
        Assert.IsTrue(
          ApplicationAreaMgmt.TrySaveApplicationAreaCurrentCompany(TempApplicationAreaBuffer),
          'Change to ApplicationArea expected');
        TempApplicationAreaBuffer.DeleteAll();

        // Verify
        ApplicationAreaSetup.Get(CompanyName);
        Assert.IsTrue(ApplicationAreaSetup.Suite, 'Unexpected value in ' + ApplicationAreaSetup.FieldName(Suite));

        // Setup
        Clear(TempApplicationAreaBuffer);
        TempApplicationAreaBuffer."Field No." := ApplicationAreaSetup.FieldNo(Suite);
        TempApplicationAreaBuffer.Selected := false;
        TempApplicationAreaBuffer.Insert();

        // Exercise
        Assert.IsTrue(
          ApplicationAreaMgmt.TrySaveApplicationAreaCurrentCompany(TempApplicationAreaBuffer),
          'Change to ApplicationArea expected');

        // Verify
        ApplicationAreaSetup.Get(CompanyName());
        Assert.IsFalse(ApplicationAreaSetup.Suite, 'Unexpected value in ' + ApplicationAreaSetup.FieldName(Suite));

        // Cleanup
        ApplicationArea('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTrySaveApplicationAreaClearUserAppAreaWhenProfileAppAreaSet()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        TempApplicationAreaBuffer: Record "Application Area Buffer" temporary;
        AllProfile: Record "All Profile";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        Initialize();

        // Setup
        Clear(ApplicationAreaSetup);
        ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        ApplicationAreaSetup."Profile ID" := AllProfile."Profile ID";
        ApplicationAreaSetup.Suite := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();
        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Exercise and Verify
        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(Suite));
        TempApplicationAreaBuffer.Selected := false;
        TempApplicationAreaBuffer.Modify();
        Assert.IsTrue(
          ApplicationAreaMgmt.TrySaveApplicationAreaCurrentUser(TempApplicationAreaBuffer),
          'Shoud save Application Area from user');
        Assert.RecordCount(ApplicationAreaSetup, 2);

        // Cleanup
        ApplicationArea('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIsFoundationOnlyAndIsAdvanced()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        Initialize();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsFoundationEnabled(), 'No row, FoundationEnabled return false');
        Assert.IsTrue(ApplicationAreaMgmtFacade.IsAdvancedEnabled(), 'No row, IsAdvanced return true');

        // Setup Set Foundation
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Validate(Suite, true);
        ApplicationAreaSetup.Validate("Fixed Assets", true);
        ApplicationAreaSetup.Insert(true);
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // Exercise and Verify
        Assert.IsTrue(ApplicationAreaMgmtFacade.IsFoundationEnabled(), 'Has Foundation, FoundationEnabled return true');
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsAdvancedEnabled(), 'Has Foundation, IsAdvanced return false');

        // Setup Clear Foundation
        ApplicationAreaSetup.Suite := false;
        ApplicationAreaSetup.Modify();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsFoundationEnabled(), 'Foundation false, FoundationEnabled return false');
        Assert.IsTrue(ApplicationAreaMgmtFacade.IsAdvancedEnabled(), 'Foundation false, IsAdvanced return true');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestStartWithNonFoundation()
    var
        TempApplicationAreaBuffer: Record "Application Area Buffer" temporary;
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        Initialize();

        // Setup.
        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Exercise.
        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo("Fixed Assets"));
        TempApplicationAreaBuffer.Validate(Selected, true);
        TempApplicationAreaBuffer.Modify(true);

        // Verify.
        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(Basic));
        TempApplicationAreaBuffer.TestField(Selected);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveFoundation()
    var
        TempApplicationAreaBuffer: Record "Application Area Buffer" temporary;
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        Initialize();

        // Setup.
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Validate(Suite, true);
        ApplicationAreaSetup.Validate(Jobs, true);
        ApplicationAreaSetup.Insert(true);

        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Exercise.
        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(Basic));
        TempApplicationAreaBuffer.Validate(Selected, false);
        TempApplicationAreaBuffer.Modify(true);

        // Verify.
        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(Jobs));
        TempApplicationAreaBuffer.TestField(Selected, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveNonFoundation()
    var
        TempApplicationAreaBuffer: Record "Application Area Buffer" temporary;
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        Initialize();

        // Setup.
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Validate(Suite, true);
        ApplicationAreaSetup.Validate(Jobs, true);
        ApplicationAreaSetup.Insert(true);

        ApplicationAreaMgmt.GetApplicationAreaBuffer(TempApplicationAreaBuffer);

        // Exercise.
        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(Jobs));
        TempApplicationAreaBuffer.Validate(Selected, false);
        TempApplicationAreaBuffer.Modify(true);

        // Verify.
        TempApplicationAreaBuffer.Get(ApplicationAreaSetup.FieldNo(Suite));
        TempApplicationAreaBuffer.TestField(Selected);
    end;

    [Scope('OnPrem')]
    procedure TestSetExperienceTierCurrentCompany()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        Initialize();
        // [WHEN] Set current company to Premium experience
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Premium));

        // [THEN] current company's ApplicationArea is set to Premium experience
        ApplicationAreaSetup.Get(CompanyName());
        LibraryApplicationArea.VerifyApplicationAreaPremiumExperience(ApplicationAreaSetup);

        // [WHEN] Set current company to Essential experience
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));

        // [THEN] current company's ApplicationArea is set to Essential experience
        ApplicationAreaSetup.Get(CompanyName());
        LibraryApplicationArea.VerifyApplicationAreaEssentialExperience(ApplicationAreaSetup);

        // [WHEN] Set current company to Basic experience
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Basic));

        // [THEN] current company's ApplicationArea is set to Basic experience
        ApplicationAreaSetup.Get(CompanyName());
        LibraryApplicationArea.VerifyApplicationAreaBasicExperience(ApplicationAreaSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetExperienceTierCurrentCompanyErrorOnInvalidValues()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        Initialize();

        // Exercise and Verify
        asserterror ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Custom));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSetExperienceTierCurrentCompanyToCurrentCompanyLevel()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        Initialize();

        // [GIVEN] non-company ApplicationArea is set to Essential experience
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        ApplicationAreaMgmtFacade.GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName());
        ApplicationAreaSetup.Rename('', '', '');

        // [WHEN] Set current company to Basic experience
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Basic));

        // [THEN] non-company ApplicationArea is still set to Essential experience
        ApplicationAreaSetup.Get();
        LibraryApplicationArea.VerifyApplicationAreaEssentialExperience(ApplicationAreaSetup);

        // [THEN] current company's ApplicationArea is set to Basic experience
        ApplicationAreaSetup.Get(CompanyName());
        LibraryApplicationArea.VerifyApplicationAreaBasicExperience(ApplicationAreaSetup);
    end;

    [Test]
    [HandlerFunctions('ExperienceTiersLookupHandlerEssential')]
    [Scope('OnPrem')]
    procedure TestSettingExperienceSaaS()
    var
        TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary;
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        ExperienceTier: Text;
    begin
        Initialize();

        // Setup.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        ApplicationAreaMgmt.GetExperienceTierBuffer(TempExperienceTierBuffer);

        // Verify
        VerifyExperienceTierBufferRecords(TempExperienceTierBuffer);

        // Exercise and Verify (ModalPageHandler)
        ApplicationAreaMgmtFacade.LookupExperienceTier(ExperienceTier);
    end;

    [Test]
    [HandlerFunctions('ExperienceTiersLookupHandlerEssential')]
    [Scope('OnPrem')]
    procedure TestExperienceOnPrem()
    var
        TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary;
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        ExperienceTier: Text;
    begin
        Initialize();

        // Setup.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        ApplicationAreaMgmt.GetExperienceTierBuffer(TempExperienceTierBuffer);

        // Verify
        VerifyExperienceTierBufferRecords(TempExperienceTierBuffer);

        // Exercise and Verify (ModalPageHandler)
        ApplicationAreaMgmtFacade.LookupExperienceTier(ExperienceTier);
    end;

    [Test]
    [HandlerFunctions('ExperienceTiersLookupHandlerAdvanced')]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure TestSettingAdvancedExperience()
    var
        TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary;
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        ExperienceTier: Text;
    begin
        Initialize();

        // Setup.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        EnableSandbox();
        ApplicationAreaMgmt.GetExperienceTierBuffer(TempExperienceTierBuffer);

        // Verify
        VerifyExperienceTierBufferRecords(TempExperienceTierBuffer);

        // Exercise and Verify (ModalPageHandler)
        ApplicationAreaMgmtFacade.LookupExperienceTier(ExperienceTier);

        DisableSandbox();
    end;

    [Test]
    [HandlerFunctions('ExperienceTiersLookupHandlerEssential,SessionSettingsHandler')]
    [Scope('OnPrem')]
    procedure TestSettingExperienceSaaSFromCompanyInfo()
    var
        TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary;
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        CompanyInformation: TestPage "Company Information";
    begin
        Initialize();

        // Setup.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        ApplicationAreaMgmt.GetExperienceTierBuffer(TempExperienceTierBuffer);

        // Verify
        VerifyExperienceTierBufferRecords(TempExperienceTierBuffer);

        // Exercise and Verify (ModalPageHandler)
        CompanyInformation.OpenEdit();
        CompanyInformation.Experience.AssistEdit();
        CompanyInformation.Experience.AssertEquals(ExperienceTierSetup.FieldCaption(Essential));
        CompanyInformation.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('ExperienceTiersLookupHandler,SessionSettingsHandler')]
    [Scope('OnPrem')]
    procedure TestExperienceTierCompanyInformationWithUserAppAreas()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        CompanyInformation: TestPage "Company Information";
    begin
        Initialize();

        // Setup.
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        ApplicationAreaSetup.Get(CompanyName);
        ApplicationAreaSetup.Rename('', '', CopyStr(UserId(), 1, 50));
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Basic));

        // Exercise and Verify
        CompanyInformation.OpenEdit();
        CompanyInformation.Experience.AssertEquals(ExperienceTierSetup.FieldCaption(Basic));
        LibraryVariableStorage.Enqueue(ExperienceTierSetup.FieldCaption(Essential));
        CompanyInformation.Experience.AssistEdit();
        CompanyInformation.Close();
        CompanyInformation.OpenEdit();
        CompanyInformation.Experience.AssertEquals(ExperienceTierSetup.FieldCaption(Essential));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplicationAreaReadonly()
    var
        ApplicationArea: TestPage "Application Area";
    begin
        Initialize();

        // Exercise and Verify
        ApplicationArea.OpenEdit();
        Assert.IsFalse(ApplicationArea.Editable(), 'Application Area Page should always be read-only');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplicationAreaIsAllDisabled()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        Initialize();

        // Setup
        Clear(ApplicationAreaSetup);
        // Exercise and Verify
        Assert.IsTrue(ApplicationAreaMgmtFacade.IsAllDisabled(), 'All Application Areas are expected to be disabled.');

        // Setup
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Basic := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsAllDisabled(), 'Basic Application Area is expected to be enabled.');

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Suite := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsAllDisabled(), 'Suite Application Area is expected to be enabled.');

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup."Fixed Assets" := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsAllDisabled(), 'Fixed Assets Application Area is expected to be enabled.');

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Jobs := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsAllDisabled(), 'Jobs Application Area is expected to be enabled.');

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup."Relationship Mgmt" := true;
        ApplicationAreaSetup.Insert();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsAllDisabled(), 'Relationship Mgmt Application Area is expected to be enabled.');

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Location := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsAllDisabled(), 'Location Application Area is expected to be enabled.');

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.BasicHR := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsAllDisabled(), 'BasicHR Application Area is expected to be enabled.');

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Intercompany := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsAllDisabled(), 'Intercompany Application Area is expected to be enabled.');

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup."Item Charges" := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsAllDisabled(), 'Item Charges Application Area is expected to be enabled.');

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup.Assembly := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsAllDisabled(), 'Assembly Application Area is expected to be enabled.');

        // Setup
        Clear(ApplicationAreaSetup);
        ApplicationAreaSetup.DeleteAll();
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, 50);
        ApplicationAreaSetup."Cost Accounting" := true;
        ApplicationAreaSetup.Insert();
        ApplicationAreaMgmtFacade.SetupApplicationArea();

        // Exercise and Verify
        Assert.IsFalse(ApplicationAreaMgmtFacade.IsAllDisabled(), 'Cost Accounting Application Area is expected to be enabled.');
    end;

    [Scope('OnPrem')]
    procedure TestValidateAppAreasOnSetExperienceTierToPremium()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        TestApplicationAreaSetup: Codeunit "Test ApplicationArea Setup";
        ExperienceTier: Text;
    begin
        // [FEATURE] [Application Area]
        Initialize();

        // [GIVEN] an experience tier is set
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Basic));
        Commit();
        BindSubscription(TestApplicationAreaSetup);
        // [WHEN] the user changes experience tier
        // [WHEN] all app areas are disabled
        // [THEN] an error is thrown
        asserterror ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Premium));
        Assert.ExpectedError('Basic must be equal to ''Yes''  in Application Area Setup');

        // [THEN] the application area is not changed
        ApplicationAreaMgmtFacade.GetExperienceTierCurrentCompany(ExperienceTier);
        Assert.AreEqual(ExperienceTierSetup.FieldCaption(Basic), ExperienceTier, 'The exp tier was changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateAppAreasOnSetExperienceTierToEssential()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        TestApplicationAreaSetup: Codeunit "Test ApplicationArea Setup";
        ExperienceTier: Text;
    begin
        // [FEATURE] [Application Area]
        Initialize();

        // [GIVEN] an experience tier is set
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Basic));
        Commit();
        BindSubscription(TestApplicationAreaSetup);
        // [WHEN] the user changes experience tier
        // [WHEN] all app areas are disabled
        // [THEN] an error is thrown
        asserterror ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        Assert.ExpectedTestFieldError(ApplicationAreaSetup.FieldCaption(Basic), Format(true));

        // [THEN] the application area is not changed
        ApplicationAreaMgmtFacade.GetExperienceTierCurrentCompany(ExperienceTier);
        Assert.AreEqual(ExperienceTierSetup.FieldCaption(Basic), ExperienceTier, 'The exp tier was changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestValidateAppAreasOnSetExperienceTierToBasic()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaSetup: Record "Application Area Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        TestApplicationAreaSetup: Codeunit "Test ApplicationArea Setup";
        ExperienceTier: Text;
    begin
        // [FEATURE] [Application Area]
        Initialize();

        // [GIVEN] an experience tier is set
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
        Commit();
        BindSubscription(TestApplicationAreaSetup);
        // [WHEN] the user changes experience tier
        // [WHEN] all app areas are disabled
        // [THEN] an error is thrown
        asserterror ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Basic));
        Assert.ExpectedTestFieldError(ApplicationAreaSetup.FieldCaption(Basic), Format(true));

        // [THEN] the application area is not changed
        ApplicationAreaMgmtFacade.GetExperienceTierCurrentCompany(ExperienceTier);
        Assert.AreEqual(ExperienceTierSetup.FieldCaption(Essential), ExperienceTier, 'The exp tier was changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomExperienceTierOnCompanyInfo()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        CompanyInformation: TestPage "Company Information";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO] When the experience is set to custom, opening and closing the company info page should not throw an error
        Initialize();
        ClearLastError();

        // Setup
        ExperienceTierSetup."Company Name" := CopyStr(CompanyName(), 1, 30);
        ExperienceTierSetup.Custom := true;
        ExperienceTierSetup.Insert();

        // Exercise
        CompanyInformation.OpenEdit();

        // Verify
        CompanyInformation.Close();
        Assert.AreEqual('', GetLastErrorText(), 'no error should be thrown');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangeCustomExperienceTierOnCompanyInfoFail()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        CompanyInformation: TestPage "Company Information";
    begin
        // [FEATURE] [Application Area]
        // [SCENARIO] When the experience is changed to custom, closing the company info page should throw an error
        Initialize();
        ClearLastError();

        // Setup
        ExperienceTierSetup."Company Name" := CopyStr(CompanyName(), 1, 30);
        ExperienceTierSetup.Custom := true; // This will be loaded in Company Info as the 'new' experience tier
        ExperienceTierSetup.Insert();

        // Exercise
        CompanyInformation.OpenEdit();
        ExperienceTierSetup."Company Name" := CopyStr(CompanyName(), 1, 30);
        ExperienceTierSetup.Basic := true; // This will be considered the 'old' experience tier
        ExperienceTierSetup.Custom := false;
        ExperienceTierSetup.Modify();

        // Verify
        asserterror CompanyInformation.Close();
        Assert.ExpectedError('The selected experience is not supported.');
    end;

    [Test]
    [HandlerFunctions('ExperienceTiersLookupHandler,SessionSettingsHandler')]
    [Scope('OnPrem')]
    procedure AutoSignOutSignInWhenChangeUserExperienceInCompInformation()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        CompanyInformation: TestPage "Company Information";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 221676] Automatic sign out/sign in happens when user experience is being changed in Company Information page
        Initialize();
        MockUserHasPremiumPlan();

        // [GIVEN] User experience set to Essential
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetEssentialUserExperience();

        // [GIVEN] Open Company Information page
        CompanyInformation.OpenEdit();
        CompanyInformation.Experience.AssertEquals(ExperienceTierSetup.FieldCaption(Essential));

        // [GIVEN] Change user experience to Premium
        LibraryVariableStorage.Enqueue(ExperienceTierSetup.FieldCaption(Premium));
        CompanyInformation.Experience.AssistEdit();
        CompanyInformation.Experience.AssertEquals(ExperienceTierSetup.FieldCaption(Premium));

        // [WHEN] Page Company Information is being  closed
        CompanyInformation.OK().Invoke();

        // [THEN] Automatic sign out/sign in happens
        // The only verification available - executed SessionSettingsHandler
    end;

    [Test]
    [HandlerFunctions('ExperienceTiersLookupHandler')]
    [Scope('OnPrem')]
    procedure NoAutoSignOutSignInWhenUserExperienceInCompInformationNotChanged()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        CompanyInformation: TestPage "Company Information";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 221676] There is no automatic sign out/sign in when user experience is not changed in Company Information page
        Initialize();
        MockUserHasPremiumPlan();

        // [GIVEN] User experience set to Essential
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        SetEssentialUserExperience();

        // [GIVEN] Open Company Information page
        CompanyInformation.OpenEdit();
        CompanyInformation.Experience.AssertEquals(ExperienceTierSetup.FieldCaption(Essential));

        // [GIVEN] Change user experience to Premium
        LibraryVariableStorage.Enqueue(ExperienceTierSetup.FieldCaption(Premium));
        CompanyInformation.Experience.AssistEdit();
        CompanyInformation.Experience.AssertEquals(ExperienceTierSetup.FieldCaption(Premium));

        // [GIVEN] Change user experience back to Essential
        LibraryVariableStorage.Enqueue(ExperienceTierSetup.FieldCaption(Essential));
        CompanyInformation.Experience.AssistEdit();
        CompanyInformation.Experience.AssertEquals(ExperienceTierSetup.FieldCaption(Essential));

        // [WHEN] Page Company Information is being  closed
        CompanyInformation.OK().Invoke();

        // [THEN] No automatic sign out/sign in
        // The only verification available - SessionSettingsHandler is not executed
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralLedgerSetupApplicationTabIsBasicSuite()
    var
        GeneralLedgerSetup: TestPage "General Ledger Setup";
    begin
        // [FEATURE] [UI] [General Ledger Setup]
        // [SCENARIO 229614] There is a "#Basic,#Suite" application area for "Application" tab in general ledger setup page
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        SetBasicUserExperience();

        GeneralLedgerSetup.OpenEdit();
        Assert.IsTrue(GeneralLedgerSetup."Pmt. Disc. Tolerance Warning".Enabled(), '');
        Assert.IsTrue(GeneralLedgerSetup."Pmt. Disc. Tolerance Posting".Enabled(), '');
        Assert.IsTrue(GeneralLedgerSetup."Payment Discount Grace Period".Enabled(), '');
        Assert.IsTrue(GeneralLedgerSetup."Payment Tolerance Warning".Enabled(), '');
        Assert.IsTrue(GeneralLedgerSetup."Payment Tolerance Posting".Enabled(), '');
        Assert.IsTrue(GeneralLedgerSetup."Payment Tolerance %".Enabled(), '');
        Assert.IsTrue(GeneralLedgerSetup."Max. Payment Tolerance Amount".Enabled(), '');
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentCheckOtherJnlBatchesValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentCheckOtherJournalBatchesForSaaS()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 279398] Report 393 "Suggest Vendor Payment" request page has "CheckOtherJournalBatches" set to True for SaaS
        Initialize();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        PreparePaymentJnlLine(GenJournalLine);
        Commit();
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.Run();

        // Value collected with SuggestVendorPaymentCheckOtherJnlBatchesValueRequestPageHandler
        Assert.AreEqual('Yes', LibraryVariableStorage.DequeueText(), 'Expecting CheckOtherJournalBatches is Yes');

        LibraryVariableStorage.AssertEmpty();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentCheckOtherJnlBatchesPropertyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentCheckOtherJournalBatchesApplicationArea()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        // [FEATURE] [UI] [UT]
        // [SCENARIO 279398] Report 393 "Suggest Vendor Payment" request page has "CheckOtherJournalBatches" checkbox visible and editable
        Initialize();

        LibraryApplicationArea.EnableFoundationSetup();
        SetBasicUserExperience();

        PreparePaymentJnlLine(GenJournalLine);
        Commit();
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.Run();

        // Values collected with SuggestVendorPaymentCheckOtherJnlBatchesPropertyRequestPageHandler
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Expecting CheckOtherJournalBatches is VISIBLE');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Expecting CheckOtherJournalBatches is EDITABLE');

        LibraryVariableStorage.AssertEmpty();
        LibraryApplicationArea.DeleteExistingFoundationSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CompanyInformationResponsibilityCenter()
    var
        CompanyInformation: TestPage "Company Information";
    begin
        // [SCENARIO 290518] Field "Responsibility Center" visible on page "Company Information"
        Initialize();

        // [GIVEN] Enable Basic user experience
        SetBasicUserExperience();

        // [WHEN] Page "Company Information" is being opened
        CompanyInformation.OpenEdit();

        // [THEN] Field "Responsibility Center" visible
        Assert.IsTrue(CompanyInformation."Responsibility Center".Visible(), 'Responsibility Center should be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SpecialSalesPricesDiscountsOnItemList()
    var
        ItemList: TestPage "Item List";
    begin
        // [FEATURE] [Special Price] [Application Area] [UI]
        // [SCENARIO 324319] On the item list page there is a link to Special Price and Discount for customers in SaaS
        Initialize();

        // [GIVEN] Set Application Area = Suite
        LibraryApplicationArea.EnableFoundationSetup();

        // [WHEN] Open Item List
        ItemList.OpenEdit();

        // [THEN] Links to Orders, "Substituti&ons" and "Ledger E&ntries" are present
        Assert.IsTrue(ItemList.Action40.Visible(), '');
        Assert.IsTrue(ItemList."Substituti&ons".Visible(), '');
        Assert.IsTrue(ItemList."Ledger E&ntries".Visible(), '');
    end;

    local procedure Initialize()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
    begin
        LibraryApplicationArea.DisableApplicationAreaSetup();
        ExperienceTierSetup.DeleteAll(true);
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.AssertEmpty();

        if IsInitialized then
            exit;

        MockDisabledCompanyBankAccountUpdate();
        Commit();

        LibrarySetupStorage.Save(Database::"Company Information");

        IsInitialized := true;
    end;

    local procedure EnableSandbox()
    begin
        SetSandboxValue(true);
    end;

    local procedure DisableSandbox()
    begin
        SetSandboxValue(false);
    end;

    local procedure MockDisabledCompanyBankAccountUpdate()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."Bank Branch No." := '';
        CompanyInformation."Bank Account No." := '';
        CompanyInformation."SWIFT Code" := '';
        CompanyInformation.IBAN := '';
        CompanyInformation.Modify();
    end;

    local procedure MockUserHasPremiumPlan()
    var
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        PlanIds: Codeunit "Plan Ids";
    begin
        AzureADPlanTestLibrary.RemoveUserFromPlan(UserSecurityId(), PlanIds.GetPremiumPlanId());

        AzureADPlanTestLibrary.AssignUserToPlan(UserSecurityId(), PlanIds.GetPremiumPlanId());
    end;

    local procedure PreparePaymentJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalTemplate.Type::Payments);
        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
    end;

    local procedure SetBasicUserExperience()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Basic));
    end;

    local procedure SetEssentialUserExperience()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
    end;

    local procedure SetSandboxValue(Enable: Boolean)
    var
        LibraryPermissions: Codeunit "Library - Permissions";
    begin
        LibraryPermissions.SetTestTenantEnvironmentType(Enable);
    end;

    local procedure VerifyApplicationAreaBuffer(var TempApplicationAreaBuffer: Record "Application Area Buffer" temporary; FieldNoToBeTrue: Integer)
    var
        "Field": Record "Field";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open(DATABASE::"Application Area Setup");
        FieldRef := RecRef.FieldIndex(ApplicationAreaMgmt.GetFirstPublicAppAreaFieldIndex());
        Field.SetFilter("No.", '<%1', FieldRef.Number);
        Field.SetRange(TableNo, RecRef.Number);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Assert.RecordCount(TempApplicationAreaBuffer, RecRef.FieldCount - Field.Count);
        repeat
            if TempApplicationAreaBuffer."Field No." = FieldNoToBeTrue then
                Assert.IsTrue(TempApplicationAreaBuffer.Selected, StrSubstNo(FieldShouldBeTrueMsg, FieldNoToBeTrue))
            else
                Assert.IsFalse(TempApplicationAreaBuffer.Selected, StrSubstNo(FieldShouldBeFalseMsg, FieldNoToBeTrue))
        until TempApplicationAreaBuffer.Next() = 0;
    end;

    local procedure VerifyExperienceTierBufferRecords(var TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary)
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
    begin
        TempExperienceTierBuffer.SetRange("Experience Tier", ExperienceTierSetup.FieldCaption(Custom));
        Assert.RecordIsNotEmpty(TempExperienceTierBuffer);
        TempExperienceTierBuffer.SetRange("Experience Tier", ExperienceTierSetup.FieldCaption(Advanced));
        Assert.RecordIsNotEmpty(TempExperienceTierBuffer);
        TempExperienceTierBuffer.SetRange("Experience Tier", ExperienceTierSetup.FieldCaption(Basic));
        Assert.RecordIsNotEmpty(TempExperienceTierBuffer);
        TempExperienceTierBuffer.SetRange("Experience Tier", ExperienceTierSetup.FieldCaption(Essential));
        Assert.RecordIsNotEmpty(TempExperienceTierBuffer);
    end;

    [SessionSettingsHandler]
    [Scope('OnPrem')]
    procedure SessionSettingsHandler(var TestSessionSettings: SessionSettings): Boolean
    begin
        exit(false);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExperienceTiersLookupHandlerEssential(var ExperienceTiers: TestPage "Experience Tiers")
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
    begin
        asserterror ExperienceTiers.GotoKey(ExperienceTierSetup.FieldNo(Custom));
        Assert.ExpectedError('The row does not exist on the TestPage.');
        asserterror ExperienceTiers.GotoKey(ExperienceTierSetup.FieldNo(Advanced));
        Assert.ExpectedError('The row does not exist on the TestPage.');
        asserterror ExperienceTiers.GotoKey(ExperienceTierSetup.FieldNo(Basic));
        Assert.ExpectedError('The row does not exist on the TestPage.');
        ExperienceTiers.GotoKey(ExperienceTierSetup.FieldNo(Essential));
        ExperienceTiers."Experience Tier".AssertEquals(ExperienceTierSetup.FieldCaption(Essential));
        ExperienceTiers.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExperienceTiersLookupHandler(var ExperienceTiers: TestPage "Experience Tiers")
    var
        TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary;
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        ApplicationAreaMgmt.GetExperienceTierBuffer(TempExperienceTierBuffer);
        TempExperienceTierBuffer.SetRange("Experience Tier", LibraryVariableStorage.DequeueText());
        TempExperienceTierBuffer.FindFirst();
        ExperienceTiers.GotoKey(TempExperienceTierBuffer."Field No.");
        ExperienceTiers.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExperienceTiersLookupHandlerAdvanced(var ExperienceTiers: TestPage "Experience Tiers")
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
    begin
        asserterror ExperienceTiers.GotoKey(ExperienceTierSetup.FieldNo(Custom));
        Assert.ExpectedError('The row does not exist on the TestPage.');
        asserterror ExperienceTiers.GotoKey(ExperienceTierSetup.FieldNo(Basic));
        Assert.ExpectedError('The row does not exist on the TestPage.');
        ExperienceTiers.GotoKey(ExperienceTierSetup.FieldNo(Essential));
        ExperienceTiers."Experience Tier".AssertEquals(ExperienceTierSetup.FieldCaption(Essential));
        asserterror ExperienceTiers.GotoKey(ExperienceTierSetup.FieldNo(Advanced));
        Assert.ExpectedError('The row does not exist on the TestPage.');
        ExperienceTiers.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnGetBasicExperienceAppAreas', '', false, false)]
    local procedure ClearAppAreaSetupOnGetBasicExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup.Init()
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnGetEssentialExperienceAppAreas', '', false, false)]
    local procedure ClearAppAreaSetupOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup.Init()
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnGetPremiumExperienceAppAreas', '', false, false)]
    local procedure ClearAppAreaSetupOnGetPremiumExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup.Init()
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentCheckOtherJnlBatchesValueRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        LibraryVariableStorage.Enqueue(Format(SuggestVendorPayments.CheckOtherJournalBatches.Value));
        SuggestVendorPayments.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentCheckOtherJnlBatchesPropertyRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    begin
        LibraryVariableStorage.Enqueue(SuggestVendorPayments.CheckOtherJournalBatches.Visible());
        LibraryVariableStorage.Enqueue(SuggestVendorPayments.CheckOtherJournalBatches.Enabled());
        SuggestVendorPayments.Cancel().Invoke();
    end;
}

