// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Apps;

using System.Apps;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 133102 "Extension Marketplace Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        ExtensionManagement: Codeunit "Extension Management";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        PermissionsMock: Codeunit "Permissions Mock";
        InvalidAppIdErr: Label 'Selected extension could not be installed because a valid App Id is not passed.';

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('InstallationMessageHandler')]
    procedure FailedMarketplaceInstallShowsError()
    var
        NullGuid: Guid;
    begin
        // [GIVEN] An invalid AppSource app ID
        PermissionsMock.Set('Exten. Mgt. - Admin');
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(InvalidAppIdErr);

        // [WHEN] Installing the app
        ExtensionManagement.InstallMarketplaceExtension(NullGuid);

        // [THEN] The original error is shown exactly once
        LibraryVariableStorage.AssertEmpty();
    end;

    [MessageHandler]
    procedure InstallationMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
    end;
}
