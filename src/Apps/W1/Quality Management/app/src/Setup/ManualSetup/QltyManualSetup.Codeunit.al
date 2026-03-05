// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup.ManualSetup;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Result;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Setup;
using System.Environment.Configuration;

codeunit 20400 "Qlty. Manual Setup"
{
    Access = Internal;

    var
        QualityTestsShortTitleTxt: Label 'Set up quality tests';
        QualityTestsTitleTxt: Label 'Tests';
        QualityTestsDescriptionTxt: Label 'Set up quality tests to define what is measured. Visit the Quality Tests list to see available tests, then open a test card to review parameters, limits, and expected values used during inspections.';
        QualityTestsKeywordsTxt: Label 'Quality Tests, Measurements, Parameters, Expected Values';

        QualityTestLookupValuesShortTitleTxt: Label 'Set up quality test lookup values';
        QualityTestLookupValuesTitleTxt: Label 'Test lookup values';
        QualityTestLookupValuesDescriptionTxt: Label 'Set up the allowed outcome values for quality tests using a predefined custom list.';
        QualityTestLookupValuesKeywordsTxt: Label 'Quality Test, Lookup, Values';

        QualityInspectionResultsShortTitleTxt: Label 'Set up quality inspection results';
        QualityInspectionResultsTitleTxt: Label 'Inspection results';
        QualityInspectionResultsDescriptionTxt: Label 'Set up how inspection results are captured and tracked. Review completed quality inspections to see test results, pass or fail outcomes, and recorded measurements.';
        QualityInspectionResultsKeywordsTxt: Label 'Quality Inspection, Results, Grades, Outcomes';

        QualityInspectionGenerationRulesShortTitleTxt: Label 'Set up quality inspection generation rules';
        QualityInspectionGenerationRulesTitleTxt: Label 'Inspection generation rules';
        QualityInspectionGenerationRulesDescriptionTxt: Label 'Set up inspection generation rules to define when quality inspections are created automatically, such as during receiving, production, or assembly.';
        QualityInspectionGenerationRulesKeywordsTxt: Label 'Quality Inspection, Generation, Creation, Rules';

        QualityInspectionTemplatesShortTitleTxt: Label 'Set up quality inspection templates';
        QualityInspectionTemplatesTitleTxt: Label 'Inspection templates';
        QualityInspectionTemplatesDescriptionTxt: Label 'Set up templates you can group and reuse quality tests so you can apply consistent inspection standards across items, processes, or scenarios. From the list you can create a new template card to understand its structure and purpose.';
        QualityInspectionTemplatesKeywordsTxt: Label 'Quality Inspection, Templates, Procedures';

        QualityManagementSetupTitleTxt: Label 'Set up quality management';
        QualityManagementSetupShortTitleTxt: Label 'Quality management setup';
        QualityManagementSetupDescriptionTxt: Label 'Set up how and when inspections are created. Manage when to show inspections, set up test generation rules, such as for production scenarios or inventory and warehouse inspections.';
        QualityManagementSetupKeywordsTxt: Label 'Quality Management Setup';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterManualSetup', '', false, false)]
    local procedure InsertQualityManagementManualSetupOnRegisterManualSetup(var Sender: Codeunit "Guided Experience")
    var
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        Sender.InsertManualSetup(QualityTestsShortTitleTxt,
            QualityTestsTitleTxt,
            QualityTestsDescriptionTxt,
            10,
            ObjectType::Page,
            Page::"Qlty. Tests",
            ManualSetupCategory::"Quality Management",
            QualityTestsKeywordsTxt);

        Sender.InsertManualSetup(QualityTestLookupValuesShortTitleTxt,
            QualityTestLookupValuesTitleTxt,
            QualityTestLookupValuesDescriptionTxt,
            10,
            ObjectType::Page,
            Page::"Qlty. Test Lookup Values",
            ManualSetupCategory::"Quality Management",
            QualityTestLookupValuesKeywordsTxt);

        Sender.InsertManualSetup(QualityInspectionResultsShortTitleTxt,
            QualityInspectionResultsTitleTxt,
            QualityInspectionResultsDescriptionTxt,
            10,
            ObjectType::Page,
            Page::"Qlty. Inspection Result List",
            ManualSetupCategory::"Quality Management",
            QualityInspectionResultsKeywordsTxt);

        Sender.InsertManualSetup(QualityInspectionGenerationRulesShortTitleTxt,
            QualityInspectionGenerationRulesTitleTxt,
            QualityInspectionGenerationRulesDescriptionTxt,
            10,
            ObjectType::Page,
            Page::"Qlty. Inspection Gen. Rules",
            ManualSetupCategory::"Quality Management",
            QualityInspectionGenerationRulesKeywordsTxt);

        Sender.InsertManualSetup(QualityInspectionTemplatesShortTitleTxt,
            QualityInspectionTemplatesTitleTxt,
            QualityInspectionTemplatesDescriptionTxt,
            10,
            ObjectType::Page,
            Page::"Qlty. Inspection Template List",
            ManualSetupCategory::"Quality Management",
            QualityInspectionTemplatesKeywordsTxt);

        Sender.InsertManualSetup(QualityManagementSetupTitleTxt,
            QualityManagementSetupShortTitleTxt,
            QualityManagementSetupDescriptionTxt,
            10,
            ObjectType::Page,
            Page::"Qlty. Management Setup",
            ManualSetupCategory::"Quality Management",
            QualityManagementSetupKeywordsTxt,
            true);
    end;
}
