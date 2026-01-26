// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Finance.Currency;

page 7000044 "Closed Documents Analysis"
{
    Caption = 'Closed Documents Analysis';
    DataCaptionExpression = Rec.GetFilter(Type);
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Closed Cartera Doc.";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(CurrencyFilter; CurrencyFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Currency Filter';
                    TableRelation = Currency;
                    ToolTip = 'Specifies the currencies that the data is included for.';

                    trigger OnValidate()
                    begin
                        CurrencyFilterOnAfterValidate();
                    end;
                }
            }
            group(Control23)
            {
                ShowCaption = false;
                fixed(Control1902115401)
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
                    }
                    group("Original Amount")
                    {
                        Caption = 'Original Amount';
                        field(Honored; HonoredAmt)
                        {
                            ApplicationArea = All;
                            AutoFormatExpression = ClosedDoc."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Original Amount';
                            Editable = false;
                            ToolTip = 'Specifies the initial amount of this closed document.';
                            Visible = HonoredVisible;
                        }
                        field(Rejected; RejectedAmt)
                        {
                            ApplicationArea = All;
                            AutoFormatExpression = ClosedDoc."Currency Code";
                            AutoFormatType = 1;
                            Editable = false;
                            Visible = RejectedVisible;
                        }
                        field(Rejected2; RedrawnAmt)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = ClosedDoc."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Rejected';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is rejected.';
                        }
                    }
                    group("Original Amt. (LCY)")
                    {
                        Caption = 'Original Amt. (LCY)';
                        field(HonoredLCY; HonoredAmtLCY)
                        {
                            ApplicationArea = All;
                            AutoFormatType = 1;
                            Caption = 'Original Amt. (LCY)';
                            Editable = false;
                            ToolTip = 'Specifies the initial amount of this closed document, in LCY.';
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
                        field(RejectedLCY2; RedrawnAmtLCY)
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

    trigger OnInit()
    begin
        RejectedLCYVisible := true;
        HonoredLCYVisible := true;
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
        HonoredAmtLCY: Decimal;
        RejectedAmtLCY: Decimal;
        RedrawnAmtLCY: Decimal;
        NoHonored: Integer;
        NoRejected: Integer;
        NoRedrawn: Integer;
        CurrencyFilter: Code[250];
        HonoredVisible: Boolean;
        RejectedVisible: Boolean;
        HonoredLCYVisible: Boolean;
        RejectedLCYVisible: Boolean;

    local procedure UpdateStatistics()
    begin
        ClosedDoc.Copy(Rec);
        ClosedDoc.SetCurrentKey(Type, "Collection Agent", "Bill Gr./Pmt. Order No.", "Currency Code", Status, Redrawn);
        ClosedDoc.SetFilter("Currency Code", CurrencyFilter);
        ClosedDoc.SetRange(Status, ClosedDoc.Status::Honored);
        ClosedDoc.SetRange(Redrawn, true);
        RedrawnAmt := 0;
        RedrawnAmtLCY := 0;
        if ClosedDoc.FindSet() then
            repeat
                RedrawnAmt += ClosedDoc."Original Amount";
                RedrawnAmtLCY += ClosedDoc."Original Amount (LCY)";
            until ClosedDoc.Next() = 0;
        NoRedrawn := ClosedDoc.Count;

        ClosedDoc.SetRange(Redrawn, false);
        HonoredAmt := 0;
        HonoredAmtLCY := 0;
        if ClosedDoc.FindSet() then
            repeat
                HonoredAmt += ClosedDoc."Original Amount";
                HonoredAmtLCY += ClosedDoc."Original Amount (LCY)";
            until ClosedDoc.Next() = 0;
        NoHonored := ClosedDoc.Count;
        ClosedDoc.SetRange(Redrawn);

        ClosedDoc.SetRange(Status, ClosedDoc.Status::Rejected);
        RejectedAmt := 0;
        RejectedAmtLCY := 0;
        if ClosedDoc.FindSet() then
            repeat
                RejectedAmt += ClosedDoc."Original Amount";
                RejectedAmtLCY += ClosedDoc."Original Amount (LCY)";
            until ClosedDoc.Next() = 0;

        NoRejected := ClosedDoc.Count;
        ClosedDoc.SetRange(Status);

        if ClosedDoc.Find('=><') then;  // necessary to calculate decimal places
    end;

    local procedure CurrencyFilterOnAfterValidate()
    begin
        UpdateStatistics();
    end;
}

