// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.History;

using Microsoft.Finance.ReceivablesPayables;

page 7000059 "Post. Payment Orders Analysis"
{
    Caption = 'Post. Payment Orders Analysis';
    DataCaptionExpression = Rec.Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Posted Payment Order";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field("Category Filter"; Rec."Category Filter")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a category filter for the documents included in this posted payment order.';

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
                    group("No. of Documents")
                    {
                        Caption = 'No. of Documents';
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
                            Caption = 'Redrawn';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is recirculated because it was rejected when its due date arrived.';
                        }
                        field("Currency Code"; Rec."Currency Code")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the currency code associated with this posted payment order.';
                        }
                        field("Amount Grouped"; Rec."Amount Grouped")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the grouped amount for this posted payment order.';
                        }
                        field("Remaining Amount"; Rec."Remaining Amount")
                        {
                            ApplicationArea = Basic, Suite;
                            ToolTip = 'Specifies the pending amounts left to pay for documents that are part of this posted payment order.';
                        }
                    }
                    group(Amount)
                    {
                        Caption = 'Amount';
                        field(OpenAmt; OpenAmt)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Open';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is not processed yet. ';
                        }
                        field(HonoredAmt; HonoredAmt)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Closed';
                            Editable = false;
                            ToolTip = 'Specifies if the document is closed.';
                        }
                        field(RejectedAmt; RejectedAmt)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Rejected';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is rejected.';
                        }
                        field(RedrawnAmt; RedrawnAmt)
                        {
                            ApplicationArea = Basic, Suite;
                            AutoFormatExpression = Rec."Currency Code";
                            AutoFormatType = 1;
                            Caption = 'Rejected';
                            Editable = false;
                            ToolTip = 'Specifies that the related payment is rejected.';
                        }
                    }
                    group("Amount (LCY)")
                    {
                        Caption = 'Amount (LCY)';
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
        PostedDoc: Record "Posted Cartera Doc.";
        OpenAmt: Decimal;
        HonoredAmt: Decimal;
        RejectedAmt: Decimal;
        RedrawnAmt: Decimal;
        OpenAmtLCY: Decimal;
        HonoredAmtLCY: Decimal;
        RejectedAmtLCY: Decimal;
        RedrawnAmtLCY: Decimal;
        NoOpen: Integer;
        NoHonored: Integer;
        NoRejected: Integer;
        NoRedrawn: Integer;

    local procedure UpdateStatistics()
    begin
        PostedDoc.SetCurrentKey("Bill Gr./Pmt. Order No.", Status, "Category Code", Redrawn, "Due Date");
        PostedDoc.SetRange(Type, PostedDoc.Type::Payable);
        PostedDoc.SetRange("Bill Gr./Pmt. Order No.", Rec."No.");
        Rec.CopyFilter("Due Date Filter", PostedDoc."Due Date");
        Rec.CopyFilter("Global Dimension 1 Filter", PostedDoc."Global Dimension 1 Code");
        Rec.CopyFilter("Global Dimension 2 Filter", PostedDoc."Global Dimension 2 Code");
        Rec.CopyFilter("Category Filter", PostedDoc."Category Code");

        PostedDoc.SetRange(Status, PostedDoc.Status::Open);
        PostedDoc.CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
        OpenAmt := PostedDoc."Amount for Collection";
        OpenAmtLCY := PostedDoc."Amt. for Collection (LCY)";
        NoOpen := PostedDoc.Count;

        PostedDoc.SetRange(Status);
        PostedDoc.SetRange(Redrawn, true);
        PostedDoc.CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
        RedrawnAmt := PostedDoc."Amount for Collection";
        RedrawnAmtLCY := PostedDoc."Amt. for Collection (LCY)";
        NoRedrawn := PostedDoc.Count;
        PostedDoc.SetRange(Redrawn);

        PostedDoc.SetRange(Status, PostedDoc.Status::Honored);
        PostedDoc.CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
        HonoredAmt := PostedDoc."Amount for Collection" - RedrawnAmt;
        HonoredAmtLCY := PostedDoc."Amt. for Collection (LCY)" - RedrawnAmtLCY;
        NoHonored := PostedDoc.Count - NoRedrawn;

        PostedDoc.SetRange(Status, PostedDoc.Status::Rejected);
        PostedDoc.CalcSums("Amount for Collection", "Amt. for Collection (LCY)");
        RejectedAmt := PostedDoc."Amount for Collection";
        RejectedAmtLCY := PostedDoc."Amt. for Collection (LCY)";
        NoRejected := PostedDoc.Count;
    end;

    local procedure CategoryFilterOnAfterValidate()
    begin
        UpdateStatistics();
    end;
}

