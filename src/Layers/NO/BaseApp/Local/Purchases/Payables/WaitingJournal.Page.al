// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.Dimension;

page 15000005 "Waiting Journal"
{
    Caption = 'Waiting Journal';
    DataCaptionFields = "Payment Order ID - Sent", "Payment Order ID - Approved", "Payment Order ID - Settled";
    Editable = false;
    PageType = List;
    SourceTable = "Waiting Journal";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Reference; Rec.Reference)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference associated with the waiting journal.';
                }
                field("BBS Referance"; Rec."BBS Referance")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reference number when remitting to Bankenes BetalingsSentral (BBS).';
                    Visible = false;
                }
                field("Remittance Status"; Rec."Remittance Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the remittance associated with the waiting journal.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the waiting journal.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document type to which the waiting journal belongs.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account type associated with the waiting journal.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number associated with the waiting journal.';

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the waiting journal.';
                    Visible = false;
                }
                field(DescriptionField; Rec.ReadDescription())
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the waiting journal.';
                    Caption = 'Description';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the currency associated with the waiting journal.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the waiting journal.';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the waiting journal entry in LCY.';
                    Visible = false;
                }
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document to which the journal line will be applied.';
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document to which the journal line will be applied.';
                }
                field("Return Code"; Rec."Return Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the return code associated with the waiting journal.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Handling Ref."; Rec."Handling Ref.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the handling reference associated with the waiting journal.';
                }
                field("BBS Shipment No."; Rec."BBS Shipment No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the shipment order when remitting to Bankenes BetalingsSentral (BBS).';
                    Visible = false;
                }
                field("BBS Payment Order No."; Rec."BBS Payment Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment order number when remitting to Bankenes BetalingsSentral (BBS).';
                    Visible = false;
                }
                field("BBS Transaction No."; Rec."BBS Transaction No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction number when remitting to Bankenes BetalingsSentral (BBS).';
                    Visible = false;
                }
                field("Payment Order ID - Sent"; Rec."Payment Order ID - Sent")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the sent remittance payment order ID associated with the waiting journal.';
                }
                field("Payment Order ID - Approved"; Rec."Payment Order ID - Approved")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the approved remittance payment order ID associated with the waiting journal.';
                }
                field("Payment Order ID - Settled"; Rec."Payment Order ID - Settled")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the settled remittance payment order ID associated with the waiting journal.';
                }
                field("Journal, Settlement Template"; Rec."Journal, Settlement Template")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the settlement template associated with the waiting journal.';
                    Visible = false;
                }
                field("Journal - Settlement"; Rec."Journal - Settlement")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the settlement journal associated with the waiting journal.';
                    Visible = false;
                }
                field(KID; Rec.KID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the electronic Kunde ID (KID).';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                action("&Dimensions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
            }
            group("Waiting Journal")
            {
                Caption = 'Waiting Journal';
                action("Payment Overview")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment Overview';
                    Image = Payment;
                    RunObject = Report "Waiting Jnl - paym. overview";
                    ToolTip = 'Get an overview of payments that are not settled.';
                }
                action("Return Error")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Return Error';
                    Image = ErrorLog;
                    RunObject = Page "Return Error";
                    RunPageLink = "Waiting Journal Reference" = field(Reference);
                    ToolTip = 'View the electronic payment orders that have been returned with an error. For a remittance error, the error code from the bank and an explanation of the error will be shown for the payment in the Waiting Journal window.';
                }
                separator(Action37)
                {
                }
                action("Cancel Payment")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Cancel Payment';
                    Image = VoidExpiredCheck;
                    ToolTip = 'Cancel the payment. An individual payment can be canceled if the payment cannot be processed by the bank and a new remittance has to be made. You can also cancel a payment if you do not want to process the payment. Settled payments cannot be canceled.';

                    trigger OnAction()
                    var
                        ResetJournal: Codeunit "Reset Remittance Payment Order";
                    begin
                        // Reset waiting journal (and related posts):
                        ResetJournal.ResetWaitingJournalJN(Rec);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    var
        ShortcutDimCode: array[8] of Code[20];
}

