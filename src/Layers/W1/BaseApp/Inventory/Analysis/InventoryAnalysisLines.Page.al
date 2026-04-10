// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;

page 7115 "Inventory Analysis Lines"
{
    AutoSplitKey = true;
    Caption = 'Inventory Analysis Lines';
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = Worksheet;
    SourceTable = "Analysis Line";

    layout
    {
        area(content)
        {
            field(CurrentAnalysisLineTempl; CurrentAnalysisLineTempl)
            {
                ApplicationArea = InventoryAnalysis;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the record.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    AnalysisReportMgt.LookupAnalysisLineTemplName(CurrentAnalysisLineTempl, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    AnalysisReportMgt.CheckAnalysisLineTemplName(CurrentAnalysisLineTempl, Rec);
                    CurrentAnalysisLineTemplOnAfte();
                end;
            }
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("Row Ref. No."; Rec."Row Ref. No.")
                {
                    ApplicationArea = InventoryAnalysis;
                    StyleExpr = 'Strong';

                    trigger OnValidate()
                    begin
                        RowRefNoOnAfterValidate();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = InventoryAnalysis;
                    StyleExpr = 'Strong';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = InventoryAnalysis;

                    trigger OnValidate()
                    begin
                        if (Rec.Type in [Rec.Type::Customer, Rec.Type::"Customer Group", Rec.Type::Vendor, Rec.Type::"Sales/Purchase Person"]) then
                            Rec.FieldError(Rec.Type);
                    end;
                }
                field(Range; Rec.Range)
                {
                    ApplicationArea = InventoryAnalysis;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookupTotalingRange(Text));
                    end;
                }
                field("Dimension 1 Totaling"; Rec."Dimension 1 Totaling")
                {
                    ApplicationArea = Dimensions;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookupDimTotalingRange(Text, ItemAnalysisView."Dimension 1 Code"));
                    end;
                }
                field("Dimension 2 Totaling"; Rec."Dimension 2 Totaling")
                {
                    ApplicationArea = Dimensions;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookupDimTotalingRange(Text, ItemAnalysisView."Dimension 2 Code"));
                    end;
                }
                field("Dimension 3 Totaling"; Rec."Dimension 3 Totaling")
                {
                    ApplicationArea = Dimensions;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        exit(Rec.LookupDimTotalingRange(Text, ItemAnalysisView."Dimension 3 Code"));
                    end;
                }
                field("New Page"; Rec."New Page")
                {
                    ApplicationArea = InventoryAnalysis;
                }
                field(Show; Rec.Show)
                {
                    ApplicationArea = InventoryAnalysis;
                }
                field(Bold; Rec.Bold)
                {
                    ApplicationArea = InventoryAnalysis;
                    ToolTip = 'Specifies if you want the amounts in this line to be printed in bold.';
                }
                field(Indentation; Rec.Indentation)
                {
                    ApplicationArea = InventoryAnalysis;
                    Visible = false;
                }
                field(Italic; Rec.Italic)
                {
                    ApplicationArea = InventoryAnalysis;
                }
                field(Underline; Rec.Underline)
                {
                    ApplicationArea = InventoryAnalysis;
                }
                field("Show Opposite Sign"; Rec."Show Opposite Sign")
                {
                    ApplicationArea = InventoryAnalysis;
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Insert &Items")
                {
                    ApplicationArea = InventoryAnalysis;
                    Caption = 'Insert &Items';
                    Ellipsis = true;
                    Image = Item;
                    ToolTip = 'Insert one or more items that you want to include in the sales analysis report.';

                    trigger OnAction()
                    begin
                        InsertLine("Analysis Line Type"::Item);
                    end;
                }
                separator(Action36)
                {
                }
                action("Insert Ite&m Groups")
                {
                    ApplicationArea = InventoryAnalysis;
                    Caption = 'Insert Ite&m Groups';
                    Ellipsis = true;
                    Image = ItemGroup;
                    ToolTip = 'Insert one or more item groups that you want to include in the sales analysis report.';

                    trigger OnAction()
                    begin
                        InsertLine("Analysis Line Type"::"Item Group");
                    end;
                }
                separator(Action48)
                {
                }
                action("Renumber Lines")
                {
                    ApplicationArea = InventoryAnalysis;
                    Caption = 'Renumber Lines';
                    Image = Refresh;
                    ToolTip = 'Renumber lines in the analysis report sequentially from a number that you specify.';

                    trigger OnAction()
                    var
                        AnalysisLine: Record "Analysis Line";
                        RenAnalysisLines: Report "Renumber Analysis Lines";
                    begin
                        CurrPage.SetSelectionFilter(AnalysisLine);
                        RenAnalysisLines.Init(AnalysisLine);
                        RenAnalysisLines.RunModal();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat();
    end;

    trigger OnOpenPage()
    var
        GLSetup: Record "General Ledger Setup";
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        AnalysisReportMgt.OpenAnalysisLines(CurrentAnalysisLineTempl, Rec);

        GLSetup.Get();

        if AnalysisLineTemplate.Get(Rec.GetRangeMax("Analysis Area"), CurrentAnalysisLineTempl) then
            if AnalysisLineTemplate."Item Analysis View Code" <> '' then
                ItemAnalysisView.Get(Rec.GetRangeMax("Analysis Area"), AnalysisLineTemplate."Item Analysis View Code")
            else begin
                Clear(ItemAnalysisView);
                ItemAnalysisView."Dimension 1 Code" := GLSetup."Global Dimension 1 Code";
                ItemAnalysisView."Dimension 2 Code" := GLSetup."Global Dimension 2 Code";
            end;
    end;

    var
        ItemAnalysisView: Record "Item Analysis View";
        AnalysisReportMgt: Codeunit "Analysis Report Management";
        CurrentAnalysisLineTempl: Code[10];
        DescriptionIndent: Integer;

    local procedure InsertLine(Type: Enum "Analysis Line Type")
    var
        AnalysisLine: Record "Analysis Line";
    begin
        CurrPage.Update(true);
        AnalysisLine.Copy(Rec);
        if Rec."Line No." = 0 then begin
            AnalysisLine := xRec;
            if AnalysisLine.Next() = 0 then
                AnalysisLine."Line No." := xRec."Line No." + 10000;
        end;

        InsertAnalysisLines(AnalysisLine, Type);
    end;

    local procedure InsertAnalysisLines(var AnalysisLine: Record "Analysis Line"; Type: Enum "Analysis Line Type")
    var
        InsertAnalysisLine: Codeunit "Insert Analysis Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertAnalysisLine(AnalysisLine, Type, IsHandled);
        if IsHandled then
            exit;

        case Type of
            Type::Item:
                InsertAnalysisLine.InsertItems(AnalysisLine);
            Type::Customer:
                InsertAnalysisLine.InsertCust(AnalysisLine);
            Type::Vendor:
                InsertAnalysisLine.InsertVend(AnalysisLine);
            Type::"Item Group":
                InsertAnalysisLine.InsertItemGrDim(AnalysisLine);
            Type::"Customer Group":
                InsertAnalysisLine.InsertCustGrDim(AnalysisLine);
            Type::"Sales/Purchase Person":
                InsertAnalysisLine.InsertSalespersonPurchaser(AnalysisLine);
        end;
    end;

    procedure SetCurrentAnalysisLineTempl(AnalysisLineTemlName: Code[10])
    begin
        CurrentAnalysisLineTempl := AnalysisLineTemlName;
    end;

    local procedure RowRefNoOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure CurrentAnalysisLineTemplOnAfte()
    var
        ItemSchedName: Record "Analysis Line Template";
    begin
        CurrPage.SaveRecord();
        AnalysisReportMgt.SetAnalysisLineTemplName(CurrentAnalysisLineTempl, Rec);
        if ItemSchedName.Get(Rec.GetRangeMax("Analysis Area"), CurrentAnalysisLineTempl) then
            CurrPage.Update(false);
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionIndent := Rec.Indentation;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertAnalysisLine(var AnalysisLine: Record "Analysis Line"; Type: Enum "Analysis Line Type"; var IsHandled: Boolean)
    begin
    end;
}

