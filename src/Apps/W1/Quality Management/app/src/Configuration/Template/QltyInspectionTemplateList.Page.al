// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.Foundation.Attachment;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;

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
                ToolTip = 'Specifies to create a new Quality Inspection using this template.';
                AboutTitle = 'More ways to create inspections';
                AboutText = 'Use this action to create a manual inspection from the selected template. You can also create inspections directly from other pages, such as output journals, production order routing lines, consumption journals, purchase orders, sales returns, and item tracking lines.';
                Image = CreateForm;
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
                ToolTip = 'View existing Quality Inspection Generation Rules related to this template. A Quality Inspection generation rule defines when you want to ask a set of questions defined in a template. You connect a template to a source table, and set the criteria to use that template with the table filter. When these filter criteria is met, then it will choose that template.';
                Image = FilterLines;
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
                ToolTip = 'Review existing inspections created using this template.';
                Image = TaskQualityMeasure;
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
}
