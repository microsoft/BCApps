// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.RoleCenters;

using Microsoft.Finance.RoleCenters;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Reports;
using Microsoft.QualityManagement.Setup.Setup;

pageextension 20404 "Qlty. Business Manager RC" extends "Business Manager Role Center"
{
    actions
    {
        addlast(processing)
        {
            group(Qlty_Processing)
            {
                Image = TaskQualityMeasure;
                Caption = 'Quality Management';
                ToolTip = 'Create Quality Inspections.';

                action(Qlty_ShowInspections)
                {
                    Caption = 'Quality Inspections';
                    Image = TaskQualityMeasure;
                    ToolTip = 'See existing Quality Inspections and create a new inspection.';
                    ApplicationArea = QualityManagement;
                    RunObject = Page "Qlty. Inspection List";
                }
                action(Qlty_CertificateOfAnalysis)
                {
                    Caption = 'Certificate of Analysis';
                    Image = Certificate;
                    ToolTip = 'Certificate of Analysis (CoA) report.';
                    ApplicationArea = QualityManagement;
                    RunObject = Report "Qlty. Certificate of Analysis";
                }
                group(Qlty_Analysis_Group)
                {
                    Caption = 'Analysis';
                    Tooltip = 'Analyze Quality Inspection data';

                    action(Qlty_InspectionLines)
                    {
                        Caption = 'Quality Inspection Lines';
                        Image = AnalysisView;
                        ToolTip = 'Historical Quality Inspection lines. Use this with analysis mode.';
                        ApplicationArea = QualityManagement;
                        RunObject = Page "Qlty. Inspection Lines";
                    }
                }
                group(Qlty_SemiRegularSetup)
                {
                    Caption = 'Templates and Rules';
                    Tooltip = 'Configure the Quality Inspection Templates and Rules';

                    action(Qlty_ConfigureInspectionTemplates)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Test Inspections';
                        Image = Database;
                        RunObject = Page "Qlty. Inspection Template List";
                        RunPageMode = Edit;
                        ToolTip = 'Specifies a Quality Inspection Template is an inspection plan containing a set of questions and data points that you want to collect.';
                    }
                    action(Qlty_ConfigureInspectionGenerationRules)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Inspection Generation Rules';
                        Image = MapDimensions;
                        RunObject = Page "Qlty. Inspection Gen. Rules";
                        RunPageMode = Edit;
                        ToolTip = 'Specifies a Quality Inspection generation rule defines when you want to ask a set of questions or other data that you want to collect that is defined in a template. You connect a template to a source table, and set the criteria to use that template with the table filter. When these filter criteria is met, then it will choose that template. When there are multiple matches, it will use the first template that it finds, based on the sort order.';
                    }
                    action(Qlty_ConfigureTests)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Tests';
                        Image = MapDimensions;
                        RunObject = Page "Qlty. Tests";
                        RunPageMode = Edit;
                        ToolTip = 'Specifies a quality inspection test is a data points to capture, or questions, or measurements.';
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
                        ApplicationArea = QualityManagement;
                        Image = Setup;
                        RunPageMode = Edit;
                    }
                }
            }
        }
        addlast(sections)
        {
            group(Qlty_Sections_Group)
            {
                Caption = 'Quality Management';

                action(Qlty_Sections_ShowInspections)
                {
                    Caption = 'Quality Inspections';
                    Image = TaskQualityMeasure;
                    ToolTip = 'See existing Quality Inspections and create a new inspection.';
                    ApplicationArea = QualityManagement;
                    RunObject = Page "Qlty. Inspection List";
                }
                action(Qlty_Sections_InspectionLines)
                {
                    Caption = 'Quality Inspection Lines';
                    Image = AnalysisView;
                    ToolTip = 'Historical Quality Inspection lines. Use this with analysis mode.';
                    ApplicationArea = QualityManagement;
                    RunObject = Page "Qlty. Inspection Lines";
                }
            }
        }
    }
}
