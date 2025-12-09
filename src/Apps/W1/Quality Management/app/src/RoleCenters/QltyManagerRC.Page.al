// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.RoleCenters;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Grade;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Reports;
using Microsoft.QualityManagement.Setup.Setup;

page 20421 "Qlty. Manager RC"
{
    Caption = 'Quality Manager Role Center';
    PageType = RoleCenter;
    ApplicationArea = QualityManagement;

    actions
    {
        area(Sections)
        {
            group(Qlty_GetStarted_Group)
            {
                Caption = 'Quality Inspection';

                action(Qlty_ShowTests)
                {
                    Caption = 'Quality Inspection Tests';
                    Image = TaskQualityMeasure;
                    ToolTip = 'See existing Quality Inspection Tests and create a new test.';
                    RunObject = Page "Qlty. Inspection Test List";
                }
                action(Qlty_CertificateOfAnalysis)
                {
                    Caption = 'Quality Inspection Certificate of Analysis';
                    Image = Certificate;
                    ToolTip = 'Certificate of Analysis (CoA) report.';
                    RunObject = Report "Qlty. Certificate of Analysis";
                }
            }
            group(Qlty_Analysis_Group)
            {
                Caption = 'Analysis';

                action(Qlty_QualityInspectionTestValues)
                {
                    Caption = 'Quality Inspection Test Values';
                    Image = AnalysisView;
                    ToolTip = 'Historical Quality Inspection Test values. Use this with analysis mode.';
                    RunObject = Page "Qlty. Inspection Test Lines";
                }
            }
            group(Qlty_SemiRegularSetup)
            {
                Caption = 'Templates and Rules';

                action(Qlty_ConfigureTestTemplates)
                {
                    Caption = 'Quality Inspection Templates';
                    Image = Database;
                    RunObject = Page "Qlty. Inspection Template List";
                    RunPageMode = Edit;
                    ToolTip = 'Specifies a Quality Inspection Template is a test plan containing a set of questions and data points that you want to collect.';
                }
                action(Qlty_ConfigureTestGenerationRules)
                {
                    Caption = 'Quality Inspection Test Generation Rules';
                    Image = MapDimensions;
                    RunObject = Page "Qlty. In. Test Generat. Rules";
                    RunPageMode = Edit;
                    ToolTip = 'Specifies a Quality Inspection Test generation rule defines when you want to ask a set of questions or other data that you want to collect that is defined in a template. You connect a template to a source table, and set the criteria to use that template with the table filter. When these filter criteria is met, then it will choose that template. When there are multiple matches, it will use the first template that it finds, based on the sort order.';
                }
                action(Qlty_ConfigureFields)
                {
                    Caption = 'Quality Inspection Fields';
                    Image = MapDimensions;
                    RunObject = Page "Qlty. Fields";
                    RunPageMode = Edit;
                    ToolTip = 'Specifies a quality inspection field is a data points to capture, or questions, or measurements.';
                }
            }
            group(Qlty_ManagementConfigure)
            {
                Caption = 'Setup';
                Tooltip = 'Configure the Quality Management';
                Image = Setup;

                action(Qlty_ManagementSetup)
                {
                    Caption = 'Quality Management Setup';
                    Tooltip = 'Change the behavior of the Quality Management.';
                    RunObject = Page "Qlty. Management Setup";
                    Image = Setup;
                    RunPageMode = Edit;
                }
                group(Qlty_Advanced)
                {
                    Caption = 'Advanced Quality Management Configuration';

                    action(Qlty_AdvancedGrades)
                    {
                        Caption = 'Quality Inspection Grades';
                        Image = CodesList;
                        RunObject = Page "Qlty. Inspection Grade List";
                        RunPageMode = Edit;
                        ToolTip = 'Grades are effectively the incomplete/pass/fail state of a test. The document specific lot blocking available with grades is for item+variant+lot+serial+package combinations, and can be used for serial-only tracking, or package-only tracking.';
                    }
                }
            }
        }
    }
}
