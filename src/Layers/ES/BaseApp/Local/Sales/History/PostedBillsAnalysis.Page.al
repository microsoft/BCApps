// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.History;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;

page 7000068 "Posted Bills Analysis"
{
    Caption = 'Posted Bills Analysis';
    DataCaptionExpression = Rec.Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Posted Cartera Doc.";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(CategoryFilter; CategoryFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Category Filter';
                    TableRelation = "Category Code";
                    ToolTip = 'Specifies the categories that the data is included for.';

                    trigger OnValidate()
                    begin
                        CategoryFilterOnAfterValidate();
                    end;
                }
            }
            group(Control16)
            {
                ShowCaption = false;
                fixed(Control1902454701)
                {
                    ShowCaption = false;
                    group("Number of Bills")
                    {
                        Caption = 'Number of Bills';
                        field(NoOpen; NoOpen)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Open';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is not processed yet. ';
                        }
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
                            Caption = 'Redrawn (o/Rejected)';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is recirculated because it was rejected when its due date arrived.';
                        }
                        field(BGPOAmtLCY; BGPOAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'BGPO Amount';
                            Editable = false;
                            ToolTip = 'Specifies the amount on the bill group or payment order.';
                        }
                        field(NoBillInBGPO; NoBillInBGPO)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Number of Bills';
                            Editable = false;
                            ToolTip = 'Specifies the number of bills included.';
                        }
                    }
                    group(Amount)
                    {
                        Caption = 'Amount';
                        field(OpenAmtLCY; OpenAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Open';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is not processed yet. ';
                        }
                        field(HonoredAmtLCY; HonoredAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Closed';
                            Editable = false;
                            ToolTip = 'Specifies if the document is closed.';
                        }
                        field(RejectedAmtLCY; RejectedAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Caption = 'Rejected';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is rejected.';
                        }
                        field(RedrawnAmtLCY; RedrawnAmtLCY)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatType = 1;
                            Editable = false;
                        }
                    }
                    group("%")
                    {
                        Caption = '%';
                        field(OpenPercentage; OpenPercentage)
                        {
                            ApplicationArea = Basic, Suite;
                            ExtendedDatatype = Ratio;
                            MaxValue = 100;
                            MinValue = 0;
                        }
                        field(HonoredPercentage; HonoredPercentage)
                        {
                            ApplicationArea = Basic, Suite;
                            ExtendedDatatype = Ratio;
                            MaxValue = 100;
                            MinValue = 0;
                        }
                        field(RejectedPercentage; RejectedPercentage)
                        {
                            ApplicationArea = Basic, Suite;
                            ExtendedDatatype = Ratio;
                            MaxValue = 100;
                            MinValue = 0;
                        }
                        field(RedrawnPercentage; RedrawnPercentage)
                        {
                            ApplicationArea = Basic, Suite;
                            ExtendedDatatype = Ratio;
                            MaxValue = 100;
                            MinValue = 0;
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

    trigger OnOpenPage()
    begin
        UpdateStatistics();
    end;

    var
        OpenAmtLCY: Decimal;
        HonoredAmtLCY: Decimal;
        RejectedAmtLCY: Decimal;
        RedrawnAmtLCY: Decimal;
        BGPOAmtLCY: Decimal;
        OpenPercentage: Decimal;
        RejectedPercentage: Decimal;
        HonoredPercentage: Decimal;
        RedrawnPercentage: Decimal;
        NoBillInBGPO: Integer;
        NoOpen: Integer;
        NoHonored: Integer;
        NoRejected: Integer;
        NoRedrawn: Integer;
        CategoryFilter: Code[10];

    local procedure UpdateStatistics()
    begin
        Rec.SetCurrentKey("Bank Account No.", "Bill Gr./Pmt. Order No.", Status, "Category Code", Redrawn, "Due Date", "Document Type");
        Rec.SetRange("Document Type", Rec."Document Type"::Bill);
        if Rec.Type = Rec.Type::Receivable then
            Rec.SetRange(Type, Rec.Type::Receivable)
        else
            Rec.SetRange(Type, Rec.Type::Payable);

        if CategoryFilter = '' then
            Rec.SetRange("Category Code")
        else
            Rec.SetRange("Category Code", CategoryFilter);

        Rec.SetRange(Status);
        Rec.CalcSums("Amt. for Collection (LCY)");
        BGPOAmtLCY := Rec."Amt. for Collection (LCY)";
        NoBillInBGPO := Rec.Count;

        Rec.SetRange(Status, Rec.Status::Open);
        Rec.CalcSums("Amt. for Collection (LCY)");
        OpenAmtLCY := Rec."Amt. for Collection (LCY)";
        NoOpen := Rec.Count;

        if BGPOAmtLCY = 0 then
            OpenPercentage := 0
        else
            OpenPercentage := OpenAmtLCY / BGPOAmtLCY * 100;

        Rec.SetRange(Status);
        Rec.SetRange(Redrawn, true);
        Rec.CalcSums("Amt. for Collection (LCY)");
        RedrawnAmtLCY := Rec."Amt. for Collection (LCY)";
        NoRedrawn := Rec.Count;

        Rec.SetRange(Redrawn);

        Rec.SetRange(Status, Rec.Status::Honored);
        Rec.CalcSums("Amt. for Collection (LCY)");
        HonoredAmtLCY := Rec."Amt. for Collection (LCY)" - RedrawnAmtLCY;
        NoHonored := Rec.Count - NoRedrawn;

        if BGPOAmtLCY = 0 then
            HonoredPercentage := 0
        else
            HonoredPercentage := HonoredAmtLCY / BGPOAmtLCY * 100;

        Rec.SetRange(Status);

        Rec.SetRange(Status, Rec.Status::Rejected);
        Rec.CalcSums("Amt. for Collection (LCY)");
        RejectedAmtLCY := Rec."Amt. for Collection (LCY)" + RedrawnAmtLCY;
        NoRejected := Rec.Count + NoRedrawn;

        if BGPOAmtLCY = 0 then
            RejectedPercentage := 0
        else
            RejectedPercentage := RejectedAmtLCY / BGPOAmtLCY * 100;

        if RejectedAmtLCY = 0 then
            RedrawnPercentage := 0
        else
            RedrawnPercentage := RedrawnAmtLCY / RejectedAmtLCY * 100;

        Rec.SetRange(Status);
    end;

    local procedure CategoryFilterOnAfterValidate()
    begin
        UpdateStatistics();
    end;
}

