// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 7114 "Analysis Columns"
{
    AutoSplitKey = true;
    Caption = 'Analysis Columns';
    DataCaptionFields = "Analysis Area";
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Analysis Column";

    layout
    {
        area(content)
        {
            field(CurrentColumnName; CurrentColumnName)
            {
                ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                Caption = 'Name';
                ToolTip = 'Specifies the name of the record.';

                trigger OnLookup(var Text: Text): Boolean
                var
                    AnalysisAreaType: Enum "Analysis Area Type";
                begin
                    CurrPage.SaveRecord();
                    AnalysisAreaType := Rec.GetRangeMax("Analysis Area");
                    if AnalysisRepMgmt.LookupAnalysisColumnName(AnalysisAreaType, CurrentColumnName) then begin
                        Text := CurrentColumnName;
                        exit(true);
                    end;
                end;

                trigger OnValidate()
                var
                    AnalysisAreaType: Enum "Analysis Area Type";
                begin
                    AnalysisAreaType := Rec.GetRangeMax("Analysis Area");
                    AnalysisRepMgmt.GetColumnTemplate(AnalysisAreaType.AsInteger(), CurrentColumnName);
                    CurrentColumnNameOnAfterValida();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Column No."; Rec."Column No.")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field("Column Header"; Rec."Column Header")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field("Item Ledger Entry Type Filter"; Rec."Item Ledger Entry Type Filter")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    Visible = false;
                }
                field("Value Entry Type Filter"; Rec."Value Entry Type Filter")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                    Visible = false;
                }
                field(Invoiced; Rec.Invoiced)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field("Column Type"; Rec."Column Type")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field("Ledger Entry Type"; Rec."Ledger Entry Type")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field(Formula; Rec.Formula)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field("Show Opposite Sign"; Rec."Show Opposite Sign")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field("Comparison Date Formula"; Rec."Comparison Date Formula")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field("Analysis Type Code"; Rec."Analysis Type Code")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field("Value Type"; Rec."Value Type")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field(Show; Rec.Show)
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field("Rounding Factor"; Rec."Rounding Factor")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
                }
                field("Comparison Period Formula"; Rec."Comparison Period Formula")
                {
                    ApplicationArea = SalesAnalysis, PurchaseAnalysis;
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
    }

    trigger OnAfterGetRecord()
    begin
        ItemLedgerEntryTypeFilterOnFor(Format(Rec."Item Ledger Entry Type Filter"));
        ValueEntryTypeFilterOnFormat(Format(Rec."Value Entry Type Filter"));
    end;

    trigger OnOpenPage()
    begin
        AnalysisRepMgmt.OpenColumns(CurrentColumnName, Rec);
    end;

    var
        AnalysisRepMgmt: Codeunit "Analysis Report Management";
        CurrentColumnName: Code[10];

    procedure SetCurrentColumnName(ColumnlName: Code[10])
    begin
        CurrentColumnName := ColumnlName;
    end;

    local procedure CurrentColumnNameOnAfterValida()
    var
        AnalysisAreaType: Enum "Analysis Area Type";
    begin
        CurrPage.SaveRecord();
        AnalysisAreaType := Rec.GetRangeMax("Analysis Area");
        AnalysisRepMgmt.SetColumnName(AnalysisAreaType.AsInteger(), CurrentColumnName, Rec);
        CurrPage.Update(false);
    end;

    local procedure ItemLedgerEntryTypeFilterOnFor(Text: Text[1024])
    begin
        Text := Rec."Item Ledger Entry Type Filter";
        AnalysisRepMgmt.ValidateFilter(Text, DATABASE::"Analysis Column", Rec.FieldNo("Item Ledger Entry Type Filter"), false);
    end;

    local procedure ValueEntryTypeFilterOnFormat(Text: Text[1024])
    begin
        Text := Rec."Value Entry Type Filter";
        AnalysisRepMgmt.ValidateFilter(Text, DATABASE::"Analysis Column", Rec.FieldNo("Value Entry Type Filter"), false);
    end;
}

