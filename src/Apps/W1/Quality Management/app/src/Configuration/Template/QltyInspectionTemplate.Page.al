// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Template;

using Microsoft.Foundation.Attachment;
using Microsoft.QualityManagement.AccessControl;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;
using System.Telemetry;

/// <summary>
/// A Quality Inspection Template is a test plan containing a set of questions and data points that you want to collect.
/// </summary>
page 20402 "Qlty. Inspection Template"
{
    UsageCategory = None;
    Caption = 'Quality Inspection Template';
    DataCaptionExpression = GetDataCaptionExpression();
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Qlty. Inspection Template Hdr.";
    AdditionalSearchTerms = 'Test Plan,Quality Inspection,design an inspection,quality inspection template,questions,types of tests,template,quality inspector template,quality template,certificate design,SOP,standard operating procedures';
    AboutTitle = 'Quality Inspection Template';
    AboutText = 'A Quality Inspection Template is a test plan containing a set of questions and data points that you want to collect.';
    PromotedActionCategories = 'New,Process,Report';
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Code"; Rec.Code)
                {
                    ToolTip = 'Specifies the code to identify the Quality Inspection Template.';

                    trigger OnValidate()
                    begin
                        if xRec.Code = '' then
                            CurrPage.Update(true)
                        else
                            CurrPage.Update(false);
                    end;
                }
                field(Description; Rec.Description)
                {
                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Sample Source"; Rec."Sample Source")
                {
                    ShowCaption = true;
                    AboutTitle = 'Sample Source';
                    AboutText = 'Sample Source determines how the Sample Size initially gets set. Values are rounded up to the nearest whole number.';

                    trigger OnValidate()
                    begin
                        UpdateControls();
                    end;
                }
                group(SettingsForSampleFixedAmountVisibilityWrapper)
                {
                    ShowCaption = false;
                    Caption = '';
                    Visible = ShowSampleSizeFixedQuantity;

                    field("Sample Fixed Amount"; Rec."Sample Fixed Amount")
                    {
                        ShowCaption = true;
                        AboutTitle = 'Sample Fixed Amount';
                        AboutText = 'When Sample Source is set to a fixed quantity then this represents a discrete fixed sample size. Samples can only be discrete units. If the quantity here exceeds the Source Quantity then the Source Quantity will be used instead.';
                    }
                }
                group(SettingsForSamplePercentVisibilityWrapper)
                {
                    ShowCaption = false;
                    Caption = '';
                    Visible = ShowSampleSizePercentage;

                    field("Sample Percentage"; Rec."Sample Percentage")
                    {
                        ShowCaption = true;
                        AboutTitle = 'Sample Percentage';
                        AboutText = 'When Sample Source is set to a percentage then this represents the percent of the source quantity to use. Values will be rounded to the highest discrete amount.';
                    }
                }
            }
            part(LinesPart; "Qlty. Inspection Template Subf")
            {
                Caption = 'Lines';
                SubPageLink = "Template Code" = field(Code);
                SubPageView = sorting("Template Code", "Line No.");
            }
        }
        area(FactBoxes)
        {
            part("Attached Documents"; "Doc. Attachment List Factbox")
            {
                Caption = 'Template Attachments';
                SubPageLink = "Table ID" = const(Database::"Qlty. Inspection Template Hdr."),
                              "No." = field("Code");
            }
            part("Attached Documents List"; "Doc. Attachment List Factbox")
            {
                Visible = false;
                Caption = 'Specification Attachments';
                Provider = LinesPart;
                SubPageLink = "Table ID" = const(Database::"Qlty. Inspection Template Line"),
                              "No." = field("Template Code"),
                              "Line No." = field("Line No.");
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
            action(tNewField)
            {
                Image = Default;
                Caption = 'Add Field(s) To This Template';
                ToolTip = 'Add a new Field or existing Field(s) to this template';
                Scope = Repeater;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                AboutTitle = 'Add field(s)';
                AboutText = 'Add a new field or add existing fields to this template.';

                trigger OnAction()
                begin
                    CurrPage.LinesPart.Page.AddFieldWizard();
                end;
            }
            action(ViewRules)
            {
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
                PromotedOnly = true;
            }
            action(CreateTest)
            {
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
                    QltyCreateInspectionTest.initializeReportParameters(Rec.Code);
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
                PromotedIsBig = true;

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
    }

    var
        QltyPermissionMgmt: Codeunit "Qlty. Permission Mgmt.";
        CanCreateTest: Boolean;
        ShowSampleSizeFixedQuantity: Boolean;
        ShowSampleSizePercentage: Boolean;
        QualityManagementTok: Label 'Quality Management', Locked = true;

    local procedure GetDataCaptionExpression(): Text
    begin
        exit(Rec.Code + ' - ' + Rec.Description);
    end;

    trigger OnAfterGetRecord()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000QIA', QualityManagementTok, Enum::"Feature Uptake Status"::Used);
        CanCreateTest := QltyPermissionMgmt.CanCreateManualTest();
        UpdateControls();
    end;

    local procedure UpdateControls()
    begin
        ShowSampleSizeFixedQuantity := Rec."Sample Source" = Rec."Sample Source"::"Fixed Quantity";
        ShowSampleSizePercentage := Rec."Sample Source" = Rec."Sample Source"::"Percent of Quantity";
    end;
}
