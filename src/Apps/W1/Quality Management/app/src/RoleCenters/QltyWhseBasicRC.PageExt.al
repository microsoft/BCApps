// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.RoleCenters;

using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Reports;
using Microsoft.QualityManagement.Setup;
using Microsoft.Warehouse.RoleCenters;

pageextension 20421 "Qlty. Whse. Basic RC" extends "Whse. Basic Role Center"
{
    actions
    {
        addlast(processing)
        {
            group(Qlty_QualityManagement_Processing_Group)
            {
                Image = CheckList;
                Caption = 'Quality Management';
                ToolTip = 'Work with quality inspections.';

                action(Qlty_ShowQualityInspections)
                {
                    Caption = 'Quality Inspections';
                    Image = CheckList;
                    ToolTip = 'See existing quality inspections and create a new inspection.';
                    ApplicationArea = QualityManagement;
                    RunObject = Page "Qlty. Inspection List";
                }
                action(Qlty_CertificateOfAnalysis)
                {
                    Caption = 'Certificate of Analysis';
                    Image = Certificate;
                    ToolTip = 'Print a certificate of analysis (CoA) report.';
                    ApplicationArea = QualityManagement;
                    RunObject = Report "Qlty. Certificate of Analysis";
                }
                group(Qlty_Analysis_Group)
                {
                    Caption = 'Analysis';
                    ToolTip = 'Analyze quality inspection data';

                    action(Qlty_QualityInspectionLines)
                    {
                        Caption = 'Quality Inspection Lines';
                        Image = CheckList;
                        ToolTip = 'Historical quality inspection lines. Use this with analysis mode.';
                        ApplicationArea = QualityManagement;
                        RunObject = Page "Qlty. Inspection Lines";
                    }
                }
                group(Qlty_ConfigureQualityManagement)
                {
                    Caption = 'Setup';
                    Tooltip = 'Configure the Quality Management';
                    Image = Setup;

                    action(Qlty_ManagementSetup)
                    {
                        Caption = 'Quality Management Setup';
                        RunObject = Page "Qlty. Management Setup";
                        ApplicationArea = QualityManagement;
                        Image = Setup;
                        RunPageMode = Edit;
                        Tooltip = 'Change the behavior of the Quality Management.';
                    }
                    action(Qlty_ConfigureInspectionTemplates)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Inspection Templates';
                        Image = BreakpointsList;
                        RunObject = Page "Qlty. Inspection Template List";
                        RunPageMode = Edit;
                        ToolTip = 'Quality inspection templates are inspection plans that contain a set of tests to perform.';
                    }
                    action(Qlty_ConfigureInspectionGenerationRules)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Inspection Generation Rules';
                        Image = CopyFromTask;
                        RunObject = Page "Qlty. Inspection Gen. Rules";
                        RunPageMode = Edit;
                        ToolTip = 'Quality inspection generation rules specify when quality inspections are automatically generated and which template is used, such as during receiving, production, or warehouse activities. You link a template to a source table and define filter criteria that determine when an inspection is created. When the criteria are met, the system generates a quality inspection based on the linked template. If multiple rules match, the system uses the first rule according to the sort order.';
                    }
                    action(Qlty_ConfigureTests)
                    {
                        ApplicationArea = QualityManagement;
                        Caption = 'Tests';
                        Image = TaskQualityMeasure;
                        RunObject = Page "Qlty. Tests";
                        RunPageMode = Edit;
                        ToolTip = 'Quality tests are defined data points, checks, questions or measurements used to evaluate quality.';
                    }
                }
            }
        }
        addlast(sections)
        {
            group(Qlty_QualityManagement_Sections_Group)
            {
                Caption = 'Quality Inspection';

                action(Qlty_Sections_ShowQualityInspections)
                {
                    Caption = 'Quality Inspections';
                    Image = CheckList;
                    ToolTip = 'See existing quality inspections and create a new inspection.';
                    ApplicationArea = QualityManagement;
                    RunObject = Page "Qlty. Inspection List";
                }
                action(Qlty_Sections_QualityInspectionLines)
                {
                    Caption = 'Quality Inspection Lines';
                    Image = CheckList;
                    ToolTip = 'Historical quality inspection lines. Use this with analysis mode.';
                    ApplicationArea = QualityManagement;
                    RunObject = Page "Qlty. Inspection Lines";
                }
            }
        }
    }
}
