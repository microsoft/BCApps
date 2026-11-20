// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;
using System.Threading;

codeunit 139416 "Shpfy Recurring Sched. UI Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Any: Codeunit Any;
        LibraryAssert: Codeunit "Library Assert";
        ScheduleMgt: Codeunit "Shpfy Recurring Schedule Mgt.";
        TestShopCodePrefixTok: Label 'SCHED', Locked = true;

    #region Tests
    [Test]
    procedure GuideOpensOnWelcomeStepWithOnlyNextEnabled()
    var
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        WelcomeBackErr: Label 'Back must be disabled on the Welcome step.';
        WelcomeFinishErr: Label 'Finish must be disabled on the Welcome step.';
        WelcomeNextErr: Label 'Next must be enabled on the Welcome step.';
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
    begin
        //[SCENARIO] The guide opens on the Welcome step, where only Next is enabled.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop);

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
        GuidePage.Close();
    end;

    [Test]
    procedure NextOnWelcomeStepOpensSelectionStepWithBackAndFinishEnabled()
    var
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        SelectionBackErr: Label 'Back must be enabled on the selection step.';
        SelectionFinishErr: Label 'Finish must be enabled on the selection step.';
        SelectionNextErr: Label 'Next must be disabled on the selection step.';
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
    begin
        //[SCENARIO] Next on the Welcome step opens the selection step, where Back and Finish are enabled.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop);

        //[GIVEN] The guide is initialized for the shop.
        RecurringSyncGuide.SetShop(ShopifyShop);

        //[GIVEN] The guide page is trapped.
        GuidePage.Trap();

        //[GIVEN] The guide opens.
        RecurringSyncGuide.Run();

        //[WHEN] Next opens the selection step.
        GuidePage.ActionNext.Invoke();

        //[THEN] Back is enabled on the selection step.
        this.LibraryAssert.IsTrue(GuidePage.ActionBack.Enabled(), SelectionBackErr);

        //[THEN] Next is disabled on the selection step.
        this.LibraryAssert.IsFalse(GuidePage.ActionNext.Enabled(), SelectionNextErr);

        //[THEN] Finish is enabled on the selection step.
        this.LibraryAssert.IsTrue(GuidePage.ActionFinish.Enabled(), SelectionFinishErr);
        GuidePage.Close();
    end;

    [Test]
    procedure BackOnSelectionStepReturnsToWelcomeStep()
    var
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        WelcomeNextErr: Label 'Next must be enabled on the Welcome step.';
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
    begin
        //[SCENARIO] Back on the selection step returns to the Welcome step.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop);

        //[GIVEN] The guide is initialized for the shop.
        RecurringSyncGuide.SetShop(ShopifyShop);

        //[GIVEN] The guide page is trapped.
        GuidePage.Trap();

        //[GIVEN] The guide opens.
        RecurringSyncGuide.Run();

        //[GIVEN] The selection step is opened.
        GuidePage.ActionNext.Invoke();

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
        NoSelectionFinishErr: Label 'Finish must be disabled when no synchronization is selected.';
        SelectedFinishErr: Label 'Finish must be enabled after selecting a ready synchronization.';
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
    begin
        //[SCENARIO] Finish requires at least one selected synchronization.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop);

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
    procedure ZeroFrequencyOnSelectedWorkloadDisablesFinish()
    var
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        InvalidFrequencyFinishErr: Label 'Finish must be disabled when any selected synchronization has a nonpositive frequency.';
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
    begin
        //[SCENARIO] A zero frequency on a selected workload shows a message and disables Finish.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop);

        //[GIVEN] The guide is opened on the selection step with the first workload current.
        RecurringSyncGuide.SetShop(ShopifyShop);
        GuidePage.Trap();
        RecurringSyncGuide.Run();
        GuidePage.ActionNext.Invoke();
        GuidePage.SelectionPart.First();

        //[WHEN] The selected workload gets a zero frequency.
        GuidePage.SelectionPart.Frequency.SetValue(0);

        //[THEN] Finish is disabled.
        this.LibraryAssert.IsFalse(GuidePage.ActionFinish.Enabled(), InvalidFrequencyFinishErr);
        GuidePage.Close();
    end;

    [Test]
    [HandlerFunctions('FrequencyMessageHandler')]
    procedure NegativeFrequencyOnSelectedWorkloadDisablesFinish()
    var
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        InvalidFrequencyFinishErr: Label 'Finish must be disabled when any selected synchronization has a nonpositive frequency.';
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
    begin
        //[SCENARIO] A negative frequency on a selected workload shows a message and disables Finish.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop);

        //[GIVEN] The guide is opened on the selection step with the first workload current.
        RecurringSyncGuide.SetShop(ShopifyShop);
        GuidePage.Trap();
        RecurringSyncGuide.Run();
        GuidePage.ActionNext.Invoke();
        GuidePage.SelectionPart.First();

        //[WHEN] The selected workload gets a negative frequency.
        GuidePage.SelectionPart.Frequency.SetValue(-1);

        //[THEN] Finish is disabled for negative frequencies too.
        this.LibraryAssert.IsFalse(GuidePage.ActionFinish.Enabled(), InvalidFrequencyFinishErr);
        GuidePage.Close();
    end;

    [Test]
    [HandlerFunctions('FrequencyMessageHandler')]
    procedure MovingToAnotherRowKeepsFinishDisabledForInvalidFrequency()
    var
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        InvalidFrequencyFinishErr: Label 'Finish must be disabled when any selected synchronization has a nonpositive frequency.';
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
    begin
        //[SCENARIO] An invalid frequency on a selected workload keeps Finish disabled when another row becomes current.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop);

        //[GIVEN] The guide is opened on the selection step with the first workload current.
        RecurringSyncGuide.SetShop(ShopifyShop);
        GuidePage.Trap();
        RecurringSyncGuide.Run();
        GuidePage.ActionNext.Invoke();
        GuidePage.SelectionPart.First();

        //[GIVEN] The selected workload has an invalid frequency.
        GuidePage.SelectionPart.Frequency.SetValue(0);

        //[WHEN] Another row becomes current.
        GuidePage.SelectionPart.Next();

        //[THEN] The invalid selected frequency still disables Finish.
        this.LibraryAssert.IsFalse(GuidePage.ActionFinish.Enabled(), InvalidFrequencyFinishErr);
        GuidePage.Close();
    end;

    [Test]
    [HandlerFunctions('FrequencyMessageHandler')]
    procedure DeselectingWorkloadWithInvalidFrequencyEnablesFinish()
    var
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        UnselectedFrequencyFinishErr: Label 'An invalid frequency on an unselected synchronization must not disable Finish.';
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
    begin
        //[SCENARIO] An invalid frequency on an unselected workload does not disable Finish.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop);

        //[GIVEN] The guide is opened on the selection step with the first workload current.
        RecurringSyncGuide.SetShop(ShopifyShop);
        GuidePage.Trap();
        RecurringSyncGuide.Run();
        GuidePage.ActionNext.Invoke();
        GuidePage.SelectionPart.First();

        //[GIVEN] The selected workload has an invalid frequency.
        GuidePage.SelectionPart.Frequency.SetValue(0);

        //[WHEN] The invalid workload is deselected.
        GuidePage.SelectionPart.Selected.SetValue(false);

        //[THEN] The remaining valid selected workloads enable Finish.
        this.LibraryAssert.IsTrue(GuidePage.ActionFinish.Enabled(), UnselectedFrequencyFinishErr);
        GuidePage.Close();
    end;

    [Test]
    [HandlerFunctions('FrequencyMessageHandler')]
    procedure ReselectingWorkloadWithInvalidFrequencyDisablesFinish()
    var
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        InvalidFrequencyFinishErr: Label 'Finish must be disabled when any selected synchronization has a nonpositive frequency.';
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
    begin
        //[SCENARIO] Selecting a workload with an invalid frequency again disables Finish.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop);

        //[GIVEN] The guide is opened on the selection step with the first workload current.
        RecurringSyncGuide.SetShop(ShopifyShop);
        GuidePage.Trap();
        RecurringSyncGuide.Run();
        GuidePage.ActionNext.Invoke();
        GuidePage.SelectionPart.First();

        //[GIVEN] The workload has an invalid frequency and is deselected.
        GuidePage.SelectionPart.Frequency.SetValue(0);
        GuidePage.SelectionPart.Selected.SetValue(false);

        //[WHEN] The invalid workload is selected again.
        GuidePage.SelectionPart.Selected.SetValue(true);

        //[THEN] Finish is disabled again.
        this.LibraryAssert.IsFalse(GuidePage.ActionFinish.Enabled(), InvalidFrequencyFinishErr);
        GuidePage.Close();
    end;

    [Test]
    [HandlerFunctions('FrequencyMessageHandler')]
    procedure CorrectingInvalidFrequencyEnablesFinish()
    var
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        ValidFrequencyFinishErr: Label 'Finish must be enabled after correcting every selected frequency.';
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
    begin
        //[SCENARIO] Correcting an invalid frequency enables Finish again.

        //[GIVEN] No recurring Shopify synchronization job queue entries exist.
        //[GIVEN] No recurring schedule test shops exist.
        this.Initialize();

        //[GIVEN] A shop with ready product synchronizations exists.
        this.CreateProductsToShopifyShop(ShopifyShop);

        //[GIVEN] The guide is opened on the selection step with the first workload current.
        RecurringSyncGuide.SetShop(ShopifyShop);
        GuidePage.Trap();
        RecurringSyncGuide.Run();
        GuidePage.ActionNext.Invoke();
        GuidePage.SelectionPart.First();

        //[GIVEN] The selected workload has an invalid frequency.
        GuidePage.SelectionPart.Frequency.SetValue(0);

        //[WHEN] The invalid frequency is corrected.
        GuidePage.SelectionPart.Frequency.SetValue(1440);

        //[THEN] Finish is enabled again.
        this.LibraryAssert.IsTrue(GuidePage.ActionFinish.Enabled(), ValidFrequencyFinishErr);
        GuidePage.Close();
    end;

    [Test]
    procedure FinishIsDisabledWhenOnlyUnavailableWorkloadsRemain()
    var
        JobQueueEntry: Record "Job Queue Entry";
        TempRecommendations: Record "Shpfy Recurring Sync Buffer" temporary;
        ShopifyShop: Record "Shpfy Shop";
        RecurringSyncGuide: Page "Shpfy Recurring Sync Guide";
        NoReadyWorkloadsErr: Label 'Finish must be disabled when all ready workloads are already scheduled.';
        GuidePage: TestPage "Shpfy Recurring Sync Guide";
    begin
        //[SCENARIO] Finish is disabled when only unavailable workloads remain.

        //[GIVEN] No recurring Shopify synchronization job queue entries or test shops exist.
        this.Initialize();

        //[GIVEN] A shop with incomplete synchronization setup exists.
        this.CreateShop(ShopifyShop);

        //[GIVEN] Every ready workload is already scheduled.
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
    #endregion Tests

    #region Initialize
    local procedure Initialize()
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        this.DeleteShopifyJobQueueEntries();
        this.DeleteRecurringScheduleTestShops();
        JobQueueCategory.InsertRec('SHPFY', 'Shopify');
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
        TestShopCodeFilter: Text;
    begin
        TestShopCodeFilter := this.TestShopCodePrefixTok + '*';
        ShopifyShopLocation.SetFilter("Shop Code", TestShopCodeFilter);
        ShopifyShopLocation.DeleteAll(false);
        ShopifyPaymentTerms.SetFilter("Shop Code", TestShopCodeFilter);
        ShopifyPaymentTerms.DeleteAll(false);
        ShopifyShop.SetFilter(Code, TestShopCodeFilter);
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

    local procedure CreateShop(var ShopifyShop: Record "Shpfy Shop")
    begin
        ShopifyShop.Init();
        ShopifyShop.Code := CopyStr(this.TestShopCodePrefixTok + this.Any.AlphabeticText(15), 1, MaxStrLen(ShopifyShop.Code));
        ShopifyShop.Insert(false);
    end;

    local procedure CreateProductsToShopifyShop(var ShopifyShop: Record "Shpfy Shop")
    begin
        this.CreateShop(ShopifyShop);
        ShopifyShop."Sync Item" := ShopifyShop."Sync Item"::"To Shopify";
        ShopifyShop."Can Update Shopify Products" := true;
        ShopifyShop."Allow Outgoing Requests" := true;
        ShopifyShop.Modify(false);
    end;
    #endregion Given

    #region Handlers
    [MessageHandler]
    procedure FrequencyMessageHandler(Message: Text[1024])
    var
        FrequencyMessageErr: Label 'A blank or zero frequency must show the frequency message for the workload.';
        FrequencyMessageTxt: Label 'Frequency must be greater than zero for Products to Shopify.', Locked = true;
    begin
        this.LibraryAssert.AreEqual(FrequencyMessageTxt, Message, FrequencyMessageErr);
    end;
    #endregion Handlers
}
