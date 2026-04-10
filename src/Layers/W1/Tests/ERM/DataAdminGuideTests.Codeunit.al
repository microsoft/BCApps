codeunit 134133 "Data Admin. Guide Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        DataAdminGuidePage: Enum "Data Administration Guide Page";
        CurrentDataAdminGuidePage: Enum "Data Administration Guide Page";
        DataAdminGuidePages: List of [Enum "Data Administration Guide Page"];
        DataAdminGuideSkipTo: Dictionary of [Enum "Data Administration Guide Page", Enum "Data Administration Guide Page"];
        DataAdminGuideHideNext: List of [Enum "Data Administration Guide Page"];

    [Test]
    procedure TestDataAdminGuidePages()
    var
        DataAdministrationGuide: TestPage "Data Administration Guide";
        DataAdminGuideTests: Codeunit "Data Admin. Guide Tests";
    begin
        // Setup
        BindSubscription(DataAdminGuideTests);

        // Exercise
        DataAdministrationGuide.OpenView();
        DataAdminGuideTests.GetGlobals(CurrentDataAdminGuidePage, DataAdminGuidePages, DataAdminGuideSkipTo);

        // Verify
        Assert.AreEqual(1, DataAdminGuidePages.IndexOf(DataAdminGuidePage::Introduction), 'The intro page should be first');
        Assert.AreEqual(2, DataAdminGuidePages.IndexOf(DataAdminGuidePage::RetenPolIntro), 'The page is not in at the right index');
        Assert.AreEqual(3, DataAdminGuidePages.IndexOf(DataAdminGuidePage::CompaniesIntro), 'The page is not in at the right index');
        Assert.AreEqual(4, DataAdminGuidePages.IndexOf(DataAdminGuidePage::DateCompressionIntro), 'The page is not in at the right index');
        Assert.AreEqual(5, DataAdminGuidePages.IndexOf(DataAdminGuidePage::DateCompressionSelection), 'The page is not in at the right index');
        Assert.AreEqual(6, DataAdminGuidePages.IndexOf(DataAdminGuidePage::DateCompressionOptions), 'The page is not in at the right index');
        Assert.AreEqual(7, DataAdminGuidePages.IndexOf(DataAdminGuidePage::DateCompressionOptions2), 'The page is not in at the right index');
        Assert.AreEqual(8, DataAdminGuidePages.IndexOf(DataAdminGuidePage::DateCompressionRun), 'The page is not in at the right index');
        Assert.AreEqual(DataAdminGuidePages.Count(), DataAdminGuidePages.IndexOf(DataAdminGuidePage::Conclusion), 'The conclusion page should be last');
    end;

    [Test]
    procedure TestDataAdminGuideSkipTo()
    var
        DataAdministrationGuide: TestPage "Data Administration Guide";
        DataAdminGuideTests: Codeunit "Data Admin. Guide Tests";
    begin
        // Setup
        BindSubscription(DataAdminGuideTests);

        // Exercise
        DataAdministrationGuide.OpenView();
        DataAdminGuideTests.GetGlobals(CurrentDataAdminGuidePage, DataAdminGuidePages, DataAdminGuideSkipTo);

        // Verify
        Assert.IsTrue(DataAdminGuideSkipTo.ContainsKey(DataAdminGuidePage::DateCompressionIntro), 'DateCompressionIntro should be in the SkipTo pages');
        Assert.AreEqual(DataAdminGuidePage::Conclusion, DataAdminGuideSkipTo.Get(DataAdminGuidePage::DateCompressionIntro), 'DateCompressionIntro should skip to Conclusion');
    end;

    [Test]
    procedure TestDataAdminGuideNextStep()
    var
        DataAdministrationGuide: TestPage "Data Administration Guide";
        DataAdminGuideTests: Codeunit "Data Admin. Guide Tests";
    begin
        // Setup
        BindSubscription(DataAdminGuideTests);

        // Exercise
        DataAdministrationGuide.OpenView();
        DataAdminGuideTests.GetGlobals(CurrentDataAdminGuidePage, DataAdminGuidePages, DataAdminGuideSkipTo);

        // Verify
        Assert.AreEqual(DataAdminGuidePage::Introduction, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::RetenPolIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::CompaniesIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsTrue(DataAdministrationGuide.Skip.Visible(), 'Skip action is not visible');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionSelection, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionOptions, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionOptions2, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionRun, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsTrue(DataAdministrationGuide.DateCompress.Visible(), 'Compress Entries (Next) action is not visible');
        Assert.IsFalse(DataAdministrationGuide.Next.Visible(), 'Next action is visible');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionResult, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::Conclusion, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsTrue(DataAdministrationGuide.Finish.Visible(), 'Finish action is not visible');
        Assert.IsFalse(DataAdministrationGuide.Next.Enabled(), 'Next action is enabled');
    end;

    [Test]
    procedure TestDataAdminGuidePreviousStep()
    var
        DataAdministrationGuide: TestPage "Data Administration Guide";
        DataAdminGuideTests: Codeunit "Data Admin. Guide Tests";
    begin
        // Setup
        BindSubscription(DataAdminGuideTests);

        // Exercise
        DataAdministrationGuide.OpenView();
        DataAdminGuideTests.GetGlobals(CurrentDataAdminGuidePage, DataAdminGuidePages, DataAdminGuideSkipTo);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);

        // Verify
        Assert.AreEqual(DataAdminGuidePage::Conclusion, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsTrue(DataAdministrationGuide.Finish.Visible(), 'Finish action is not visible');
        Assert.IsTrue(DataAdministrationGuide.Previous.Enabled(), 'Previous action is not enabled');
        Assert.IsFalse(DataAdministrationGuide.Next.Enabled(), 'Next action is enabled');

        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionResult, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionRun, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionOptions2, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionOptions, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionSelection, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::CompaniesIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::RetenPolIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::Introduction, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsFalse(DataAdministrationGuide.Previous.Enabled(), 'Previous action is enabled');
    end;

    [Test]
    procedure TestDataAdminGuideSkipStep()
    var
        DataAdministrationGuide: TestPage "Data Administration Guide";
        DataAdminGuideTests: Codeunit "Data Admin. Guide Tests";
    begin
        // Setup
        BindSubscription(DataAdminGuideTests);

        // Exercise
        DataAdministrationGuide.OpenView();
        DataAdminGuideTests.GetGlobals(CurrentDataAdminGuidePage, DataAdminGuidePages, DataAdminGuideSkipTo);

        // Verify
        Assert.AreEqual(DataAdminGuidePage::Introduction, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::RetenPolIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::CompaniesIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsTrue(DataAdministrationGuide.Skip.Visible(), 'Skip action is not visible');
        InvokeSkipAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.IsTrue(DataAdministrationGuide.Finish.Visible(), 'Finish action is not visible');
    end;

    [Test]
    procedure TestExtDataAdminGuidePages()
    var
        DataAdministrationGuide: TestPage "Data Administration Guide";
        DataAdminGuideTests: Codeunit "Data Admin. Guide Tests";
        DataAdminGuideExtTests: Codeunit "Data Admin. Guide Ext. Tests";
    begin
        // Setup
        BindSubscription(DataAdminGuideTests);
        BindSubscription(DataAdminGuideExtTests);

        // Exercise
        DataAdministrationGuide.OpenView();
        DataAdminGuideTests.GetGlobals(CurrentDataAdminGuidePage, DataAdminGuidePages, DataAdminGuideSkipTo);

        // Verify
        Assert.AreEqual(1, DataAdminGuidePages.IndexOf(DataAdminGuidePage::Introduction), 'The intro page should be first');
        Assert.AreEqual(2, DataAdminGuidePages.IndexOf(DataAdminGuidePage::TestGuidePage1), 'The page is not in at the right index');
        Assert.AreEqual(3, DataAdminGuidePages.IndexOf(DataAdminGuidePage::RetenPolIntro), 'The page is not in at the right index');
        Assert.AreEqual(4, DataAdminGuidePages.IndexOf(DataAdminGuidePage::CompaniesIntro), 'The page is not in at the right index');
        Assert.AreEqual(5, DataAdminGuidePages.IndexOf(DataAdminGuidePage::TestGuidePage2), 'The page is not in at the right index');
        Assert.AreEqual(6, DataAdminGuidePages.IndexOf(DataAdminGuidePage::DateCompressionIntro), 'The page is not in at the right index');
        Assert.AreEqual(7, DataAdminGuidePages.IndexOf(DataAdminGuidePage::DateCompressionSelection), 'The page is not in at the right index');
        Assert.AreEqual(8, DataAdminGuidePages.IndexOf(DataAdminGuidePage::DateCompressionOptions), 'The page is not in at the right index');
        Assert.AreEqual(9, DataAdminGuidePages.IndexOf(DataAdminGuidePage::DateCompressionOptions2), 'The page is not in at the right index');
        Assert.AreEqual(10, DataAdminGuidePages.IndexOf(DataAdminGuidePage::DateCompressionRun), 'The page is not in at the right index');
        Assert.AreEqual(DataAdminGuidePages.Count(), DataAdminGuidePages.IndexOf(DataAdminGuidePage::Conclusion), 'The conclusion page should be last');
    end;

    [Test]
    procedure TestExtDataAdminGuideSkipTo()
    var
        DataAdministrationGuide: TestPage "Data Administration Guide";
        DataAdminGuideTests: Codeunit "Data Admin. Guide Tests";
        DataAdminGuideExtTests: Codeunit "Data Admin. Guide Ext. Tests";
    begin
        // Setup
        BindSubscription(DataAdminGuideTests);
        BindSubscription(DataAdminGuideExtTests);

        // Exercise
        DataAdministrationGuide.OpenView();
        DataAdminGuideTests.GetGlobals(CurrentDataAdminGuidePage, DataAdminGuidePages, DataAdminGuideSkipTo);

        // Verify
        Assert.IsTrue(DataAdminGuideSkipTo.ContainsKey(DataAdminGuidePage::DateCompressionIntro), 'DateCompressionIntro should be in the SkipTo pages');
        Assert.AreEqual(DataAdminGuidePage::Conclusion, DataAdminGuideSkipTo.Get(DataAdminGuidePage::DateCompressionIntro), 'DateCompressionIntro should skip to Conclusion');
        Assert.IsTrue(DataAdminGuideSkipTo.ContainsKey(DataAdminGuidePage::TestGuidePage2), 'TestGuidePage2 should be in the SkipTo pages');
        Assert.AreEqual(DataAdminGuidePage::Conclusion, DataAdminGuideSkipTo.Get(DataAdminGuidePage::TestGuidePage2), 'TestGuidePage2 should skip to DateCompressionRun');
    end;

    [Test]
    procedure TestExtDataAdminGuideNextStep()
    var
        DataAdministrationGuide: TestPage "Data Administration Guide";
        DataAdminGuideTests: Codeunit "Data Admin. Guide Tests";
        DataAdminGuideExtTests: Codeunit "Data Admin. Guide Ext. Tests";
    begin
        // Setup
        BindSubscription(DataAdminGuideTests);
        BindSubscription(DataAdminGuideExtTests);

        // Exercise
        DataAdministrationGuide.OpenView();
        DataAdminGuideTests.GetGlobals(CurrentDataAdminGuidePage, DataAdminGuidePages, DataAdminGuideSkipTo);

        // Verify
        Assert.AreEqual(DataAdminGuidePage::Introduction, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::TestGuidePage1, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsTrue(DataAdministrationGuide.ERMTestsField1.Visible(), 'ERMTestsField1 is not visible');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::RetenPolIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::CompaniesIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::TestGuidePage2, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsTrue(DataAdministrationGuide.ERMTestsField2.Visible(), 'ERMTestsField2 is not visible');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsTrue(DataAdministrationGuide.Skip.Visible(), 'Skip action is not visible');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionSelection, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionOptions, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionOptions2, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionRun, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsTrue(DataAdministrationGuide.DateCompress.Visible(), 'Compress Entries action is not visible');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionResult, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::Conclusion, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsTrue(DataAdministrationGuide.Finish.Visible(), 'Finish action is not visible');
        Assert.IsFalse(DataAdministrationGuide.Next.Enabled(), 'Next action is enabled');
    end;

    [Test]
    procedure TestExtDataAdminGuidePreviousStep()
    var
        DataAdministrationGuide: TestPage "Data Administration Guide";
        DataAdminGuideTests: Codeunit "Data Admin. Guide Tests";
        DataAdminGuideExtTests: Codeunit "Data Admin. Guide Ext. Tests";
    begin
        // Setup
        BindSubscription(DataAdminGuideTests);
        BindSubscription(DataAdminGuideExtTests);

        // Exercise
        DataAdministrationGuide.OpenView();
        DataAdminGuideTests.GetGlobals(CurrentDataAdminGuidePage, DataAdminGuidePages, DataAdminGuideSkipTo);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);

        // Verify
        Assert.AreEqual(DataAdminGuidePage::Conclusion, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsTrue(DataAdministrationGuide.Finish.Visible(), 'Finish action is not visible');
        Assert.IsTrue(DataAdministrationGuide.Previous.Enabled(), 'Previous action is not enabled');
        Assert.IsFalse(DataAdministrationGuide.Next.Enabled(), 'Next action is enabled');

        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionResult, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionRun, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionOptions2, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionOptions, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionSelection, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::DateCompressionIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::TestGuidePage2, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::CompaniesIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::RetenPolIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::TestGuidePage1, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokePreviousAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::Introduction, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsFalse(DataAdministrationGuide.Previous.Enabled(), 'Previous action is enabled');
    end;

    [Test]
    procedure TestExtDataAdminGuideSkipStep()
    var
        DataAdministrationGuide: TestPage "Data Administration Guide";
        DataAdminGuideTests: Codeunit "Data Admin. Guide Tests";
        DataAdminGuideExtTests: Codeunit "Data Admin. Guide Ext. Tests";
    begin
        // Setup
        BindSubscription(DataAdminGuideTests);
        BindSubscription(DataAdminGuideExtTests);

        // Exercise
        DataAdministrationGuide.OpenView();
        DataAdminGuideTests.GetGlobals(CurrentDataAdminGuidePage, DataAdminGuidePages, DataAdminGuideSkipTo);

        // Verify
        Assert.AreEqual(DataAdminGuidePage::Introduction, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::TestGuidePage1, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::RetenPolIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::CompaniesIntro, CurrentDataAdminGuidePage, 'Wrong page is selected');
        InvokeNextAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.AreEqual(DataAdminGuidePage::TestGuidePage2, CurrentDataAdminGuidePage, 'Wrong page is selected');
        Assert.IsTrue(DataAdministrationGuide.Skip.Visible(), 'Skip action is not visible');
        InvokeSkipAndGetCurrentPage(DataAdministrationGuide, DataAdminGuideTests);
        Assert.IsTrue(DataAdministrationGuide.Finish.Visible(), 'Finish action is not visible');
    end;

    /// <summary>
    /// Invokes the Next action and retrieves the new CurrentPage from the manual event subscriber instance
    /// </summary>
    local procedure InvokeNextAndGetCurrentPage(var DataAdministrationGuide: TestPage "Data Administration Guide"; DataAdminGuideTests: Codeunit "Data Admin. Guide Tests")
    begin
        DataAdministrationGuide.Next.Invoke();
        DataAdminGuideTests.GetCurrentDataAdminGuidePage(CurrentDataAdminGuidePage);
    end;

    /// <summary>
    /// Invokes the Previous action and retrieves the new CurrentPage from the manual event subscriber instance
    /// </summary>
    local procedure InvokePreviousAndGetCurrentPage(var DataAdministrationGuide: TestPage "Data Administration Guide"; DataAdminGuideTests: Codeunit "Data Admin. Guide Tests")
    begin
        DataAdministrationGuide.Previous.Invoke();
        DataAdminGuideTests.GetCurrentDataAdminGuidePage(CurrentDataAdminGuidePage);
    end;

    /// <summary>
    /// Invokes the Skip action and retrieves the new CurrentPage from the manual event subscriber instance
    /// </summary>
    local procedure InvokeSkipAndGetCurrentPage(var DataAdministrationGuide: TestPage "Data Administration Guide"; DataAdminGuideTests: Codeunit "Data Admin. Guide Tests")
    begin
        DataAdministrationGuide.Skip.Invoke();
        DataAdminGuideTests.GetCurrentDataAdminGuidePage(CurrentDataAdminGuidePage);
    end;

    /// <summary>
    /// Assigns the global values from the manual subscriber instance to the parameters to transfer the values to the current codeunit instance.
    /// </summary>
    internal procedure GetGlobals(var CurrentDataAdminGuidePage2: Enum "Data Administration Guide Page"; var DataAdminGuidePages2: List of [Enum "Data Administration Guide Page"]; var DataAdminGuideSkipTo2: Dictionary of [Enum "Data Administration Guide Page", Enum "Data Administration Guide Page"])
    begin
        GetCurrentDataAdminGuidePage(CurrentDataAdminGuidePage2);
        DataAdminGuidePages2 := DataAdminGuidePages;
        DataAdminGuideSkipTo2 := DataAdminGuideSkipTo;
    end;

    /// <summary>
    /// Assigns the global value from the manual subscriber instance to the parameter to transfer the value to the current codeunit instance.
    /// </summary>
    internal procedure GetCurrentDataAdminGuidePage(var CurrentDataAdminGuidePage2: Enum "Data Administration Guide Page")
    begin
        CurrentDataAdminGuidePage2 := CurrentDataAdminGuidePage;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Data Administration Guide", 'OnAfterLoadPages', '', false, false)]
    local procedure SetGlobalsOnAfterLoadPages(var GuidePages: List of [Enum "Data Administration Guide Page"]; var SkipTo: Dictionary of [Enum "Data Administration Guide Page", Enum "Data Administration Guide Page"]; var HideNext: List of [Enum "Data Administration Guide Page"])
    begin
        DataAdminGuidePages := GuidePages;
        DataAdminGuideSkipTo := SkipTo;
        DataAdminGuideHideNext := HideNext;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Data Administration Guide", 'OnAfterUpdateControls', '', false, false)]
    local procedure SetGlobalsOnAfterUpdateControls(CurrentPage: Enum "Data Administration Guide Page")
    begin
        CurrentDataAdminGuidePage := CurrentPage;
    end;
}