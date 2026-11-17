// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

page 35297 "Closed Docs Analysis NonLCY FB"
{
    Caption = 'Closed Docs Analysis NonLCY FB';
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
            field(Honored; HonoredAmt)
            {
                ApplicationArea = All;
                AutoFormatExpression = ClosedDoc."Currency Code";
                AutoFormatType = 1;
                Caption = 'Honored';
                Editable = false;
                ToolTip = 'Specifies that the related payment is settled. ';
                Visible = HonoredVisible;
            }
            field(Rejected; RejectedAmt)
            {
                ApplicationArea = All;
                AutoFormatExpression = ClosedDoc."Currency Code";
                AutoFormatType = 1;
                Caption = 'Rejected';
                Editable = false;
                ToolTip = 'Specifies that the related payment is rejected.';
                Visible = RejectedVisible;
            }
            field(Redrawn; RedrawnAmt)
            {
                ApplicationArea = Basic, Suite;
                AutoFormatExpression = ClosedDoc."Currency Code";
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
        RejectedVisible := true;
        HonoredVisible := true;
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
        NoHonored: Integer;
        NoRejected: Integer;
        NoRedrawn: Integer;
        CurrencyFilter: Text;
        Show: Boolean;
        HonoredVisible: Boolean;
        RejectedVisible: Boolean;

    local procedure UpdateStatistics()
    begin
        ClosedDoc.Copy(Rec);
        ClosedDoc.SetCurrentKey(Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Status, Redrawn);
        ClosedDoc.SetFilter("Currency Code", CurrencyFilter);
        ClosedDoc.SetRange(Status, ClosedDoc.Status::Honored);
        ClosedDoc.SetRange(Redrawn, true);
        Show := ClosedDoc.CalcSums("Original Amount");
        if Show then
            RedrawnAmt := ClosedDoc."Original Amount";
        NoRedrawn := ClosedDoc.Count;

        ClosedDoc.SetRange(Redrawn, false);
        if Show then begin
            ClosedDoc.CalcSums("Original Amount");
            HonoredAmt := ClosedDoc."Original Amount";
        end;
        NoHonored := ClosedDoc.Count;
        ClosedDoc.SetRange(Redrawn);

        ClosedDoc.SetRange(Status, ClosedDoc.Status::Rejected);
        if Show then begin
            ClosedDoc.CalcSums("Original Amount");
            RejectedAmt := ClosedDoc."Original Amount";
        end;
        NoRejected := ClosedDoc.Count;
        ClosedDoc.SetRange(Status);

        if ClosedDoc.Find('=><') then;
        // necessary to calculate decimal places
        HonoredVisible := Show;
        RejectedVisible := Show;
        // CurrForm.HonoredLCY.VISIBLE(Show);
        // CurrForm.RejectedLCY.VISIBLE(Show);
    end;
}

