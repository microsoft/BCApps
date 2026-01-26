// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.ReceivablesPayables;

page 7000062 "Closed Pmt. Ord. Analysis"
{
    Caption = 'Closed Pmt. Ord. Analysis';
    DataCaptionExpression = Rec.Caption();
    Editable = false;
    PageType = Card;
    SourceTable = "Closed Payment Order";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code in which the payment order was generated.';
                }
                field("Amount Grouped"; Rec."Amount Grouped")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the grouped amount for this closed payment order.';
                }
            }
            group(Control1100000)
            {
                ShowCaption = false;
                fixed(Control1905470101)
                {
                    ShowCaption = false;
                    group("No. of Documents")
                    {
                        Caption = 'No. of Documents';
                        field(NoHonored; NoHonored)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Honored';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is settled. ';
                        }
                        field(NoRedrawn; NoRedrawn)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Redrawn';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is recirculated because it was rejected when its due date arrived.';
                        }
                    }
                    group(Amount)
                    {
                        Caption = 'Amount';
                        field(Honored; HonoredAmt)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Editable = false;
                        }
                        field(Rejected; RedrawnAmt)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Editable = false;
                        }
                    }
                    group("Amount (LCY)")
                    {
                        Caption = 'Amount (LCY)';
                        field(Honored2; HonoredAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Honored';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is settled. ';
                        }
                        field(Rejected2; RedrawnAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Rejected';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is rejected.';
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
        UpdateStatistics();
    end;

    var
        ClosedDoc: Record "Closed Cartera Doc.";
        HonoredAmt: Decimal;
        RedrawnAmt: Decimal;
        HonoredAmtLCY: Decimal;
        RedrawnAmtLCY: Decimal;
        NoHonored: Integer;
        NoRedrawn: Integer;

    local procedure UpdateStatistics()
    begin
        ClosedDoc.SetCurrentKey(Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Status, Redrawn);
        ClosedDoc.SetRange(Type, ClosedDoc.Type::Payable);
        ClosedDoc.SetRange("Collection Agent", ClosedDoc."Collection Agent"::Bank);
        ClosedDoc.SetRange("Bill Gr./Pmt. Order No.", Rec."No.");
        Rec.CopyFilter("Global Dimension 1 Filter", ClosedDoc."Global Dimension 1 Code");
        Rec.CopyFilter("Global Dimension 2 Filter", ClosedDoc."Global Dimension 2 Code");

        ClosedDoc.SetRange(Status, ClosedDoc.Status::Honored);
        ClosedDoc.SetRange(Redrawn, true);
        ClosedDoc.CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
        RedrawnAmt := ClosedDoc."Amount for Collection";
        RedrawnAmtLCY := ClosedDoc."Amt. for Collection (LCY)";
        NoRedrawn := ClosedDoc.Count;

        ClosedDoc.SetRange(Redrawn, false);
        ClosedDoc.CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
        HonoredAmt := ClosedDoc."Amount for Collection";
        HonoredAmtLCY := ClosedDoc."Amt. for Collection (LCY)";
        NoHonored := ClosedDoc.Count;
        ClosedDoc.SetRange(Redrawn);

        ClosedDoc.SetRange(Status);
    end;
}

