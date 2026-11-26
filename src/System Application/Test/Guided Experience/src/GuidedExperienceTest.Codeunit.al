// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Environment.Configuration;

using System.Environment.Configuration;
using System.Media;
using System.TestLibraries.Environment.Configuration;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 132594 "Guided Experience Test"
{
    Subtype = Test;

    Permissions = tabledata "Guided Experience Item" = rimd,
                    tabledata "Spotlight Tour Text" = rimd;

    var
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        Any: Codeunit Any;
        GuidedExperienceTestLibrary: Codeunit "Guided Experience Test Library";
        GuidedExperienceRecordCountErr: Label 'Guided Experience record count error.';

    [Test]
    [HandlerFunctions('EarlyAccessFeatureDetailsHandler')]
    procedure EarlyAccessMetadataKeepsFullTextAndStepOrder()
    var
        TempGuidedExperienceItem: Record "Guided Experience Item" temporary;
        EarlyAccessPreviewMgt: Codeunit "Early Access Preview Mgt.";
        FeatureDetails: Page "Early Access Feature Details";
        Features: JsonArray;
        Feature: JsonObject;
        Steps: JsonArray;
        Overview: Text;
        GettingStarted: Text;
        LongStep: Text;
        FullOverview: Text;
        ExpectedGuide: TextBuilder;
    begin
        FullOverview := PadStr('Feature benefit. ', 1500, 'x');
        LongStep := PadStr('Read the full guidance, including <plain text>. ', 6000, 'y');
        Feature.Add('FeatureName', 'Feature with guidance');
        Feature.Add('Category', 'General');
        Feature.Add('Description', FullOverview);
        Feature.Add('ReleaseVersion', '30.0');
        Feature.Add('HelpURL', 'https://example.com/help');
        Feature.Add('VideoURL', 'https://example.com/video');
        Steps.Add('Open the feature.');
        Steps.Add(LongStep);
        Steps.Add('Complete setup.');
        Feature.Add('GettingStartedSteps', Steps);
        Features.Add(Feature);

        EarlyAccessPreviewMgt.LoadNewFeatures(TempGuidedExperienceItem, Features);
        EarlyAccessPreviewMgt.GetFeatureDetails(TempGuidedExperienceItem.Code, Overview, GettingStarted);

        ExpectedGuide.AppendLine('1. Open the feature.');
        ExpectedGuide.AppendLine();
        ExpectedGuide.AppendLine('2. ' + LongStep);
        ExpectedGuide.AppendLine();
        ExpectedGuide.Append('3. Complete setup.');
        Assert.AreEqual('30.0', EarlyAccessPreviewMgt.GetReleaseVersion(TempGuidedExperienceItem.Code), 'Release must come from the selected feature.');
        Assert.AreEqual(FullOverview, Overview, 'The overview must not be truncated or contain release information.');
        Assert.AreEqual(ExpectedGuide.ToText(), GettingStarted, 'Numbered steps must preserve their order and full plain text.');
        Assert.AreEqual('https://example.com/help', TempGuidedExperienceItem."Help URL", 'Help must be preserved.');
        Assert.AreEqual('https://example.com/video', TempGuidedExperienceItem."Video URL", 'Video must be preserved.');
        FeatureDetails.SetFeature(TempGuidedExperienceItem, EarlyAccessPreviewMgt.GetReleaseVersion(TempGuidedExperienceItem.Code), Overview, GettingStarted);
        FeatureDetails.Run();
    end;

    [Test]
    [HandlerFunctions('EarlyAccessLegacyFeatureDetailsHandler')]
    procedure EarlyAccessMetadataDoesNotLeakBetweenFeaturesOrReloads()
    var
        TempGuidedExperienceItem: Record "Guided Experience Item" temporary;
        EarlyAccessPreviewMgt: Codeunit "Early Access Preview Mgt.";
        FeatureDetails: Page "Early Access Feature Details";
        Features: JsonArray;
        EmptyFeatures: JsonArray;
        Overview: Text;
        GettingStarted: Text;
    begin
        Features.ReadFrom(
            '[{"FeatureName":"Guided","Description":"Overview","ReleaseVersion":"30.0","GettingStartedSteps":["Start here."]},' +
            '{"FeatureName":"Legacy"},{"FeatureName":"Empty","ReleaseVersion":"","GettingStartedSteps":[]},' +
            '{"FeatureName":"Release only","ReleaseVersion":"29.1"},{"FeatureName":"Steps only","GettingStartedSteps":["Try this."]}]');
        EarlyAccessPreviewMgt.LoadNewFeatures(TempGuidedExperienceItem, Features);
        EarlyAccessPreviewMgt.GetFeatureDetails('1', Overview, GettingStarted);
        Assert.AreEqual('1. Start here.', GettingStarted, 'The first feature must have guidance.');

        EarlyAccessPreviewMgt.GetFeatureDetails('2', Overview, GettingStarted);
        Assert.AreEqual('', Overview, 'A missing overview must clear the previous feature.');
        Assert.AreEqual('', GettingStarted, 'A legacy feature must not reuse the previous guidance.');
        Assert.AreEqual('', EarlyAccessPreviewMgt.GetReleaseVersion('2'), 'A missing release must stay blank.');
        EarlyAccessPreviewMgt.GetFeatureDetails('3', Overview, GettingStarted);
        Assert.AreEqual('', GettingStarted, 'An empty steps array must stay blank.');
        Assert.AreEqual('', EarlyAccessPreviewMgt.GetReleaseVersion('3'), 'An empty release must stay blank.');
        EarlyAccessPreviewMgt.GetFeatureDetails('4', Overview, GettingStarted);
        Assert.AreEqual('', GettingStarted, 'Release information must not require guidance.');
        Assert.AreEqual('29.1', EarlyAccessPreviewMgt.GetReleaseVersion('4'), 'Each feature must retain its own introducing release.');
        EarlyAccessPreviewMgt.GetFeatureDetails('5', Overview, GettingStarted);
        Assert.AreEqual('1. Try this.', GettingStarted, 'Guidance must not require release information.');
        Assert.AreEqual('', EarlyAccessPreviewMgt.GetReleaseVersion('5'), 'Guidance must not invent a release.');

        EarlyAccessPreviewMgt.GetFeatureDetails('1', Overview, GettingStarted);
        Assert.AreEqual('1. Start here.', GettingStarted, 'Returning to a feature must restore its own guidance.');
        EarlyAccessPreviewMgt.GetFeatureDetails('', Overview, GettingStarted);
        Assert.AreEqual('', Overview, 'No selection must clear the overview.');
        Assert.AreEqual('', GettingStarted, 'No selection must clear the guidance.');

        TempGuidedExperienceItem.Get('1', 0);
        TempGuidedExperienceItem."Help URL" := 'https://example.com/help';
        TempGuidedExperienceItem."Video URL" := 'https://example.com/video';
        EarlyAccessPreviewMgt.GetFeatureDetails('1', Overview, GettingStarted);
        FeatureDetails.SetFeature(TempGuidedExperienceItem, EarlyAccessPreviewMgt.GetReleaseVersion('1'), Overview, GettingStarted);
        TempGuidedExperienceItem.Get('2', 0);
        EarlyAccessPreviewMgt.GetFeatureDetails('2', Overview, GettingStarted);
        FeatureDetails.SetFeature(TempGuidedExperienceItem, EarlyAccessPreviewMgt.GetReleaseVersion('2'), Overview, GettingStarted);
        FeatureDetails.Run();

        TempGuidedExperienceItem.SetRange(Code, '2');
        EarlyAccessPreviewMgt.LoadNewFeatures(TempGuidedExperienceItem, EmptyFeatures);
        Assert.IsTrue(TempGuidedExperienceItem.IsEmpty(), 'An empty catalog must clear all rows, including filtered rows.');
        Assert.AreEqual('', TempGuidedExperienceItem.Code, 'An empty catalog must not retain a selected feature.');
        EarlyAccessPreviewMgt.GetFeatureDetails('1', Overview, GettingStarted);
        Assert.AreEqual('', Overview, 'Reloading must clear cached overviews.');
        Assert.AreEqual('', GettingStarted, 'Reloading must clear cached guidance.');
        Assert.AreEqual('', EarlyAccessPreviewMgt.GetReleaseVersion('1'), 'Reloading must clear cached releases.');
    end;

    [Test]
    procedure EarlyAccessMetadataRejectsInvalidReleaseVersions()
    var
        TempGuidedExperienceItem: Record "Guided Experience Item" temporary;
        EarlyAccessPreviewMgt: Codeunit "Early Access Preview Mgt.";
        Features: JsonArray;
    begin
        Features.ReadFrom('[{"ReleaseVersion":30.0}]');
        asserterror EarlyAccessPreviewMgt.LoadNewFeatures(TempGuidedExperienceItem, Features);
        Assert.ExpectedError('ReleaseVersion value for early access preview feature 1 must be a JSON string.');

        Features.ReadFrom('[{"ReleaseVersion":null}]');
        asserterror EarlyAccessPreviewMgt.LoadNewFeatures(TempGuidedExperienceItem, Features);
        Assert.ExpectedError('ReleaseVersion value for early access preview feature 1 must be a JSON string.');

        Features.ReadFrom('[{"ReleaseVersion":"30.0.1"}]');
        asserterror EarlyAccessPreviewMgt.LoadNewFeatures(TempGuidedExperienceItem, Features);
        Assert.ExpectedError('must use the major.minor format');

        Features.ReadFrom('[{"ReleaseVersion":"30.x"}]');
        asserterror EarlyAccessPreviewMgt.LoadNewFeatures(TempGuidedExperienceItem, Features);
        Assert.ExpectedError('must use the major.minor format');
    end;

    [Test]
    procedure EarlyAccessMetadataRejectsInvalidSteps()
    var
        TempGuidedExperienceItem: Record "Guided Experience Item" temporary;
        EarlyAccessPreviewMgt: Codeunit "Early Access Preview Mgt.";
        Features: JsonArray;
    begin
        Features.ReadFrom('[{"GettingStartedSteps":"Not an array"}]');
        asserterror EarlyAccessPreviewMgt.LoadNewFeatures(TempGuidedExperienceItem, Features);
        Assert.ExpectedError('must be a JSON array of strings');

        Features.ReadFrom('[{"GettingStartedSteps":["Valid",false]}]');
        asserterror EarlyAccessPreviewMgt.LoadNewFeatures(TempGuidedExperienceItem, Features);
        Assert.ExpectedError('GettingStartedSteps value for early access preview feature 1 must be a JSON string.');

        Features.ReadFrom('[{"GettingStartedSteps":[null]}]');
        asserterror EarlyAccessPreviewMgt.LoadNewFeatures(TempGuidedExperienceItem, Features);
        Assert.ExpectedError('GettingStartedSteps value for early access preview feature 1 must be a JSON string.');

        Features.ReadFrom('[{"GettingStartedSteps":[{}]}]');
        asserterror EarlyAccessPreviewMgt.LoadNewFeatures(TempGuidedExperienceItem, Features);
        Assert.ExpectedError('GettingStartedSteps value for early access preview feature 1 must be a JSON string.');
    end;

    [PageHandler]
    procedure EarlyAccessFeatureDetailsHandler(var FeatureDetails: TestPage "Early Access Feature Details")
    begin
        FeatureDetails.FeatureName.AssertEquals('Feature with guidance');
        FeatureDetails.Category.AssertEquals('General');
        FeatureDetails.ReleaseVersion.AssertEquals('30.0');
        Assert.AreEqual(1500, StrLen(FeatureDetails.Overview.Value()), 'The reading page must retain the full overview.');
        Assert.IsTrue(StrLen(FeatureDetails.GettingStarted.Value()) > 6000, 'The reading page must retain the full numbered guidance.');
        Assert.IsTrue(FeatureDetails.ViewHelp.Enabled(), 'The selected feature has a help link.');
        Assert.IsTrue(FeatureDetails.WatchVideo.Enabled(), 'The selected feature has a video link.');
        Assert.IsTrue(FeatureDetails.ProvideFeatureFeedback.Enabled(), 'Feature feedback must be available in the reading context.');
        FeatureDetails.Close();
    end;

    [PageHandler]
    procedure EarlyAccessLegacyFeatureDetailsHandler(var FeatureDetails: TestPage "Early Access Feature Details")
    begin
        FeatureDetails.FeatureName.AssertEquals('Legacy');
        FeatureDetails.ReleaseVersion.AssertEquals('');
        FeatureDetails.Overview.AssertEquals('');
        Assert.IsFalse(FeatureDetails.GettingStarted.Visible(), 'Legacy features must not show guidance from another feature.');
        Assert.IsFalse(FeatureDetails.ViewHelp.Enabled(), 'A missing help link must clear the previous enabled state.');
        Assert.IsFalse(FeatureDetails.WatchVideo.Enabled(), 'A missing video link must clear the previous enabled state.');
        Assert.IsTrue(FeatureDetails.ProvideFeatureFeedback.Enabled(), 'Legacy features can still receive feature feedback.');
        FeatureDetails.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertAssistedSetup()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        ObjectTypeToRun: Enum "Guided Experience Object Type";
        GuidedExperienceType: Enum "Guided Experience Type";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        ManualSetupCategory: Enum "Manual Setup Category";
        SpotlightTourType: Enum "Spotlight Tour Type";
        SpotlightTourTexts: Dictionary of [Enum "Spotlight Tour Text", Text];
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
        ExpectedDuration: Integer;
        ObjectIDToRun: Integer;
        Code: Code[300];
        VideoUrl: Text[250];
        HelpUrl: Text[250];
    begin
        // [GIVEN] The Guided Experience Item table is empty
        GuidedExperienceItem.DeleteAll();

        PermissionsMock.Set('Guided Exp Edit');

        // [WHEN] Inserting a new assisted setup
        ObjectIDToRun := Page::"Assisted Setup Wizard";
        AssistedSetupGroup := AssistedSetupGroup::Uncategorized;
        VideoCategory := VideoCategory::Uncategorized;
        GuidedExperienceTestLibrary.InsertAssistedSetup(true, Title, ShortTitle, Description, ExpectedDuration,
            ObjectType::Page, ObjectIDToRun, AssistedSetupGroup, VideoUrl, VideoCategory, HelpUrl);

        // [THEN] There is exactly one record in the Guided Experience Item table
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item should contain exactly one record');

        // [THEN] The fields of the Guided Experience Item are set correctly
        GuidedExperienceItem.FindFirst();
        Code := 'ASSISTED SETUP_PAGE_132610__0';
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 0, ObjectTypeToRun::Page, ObjectIDToRun, '', Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::"Assisted Setup", AssistedSetupGroup,
            HelpUrl, VideoUrl, VideoCategory, ManualSetupCategory::Uncategorized, '', SpotlightTourType::None, SpotlightTourTexts);

        // [WHEN] Inserting a new version of the assisted setup page
        GuidedExperienceTestLibrary.InsertAssistedSetup(true, Title, ShortTitle, Description, ExpectedDuration,
            ObjectType::Page, ObjectIDToRun, AssistedSetupGroup, VideoUrl, VideoCategory, HelpUrl);

        VerifyAfterNonIdenticalInsertion(Code);

        // [THEN] The fields of the second version of the Guided Experience Item are set correctly
        if GuidedExperienceItem.Get(Code, 1) then;
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 1, ObjectTypeToRun::Page, ObjectIDToRun, '', Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::"Assisted Setup", AssistedSetupGroup,
            HelpUrl, VideoUrl, VideoCategory, ManualSetupCategory::Uncategorized, '', SpotlightTourType::None, SpotlightTourTexts);

        // [WHEN] Trying to insert an assisted setup page with the same fields as the last version that was inserted
        GuidedExperienceTestLibrary.InsertAssistedSetup(false, Title, ShortTitle, Description, ExpectedDuration,
            ObjectType::Page, ObjectIDToRun, AssistedSetupGroup, VideoUrl, VideoCategory, HelpUrl);

        VerifyAfterIdenticalInsertion(Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertManualSetup()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        ObjectTypeToRun: Enum "Guided Experience Object Type";
        GuidedExperienceType: Enum "Guided Experience Type";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        ManualSetupCategory: Enum "Manual Setup Category";
        SpotlightTourType: Enum "Spotlight Tour Type";
        SpotlightTourTexts: Dictionary of [Enum "Spotlight Tour Text", Text];
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
        ExpectedDuration: Integer;
        ObjectIDToRun: Integer;
        Code: Code[300];
        Keywords: Text[250];
    begin
        // [GIVEN] The Guided Experience Item table is empty
        GuidedExperienceItem.DeleteAll();

        PermissionsMock.Set('Guided Exp Edit');

        // [WHEN] Inserting a new manual setup
        ObjectIDToRun := Codeunit::"Checklist Test Codeunit";
        ManualSetupCategory := ManualSetupCategory::Uncategorized;
        GuidedExperienceTestLibrary.InsertManualSetup(true, Title, ShortTitle, Description, ExpectedDuration,
            ObjectType::Codeunit, ObjectIDToRun, ManualSetupCategory, Keywords);

        // [THEN] There is exactly one record in the Guided Experience Item table
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item should contain exactly one record');

        // [THEN] The fields of the Guided Experience Item are set correctly
        GuidedExperienceItem.FindFirst();
        Code := 'MANUAL SETUP_CODEUNIT_132610__0';
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 0, ObjectTypeToRun::Codeunit, ObjectIDToRun, '', Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::"Manual Setup", AssistedSetupGroup::Uncategorized,
            '', '', VideoCategory::Uncategorized, ManualSetupCategory, Keywords, SpotlightTourType::None, SpotlightTourTexts);

        // [WHEN] Inserting a new version of the manual setup
        GuidedExperienceTestLibrary.InsertManualSetup(true, Title, ShortTitle, Description, ExpectedDuration,
            ObjectType::Codeunit, ObjectIDToRun, ManualSetupCategory, Keywords);

        VerifyAfterNonIdenticalInsertion(Code);

        // [THEN] The fields of the second version of the Guided Experience Item are set correctly
        if GuidedExperienceItem.Get(Code, 1) then;
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 1, ObjectTypeToRun::Codeunit, ObjectIDToRun, '', Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::"Manual Setup", AssistedSetupGroup::Uncategorized,
            '', '', VideoCategory::Uncategorized, ManualSetupCategory, Keywords, SpotlightTourType::None, SpotlightTourTexts);

        // [WHEN] Trying to insert a manual setup with the same fields as the last version that was inserted
        GuidedExperienceTestLibrary.InsertManualSetup(false, Title, ShortTitle, Description, ExpectedDuration,
            ObjectType::Codeunit, ObjectIDToRun, ManualSetupCategory, Keywords);

        VerifyAfterIdenticalInsertion(Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertLearnLink()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        ObjectTypeToRun: Enum "Guided Experience Object Type";
        GuidedExperienceType: Enum "Guided Experience Type";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        ManualSetupCategory: Enum "Manual Setup Category";
        SpotlightTourType: Enum "Spotlight Tour Type";
        SpotlightTourTexts: Dictionary of [Enum "Spotlight Tour Text", Text];
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
        ExpectedDuration: Integer;
        Link: Text[250];
        Code: Code[300];
    begin
        // [GIVEN] The Guided Experience Item table is empty
        GuidedExperienceItem.DeleteAll();

        PermissionsMock.Set('Guided Exp Edit');

        // [WHEN] Inserting a new learn link
        Link := CopyStr(Any.AlphanumericText(MaxStrLen(Link)), 1, MaxStrLen(Link));
        GuidedExperienceTestLibrary.InsertLearnLink(true, Title, ShortTitle, Description, ExpectedDuration, Link);

        // [THEN] There is exactly one record in the Guided Experience Item table
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item should contain exactly one record');

        // [THEN] The fields of the Guided Experience Item are set correctly
        GuidedExperienceItem.FindFirst();
        Code := 'LEARN_UNINITIALIZED_0_' + Link + '_0';
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 0, ObjectTypeToRun::Uninitialized, 0, Link, Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::Learn, AssistedSetupGroup::Uncategorized,
            '', '', VideoCategory::Uncategorized, ManualSetupCategory::Uncategorized, '', SpotlightTourType::None, SpotlightTourTexts);

        // [WHEN] Inserting a new version of the learn link
        GuidedExperienceTestLibrary.InsertLearnLink(true, Title, ShortTitle, Description, ExpectedDuration, Link);

        VerifyAfterNonIdenticalInsertion(Code);

        // [THEN] The fields of the second version of the Guided Experience Item are set correctly
        if GuidedExperienceItem.Get(Code, 1) then;
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 1, ObjectTypeToRun::Uninitialized, 0, Link, Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::Learn, AssistedSetupGroup::Uncategorized,
            '', '', VideoCategory::Uncategorized, ManualSetupCategory::Uncategorized, '', SpotlightTourType::None, SpotlightTourTexts);

        // [WHEN] Trying to insert a learn link with the same fields as the last version that was inserted
        GuidedExperienceTestLibrary.InsertLearnLink(false, Title, ShortTitle, Description, ExpectedDuration, Link);

        VerifyAfterIdenticalInsertion(Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertApplicationFeature()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        ObjectTypeToRun: Enum "Guided Experience Object Type";
        GuidedExperienceType: Enum "Guided Experience Type";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        ManualSetupCategory: Enum "Manual Setup Category";
        SpotlightTourType: Enum "Spotlight Tour Type";
        SpotlightTourTexts: Dictionary of [Enum "Spotlight Tour Text", Text];
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
        ExpectedDuration: Integer;
        ObjectIDToRun: Integer;
        Code: Code[300];
        Keywords: Text[250];
    begin
        // [GIVEN] The Guided Experience Item table is empty
        GuidedExperienceItem.DeleteAll();

        PermissionsMock.Set('Guided Exp Edit');

        // [WHEN] Inserting a new application feature
        ObjectIDToRun := Codeunit::"Checklist Test Codeunit";
        GuidedExperienceTestLibrary.InsertApplicationFeature(true, Title, ShortTitle,
            Description, ExpectedDuration, ObjectType::Codeunit, ObjectIDToRun);

        // [THEN] There is exactly one record in the Guided Experience Item table
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item should contain exactly one record');

        // [THEN] The fields of the Guided Experience Item are set correctly
        GuidedExperienceItem.FindFirst();
        Code := 'APPLICATION FEATURE_CODEUNIT_132610__0';
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 0, ObjectTypeToRun::Codeunit, ObjectIDToRun, '', Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::"Application Feature", AssistedSetupGroup::Uncategorized,
            '', '', VideoCategory::Uncategorized, ManualSetupCategory::Uncategorized, Keywords, SpotlightTourType::None, SpotlightTourTexts);

        // [WHEN] Inserting a new version of the application feature
        GuidedExperienceTestLibrary.InsertApplicationFeature(true, Title, ShortTitle,
             Description, ExpectedDuration, ObjectType::Codeunit, ObjectIDToRun);

        VerifyAfterNonIdenticalInsertion(Code);

        // [THEN] The fields of the second version of the Guided Experience Item are set correctly
        if GuidedExperienceItem.Get(Code, 1) then;
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 1, ObjectTypeToRun::Codeunit, ObjectIDToRun, '', Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::"Application Feature", AssistedSetupGroup::Uncategorized,
            '', '', VideoCategory::Uncategorized, ManualSetupCategory::Uncategorized, Keywords, SpotlightTourType::None, SpotlightTourTexts);

        // [WHEN] Trying to insert an application feature with the same fields as the last version that was inserted
        GuidedExperienceTestLibrary.InsertApplicationFeature(false, Title, ShortTitle,
            Description, ExpectedDuration, ObjectType::Codeunit, ObjectIDToRun);

        VerifyAfterIdenticalInsertion(Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertVideo()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        ObjectTypeToRun: Enum "Guided Experience Object Type";
        GuidedExperienceType: Enum "Guided Experience Type";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        ManualSetupCategory: Enum "Manual Setup Category";
        SpotlightTourType: Enum "Spotlight Tour Type";
        SpotlightTourTexts: Dictionary of [Enum "Spotlight Tour Text", Text];
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
        ExpectedDuration: Integer;
        VideoUrl: Text[250];
        Code: Code[300];
    begin
        // [GIVEN] The Guided Experience Item table is empty
        GuidedExperienceItem.DeleteAll();

        PermissionsMock.Set('Guided Exp Edit');

        // [WHEN] Inserting a new video 
        VideoUrl := CopyStr(Any.AlphanumericText(MaxStrLen(VideoUrl)), 1, MaxStrLen(VideoUrl));
        VideoCategory := VideoCategory::Uncategorized;
        GuidedExperienceTestLibrary.InsertVideo(true, Title, ShortTitle, Description,
            ExpectedDuration, VideoUrl, VideoCategory);

        // [THEN] There is exactly one record in the Guided Experience Item table
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item should contain exactly one record');

        // [THEN] The fields of the Guided Experience Item are set correctly
        GuidedExperienceItem.FindFirst();
        Code := 'VIDEO_UNINITIALIZED_0_' + VideoUrl + '_0';
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 0, ObjectTypeToRun::Uninitialized, 0, '', Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::Video, AssistedSetupGroup::Uncategorized,
            '', VideoUrl, VideoCategory, ManualSetupCategory::Uncategorized, '', SpotlightTourType::None, SpotlightTourTexts);

        // [WHEN] Inserting a new version of the video
        GuidedExperienceTestLibrary.InsertVideo(true, Title, ShortTitle, Description,
            ExpectedDuration, VideoUrl, VideoCategory);

        VerifyAfterNonIdenticalInsertion(Code);

        // [THEN] The fields of the second version of the Guided Experience Item are set correctly
        if GuidedExperienceItem.Get(Code, 1) then;
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 1, ObjectTypeToRun::Uninitialized, 0, '', Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::Video, AssistedSetupGroup::Uncategorized,
            '', VideoUrl, VideoCategory, ManualSetupCategory::Uncategorized, '', SpotlightTourType::None, SpotlightTourTexts);

        // [WHEN] Trying to insert a video with the same fields as the last version that was inserted
        GuidedExperienceTestLibrary.InsertVideo(false, Title, ShortTitle, Description,
            ExpectedDuration, VideoUrl, VideoCategory);

        VerifyAfterIdenticalInsertion(Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertTour()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        ObjectTypeToRun: Enum "Guided Experience Object Type";
        GuidedExperienceType: Enum "Guided Experience Type";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        ManualSetupCategory: Enum "Manual Setup Category";
        SpotlightTourType: Enum "Spotlight Tour Type";
        SpotlightTourTexts: Dictionary of [Enum "Spotlight Tour Text", Text];
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
        ExpectedDuration: Integer;
        ObjectIDToRun: Integer;
        Code: Code[300];
        Keywords: Text[250];
    begin
        // [GIVEN] The Guided Experience Item table is empty
        GuidedExperienceItem.DeleteAll();

        PermissionsMock.Set('Guided Exp Edit');

        // [WHEN] Inserting a new tour
        ObjectIDToRun := Page::"Assisted Setup Wizard";
        GuidedExperienceTestLibrary.InsertTour(true, Title, ShortTitle, Description, ExpectedDuration, ObjectIDToRun);

        // [THEN] There is exactly one record in the Guided Experience Item table
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item should contain exactly one record');

        // [THEN] The fields of the Guided Experience Item are set correctly
        GuidedExperienceItem.FindFirst();
        Code := 'TOUR_PAGE_132610__0';
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 0, ObjectTypeToRun::Page, ObjectIDToRun, '', Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::Tour, AssistedSetupGroup::Uncategorized,
            '', '', VideoCategory::Uncategorized, ManualSetupCategory::Uncategorized, Keywords, SpotlightTourType::None, SpotlightTourTexts);

        // [WHEN] Inserting a new version of the tour
        GuidedExperienceTestLibrary.InsertTour(true, Title, ShortTitle, Description, ExpectedDuration, ObjectIDToRun);

        VerifyAfterNonIdenticalInsertion(Code);

        // [THEN] The fields of the second version of the Guided Experience Item are set correctly
        if GuidedExperienceItem.Get(Code, 1) then;
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 1, ObjectTypeToRun::Page, ObjectIDToRun, '', Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::Tour, AssistedSetupGroup::Uncategorized,
            '', '', VideoCategory::Uncategorized, ManualSetupCategory::Uncategorized, Keywords, SpotlightTourType::None, SpotlightTourTexts);

        // [WHEN] Trying to insert a tour with the same fields as the last version that was inserted        
        GuidedExperienceTestLibrary.InsertTour(false, Title, ShortTitle, Description, ExpectedDuration, ObjectIDToRun);

        VerifyAfterIdenticalInsertion(Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertSpotlightTour()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        ObjectTypeToRun: Enum "Guided Experience Object Type";
        GuidedExperienceType: Enum "Guided Experience Type";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        ManualSetupCategory: Enum "Manual Setup Category";
        SpotlightTourType: Enum "Spotlight Tour Type";
        SpotlightTourTexts: Dictionary of [Enum "Spotlight Tour Text", Text];
        Title: Text[2048];
        ShortTitle: Text[50];
        Description: Text[1024];
        ExpectedDuration: Integer;
        ObjectIDToRun: Integer;
        Code: Code[300];
        Keywords: Text[250];
    begin
        // [GIVEN] The Guided Experience Item table is empty
        GuidedExperienceItem.DeleteAll();

        PermissionsMock.Set('Guided Exp Edit');

        // [WHEN] Inserting a new spotlight tour
        ObjectIDToRun := Page::"Assisted Setup Wizard";
        SpotlightTourType := SpotlightTourType::"Open in Excel";
        GuidedExperienceTestLibrary.InsertSpotlightTour(true, Title, ShortTitle, Description,
            ExpectedDuration, ObjectIDToRun, SpotlightTourType, SpotlightTourTexts);

        // [THEN] There is exactly one record in the Guided Experience Item table
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item should contain exactly one record');

        // [THEN] The fields of the Guided Experience Item are set correctly
        GuidedExperienceItem.FindFirst();
        Code := 'SPOTLIGHT TOUR_PAGE_132610__' + Format(SpotlightTourType.AsInteger());
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 0, ObjectTypeToRun::Page, ObjectIDToRun, '', Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::"Spotlight Tour", AssistedSetupGroup::Uncategorized,
            '', '', VideoCategory::Uncategorized, ManualSetupCategory::Uncategorized, Keywords, SpotlightTourType, SpotlightTourTexts);

        // [WHEN] Inserting a new version of the spotlight tour
        GuidedExperienceTestLibrary.InsertSpotlightTour(true, Title, ShortTitle, Description,
            ExpectedDuration, ObjectIDToRun, SpotlightTourType, SpotlightTourTexts);

        VerifyAfterNonIdenticalInsertion(Code);

        // [THEN] The fields of the second version of the Guided Experience Item are set correctly
        if GuidedExperienceItem.Get(Code, 1) then;
        VerifyGuidedExperienceItemFields(GuidedExperienceItem, Code, 1, ObjectTypeToRun::Page, ObjectIDToRun, '', Title, ShortTitle, Description,
            ExpectedDuration, false, GuidedExperienceType::"Spotlight Tour", AssistedSetupGroup::Uncategorized,
            '', '', VideoCategory::Uncategorized, ManualSetupCategory::Uncategorized, Keywords, SpotlightTourType, SpotlightTourTexts);

        // [WHEN] Trying to insert a spotlight tour with the same fields as the last version that was inserted       
        GuidedExperienceTestLibrary.InsertSpotlightTour(false, Title, ShortTitle, Description,
            ExpectedDuration, ObjectIDToRun, SpotlightTourType, SpotlightTourTexts);

        VerifyAfterIdenticalInsertion(Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveAssistedSetup()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        ObjectTypeToRun1: ObjectType;
        ObjectTypeToRun2: ObjectType;
        ObjectIDToRun1: Integer;
        ObjectIDToRun2: Integer;
        Title1: Text[2048];
        Title2: Text[2048];
        ShortTitle1: Text[50];
        ShortTitle2: Text[50];
        Description1: Text[1024];
        Description2: Text[1024];
        ExpectedDuration: Integer;
        VideoUrl: Text[250];
        HelpUrl: Text[250];
    begin
        PermissionsMock.Set('Guided Exp Edit');

        // [GIVEN] The Guided Experience Item table contains 2 assisted setups
        GuidedExperienceItem.DeleteAll();

        ObjectTypeToRun1 := ObjectType::Page;
        ObjectIDToRun1 := Page::"Assisted Setup Wizard";
        AssistedSetupGroup := AssistedSetupGroup::Uncategorized;
        VideoCategory := VideoCategory::Uncategorized;
        GuidedExperienceTestLibrary.InsertAssistedSetup(true, Title1, ShortTitle1, Description1, ExpectedDuration,
            ObjectTypeToRun1, ObjectIDToRun1, AssistedSetupGroup, VideoUrl, VideoCategory, HelpUrl);

        ObjectTypeToRun2 := ObjectType::Page;
        ObjectIDToRun2 := Page::Checklist;
        GuidedExperienceTestLibrary.InsertAssistedSetup(true, Title2, ShortTitle2, Description2, ExpectedDuration,
            ObjectTypeToRun2, ObjectIDToRun2, AssistedSetupGroup, VideoUrl, VideoCategory, HelpUrl);

        // [WHEN] Trying to remove a guided experience item that does not exist
        GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectTypeToRun1, Page::"Manual Setup");

        // [THEN] The Guided Experience Item table contains exactly 2 records
        Assert.AreEqual(2, GuidedExperienceItem.Count, 'None of the records should have been deleted.');

        // [WHEN] Removing one of the existing assisted setups
        GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectTypeToRun1, ObjectIDToRun1);

        // [THEN] The Guided Experience Item table contains exactly 1 record
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item table should contain exactly 1 record.');

        // [THEN] The fields of the existing record are correct
        GuidedExperienceItem.FindFirst();
        Assert.AreEqual(Title2, GuidedExperienceItem.Title, 'The title is incorrect.');
        Assert.AreEqual(ShortTitle2, GuidedExperienceItem."Short Title", 'The short title is incorrect.');
        Assert.AreEqual(Description2, GuidedExperienceItem.Description, 'The description is incorrect.');
        Assert.AreEqual(ObjectIDToRun2, GuidedExperienceItem."Object ID to Run", 'The object ID is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveManualSetup()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        ManualSetupCategory: Enum "Manual Setup Category";
        ObjectTypeToRun1: ObjectType;
        ObjectTypeToRun2: ObjectType;
        ObjectIDToRun1: Integer;
        ObjectIDToRun2: Integer;
        Title1: Text[2048];
        Title2: Text[2048];
        ShortTitle1: Text[50];
        ShortTitle2: Text[50];
        Description1: Text[1024];
        Description2: Text[1024];
        Keywords: Text[250];
        ExpectedDuration: Integer;
    begin
        PermissionsMock.Set('Guided Exp Edit');

        // [GIVEN] The Guided Experience Item table contains 2 manual setups
        GuidedExperienceItem.DeleteAll();

        ObjectTypeToRun1 := ObjectType::Codeunit;
        ObjectIDToRun1 := Codeunit::"Checklist Test Codeunit";
        ManualSetupCategory := ManualSetupCategory::Uncategorized;
        GuidedExperienceTestLibrary.InsertManualSetup(true, Title1, ShortTitle1, Description1, ExpectedDuration,
            ObjectTypeToRun1, ObjectIDToRun1, ManualSetupCategory, Keywords);

        ObjectTypeToRun2 := ObjectType::Report;
        ObjectIDToRun2 := Report::"Checklist Test Report";
        GuidedExperienceTestLibrary.InsertManualSetup(true, Title2, ShortTitle2, Description2, ExpectedDuration,
            ObjectTypeToRun2, ObjectIDToRun2, ManualSetupCategory, Keywords);

        // [WHEN] Trying to remove a guided experience item that does not exist
        GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectTypeToRun1, ObjectIDToRun1);

        // [THEN] The Guided Experience Item table contains exactly 2 records
        Assert.AreEqual(2, GuidedExperienceItem.Count, 'None of the records should have been deleted.');

        // [WHEN] Removing one of the manual setups
        GuidedExperience.Remove(GuidedExperienceType::"Manual Setup", ObjectTypeToRun1, ObjectIDToRun1);

        // [THEN] The Guided Experience Item table contains exactly 1 record
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item table should contain exactly 1 record.');

        // [THEN] The fields of the existing record are correct
        GuidedExperienceItem.FindFirst();
        Assert.AreEqual(Title2, GuidedExperienceItem.Title, 'The title is incorrect.');
        Assert.AreEqual(ShortTitle2, GuidedExperienceItem."Short Title", 'The short title is incorrect.');
        Assert.AreEqual(Description2, GuidedExperienceItem.Description, 'The description is incorrect.');
        Assert.AreEqual(ObjectIDToRun2, GuidedExperienceItem."Object ID to Run", 'The object ID is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveLink()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        Title1: Text[2048];
        Title2: Text[2048];
        ShortTitle1: Text[50];
        ShortTitle2: Text[50];
        Description1: Text[1024];
        Description2: Text[1024];
        Link1: Text[250];
        Link2: Text[250];
        ExpectedDuration: Integer;
    begin
        PermissionsMock.Set('Guided Exp Edit');

        // [GIVEN] The Guided Experience Item table contains 2 learn links
        GuidedExperienceItem.DeleteAll();

        Link1 := CopyStr(Any.AlphanumericText(MaxStrLen(Link1)), 1, MaxStrLen(Link1));
        GuidedExperienceTestLibrary.InsertLearnLink(true, Title1, ShortTitle1, Description1, ExpectedDuration, Link1);

        Link2 := CopyStr(Any.AlphanumericText(MaxStrLen(Link2)), 1, MaxStrLen(Link2));
        GuidedExperienceTestLibrary.InsertLearnLink(true, Title2, ShortTitle2, Description2, ExpectedDuration, Link2);

        // [WHEN] Trying to remove a guided experience item that does not exist
        GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Checklist Item Roles");

        // [THEN] The Guided Experience Item table contains exactly 2 records
        Assert.AreEqual(2, GuidedExperienceItem.Count, 'None of the records should have been deleted.');

        // [WHEN] Removing one of the links
        GuidedExperience.Remove(GuidedExperienceType::Learn, Link2);

        // [THEN] The Guided Experience Item table contains exactly 1 record
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item table should contain exactly 1 record.');

        // [THEN] The fields of the existing record are correct
        GuidedExperienceItem.FindFirst();
        Assert.AreEqual(Title1, GuidedExperienceItem.Title, 'The title is incorrect.');
        Assert.AreEqual(ShortTitle1, GuidedExperienceItem."Short Title", 'The short title is incorrect.');
        Assert.AreEqual(Description1, GuidedExperienceItem.Description, 'The description is incorrect.');
        Assert.AreEqual(Link1, GuidedExperienceItem.Link, 'The link is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveApplicationFeature()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        ObjectTypeToRun1: ObjectType;
        ObjectTypeToRun2: ObjectType;
        ObjectIDToRun1: Integer;
        ObjectIDToRun2: Integer;
        Title1: Text[2048];
        Title2: Text[2048];
        ShortTitle1: Text[50];
        ShortTitle2: Text[50];
        Description1: Text[1024];
        Description2: Text[1024];
        ExpectedDuration: Integer;
    begin
        PermissionsMock.Set('Guided Exp Edit');

        // [GIVEN] The Guided Experience Item table contains 2 application features
        GuidedExperienceItem.DeleteAll();

        ObjectTypeToRun1 := ObjectType::Page;
        ObjectIDToRun1 := Page::"Checklist Administration";
        GuidedExperienceTestLibrary.InsertApplicationFeature(true, Title1, ShortTitle1, Description1,
            ExpectedDuration, ObjectTypeToRun1, ObjectIDToRun1);

        ObjectTypeToRun2 := ObjectType::Report;
        ObjectIDToRun2 := Report::"Checklist Test Report";
        GuidedExperienceTestLibrary.InsertApplicationFeature(true, Title2, ShortTitle2, Description2,
            ExpectedDuration, ObjectTypeToRun2, ObjectIDToRun2);

        // [WHEN] Trying to remove a guided experience item that does not exist
        GuidedExperience.Remove(GuidedExperienceType::"Manual Setup", ObjectTypeToRun1, ObjectIDToRun1);

        // [THEN] The Guided Experience Item table contains exactly 2 records
        Assert.AreEqual(2, GuidedExperienceItem.Count, 'None of the records should have been deleted.');

        // [WHEN] Removing one of the application features
        GuidedExperience.Remove(GuidedExperienceType::"Application Feature", ObjectTypeToRun2, ObjectIDToRun2);

        // [THEN] The Guided Experience Item table contains exactly 1 record
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item table should contain exactly 1 record.');

        // [THEN] The fields of the existing record are correct
        GuidedExperienceItem.FindFirst();
        Assert.AreEqual(Title1, GuidedExperienceItem.Title, 'The title is incorrect.');
        Assert.AreEqual(ShortTitle1, GuidedExperienceItem."Short Title", 'The short title is incorrect.');
        Assert.AreEqual(Description1, GuidedExperienceItem.Description, 'The description is incorrect.');
        Assert.AreEqual(ObjectIDToRun1, GuidedExperienceItem."Object ID to Run", 'The object ID is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveVideo()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        VideoCategory: Enum "Video Category";
        Title1: Text[2048];
        Title2: Text[2048];
        ShortTitle1: Text[50];
        ShortTitle2: Text[50];
        Description1: Text[1024];
        Description2: Text[1024];
        VideoUrl1: Text[250];
        VideoUrl2: Text[250];
        ExpectedDuration: Integer;
    begin
        PermissionsMock.Set('Guided Exp Edit');

        // [GIVEN] The Guided Experience Item table contains 2 video urls
        GuidedExperienceItem.DeleteAll();

        VideoCategory := VideoCategory::Uncategorized;
        VideoUrl1 := CopyStr(Any.AlphanumericText(MaxStrLen(VideoUrl1)), 1, MaxStrLen(VideoUrl1));
        GuidedExperienceTestLibrary.InsertVideo(true, Title1, ShortTitle1,
            Description1, ExpectedDuration, VideoUrl1, VideoCategory);

        VideoUrl2 := CopyStr(Any.AlphanumericText(MaxStrLen(VideoUrl2)), 1, MaxStrLen(VideoUrl2));
        GuidedExperienceTestLibrary.InsertVideo(true, Title2, ShortTitle2,
            Description2, ExpectedDuration, VideoUrl2, VideoCategory);

        // [WHEN] Trying to remove a guided experience item that does not exist
        GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Assisted Setup");

        // [THEN] The Guided Experience Item table contains exactly 2 records
        Assert.AreEqual(2, GuidedExperienceItem.Count, 'None of the records should have been deleted.');

        // [WHEN] Removing one of the video urls
        GuidedExperience.Remove(GuidedExperienceType::Video, VideoUrl2);

        // [THEN] The Guided Experience Item table contains exactly 1 record
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item table should contain exactly 1 record.');

        // [THEN] The fields of the existing record are correct
        GuidedExperienceItem.FindFirst();
        Assert.AreEqual(Title1, GuidedExperienceItem.Title, 'The title is incorrect.');
        Assert.AreEqual(ShortTitle1, GuidedExperienceItem."Short Title", 'The short title is incorrect.');
        Assert.AreEqual(Description1, GuidedExperienceItem.Description, 'The description is incorrect.');
        Assert.AreEqual(VideoUrl1, GuidedExperienceItem."Video Url", 'The video URL is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveTour()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        ObjectIDToRun1: Integer;
        ObjectIDToRun2: Integer;
        Title1: Text[2048];
        Title2: Text[2048];
        ShortTitle1: Text[50];
        ShortTitle2: Text[50];
        Description1: Text[1024];
        Description2: Text[1024];
        ExpectedDuration: Integer;
    begin
        PermissionsMock.Set('Guided Exp Edit');

        // [GIVEN] The Guided Experience Item table contains 2 tours
        GuidedExperienceItem.DeleteAll();

        ObjectIDToRun1 := Page::"Checklist Administration";
        GuidedExperienceTestLibrary.InsertTour(true, Title1, ShortTitle1, Description1, ExpectedDuration, ObjectIDToRun1);

        ObjectIDToRun2 := Page::"Assisted Setup Wizard";
        GuidedExperienceTestLibrary.InsertTour(true, Title2, ShortTitle2, Description2, ExpectedDuration, ObjectIDToRun2);

        // [WHEN] Trying to remove a guided experience item that does not exist
        GuidedExperience.Remove(GuidedExperienceType::Tour, ObjectType::Codeunit, ObjectIDToRun1);

        // [THEN] The Guided Experience Item table contains exactly 2 records
        Assert.AreEqual(2, GuidedExperienceItem.Count, 'None of the records should have been deleted.');

        // [WHEN] Removing one of the tours
        GuidedExperience.Remove(GuidedExperienceType::Tour, ObjectType::Page, ObjectIDToRun2);

        // [THEN] The Guided Experience Item table contains exactly 1 record
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item table should contain exactly 1 record.');

        // [THEN] The fields of the existing record are correct
        GuidedExperienceItem.FindFirst();
        Assert.AreEqual(Title1, GuidedExperienceItem.Title, 'The title is incorrect.');
        Assert.AreEqual(ShortTitle1, GuidedExperienceItem."Short Title", 'The short title is incorrect.');
        Assert.AreEqual(Description1, GuidedExperienceItem.Description, 'The description is incorrect.');
        Assert.AreEqual(ObjectIDToRun1, GuidedExperienceItem."Object ID to Run", 'The object ID is incorrect.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemoveSpotlightTour()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        SpotlightTourText: Record "Spotlight Tour Text";
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
        SpotlightTourType: Enum "Spotlight Tour Type";
        SpotlightTourTexts: Dictionary of [Enum "Spotlight Tour Text", Text];
        ObjectIDToRun1: Integer;
        ObjectIDToRun2: Integer;
        Title1: Text[2048];
        Title2: Text[2048];
        ShortTitle1: Text[50];
        ShortTitle2: Text[50];
        Description1: Text[1024];
        Description2: Text[1024];
        ExpectedDuration: Integer;
    begin
        PermissionsMock.Set('Guided Exp Edit');

        // [GIVEN] The Guided Experience Item table contains 2 spotlight tours
        GuidedExperienceItem.DeleteAll();
        SpotlightTourText.DeleteAll();

        ObjectIDToRun1 := Page::"Checklist Administration";
        SpotlightTourType := SpotlightTourType::"Share to Teams";
        GuidedExperienceTestLibrary.InsertSpotlightTour(true, Title1, ShortTitle1, Description1,
            ExpectedDuration, ObjectIDToRun1, SpotlightTourType, SpotlightTourTexts);

        ObjectIDToRun2 := Page::"Assisted Setup Wizard";
        GuidedExperienceTestLibrary.InsertSpotlightTour(true, Title2, ShortTitle2, Description2,
            ExpectedDuration, ObjectIDToRun2, SpotlightTourType, SpotlightTourTexts);

        // [WHEN] Trying to remove a guided experience item that does not exist
        GuidedExperience.Remove(GuidedExperienceType::"Spotlight Tour", ObjectType::Report, ObjectIDToRun1, SpotlightTourType);

        // [THEN] The Guided Experience Item table contains exactly 2 records and the spotlight tour texts 8
        Assert.AreEqual(2, GuidedExperienceItem.Count, 'None of the records should have been deleted.');
        Assert.AreEqual(8, SpotlightTourText.Count, 'None of the spotlight tour texts should have been deleted.');

        // [WHEN] Removing one of the spotlight tours
        GuidedExperience.Remove(GuidedExperienceType::"Spotlight Tour", ObjectType::Page, ObjectIDToRun1, SpotlightTourType);

        // [THEN] The Guided Experience Item table contains exactly 1 record
        Assert.AreEqual(1, GuidedExperienceItem.Count, 'The Guided Experience Item table should contain exactly 1 record.');

        // [THEN] The fields of the existing record are correct
        GuidedExperienceItem.FindFirst();
        Assert.AreEqual(Title2, GuidedExperienceItem.Title, 'The title is incorrect.');
        Assert.AreEqual(ShortTitle2, GuidedExperienceItem."Short Title", 'The short title is incorrect.');
        Assert.AreEqual(Description2, GuidedExperienceItem.Description, 'The description is incorrect.');
        Assert.AreEqual(ObjectIDToRun2, GuidedExperienceItem."Object ID to Run", 'The object ID is incorrect.');
        Assert.AreEqual(SpotlightTourType, GuidedExperienceItem."Spotlight Tour Type", 'The spotlight tour type is incorrect.');

        // [THEN] The spotlight tours for the correct item have been deleted
        Assert.AreEqual(4, SpotlightTourText.Count, 'The number of spotlight tour texts is incorrect.');
        SpotlightTourText.SetRange("Guided Experience Item Code", 'SPOTLIGHT TOUR_PAGE_132610__' + Format(SpotlightTourType.AsInteger()));
        SpotlightTourText.SetRange("Guided Experience Item Version", 0);
        Assert.AreEqual(4, SpotlightTourText.Count, 'The spotlight tour texts have incorrect keys.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGuidedExperienceDoNotShowDuplicateRecordForSameCombination()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        TempGuidedExperienceItem: Record "Guided Experience Item" temporary;
        GuidedExperienceImpl: Codeunit "Guided Experience Impl.";
        GuidedExperienceType: Enum "Guided Experience Type";
        ManualSetupCategory: Enum "Manual Setup Category";
        ObjectTypeToRun1: ObjectType;
        ObjectTypeToRun2: ObjectType;
        ObjectIDToRun1: Integer;
        ObjectIDToRun2: Integer;
        Title1: Text[2048];
        Title2: Text[2048];
        ShortTitle1: Text[50];
        ShortTitle2: Text[50];
        Description1: Text[1024];
        Description2: Text[1024];
        Keywords: Text[250];
        ExpectedDuration: Integer;
    begin
        // [SCENARIO 467947] Numerous Sales and Inventory Forecast Entries appear in Manual Setup.
        PermissionsMock.Set('Guided Exp Edit');

        // [GIVEN] The Guided Experience Item table contains 2 manual setups
        GuidedExperienceItem.DeleteAll();

        // [GIVEN] Define ObjectType, Object ID and Manual Setup Category
        ObjectTypeToRun1 := ObjectType::Codeunit;
        ObjectIDToRun1 := Codeunit::"Checklist Test Codeunit";
        ManualSetupCategory := ManualSetupCategory::Uncategorized;

        // [GIVEN] Insert Manual Setup
        GuidedExperienceTestLibrary.InsertManualSetup(true, Title1, ShortTitle1, Description1, ExpectedDuration,
            ObjectTypeToRun1, ObjectIDToRun1, ManualSetupCategory, Keywords);

        // [GIVEN] Define ObjectType and Object ID 
        ObjectTypeToRun2 := ObjectType::Codeunit;
        ObjectIDToRun2 := Codeunit::"Checklist Test Codeunit";

        // [GIVEN] Insert Manual Setup with same detail
        GuidedExperienceTestLibrary.InsertManualSetup(true, Title2, ShortTitle2, Description2, ExpectedDuration,
            ObjectTypeToRun2, ObjectIDToRun2, ManualSetupCategory, Keywords);

        // [WHEN] Create Page to view Manual setup entry by Temporary Guided Experience Item table  
        GuidedExperienceImpl.GetContentForSetupPage(TempGuidedExperienceItem, GuidedExperienceType::"Manual Setup");

        // [THEN] Temporary Guided Experience Item table contains exactly 1 records
        Assert.AreEqual(1, TempGuidedExperienceItem.Count, GuidedExperienceRecordCountErr);
    end;

    [Test]
    procedure TestResetAssistedSetupConsiderFilter()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        // [SCENARIO] When more than one assisted setup is completed and reset is called on one of them, only the one that has been reset has status incomplete.

        // [GIVEN] The Guided Experience Item table contains 2 assisted setups
        GuidedExperience.InsertAssistedSetup('My Assisted Setup Test Page', 'My Assisted Setup Test Page', 'Description of Setup Page', 0, ObjectType::Page,
            Page::"My Assisted Setup Test Page", Enum::"Assisted Setup Group"::WithLinks, 'http://youtube.com', "Video Category"::Uncategorized, 'https://docs.microsoft.com/');

        GuidedExperience.InsertAssistedSetup('Other Assisted Setup Test Page', 'Other Assisted Setup Test Page', '', 0, ObjectType::Page,
            Page::"Other Assisted Setup Test Page", Enum::"Assisted Setup Group"::WithoutLinks, '', "Video Category"::Uncategorized, '');

        // [WHEN] Both assisted setups are completed
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"My Assisted Setup Test Page");
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Other Assisted Setup Test Page");

        // [WHEN] Reset is called on one of them
        GuidedExperience.ResetAssistedSetup(ObjectType::Page, Page::"Other Assisted Setup Test Page");

        // [THEN] Only the one that has been reset has status incomplete
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Other Assisted Setup Test Page"), 'The assisted setup that has been reset should be incomplete.');

        // [THEN] The other one is still completed
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"My Assisted Setup Test Page"), 'The assisted setup that has not been reset should still be completed.');
    end;

    local procedure VerifyGuidedExperienceItemFields(GuidedExperienceItem: Record "Guided Experience Item"; Code: Code[300]; Version: Integer; ObjectTypeToRun: Enum "Guided Experience Object Type"; ObjectID: Integer; Link: Text[250]; Title: Text[2048]; ShortTitle: Text[2048]; Description: Text[1024]; ExpectedDuration: Integer; Completed: Boolean; GuidedExperienceType: Enum "Guided Experience Type"; AssistedSetupGroup: Enum "Assisted Setup Group"; HelpUrl: Text[250]; VideoUrl: Text[250]; VideoCategory: Enum "Video Category"; ManualSetupCategory: Enum "Manual Setup Category"; Keywords: Text[250]; SpotlightTourType: Enum "Spotlight Tour Type"; SpotlightTourTexts: Dictionary of [Enum "Spotlight Tour Text", Text])
    begin
        Assert.AreEqual(Code, GuidedExperienceItem.Code, 'The Code field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(Version, GuidedExperienceItem.Version, 'The Version field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(ObjectTypeToRun, GuidedExperienceItem."Object Type to Run", 'The Object Type to Run field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(ObjectID, GuidedExperienceItem."Object ID to Run", 'The Object ID to Run field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(Link, GuidedExperienceItem.Link, 'The Link field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(Title, GuidedExperienceItem.Title, 'The Title field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(ShortTitle, GuidedExperienceItem."Short Title", 'The Short Title field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(Description, GuidedExperienceItem.Description, 'The Description field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(ExpectedDuration, GuidedExperienceItem."Expected Duration", 'The Expected Duration field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(Completed, GuidedExperienceItem.Completed, 'The Completed field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(GuidedExperienceType, GuidedExperienceItem."Guided Experience Type", 'The Guided Experience Type field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(AssistedSetupGroup, GuidedExperienceItem."Assisted Setup Group", 'The Assisted Setup Group field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(HelpUrl, GuidedExperienceItem."Help Url", 'The Help Url field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(VideoUrl, GuidedExperienceItem."Video Url", 'The Video Url field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(VideoCategory, GuidedExperienceItem."Video Category", 'The Video Category field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(ManualSetupCategory, GuidedExperienceItem."Manual Setup Category", 'The Manual Setup Category field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(Keywords, GuidedExperienceItem.Keywords, 'The Keywords field of the Guided Experience Item is incorrect.');
        Assert.AreEqual(SpotlightTourType, GuidedExperienceItem."Spotlight Tour Type", 'The Spotlight Tour Type of the Guided Experience Item is incorrect.');

        VerifySpotlightTourTexts(SpotlightTourTexts, GuidedExperienceItem.Code, GuidedExperienceItem.Version);
    end;

    local procedure VerifySpotlightTourTexts(SpotlightTourTexts: Dictionary of [Enum "Spotlight Tour Text", Text]; Code: Code[300]; Version: Integer)
    var
        SpotlightTourText: Record "Spotlight Tour Text";
        SpotlightTourTextEnum: Enum "Spotlight Tour Text";
    begin
        SpotlightTourText.SetRange("Guided Experience Item Code", Code);
        SpotlightTourText.SetRange("Guided Experience Item Version", Version);
        foreach SpotlightTourTextEnum in SpotlightTourTexts.Keys() do begin
            SpotlightTourText.SetRange("Spotlight Tour Step", SpotlightTourTextEnum);
            Assert.IsTrue(SpotlightTourText.FindFirst(), 'The record for the key ' + Format(SpotlightTourTextEnum) + ' could not be found in the database');
            Assert.AreEqual(SpotlightTourTexts.Get(SpotlightTourTextEnum), SpotlightTourText."Spotlight Tour Text",
                'The text for the ' + Format(SpotlightTourTextEnum) + 'is incorrect.');
        end;
    end;

    local procedure VerifyAfterNonIdenticalInsertion(Code: Code[300])
    var
        GuidedExperienceItem: Record "Guided Experience Item";
    begin
        // [THEN] There are 2 records in the Guided Experience Item table
        Assert.AreEqual(2, GuidedExperienceItem.Count, 'The Guided Experience Item should contain two records');

        // [THEN] Both of the records should have the same code
        GuidedExperienceItem.SetRange(Code, Code);
        Assert.AreEqual(2, GuidedExperienceItem.Count, 'The Guided Experience Item should contain two records with the same Code');
    end;

    local procedure VerifyAfterIdenticalInsertion(Code: Code[300])
    var
        GuidedExperienceItem: Record "Guided Experience Item";
    begin
        // [THEN] The Guided Experience Item table does not contain a new record
        Assert.AreEqual(2, GuidedExperienceItem.Count, 'The Guided Experience Item should not contain a new version of the object.');

        // [THEN] There shouln't be a record with version 2 in the Guided Experience Item table
        Assert.IsFalse(GuidedExperienceItem.Get(Code, 2), 'The Guided Experience Item should not contain a new version of the object.');
    end;
}