// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.GuidedExperience;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.RoleCenters;
using Microsoft.QualityManagement.Setup;
using System.Environment.Configuration;


codeunit 20419 "Qlty. Guided Experience"
{
    var
        QualityManagerRoleCenterTourShortTitleTxt: Label 'A first look around';
        QualityManagerRoleCenterTourTitleTxt: Label 'Take a first look around';
        QualityManagerRoleCenterTourDescriptionTxt: Label 'The Quality Manager home page offers metrics and activities that help run a business. We`ll also show you how to explore all Business Central features.';
        DemoDataShortTitleTxt: Label 'Demo data';
        DemoDataTitleTxt: Label 'Explore with demo data';
        DemoDataDescriptionTxt: Label 'Use Contoso demo data to explore Quality Management with sample quality tests, templates, generation rules, and inspections. This lets you learn how quality checks work without setting up your own data.';
        QualityTestsShortTitleTxt: Label 'Quality tests';
        QualityTestsTitleTxt: Label 'Understand quality tests';
        QualityTestsDescriptionTxt: Label 'Quality tests define what is measured. Visit the Quality Tests list to see available tests, then open a test card to review parameters, limits, and expected values used during inspections.';
        QualityTemplatesShortTitleTxt: Label 'Reuse inspection templates';
        QualityTemplatesTitleTxt: Label 'Quality templates';
        QualityTemplatesDescriptionTxt: Label 'With templates you can group and reuse quality tests so you can apply consistent inspection standards across items, processes, or scenarios. From the list you can create a new template card to understand its structure and purpose.';
        GenerationRulesShortTitleTxt: Label 'Set up inspection generation rules';
        GenerationRulesTitleTxt: Label 'Generation rules';
        GenerationRulesDescriptionTxt: Label 'Inspection generation rules define when quality inspections are created automatically, such as during receiving, production, or assembly.';
        QualityInspectionsShortTitleTxt: Label 'Track inspections';
        QualityInspectionsTitleTxt: Label 'Quality Inspections';
        QualityInspectionsDescriptionTxt: Label 'Browse the Quality Inspections list to see inspections created by rules or manually, and follow their status as they move through the inspection process.';
        ViewResultsShortTitleTxt: Label 'Review inspection results';
        ViewResultsTitleTxt: Label 'View results';
        ViewResultsDescriptionTxt: Label 'Review completed quality inspections to see test results, pass or fail outcomes, and recorded measurements. This helps you understand how inspection results are captured and tracked.';
        DefaultSetupShortTitleTxt: Label 'Quality Management setup page';
        DefaultSetupTitleTxt: Label 'Default setup';
        DefaultSetupDescriptionTxt: Label 'Define the behavior of how and when inspections are created. Manage when to show inspections, set up test generation rules, such as for production scenarios or inventory and warehouse inspections.';
        MicrosoftLearnShortTitleTxt: Label 'Discover more capabilities';
        MicrosoftLearnTitleTxt: Label 'Microsoft Learn';
        MicrosoftLearnDescriptionTxt: Label 'Discover what else you can do in your role. Explore Business Central''s quality capabilities to reach your needs, from manual or automated inspections on Microsoft Learn.';
        MicrosoftLearnLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2198403', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterGuidedExperienceItem', '', false, false)]
    local procedure OnRegisterGuidedExperienceItem()
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        GuidedExperience.InsertTour(QualityManagerRoleCenterTourTitleTxt, QualityManagerRoleCenterTourShortTitleTxt,
            QualityManagerRoleCenterTourDescriptionTxt, 2, Page::"Qlty. Manager RC");

        GuidedExperience.InsertApplicationFeature(DemoDataTitleTxt, DemoDataShortTitleTxt, DemoDataDescriptionTxt, 10, ObjectType::Page,
            51949); // Contoso Demo Tool Page
        GuidedExperience.InsertApplicationFeature(QualityTestsTitleTxt, QualityTestsShortTitleTxt, QualityTestsDescriptionTxt, 5, ObjectType::Page,
            Page::"Qlty. Tests");
        GuidedExperience.InsertApplicationFeature(QualityTemplatesTitleTxt, QualityTemplatesShortTitleTxt, QualityTemplatesDescriptionTxt, 3, ObjectType::Page,
            Page::"Qlty. Inspection Template List");
        GuidedExperience.InsertApplicationFeature(GenerationRulesTitleTxt, GenerationRulesShortTitleTxt, GenerationRulesDescriptionTxt, 4, ObjectType::Page,
            Page::"Qlty. Inspection Gen. Rules");
        GuidedExperience.InsertApplicationFeature(QualityInspectionsTitleTxt, QualityInspectionsShortTitleTxt, QualityInspectionsDescriptionTxt, 5, ObjectType::Page,
            Page::"Qlty. Inspection List");
        GuidedExperience.InsertApplicationFeature(ViewResultsTitleTxt, ViewResultsShortTitleTxt, ViewResultsDescriptionTxt, 6, ObjectType::Page,
            Page::"Qlty. Inspection Result List");
        GuidedExperience.InsertApplicationFeature(DefaultSetupTitleTxt, DefaultSetupShortTitleTxt, DefaultSetupDescriptionTxt, 7, ObjectType::Page,
            Page::"Qlty. Management Setup");

        GuidedExperience.InsertLearnLink(MicrosoftLearnTitleTxt, MicrosoftLearnShortTitleTxt, MicrosoftLearnDescriptionTxt, 8, MicrosoftLearnLinkTxt);
    end;

}
