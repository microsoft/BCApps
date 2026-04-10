codeunit 139088 "PowerBI Embedded Report Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetStartedVisibleWhenNoReport()
    var
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::Never);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportFailAtStartImport_NoRetry()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::StartImport);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        PowerBIEmbeddedReportPart.GetRecord(PowerBIDisplayedElement);
        AssertCU.RecordIsEmpty(PowerBIDisplayedElement);

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::Failed, 'Unexpected upload status');
        AssertCU.AreEqual(PowerBIReportUploads."Retry After", 0DT, 'Unexpected retry after');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportFailAtGetImport_NoRetry()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::GetImport);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        PowerBIEmbeddedReportPart.GetRecord(PowerBIDisplayedElement);
        AssertCU.RecordIsEmpty(PowerBIDisplayedElement);

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::Failed, 'Unexpected upload status');
        AssertCU.AreEqual(PowerBIReportUploads."Retry After", 0DT, 'Unexpected retry after');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportFailAtUpdateParams_NoRetry()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::UpdateParams);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::Completed, 'Unexpected upload status');

        AssertCU.RecordCount(PowerBIDisplayedElement, 1);
        PowerBIDisplayedElement.FindFirst();
        AssertCU.AreEqual(PowerBIDisplayedElement.ElementId, Format(PowerBIReportUploads."Uploaded Report ID"), 'Unexpected report ID');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportFailAtGetDatasource_NoRetry()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::GetDatasource);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::Completed, 'Unexpected upload status');

        AssertCU.RecordCount(PowerBIDisplayedElement, 1);
        PowerBIDisplayedElement.FindFirst();
        AssertCU.AreEqual(PowerBIDisplayedElement.ElementId, Format(PowerBIReportUploads."Uploaded Report ID"), 'Unexpected report ID');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportFailAtUpdateCreds_NoRetry()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::UpdateCreds);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::Completed, 'Unexpected upload status');

        AssertCU.RecordCount(PowerBIDisplayedElement, 1);
        PowerBIDisplayedElement.FindFirst();
        AssertCU.AreEqual(PowerBIDisplayedElement.ElementId, Format(PowerBIReportUploads."Uploaded Report ID"), 'Unexpected report ID');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportFailAtRefreshDataset_NoRetry()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::RefreshDataset);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        PowerBIEmbeddedReportPart.GetRecord(PowerBIDisplayedElement);
        AssertCU.RecordIsEmpty(PowerBIDisplayedElement);

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::Failed, 'Unexpected upload status');
        AssertCU.AreEqual(PowerBIReportUploads."Retry After", 0DT, 'Unexpected retry after');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportFailAtStartImport_WithRetry()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::StartImport);
        PowerBITestSubscriber.SetRetryDateTime(CurrentDateTime());
        PowerBITestSubscriber.SetExpectSynchronizerError(true);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        PowerBIEmbeddedReportPart.GetRecord(PowerBIDisplayedElement);
        AssertCU.RecordIsEmpty(PowerBIDisplayedElement);

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::NotStarted, 'Unexpected upload status');
        AssertCU.AreNotEqual(PowerBIReportUploads."Retry After", 0DT, 'Unexpected retry after');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportFailAtGetImport_WithRetry()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::GetImport);
        PowerBITestSubscriber.SetRetryDateTime(CurrentDateTime());
        PowerBITestSubscriber.SetExpectSynchronizerError(true);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        PowerBIEmbeddedReportPart.GetRecord(PowerBIDisplayedElement);
        AssertCU.RecordIsEmpty(PowerBIDisplayedElement);

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::ImportStarted, 'Unexpected upload status');
        AssertCU.AreNotEqual(PowerBIReportUploads."Retry After", 0DT, 'Unexpected retry after');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportFailAtUpdateParams_WithRetry()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::UpdateParams);
        PowerBITestSubscriber.SetRetryDateTime(CurrentDateTime());
        PowerBITestSubscriber.SetExpectSynchronizerError(true);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        PowerBIEmbeddedReportPart.GetRecord(PowerBIDisplayedElement);
        AssertCU.RecordIsEmpty(PowerBIDisplayedElement);

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::ImportFinished, 'Unexpected upload status');
        AssertCU.AreNotEqual(PowerBIReportUploads."Retry After", 0DT, 'Unexpected retry after');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportFailAtGetDatasource_WithRetry()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::GetDatasource);
        PowerBITestSubscriber.SetRetryDateTime(CurrentDateTime());
        PowerBITestSubscriber.SetExpectSynchronizerError(true);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        PowerBIEmbeddedReportPart.GetRecord(PowerBIDisplayedElement);
        AssertCU.RecordIsEmpty(PowerBIDisplayedElement);

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::ImportFinished, 'Unexpected upload status');
        AssertCU.AreNotEqual(PowerBIReportUploads."Retry After", 0DT, 'Unexpected retry after');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportFailAtUpdateCreds_WithRetry()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::UpdateCreds);
        PowerBITestSubscriber.SetRetryDateTime(CurrentDateTime());
        PowerBITestSubscriber.SetExpectSynchronizerError(true);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        PowerBIEmbeddedReportPart.GetRecord(PowerBIDisplayedElement);
        AssertCU.RecordIsEmpty(PowerBIDisplayedElement);

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::ImportFinished, 'Unexpected upload status');
        AssertCU.AreNotEqual(PowerBIReportUploads."Retry After", 0DT, 'Unexpected retry after');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportFailAtRefreshDataset_WithRetry()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::RefreshDataset);
        PowerBITestSubscriber.SetRetryDateTime(CurrentDateTime());
        PowerBITestSubscriber.SetExpectSynchronizerError(true);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        PowerBIEmbeddedReportPart.GetRecord(PowerBIDisplayedElement);
        AssertCU.RecordIsEmpty(PowerBIDisplayedElement);

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::ParametersUpdated, 'Unexpected upload status');
        AssertCU.AreNotEqual(PowerBIReportUploads."Retry After", 0DT, 'Unexpected retry after');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('HandleGetStartedWizard')]
    procedure TestDeployReportSuccess()
    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIEmbeddedReportPart: Page "Power BI Embedded Report Part";
        PowerBIEmbeddedReportPartTestPage: TestPage "Power BI Embedded Report Part";
    begin
        Setup();
        PowerBITestSubscriber.SetFailAtStep(FailStep::Never);
        AssertCU.TableIsEmpty(Database::"Power BI Context Settings");

        PowerBIEmbeddedReportPartTestPage.Trap();
        PowerBIEmbeddedReportPart.SetPageContext('TestContext');
        PowerBIEmbeddedReportPart.Run();

        // TODO: ideally, the following lines should also test PowerBIEmbeddedReportPartTestPage.ExpandReport.Visible(), but unfortunately dynamic visibility for actions based on enums does not work in test pages
        AssertCU.IsTrue(PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Visible(), 'Getting Started should be visible.');
        PowerBIEmbeddedReportPartTestPage.OptInGettingStarted.Drilldown();

        // Handler executes

        AssertCU.RecordCount(PowerBIReportUploads, 1);
        PowerBIReportUploads.FindFirst();
        AssertCU.AreEqual(PowerBIReportUploads."Report Upload Status", PowerBIReportUploads."Report Upload Status"::Completed, 'Unexpected upload status');

        AssertCU.RecordCount(PowerBIDisplayedElement, 1);
        PowerBIDisplayedElement.FindFirst();
        AssertCU.AreEqual(PowerBIDisplayedElement.ElementId, Format(PowerBIReportUploads."Uploaded Report ID"), 'Unexpected report ID');
    end;

    #region handlersAndHelpers

    local procedure Setup()
    var
        AzureADMgtSetup: Record "Azure AD Mgt. Setup";
        PowerBIBlob: Record "Power BI Blob";
        JobQueueEntry: Record "Job Queue Entry";
        PowerBIReportUploads: Record "Power BI Report Uploads";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        PowerBIUserConfiguration: Record "Power BI Context Settings";
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        OutStream: OutStream;
    begin
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        if UnbindSubscription(PowerBITestSubscriber) then;
        Clear(PowerBITestSubscriber);
        if BindSubscription(PowerBITestSubscriber) then;

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Power BI Report Synchronizer");
        JobQueueEntry.DeleteAll();

        PowerBIReportUploads.DeleteAll();
        PowerBIUserConfiguration.DeleteAll();
        PowerBIDisplayedElement.DeleteAll();

        PowerBIBlob.DeleteAll();
        PowerBIBlob.Init();
        PowerBIBlob.Name := 'A nice report just for test';
        PowerBIBlob.Id := PowerBIBlobIdTxt;
        PowerBIBlob."Blob File".CreateOutStream(OutStream);
        OutStream.Write('This is not really relevant');
        PowerBIBlob.Insert();

        PowerBIDefaultSelection.DeleteAll();
        PowerBIDefaultSelection.Init();
        PowerBIDefaultSelection.Id := PowerBIBlobIdTxt;
        PowerBIDefaultSelection.Context := 'TestContext';
        PowerBIDefaultSelection.Selected := true;
        PowerBIDefaultSelection.Insert();

        if not AzureADMgtSetup.Get() then begin
            AzureADMgtSetup.Init();
            AzureADMgtSetup.Insert();
        end;

        AzureADMgtSetup."Auth Flow Codeunit ID" := 0;
        AzureADMgtSetup.Modify();
    end;

    [ModalPageHandler]
    procedure HandleGetStartedWizard(var PowerBIEmbedSetupWizard: TestPage "Power BI Embed Setup Wizard")
    begin
        PowerBIEmbedSetupWizard.ActionNext.Invoke(); // Welcome -> Check license
        PowerBIEmbedSetupWizard.ActionNext.Invoke(); // Check License -> Deploy Reports
        PowerBIEmbedSetupWizard.ActionNext.Invoke(); // Deploy Reports -> Done
        PowerBIEmbedSetupWizard.ActionFinish.Invoke();
    end;

    #endregion

    var
        AssertCU: Codeunit Assert;
        PowerBITestSubscriber: Codeunit "Power BI Test Subscriber";
        PowerBIBlobIdTxt: Label 'bcbcbcbc-bcbc-bcbc-1111-000000000000', Locked = true;
        FailStep: Option NotSet,CheckLicense,StartImport,GetImport,UpdateParams,GetDatasource,UpdateCreds,RefreshDataset,Never;

}