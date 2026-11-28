namespace System.Test.AI;

using System.AI;
using System.TestLibraries.AI;
using System.TestLibraries.Utilities;

codeunit 132683 "Copilot Test"
{
    Subtype = Test;

    var
        CopilotCapability: Codeunit "Copilot Capability";
        CopilotTestLibrary: Codeunit "Copilot Test Library";
        LibraryAssert: Codeunit "Library Assert";
        LearnMoreUrlLbl: Label 'http://LearnMore.com', Locked = true;
        LearnMoreUrl2Lbl: Label 'http://LearnMore2.com', Locked = true;
        NotRegisteredErr: Label 'Copilot capability has not been registered by the module.';
        AlreadyRegisteredErr: Label 'Capability has already been registered.';
        InvalidBillingTypeErr: Label 'Invalid billing type for Copilot capability ''%1''', Comment = '%1 is the name of the Copilot Capability';
        ConsumptionIdMustBeSpecifiedErr: Label 'The consumption ID must be specified.';
        TrialIdMustBeSpecifiedErr: Label 'The trial ID must be specified.';
        QuotaLimitsMustBeNonNegativeErr: Label 'All trial quota limits must be non-negative.';

    [Test]
    procedure MonetizationOverrideIsScoped()
    var
        Quota: Codeunit "Copilot Quota";
        Mock: Codeunit "Copilot Test Library";
    begin
        LibraryAssert.IsFalse(Quota.IsNewMonetizationEnabled(), 'Legacy monetization must be the default.');
        Mock.SetNewMonetizationEnabled(true);
        BindSubscription(Mock);
        LibraryAssert.IsTrue(Quota.IsNewMonetizationEnabled(), 'The bound test must be able to select V2.');
        UnbindSubscription(Mock);
        LibraryAssert.IsFalse(Quota.IsNewMonetizationEnabled(), 'Unbinding must restore V1 without persistent configuration.');
    end;

    [Test]
    procedure V2QuotaDenialAndUnknownAmountsArePreserved()
    var
        Snapshot: Record "AI Consumption Quota" temporary;
        Quota: Codeunit "Copilot Quota";
        Mock: Codeunit "Copilot Test Library";
        PrincipalId: Guid;
        Results: Dictionary of [Text, Text];
    begin
        Mock.SetNewMonetizationEnabled(true);
        Mock.SetAIConsumptionQuota(false, false, -1, -1);
        BindSubscription(Mock);
        LibraryAssert.IsFalse(Quota.CanConsume(), 'A denied V2 decision must not fall back to V1.');
        PrincipalId := CreateGuid();
        Quota.GetAIConsumptionQuota(PrincipalId, Snapshot);
        LibraryAssert.AreEqual(PrincipalId, Mock.GetLastQuotaPrincipalId(), 'The billed principal must be forwarded.');
        LibraryAssert.AreEqual(-1, Snapshot."AI Credit Limit", 'An unavailable limit must not become zero.');
        LibraryAssert.AreEqual(-1, Snapshot."Consumed AI Credits", 'Unavailable usage must not become zero.');
        Mock.GetQuotaResults(Results);
        LibraryAssert.IsFalse(Results.ContainsKey('QuotaUsedPercentage'), 'Unknown usage must not be presented as a percentage.');
        UnbindSubscription(Mock);
    end;

    [Test]
    procedure V2QuotaBackgroundResultUsesMeasuredAmounts()
    var
        Quota: Codeunit "Copilot Quota";
        Mock: Codeunit "Copilot Test Library";
        Results: Dictionary of [Text, Text];
        Percentage: Decimal;
    begin
        Mock.SetNewMonetizationEnabled(true);
        Mock.SetAIConsumptionQuota(true, false, 100, 85);
        BindSubscription(Mock);
        LibraryAssert.IsTrue(Quota.CanConsume(), 'An allowed V2 decision must not inherit the legacy API decision.');
        Mock.GetQuotaResults(Results);
        Evaluate(Percentage, Results.Get('QuotaUsedPercentage'));
        LibraryAssert.AreEqual(85, Percentage, 'Background quota warnings must use the V2 amounts.');
        Mock.SetAIConsumptionQuota(true, true, -1, -1);
        Mock.GetQuotaResults(Results);
        LibraryAssert.IsFalse(Results.ContainsKey('QuotaUsedPercentage'), 'A paid source must not retain an earlier trial percentage.');
        UnbindSubscription(Mock);
    end;

    [Test]
    procedure TestRegisterCapability()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
        CurrentModuleInfo: ModuleInfo;
    begin
        // [SCENARIO] Register a copilot capability

        // [GIVEN] Copilot capability is not registered
        Initialize();

        // [WHEN] RegisterCapability is called
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);

        // [THEN] Copilot capability is registered
        LibraryAssert.IsTrue(CopilotSettingsTestLibrary.FindFirst(), 'Copilot capability should be registered');
        LibraryAssert.AreEqual(Enum::"Copilot Capability"::"Text Capability", CopilotSettingsTestLibrary.GetCapability(), 'Copilot capability is not "Text Capability"');

        // [THEN] Registered capability is associated with the current module
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        LibraryAssert.AreEqual(CurrentModuleInfo.Id(), CopilotSettingsTestLibrary.GetAppId(), 'App Id is different from the current module');

        // [THEN] Registered capability is in preview
        LibraryAssert.AreEqual(Enum::"Copilot Availability"::Preview, CopilotSettingsTestLibrary.GetAvailability(), 'Availability is not preview');
    end;

    [Test]
    procedure TestRegisterCapabilityAlreadyRegistered()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
    begin
        // [SCENARIO] Register a copilot capability

        // [GIVEN] Copilot capability is not registered
        Initialize();

        // [WHEN] RegisterCapability is called
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);
        LibraryAssert.IsFalse(CopilotSettingsTestLibrary.IsEmpty(), 'Copilot capability should be registered');

        // [WHEN] RegisterCapability is called again
        asserterror CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);
        LibraryAssert.ExpectedError(AlreadyRegisteredErr);
    end;

    [Test]
    procedure TestRegisterCapabilityWithGAAvailability()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
        CurrentModuleInfo: ModuleInfo;
    begin
        // [SCENARIO] Register a copilot capability with availability set to Generally Available

        // [GIVEN] Copilot capability is not registered
        Initialize();

        // [WHEN] RegisterCapability is called
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Not Billed", LearnMoreUrlLbl);

        // [THEN] Copilot capability is registered
        LibraryAssert.IsTrue(CopilotSettingsTestLibrary.FindFirst(), 'Copilot capability should be registered');
        LibraryAssert.AreEqual(Enum::"Copilot Capability"::"Text Capability", CopilotSettingsTestLibrary.GetCapability(), 'Copilot capability is not "Text Capability"');

        // [THEN] Registered capability is associated with the current module
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        LibraryAssert.AreEqual(CurrentModuleInfo.Id(), CopilotSettingsTestLibrary.GetAppId(), 'App Id is different from the current module');

        // [THEN] Registered capability is generally available
        LibraryAssert.AreEqual(Enum::"Copilot Availability"::"Generally Available", CopilotSettingsTestLibrary.GetAvailability(), 'Availability is not Generally Available');
    end;

    [Test]
    procedure TestRegisterCapabilityWithInvalidBillingType()
    var
        ErrorMessage: Text;
    begin
        // [SCENARIO] Register a copilot capability with invalid billing type

        // [GIVEN] Copilot capability is not registered
        Initialize();

        // [WHEN] RegisterCapability is called
        asserterror CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::Undefined, LearnMoreUrlLbl);

        // [THEN] Registered capability should throw an error
        ErrorMessage := StrSubstNo(InvalidBillingTypeErr, Enum::"Copilot Capability"::"Text Capability");
        LibraryAssert.ExpectedError(ErrorMessage);
    end;

    [Test]
    procedure TestModifyCapability()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
    begin
        // [SCENARIO] Modify a copilot capability

        // [GIVEN] Copilot capability is registered
        Initialize();
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);

        // [WHEN] ModifyCapability is called
        CopilotCapability.ModifyCapability(Enum::"Copilot Capability"::"Text Capability", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Not Billed", LearnMoreUrl2Lbl);

        // [THEN] Copilot capability is modified
        CopilotSettingsTestLibrary.FindFirst();
        LibraryAssert.AreEqual(Enum::"Copilot Availability"::"Generally Available", CopilotSettingsTestLibrary.GetAvailability(), 'Availability is not Generally Available');
        LibraryAssert.AreEqual(LearnMoreUrl2Lbl, CopilotSettingsTestLibrary.GetLearnMoreUrl(), 'Learn More Url is not updated');
        LibraryAssert.AreEqual(Enum::"Copilot Status"::Active, CopilotSettingsTestLibrary.GetStatus(), 'Status is not Active');
        LibraryAssert.AreEqual(Enum::"Copilot Billing Type"::"Not Billed", CopilotSettingsTestLibrary.GetBillingType(), 'Billing Type is not Not Billed');
    end;

    [Test]
    procedure TestModifyCapabilityInactiveCapabilityToGA()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
    begin
        // [SCENARIO] Modify a copilot capability

        // [GIVEN] Copilot capability is registered
        Initialize();
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);
        CopilotTestLibrary.SetCopilotStatus(Enum::"Copilot Capability"::"Text Capability", GetModuleAppId(), Enum::"Copilot Status"::Inactive);

        CopilotSettingsTestLibrary.FindFirst();
        LibraryAssert.AreEqual(Enum::"Copilot Status"::Inactive, CopilotSettingsTestLibrary.GetStatus(), 'Status is not Inactive');

        // [WHEN] ModifyCapability is called
        CopilotCapability.ModifyCapability(Enum::"Copilot Capability"::"Text Capability", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Not Billed", LearnMoreUrl2Lbl);

        // [THEN] Copilot capability is modified
        CopilotSettingsTestLibrary.FindFirst();
        LibraryAssert.AreEqual(Enum::"Copilot Availability"::"Generally Available", CopilotSettingsTestLibrary.GetAvailability(), 'Availability is not Generally Available');
        LibraryAssert.AreEqual(LearnMoreUrl2Lbl, CopilotSettingsTestLibrary.GetLearnMoreUrl(), 'Learn More Url is not updated');
        LibraryAssert.AreEqual(Enum::"Copilot Status"::Active, CopilotSettingsTestLibrary.GetStatus(), 'Status is not Active');
        LibraryAssert.AreEqual(Enum::"Copilot Billing Type"::"Not Billed", CopilotSettingsTestLibrary.GetBillingType(), 'Billing Type is not Not Billed');
    end;

    [Test]
    procedure TestModifyCapabilityWithInvalidBillingType()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
        ErrorMessage: Text;
    begin
        // [SCENARIO] Modify a copilot capability

        // [GIVEN] Copilot capability is registered
        Initialize();
        //CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", Enum::"Copilot Availability"::Preview, Enum::"Copilot Billing Type"::"Not Billed", LearnMoreUrlLbl);
        // [WHEN] ModifyCapability is called
        asserterror CopilotCapability.ModifyCapability(Enum::"Copilot Capability"::"Text Capability", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::Undefined, LearnMoreUrl2Lbl);
        ErrorMessage := StrSubstNo(InvalidBillingTypeErr, Enum::"Copilot Capability"::"Text Capability");
        LibraryAssert.ExpectedError(ErrorMessage);
        // Copilot capability is not modified
        CopilotSettingsTestLibrary.FindFirst();
        LibraryAssert.AreEqual(Enum::"Copilot Availability"::Preview, CopilotSettingsTestLibrary.GetAvailability(), 'Availability is updated to Generally Available');
        LibraryAssert.AreEqual(LearnMoreUrlLbl, CopilotSettingsTestLibrary.GetLearnMoreUrl(), 'Learn More Url is updated');
        LibraryAssert.AreEqual(Enum::"Copilot Status"::Active, CopilotSettingsTestLibrary.GetStatus(), 'Status is not Active');
    end;

    [Test]
    procedure TestUnregisterCapability()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
    begin
        // [SCENARIO] Unregister a copilot capability

        // [GIVEN] Copilot capability is registered
        Initialize();
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);

        // [THEN]
        LibraryAssert.IsFalse(CopilotSettingsTestLibrary.IsEmpty(), 'Copilot capability should be registered');

        // [WHEN] UnregisterCapability is called
        CopilotCapability.UnregisterCapability(Enum::"Copilot Capability"::"Text Capability");

        // [THEN] Copilot capability is unregistered
        LibraryAssert.IsTrue(CopilotSettingsTestLibrary.IsEmpty(), 'Copilot capability should be unregistered');
    end;

    [Test]
    procedure TestUnregisterCapabilityOfAnotherModule()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
    begin
        // [SCENARIO] Try to unregister a copilot capability of another module

        // [GIVEN] Copilot capability is registered from another module
        Initialize();
        CopilotTestLibrary.RegisterCopilotCapability(Enum::"Copilot Capability"::"Text Capability");

        // [WHEN] UnregisterCapability is called
        asserterror CopilotCapability.UnregisterCapability(Enum::"Copilot Capability"::"Text Capability");

        // [THEN] Error is thrown
        LibraryAssert.ExpectedError(NotRegisteredErr);

        // [THEN] Copilot capability is still registered
        LibraryAssert.IsFalse(CopilotSettingsTestLibrary.IsEmpty(), 'Copilot capability should be registered');
    end;

    [Test]
    procedure TestIsCapabilityRegistered()
    begin
        // [SCENARIO] Check if a copilot capability is registered after registering

        // [GIVEN] Copilot capability is registered
        Initialize();
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);

        // [WHEN] IsCapabilityRegistered is called
        // [THEN] True is returned
        LibraryAssert.IsTrue(CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Text Capability"), 'Copilot capability should be registered');
    end;

    [Test]
    procedure TestIsCapabilityRegisteredOfCapabilityFromAnotherModule()
    var
        ModuleGuid: Guid;
    begin
        // [SCENARIO] Check if a copilot capability is registered after registering

        // [GIVEN] Copilot capability from another module is registered
        Initialize();
        CopilotTestLibrary.RegisterCopilotCapability(Enum::"Copilot Capability"::"Text Capability", ModuleGuid);

        // [WHEN] IsCapabilityRegistered is called
        // [THEN] False is returned
        LibraryAssert.IsFalse(CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Text Capability"), 'Copilot capability should not be registered');

        // [WHEN] IsCapabilityRegistered is called with the module id of the system test library
        // [THEN] True is returned
        LibraryAssert.IsTrue(CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Text Capability", ModuleGuid), 'Copilot capability should be registered');
    end;

    [Test]
    procedure TestIsCapabilityRegisteredWithoutRegistering()
    begin
        // [SCENARIO] Check if a copilot capability is registered without registering

        // [GIVEN] Copilot capability is not registered
        Initialize();

        // [WHEN] IsCapabilityRegistered is called
        // [THEN] False is returned
        LibraryAssert.IsFalse(CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Text Capability"), 'Copilot capability should not be registered');
    end;

    [Test]
    procedure TestIsCapabilityActive()
    begin
        // [SCENARIO] Check if a copilot capability is active after registering

        // [GIVEN] Copilot capability is registered
        Initialize();
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);

        // [WHEN] IsCapabilityActive is called
        // [THEN] True is returned
        LibraryAssert.IsTrue(CopilotCapability.IsCapabilityActive(Enum::"Copilot Capability"::"Text Capability"), 'Copilot capability should be enabled');
    end;

    [Test]
    procedure TestIsCapabilityActiveOnInactiveCapability()
    begin
        // [SCENARIO] Check if a copilot capability is active after setting to inactive

        // [GIVEN] Copilot capability is registered and status set to inactive
        Initialize();
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);
        CopilotTestLibrary.SetCopilotStatus(Enum::"Copilot Capability"::"Text Capability", GetModuleAppId(), Enum::"Copilot Status"::Inactive);

        // [WHEN] IsCapabilityActive is called
        // [THEN] False is returned
        LibraryAssert.IsFalse(CopilotCapability.IsCapabilityActive(Enum::"Copilot Capability"::"Text Capability"), 'Copilot capability should not be enabled');
    end;

    [Test]
    procedure TestReportFeatureTrialQuotaWithEmptyConsumptionId()
    var
        CopilotFeatureTrial: Codeunit "Copilot Feature Trial";
        ConsumptionId: Guid;
    begin
        // [SCENARIO] Report feature trial quota with an empty consumption ID
        Initialize();
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);

        // [WHEN] Feature trial quota is reported
        asserterror CopilotFeatureTrial.ReportNonRecurringFeatureTrialQuota(ConsumptionId, 'Trial', Enum::"Copilot Capability"::"Text Capability", 0, 0, 0, 0, '');

        // [THEN] An error is thrown
        LibraryAssert.ExpectedError(ConsumptionIdMustBeSpecifiedErr);
    end;

    [Test]
    procedure TestGetFeatureTrialQuotaWithBlankTrialId()
    var
        CopilotFeatureTrial: Codeunit "Copilot Feature Trial";
    begin
        // [SCENARIO] Get feature trial quota with a blank trial ID
        Initialize();
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);

        // [WHEN] Feature trial quota is retrieved
        asserterror CopilotFeatureTrial.GetQuotaRemaining(' ', Enum::"Copilot Capability"::"Text Capability");

        // [THEN] An error is thrown
        LibraryAssert.ExpectedError(TrialIdMustBeSpecifiedErr);

        // [WHEN] Whether the feature trial has started is retrieved
        asserterror CopilotFeatureTrial.IsTrialStarted(' ', Enum::"Copilot Capability"::"Text Capability");

        // [THEN] An error is thrown
        LibraryAssert.ExpectedError(TrialIdMustBeSpecifiedErr);

        // [WHEN] Whether the feature trial has quota remaining is retrieved
        asserterror CopilotFeatureTrial.HasQuotaRemaining(' ', Enum::"Copilot Capability"::"Text Capability");

        // [THEN] An error is thrown
        LibraryAssert.ExpectedError(TrialIdMustBeSpecifiedErr);
    end;

    [Test]
    procedure TestReportFeatureTrialQuotaWithNegativeQuotaLimits()
    var
        CopilotFeatureTrial: Codeunit "Copilot Feature Trial";
        ConsumptionId: Guid;
    begin
        // [SCENARIO] Report feature trial quota with negative quota limits
        Initialize();
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Capability", LearnMoreUrlLbl);
        ConsumptionId := CreateGuid();

        // [WHEN] Feature trial quota is reported with a negative paid production quota limit
        asserterror CopilotFeatureTrial.ReportMonthlyFeatureTrialQuota(ConsumptionId, 'Trial', Enum::"Copilot Capability"::"Text Capability", -1, 0, 0, 0, '');
        // [THEN] An error is thrown
        LibraryAssert.ExpectedError(QuotaLimitsMustBeNonNegativeErr);

        // [WHEN] Feature trial quota is reported with a negative paid sandbox quota limit
        asserterror CopilotFeatureTrial.ReportMonthlyFeatureTrialQuota(ConsumptionId, 'Trial', Enum::"Copilot Capability"::"Text Capability", 0, -1, 0, 0, '');
        // [THEN] An error is thrown
        LibraryAssert.ExpectedError(QuotaLimitsMustBeNonNegativeErr);

        // [WHEN] Feature trial quota is reported with a negative unpaid production quota limit
        asserterror CopilotFeatureTrial.ReportMonthlyFeatureTrialQuota(ConsumptionId, 'Trial', Enum::"Copilot Capability"::"Text Capability", 0, 0, -1, 0, '');
        // [THEN] An error is thrown
        LibraryAssert.ExpectedError(QuotaLimitsMustBeNonNegativeErr);

        // [WHEN] Feature trial quota is reported with a negative unpaid sandbox quota limit
        asserterror CopilotFeatureTrial.ReportMonthlyFeatureTrialQuota(ConsumptionId, 'Trial', Enum::"Copilot Capability"::"Text Capability", 0, 0, 0, -1, '');
        // [THEN] An error is thrown
        LibraryAssert.ExpectedError(QuotaLimitsMustBeNonNegativeErr);
    end;

    local procedure Initialize()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
    begin
        CopilotSettingsTestLibrary.DeleteAll();
    end;

    local procedure GetModuleAppId(): Guid
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        exit(CurrentModuleInfo.Id());
    end;
}