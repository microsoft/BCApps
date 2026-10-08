// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.Result;

/// <summary>
/// Card page for Quality Inspection Result.
/// </summary>
page 20417 "Qlty. Inspection Result Card"
{
    Caption = 'Quality Inspection Result';
    AboutTitle = 'About Inspection Result details';
    AboutText = 'Inspection result shows the outcome of an inspection, such as *In progress, Fail*, or *Pass*. Use this page to set up custom grades to match your process.';
    SourceTable = "Qlty. Inspection Result";
    PageType = Card;
    ApplicationArea = QualityManagement;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Code; Rec.Code)
                {
                    ShowMandatory = true;
                }
                field(Description; Rec.Description)
                {
                    ShowMandatory = true;
                }
                field("Evaluation Sequence"; Rec."Evaluation Sequence")
                {
                    AboutTitle = 'Evaluation Sequence';
                    AboutText = 'The evaluation sequence sets the priority order for checking results. Inspection results with lower numbers are checked first, so *Fail* or *In progress* conditions are usually prioritized before *Pass*.';

                    trigger OnValidate()
                    begin
                        Rec.ValidateEvaluationSequenceNotUsedElsewhere();
                    end;
                }
                field("Copy Behavior"; Rec."Copy Behavior")
                {
                }
                field("Result Visibility"; Rec."Result Visibility")
                {
                    AboutTitle = 'Result Visibility';
                    AboutText = '*Promote* important results, typically pass conditions, so they will show on pages and reports, such as Quality Tests, Quality Inspections and Certificate of Analysis.';
                }
                field("Result Category"; Rec."Result Category")
                {
                }
                field("Finish Allowed"; Rec."Finish Allowed")
                {
                }
            }
            group("Default Conditions")
            {
                Caption = 'Default Conditions';

                field("Default Number Condition"; Rec."Default Number Condition")
                {
                }
                field("Default Text Condition"; Rec."Default Text Condition")
                {
                }
                field("Default Boolean Condition"; Rec."Default Boolean Condition")
                {
                }
            }
            group("Item Tracking Restrictions")
            {
                Caption = 'Item Tracking Restrictions';
                AboutTitle = 'Allow or block specific transactions';
                AboutText = 'For items with lot, serial, or package tracking, you can specify how quality inspection results affect specific document transactions. For example, you can block purchase documents while inspections are in progress and block sales documents for failed inspections.';

                group(Basic)
                {
                    Caption = 'Basic';
                    ShowCaption = true;

                    field("Item Tracking Allow Sales"; Rec."Item Tracking Allow Sales")
                    {
                        Caption = 'Sales';
                    }
                    field("Item Tracking Allow Purchase"; Rec."Item Tracking Allow Purchase")
                    {
                        Caption = 'Purchase';
                    }
                    field("Item Tracking Allow Transfer"; Rec."Item Tracking Allow Transfer")
                    {
                        Caption = 'Transfer';
                    }
                }
                group(Manufacturing)
                {
                    Caption = 'Manufacturing';
                    ShowCaption = true;

                    field("Item Tracking Allow Consump."; Rec."Item Tracking Allow Consump.")
                    {
                        Caption = 'Consumption';
                        ApplicationArea = Manufacturing;
                    }
                    field("Item Tracking Allow Output"; Rec."Item Tracking Allow Output")
                    {
                        Caption = 'Output';
                        ApplicationArea = Manufacturing;
                    }
                }
                group(Assembly)
                {
                    Caption = 'Assembly';
                    ShowCaption = true;

                    field("Item Tracking Allow Asm. Cons."; Rec."Item Tracking Allow Asm. Cons.")
                    {
                        Caption = 'Assembly Consumption';
                        ApplicationArea = Assembly;
                    }
                    field("Item Tracking Allow Asm. Out."; Rec."Item Tracking Allow Asm. Out.")
                    {
                        Caption = 'Assembly Output';
                        ApplicationArea = Assembly;
                    }
                }
                group(Warehouse)
                {
                    Caption = 'Warehouse';
                    ShowCaption = true;

                    field("Item Tracking Allow Invt. Mov."; Rec."Item Tracking Allow Invt. Mov.")
                    {
                        Caption = 'Inventory Movement';
                    }
                    field("Item Tracking Allow Invt. Pick"; Rec."Item Tracking Allow Invt. Pick")
                    {
                        Caption = 'Inventory Pick';
                    }
                    field("Item Tracking Allow Invt. PA"; Rec."Item Tracking Allow Invt. PA")
                    {
                        Caption = 'Inventory Put-Away';
                    }
                    field("Item Tracking Allow Movement"; Rec."Item Tracking Allow Movement")
                    {
                        Caption = 'Movement';
                    }
                    field("Item Tracking Allow Pick"; Rec."Item Tracking Allow Pick")
                    {
                        Caption = 'Pick';
                    }
                    field("Item Tracking Allow Put-Away"; Rec."Item Tracking Allow Put-Away")
                    {
                        Caption = 'Put-Away';
                    }
                }
            }
            group(Appearance)
            {
                Caption = 'Appearance';

                field("Override Style"; Rec."Override Style")
                {
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.AssistEditResultStyle();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CopyResultsToAllTemplates)
            {
                ApplicationArea = QualityManagement;
                Caption = 'Update Tests, Templates, and Inspections';
                ToolTip = 'Adds newly created results to existing quality tests and templates, adjusts evaluation sequences, and updates promoted results. Inspections based on these templates are also updated.';
                Image = CopyToTask;

                trigger OnAction()
                begin
                    Rec.UpdateTestsTemplatesAndInspections();
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetDefaultEvaluationSequence();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.ValidateEvaluationSequenceNotUsedElsewhere();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec.ValidateEvaluationSequenceNotUsedElsewhere();
    end;
}
