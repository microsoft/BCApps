// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Environment.Configuration;
using System.TestLibraries.Environment.Configuration;

codeunit 148025 "IRS Forms Assisted Setup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        LibraryIRSReportingPeriod: Codeunit "Library IRS Reporting Period";
        IsInitialized: Boolean;
        AssistedSetupTitleTxt: Label 'Set up IRS 1099 forms';
        AssistedSetupDescriptionTxt: Label 'Set up 1099 forms to transmit the tax data to the IRS in the United States.';

    [Test]
    procedure AssistedSetupRegisteredForIRSFormsGuide()
    var
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        // [SCENARIO 638735] The IRS Forms Guide wizard is registered as an assisted setup so it appears in the Assisted Setup list

        Initialize();

        // [GIVEN] A clean Guided Experience (assisted setup) state
        AssistedSetupTestLibrary.DeleteAll();

        // [WHEN] Subscribers register their assisted setups
        AssistedSetupTestLibrary.CallOnRegister();

        // [THEN] The IRS Forms Guide wizard is registered as an assisted setup
        Assert.IsTrue(
            GuidedExperience.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"IRS Forms Guide"),
            'IRS Forms Guide should be registered in the Assisted Setup list after OnRegisterAssistedSetup.');
    end;

    [Test]
    procedure AssistedSetupNotCompletedWhenNoReportingPeriod()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        // [SCENARIO 638735] The IRS Forms assisted setup is registered but not completed when the company has no reporting period

        Initialize();

        // [GIVEN] No IRS Reporting Period records exist
        IRSReportingPeriod.DeleteAll();
        // [GIVEN] A clean Guided Experience state
        AssistedSetupTestLibrary.DeleteAll();

        // [WHEN] Subscribers register their assisted setups
        AssistedSetupTestLibrary.CallOnRegister();

        // [THEN] The IRS Forms Guide assisted setup is registered
        Assert.IsTrue(
            GuidedExperience.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"IRS Forms Guide"),
            'IRS Forms Guide should be registered in the Assisted Setup list.');
        // [THEN] It is not marked as completed
        Assert.IsFalse(
            GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"IRS Forms Guide"),
            'IRS Forms Guide assisted setup should not be completed when no reporting period exists.');
    end;

    [Test]
    procedure AssistedSetupCompletedWhenReportingPeriodExists()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        // [SCENARIO 638735] The IRS Forms assisted setup is marked completed for companies that already configured 1099

        Initialize();

        // [GIVEN] An IRS Reporting Period already exists (the company already configured 1099)
        IRSReportingPeriod.DeleteAll();
        LibraryIRSReportingPeriod.CreateReportingPeriod(DMY2Date(1, 1, 2024), DMY2Date(31, 12, 2024));
        // [GIVEN] A clean Guided Experience state
        AssistedSetupTestLibrary.DeleteAll();

        // [WHEN] Subscribers register their assisted setups
        AssistedSetupTestLibrary.CallOnRegister();

        // [THEN] The IRS Forms Guide assisted setup is registered
        Assert.IsTrue(
            GuidedExperience.Exists(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"IRS Forms Guide"),
            'IRS Forms Guide should be registered in the Assisted Setup list.');
        // [THEN] It is marked as completed
        Assert.IsTrue(
            GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"IRS Forms Guide"),
            'IRS Forms Guide assisted setup should be completed when a reporting period already exists.');
    end;

    [Test]
    procedure AssistedSetupTitleDescriptionAndHelpUrl()
    var
        AssistedSetupGroup: Enum "Assisted Setup Group";
        AssistedSetupPage: TestPage "Assisted Setup";
        FinancialReportingGroupCaption: Text;
        Found: Boolean;
    begin
        // [SCENARIO 638735] Opening the Assisted Setup page runs the IRS Forms OnRegisterAssistedSetup subscriber and
        // registers the IRS Forms Guide wizard under the Financial Reporting group with the modernised title,
        // description and a help URL (option 3a). Opening the page is the real production path and also exercises the
        // ReadPermission guard in the subscriber.

        Initialize();

        // [GIVEN] A clean Guided Experience (assisted setup) state
        AssistedSetupTestLibrary.DeleteAll();
        // [GIVEN] The Financial Reporting group caption as rendered on the page
        FinancialReportingGroupCaption := Format(AssistedSetupGroup::FinancialReporting);

        // [WHEN] The Assisted Setup list is opened (OnOpenPage raises OnRegisterAssistedSetup for all subscribers)
        AssistedSetupPage.OpenView();

        // [WHEN] The Financial Reporting group node is expanded so its child setup rows become navigable
        // (the page is a tree over a temporary table; child rows stay hidden while the parent group is collapsed)
        if AssistedSetupPage.First() then
            repeat
                if AssistedSetupPage.Name.Value = FinancialReportingGroupCaption then
                    AssistedSetupPage.Expand(true);
            until not AssistedSetupPage.Next();

        // [THEN] The IRS Forms Guide setup row is listed with the expected title, description and help link
        Found := false;
        if AssistedSetupPage.First() then
            repeat
                if AssistedSetupPage.Name.Value = AssistedSetupTitleTxt then begin
                    Found := true;
                    // [THEN] Its description matches the registered value
                    Assert.AreEqual(
                        AssistedSetupDescriptionTxt, AssistedSetupPage.Description.Value,
                        'The IRS Forms Guide assisted setup should show the expected description.');
                    // [THEN] It exposes a help link (the page renders 'Read' when a Help Url is registered)
                    Assert.AreNotEqual(
                        '', AssistedSetupPage.Help.Value,
                        'The IRS Forms Guide assisted setup should expose a help link.');
                end;
            until (not AssistedSetupPage.Next()) or Found;
        AssistedSetupPage.Close();

        // [THEN] The IRS 1099 forms assisted setup was found (specific to our registration - not satisfied by any
        // other subscriber's Financial Reporting group entry)
        Assert.IsTrue(Found, 'The IRS 1099 forms assisted setup should be listed under the Financial Reporting group.');
    end;

    trigger OnRun()
    begin
        // [FEATURE] [1099] [Assisted Setup]
    end;

    local procedure Initialize()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        IRSReportingPeriod.DeleteAll();
        if IsInitialized then
            exit;
        IsInitialized := true;
    end;
}
