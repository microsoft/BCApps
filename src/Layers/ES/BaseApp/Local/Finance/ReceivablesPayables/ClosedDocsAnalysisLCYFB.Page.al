// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

page 35296 "Closed Docs Analysis LCY FB"
{
    Caption = 'Closed Docs Analysis LCY FB';
    DataCaptionExpression = Rec.GetFilter(Type);
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = CardPart;
    SourceTable = "Closed Cartera Doc.";

    layout
    {
        area(content)
        {
            field(NoHonored; NoHonored)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Honored';
                Editable = false;
                ToolTip = 'Specifies that the related payment is settled. ';
            }
            field(NoRejected; NoRejected)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Rejected';
                Editable = false;
                ToolTip = 'Specifies that the related payment is rejected.';
            }
            field(NoRedrawn; NoRedrawn)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Redrawn';
                Editable = false;
                ToolTip = 'Specifies that the related payment is recirculated because it was rejected when its due date arrived.';
            }
            field(HonoredLCY; HonoredAmtLCY)
            {
                ApplicationArea = All;
                AutoFormatType = 1;
                Caption = 'Honored';
                Editable = false;
                ToolTip = 'Specifies that the related payment is settled. ';
                Visible = HonoredLCYVisible;
            }
            field(RejectedLCY; RejectedAmtLCY)
            {
                ApplicationArea = All;
                AutoFormatType = 1;
                Caption = 'Rejected';
                Editable = false;
                ToolTip = 'Specifies that the related payment is rejected.';
                Visible = RejectedLCYVisible;
            }
            field(RedrawnLCY; RedrawnAmtLCY)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatType = 1;
                Caption = 'Redrawn';
                Editable = false;
                ToolTip = 'Specifies that the related payment is recirculated because it was rejected when its due date arrived.';
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

    trigger OnInit()
    begin
        RejectedLCYVisible := true;
        HonoredLCYVisible := true;
    end;

    trigger OnOpenPage()
    begin
        CurrencyFilter := Rec.GetFilter("Currency Code");
        UpdateStatistics();
    end;

    var
        ClosedDoc: Record "Closed Cartera Doc.";
        HonoredAmt: Decimal;
        RejectedAmt: Decimal;
        RedrawnAmt: Decimal;
        HonoredAmtLCY: Decimal;
        RejectedAmtLCY: Decimal;
        RedrawnAmtLCY: Decimal;
        NoHonored: Integer;
        NoRejected: Integer;
        NoRedrawn: Integer;
        CurrencyFilter: Code[250];
        Show: Boolean;
        HonoredLCYVisible: Boolean;
        RejectedLCYVisible: Boolean;

    local procedure UpdateStatistics()
    begin
        ClosedDoc.Copy(Rec);
        ClosedDoc.SetCurrentKey(Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Status, Redrawn);
        ClosedDoc.SetFilter("Currency Code", CurrencyFilter);
        ClosedDoc.SetRange(Status, ClosedDoc.Status::Honored);
        ClosedDoc.SetRange(Redrawn, true);
        Show := ClosedDoc.CalcSums("Original Amount", "Original Amount (LCY)");
        if Show then begin
            RedrawnAmt := ClosedDoc."Original Amount";
            RedrawnAmtLCY := ClosedDoc."Original Amount (LCY)";
        end;
        NoRedrawn := ClosedDoc.Count;

        ClosedDoc.SetRange(Redrawn, false);
        if Show then begin
            ClosedDoc.CalcSums("Original Amount", "Original Amount (LCY)");
            HonoredAmt := ClosedDoc."Original Amount";
            HonoredAmtLCY := ClosedDoc."Original Amount (LCY)";
        end;
        NoHonored := ClosedDoc.Count;
        ClosedDoc.SetRange(Redrawn);

        ClosedDoc.SetRange(Status, ClosedDoc.Status::Rejected);
        if Show then begin
            ClosedDoc.CalcSums("Original Amount", "Original Amount (LCY)");
            RejectedAmt := ClosedDoc."Original Amount";
            RejectedAmtLCY := ClosedDoc."Original Amount (LCY)";
        end;
        NoRejected := ClosedDoc.Count;
        ClosedDoc.SetRange(Status);

        if ClosedDoc.Find('=><') then;
        // necessary to calculate decimal places
        // CurrForm.Honored.VISIBLE(Show);
        // CurrForm.Rejected.VISIBLE(Show);
        HonoredLCYVisible := Show;
        RejectedLCYVisible := Show;
    end;
}

