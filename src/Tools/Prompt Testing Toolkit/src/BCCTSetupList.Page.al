// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149040 "BCCT Setup List"
{
    Caption = 'BCCT Suites';
    PageType = List;
    PromotedActionCategories = 'New,Process,Report,Import/Export';
    SourceTable = "BCCT Header";
    CardPageId = "BCCT Setup Card";
    Editable = false;
    RefreshOnActivate = true;
    UsageCategory = Lists;
    Extensible = true;
    AdditionalSearchTerms = 'AITT';
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
                    ToolTip = 'Specifies the ID of the BCCT.';
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the BCCT.';
                    ApplicationArea = All;
                }
                field(Started; Rec."Started at")
                {
                    Caption = 'Started at';
                    ToolTip = 'Specifies when the BCCT was started.';
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the BCCT.';
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
                action(ImportBCCT)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Import';
                    Image = Import;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedIsBig = false;
                    PromotedOnly = true;
                    ToolTip = 'Import a file with BCCT Suite details.';

                    trigger OnAction()
                    var
                        BCCTHeader: Record "BCCT Header";
                    begin
                        XMLPORT.Run(XMLPORT::"BCCT Import/Export", false, true, BCCTHeader);
                        CurrPage.Update(false);
                    end;
                }
                action(ExportBCCT)
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
                    ToolTip = 'Exports a file with BCCT Suite details.';

                    trigger OnAction()
                    var
                        BCCTHeader: Record "BCCT Header";
                    begin
                        CurrPage.SetSelectionFilter(BCCTHeader);
                        XMLPORT.Run(XMLPORT::"BCCT Import/Export", false, false, BCCTHeader);
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