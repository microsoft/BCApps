// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149040 "AIT Test Suite List"
{
    Caption = 'AI Test Suites';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Import/Export';
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
        area(content)
        {
            repeater(Control1)
            {
                field("Code"; Rec."Code")
                {
                    Caption = 'Code';
                    ToolTip = 'Specifies the ID of the AIT.';
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the AIT.';
                    ApplicationArea = All;
                }
                field(Started; Rec."Started at")
                {
                    Caption = 'Started at';
                    ToolTip = 'Specifies when the AIT was started.';
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the AIT.';
                    ApplicationArea = All;
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
                action(ImportAIT)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = false;
                    PromotedOnly = true;
                    ToolTip = 'Import a file with AIT Suite details.';

                    trigger OnAction()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                    begin
                        XMLPORT.Run(XMLPORT::"AIT Test Suite Import/Export", false, true, AITTestSuite);
                        CurrPage.Update(false);
                    end;
                }
                action(ExportAIT)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export';
                    Image = Export;
                    Enabled = this.ValidRecord;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = false;
                    PromotedOnly = true;
                    Scope = Repeater;
                    ToolTip = 'Exports a file with AIT Suite details.';

                    trigger OnAction()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                    begin
                        CurrPage.SetSelectionFilter(AITTestSuite);
                        XMLPORT.Run(XMLPORT::"AIT Test Suite Import/Export", false, false, AITTestSuite);
                        CurrPage.Update(false);
                    end;
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