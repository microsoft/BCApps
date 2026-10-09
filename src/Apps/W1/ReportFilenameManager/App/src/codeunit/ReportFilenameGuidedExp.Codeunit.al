// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 50125 "Report Filename Guided Exp."
{
    // Lists Report Filename Setup under Manual Setup, beside Report Layout Selection, so an
    // administrator can find it without knowing the page's name. Base Application registers its
    // own setup pages the same way, from Business Setup Subscribers, and puts Report Layout
    // Selection in the System category - the closest neighbour this setup has. A separate app
    // registers its own setup the same way, through the same event.

    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterManualSetup', '', false, false)]
    local procedure RegisterManualSetup(var Sender: Codeunit "Guided Experience")
    var
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        Sender.InsertManualSetup(TitleTxt, ShortTitleTxt, DescriptionTxt, 10, ObjectType::Page,
          Page::"Report Filename Setup", ManualSetupCategory::System, KeywordsTxt);
    end;

    var
        TitleTxt: Label 'Report file names', MaxLength = 2048;
        ShortTitleTxt: Label 'Report file names', MaxLength = 50;
        DescriptionTxt: Label 'Define the file names that reports get when they are downloaded, emailed, attached, scheduled or sent to disk.', MaxLength = 1024;
        KeywordsTxt: Label 'Report, File Name, PDF, Email, Attachment', MaxLength = 250;
}
