// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

page 149040 "AIT Test Suite List"
{
    Caption = 'AI Test Suites';
    PageType = List;
    SourceTable = "AIT Test Suite";
    CardPageId = "AIT Test Suite";
    Editable = false;
    RefreshOnActivate = true;
    UsageCategory = Lists;
    Extensible = true;
    AdditionalSearchTerms = 'AIT, AI Test Tool, Test Tool, AI Test Suite, Test Suite, Copilot, Copilot Test';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Code"; Rec."Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Started; Rec."Started at")
                {
                }
                field(Status; Rec.Status)
                {
                }

            }
        }
    }
    actions
    {
        area(Processing)
        {
            group("Import/Export")
            {
                Caption = 'Import/Export';
                action(ImportAIT)
                {
                    Caption = 'Import';
                    Image = Import;
                    ToolTip = 'Import the AI Test Suite configuration.';

                    trigger OnAction()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                    begin
                        XmlPort.Run(XmlPort::"AIT Test Suite Import/Export", false, true, AITTestSuite);
                        CurrPage.Update(false);
                    end;
                }
                action(ExportAIT)
                {
                    Caption = 'Export';
                    Image = Export;
                    Enabled = ValidRecord;
                    Scope = Repeater;
                    ToolTip = 'Exports the AI Test Suite configuration.';

                    trigger OnAction()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
                    begin
                        CurrPage.SetSelectionFilter(AITTestSuite);
                        if AITTestSuite.FindFirst() then
                            AITTestSuiteMgt.ExportAITTestSuite(AITTestSuite);
                    end;
                }
            }
        }
        area(Navigation)
        {
            action(Datasets)
            {
                Caption = 'Input Datasets';
                Image = DataEntry;
                ToolTip = 'Open input datasets.';
                RunObject = page "Test Input Groups";
            }
        }
        area(Promoted)
        {
            actionref(Datasets_Promoted; Datasets)
            {
            }
            group(Category_Category4)
            {
                Caption = 'Import/Export';

                actionref(ImportAIT_Promoted; ImportAIT)
                {
                }
                actionref(ExportAIT_Promoted; ExportAIT)
                {
                }
            }
        }
    }

    var
        ValidRecord: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        ValidRecord := Rec.Code <> '';
    end;
}