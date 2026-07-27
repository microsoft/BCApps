// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.Foundation.Attachment;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Telemetry;

/// <summary>
/// A Quality Inspection Template is an inspection plan containing a set of questions and data points that you want to collect.
/// </summary>
page 20404 "Qlty. Inspection Template List"
{
    Caption = 'Quality Inspection Templates';
    CardPageId = "Qlty. Inspection Template";
    DeleteAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "Qlty. Inspection Template Hdr.";
    AccessByPermission = tabledata "Qlty. Inspection Template Hdr." = R;
    UsageCategory = Lists;
    ApplicationArea = QualityManagement;
    AdditionalSearchTerms = 'Standard operating procedures';
    AboutTitle = 'About Quality Inspection Templates';
    AboutText = 'Quality Inspection Templates are inspection plans containing a set of tests that represent questions and data points that you want to collect.';

    layout
    {
        area(Content)
        {
            repeater(GroupAllTemplates)
            {
                ShowCaption = false;

                field("Code"; Rec.Code)
                {
                }
                field(Description; Rec.Description)
                {
                }
            }
        }
        area(FactBoxes)
        {
            part("Attached Documents"; "Doc. Attachment List Factbox")
            {
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"Qlty. Inspection Template Hdr."),
                              "No." = field("Code");
            }
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(RecordNotes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateInspection)
            {
                Scope = Repeater;
                AccessByPermission = tabledata "Qlty. Inspection Header" = I;
                Caption = 'Create Inspection';
                ToolTip = 'Create a new quality inspection from this template.';
                AboutTitle = 'More ways to create inspections';
                AboutText = 'Use this action to create a manual inspection from the selected template. You can also create inspections directly from other pages, such as output journals, production order routing lines, consumption journals, purchase orders, sales returns, and item tracking lines.';
                Image = BulletList;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;

                trigger OnAction()
                var
                    QltyCreateInspection: Report "Qlty. Create Inspection";
                begin
                    QltyCreateInspection.InitializeReportParameters(Rec.Code);
                    QltyCreateInspection.RunModal();
                end;
            }
            action(CopyTemplate)
            {
                Image = Copy;
                Caption = 'Copy Template';
                ToolTip = 'Copy an existing template.';
                AboutTitle = 'Copy inspection templates';
                AboutText = 'Copy an existing template and adjust it to your needs. This helps you define what to inspect and how, while keeping inspections consistent across documents.';
                Promoted = true;
                PromotedCategory = Process;
                Scope = Repeater;

                trigger OnAction()
                var
                    ExistingQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
                begin
                    ExistingQltyInspectionTemplateHdr := Rec;
                    ExistingQltyInspectionTemplateHdr.SetRecFilter();
                    Report.Run(Report::"Qlty. Inspection Copy Template", true, true, ExistingQltyInspectionTemplateHdr);
                end;
            }
        }
        area(Navigation)
        {
            action(ViewGenerationRules)
            {
                Scope = Repeater;
                Caption = 'Inspection Generation Rules';
                ToolTip = 'View existing quality inspection generation rules related to this template. Quality inspection generation rules specify when quality inspections are automatically generated and which template is used, such as during receiving, production, or warehouse activities. You link a template to a source table and define filter criteria that determine when an inspection is created. When the criteria are met, the system generates a quality inspection based on the linked template. If multiple rules match, the system uses the first rule according to the sort order.';
                Image = CopyFromTask;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Qlty. Inspection Gen. Rules";
                RunPageLink = "Template Code" = field(Code);
                RunPageMode = Edit;
            }
            action(ExistingInspection)
            {
                Scope = Repeater;
                Caption = 'Existing Inspections';
                ToolTip = 'Review existing quality inspections created using this template.';
                Image = CheckList;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Qlty. Inspection List";
                RunPageLink = "Template Code" = field(Code);
                RunPageMode = View;
            }
        }
    }

    trigger OnOpenPage()
    var
        QltyMgmtFeatureTelemetry: Codeunit "Qlty. Mgmt. Feature Telemetry";
    begin
        QltyMgmtFeatureTelemetry.LogFeatureUptakeDiscovered(ObjectType::Page, Page::"Qlty. Inspection Template List");
    end;
}
