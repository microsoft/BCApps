// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Apps;

using System.Apps;
using System.TestLibraries.Apps;
using System.TestLibraries.Utilities;

codeunit 133102 "Extension Marketplace Test"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        InstallationFailedOpenStatusQst: Label 'Sorry, we couldn''t install the app. Do you want to open Extension Installation Status?';

    [Test]
    [HandlerFunctions('ConfirmHandler,ExtensionDeploymentStatusPageHandler')]
    procedure InstallFailurePromptOpensStatusPage()
    var
        ExtensionMgtTestLibrary: Codeunit "Extension Mgt. Test Library";
    begin
        Initialize();
        LibraryVariableStorage.Enqueue(InstallationFailedOpenStatusQst);
        LibraryVariableStorage.Enqueue(true);

        ExtensionMgtTestLibrary.ShowInstallFailureStatus();

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Extension Installation Status should open.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure InstallFailurePromptCanBeDeclined()
    var
        ExtensionMgtTestLibrary: Codeunit "Extension Mgt. Test Library";
    begin
        Initialize();
        LibraryVariableStorage.Enqueue(InstallationFailedOpenStatusQst);
        LibraryVariableStorage.Enqueue(false);

        ExtensionMgtTestLibrary.ShowInstallFailureStatus();

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [PageHandler]
    procedure ExtensionDeploymentStatusPageHandler(var ExtensionDeploymentStatus: TestPage "Extension Deployment Status")
    begin
        LibraryVariableStorage.Enqueue(true);
        ExtensionDeploymentStatus.Close();
    end;
}
