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
    [HandlerFunctions('OpenStatusConfirmHandler,ExtensionDeploymentStatusPageHandler')]
    procedure InstallFailurePromptOpensStatusPage()
    var
        ExtensionMgtTestLibrary: Codeunit "Extension Mgt. Test Library";
    begin
        LibraryVariableStorage.Enqueue(InstallationFailedOpenStatusQst);

        ExtensionMgtTestLibrary.ShowInstallFailureStatus();

        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Extension Installation Status should open.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('DeclineStatusConfirmHandler')]
    procedure InstallFailurePromptCanBeDeclined()
    var
        ExtensionMgtTestLibrary: Codeunit "Extension Mgt. Test Library";
    begin
        LibraryVariableStorage.Enqueue(InstallationFailedOpenStatusQst);

        ExtensionMgtTestLibrary.ShowInstallFailureStatus();

        LibraryVariableStorage.AssertEmpty();
    end;

    [ConfirmHandler]
    procedure OpenStatusConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, 'Unexpected confirmation question.');
        Reply := true;
    end;

    [ConfirmHandler]
    procedure DeclineStatusConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), Question, 'Unexpected confirmation question.');
        Reply := false;
    end;

    [PageHandler]
    procedure ExtensionDeploymentStatusPageHandler(var ExtensionDeploymentStatus: TestPage "Extension Deployment Status")
    begin
        LibraryVariableStorage.Enqueue(true);
        ExtensionDeploymentStatus.Close();
    end;
}
