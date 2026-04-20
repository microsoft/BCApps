// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Environment.Configuration;
using System.Media;

/// <summary>
/// Registers the Performance Center assisted setup tile that launches the wizard.
/// </summary>
codeunit 8420 "Perf. Center Assisted Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure OnRegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        TitleTxt: Label 'Report a performance problem';
        ShortTitleTxt: Label 'Performance Center';
        DescriptionTxt: Label 'Tell us about a slow scenario and schedule a performance analysis. The Performance Center will capture data, filter it and explain what is going on.';
    begin
        if GuidedExperience.Exists(Enum::"Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Perf. Analysis Wizard") then
            exit;
        GuidedExperience.InsertAssistedSetup(
            TitleTxt,
            CopyStr(ShortTitleTxt, 1, 50),
            DescriptionTxt,
            5,
            ObjectType::Page,
            Page::"Perf. Analysis Wizard",
            Enum::"Assisted Setup Group"::Uncategorized,
            '',
            Enum::"Video Category"::Uncategorized,
            '');
    end;
}
