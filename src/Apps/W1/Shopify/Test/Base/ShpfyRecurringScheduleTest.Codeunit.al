// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;
using System.Threading;

codeunit 139649 "Shpfy Recurring Schedule Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        ScheduleMgt: Codeunit "Shpfy Recurring Schedule Mgt.";

    #region Tests
    [Test]
    procedure GuideStepsUseOnlyBackNextAndFinish()
    var
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
        WelcomeBackErr: Label 'Back must be disabled on the Welcome step.';
        WelcomeFinishErr: Label 'Finish must be disabled on the Welcome step.';
        WelcomeNextErr: Label 'Next must be enabled on the Welcome step.';
        SelectionBackErr: Label 'Back must be enabled on the selection step.';
        SelectionFinishErr: Label 'Finish must be enabled on the selection step.';
        SelectionNextErr: Label 'Next must be disabled on the selection step.';
    begin
        //[SCENARIO] Guide steps use only Back, Next, and Finish.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop, 'SCHEDSTEPS');

        //[GIVEN] The guide is initialized for the shop.
        RecurringSyncGuide.SetShop(ShopifyShop);

        //[GIVEN] The guide page is trapped.
        GuidePage.Trap();

        //[WHEN] The guide opens.
        RecurringSyncGuide.Run();

        //[THEN] Back is disabled on the Welcome step.
        this.LibraryAssert.IsFalse(GuidePage.ActionBack.Enabled(), WelcomeBackErr);

        //[THEN] Next is enabled on the Welcome step.
        this.LibraryAssert.IsTrue(GuidePage.ActionNext.Enabled(), WelcomeNextErr);

        //[THEN] Finish is disabled on the Welcome step.
        this.LibraryAssert.IsFalse(GuidePage.ActionFinish.Enabled(), WelcomeFinishErr);

        //[WHEN] Next opens the selection step.
        GuidePage.ActionNext.Invoke();

        //[THEN] Back is enabled on the selection step.
        this.LibraryAssert.IsTrue(GuidePage.ActionBack.Enabled(), SelectionBackErr);

        //[THEN] Next is disabled on the selection step.
        this.LibraryAssert.IsFalse(GuidePage.ActionNext.Enabled(), SelectionNextErr);

        //[THEN] Finish is enabled on the selection step.
        this.LibraryAssert.IsTrue(GuidePage.ActionFinish.Enabled(), SelectionFinishErr);

        //[WHEN] Back returns to the Welcome step.
        GuidePage.ActionBack.Invoke();

        //[THEN] Next is enabled again.
        this.LibraryAssert.IsTrue(GuidePage.ActionNext.Enabled(), WelcomeNextErr);

        //[THEN] The guide can be closed without creating schedules.
        GuidePage.Close();
    end;

    [Test]
    procedure FinishRequiresSelection()
    var
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
        NoSelectionFinishErr: Label 'Finish must be disabled when no synchronization is selected.';
        SelectedFinishErr: Label 'Finish must be enabled after selecting a ready synchronization.';
    begin
        //[SCENARIO] Finish requires at least one selected synchronization.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop, 'SCHEDSELECT');

        //[GIVEN] The guide is initialized for the shop.
        RecurringSyncGuide.SetShop(ShopifyShop);

        //[GIVEN] The guide page is trapped.
        GuidePage.Trap();

        //[GIVEN] The guide opens.
        RecurringSyncGuide.Run();

        //[GIVEN] The selection step is opened.
        GuidePage.ActionNext.Invoke();

        //[GIVEN] Every selectable workload is cleared.
        this.ClearScheduleSelections(GuidePage);

        //[THEN] Finish is disabled without a selected workload.
        this.LibraryAssert.IsFalse(GuidePage.ActionFinish.Enabled(), NoSelectionFinishErr);

        //[WHEN] A ready workload is selected again.
        GuidePage.SelectionPart.First();
        GuidePage.SelectionPart.Selected.SetValue(true);

        //[THEN] Finish is enabled again.
        this.LibraryAssert.IsTrue(GuidePage.ActionFinish.Enabled(), SelectedFinishErr);
        GuidePage.Close();
    end;

    [Test]
    [HandlerFunctions('FrequencyMessageHandler')]
    procedure FinishRequiresValidFrequency()
    var
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
        InvalidFrequencyFinishErr: Label 'Finish must be disabled when any selected synchronization has a nonpositive frequency.';
        ValidFrequencyFinishErr: Label 'Finish must be enabled after correcting every selected frequency.';
        UnselectedFrequencyFinishErr: Label 'An invalid frequency on an unselected synchronization must not disable Finish.';
    begin
        //[SCENARIO] An invalid frequency shows a message and blocks Finish.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop, 'SCHEDFREQ');

        //[GIVEN] The guide is initialized for the shop.
        RecurringSyncGuide.SetShop(ShopifyShop);

        //[GIVEN] The guide page is trapped.
        GuidePage.Trap();

        //[GIVEN] The guide opens.
        RecurringSyncGuide.Run();

        //[GIVEN] The selection step is opened.
        GuidePage.ActionNext.Invoke();

        //[GIVEN] The first workload is current.
        GuidePage.SelectionPart.First();

        //[GIVEN] The selected workload has an invalid frequency.
        GuidePage.SelectionPart.Frequency.SetValue(0);

        //[THEN] Finish is disabled.
        this.LibraryAssert.IsFalse(GuidePage.ActionFinish.Enabled(), InvalidFrequencyFinishErr);

        //[WHEN] Another row becomes current.
        GuidePage.SelectionPart.Next();

        //[THEN] The invalid selected frequency still disables Finish.
        this.LibraryAssert.IsFalse(GuidePage.ActionFinish.Enabled(), InvalidFrequencyFinishErr);

        //[WHEN] The invalid workload is deselected.
        GuidePage.SelectionPart.First();
        GuidePage.SelectionPart.Selected.SetValue(false);

        //[THEN] The remaining valid selected workloads enable Finish.
        this.LibraryAssert.IsTrue(GuidePage.ActionFinish.Enabled(), UnselectedFrequencyFinishErr);

        //[WHEN] The invalid workload is selected again.
        GuidePage.SelectionPart.Selected.SetValue(true);

        //[THEN] Finish is disabled again.
        this.LibraryAssert.IsFalse(GuidePage.ActionFinish.Enabled(), InvalidFrequencyFinishErr);

        //[WHEN] The invalid frequency is corrected.
        GuidePage.SelectionPart.Frequency.SetValue(1440);

        //[THEN] Finish is enabled again.
        this.LibraryAssert.IsTrue(GuidePage.ActionFinish.Enabled(), ValidFrequencyFinishErr);

        //[WHEN] A selected frequency is negative.
        GuidePage.SelectionPart.Frequency.SetValue(-1);

        //[THEN] Finish is disabled for negative frequencies too.
        this.LibraryAssert.IsFalse(GuidePage.ActionFinish.Enabled(), InvalidFrequencyFinishErr);
        GuidePage.Close();
    end;

    [Test]
    procedure FinishIsDisabledWhenOnlyUnavailableWorkloadsRemain()
    var
        JobQueueCategory: Record "Job Queue Category";
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        TempRecommendations: Record "Shpfy Recurring Sync Buffer" temporary;
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
        NoReadyWorkloadsErr: Label 'Finish must be disabled when all ready workloads are already scheduled.';
    begin
        //[SCENARIO] Finish is disabled when only unavailable workloads remain.

        //[GIVEN] No recurring Shopify synchronization job queue entries or test shops exist.
        this.Initialize();

        //[GIVEN] A shop with incomplete synchronization setup exists.
        this.CreateShop(ShopifyShop, 'SCHEDUNAVAILABLE');

        //[GIVEN] Every ready workload is already scheduled.
        JobQueueCategory.InsertRec('SHPFY', 'Shopify');
        this.ScheduleMgt.BuildRecommendations(ShopifyShop, TempRecommendations);
        TempRecommendations.SetRange(Selectable, true);
        if TempRecommendations.FindSet(false) then
            repeat
                this.ScheduleMgt.CreateJobQueueEntry(ShopifyShop, TempRecommendations, TempRecommendations.Frequency, JobQueueEntry);
            until TempRecommendations.Next() = 0;

        //[GIVEN] The guide is initialized and opened for the shop.
        RecurringSyncGuide.SetShop(ShopifyShop);
        GuidePage.Trap();
        RecurringSyncGuide.Run();

        //[WHEN] The selection step is opened.
        GuidePage.ActionNext.Invoke();

        //[THEN] Finish is disabled.
        this.LibraryAssert.IsFalse(GuidePage.ActionFinish.Enabled(), NoReadyWorkloadsErr);
        GuidePage.Close();
    end;

    [Test]
    procedure ShopifyAdminUsesIndirectJobQueuePermissions()
    var
        JobQueueCategory: Record "Job Queue Category";
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        TempJobQueueEntryBuffer: Record "Job Queue Entry" temporary;
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        CreatedEntryID: Guid;
        ScheduleListedErr: Label 'Shopify Admin must be able to create and list Shopify schedules through the connector.';
    begin
        //[SCENARIO] Shopify Admin uses indirect Job Queue permissions.

        //[GIVEN] No recurring Shopify synchronization job queue entries or test shops exist.
        this.Initialize();

        //[GIVEN] A shop ready for product synchronization and the Shopify job queue category exist.
        this.CreateProductsToShopifyShop(ShopifyShop, 'SCHEDPERMISSIONS');
        JobQueueCategory.InsertRec('SHPFY', 'Shopify');

        //[GIVEN] Only Shopify Admin and object execution permissions are assigned.
        this.PermissionsMock.Start();
        this.PermissionsMock.Set('Shpfy - Admin');

        //[WHEN] A Shopify schedule is created through the connector.
        this.CreateScheduleForWorkload(ShopifyShop, Enum::"Shpfy Sync Workload"::Products, 1440, JobQueueEntry);
        CreatedEntryID := JobQueueEntry.ID;

        //[WHEN] Shopify schedules are listed through the connector.
        this.ScheduleMgt.BuildExistingScheduleEntries(ShopifyShop, TempJobQueueEntryBuffer, TempRecurringSyncBuffer);

        //[THEN] The created Shopify schedule can be listed without direct table permissions.
        this.LibraryAssert.IsTrue(TempJobQueueEntryBuffer.Get(CreatedEntryID), ScheduleListedErr);

        //[THEN] Direct access to Job Queue Entries is denied.
        asserterror JobQueueEntry.FindFirst();
        this.LibraryAssert.ExpectedErrorCode('DB:ClientReadDenied');

        //[THEN] Direct modification of the created entry is denied.
        asserterror JobQueueEntry.Modify(false);
        this.LibraryAssert.ExpectedErrorCode('DB:ClientModifyDenied');

        //[THEN] Direct access to Job Queue Categories is denied.
        asserterror JobQueueCategory.FindFirst();
        this.LibraryAssert.ExpectedErrorCode('DB:ClientReadDenied');

        this.PermissionsMock.Stop();
    end;

    [Test]
    procedure ReadyWorkloadStatusDoesNotOpenSetup()
    var
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        ShopifyShop: Record "Shpfy Shop";
        SetupOpened: Boolean;
        ProductRowVisibleErr: Label 'The products row must be recommended.';
        SetupOpenedErr: Label 'A ready workload must not open a setup page.';
    begin
        //[SCENARIO] Ready workload status does not open setup.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop, 'SCHEDNOSETUP');

        //[GIVEN] Recommendations are built.
        this.ScheduleMgt.BuildRecommendations(ShopifyShop, TempRecurringSyncBuffer);

        //[GIVEN] Products workload is current.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Products), ProductRowVisibleErr);

        //[WHEN] Status drilldown is requested for the ready workload.
        SetupOpened := this.ScheduleMgt.OpenSetupTarget(ShopifyShop, TempRecurringSyncBuffer);

        //[THEN] No setup page is opened.
        this.LibraryAssert.IsFalse(SetupOpened, SetupOpenedErr);
    end;

    [Test]
    procedure InProcessScheduleIsDisplayedAsRunning()
    var
        JobQueueEntry: Record "Job Queue Entry";
        StatusDisplay: Text;
        RunningStatusErr: Label 'In Process must be displayed as Running.';
    begin
        //[SCENARIO] In Process schedule is displayed as Running.

        //[GIVEN] Job queue entry is in process.
        JobQueueEntry.Status := JobQueueEntry.Status::"In Process";

        //[WHEN] The schedule status display is calculated.
        StatusDisplay := this.ScheduleMgt.GetScheduleStatusDisplay(JobQueueEntry);

        //[THEN] The status is displayed as Running.
        this.LibraryAssert.AreEqual('Running', StatusDisplay, RunningStatusErr);
    end;

    [Test]
    procedure OnHoldProductScheduleWithCustomFrequencyIsRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        ProductScheduleErr: Label 'A recurring product schedule must be recognized regardless of its status and frequency.';
        ProductWorkloadErr: Label 'The schedule must be recognized as the products workload.';
        AllShopsCoverageErr: Label 'An unfiltered schedule must cover all shops.';
    begin
        //[SCENARIO] Recurring product schedule is recognized regardless of status and frequency.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Recurring product schedule for all shops exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", this.ProductParameters('false', '0', ''));

        //[GIVEN] Job queue entry is on hold.
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";

        //[GIVEN] Job queue entry runs every 20 minutes.
        JobQueueEntry."No. of Minutes between Runs" := 20;

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, ProductScheduleErr);

        //[THEN] Workload is products.
        this.LibraryAssert.AreEqual(Workload::Products, Workload, ProductWorkloadErr);

        //[THEN] Coverage is all shops.
        this.LibraryAssert.AreEqual(Coverage::"All Shops", Coverage, AllShopsCoverageErr);
    end;

    [Test]
    procedure PriceOnlyProductScheduleIsRecognizedAsPrices()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        PriceModeErr: Label 'The price-only mode must be recognized.';
        PriceWorkloadErr: Label 'The price-only option distinguishes price synchronization from products.';
    begin
        //[SCENARIO] Price only product schedule is recognized as prices.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Recurring price-only product schedule for all shops exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", this.ProductParameters('true', '0', ''));

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, PriceModeErr);

        //[THEN] Workload is prices.
        this.LibraryAssert.AreEqual(Workload::Prices, Workload, PriceWorkloadErr);
    end;

    [Test]
    procedure MultiShopFilterIncludingCurrentShopIsRecognizedAsMultipleShops()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        MultiShopMatchErr: Label 'A multi-shop schedule containing the current shop must match.';
        MultiShopCoverageErr: Label 'A filter resolving to multiple shops must be classified as multi-shop coverage.';
    begin
        //[SCENARIO] Multi shop filter including current shop is recognized as multiple shops.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop A exists.
        this.CreateShop(ShopifyShop, 'SCHEDA');

        //[GIVEN] Shop B exists.
        this.CreateShop(ShopifyShop, 'SCHEDB');

        //[GIVEN] Product schedule filtered to shops A and B exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", this.ProductParameters('false', '0', 'SCHEDA|SCHEDB'));

        //[WHEN] Schedule is recognized for shop A.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, 'SCHEDA', Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, MultiShopMatchErr);

        //[THEN] Coverage is multiple shops.
        this.LibraryAssert.AreEqual(Coverage::"Multiple Shops", Coverage, MultiShopCoverageErr);
    end;

    [Test]
    procedure MultiShopFilterExcludingCurrentShopIsClassifiedAsOtherShops()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        OtherShopsMatchErr: Label 'A schedule for other shops must not hide this shop workload.';
        OtherShopsCoverageErr: Label 'A filter that excludes the current shop must be classified as other-shop coverage.';
    begin
        //[SCENARIO] Multi shop filter excluding current shop is classified as other shops.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop A exists.
        this.CreateShop(ShopifyShop, 'SCHEDA');

        //[GIVEN] Shop B exists.
        this.CreateShop(ShopifyShop, 'SCHEDB');

        //[GIVEN] Shop C exists.
        this.CreateShop(ShopifyShop, 'SCHEDC');

        //[GIVEN] Product schedule filtered to shops A and B exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", this.ProductParameters('false', '0', 'SCHEDA|SCHEDB'));

        //[WHEN] Schedule is recognized for shop C.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, 'SCHEDC', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, OtherShopsMatchErr);

        //[THEN] Coverage is other shops.
        this.LibraryAssert.AreEqual(Coverage::"Other Shops", Coverage, OtherShopsCoverageErr);
    end;

    [Test]
    procedure SingleShopFilterIsRecognizedAsCurrentShop()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        SingleShopMatchErr: Label 'A single-shop schedule must match its shop.';
        CurrentShopCoverageErr: Label 'A one-shop filter must be classified as current-shop coverage.';
    begin
        //[SCENARIO] Single shop filter is recognized as current shop.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop A exists.
        this.CreateShop(ShopifyShop, 'SCHEDA');

        //[GIVEN] Product schedule filtered to shop A exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", this.ProductParameters('false', '0', 'SCHEDA'));

        //[WHEN] Schedule is recognized for shop A.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, 'SCHEDA', Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, SingleShopMatchErr);

        //[THEN] Coverage is current shop.
        this.LibraryAssert.AreEqual(Coverage::"Current Shop", Coverage, CurrentShopCoverageErr);
    end;

    [Test]
    procedure EmptyShopFilterIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        EmptyShopFilterErr: Label 'An explicitly empty shop filter is not an all-shop schedule.';
    begin
        //[SCENARIO] Empty shop filter is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop A exists.
        this.CreateShop(ShopifyShop, 'SCHEDA');

        //[GIVEN] Product schedule with an explicitly empty shop filter exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", '<ReportParameters><Options><OnlySyncPrice>false</OnlySyncPrice><NumberOfRecords>0</NumberOfRecords></Options><DataItems><DataItem name="Shop">Shpfy Shop: Code=</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized for shop A.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, 'SCHEDA', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, EmptyShopFilterErr);
    end;

    [Test]
    procedure DuplicateShopDataItemsAreNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        DuplicateDataItemsErr: Label 'Duplicate report data items must fail closed.';
    begin
        //[SCENARIO] Duplicate shop data items are not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop A exists.
        this.CreateShop(ShopifyShop, 'SCHEDA');

        //[GIVEN] Product schedule with duplicate shop data items exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", '<ReportParameters><Options><OnlySyncPrice>false</OnlySyncPrice><NumberOfRecords>0</NumberOfRecords></Options><DataItems><DataItem name="Shop">Shpfy Shop</DataItem><DataItem name="Shop">Shpfy Shop</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized for shop A.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, 'SCHEDA', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, DuplicateDataItemsErr);
    end;

    [Test]
    procedure OneTimeReportIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        OneTimeReportErr: Label 'A one-time report is not a recurring synchronization.';
    begin
        //[SCENARIO] One time report is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Product schedule for all shops exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", this.ProductParameters('false', '0', ''));

        //[GIVEN] Job queue entry is not recurring.
        JobQueueEntry."Recurring Job" := false;

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, OneTimeReportErr);
    end;

    [Test]
    procedure MissingReportParametersAreNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        MissingParametersErr: Label 'Missing saved report parameters must fail closed.';
    begin
        //[SCENARIO] Missing report parameters are not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Product schedule without report parameters exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", '');

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, MissingParametersErr);
    end;

    [Test]
    procedure RecordLimitedProductReportIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        RecordLimitErr: Label 'A record-limited product report is custom behavior.';
    begin
        //[SCENARIO] Record limited product report is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Product schedule limited to one hundred records exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", this.ProductParameters('false', '100', ''));

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, RecordLimitErr);
    end;

    [Test]
    procedure MissingReportOptionsAreNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        MissingOptionsErr: Label 'Missing report options must fail closed.';
    begin
        //[SCENARIO] Missing report options are not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Product schedule without the record count option exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", '<ReportParameters><Options><OnlySyncPrice>false</OnlySyncPrice></Options><DataItems><DataItem name="Shop">Shpfy Shop</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, MissingOptionsErr);
    end;

    [Test]
    procedure MissingReportDataItemsAreNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        MissingDataItemsErr: Label 'Missing report data items must fail closed.';
    begin
        //[SCENARIO] Missing report data items are not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Product schedule without data items exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", '<ReportParameters><Options><OnlySyncPrice>false</OnlySyncPrice><NumberOfRecords>0</NumberOfRecords></Options><DataItems /></ReportParameters>');

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, MissingDataItemsErr);
    end;

    [Test]
    procedure UnknownReportOptionIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        UnknownOptionErr: Label 'An unknown report option must fail closed.';
    begin
        //[SCENARIO] Unknown report option is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Otherwise valid product schedule with an additional unknown report option exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", '<ReportParameters><Options><OnlySyncPrice>false</OnlySyncPrice><NumberOfRecords>0</NumberOfRecords><UnknownOption>true</UnknownOption></Options><DataItems><DataItem name="Shop">Shpfy Shop</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, UnknownOptionErr);
    end;

    [Test]
    procedure DifferentXmlDocumentIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        DifferentXmlErr: Label 'A different XML document must not be interpreted as a schedule definition.';
    begin
        //[SCENARIO] Different XML document is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Product schedule with a non report parameters XML document exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", '<not-report-parameters />');

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, DifferentXmlErr);
    end;

    [Test]
    procedure MalformedReportParametersAreNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        MalformedParametersErr: Label 'Malformed saved report parameters must fail closed.';
    begin
        //[SCENARIO] Malformed report parameters are not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Product schedule with malformed report parameters exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", '<ReportParameters><Options>');

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, MalformedParametersErr);
    end;

    [Test]
    procedure RecurringCodeunitJobIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        CodeunitJobErr: Label 'A recurring codeunit is not a Shopify report schedule.';
    begin
        //[SCENARIO] Recurring codeunit job is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Product schedule for all shops exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", this.ProductParameters('false', '0', ''));

        //[GIVEN] Job queue entry runs a codeunit.
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, CodeunitJobErr);
    end;

    [Test]
    procedure ReportWithOutputIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        ReportOutputErr: Label 'A report with output is not a processing-only synchronization schedule.';
    begin
        //[SCENARIO] Report with output is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Product schedule for all shops exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", this.ProductParameters('false', '0', ''));

        //[GIVEN] Job queue entry produces PDF output.
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::PDF;

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, ReportOutputErr);
    end;

    [Test]
    procedure JobWithParameterStringIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        ParameterStringErr: Label 'A custom Job Queue parameter string changes report behavior.';
    begin
        //[SCENARIO] Job with parameter string is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Product schedule for all shops exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", this.ProductParameters('false', '0', ''));

        //[GIVEN] Job queue entry has a custom parameter string.
        JobQueueEntry."Parameter String" := 'custom job queue parameters';

        //[WHEN] Schedule is recognized.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, ParameterStringErr);
    end;

    [Test]
    procedure RecordBoundJobIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        RecordBoundJobErr: Label 'A record-bound Job Queue entry is not an unfiltered recurring synchronization.';
    begin
        //[SCENARIO] Record bound job is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop exists.
        this.CreateShop(ShopifyShop, 'SCHEDRECID');

        //[GIVEN] Product schedule for all shops exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", this.ProductParameters('false', '0', ''));

        //[GIVEN] Job queue entry is bound to the shop record.
        JobQueueEntry."Record ID to Process" := ShopifyShop.RecordId;

        //[WHEN] Schedule is recognized for the shop.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, ShopifyShop.Code, Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, RecordBoundJobErr);
    end;

    [Test]
    procedure SelectedScheduleCreationCreatesRecurringEntry()
    var
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        ShopifyShop: Record "Shpfy Shop";
        CompletionMessageErr: Label 'Creating a selected recurring schedule must return a completion message.';
        RecurringProductSyncTxt: Label 'Recurring product sync', Locked = true;
        ScheduleNotCreatedErr: Label 'Finish must create a recurring product schedule for the selected shop.';
        Result: Text;
    begin
        //[SCENARIO] Selected schedule creation creates recurring entry.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop ready for product synchronization to Shopify exists.
        this.CreateProductsToShopifyShop(ShopifyShop, 'SCHEDFINISH');

        //[GIVEN] Products workload is selected.
        this.CreateSelectedRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Products, Enum::"Shpfy Sync Direction"::"Products to Shopify", RecurringProductSyncTxt);

        //[WHEN] Selected schedules are created.
        Result := this.ScheduleMgt.CreateSelectedSchedules(ShopifyShop, TempRecurringSyncBuffer);

        //[THEN] Completion message is returned.
        this.LibraryAssert.IsTrue(Result <> '', CompletionMessageErr);

        //[THEN] Recurring product schedule for the current shop exists.
        this.LibraryAssert.IsTrue(this.HasRecognizedSchedule(ShopifyShop.Code, Enum::"Shpfy Sync Workload"::Products, Enum::"Shpfy Sync Coverage"::"Current Shop"), ScheduleNotCreatedErr);
    end;

    [Test]
    procedure RepeatedSelectedScheduleCreationDoesNotCreateDuplicate()
    var
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        ShopifyShop: Record "Shpfy Shop";
        EntryCount: Integer;
        DuplicateScheduleErr: Label 'Finishing the same selection again must not create another Job Queue Entry.';
        RecurringProductSyncTxt: Label 'Recurring product sync', Locked = true;
    begin
        //[SCENARIO] Repeated selected schedule creation does not create duplicate.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop ready for product synchronization to Shopify exists.
        this.CreateProductsToShopifyShop(ShopifyShop, 'SCHEDFINISH');

        //[GIVEN] Products workload is selected.
        this.CreateSelectedRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Products, Enum::"Shpfy Sync Direction"::"Products to Shopify", RecurringProductSyncTxt);

        //[GIVEN] Selected schedules are created.
        this.ScheduleMgt.CreateSelectedSchedules(ShopifyShop, TempRecurringSyncBuffer);

        //[GIVEN] Number of recurring product job queue entries is known.
        EntryCount := this.CountRecurringProductJobQueueEntries();

        //[WHEN] Same selection is created again.
        this.ScheduleMgt.CreateSelectedSchedules(ShopifyShop, TempRecurringSyncBuffer);

        //[THEN] No additional job queue entry is created.
        this.LibraryAssert.AreEqual(EntryCount, this.CountRecurringProductJobQueueEntries(), DuplicateScheduleErr);
    end;

    [Test]
    procedure NativeShopViewWithFieldNamesIsRecognizedForCurrentShop()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        NativeViewErr: Label 'Native shop views using field names must recognize the price schedule.';
        CoverageErr: Label 'The native view must cover only the selected shop, including parentheses in its code.';
    begin
        //[SCENARIO] Native shop view with field names is recognized for current shop.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop with parentheses in its code exists.
        this.CreateShop(ShopifyShop, 'SCHED (A)');

        //[GIVEN] Price schedule with a native shop view using field names exists.
        this.CreateNativePriceSchedule(JobQueueEntry, ShopifyShop, true, false);

        //[WHEN] Schedule is recognized for the shop.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, ShopifyShop.Code, Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, NativeViewErr);

        //[THEN] Workload is prices.
        this.LibraryAssert.AreEqual(Workload::Prices, Workload, NativeViewErr);

        //[THEN] Coverage is current shop.
        this.LibraryAssert.AreEqual(Coverage::"Current Shop", Coverage, CoverageErr);
    end;

    [Test]
    procedure NativeShopViewWithFieldNumbersIsRecognizedForCurrentShop()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        NativeViewErr: Label 'Native shop views using field numbers must recognize the price schedule.';
        CoverageErr: Label 'The native view must cover only the selected shop, including parentheses in its code.';
    begin
        //[SCENARIO] Native shop view with field numbers is recognized for current shop.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop with parentheses in its code exists.
        this.CreateShop(ShopifyShop, 'SCHED (A)');

        //[GIVEN] Price schedule with a native shop view using field numbers exists.
        this.CreateNativePriceSchedule(JobQueueEntry, ShopifyShop, false, false);

        //[WHEN] Schedule is recognized for the shop.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, ShopifyShop.Code, Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, NativeViewErr);

        //[THEN] Workload is prices.
        this.LibraryAssert.AreEqual(Workload::Prices, Workload, NativeViewErr);

        //[THEN] Coverage is current shop.
        this.LibraryAssert.AreEqual(Coverage::"Current Shop", Coverage, CoverageErr);
    end;

    [Test]
    procedure NativeShopViewDoesNotMatchOtherShop()
    var
        JobQueueEntry: Record "Job Queue Entry";
        OtherShop: Record "Shpfy Shop";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        OtherShopErr: Label 'A native shop view must not hide recommendations for another shop.';
    begin
        //[SCENARIO] Native shop view does not match other shop.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop with parentheses in its code exists.
        this.CreateShop(ShopifyShop, 'SCHED (A)');

        //[GIVEN] Other shop exists.
        this.CreateShop(OtherShop, 'SCHEDOTHER');

        //[GIVEN] Price schedule with a native shop view for the first shop exists.
        this.CreateNativePriceSchedule(JobQueueEntry, ShopifyShop, true, false);

        //[WHEN] Schedule is recognized for the other shop.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, OtherShop.Code, Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, OtherShopErr);
    end;

    [Test]
    procedure NativeShopViewWithFieldNamesAndAdditionalFilterIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        AdditionalFilterErr: Label 'A native view with filters beyond Shop Code must not hide the complete workload.';
    begin
        //[SCENARIO] Native shop view with field names and additional filter is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop with parentheses in its code exists.
        this.CreateShop(ShopifyShop, 'SCHED (A)');

        //[GIVEN] Price schedule with a native shop view using field names and an additional filter exists.
        this.CreateNativePriceSchedule(JobQueueEntry, ShopifyShop, true, true);

        //[WHEN] Schedule is recognized for the shop.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, ShopifyShop.Code, Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, AdditionalFilterErr);
    end;

    [Test]
    procedure NativeShopViewWithFieldNumbersAndAdditionalFilterIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        AdditionalFilterErr: Label 'A native view with filters beyond Shop Code must not hide the complete workload.';
    begin
        //[SCENARIO] Native shop view with field numbers and additional filter is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop with parentheses in its code exists.
        this.CreateShop(ShopifyShop, 'SCHED (A)');

        //[GIVEN] Price schedule with a native shop view using field numbers and an additional filter exists.
        this.CreateNativePriceSchedule(JobQueueEntry, ShopifyShop, false, true);

        //[WHEN] Schedule is recognized for the shop.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, ShopifyShop.Code, Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, AdditionalFilterErr);
    end;

    [Test]
    procedure ExistingSchedulesCanBeListedForTheCurrentShop()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TempJobQueueEntryBuffer: Record "Job Queue Entry" temporary;
        TempRecommendations: Record "Shpfy Recurring Sync Buffer" temporary;
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        ShopifyShop: Record "Shpfy Shop";
        HasExistingSchedules: Boolean;
        ExistingSchedulesErr: Label 'The recommendations scan must report recognized schedules for the current shop.';
        ListCountErr: Label 'The current shop list must contain its recognized recurring schedule.';
        ListEntryIdErr: Label 'The list row must retain the source Job Queue Entry ID.';
        ListFrequencyErr: Label 'The schedule list must show the recurring frequency.';
        ShopDisplayErr: Label 'The list must show the covered shop.';
        SourceRecordCountErr: Label 'The list source records must contain the matching Job Queue Entry.';
        SourceRecordIdErr: Label 'The temporary list record must preserve the Job Queue Entry ID for CardPageId navigation.';
    begin
        //[SCENARIO] Existing schedules can be listed for the current shop.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop ready for product synchronization to Shopify exists.
        this.CreateProductsToShopifyShop(ShopifyShop, 'SCHEDLIST');

        //[GIVEN] Hourly product schedule for the shop exists.
        this.CreateProductScheduleForShop(JobQueueEntry, ShopifyShop.Code, 60, JobQueueEntry.Status::Ready);

        //[WHEN] Recommendations are built.
        this.ScheduleMgt.BuildRecommendationsWithScheduleState(ShopifyShop, TempRecommendations, HasExistingSchedules);

        //[WHEN] Existing schedule entries are built.
        this.ScheduleMgt.BuildExistingScheduleEntries(ShopifyShop, TempJobQueueEntryBuffer, TempRecurringSyncBuffer);

        //[THEN] Existing schedules are detected.
        this.LibraryAssert.IsTrue(HasExistingSchedules, ExistingSchedulesErr);

        //[THEN] One schedule is listed.
        this.LibraryAssert.AreEqual(1, TempRecurringSyncBuffer.Count(), ListCountErr);

        //[THEN] Listed schedule exists.
        this.LibraryAssert.IsTrue(TempRecurringSyncBuffer.FindFirst(), ListCountErr);

        //[THEN] Listed schedule retains the job queue entry ID.
        this.LibraryAssert.AreEqual(JobQueueEntry.ID, TempRecurringSyncBuffer."Job Queue Entry ID", ListEntryIdErr);

        //[THEN] Listed schedule shows the recurring frequency.
        this.LibraryAssert.AreEqual(60, TempRecurringSyncBuffer.Frequency, ListFrequencyErr);

        //[THEN] Listed schedule shows the covered shop.
        this.LibraryAssert.AreEqual(ShopifyShop.Code, TempRecurringSyncBuffer."Shop Display", ShopDisplayErr);

        //[THEN] One source job queue entry is listed.
        this.LibraryAssert.AreEqual(1, TempJobQueueEntryBuffer.Count(), SourceRecordCountErr);

        //[THEN] Source job queue entry exists.
        this.LibraryAssert.IsTrue(TempJobQueueEntryBuffer.FindFirst(), SourceRecordCountErr);

        //[THEN] Source job queue entry retains its ID.
        this.LibraryAssert.AreEqual(JobQueueEntry.ID, TempJobQueueEntryBuffer.ID, SourceRecordIdErr);
    end;

    [Test]
    procedure SelectedWorkloadThatIsNoLongerReadyIsSkipped()
    var
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        ShopifyShop: Record "Shpfy Shop";
        SkippedExplanationErr: Label 'Finish must explain when a selected workload is skipped after it becomes unready.';
        StaleProductSyncTxt: Label 'Stale selected product sync SCHEDSTALE', Locked = true;
        UnreadyScheduleCreatedErr: Label 'Finish must not create a schedule for a workload that is no longer ready.';
        Result: Text;
    begin
        //[SCENARIO] Selected workload that is no longer ready is skipped.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop without product synchronization setup exists.
        this.CreateShop(ShopifyShop, 'SCHEDSTALE');

        //[GIVEN] Products workload is selected.
        this.CreateSelectedRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Products, Enum::"Shpfy Sync Direction"::Products, StaleProductSyncTxt);

        //[WHEN] Selected schedules are created.
        Result := this.ScheduleMgt.CreateSelectedSchedules(ShopifyShop, TempRecurringSyncBuffer);

        //[THEN] Explanation message is returned.
        this.LibraryAssert.IsTrue(Result <> '', SkippedExplanationErr);

        //[THEN] No product schedule is created.
        this.LibraryAssert.IsFalse(this.ProductJobQueueEntryExists(StaleProductSyncTxt), UnreadyScheduleCreatedErr);
    end;

    [Test]
    procedure InventoryReportIsRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        InventoryRecognizedErr: Label 'An unfiltered inventory report must be recognized.';
        InventoryWorkloadErr: Label 'The stock report is the inventory workload.';
    begin
        //[SCENARIO] Inventory report is recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop A exists.
        this.CreateShop(ShopifyShop, 'SCHEDA');

        //[GIVEN] Inventory schedule for shop A exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Stock to Shopify", '<ReportParameters><Options><Skip_x0020_Import>false</Skip_x0020_Import><Variant_x0020_ID_x0020_Filter /></Options><DataItems><DataItem name="Shop">Shpfy Shop: Code=SCHEDA</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized for shop A.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, 'SCHEDA', Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, InventoryRecognizedErr);

        //[THEN] Workload is inventory.
        this.LibraryAssert.AreEqual(Workload::Inventory, Workload, InventoryWorkloadErr);
    end;

    [Test]
    procedure OrdersReportIsRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        OrdersRecognizedErr: Label 'An unfiltered orders report must be recognized.';
        OrdersWorkloadErr: Label 'The order report is the orders workload.';
    begin
        //[SCENARIO] Orders report is recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop A exists.
        this.CreateShop(ShopifyShop, 'SCHEDA');

        //[GIVEN] Orders schedule for shop A exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Orders from Shopify", '<ReportParameters><Options /><DataItems><DataItem name="Shop">Shpfy Shop: Code=SCHEDA</DataItem><DataItem name="OrdersToImport">Shpfy Orders to Import</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized for shop A.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, 'SCHEDA', Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, OrdersRecognizedErr);

        //[THEN] Workload is orders.
        this.LibraryAssert.AreEqual(Workload::Orders, Workload, OrdersWorkloadErr);
    end;

    [Test]
    procedure CustomersReportIsRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        CustomersRecognizedErr: Label 'An unfiltered customer report must be recognized.';
        CustomersWorkloadErr: Label 'The customer report is the customers workload.';
    begin
        //[SCENARIO] Customers report is recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop A exists.
        this.CreateShop(ShopifyShop, 'SCHEDA');

        //[GIVEN] Customers schedule for shop A exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Customers", '<ReportParameters><Options /><DataItems><DataItem name="Shop">Shpfy Shop: Code=SCHEDA</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized for shop A.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, 'SCHEDA', Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, CustomersRecognizedErr);

        //[THEN] Workload is customers.
        this.LibraryAssert.AreEqual(Workload::Customers, Workload, CustomersWorkloadErr);
    end;

    [Test]
    procedure CompaniesReportIsRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        CompaniesRecognizedErr: Label 'An unfiltered company report must be recognized.';
        CompaniesWorkloadErr: Label 'The company report is the companies workload.';
    begin
        //[SCENARIO] Companies report is recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop A exists.
        this.CreateShop(ShopifyShop, 'SCHEDA');

        //[GIVEN] Companies schedule for shop A exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Companies", '<ReportParameters><Options /><DataItems><DataItem name="Shop">Shpfy Shop: Code=SCHEDA</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized for shop A.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, 'SCHEDA', Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, CompaniesRecognizedErr);

        //[THEN] Workload is companies.
        this.LibraryAssert.AreEqual(Workload::Companies, Workload, CompaniesWorkloadErr);
    end;

    [Test]
    procedure ImagesReportIsRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        ImagesRecognizedErr: Label 'An image report without a product filter must be recognized.';
        ImagesWorkloadErr: Label 'The image report is the product-images workload.';
    begin
        //[SCENARIO] Images report is recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop A exists.
        this.CreateShop(ShopifyShop, 'SCHEDA');

        //[GIVEN] Images schedule without a product filter for shop A exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Images", '<ReportParameters><Options><ProductFilter /></Options><DataItems><DataItem name="Shop">Shpfy Shop: Code=SCHEDA</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized for shop A.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, 'SCHEDA', Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, ImagesRecognizedErr);

        //[THEN] Workload is product images.
        this.LibraryAssert.AreEqual(Workload::"Product Images", Workload, ImagesWorkloadErr);
    end;

    [Test]
    procedure InvoiceScheduleIsRecognizedForItsShop()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        InvoiceShopOptionErr: Label 'An invoice schedule must recognize its explicit shop option.';
        InvoiceCoverageErr: Label 'An invoice schedule is shop-specific.';
    begin
        //[SCENARIO] Invoice schedule is recognized for its shop.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Posted invoice schedule for shop A exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Invoices to Shpfy", '<ReportParameters><Options><Shop>SCHEDA</Shop></Options><DataItems><DataItem name="SalesInvoiceHeader">Sales Invoice Header</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized for shop A.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, 'SCHEDA', Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, InvoiceShopOptionErr);

        //[THEN] Coverage is current shop.
        this.LibraryAssert.AreEqual(Coverage::"Current Shop", Coverage, InvoiceCoverageErr);
    end;

    [Test]
    procedure InvoiceScheduleIsNotRecognizedForOtherShop()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        InvoiceOtherShopErr: Label 'An invoice schedule for another shop must not match.';
    begin
        //[SCENARIO] Invoice schedule is not recognized for other shop.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Posted invoice schedule for shop A exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Invoices to Shpfy", '<ReportParameters><Options><Shop>SCHEDA</Shop></Options><DataItems><DataItem name="SalesInvoiceHeader">Sales Invoice Header</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized for shop B.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, 'SCHEDB', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, InvoiceOtherShopErr);
    end;

    [Test]
    procedure ShopFilteredCatalogPriceScheduleIsRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        CatalogRecognizedErr: Label 'A shop-filtered catalog-price schedule is recognized for that shop.';
        CatalogWorkloadErr: Label 'The catalog-prices report must be identified as its own workload.';
        CatalogCoverageErr: Label 'Catalog prices require explicit shop coverage.';
    begin
        //[SCENARIO] Shop filtered catalog price schedule is recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop exists.
        this.CreateShop(ShopifyShop, 'SCHEDCAT');

        //[GIVEN] Catalog price schedule filtered to the shop exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Catalog Prices", '<ReportParameters><Options><ShopifyCompanyId /><ShopifyCatalogType>0</ShopifyCatalogType></Options><DataItems><DataItem name="Shop">Shpfy Shop: Code=SCHEDCAT</DataItem><DataItem name="Catalog">Shpfy Catalog</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized for the shop.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, ShopifyShop.Code, Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, CatalogRecognizedErr);

        //[THEN] Workload is catalog prices.
        this.LibraryAssert.AreEqual(Workload::"Catalog Prices", Workload, CatalogWorkloadErr);

        //[THEN] Coverage is current shop.
        this.LibraryAssert.AreEqual(Coverage::"Current Shop", Coverage, CatalogCoverageErr);
    end;

    [Test]
    procedure UnfilteredCatalogPriceScheduleIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        UnfilteredCatalogErr: Label 'An unfiltered catalog-prices report is not a match.';
    begin
        //[SCENARIO] Unfiltered catalog price schedule is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop exists.
        this.CreateShop(ShopifyShop, 'SCHEDCAT');

        //[GIVEN] Catalog price schedule without a shop filter exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Catalog Prices", '<ReportParameters><Options><ShopifyCompanyId /><ShopifyCatalogType>0</ShopifyCatalogType></Options><DataItems><DataItem name="Shop">Shpfy Shop</DataItem><DataItem name="Catalog">Shpfy Catalog</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized for the shop.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, ShopifyShop.Code, Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, UnfilteredCatalogErr);
    end;

    [Test]
    procedure CompanyRestrictedCatalogPriceScheduleIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        CompanyCatalogErr: Label 'A company-restricted catalog report is not the complete catalog-prices workload.';
    begin
        //[SCENARIO] Company restricted catalog price schedule is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop exists.
        this.CreateShop(ShopifyShop, 'SCHEDCAT');

        //[GIVEN] Catalog price schedule restricted to a company exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Catalog Prices", '<ReportParameters><Options><ShopifyCompanyId>company-id</ShopifyCompanyId><ShopifyCatalogType>0</ShopifyCatalogType></Options><DataItems><DataItem name="Shop">Shpfy Shop: Code=SCHEDCAT</DataItem><DataItem name="Catalog">Shpfy Catalog</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized for the shop.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, ShopifyShop.Code, Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, CompanyCatalogErr);
    end;

    [Test]
    procedure ShipmentScheduleIsOneGlobalWorkload()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        ShipmentRecognizedErr: Label 'The standard shipment schedule must be recognized without selecting a shop.';
        ShipmentWorkloadErr: Label 'The shipment report is its own workload.';
        ShipmentCoverageErr: Label 'One shipment schedule covers all Shopify shops.';
    begin
        //[SCENARIO] Shipment schedule is one global workload.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Unfiltered shipment schedule exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Shipm. to Shopify", '<ReportParameters><Options /><DataItems><DataItem name="Sales Shipment Header">Sales Shipment Header</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized without a shop.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, ShipmentRecognizedErr);

        //[THEN] Workload is shipments.
        this.LibraryAssert.AreEqual(Workload::Shipments, Workload, ShipmentWorkloadErr);

        //[THEN] Coverage is all shops.
        this.LibraryAssert.AreEqual(Coverage::"All Shops", Coverage, ShipmentCoverageErr);
    end;

    [Test]
    procedure FilteredShipmentScheduleIsNotRecognized()
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        FilteredShipmentErr: Label 'A filtered shipment report is not the global recurring workload.';
    begin
        //[SCENARIO] Filtered shipment schedule is not recognized.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shipment schedule filtered to one shipment exists.
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Shipm. to Shopify", '<ReportParameters><Options /><DataItems><DataItem name="Sales Shipment Header">Sales Shipment Header: No.=S-100</DataItem></DataItems></ReportParameters>');

        //[WHEN] Schedule is recognized without a shop.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, '', Workload, Coverage);

        //[THEN] Schedule is not recognized.
        this.LibraryAssert.IsFalse(IsRecognized, FilteredShipmentErr);
    end;

    [Test]
    procedure RecommendationsUseDefaultsAndHideRecognizedWorkloads()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        ShopifyShop: Record "Shpfy Shop";
        OrderDescriptionErr: Label 'Webhook-enabled order recommendation includes a description.';
        OrderFrequencyErr: Label 'Webhook-enabled order synchronization defaults to once daily.';
        OrdersRecommendedErr: Label 'Orders remain relevant when Auto Sync Orders is enabled.';
        PriceDirectionErr: Label 'Price synchronization is outbound.';
        PriceFrequencyErr: Label 'Price synchronization defaults to every six hours.';
        PriceReadinessErr: Label 'A ready workload is selectable by default.';
        PriceSelectedErr: Label 'Ready recommendations are selected by default.';
        PricesRecommendedErr: Label 'Prices are independent from full product synchronization.';
        ProductsRecommendedErr: Label 'The recognized workload must not be recommended again.';
        RecommendationCountErr: Label 'A recognized product schedule in Error status hides only the Products workload.';
        ShipmentDescriptionErr: Label 'Shipment recommendation includes a description.';
        ShipmentFrequencyErr: Label 'Shipment synchronization defaults to every two hours.';
        ShipmentsRecommendedErr: Label 'Shipments do not require current shipment records or a shop direction.';
    begin
        //[SCENARIO] Recommendations use defaults and hide recognized workloads.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop ready for all workloads with order webhooks exists.
        this.CreateShopReadyForAllWorkloads(ShopifyShop, 'SCHEDREADY', true);

        //[GIVEN] Shop location with stock calculation exists.
        this.CreateShopLocation(ShopifyShop.Code, 1, Enum::"Shpfy Stock Calculation"::"Non-reserved Inventory");

        //[GIVEN] Primary Shopify payment terms exist.
        this.CreateShopifyPaymentTerms(ShopifyShop.Code, '', true);

        //[GIVEN] Product schedule for the shop in Error status exists.
        this.CreateProductScheduleForShop(JobQueueEntry, ShopifyShop.Code, 0, JobQueueEntry.Status::Error);

        //[WHEN] Recommendations are built.
        this.ScheduleMgt.BuildRecommendations(ShopifyShop, TempRecurringSyncBuffer);

        //[THEN] Nine workloads are recommended.
        this.LibraryAssert.AreEqual(9, TempRecurringSyncBuffer.Count(), RecommendationCountErr);

        //[THEN] Products workload is not recommended.
        this.LibraryAssert.IsFalse(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Products), ProductsRecommendedErr);

        //[THEN] Prices workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Prices), PricesRecommendedErr);

        //[THEN] Prices run every six hours.
        this.LibraryAssert.AreEqual(360, TempRecurringSyncBuffer.Frequency, PriceFrequencyErr);

        //[THEN] Prices are not scheduled yet.
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer.Readiness::"Not scheduled", TempRecurringSyncBuffer.Readiness, PriceReadinessErr);

        //[THEN] Prices are selected.
        this.LibraryAssert.IsTrue(TempRecurringSyncBuffer.Selected, PriceSelectedErr);

        //[THEN] Prices are synchronized to Shopify.
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer.Synchronization::"Prices to Shopify", TempRecurringSyncBuffer.Synchronization, PriceDirectionErr);

        //[THEN] Orders workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Orders), OrdersRecommendedErr);

        //[THEN] Orders run once daily.
        this.LibraryAssert.AreEqual(1440, TempRecurringSyncBuffer.Frequency, OrderFrequencyErr);

        //[THEN] Orders recommendation includes a description.
        this.LibraryAssert.IsTrue(TempRecurringSyncBuffer.Description <> '', OrderDescriptionErr);

        //[THEN] Shipments workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Shipments), ShipmentsRecommendedErr);

        //[THEN] Shipments run every two hours.
        this.LibraryAssert.AreEqual(120, TempRecurringSyncBuffer.Frequency, ShipmentFrequencyErr);

        //[THEN] Shipments recommendation includes a description.
        this.LibraryAssert.IsTrue(TempRecurringSyncBuffer.Description <> '', ShipmentDescriptionErr);
    end;

    [Test]
    procedure AllTenWorkloadsUsePlannedFrequenciesAndAreSelectedWhenReady()
    var
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        ShopifyShop: Record "Shpfy Shop";
    begin
        //[SCENARIO] All ten workloads use planned frequencies and are selected when ready.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop ready for all workloads without order webhooks exists.
        this.CreateShopReadyForAllWorkloads(ShopifyShop, 'SCHEDMATRIX', false);

        //[GIVEN] Shop location with stock calculation exists.
        this.CreateShopLocation(ShopifyShop.Code, 1, Enum::"Shpfy Stock Calculation"::"Projected Available Balance Today");

        //[GIVEN] Mapped Shopify payment terms exist.
        this.CreateShopifyPaymentTerms(ShopifyShop.Code, 'NET30', false);

        //[WHEN] Recommendations are built.
        this.ScheduleMgt.BuildRecommendations(ShopifyShop, TempRecurringSyncBuffer);

        //[THEN] Products use the planned defaults.
        this.AssertRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Products, 1440, Enum::"Shpfy Sync Direction"::"Products to Shopify");

        //[THEN] Prices use the planned defaults.
        this.AssertRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Prices, 360, Enum::"Shpfy Sync Direction"::"Prices to Shopify");

        //[THEN] Inventory uses the planned defaults.
        this.AssertRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Inventory, 360, Enum::"Shpfy Sync Direction"::"Inventory to Shopify");

        //[THEN] Orders use the planned defaults.
        this.AssertRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Orders, 30, Enum::"Shpfy Sync Direction"::"Orders from Shopify");

        //[THEN] Shipments use the planned defaults.
        this.AssertRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Shipments, 120, Enum::"Shpfy Sync Direction"::"Shipments to Shopify");

        //[THEN] Customers use the planned defaults.
        this.AssertRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Customers, 240, Enum::"Shpfy Sync Direction"::"Customers from Shopify");

        //[THEN] Companies use the planned defaults.
        this.AssertRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Companies, 240, Enum::"Shpfy Sync Direction"::"Companies from Shopify");

        //[THEN] Product images use the planned defaults.
        this.AssertRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::"Product Images", 1440, Enum::"Shpfy Sync Direction"::"Product images from Shopify");

        //[THEN] Posted invoices use the planned defaults.
        this.AssertRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::"Posted Invoices", 360, Enum::"Shpfy Sync Direction"::"Posted invoices to Shopify");

        //[THEN] Catalog prices use the planned defaults.
        this.AssertRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::"Catalog Prices", 720, Enum::"Shpfy Sync Direction"::"Catalog prices to Shopify");
    end;

    [Test]
    procedure ReadinessUsesImportUpdateAndLocationRulesWithoutTemplatePrerequisites()
    var
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        ShopifyShop: Record "Shpfy Shop";
        CompaniesDirectionErr: Label 'Inbound and outbound company settings are represented together.';
        CustomersDirectionErr: Label 'Inbound and outbound customer settings are represented together.';
        InboundCompaniesErr: Label 'Company import plus Shopify update permission enables inbound synchronization.';
        InboundCustomersErr: Label 'Customer import plus Shopify update permission enables inbound synchronization.';
        InboundProductsErr: Label 'Inbound product synchronization is available when item update or auto-create is enabled.';
        InboundSelectableErr: Label 'An eligible inbound-only workload is selectable.';
        InventorySetupRequiredErr: Label 'No location with stock calculation configured is unavailable.';
        InventorySetupTargetErr: Label 'Inventory setup opens Shopify Shop Locations.';
        InventoryVisibleErr: Label 'A stock calculation is required before inventory is ready.';
        ProductsDirectionErr: Label 'Products retain the configured inbound direction.';
        UnavailableSelectableErr: Label 'Unavailable workloads cannot be selected.';
        UnavailableSelectedErr: Label 'Unavailable workloads are not selected by default.';
    begin
        //[SCENARIO] Readiness uses import update and location rules without template prerequisites.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop with inbound synchronization settings exists.
        this.CreateInboundShop(ShopifyShop, 'SCHEDINBOUND');

        //[WHEN] Recommendations are built.
        this.ScheduleMgt.BuildRecommendations(ShopifyShop, TempRecurringSyncBuffer);

        //[THEN] Products workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Products), InboundProductsErr);

        //[THEN] Products are synchronized from Shopify.
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer.Synchronization::"Products from Shopify", TempRecurringSyncBuffer.Synchronization, ProductsDirectionErr);

        //[THEN] Products workload is selectable.
        this.LibraryAssert.IsTrue(TempRecurringSyncBuffer.Selectable, InboundSelectableErr);

        //[THEN] Customers workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Customers), InboundCustomersErr);

        //[THEN] Customers are synchronized in both directions.
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer.Synchronization::"Customers to/from Shopify", TempRecurringSyncBuffer.Synchronization, CustomersDirectionErr);

        //[THEN] Companies workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Companies), InboundCompaniesErr);

        //[THEN] Companies are synchronized in both directions.
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer.Synchronization::"Companies to/from Shopify", TempRecurringSyncBuffer.Synchronization, CompaniesDirectionErr);

        //[THEN] Inventory workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Inventory), InventoryVisibleErr);

        //[THEN] Inventory requires setup.
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer.Readiness::"Setup required", TempRecurringSyncBuffer.Readiness, InventorySetupRequiredErr);

        //[THEN] Inventory setup opens shop locations.
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer."Setup Target"::"Shop Locations", TempRecurringSyncBuffer."Setup Target", InventorySetupTargetErr);

        //[THEN] Inventory workload is not selectable.
        this.LibraryAssert.IsFalse(TempRecurringSyncBuffer.Selectable, UnavailableSelectableErr);

        //[THEN] Inventory workload is not selected.
        this.LibraryAssert.IsFalse(TempRecurringSyncBuffer.Selected, UnavailableSelectedErr);
    end;

    [Test]
    procedure InventoryIsReadyWithBlankLocationFilter()
    var
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        ShopifyShop: Record "Shpfy Shop";
        BlankLocationFilterErr: Label 'A blank location filter is valid when a stock calculation is enabled.';
        InventoryReadyErr: Label 'Inventory is ready with any participating location.';
    begin
        //[SCENARIO] Inventory is ready with blank location filter.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop with inbound synchronization settings exists.
        this.CreateInboundShop(ShopifyShop, 'SCHEDINBOUND');

        //[GIVEN] Shop location with stock calculation and blank location filter exists.
        this.CreateShopLocation(ShopifyShop.Code, 2, Enum::"Shpfy Stock Calculation"::"Non-reserved Inventory");

        //[WHEN] Recommendations are built.
        this.ScheduleMgt.BuildRecommendations(ShopifyShop, TempRecurringSyncBuffer);

        //[THEN] Inventory workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Inventory), BlankLocationFilterErr);

        //[THEN] Inventory is ready to be scheduled.
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer.Readiness::"Not scheduled", TempRecurringSyncBuffer.Readiness, InventoryReadyErr);
    end;

    [Test]
    procedure OutboundPermissionOverlayDoesNotBlockInboundOnlyRows()
    var
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        ShopifyShop: Record "Shpfy Shop";
        InboundOrdersErr: Label 'Inbound order synchronization stays schedulable when outbound synchronization is disabled.';
        InboundOrdersSelectableErr: Label 'The outbound overlay does not disable inbound-only rows.';
        InboundProductsErr: Label 'Inbound product synchronization stays schedulable.';
        InboundProductsSelectableErr: Label 'Inbound product synchronization remains selectable.';
        OutboundPricesSelectableErr: Label 'Outbound price synchronization is unavailable when outbound data sync is disabled.';
        OutboundPricesVisibleErr: Label 'Outbound price synchronization remains visible.';
        OverlayDetailErr: Label 'The outbound overlay includes setup guidance.';
        OverlaySetupTargetErr: Label 'The outbound overlay opens the Shop Card.';
    begin
        //[SCENARIO] Outbound permission overlay does not block inbound only rows.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop with inbound settings and outgoing requests disabled exists.
        this.CreateShopWithOutgoingRequestsDisabled(ShopifyShop, 'SCHEDOVERLAY');

        //[WHEN] Recommendations are built.
        this.ScheduleMgt.BuildRecommendations(ShopifyShop, TempRecurringSyncBuffer);

        //[THEN] Orders workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Orders), InboundOrdersErr);

        //[THEN] Orders workload is selectable.
        this.LibraryAssert.IsTrue(TempRecurringSyncBuffer.Selectable, InboundOrdersSelectableErr);

        //[THEN] Products workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Products), InboundProductsErr);

        //[THEN] Products workload is selectable.
        this.LibraryAssert.IsTrue(TempRecurringSyncBuffer.Selectable, InboundProductsSelectableErr);

        //[THEN] Prices workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Prices), OutboundPricesVisibleErr);

        //[THEN] Prices workload is not selectable.
        this.LibraryAssert.IsFalse(TempRecurringSyncBuffer.Selectable, OutboundPricesSelectableErr);

        //[THEN] Prices details include setup guidance.
        this.LibraryAssert.IsTrue(TempRecurringSyncBuffer.Details <> '', OverlayDetailErr);

        //[THEN] Prices setup opens the shop card.
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer."Setup Target"::"Shop Card", TempRecurringSyncBuffer."Setup Target", OverlaySetupTargetErr);
    end;

    [Test]
    procedure ReadinessDoesNotInferCustomerOrCompanyImportFromAutoCreateAlone()
    var
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        ShopifyShop: Record "Shpfy Shop";
        CompanyReadinessErr: Label 'Auto-create alone does not enable company import.';
        CompanyRowVisibleErr: Label 'A company row remains visible when neither direction is active.';
        CompanySetupGuidanceErr: Label 'Company setup guidance is shown.';
        CustomerDirectionErr: Label 'No active customer direction is displayed as Customers.';
        CustomerReadinessErr: Label 'An inbound update switch does not enable import when the import range is None.';
        CustomerRowVisibleErr: Label 'A customer row remains visible when neither direction is active.';
    begin
        //[SCENARIO] Readiness does not infer customer or company import from auto create alone.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop with auto-create but without customer and company import exists.
        this.CreateShopWithAutoCreateWithoutImport(ShopifyShop, 'SCHEDIMPORT');

        //[WHEN] Recommendations are built.
        this.ScheduleMgt.BuildRecommendations(ShopifyShop, TempRecurringSyncBuffer);

        //[THEN] Customers workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Customers), CustomerRowVisibleErr);

        //[THEN] Customers require setup.
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer.Readiness::"Setup required", TempRecurringSyncBuffer.Readiness, CustomerReadinessErr);

        //[THEN] Customers have no active direction.
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer.Synchronization::Customers, TempRecurringSyncBuffer.Synchronization, CustomerDirectionErr);

        //[THEN] Companies workload is recommended.
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Companies), CompanyRowVisibleErr);

        //[THEN] Companies require setup.
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer.Readiness::"Setup required", TempRecurringSyncBuffer.Readiness, CompanyReadinessErr);

        //[THEN] Companies setup guidance is shown.
        this.LibraryAssert.IsTrue(TempRecurringSyncBuffer.Details <> '', CompanySetupGuidanceErr);
    end;

    [Test]
    procedure CreatedScheduleDefinitionsUseNativeReportsAndRecognizedCoverage()
    var
        JobQueueEntries: array[10] of Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
    begin
        //[SCENARIO] Created schedule definitions use native reports and recognized coverage.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop exists.
        this.CreateShop(ShopifyShop, 'SCHEDCREATE');

        //[WHEN] Products schedule is created.
        this.CreateScheduleForWorkload(ShopifyShop, Enum::"Shpfy Sync Workload"::Products, 1440, JobQueueEntries[1]);

        //[WHEN] Prices schedule is created.
        this.CreateScheduleForWorkload(ShopifyShop, Enum::"Shpfy Sync Workload"::Prices, 360, JobQueueEntries[2]);

        //[WHEN] Inventory schedule is created.
        this.CreateScheduleForWorkload(ShopifyShop, Enum::"Shpfy Sync Workload"::Inventory, 360, JobQueueEntries[3]);

        //[WHEN] Orders schedule is created.
        this.CreateScheduleForWorkload(ShopifyShop, Enum::"Shpfy Sync Workload"::Orders, 30, JobQueueEntries[4]);

        //[WHEN] Shipments schedule is created.
        this.CreateScheduleForWorkload(ShopifyShop, Enum::"Shpfy Sync Workload"::Shipments, 120, JobQueueEntries[5]);

        //[WHEN] Customers schedule is created.
        this.CreateScheduleForWorkload(ShopifyShop, Enum::"Shpfy Sync Workload"::Customers, 240, JobQueueEntries[6]);

        //[WHEN] Companies schedule is created.
        this.CreateScheduleForWorkload(ShopifyShop, Enum::"Shpfy Sync Workload"::Companies, 240, JobQueueEntries[7]);

        //[WHEN] Product images schedule is created.
        this.CreateScheduleForWorkload(ShopifyShop, Enum::"Shpfy Sync Workload"::"Product Images", 1440, JobQueueEntries[8]);

        //[WHEN] Posted invoices schedule is created.
        this.CreateScheduleForWorkload(ShopifyShop, Enum::"Shpfy Sync Workload"::"Posted Invoices", 360, JobQueueEntries[9]);

        //[WHEN] Catalog prices schedule is created.
        this.CreateScheduleForWorkload(ShopifyShop, Enum::"Shpfy Sync Workload"::"Catalog Prices", 720, JobQueueEntries[10]);

        //[THEN] Products schedule uses its native report and current shop coverage.
        this.AssertCreatedSchedule(ShopifyShop, JobQueueEntries[1], Enum::"Shpfy Sync Workload"::Products, Report::"Shpfy Sync Products", 1440, Enum::"Shpfy Sync Coverage"::"Current Shop");

        //[THEN] Prices schedule uses its native report and current shop coverage.
        this.AssertCreatedSchedule(ShopifyShop, JobQueueEntries[2], Enum::"Shpfy Sync Workload"::Prices, Report::"Shpfy Sync Products", 360, Enum::"Shpfy Sync Coverage"::"Current Shop");

        //[THEN] Inventory schedule uses its native report and current shop coverage.
        this.AssertCreatedSchedule(ShopifyShop, JobQueueEntries[3], Enum::"Shpfy Sync Workload"::Inventory, Report::"Shpfy Sync Stock to Shopify", 360, Enum::"Shpfy Sync Coverage"::"Current Shop");

        //[THEN] Orders schedule uses its native report and current shop coverage.
        this.AssertCreatedSchedule(ShopifyShop, JobQueueEntries[4], Enum::"Shpfy Sync Workload"::Orders, Report::"Shpfy Sync Orders from Shopify", 30, Enum::"Shpfy Sync Coverage"::"Current Shop");

        //[THEN] Shipments schedule uses its native report and all shops coverage.
        this.AssertCreatedSchedule(ShopifyShop, JobQueueEntries[5], Enum::"Shpfy Sync Workload"::Shipments, Report::"Shpfy Sync Shipm. to Shopify", 120, Enum::"Shpfy Sync Coverage"::"All Shops");

        //[THEN] Customers schedule uses its native report and current shop coverage.
        this.AssertCreatedSchedule(ShopifyShop, JobQueueEntries[6], Enum::"Shpfy Sync Workload"::Customers, Report::"Shpfy Sync Customers", 240, Enum::"Shpfy Sync Coverage"::"Current Shop");

        //[THEN] Companies schedule uses its native report and current shop coverage.
        this.AssertCreatedSchedule(ShopifyShop, JobQueueEntries[7], Enum::"Shpfy Sync Workload"::Companies, Report::"Shpfy Sync Companies", 240, Enum::"Shpfy Sync Coverage"::"Current Shop");

        //[THEN] Product images schedule uses its native report and current shop coverage.
        this.AssertCreatedSchedule(ShopifyShop, JobQueueEntries[8], Enum::"Shpfy Sync Workload"::"Product Images", Report::"Shpfy Sync Images", 1440, Enum::"Shpfy Sync Coverage"::"Current Shop");

        //[THEN] Posted invoices schedule uses its native report and current shop coverage.
        this.AssertCreatedSchedule(ShopifyShop, JobQueueEntries[9], Enum::"Shpfy Sync Workload"::"Posted Invoices", Report::"Shpfy Sync Invoices to Shpfy", 360, Enum::"Shpfy Sync Coverage"::"Current Shop");

        //[THEN] Catalog prices schedule uses its native report and current shop coverage.
        this.AssertCreatedSchedule(ShopifyShop, JobQueueEntries[10], Enum::"Shpfy Sync Workload"::"Catalog Prices", Report::"Shpfy Sync Catalog Prices", 720, Enum::"Shpfy Sync Coverage"::"Current Shop");
    end;

    [Test]
    procedure DailyFirstRunUsesStableFutureShopSlot()
    var
        FirstJobQueueEntry: Record "Job Queue Entry";
        SecondJobQueueEntry: Record "Job Queue Entry";
        ShopifyShop: Record "Shpfy Shop";
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
        IsRecognized: Boolean;
        RecurringProductSyncTxt: Label 'Recurring product sync', Locked = true;
        FutureFirstRunErr: Label 'The daily first run must be in the future.';
        StableSlotErr: Label 'The daily first-run slot must be stable for the same shop.';
        MaxAttemptsErr: Label 'Recurring Shopify jobs use three attempts.';
        RerunDelayErr: Label 'Recurring Shopify jobs use a 60-second rerun delay.';
        JobQueueCategoryErr: Label 'Recurring Shopify jobs use the Shopify category.';
        ScheduleRecognizedErr: Label 'A generated daily schedule must use parameters recognized by the shared schedule matcher.';
        WorkloadRetainedErr: Label 'The daily schedule must retain its selected workload.';
        ShopCoverageErr: Label 'The generated product schedule must be shop-specific.';
    begin
        //[SCENARIO] Daily first run uses stable future shop slot.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] Shop exists.
        this.CreateShop(ShopifyShop, 'SCHEDDAILY');

        //[GIVEN] Products recurring sync buffer exists.
        this.CreateRecurringSyncBuffer(TempRecurringSyncBuffer, Enum::"Shpfy Sync Workload"::Products, RecurringProductSyncTxt);

        //[WHEN] First daily schedule is created.
        this.ScheduleMgt.CreateJobQueueEntry(ShopifyShop, TempRecurringSyncBuffer, 1440, FirstJobQueueEntry);

        //[WHEN] Second daily schedule is created.
        this.ScheduleMgt.CreateJobQueueEntry(ShopifyShop, TempRecurringSyncBuffer, 1440, SecondJobQueueEntry);

        //[WHEN] First schedule is recognized for the shop.
        IsRecognized := this.ScheduleMgt.IsRecognizedSchedule(FirstJobQueueEntry, ShopifyShop.Code, Workload, Coverage);

        //[THEN] First run is in the future.
        this.LibraryAssert.IsTrue(FirstJobQueueEntry."Earliest Start Date/Time" > CurrentDateTime(), FutureFirstRunErr);

        //[THEN] Starting time is stable for the same shop.
        this.LibraryAssert.AreEqual(FirstJobQueueEntry."Starting Time", SecondJobQueueEntry."Starting Time", StableSlotErr);

        //[THEN] Three attempts are allowed.
        this.LibraryAssert.AreEqual(3, FirstJobQueueEntry."Maximum No. of Attempts to Run", MaxAttemptsErr);

        //[THEN] Rerun delay is sixty seconds.
        this.LibraryAssert.AreEqual(60, FirstJobQueueEntry."Rerun Delay (sec.)", RerunDelayErr);

        //[THEN] Shopify job queue category is used.
        this.LibraryAssert.AreEqual('SHPFY', FirstJobQueueEntry."Job Queue Category Code", JobQueueCategoryErr);

        //[THEN] Schedule is recognized.
        this.LibraryAssert.IsTrue(IsRecognized, ScheduleRecognizedErr);

        //[THEN] Workload is products.
        this.LibraryAssert.AreEqual(Enum::"Shpfy Sync Workload"::Products, Workload, WorkloadRetainedErr);

        //[THEN] Coverage is current shop.
        this.LibraryAssert.AreEqual(Enum::"Shpfy Sync Coverage"::"Current Shop", Coverage, ShopCoverageErr);
    end;
    #endregion Tests

    #region Initialize
    local procedure Initialize()
    begin
        this.PermissionsMock.Stop();
        this.DeleteShopifyJobQueueEntries();
        this.DeleteRecurringScheduleTestShops();
    end;

    local procedure DeleteShopifyJobQueueEntries()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetFilter(
            "Object ID to Run",
            '%1|%2|%3|%4|%5|%6|%7|%8|%9',
            Report::"Shpfy Sync Products",
            Report::"Shpfy Sync Stock to Shopify",
            Report::"Shpfy Sync Orders from Shopify",
            Report::"Shpfy Sync Shipm. to Shopify",
            Report::"Shpfy Sync Customers",
            Report::"Shpfy Sync Companies",
            Report::"Shpfy Sync Images",
            Report::"Shpfy Sync Invoices to Shpfy",
            Report::"Shpfy Sync Catalog Prices");
        JobQueueEntry.DeleteAll(false);
    end;

    local procedure DeleteRecurringScheduleTestShops()
    var
        ShopifyPaymentTerms: Record "Shpfy Payment Terms";
        ShopifyShop: Record "Shpfy Shop";
        ShopifyShopLocation: Record "Shpfy Shop Location";
        TestShopCodeFilterTok: Label 'SCHED*', Locked = true;
    begin
        ShopifyShopLocation.SetFilter("Shop Code", TestShopCodeFilterTok);
        ShopifyShopLocation.DeleteAll(false);
        ShopifyPaymentTerms.SetFilter("Shop Code", TestShopCodeFilterTok);
        ShopifyPaymentTerms.DeleteAll(false);
        ShopifyShop.SetFilter(Code, TestShopCodeFilterTok);
        ShopifyShop.DeleteAll(false);
    end;
    #endregion Initialize

    #region Given
    local procedure ClearScheduleSelections(var GuidePage: TestPage "Shpfy Recurring Sync Guide")
    begin
        GuidePage.SelectionPart.First();
        repeat
            if GuidePage.SelectionPart.Selected.Editable() then begin
                GuidePage.SelectionPart.Selected.SetValue(false);
                GuidePage.SelectionPart.Selected.AssertEquals(false);
            end;
        until not GuidePage.SelectionPart.Next();
    end;

    local procedure CreateShop(var ShopifyShop: Record "Shpfy Shop"; ShopCode: Code[20])
    begin
        ShopifyShop.Init();
        ShopifyShop.Code := ShopCode;
        ShopifyShop.Insert(false);
    end;

    local procedure CreateProductsToShopifyShop(var ShopifyShop: Record "Shpfy Shop"; ShopCode: Code[20])
    begin
        this.CreateShop(ShopifyShop, ShopCode);
        ShopifyShop."Sync Item" := ShopifyShop."Sync Item"::"To Shopify";
        ShopifyShop."Can Update Shopify Products" := true;
        ShopifyShop."Allow Outgoing Requests" := true;
        ShopifyShop.Modify(false);
    end;

    local procedure CreateShopReadyForAllWorkloads(var ShopifyShop: Record "Shpfy Shop"; ShopCode: Code[20]; OrderCreatedWebhooks: Boolean)
    begin
        this.CreateShop(ShopifyShop, ShopCode);
        ShopifyShop."Sync Item" := ShopifyShop."Sync Item"::"To Shopify";
        ShopifyShop."Can Update Shopify Products" := true;
        ShopifyShop."Sync Item Images" := ShopifyShop."Sync Item Images"::"From Shopify";
        ShopifyShop."Customer Import From Shopify" := ShopifyShop."Customer Import From Shopify"::AllCustomers;
        ShopifyShop."Company Import From Shopify" := ShopifyShop."Company Import From Shopify"::AllCompanies;
        ShopifyShop."Order Created Webhooks" := OrderCreatedWebhooks;
        ShopifyShop."Posted Invoice Sync" := true;
        ShopifyShop."Allow Outgoing Requests" := true;
        ShopifyShop.Modify(false);
    end;

    local procedure CreateInboundShop(var ShopifyShop: Record "Shpfy Shop"; ShopCode: Code[20])
    begin
        this.CreateShop(ShopifyShop, ShopCode);
        ShopifyShop."Sync Item" := ShopifyShop."Sync Item"::"From Shopify";
        ShopifyShop."Auto Create Unknown Items" := true;
        ShopifyShop."Customer Import From Shopify" := ShopifyShop."Customer Import From Shopify"::WithOrderImport;
        ShopifyShop."Shopify Can Update Customer" := true;
        ShopifyShop."Can Update Shopify Customer" := true;
        ShopifyShop."Company Import From Shopify" := ShopifyShop."Company Import From Shopify"::WithOrderImport;
        ShopifyShop."Shopify Can Update Companies" := true;
        ShopifyShop."Can Update Shopify Companies" := true;
        ShopifyShop."Sync Item Images" := ShopifyShop."Sync Item Images"::"From Shopify";
        ShopifyShop."Allow Outgoing Requests" := true;
        ShopifyShop.Modify(false);
    end;

    local procedure CreateShopWithOutgoingRequestsDisabled(var ShopifyShop: Record "Shpfy Shop"; ShopCode: Code[20])
    begin
        this.CreateShop(ShopifyShop, ShopCode);
        ShopifyShop."Sync Item" := ShopifyShop."Sync Item"::"From Shopify";
        ShopifyShop."Auto Create Unknown Items" := true;
        ShopifyShop."Sync Item Images" := ShopifyShop."Sync Item Images"::"From Shopify";
        ShopifyShop."Customer Import From Shopify" := ShopifyShop."Customer Import From Shopify"::AllCustomers;
        ShopifyShop."Company Import From Shopify" := ShopifyShop."Company Import From Shopify"::AllCompanies;
        ShopifyShop."Allow Outgoing Requests" := false;
        ShopifyShop.Modify(false);
    end;

    local procedure CreateShopWithAutoCreateWithoutImport(var ShopifyShop: Record "Shpfy Shop"; ShopCode: Code[20])
    begin
        this.CreateShop(ShopifyShop, ShopCode);
        ShopifyShop."Customer Import From Shopify" := ShopifyShop."Customer Import From Shopify"::None;
        ShopifyShop."Shopify Can Update Customer" := true;
        ShopifyShop."Auto Create Unknown Customers" := true;
        ShopifyShop."Company Import From Shopify" := ShopifyShop."Company Import From Shopify"::None;
        ShopifyShop."Shopify Can Update Companies" := true;
        ShopifyShop."Auto Create Unknown Companies" := true;
        ShopifyShop.Modify(false);
    end;

    local procedure CreateShopLocation(ShopCode: Code[20]; LocationId: BigInteger; StockCalculation: Enum "Shpfy Stock Calculation")
    var
        ShopifyShopLocation: Record "Shpfy Shop Location";
    begin
        ShopifyShopLocation.Init();
        ShopifyShopLocation."Shop Code" := ShopCode;
        ShopifyShopLocation.Id := LocationId;
        ShopifyShopLocation."Stock Calculation" := StockCalculation;
        ShopifyShopLocation."Location Filter" := '';
        ShopifyShopLocation.Insert(false);
    end;

    local procedure CreateShopifyPaymentTerms(ShopCode: Code[20]; PaymentTermsCode: Code[10]; IsPrimary: Boolean)
    var
        ShopifyPaymentTerms: Record "Shpfy Payment Terms";
    begin
        ShopifyPaymentTerms.Init();
        ShopifyPaymentTerms."Shop Code" := ShopCode;
        ShopifyPaymentTerms.Id := 1;
        ShopifyPaymentTerms."Payment Terms Code" := PaymentTermsCode;
        ShopifyPaymentTerms."Is Primary" := IsPrimary;
        ShopifyPaymentTerms.Insert(false);
    end;

    local procedure CreateJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; ReportId: Integer; ReportParameters: Text)
    begin
        JobQueueEntry.Init();
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := ReportId;
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::"None (Processing only)";
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry.Insert(false);
        JobQueueEntry.SetReportParameters(ReportParameters);
    end;

    local procedure CreateProductScheduleForShop(var JobQueueEntry: Record "Job Queue Entry"; ShopCode: Code[20]; Frequency: Integer; Status: Integer)
    begin
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", this.ProductParameters('false', '0', ShopCode));
        JobQueueEntry."No. of Minutes between Runs" := Frequency;
        JobQueueEntry.Status := Status;
        JobQueueEntry.Modify(false);
    end;

    local procedure CreateNativePriceSchedule(var JobQueueEntry: Record "Job Queue Entry"; ShopifyShop: Record "Shpfy Shop"; UseFieldNames: Boolean; WithAdditionalFilter: Boolean)
    var
        NativeParametersTok: Label '<ReportParameters name="Shpfy Sync Products" id="%2"><Options><Field name="OnlySyncPrices">true</Field><Field name="NumberOfRecords">0</Field></Options><DataItems><DataItem name="Shop">%1</DataItem></DataItems></ReportParameters>', Comment = '%1 = Shop record view, %2 = Report ID', Locked = true;
    begin
        ShopifyShop.Reset();
        ShopifyShop.SetRecFilter();
        if WithAdditionalFilter then
            ShopifyShop.SetRange("Allow Outgoing Requests", false);
        this.CreateJobQueueEntry(JobQueueEntry, Report::"Shpfy Sync Products", StrSubstNo(NativeParametersTok, ShopifyShop.GetView(UseFieldNames), Format(Report::"Shpfy Sync Products", 0, 9)));
    end;

    local procedure CreateRecurringSyncBuffer(var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary; Workload: Enum "Shpfy Sync Workload"; Description: Text[250])
    begin
        TempRecurringSyncBuffer.Init();
        TempRecurringSyncBuffer.Workload := Workload;
        TempRecurringSyncBuffer.Description := Description;
    end;

    local procedure CreateSelectedRecommendation(var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary; Workload: Enum "Shpfy Sync Workload"; SyncDirection: Enum "Shpfy Sync Direction"; Description: Text[250])
    begin
        this.CreateRecurringSyncBuffer(TempRecurringSyncBuffer, Workload, Description);
        TempRecurringSyncBuffer."Entry No." := Workload.AsInteger();
        TempRecurringSyncBuffer.Synchronization := SyncDirection;
        TempRecurringSyncBuffer.Frequency := 1440;
        TempRecurringSyncBuffer.Selected := true;
        TempRecurringSyncBuffer.Insert();
    end;

    local procedure ProductParameters(OnlySyncPrice: Text; NumberOfRecords: Text; ShopFilter: Text): Text
    var
        DataItemText: Text;
    begin
        if ShopFilter = '' then
            DataItemText := 'Shpfy Shop'
        else
            DataItemText := 'Shpfy Shop: Code=' + ShopFilter;
        exit('<ReportParameters><Options><OnlySyncPrice>' + OnlySyncPrice + '</OnlySyncPrice><NumberOfRecords>' + NumberOfRecords + '</NumberOfRecords></Options><DataItems><DataItem name="Shop">' + DataItemText + '</DataItem></DataItems></ReportParameters>');
    end;
    #endregion Given

    #region When
    local procedure CreateScheduleForWorkload(ShopifyShop: Record "Shpfy Shop"; Workload: Enum "Shpfy Sync Workload"; Frequency: Integer; var JobQueueEntry: Record "Job Queue Entry")
    var
        TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary;
        RecurringSyncTestTxt: Label 'Recurring sync test', Locked = true;
    begin
        this.CreateRecurringSyncBuffer(TempRecurringSyncBuffer, Workload, RecurringSyncTestTxt);
        this.ScheduleMgt.CreateJobQueueEntry(ShopifyShop, TempRecurringSyncBuffer, Frequency, JobQueueEntry);
    end;
    #endregion When

    #region Then
    local procedure FindRecommendation(var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary; Workload: Enum "Shpfy Sync Workload"): Boolean
    begin
        TempRecurringSyncBuffer.Reset();
        TempRecurringSyncBuffer.SetRange(Workload, Workload);
        exit(TempRecurringSyncBuffer.FindFirst());
    end;

    local procedure HasRecognizedSchedule(ShopCode: Code[20]; ExpectedWorkload: Enum "Shpfy Sync Workload"; ExpectedCoverage: Enum "Shpfy Sync Coverage"): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        Workload: Enum "Shpfy Sync Workload";
        Coverage: Enum "Shpfy Sync Coverage";
    begin
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        if JobQueueEntry.FindSet(false) then
            repeat
                if this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, ShopCode, Workload, Coverage) then
                    if (Workload = ExpectedWorkload) and (Coverage = ExpectedCoverage) then
                        exit(true);
            until JobQueueEntry.Next() = 0;
        exit(false);
    end;

    local procedure CountRecurringProductJobQueueEntries(): Integer
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Shpfy Sync Products");
        exit(JobQueueEntry.Count());
    end;

    local procedure ProductJobQueueEntryExists(Description: Text): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Report);
        JobQueueEntry.SetRange("Object ID to Run", Report::"Shpfy Sync Products");
        JobQueueEntry.SetRange(Description, Description);
        exit(not JobQueueEntry.IsEmpty());
    end;

    local procedure AssertRecommendation(var TempRecurringSyncBuffer: Record "Shpfy Recurring Sync Buffer" temporary; Workload: Enum "Shpfy Sync Workload"; ExpectedFrequency: Integer; ExpectedDirection: Enum "Shpfy Sync Direction")
    var
        NotScheduledErr: Label 'Ready workload %1 must be marked Not scheduled.', Comment = '%1 = Synchronization workload';
        PlannedDirectionErr: Label 'Workload %1 must use the planned synchronization direction.', Comment = '%1 = Synchronization workload';
        PlannedFrequencyErr: Label 'Workload %1 must use the planned frequency in minutes.', Comment = '%1 = Synchronization workload';
        SelectableErr: Label 'Ready workload %1 must be selectable.', Comment = '%1 = Synchronization workload';
        SelectedByDefaultErr: Label 'Ready workload %1 must be selected by default.', Comment = '%1 = Synchronization workload';
        WorkloadPresentErr: Label 'Workload %1 must be present.', Comment = '%1 = Synchronization workload';
    begin
        this.LibraryAssert.IsTrue(this.FindRecommendation(TempRecurringSyncBuffer, Workload), StrSubstNo(WorkloadPresentErr, Format(Workload)));
        this.LibraryAssert.AreEqual(ExpectedFrequency, TempRecurringSyncBuffer.Frequency, StrSubstNo(PlannedFrequencyErr, Format(Workload)));
        this.LibraryAssert.AreEqual(ExpectedDirection, TempRecurringSyncBuffer.Synchronization, StrSubstNo(PlannedDirectionErr, Format(Workload)));
        this.LibraryAssert.AreEqual(TempRecurringSyncBuffer.Readiness::"Not scheduled", TempRecurringSyncBuffer.Readiness, StrSubstNo(NotScheduledErr, Format(Workload)));
        this.LibraryAssert.IsTrue(TempRecurringSyncBuffer.Selected, StrSubstNo(SelectedByDefaultErr, Format(Workload)));
        this.LibraryAssert.IsTrue(TempRecurringSyncBuffer.Selectable, StrSubstNo(SelectableErr, Format(Workload)));
    end;

    local procedure AssertCreatedSchedule(ShopifyShop: Record "Shpfy Shop"; JobQueueEntry: Record "Job Queue Entry"; Workload: Enum "Shpfy Sync Workload"; ExpectedReportId: Integer; ExpectedFrequency: Integer; ExpectedCoverage: Enum "Shpfy Sync Coverage")
    var
        TempJobQueueEntryBuffer: Record "Job Queue Entry" temporary;
        TempExistingSchedules: Record "Shpfy Recurring Sync Buffer" temporary;
        TempRecommendations: Record "Shpfy Recurring Sync Buffer" temporary;
        ActualWorkload: Enum "Shpfy Sync Workload";
        ActualCoverage: Enum "Shpfy Sync Coverage";
        HasExistingSchedules: Boolean;
        ExpectedReportParametersRoot: Text;
        ReportParametersRootTok: Label '<ReportParameters name="%1" id="%2">', Comment = '%1 = Report name, %2 = Report ID', Locked = true;
        ExistingReportErr: Label 'Workload %1 must use its existing processing report.', Comment = '%1 = Synchronization workload';
        FrequencyErr: Label 'Workload %1 must preserve its selected frequency.', Comment = '%1 = Synchronization workload';
        ProcessingOnlyErr: Label 'Recurring sync entries must be processing-only.';
        OnHoldStatusErr: Label 'A new job definition is created On Hold before activation.';
        ReportParametersErr: Label 'Workload %1 must store report parameters with the report name and ID.', Comment = '%1 = Synchronization workload';
        ParametersRecognizedErr: Label 'The generated report parameters for %1 must be recognized.', Comment = '%1 = Synchronization workload';
        WorkloadModeErr: Label 'Generated parameters must retain the selected workload mode.';
        ShopCoverageErr: Label 'Generated parameters must use the intended shop coverage.';
        ReopenedSetupErr: Label 'Reopening setup must omit the persisted %1 workload.', Comment = '%1 = Synchronization workload';
        ExistingScheduleErr: Label 'The existing-schedules view must contain the persisted Job Queue Entry.';
    begin
        JobQueueEntry.Get(JobQueueEntry.ID);
        this.LibraryAssert.AreEqual(ExpectedReportId, JobQueueEntry."Object ID to Run", StrSubstNo(ExistingReportErr, Format(Workload)));
        this.LibraryAssert.AreEqual(ExpectedFrequency, JobQueueEntry."No. of Minutes between Runs", StrSubstNo(FrequencyErr, Format(Workload)));
        this.LibraryAssert.AreEqual(JobQueueEntry."Report Output Type"::"None (Processing only)", JobQueueEntry."Report Output Type", ProcessingOnlyErr);
        this.LibraryAssert.AreEqual(JobQueueEntry.Status::"On Hold", JobQueueEntry.Status, OnHoldStatusErr);
        ExpectedReportParametersRoot := StrSubstNo(ReportParametersRootTok, this.GetReportName(Workload), Format(ExpectedReportId, 0, 9));
        this.LibraryAssert.IsTrue(StrPos(JobQueueEntry.GetReportParameters(), ExpectedReportParametersRoot) > 0, StrSubstNo(ReportParametersErr, Format(Workload)));
        this.LibraryAssert.IsTrue(this.ScheduleMgt.IsRecognizedSchedule(JobQueueEntry, ShopifyShop.Code, ActualWorkload, ActualCoverage), StrSubstNo(ParametersRecognizedErr, Format(Workload)));
        this.LibraryAssert.AreEqual(Workload, ActualWorkload, WorkloadModeErr);
        this.LibraryAssert.AreEqual(ExpectedCoverage, ActualCoverage, ShopCoverageErr);
        this.ScheduleMgt.BuildRecommendationsWithScheduleState(ShopifyShop, TempRecommendations, HasExistingSchedules);
        this.LibraryAssert.IsTrue(HasExistingSchedules, StrSubstNo(ReopenedSetupErr, Format(Workload)));
        this.LibraryAssert.IsFalse(this.FindRecommendation(TempRecommendations, Workload), StrSubstNo(ReopenedSetupErr, Format(Workload)));
        this.ScheduleMgt.BuildExistingScheduleEntries(ShopifyShop, TempJobQueueEntryBuffer, TempExistingSchedules);
        this.LibraryAssert.IsTrue(TempJobQueueEntryBuffer.Get(JobQueueEntry.ID), ExistingScheduleErr);
    end;

    local procedure GetReportName(Workload: Enum "Shpfy Sync Workload"): Text
    var
        UnsupportedWorkloadErr: Label 'The synchronization workload %1 is not supported.', Comment = '%1 = Synchronization workload';
    begin
        case Workload of
            Workload::Products, Workload::Prices:
                exit('Shpfy Sync Products');
            Workload::Inventory:
                exit('Shpfy Sync Stock to Shopify');
            Workload::Orders:
                exit('Shpfy Sync Orders from Shopify');
            Workload::Shipments:
                exit('Shpfy Sync Shipm. to Shopify');
            Workload::Customers:
                exit('Shpfy Sync Customers');
            Workload::Companies:
                exit('Shpfy Sync Companies');
            Workload::"Product Images":
                exit('Shpfy Sync Images');
            Workload::"Posted Invoices":
                exit('Shpfy Sync Invoices to Shpfy');
            Workload::"Catalog Prices":
                exit('Shpfy Sync Catalog Prices');
        end;
        Error(UnsupportedWorkloadErr, Format(Workload));
    end;

    [MessageHandler]
    procedure FrequencyMessageHandler(Message: Text[1024])
    var
        FrequencyMessageTxt: Label 'Frequency must be greater than zero for Products to Shopify.', Locked = true;
        FrequencyMessageErr: Label 'A blank or zero frequency must show the frequency message for the workload.';
    begin
        this.LibraryAssert.AreEqual(FrequencyMessageTxt, Message, FrequencyMessageErr);
    end;
    #endregion Then
}
