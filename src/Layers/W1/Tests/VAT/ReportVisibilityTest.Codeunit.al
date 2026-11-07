codeunit 134095 "Report Visibility Test"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Report] [UI]
    end;

    var
        VATReportHeader: Record "VAT Report Header";
        Assert: Codeunit Assert;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ECSLReport: TestPage "ECSL Report";
        ECSLReportList: TestPage "EC Sales List Reports";
        VATReport: TestPage "VAT Report";
        VATReportList: TestPage "VAT Report List";
        PageSuggestLines: Boolean;
        PageSubmit: Boolean;
        PageMarkAsSubmitted: Boolean;
        PageRelease: Boolean;
        PageReopen: Boolean;
        PageCalcAndPost: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestECSLCardControllerVisibility()
    var
        ReportType: Enum "VAT Report Configuration";
    begin
        // [SCENARIO] For each status of the report, certain controllers is visible.
        // [GIVEN] Empty Vat report header table, ECSL report card and list page.
        LibraryLowerPermissions.SetO365Setup();
        VATReportHeader.DeleteAll();
        ReportType := VATReportHeader."VAT Report Config. Code"::"EC Sales List";
        CreateVATReportConfiguration(ReportType);

        // [WHEN] ECSL report is created with status Open and the card page is opened
        InsertVATReportHeader(ReportType);
        ECSLReportList.OpenView();

        // [THEN] Controls visibility should depend on the status of the report as following
        AssertECSLControllerVisibility(VATReportHeader.Status::Open);
        AssertECSLControllerVisibility(VATReportHeader.Status::Released);
        AssertECSLControllerVisibility(VATReportHeader.Status::Submitted);
        AssertECSLControllerVisibility(VATReportHeader.Status::Rejected);
        AssertECSLControllerVisibility(VATReportHeader.Status::Accepted);
        AssertECSLControllerVisibility(VATReportHeader.Status::Closed);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportCardControllerVisibility()
    var
        ReportType: Enum "VAT Report Configuration";
    begin
        // [SCENARIO] For each status of the report, certain controllers is visible.
        // [GIVEN] Empty Vat report header table, VAT report card and list page and VAT report configration with VAT report
        LibraryLowerPermissions.SetO365Setup();
        VATReportHeader.DeleteAll();
        ReportType := VATReportHeader."VAT Report Config. Code"::"VAT Return";
        CreateVATReportConfiguration(ReportType);

        // [WHEN] VAT report is created with status Open and the card page is opened
        InsertVATReportHeader(ReportType);
        VATReportList.OpenView();

        // [THEN] Controls visibility should depend on the status of the report as following
        AssertVATReportControllerVisibility(VATReportHeader.Status::Open);
        AssertVATReportControllerVisibility(VATReportHeader.Status::Released);
        AssertVATReportControllerVisibility(VATReportHeader.Status::Submitted);
        AssertVATReportControllerVisibility(VATReportHeader.Status::Rejected);
        AssertVATReportControllerVisibility(VATReportHeader.Status::Accepted);
        AssertVATReportControllerVisibility(VATReportHeader.Status::Closed);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewECSLReportCard()
    begin
        // [SCENARIO] When a new Card page is created, Controls should be disabled until it gets No.
        // [GIVEN] New ECSL card page.
        LibraryLowerPermissions.SetO365Setup();
        // [WHEN] New card page is opened
        ECSLReport.OpenNew();
        // [THEN] Field No should be blank and all controls should be disabled
        Assert.AreEqual(ECSLReport."No.".Value, '', 'No field should be empty for new page');
        Assert.IsFalse(ECSLReport.SuggestLines.Enabled() or ECSLReport.Release.Enabled(),
          'All control should be disabled until the page gets a value in No field');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNewVATReportCard()
    begin
        // [SCENARIO] When a new Card page is created, Controls should be disabled until it gets No.
        // [GIVEN] New VAT return card page.
        LibraryLowerPermissions.SetO365Setup();
        // [WHEN] New card page is opened
        VATReport.OpenNew();
        // [THEN] The No field is empty
        Assert.AreEqual(VATReport."No.".Value, '', 'No field should be empty for new page');
        Assert.IsFalse(VATReport.SuggestLines.Enabled() or VATReport.Release.Enabled(),
          'All control should be disabled until the page gets a value in No field');
    end;

    [Test]
    [HandlerFunctions('RPHCustomerBalanceToDate')]
    [Scope('OnPrem')]
    procedure CustomerBalanceToDateApplicationArea()
    begin
        // [FEATURE] [Application Area] [Report]
        // [SCENARIO 316751] Actions are ENABLED on '..Balance to Date' reports' request page for Basic application area
        LibraryLowerPermissions.SetO365Setup();

        // [GIVEN] Basic Applicateion are is set
        LibraryApplicationArea.EnableBasicSetup();

        // [WHEN] Run 'Vendor - Balance to Date' report
        Commit();
        REPORT.RunModal(REPORT::"Customer - Balance to Date");

        // [THEN] Actions are enabled on the request page
        Assert.IsTrue(
          LibraryVariableStorage.DequeueBoolean() and LibraryVariableStorage.DequeueBoolean() and LibraryVariableStorage.DequeueBoolean() and
          LibraryVariableStorage.DequeueBoolean() and LibraryVariableStorage.DequeueBoolean(), '');
        LibraryVariableStorage.AssertEmpty();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('RPHVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateApplicationArea()
    begin
        // [FEATURE] [Application Area] [Report]
        // [SCENARIO 316751] Actions are ENABLED on '..Balance to Date' reports' request page for Basic application area
        LibraryLowerPermissions.SetO365Setup();

        // [GIVEN] Basic Applicateion are is set
        LibraryApplicationArea.EnableBasicSetup();

        // [WHEN] Run 'Customer - Balance to Date' report
        Commit();
        REPORT.RunModal(REPORT::"Vendor - Balance to Date");

        // [THEN] Actions are enabled on the request page
        Assert.IsTrue(
          LibraryVariableStorage.DequeueBoolean() and LibraryVariableStorage.DequeueBoolean() and
          LibraryVariableStorage.DequeueBoolean() and LibraryVariableStorage.DequeueBoolean(), '');
        LibraryVariableStorage.AssertEmpty();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Scope('OnPrem')]
    procedure AssertECSLControllerVisibility(Status: Enum "VAT Report Status")
    begin
        ModifyVATReportStatus(Status);
        OpenECSLRecordCard();
        GetECSLControlStatus();
        case Status of
            VATReportHeader.Status::Open:
                begin
                    Assert.IsTrue(PageSuggestLines and PageRelease, 'Enabled controls for Open status are not correct');
                    Assert.IsFalse(
                      PageSubmit or PageMarkAsSubmitted or PageReopen,
                      'Disabled controls for Open status are not correct');
                end;
            VATReportHeader.Status::Released:
                begin
                    Assert.IsTrue(PageReopen and PageSubmit, 'Enabled controls for Released status are not correct');
                    Assert.IsFalse(
                      PageSuggestLines or PageRelease,
                      'Disabled controls for Released status are not correct');
                end;
            VATReportHeader.Status::Submitted:
                Assert.IsFalse(
                  PageSuggestLines or PageRelease or PageSubmit or PageMarkAsSubmitted or PageReopen,
                  'Disabled controls for Submitted status are not correct');
            VATReportHeader.Status::Rejected:
                Assert.IsFalse(
                  PageSuggestLines or PageRelease or PageSubmit or PageMarkAsSubmitted or PageReopen,
                  'Disabled controls for Rejected status are not correct');
            VATReportHeader.Status::Accepted:
                Assert.IsFalse(
                  PageSuggestLines or PageRelease or PageSubmit or PageMarkAsSubmitted or PageReopen,
                  'Disabled controls for Accepted status are not correct');
            VATReportHeader.Status::Closed:
                Assert.IsFalse(
                  PageSuggestLines or PageRelease or PageSubmit or PageMarkAsSubmitted or PageReopen,
                  'Disabled controls for Closed status are not correct');
        end;
        ECSLReport.Close();
    end;

    [Scope('OnPrem')]
    procedure AssertVATReportControllerVisibility(Status: Enum "VAT Report Status")
    begin
        ModifyVATReportStatus(Status);
        OpenVATReportRecordCard();
        GetVATReportControlStatus();
        case Status of
            VATReportHeader.Status::Open:
                begin
                    Assert.IsTrue(PageSuggestLines and PageRelease, 'Enabled controls for Open status are not correct');
                    Assert.IsFalse(
                      PageSubmit or
                      PageMarkAsSubmitted or PageReopen or PageCalcAndPost,
                      'Disabled controls for Open status are not correct');
                end;
            VATReportHeader.Status::Released:
                begin
                    Assert.IsTrue(PageReopen and PageSubmit and PageMarkAsSubmitted, 'Enabled controls for Released status are not correct');
                    Assert.IsFalse(
                      PageSuggestLines or PageRelease or PageCalcAndPost,
                      'Disabled controls for Released status are not correct');
                end;
            VATReportHeader.Status::Submitted:
                Assert.IsFalse(
                  PageSuggestLines or PageRelease or PageSubmit or PageMarkAsSubmitted or PageReopen or PageCalcAndPost,
                  'Disabled controls for Submitted status are not correct');
            VATReportHeader.Status::Rejected:
                Assert.IsFalse(
                  PageSuggestLines or PageRelease or PageSubmit or PageMarkAsSubmitted or PageReopen or PageCalcAndPost,
                  'Disabled controls for Rejected status are not correct');
            VATReportHeader.Status::Accepted:
                begin
                    Assert.IsTrue(
                      PageCalcAndPost, 'Enabled controls for Accepted status are not correct');
                    Assert.IsFalse(
                      PageSuggestLines or PageRelease or PageSubmit or PageMarkAsSubmitted or PageReopen,
                      'Disabled controls for Accepted status are not correct');
                end;
            VATReportHeader.Status::Closed:
                Assert.IsFalse(
                  PageSuggestLines or PageRelease or PageSubmit or PageMarkAsSubmitted or PageReopen or PageCalcAndPost,
                  'Disabled controls for Closed status are not correct');
        end;
        VATReport.Close();
    end;

    [Scope('OnPrem')]
    procedure InsertVATReportHeader(ReportType: Enum "VAT Report Configuration")
    begin
        VATReportHeader.Init();
        VATReportHeader.Validate("VAT Report Config. Code", ReportType);
        VATReportHeader.Status := VATReportHeader.Status::Open;
        VATReportHeader.Insert();
    end;

    [Scope('OnPrem')]
    procedure ModifyVATReportStatus(Status: Enum "VAT Report Status")
    begin
        VATReportHeader.Validate(Status, Status);
        VATReportHeader.Modify();
    end;

    [Scope('OnPrem')]
    procedure OpenECSLRecordCard()
    begin
        ECSLReportList.GotoRecord(VATReportHeader);
        ECSLReport.Trap();
        ECSLReportList.View().Invoke();
    end;

    [Scope('OnPrem')]
    procedure OpenVATReportRecordCard()
    begin
        VATReportList.GotoRecord(VATReportHeader);
        VATReport.Trap();
        VATReportList.View().Invoke();
    end;

    [Scope('OnPrem')]
    procedure CreateVATReportConfiguration(ReportType: Enum "VAT Report Configuration")
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        VATReportsConfiguration.DeleteAll();
        VATReportsConfiguration.Init();
        VATReportsConfiguration.Validate("VAT Report Type", ReportType);
        VATReportsConfiguration.Insert();
    end;

    [Scope('OnPrem')]
    procedure GetECSLControlStatus()
    begin
        PageSuggestLines := ECSLReport.SuggestLines.Enabled();
        PageRelease := ECSLReport.Release.Enabled();
        PageSubmit := ECSLReport.Submit.Enabled();
        PageReopen := ECSLReport.Reopen.Enabled();
    end;

    [Scope('OnPrem')]
    procedure GetVATReportControlStatus()
    begin
        PageSuggestLines := VATReport.SuggestLines.Enabled();
        PageSubmit := VATReport.Submit.Enabled();
        PageMarkAsSubmitted := VATReport."Mark as Submitted".Enabled();
        PageRelease := VATReport.Release.Enabled();
        PageReopen := VATReport.Reopen.Enabled();
        PageCalcAndPost := VATReport."Calc. and Post VAT Settlement".Enabled();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHCustomerBalanceToDate(var CustomerBalanceToDate: TestRequestPage "Customer - Balance to Date")
    begin
        LibraryVariableStorage.Enqueue(CustomerBalanceToDate."Ending Date".Enabled());
        LibraryVariableStorage.Enqueue(CustomerBalanceToDate.PrintAmountInLCY.Enabled());
        LibraryVariableStorage.Enqueue(CustomerBalanceToDate.PrintOnePrPage.Enabled());
        LibraryVariableStorage.Enqueue(CustomerBalanceToDate.PrintUnappliedEntries.Enabled());
        LibraryVariableStorage.Enqueue(CustomerBalanceToDate.ShowEntriesWithZeroBalance.Enabled());
        CustomerBalanceToDate.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHVendorBalanceToDate(var VendorBalanceToDate: TestRequestPage "Vendor - Balance to Date")
    begin
        LibraryVariableStorage.Enqueue(VendorBalanceToDate.ShowAmountsInLCY.Enabled());
        LibraryVariableStorage.Enqueue(VendorBalanceToDate.PrintOnePrPage.Enabled());
        LibraryVariableStorage.Enqueue(VendorBalanceToDate.PrintUnappliedEntries.Enabled());
        LibraryVariableStorage.Enqueue(VendorBalanceToDate.ShowEntriesWithZeroBalance.Enabled());
        VendorBalanceToDate.Cancel().Invoke();
    end;
}

