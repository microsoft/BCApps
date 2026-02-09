// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.SetupGuide;

using Microsoft.QualityManagement.Setup;
using Microsoft.QualityManagement.Setup.ApplicationAreas;
using Microsoft.Utilities;
using System.Environment.Configuration;
using System.Media;

/// <summary>
/// Assisted setup functionality for the plus version.
/// </summary>
codeunit 20401 "Qlty. Assisted Setup"
{
    Permissions = tabledata "Assisted Company Setup Status" = rimd;

    var
        QltyManagementSetup: Record "Qlty. Management Setup";
        AssistedSetUpAssistantNameTxt: Label 'Set up Quality Management';
        AssistedSetupDescriptionTxt: Label 'Set up Quality Management to define inspection plans, quality measures, and quality control processes.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', true, true)]
    local procedure HandleOnRegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        QltyApplicationAreaMgmt: Codeunit "Qlty. Application Area Mgmt.";
        CurrentAppID: Guid;
        Exists: Boolean;
    begin
        CurrentAppID := QltyManagementSetup.GetAppGuid();
        Exists := GuidedExperience.Exists("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Qlty. Management Setup Guide");

        if not QltyApplicationAreaMgmt.IsQualityManagementApplicationAreaEnabled() then
            exit;

        if not Exists then
            GuidedExperience.InsertAssistedSetup(
                CopyStr(AssistedSetUpAssistantNameTxt, 1, 2048),
                CopyStr(AssistedSetUpAssistantNameTxt, 1, 50),
                CopyStr(AssistedSetupDescriptionTxt, 1, 1024),
                3,
                ObjectType::Page,
                Page::"Qlty. Management Setup Guide",
                "Assisted Setup Group"::DoMoreWithBC,
                '',
                "Video Category"::Extensions,
                'https://go.microsoft.com/fwlink/?linkid=2338953',
                true);
    end;
}
