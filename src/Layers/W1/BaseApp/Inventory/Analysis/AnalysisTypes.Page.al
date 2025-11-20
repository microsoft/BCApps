// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 7110 "Analysis Types"
{
    ApplicationArea = SalesAnalysis, PurchaseAnalysis, InventoryAnalysis;
    Caption = 'Analysis Types';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "Analysis Type";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the code of the analysis type.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a description of the analysis type.';
                }
                field("Value Type"; Rec."Value Type")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies the value type that the analysis type is based on.';
                }
                field("Item Ledger Entry Type Filter"; Rec."Item Ledger Entry Type Filter")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a filter on the type of item ledger entry.';
                }
                field("Value Entry Type Filter"; Rec."Value Entry Type Filter")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    ToolTip = 'Specifies a filter on the type of item value entry.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("&Reset Default Analysis Types")
            {
                ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                Caption = '&Reset Default Analysis Types';
                Image = ResetStatus;
                ToolTip = 'Revert to use the default analysis types that exist in the system.';

                trigger OnAction()
                begin
                    Rec.ResetDefaultAnalysisTypes(true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Reset Default Analysis Types_Promoted"; "&Reset Default Analysis Types")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ItemLedgerEntryTypeFilterOnFor(Format(Rec."Item Ledger Entry Type Filter"));
        ValueEntryTypeFilterOnFormat(Format(Rec."Value Entry Type Filter"));
    end;

    var
        AnalysisRepMgmt: Codeunit "Analysis Report Management";

    local procedure ItemLedgerEntryTypeFilterOnFor(Text: Text[250])
    begin
        AnalysisRepMgmt.ValidateFilter(Text, DATABASE::"Analysis Type", Rec.FieldNo("Item Ledger Entry Type Filter"), false);
        Rec."Item Ledger Entry Type Filter" := Text;
    end;

    local procedure ValueEntryTypeFilterOnFormat(Text: Text[250])
    begin
        AnalysisRepMgmt.ValidateFilter(Text, DATABASE::"Analysis Type", Rec.FieldNo("Value Entry Type Filter"), false);
        Rec."Value Entry Type Filter" := Text;
    end;
}

