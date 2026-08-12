// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Company;
using Microsoft.Manufacturing.Setup;
using System.Environment.Configuration;
using System.Media;

codeunit 99001502 "Subc. Business Setup Ext."
{
    var
        AssistedSetupDescriptionLbl: Label 'Review company defaults and continue with the pages used to configure your subcontracting process.';
        AssistedSetupShortTitleLbl: Label 'Set up Subcontracting';
        AssistedSetupTitleLbl: Label 'Set up Subcontracting';
        DocumentationUrlLbl: Label 'https://go.microsoft.com/fwlink/?linkid=2345593', Locked = true;
        SubcontractingDescriptionLbl: Label 'Make manual Subcontracting Setup';
        SubcontractingKeyWordsLbl: Label 'Subcontracting, Management';
        SubcontractingLbl: Label 'Subcontracting App';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", OnRegisterAssistedSetup, '', false, false)]
    local procedure OnRegisterAssistedSetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
    begin
        if GuidedExperience.Exists("Guided Experience Type"::"Assisted Setup", ObjectType::Page, Page::"Subcontracting Setup Wizard") then
            exit;

        GuidedExperience.InsertAssistedSetup(
            AssistedSetupTitleLbl,
            AssistedSetupShortTitleLbl,
            AssistedSetupDescriptionLbl,
            5,
            ObjectType::Page,
            Page::"Subcontracting Setup Wizard",
            AssistedSetupGroup::ReadyForBusiness,
            '',
            VideoCategory::ReadyForBusiness,
            DocumentationUrlLbl,
            true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", OnRegisterManualSetup, '', false, false)]
    local procedure OnRegisterManualSetup(sender: Codeunit "Guided Experience")
    var
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        sender.InsertManualSetup(SubcontractingLbl, SubcontractingLbl, SubcontractingDescriptionLbl, 0, ObjectType::Page, Page::"Manufacturing Setup", ManualSetupCategory::Uncategorized, SubcontractingKeyWordsLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", OnCompanyInitialize, '', false, false)]
    local procedure OnCompanyInitialize()
    var
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
    end;
}