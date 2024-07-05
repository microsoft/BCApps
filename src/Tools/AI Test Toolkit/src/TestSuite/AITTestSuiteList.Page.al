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
    AdditionalSearchTerms = 'AIT, AI Test Suite, Test Suite, Copilot, Copilot Test';
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Code"; Rec."Code")
                {
                    Caption = 'Code';
                    ToolTip = 'Specifies the ID of the AIT.';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the AIT.';
                }
                field(Started; Rec."Started at")
                {
                    Caption = 'Started at';
                    ToolTip = 'Specifies when the AIT was started.';
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the AIT.';
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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import';
                    Image = Import;
                    ToolTip = 'Import a file with AIT Suite details.';

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
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Image = Export;
                    Enabled = this.ValidRecord;
                    Scope = Repeater;
                    ToolTip = 'Exports a file with AIT Suite details.';

                    trigger OnAction()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                    begin
                        CurrPage.SetSelectionFilter(AITTestSuite);
                        XmlPort.Run(XmlPort::"AIT Test Suite Import/Export", false, false, AITTestSuite);
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Navigation)
        {
            action(Datasets)
            {
                ApplicationArea = All;
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
        this.ValidRecord := Rec.Code <> '';
    end;
}