// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Environment.Configuration;

using System.Environment.Configuration;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 132599 "Duplicated Guided Exp. Item"
{
    Subtype = Test;
    Permissions = tabledata "Guided Experience Item" = rimd;

    var
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";
        DummyGuidedExperienceCode1Lbl: Label 'Dummy Guided Experience Code 1', Locked = true;
        DummyGuidedExperienceCode2Lbl: Label 'Dummy Guided Experience Code 2', Locked = true;

    [Test]
    procedure TestInsertDuplicatedGuidedExperienceItems()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperience: Codeunit "Guided Experience";
        Limit, Counter : Integer;
    begin
        // [SCENARIO] Insert multiple Guided Experience Items with the same Code
        PermissionsMock.Set('Guided Exp Edit');

        GuidedExperienceItem.DeleteAll();

        Assert.AreEqual(0, GuidedExperienceItem.Count(), 'No records should exists in the Guided Experience Item table before the test starts.');

        // [GIVEN] Insert multiple Guided Experience Items with the same Code, but with different ShortTitles
        Limit := 1000;
        for Counter := 1 to Limit do
            GuidedExperience.InsertManualSetup('Title', Format(Counter), '', 0, ObjectType::Page, Page::"Assisted Setup Wizard", Enum::"Manual Setup Category"::Uncategorized, '');

        // [Then] Only 2 Guided Experience Items should be inserted
        // Version 0 also exists because we can't Rename records with empty value in the primary key
        Assert.AreEqual(2, GuidedExperienceItem.Count(), 'Guided Experience Item table should only contain 2 records.');
    end;

    [Test]
    procedure TestCleanupDuplicatedGuidedExperienceItems()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperience: Codeunit "Guided Experience";
        Limit, Counter : Integer;
    begin
        // [SCENARIO] Cleanup old Guided Experience Items
        PermissionsMock.Set('Guided Exp Edit');

        GuidedExperienceItem.DeleteAll();

        Assert.AreEqual(0, GuidedExperienceItem.Count(), 'No records should exists in the Guided Experience Item table before the test starts.');

        // [GIVEN] Mock the situation where multiple version of the same Guided Experience Item exist
        Limit := 1000;
        for Counter := 1 to Limit do
            InsertDuplicatedGuidedExperienceItems(DummyGuidedExperienceCode1Lbl, Counter, 'Title');

        for Counter := 1 to Limit do
            InsertDuplicatedGuidedExperienceItems(DummyGuidedExperienceCode2Lbl, Counter, 'Title');

        // [Then] 2000 Guided Experience Items should be inserted
        Assert.AreEqual(Limit * 2, GuidedExperienceItem.Count(), 'Dummy Guided Experience Items should be populated.');

        // [WHEN] Clean up old Guided Experience Items
        GuidedExperience.CleanupOldGuidedExperienceItems(false, 100);

        // [Then] Only 2 Guided Experience Items should be left
        Assert.AreEqual(2, GuidedExperienceItem.Count(), 'The Guided Experience Item table should contain exactly 1 record for each Code after cleanup.');
    end;

    [Test]
    procedure TestRemoveBeforeInsertGuidedExperienceItems()
    var
        GuidedExperienceItem: Record "Guided Experience Item";
        GuidedExperience: Codeunit "Guided Experience";
        Limit, Counter : Integer;
    begin
        // [SCENARIO] Remove duplicated Guided Experience Items before inserting new one
        PermissionsMock.Set('Guided Exp Edit');

        GuidedExperienceItem.DeleteAll();

        Assert.AreEqual(0, GuidedExperienceItem.Count(), 'No records should exists in the Guided Experience Item table before the test starts.');

        // [GIVEN] Insert multiple Guided Experience Items with the same Code, but with different ShortTitles
        Limit := 1000;
        for Counter := 1 to Limit do
            GuidedExperience.InsertManualSetup('Title', Format(Counter), '', 0, ObjectType::Page, Page::"Assisted Setup Wizard", Enum::"Manual Setup Category"::Uncategorized, '');

        // [Then] Only 2 Guided Experience Items should be inserted
        // Version 0 also exists because we can't Rename records with empty value in the primary key
        Assert.AreEqual(2, GuidedExperienceItem.Count(), 'Guided Experience Item table should only contain 2 records.');

        // [When] Remove Guided Experience Items with standard functionality
        GuidedExperience.Remove(Enum::"Guided Experience Type"::"Manual Setup", ObjectType::Page, Page::"Assisted Setup Wizard");

        // [Then] All Guided Experience Items should be removed
        Assert.AreEqual(0, GuidedExperienceItem.Count(), 'Guided Experience Item table should be empty.');

        // [When] Insert Guided Experience Items with standard functionality again
        GuidedExperience.InsertManualSetup('Title', 'Short Title', '', 0, ObjectType::Page, Page::"Assisted Setup Wizard", Enum::"Manual Setup Category"::Uncategorized, '');

        // [Then] Only 1 Guided Experience Items should be inserted
        Assert.AreEqual(1, GuidedExperienceItem.Count(), 'Guided Experience Item table should contain exactly 1 record.');
    end;

    // The Standard Insert procedure is safeguarded to prevent inserting duplicated records, see `TestInsertDuplicatedGuidedExperienceItems`
    // Create a local procedure to bypass the safeguard, and mock the situation where multiple version of the same Guided Experience Item are inserted
    // The test (and the cleanup functionality) is needed because we need to cleanup existing duplicated records, even thought the Standard Insert procedure is safeguarded
    local procedure InsertDuplicatedGuidedExperienceItems(Code: Code[300]; Version: Integer; Title: Text[2048])
    var
        GuidedExperienceItem: Record "Guided Experience Item";
    begin
        GuidedExperienceItem.Code := Code;
        GuidedExperienceItem.Version := Version;
        GuidedExperienceItem.Title := Title;

        GuidedExperienceItem.Insert();
    end;
}