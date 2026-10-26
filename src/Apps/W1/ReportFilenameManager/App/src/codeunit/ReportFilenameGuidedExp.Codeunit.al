// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting.FileNaming;

using System.Environment.Configuration;

codeunit 8140 "Report Filename Guided Exp."
{
    // Lists Report Filename Setup under Manual Setup, in the System category, where Base
    // Application also lists Report Layout Selection.

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
