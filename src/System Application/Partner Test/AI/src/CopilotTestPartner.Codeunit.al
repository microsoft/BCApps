namespace Partner.Test.AI;

using System.AI;
using System.TestLibraries.AI;
using System.TestLibraries.Utilities;

codeunit 139022 "Copilot Test Partner"
{
    Subtype = Test;

    var
        CopilotCapability: Codeunit "Copilot Capability";
        //CopilotTestLibrary: Codeunit "Copilot Test Library";
        LibraryAssert: Codeunit "Library Assert";
        LearnMoreUrlLbl: Label 'http://LearnMore.com', Locked = true;
        LearnMoreUrl2Lbl: Label 'http://LearnMore2.com', Locked = true;
        InvalidBillingTypeErr: Label 'Invalid billing type for Copilot capability ''%1''', Comment = '%1 is the name of the Copilot Capability';

    [Test]
    procedure TestRegisterCapabilityWithBillingType()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
        CurrentModuleInfo: ModuleInfo;
    begin
        // [SCENARIO] Register a copilot capability with billing type set to Microsoft-billed

        // [GIVEN] Copilot capability is not registered
        Initialize();

        // [WHEN] RegisterCapability is called
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Partner Capability", Enum::"Copilot Availability"::"Preview", Enum::"Copilot Billing Type"::"Microsoft Billed", LearnMoreUrlLbl);

        // [THEN] Copilot capability is registered
        LibraryAssert.IsTrue(CopilotSettingsTestLibrary.FindFirst(), 'Copilot capability should be registered');
        LibraryAssert.AreEqual(Enum::"Copilot Capability"::"Text Partner Capability", CopilotSettingsTestLibrary.GetCapability(), 'Copilot capability is not "Text Partner Capability"');
        LibraryAssert.AreEqual(Enum::"Copilot Billing Type"::"Microsoft Billed", CopilotSettingsTestLibrary.GetBillingType(), 'Billing type is not "Microsoft Billed"');

        // [THEN] Registered capability is associated with the current module
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        LibraryAssert.AreEqual(CurrentModuleInfo.Id(), CopilotSettingsTestLibrary.GetAppId(), 'App Id is different from the current module');
        LibraryAssert.AreEqual(CurrentModuleInfo.Publisher(), CopilotSettingsTestLibrary.GetPublisher(), 'Publisher is different from the current module');
        LibraryAssert.AreEqual(CurrentModuleInfo.Publisher(), 'Partner', 'CurrentModule Publisher is Microsoft');

        // [THEN] Registered capability is in preview
        LibraryAssert.AreEqual(Enum::"Copilot Availability"::"Preview", CopilotSettingsTestLibrary.GetAvailability(), 'Availability is not Preview');
    end;

    [Test]
    procedure TestRegisterCapabilityWithInvalidBillingType()
    var
        ErrorMessage: Text;
    begin
        // [SCENARIO] Register a copilot capability with billing type set to Undefined

        // [GIVEN] Copilot capability is not registered
        Initialize();

        // [WHEN] RegisterCapability is called
        asserterror CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Partner Capability", Enum::"Copilot Availability"::"Preview", Enum::"Copilot Billing Type"::Undefined, LearnMoreUrlLbl);

        // [THEN] Register capability should throw an error
        ErrorMessage := StrSubstNo(InvalidBillingTypeErr, Enum::"Copilot Capability"::"Text Partner Capability");
        LibraryAssert.ExpectedError(ErrorMessage);
    end;

    [Test]
    procedure TestModifyCapabilityWithBillingType()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
        CurrentModuleInfo: ModuleInfo;
    begin
        // [SCENARIO] Modify copilot capabilities - Availability, Billing Type, and Learn More Url

        // [GIVEN] Copilot capability is registered
        Initialize();
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Partner Capability", Enum::"Copilot Availability"::"Early Preview", Enum::"Copilot Billing Type"::"Custom Billed", LearnMoreUrlLbl);

        // [THEN] Copilot capability is registered
        LibraryAssert.IsTrue(CopilotSettingsTestLibrary.FindFirst(), 'Copilot capability should be registered');
        LibraryAssert.AreEqual(Enum::"Copilot Capability"::"Text Partner Capability", CopilotSettingsTestLibrary.GetCapability(), 'Copilot capability is not "Text Partner Capability"');
        LibraryAssert.AreEqual(Enum::"Copilot Billing Type"::"Custom Billed", CopilotSettingsTestLibrary.GetBillingType(), 'Billing type is not "Custom Billed"');

        // [THEN] Registered capability is associated with the current module
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        LibraryAssert.AreEqual(CurrentModuleInfo.Id(), CopilotSettingsTestLibrary.GetAppId(), 'App Id is different from the current module');
        LibraryAssert.AreEqual(CurrentModuleInfo.Publisher(), CopilotSettingsTestLibrary.GetPublisher(), 'Publisher is different from the current module');
        LibraryAssert.AreEqual(CurrentModuleInfo.Publisher(), 'Partner', 'CurrentModule Publisher is Microsoft');

        // [WHEN] ModifyCapability is called
        CopilotCapability.ModifyCapability(Enum::"Copilot Capability"::"Text Partner Capability", Enum::"Copilot Availability"::"Preview", Enum::"Copilot Billing Type"::"Microsoft Billed", LearnMoreUrl2Lbl);

        // [THEN] Copilot capability is modified
        CopilotSettingsTestLibrary.FindFirst();
        LibraryAssert.AreEqual(Enum::"Copilot Availability"::"Preview", CopilotSettingsTestLibrary.GetAvailability(), 'Availability is not updated');
        LibraryAssert.AreEqual(LearnMoreUrl2Lbl, CopilotSettingsTestLibrary.GetLearnMoreUrl(), 'Learn More Url is not updated');
        LibraryAssert.AreEqual(Enum::"Copilot Status"::Active, CopilotSettingsTestLibrary.GetStatus(), 'Status is not Active');
        LibraryAssert.AreEqual(Enum::"Copilot Billing Type"::"Microsoft Billed", CopilotSettingsTestLibrary.GetBillingType(), 'Billing type is not updated');
    end;

    [Test]
    procedure TestModifyCapabilityWithInvalidBillingType()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
        CurrentModuleInfo: ModuleInfo;
        ErrorMessage: Text;
    begin
        // [SCENARIO] Modify copilot capabilities - Availability, Billing Type, and Learn More Url

        // [GIVEN] Copilot capability is registered
        Initialize();
        CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Text Partner Capability", Enum::"Copilot Availability"::"Early Preview", Enum::"Copilot Billing Type"::"Custom Billed", LearnMoreUrlLbl);

        // [THEN] Copilot capability is registered
        LibraryAssert.IsTrue(CopilotSettingsTestLibrary.FindFirst(), 'Copilot capability should be registered');
        LibraryAssert.AreEqual(Enum::"Copilot Capability"::"Text Partner Capability", CopilotSettingsTestLibrary.GetCapability(), 'Copilot capability is not "Text Partner Capability"');
        LibraryAssert.AreEqual(Enum::"Copilot Billing Type"::"Custom Billed", CopilotSettingsTestLibrary.GetBillingType(), 'Billing type is not "Custom Billed"');

        // [THEN] Registered capability is associated with the current module
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        LibraryAssert.AreEqual(CurrentModuleInfo.Id(), CopilotSettingsTestLibrary.GetAppId(), 'App Id is different from the current module');
        LibraryAssert.AreEqual(CurrentModuleInfo.Publisher(), CopilotSettingsTestLibrary.GetPublisher(), 'Publisher is different from the current module');
        LibraryAssert.AreEqual(CurrentModuleInfo.Publisher(), 'Partner', 'CurrentModule Publisher is Microsoft');

        // [WHEN] ModifyCapability is called
        asserterror CopilotCapability.ModifyCapability(Enum::"Copilot Capability"::"Text Partner Capability", Enum::"Copilot Availability"::"Preview", Enum::"Copilot Billing Type"::Undefined, LearnMoreUrl2Lbl);
        ErrorMessage := StrSubstNo(InvalidBillingTypeErr, Enum::"Copilot Capability"::"Text Partner Capability");
        LibraryAssert.ExpectedError(ErrorMessage);

        // [THEN] Copilot capability is modified
        CopilotSettingsTestLibrary.FindFirst();
        LibraryAssert.AreEqual(Enum::"Copilot Availability"::"Early Preview", CopilotSettingsTestLibrary.GetAvailability(), 'Availability is not updated');
        LibraryAssert.AreEqual(LearnMoreUrlLbl, CopilotSettingsTestLibrary.GetLearnMoreUrl(), 'Learn More Url is updated');
        LibraryAssert.AreEqual(Enum::"Copilot Status"::Inactive, CopilotSettingsTestLibrary.GetStatus(), 'Status is Active');
        LibraryAssert.AreEqual(Enum::"Copilot Billing Type"::"Custom Billed", CopilotSettingsTestLibrary.GetBillingType(), 'Billing type is not updated');
    end;

    local procedure Initialize()
    var
        CopilotSettingsTestLibrary: Codeunit "Copilot Settings Test Library";
    begin
        CopilotSettingsTestLibrary.DeleteAll();
    end;
}