// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Reporting;

page 11610 "BAS Setup Preview Subform"
{
    Caption = 'BAS Setup Preview Subform';
    Editable = false;
    PageType = ListPart;
    SourceTable = "BAS Setup";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Row No."; Rec."Row No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a number for the BAS Setup line.';
                }
                field("Field Label No."; Rec."Field Label No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the BAS Field Label, in both the xml file from the Australian Tax Office''s ECI Software and the ATO''s BAS Instructions.';
                }
                field("Field Description"; Rec."Field Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Business Activity Statement (BAS) Field Label Description.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies what the entries in the BAS line will include.';
                }
                field("Amount Type"; Rec."Amount Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the totaling of entries will consist of VAT amounts, or the amounts on which the VAT is based on.';
                }
                field("GST Bus. Posting Group"; Rec."GST Bus. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT business posting group code for the BAS.';
                }
                field("GST Prod. Posting Group"; Rec."GST Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that you can enter a VAT product posting group code for the BAS.';
                }
                field(ColumnValue; ColumnValue)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    Caption = 'Column Amount';
                    DrillDown = true;
                    ToolTip = 'Specifies the amount for this column.';

                    trigger OnDrillDown()
                    begin
                        RunOnDrillDown();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        BASUpdate.InitializeRequest(BASCalcSheet, false, Selection, PeriodSelection, ExcludeClosingEntries);
        if not BASCalcSheet.Exported then
            BASUpdate.CalcLineTotal(Rec, ColumnValue, 0)
        else
            BASUpdate.CalcExportLineTotal(Rec, ColumnValue, 0, DocumentNo, VersionNo);

        if Rec."Print with" = Rec."Print with"::"Opposite Sign" then
            ColumnValue := -ColumnValue;
    end;

    var
        Text000: Label 'Drilldown not possible when %1 is %2.';
        BASCalcSheet: Record "BAS Calculation Sheet";
        BASUpdate: Report "BAS-Update";
        ColumnValue: Decimal;
        Selection: Enum "VAT Statement Report Selection";
        PeriodSelection: Enum "VAT Statement Report Period Selection";
        ExcludeClosingEntries: Boolean;
        DocumentNo: Code[11];
        VersionNo: Integer;

    [Scope('OnPrem')]
    procedure SetValues(var NewBASCalcSheet: Record "BAS Calculation Sheet"; NewSelection: Enum "VAT Statement Report Selection"; NewPeriodSelection: Enum "VAT Statement Report Period Selection"; NewExcludeClosingEntries: Boolean; NewDocumentNo: Code[11]; NewVersionNo: Integer)
    begin
        BASCalcSheet.Copy(NewBASCalcSheet);
        Selection := NewSelection;
        PeriodSelection := NewPeriodSelection;
        ExcludeClosingEntries := NewExcludeClosingEntries;
        DocumentNo := NewDocumentNo;
        VersionNo := NewVersionNo;
        Rec.SetFilter(
          "Date Filter",
          BASUpdate.GetPeriodFilter(PeriodSelection, BASCalcSheet.A3, BASCalcSheet.A4));
        CurrPage.Update();
    end;

    local procedure RunOnDrillDown()
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VATEntries: Page "VAT Entries";
        GLEntries: Page "General Ledger Entries";
        BASCalcEntry1: Record "BAS Calc. Sheet Entry";
    begin
        case Rec.Type of
            Rec.Type::"Account Totaling":
                begin
                    GLEntry.Reset();
                    GLEntry.SetCurrentKey(
                      "G/L Account No.",
                      "BAS Adjustment",
                      "VAT Bus. Posting Group",
                      "VAT Prod. Posting Group",
                      "Posting Date");
                    GLEntry.SetFilter("G/L Account No.", Rec."Account Totaling");
                    GLEntry.SetRange("BAS Adjustment", Rec."BAS Adjustment");
                    GLEntry.SetRange("VAT Bus. Posting Group", Rec."GST Bus. Posting Group");
                    GLEntry.SetRange("VAT Prod. Posting Group", Rec."GST Prod. Posting Group");
                    GLEntry.SetFilter(
                      "Posting Date",
                      BASUpdate.GetPeriodFilter(PeriodSelection, BASCalcSheet.A3, BASCalcSheet.A4));
                    if BASCalcSheet.Exported then
                        GLEntry.SetRange("BAS Doc. No.", DocumentNo)
                    else
                        if BASCalcSheet.Updated and not BASCalcSheet.Exported then
                            GLEntry.SetRange("BAS Doc. No.", '');
                    if ExcludeClosingEntries then
                        if GLEntry.Find('-') then begin
                            repeat
                                if not BASCalcSheet.Exported then begin
                                    if GLEntry."Posting Date" = NormalDate(GLEntry."Posting Date") then
                                        GLEntry.Mark(true);
                                end else begin
                                    BASCalcEntry1.Reset();
                                    BASCalcEntry1.SetCurrentKey("Company Name", Type, "Entry No.", "BAS Document No.", "BAS Version");
                                    BASCalcEntry1.SetRange("Company Name", CompanyName);
                                    BASCalcEntry1.SetRange(Type, BASCalcEntry1.Type::"G/L Entry");
                                    BASCalcEntry1.SetRange("Entry No.", GLEntry."Entry No.");
                                    BASCalcEntry1.SetRange("BAS Document No.", DocumentNo);
                                    BASCalcEntry1.SetRange("BAS Version", VersionNo);
                                    if BASCalcEntry1.FindFirst() then
                                        if GLEntry."Posting Date" = NormalDate(GLEntry."Posting Date") then
                                            GLEntry.Mark(true);
                                end;
                            until GLEntry.Next() = 0;
                            GLEntry.MarkedOnly(true);
                        end;
                    GLEntries.SetTableView(GLEntry);
                    GLEntries.LookupMode(false);
                    GLEntries.RunModal();
                end;
            Rec.Type::"GST Entry Totaling":
                begin
                    VATEntry.Reset();
                    VATEntry.SetCurrentKey(
                      Type,
                      Closed,
                      "BAS Adjustment",
                      "VAT Bus. Posting Group",
                      "VAT Prod. Posting Group",
                      "Posting Date",
                      "BAS Doc. No.");
                    VATEntry.SetRange(Type, Rec."Gen. Posting Type");
                    case Selection of
                        Selection::Open:
                            VATEntry.SetRange(Closed, false);
                        Selection::Closed:
                            VATEntry.SetRange(Closed, true);
                    end;
                    VATEntry.SetRange("BAS Adjustment", Rec."BAS Adjustment");
                    VATEntry.SetRange("VAT Bus. Posting Group", Rec."GST Bus. Posting Group");
                    VATEntry.SetRange("VAT Prod. Posting Group", Rec."GST Prod. Posting Group");
                    VATEntry.SetFilter(
                      "Posting Date",
                      BASUpdate.GetPeriodFilter(PeriodSelection, BASCalcSheet.A3, BASCalcSheet.A4));
                    if BASCalcSheet.Updated and not BASCalcSheet.Exported then
                        VATEntry.SetRange("BAS Doc. No.", '')
                    else
                        if BASCalcSheet.Exported then
                            VATEntry.SetRange("BAS Doc. No.", DocumentNo);
                    if VATEntry.Find('-') then begin
                        repeat
                            if not BASCalcSheet.Exported then
                                VATEntry.Mark(true)
                            else begin
                                BASCalcEntry1.Reset();
                                BASCalcEntry1.SetCurrentKey("Company Name", Type, "Entry No.", "BAS Document No.", "BAS Version");
                                BASCalcEntry1.SetRange("Company Name", CompanyName);
                                BASCalcEntry1.SetRange(Type, BASCalcEntry1.Type::"GST Entry");
                                BASCalcEntry1.SetRange("Entry No.", VATEntry."Entry No.");
                                BASCalcEntry1.SetRange("BAS Document No.", DocumentNo);
                                BASCalcEntry1.SetRange("BAS Version", VersionNo);
                                if BASCalcEntry1.FindFirst() then
                                    VATEntry.Mark(true);
                            end;
                        until VATEntry.Next() = 0;
                        VATEntry.MarkedOnly(true);
                    end;
                    VATEntries.SetTableView(VATEntry);
                    VATEntries.LookupMode(false);
                    VATEntries.RunModal();
                end;
            Rec.Type::"Row Totaling", Rec.Type::Description:
                Error(Text000, Rec.FieldCaption(Type), Rec.Type);
        end;
    end;
}

