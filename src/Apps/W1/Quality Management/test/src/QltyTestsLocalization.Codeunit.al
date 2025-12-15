// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using System.TestLibraries.Utilities;

codeunit 139974 "Qlty. Tests - Localization"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        LockedYesLbl: Label 'Yes', Locked = true;
        LockedNoLbl: Label 'No', Locked = true;
        IsInitialized: Boolean;

    [Test]
    procedure GetLockedNo250()
    begin
        // [SCENARIO] Get locked "No" text value

        Initialize();

        // [WHEN] GetLockedNo250 is called
        // [THEN] The function returns the locked string "No"
        LibraryAssert.AreEqual('No', LockedNoLbl, 'locked no.');
    end;

    [Test]
    procedure GetLockedYes250()
    begin
        // [SCENARIO] Get locked "Yes" text value
        Initialize();

        // [WHEN] GetLockedYes250 is called
        // [THEN] The function returns the locked string "Yes"
        LibraryAssert.AreEqual('Yes', LockedYesLbl, 'locked yes.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        Commit();
    end;
}
