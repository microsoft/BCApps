// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.History;

page 5898 "Posted Phys. Invt. Order Stat."
{
    Caption = 'Posted Phys. Invt. Order Stat.';
    Editable = false;
    PageType = Card;
    SourceTable = "Pstd. Phys. Invt. Order Hdr";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                fixed(Control3)
                {
                    ShowCaption = false;
                    group("No. of lines")
                    {
                        Caption = 'No. of lines';
                        field(NoAllLines; NoAllLines)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'All Lines';
                            ToolTip = 'Specifies the total number of lines.';
                        }
                        field(NoCorrectLines; NoCorrectLines)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Lines Without Difference';
                            ToolTip = 'Specifies the number of lines with no difference between actual and calculated inventory.';

                            trigger OnDrillDown()
                            begin
                                PstdPhysInvtOrderLine2.Reset();
                                PstdPhysInvtOrderLine2.SetCurrentKey("Document No.", "Entry Type", "Without Difference");
                                PstdPhysInvtOrderLine2.SetRange("Document No.", Rec."No.");
                                PstdPhysInvtOrderLine2.SetRange("Entry Type", PstdPhysInvtOrderLine2."Entry Type"::"Positive Adjmt.");
                                PstdPhysInvtOrderLine2.SetRange("Without Difference", true);
                                PAGE.RunModal(0, PstdPhysInvtOrderLine2);
                            end;
                        }
                        field(NoPosDiffLines; NoPosDiffLines)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Lines Pos. Difference';
                            ToolTip = 'Specifies the number of lines with a positive difference between actual and calculated inventory.';

                            trigger OnDrillDown()
                            begin
                                PstdPhysInvtOrderLine2.Reset();
                                PstdPhysInvtOrderLine2.SetCurrentKey("Document No.", "Entry Type", "Without Difference");
                                PstdPhysInvtOrderLine2.SetRange("Document No.", Rec."No.");
                                PstdPhysInvtOrderLine2.SetRange("Entry Type", PstdPhysInvtOrderLine2."Entry Type"::"Positive Adjmt.");
                                PstdPhysInvtOrderLine2.SetRange("Without Difference", false);
                                PAGE.RunModal(0, PstdPhysInvtOrderLine2);
                            end;
                        }
                        field(NoNegDiffLines; NoNegDiffLines)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Lines Neg. Difference';
                            ToolTip = 'Specifies the number of lines with a negative difference between actual and calculated inventory.';

                            trigger OnDrillDown()
                            begin
                                PstdPhysInvtOrderLine2.Reset();
                                PstdPhysInvtOrderLine2.SetCurrentKey("Document No.", "Entry Type", "Without Difference");
                                PstdPhysInvtOrderLine2.SetRange("Document No.", Rec."No.");
                                PstdPhysInvtOrderLine2.SetRange("Entry Type", PstdPhysInvtOrderLine2."Entry Type"::"Negative Adjmt.");
                                PAGE.RunModal(0, PstdPhysInvtOrderLine2);
                            end;
                        }
                    }
                    group("Recorded Amount")
                    {
                        Caption = 'Recorded Amount';
                        field(RecAmountAllLines; RecAmountAllLines)
                        {
                            ApplicationArea = Warehouse;
                            ToolTip = 'Specifies the recorded amount of all lines.';
                        }
                        field(RecAmountCorrectLines; RecAmountCorrectLines)
                        {
                            ApplicationArea = Warehouse;
                            ToolTip = 'Specifies the recorded amount of lines with no difference between actual and calculated inventory.';
                        }
                        field(RecAmountPosDiffLines; RecAmountPosDiffLines)
                        {
                            ApplicationArea = Warehouse;
                            ToolTip = 'Specifies the recorded amount of lines with a positive difference between actual and calculated inventory.';
                        }
                        field(RecAmountNegDiffLines; RecAmountNegDiffLines)
                        {
                            ApplicationArea = Warehouse;
                            ToolTip = 'Specifies the recorded amount of lines with a negative difference between actual and calculated inventory.';
                        }
                    }
                    group("Expected Amount")
                    {
                        Caption = 'Expected Amount';
                        field(ExpAmountAllLines; ExpAmountAllLines)
                        {
                            ApplicationArea = Warehouse;
                            ToolTip = 'Specifies the expected amount of all lines.';
                        }
                        field(ExpAmountCorrectLines; ExpAmountCorrectLines)
                        {
                            ApplicationArea = Warehouse;
                            ToolTip = 'Specifies the expected amount of lines with no difference between actual and calculated inventory.';
                        }
                        field(ExpAmountPosDiffLines; ExpAmountPosDiffLines)
                        {
                            ApplicationArea = Warehouse;
                            ToolTip = 'Specifies the expected amount of lines with a positive difference between actual and calculated inventory.';
                        }
                        field(ExpAmountNegDiffLines; ExpAmountNegDiffLines)
                        {
                            ApplicationArea = Warehouse;
                            ToolTip = 'Specifies the expected amount of lines with a negative difference between actual and calculated inventory.';
                        }
                    }
                    group("Difference Amount")
                    {
                        Caption = 'Difference Amount';
                        field(DiffAmountAllLines; DiffAmountAllLines)
                        {
                            ApplicationArea = Warehouse;
                            ToolTip = 'Specifies the difference amount of all lines.';
                        }
                        field(PlaceHolderLbl; PlaceHolderLbl)
                        {
                            ApplicationArea = Warehouse;
                            Visible = false;
                        }
                        field(DiffAmountPosDiffLines; DiffAmountPosDiffLines)
                        {
                            ApplicationArea = Warehouse;
                            ToolTip = 'Specifies the difference amount of lines with a positive difference between actual and calculated inventory.';
                        }
                        field(DiffAmountNegDiffLines; DiffAmountNegDiffLines)
                        {
                            ApplicationArea = Warehouse;
                            ToolTip = 'Specifies the difference amount of lines with a negative difference between actual and calculated inventory.';
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Rec.TestField(Status, Rec.Status::Finished);

        ClearAll();

        PstdPhysInvtOrderLine.Reset();
        PstdPhysInvtOrderLine.SetRange("Document No.", Rec."No.");
        if PstdPhysInvtOrderLine.Find('-') then
            repeat
                if not PstdPhysInvtOrderLine.EmptyLine() then begin
                    NoAllLines := NoAllLines + 1;
                    OnBeforeCalcAmounts(PstdPhysInvtOrderLine);
                    ExpAmountAllLines +=
                      PstdPhysInvtOrderLine."Qty. Expected (Base)" * PstdPhysInvtOrderLine."Unit Amount";
                    RecAmountAllLines +=
                      PstdPhysInvtOrderLine."Qty. Recorded (Base)" * PstdPhysInvtOrderLine."Unit Amount";
                    DiffAmountAllLines +=
                      (PstdPhysInvtOrderLine."Qty. Recorded (Base)" - PstdPhysInvtOrderLine."Qty. Expected (Base)") *
                      PstdPhysInvtOrderLine."Unit Amount";
                    case PstdPhysInvtOrderLine."Entry Type" of
                        PstdPhysInvtOrderLine."Entry Type"::"Positive Adjmt.":
                            if PstdPhysInvtOrderLine."Quantity (Base)" = 0 then begin
                                NoCorrectLines := NoCorrectLines + 1;
                                ExpAmountCorrectLines +=
                                  PstdPhysInvtOrderLine."Qty. Expected (Base)" * PstdPhysInvtOrderLine."Unit Amount";
                                RecAmountCorrectLines +=
                                  PstdPhysInvtOrderLine."Qty. Recorded (Base)" * PstdPhysInvtOrderLine."Unit Amount";
                            end else begin
                                NoPosDiffLines := NoPosDiffLines + 1;
                                ExpAmountPosDiffLines +=
                                  PstdPhysInvtOrderLine."Qty. Expected (Base)" * PstdPhysInvtOrderLine."Unit Amount";
                                RecAmountPosDiffLines +=
                                  PstdPhysInvtOrderLine."Qty. Recorded (Base)" * PstdPhysInvtOrderLine."Unit Amount";
                                DiffAmountPosDiffLines +=
                                  (PstdPhysInvtOrderLine."Qty. Recorded (Base)" - PstdPhysInvtOrderLine."Qty. Expected (Base)") *
                                  PstdPhysInvtOrderLine."Unit Amount";
                            end;
                        PstdPhysInvtOrderLine."Entry Type"::"Negative Adjmt.":
                            begin
                                NoNegDiffLines := NoNegDiffLines + 1;
                                ExpAmountNegDiffLines +=
                                  PstdPhysInvtOrderLine."Qty. Expected (Base)" * PstdPhysInvtOrderLine."Unit Amount";
                                RecAmountNegDiffLines +=
                                  PstdPhysInvtOrderLine."Qty. Recorded (Base)" * PstdPhysInvtOrderLine."Unit Amount";
                                DiffAmountNegDiffLines +=
                                  (PstdPhysInvtOrderLine."Qty. Recorded (Base)" - PstdPhysInvtOrderLine."Qty. Expected (Base)") *
                                  PstdPhysInvtOrderLine."Unit Amount";
                            end;
                        else
                            Error(UnknownEntryTypeErr);
                    end;
                end;
            until PstdPhysInvtOrderLine.Next() = 0;
    end;

    var
        UnknownEntryTypeErr: Label 'Unknown Entry type.';
        PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line";
        PstdPhysInvtOrderLine2: Record "Pstd. Phys. Invt. Order Line";
        NoAllLines: Integer;
        NoCorrectLines: Integer;
        NoPosDiffLines: Integer;
        NoNegDiffLines: Integer;
        ExpAmountAllLines: Decimal;
        ExpAmountCorrectLines: Decimal;
        ExpAmountPosDiffLines: Decimal;
        ExpAmountNegDiffLines: Decimal;
        RecAmountAllLines: Decimal;
        RecAmountCorrectLines: Decimal;
        RecAmountPosDiffLines: Decimal;
        RecAmountNegDiffLines: Decimal;
        DiffAmountAllLines: Decimal;
        DiffAmountPosDiffLines: Decimal;
        DiffAmountNegDiffLines: Decimal;
        PlaceHolderLbl: Label 'Placeholder', Locked = true;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAmounts(var PstdPhysInvtOrderLine: Record "Pstd. Phys. Invt. Order Line")
    begin
    end;
}

