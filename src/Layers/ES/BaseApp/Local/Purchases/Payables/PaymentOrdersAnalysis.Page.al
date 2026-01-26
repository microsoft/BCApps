// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.ReceivablesPayables;

page 7000053 "Payment Orders Analysis"
{
    Caption = 'Payment Orders Analysis';
    DataCaptionExpression = Rec.Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Payment Order";

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
                    ToolTip = 'Specifies a category filter for the documents included in this payment order.';

                    trigger OnValidate()
                    begin
                        CategoryFilterOnAfterValidate();
                    end;
                }
            }
            group(Control3)
            {
                ShowCaption = false;
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the currency code associated with this payment order.';
                }
                field(DocCount; DocCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No. of Documents';
                    Editable = false;
                    ToolTip = 'Specifies the number of documents included.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sum total of the documents included in this payment order.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount of all of the documents included in this payment order.';
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
        Doc: Record "Cartera Doc.";
        DocCount: Integer;

    local procedure UpdateStatistics()
    begin
        Doc.SetRange(Type, Doc.Type::Payable);
        Doc.SetRange("Collection Agent", Doc."Collection Agent"::Bank);
        Doc.SetRange("Bill Gr./Pmt. Order No.", Rec."No.");
        Rec.CopyFilter("Global Dimension 1 Filter", Doc."Global Dimension 1 Code");
        Rec.CopyFilter("Global Dimension 2 Filter", Doc."Global Dimension 2 Code");
        Rec.CopyFilter("Category Filter", Doc."Category Code");
        Rec.CopyFilter("Due Date Filter", Doc."Due Date");
        DocCount := Doc.Count();
    end;

    local procedure CategoryFilterOnAfterValidate()
    begin
        UpdateStatistics();
    end;
}

