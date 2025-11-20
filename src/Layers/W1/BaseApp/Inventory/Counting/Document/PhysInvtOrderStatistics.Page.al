// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

page 5897 "Phys. Invt. Order Statistics"
{
    Caption = 'Phys. Invt. Order Statistics';
    Editable = false;
    PageType = Card;
    SourceTable = "Phys. Invt. Order Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                fixed(Control1905583001)
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
                                PhysInvtOrderLine2.Reset();
                                PhysInvtOrderLine2.SetCurrentKey("Document No.", "Entry Type", "Without Difference");
                                PhysInvtOrderLine2.SetRange("Document No.", Rec."No.");
                                PhysInvtOrderLine2.SetRange("Entry Type", PhysInvtOrderLine2."Entry Type"::"Positive Adjmt.");
                                PhysInvtOrderLine2.SetRange("Without Difference", true);
                                PAGE.RunModal(0, PhysInvtOrderLine2);
                            end;
                        }
                        field(NoPosDiffLines; NoPosDiffLines)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Lines Pos. Difference';
                            ToolTip = 'Specifies the number of lines with a positive difference between actual and calculated inventory.';

                            trigger OnDrillDown()
                            begin
                                PhysInvtOrderLine2.Reset();
                                PhysInvtOrderLine2.SetCurrentKey("Document No.", "Entry Type", "Without Difference");
                                PhysInvtOrderLine2.SetRange("Document No.", Rec."No.");
                                PhysInvtOrderLine2.SetRange("Entry Type", PhysInvtOrderLine2."Entry Type"::"Positive Adjmt.");
                                PhysInvtOrderLine2.SetRange("Without Difference", false);
                                PAGE.RunModal(0, PhysInvtOrderLine2);
                            end;
                        }
                        field(NoNegDiffLines; NoNegDiffLines)
                        {
                            ApplicationArea = Warehouse;
                            Caption = 'Lines Neg. Difference';
                            ToolTip = 'Specifies the number of lines with a negative difference between actual and calculated inventory.';

                            trigger OnDrillDown()
                            begin
                                PhysInvtOrderLine2.Reset();
                                PhysInvtOrderLine2.SetCurrentKey("Document No.", "Entry Type", "Without Difference");
                                PhysInvtOrderLine2.SetRange("Document No.", Rec."No.");
                                PhysInvtOrderLine2.SetRange("Entry Type", PhysInvtOrderLine2."Entry Type"::"Negative Adjmt.");
                                PAGE.RunModal(0, PhysInvtOrderLine2);
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
                            ToolTip = 'Specifies the difference amount of lines with no difference between actual and calculated inventory.';
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
                            ToolTip = 'Specifies the difference amount of lines with a positive difference between actual and calculated inventory.';
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

        PhysInvtOrderLine.Reset();
        PhysInvtOrderLine.SetRange("Document No.", Rec."No.");
        if PhysInvtOrderLine.Find('-') then
            repeat
                if not PhysInvtOrderLine.EmptyLine() then begin
                    NoAllLines := NoAllLines + 1;
                    OnBeforeCalcAmounts(PhysInvtOrderLine);
                    ExpAmountAllLines +=
                      PhysInvtOrderLine."Qty. Expected (Base)" * PhysInvtOrderLine."Unit Amount";
                    RecAmountAllLines +=
                      PhysInvtOrderLine."Qty. Recorded (Base)" * PhysInvtOrderLine."Unit Amount";
                    DiffAmountAllLines +=
                      (PhysInvtOrderLine."Qty. Recorded (Base)" - PhysInvtOrderLine."Qty. Expected (Base)") *
                      PhysInvtOrderLine."Unit Amount";
                    case PhysInvtOrderLine."Entry Type" of
                        PhysInvtOrderLine."Entry Type"::"Positive Adjmt.":
                            if PhysInvtOrderLine."Quantity (Base)" = 0 then begin
                                NoCorrectLines := NoCorrectLines + 1;
                                ExpAmountCorrectLines +=
                                  PhysInvtOrderLine."Qty. Expected (Base)" * PhysInvtOrderLine."Unit Amount";
                                RecAmountCorrectLines +=
                                  PhysInvtOrderLine."Qty. Recorded (Base)" * PhysInvtOrderLine."Unit Amount";
                            end else begin
                                NoPosDiffLines := NoPosDiffLines + 1;
                                ExpAmountPosDiffLines +=
                                  PhysInvtOrderLine."Qty. Expected (Base)" * PhysInvtOrderLine."Unit Amount";
                                RecAmountPosDiffLines +=
                                  PhysInvtOrderLine."Qty. Recorded (Base)" * PhysInvtOrderLine."Unit Amount";
                                DiffAmountPosDiffLines +=
                                  PhysInvtOrderLine."Quantity (Base)" * PhysInvtOrderLine."Unit Amount";
                            end;
                        PhysInvtOrderLine."Entry Type"::"Negative Adjmt.":
                            begin
                                NoNegDiffLines := NoNegDiffLines + 1;
                                ExpAmountNegDiffLines +=
                                  PhysInvtOrderLine."Qty. Expected (Base)" * PhysInvtOrderLine."Unit Amount";
                                RecAmountNegDiffLines +=
                                  PhysInvtOrderLine."Qty. Recorded (Base)" * PhysInvtOrderLine."Unit Amount";
                                DiffAmountNegDiffLines +=
                                  PhysInvtOrderLine."Quantity (Base)" * PhysInvtOrderLine."Unit Amount";
                            end;
                        else
                            Error(UnknownEntryTypeErr);
                    end;
                end;
            until PhysInvtOrderLine.Next() = 0;
    end;

    var
        UnknownEntryTypeErr: Label 'Unknown Entry type.';
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderLine2: Record "Phys. Invt. Order Line";
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
    local procedure OnBeforeCalcAmounts(var PhysInvtOrderLine: Record "Phys. Invt. Order Line")
    begin
    end;
}

