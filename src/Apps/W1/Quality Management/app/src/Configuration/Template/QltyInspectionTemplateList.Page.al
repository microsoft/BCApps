﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.Foundation.Attachment;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;

/// <summary>
/// A Quality Inspection Template is a test plan containing a set of questions and data points that you want to collect.
/// </summary>
page 20404 "Qlty. Inspection Template List"
{
    Caption = 'Quality Inspection Templates';
    CardPageID = "Qlty. Inspection Template";
    DeleteAllowed = false;
    Editable = false;
    PageType = List;
    SourceTable = "Qlty. Inspection Template Hdr.";
    UsageCategory = Lists;
    ApplicationArea = QualityManagement;
    AdditionalSearchTerms = 'Quality Test Template,Template,Quality Template,Quality Inspection,questions,types of tests,templates,quality inspector template,quality template,certificate design,SOP,standard operating procedures';
    AboutTitle = 'Quality Inspection Template';
    AboutText = 'A Quality Inspection Template is a test plan containing a set of questions and data points that you want to collect.';

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
            action(ViewGenerationRules)
            {
                Scope = Repeater;
                Caption = 'Test Generation Rules';
                ToolTip = 'View existing Quality Inspection Test Generation Rules related to this template. A Quality Inspection Test generation rule defines when you want to ask a set of questions defined in a template. You connect a template to a source table, and set the criteria to use that template with the table filter. When these filter criteria is met, then it will choose that template.';
                AboutTitle = 'Test Generation Rules';
                AboutText = 'View existing Quality Inspection Test Generation Rules related to this template. A Quality Inspection Test generation rule defines when you want to ask a set of questions defined in a template. You connect a template to a source table, and set the criteria to use that template with the table filter. When these filter criteria is met, then it will choose that template.';
                Image = TaskList;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                RunObject = Page "Qlty. In. Test Generat. Rules";
                RunPageLink = "Template Code" = field(Code);
                RunPageMode = Edit;
            }
            action(CreateTest)
            {
                Scope = Repeater;
                Caption = 'Create Test';
                ToolTip = 'Specifies to create a new Quality Inspection Test using this template.';
                Image = CreateForm;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                Enabled = CanCreateTest;

                trigger OnAction()
                var
                    QltyCreateInspectionTest: Report "Qlty. Create Inspection Test";
                begin
                    QltyCreateInspectionTest.InitializeReportParameters(Rec.Code);
                    QltyCreateInspectionTest.RunModal();
                end;
            }
            action(CopyTemplate)
            {
                Image = Copy;
                Caption = 'Copy Template';
                ToolTip = 'Copy an existing template.';
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
            action(ExistingTests)
            {
                Scope = Repeater;
                Caption = 'Existing Tests';
                ToolTip = 'Review existing tests created using this template.';
                Image = Report;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                RunObject = Page "Qlty. Inspection Test List";
                RunPageLink = "Template Code" = field(Code);
                RunPageMode = View;
            }
        }
        area(Reporting)
        {
        }
    }

    var
        CanCreateTest: Boolean;

    trigger OnOpenPage()
    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
    begin
        CanCreateTest := QltyPermissionMgmt.CanCreateManualTest();
    end;
}
