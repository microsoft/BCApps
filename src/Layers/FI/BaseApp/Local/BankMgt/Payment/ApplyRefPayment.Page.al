// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Payment;

page 32000002 "Apply Ref. Payment"
{
    Caption = 'Apply Ref. Payment';
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Ref. Payment - Imported";
    SourceTableView = sorting("No.")
                      order(ascending)
                      where("Posted to G/L" = const(false),
                            "Record ID" = filter(3 .. 5));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Banks Posting Date"; Rec."Banks Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date that is used by the bank.';
                }
                field("Banks Payment Date"; Rec."Banks Payment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment date used by the bank.';
                    Visible = false;
                }
                field("Bank Account Code"; Rec."Bank Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a bank account code for the reference payment.';
                }
                field("Filing Code"; Rec."Filing Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a filing code for the reference payment.';
                }
                field("Reference No."; Rec."Reference No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference number that is calculated from a reference number sequence.';
                }
                field("Payers Name"; Rec."Payers Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the customer name that is associated with the reference payment.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment amount for the reference payment.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a customer number for the reference payment.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the reference payment.';
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an entry number for the reference payment.';

                    trigger OnValidate()
                    begin
                        if Rec."Entry No." <> 0 then begin
                            Rec."Matched Date" := Today;
                            Rec."Matched Time" := Time;
                            Rec.Matched := true;
                        end else begin
                            Rec."Matched Date" := 0D;
                            Rec."Matched Time" := 0T;
                            Rec.Matched := false;
                        end
                    end;
                }
                field(Matched; Rec.Matched)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to filter payments according to date or time.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;
}

