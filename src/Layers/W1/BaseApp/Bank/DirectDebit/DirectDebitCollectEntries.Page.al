// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Bank.Payment;
using System.Utilities;

/// <summary>
/// Displays and manages individual direct debit collection entries within a collection.
/// Provides functionality to create, edit, validate, and export collection entries
/// for automated customer payment processing.
/// </summary>
page 1208 "Direct Debit Collect. Entries"
{
    Caption = 'Direct Debit Collect. Entries';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Direct Debit Collection Entry";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                Editable = LineIsEditable;
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                    Visible = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Suite;
                    Style = Attention;
                    StyleExpr = HasLineErrors;
                    ToolTip = 'Specifies the number of the customer that the direct-debit payment is collected from.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = Suite;
                    Style = Attention;
                    StyleExpr = HasLineErrors;
                    ToolTip = 'Specifies the name of the customer that the direct-debit payment is collected from.';
                }
                field("Applies-to Entry No."; Rec."Applies-to Entry No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the number of the sales invoice that the customer leger entry behind this direct-debit collection entry applies to.';
                }
                field("Applies-to Entry Document No."; Rec."Applies-to Entry Document No.")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the document number on the sales invoice that the customer leger entry behind this direct-debit collection entry applies to.';
                }
                field("Transfer Date"; Rec."Transfer Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date when the payment will be collected from the customer''s bank account.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency of the payment amount that is being collected as a direct debit.';
                }
                field("Transfer Amount"; Rec."Transfer Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount that will be collected from the customer''s bank account.';
                }
                field("Transaction ID"; Rec."Transaction ID")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ID of the direct debit collection. It consist of a number in the SEPA direct-debit message number series and the value in the Applies-to Entry No. field.';
                }
                field("Mandate ID"; Rec."Mandate ID")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the ID of the direct-debit mandate that exists for the direct debit collection in question.';
                }
                field("Sequence Type"; Rec."Sequence Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the direct-debit collection entry is the first or the last of a sequence of recurring entries.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the status of the direct-debit collection entry.';
                }
                field("Mandate Type of Payment"; Rec."Mandate Type of Payment")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the related direct-debit mandate is created for one or multiple direct debit collections.';
                    Visible = false;
                }
                field("Applies-to Entry Description"; Rec."Applies-to Entry Description")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the description of the sales invoice that the customer leger entry behind this direct-debit collection entry applies to.';
                }
                field("Applies-to Entry Posting Date"; Rec."Applies-to Entry Posting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies when the sales invoice that the customer leger entry behind this direct-debit collection entry applies to was posted.';
                }
                field("Applies-to Entry Currency Code"; Rec."Applies-to Entry Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the currency of the sales invoice that the customer leger entry behind this direct-debit collection entry applies to.';
                }
                field("Applies-to Entry Amount"; Rec."Applies-to Entry Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the payment amount on the sales invoice that the customer leger entry behind this direct-debit collection entry applies to.';
                }
                field("Applies-to Entry Rem. Amount"; Rec."Applies-to Entry Rem. Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount that remains to be paid on the sales invoice that the customer leger entry behind this direct-debit collection entry applies to.';
                }
                field("Applies-to Entry Open"; Rec."Applies-to Entry Open")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies if the sales invoice that the customer leger entry behind this direct-debit collection entry applies to is open.';
                }
            }
        }
        area(factboxes)
        {
            part("File Export Errors"; "Payment Journal Errors Part")
            {
                ApplicationArea = Suite;
                Caption = 'File Export Errors';
                SubPageLink = "Document No." = field(filter("Direct Debit Collection No.")),
                              "Journal Line No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Export)
            {
                ApplicationArea = Suite;
                Caption = 'Export Direct Debit File';
                Image = ExportFile;
                RunPageOnRec = true;
                ToolTip = 'Save the entries for the direct debit collection to a file that you send or upload to your electronic bank for processing.';

                trigger OnAction()
                begin
                    Rec.ExportSEPA();
                end;
            }
            action(Reject)
            {
                ApplicationArea = Suite;
                Caption = 'Reject Entry';
                Image = Reject;
                ToolTip = 'Reject a debit-collection entry. You will typically do this for payments that could not be processed by the bank.';

                trigger OnAction()
                begin
                    Rec.Reject();
                end;
            }
            action(Close)
            {
                ApplicationArea = Suite;
                Caption = 'Close Collection';
                Image = Close;
                ToolTip = 'Close a direct-debit collection so you begin to post payment receipts for related sales invoices. Once closed, you cannot register payments for the collection.';

                trigger OnAction()
                var
                    DirectDebitCollection: Record "Direct Debit Collection";
                begin
                    DirectDebitCollection.Get(Rec."Direct Debit Collection No.");
                    DirectDebitCollection.CloseCollection();
                end;
            }
            action(Post)
            {
                ApplicationArea = Suite;
                Caption = 'Post Payment Receipts';
                Ellipsis = true;
                Image = ReceivablesPayables;
                ToolTip = 'Post receipts of a payment for sales invoices. You can this after the direct debit collection is successfully processed by the bank.';

                trigger OnAction()
                var
                    DirectDebitCollection: Record "Direct Debit Collection";
                    PostDirectDebitCollection: Report "Post Direct Debit Collection";
                begin
                    Rec.TestField("Direct Debit Collection No.");
                    DirectDebitCollection.Get(Rec."Direct Debit Collection No.");
                    DirectDebitCollection.TestField(Status, DirectDebitCollection.Status::"File Created");
                    PostDirectDebitCollection.SetCollectionEntry(Rec."Direct Debit Collection No.");
                    PostDirectDebitCollection.SetTableView(Rec);
                    PostDirectDebitCollection.Run();
                end;
            }
            action(ResetTransferDate)
            {
                ApplicationArea = Suite;
                Caption = 'Reset Transfer Date';
                Image = ChangeDates;
                ToolTip = 'Insert today''s date in the Transfer Date field on overdue entries with the status New.';

                trigger OnAction()
                var
                    DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
                    ConfirmMgt: Codeunit "Confirm Management";
                begin
                    DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", Rec."Direct Debit Collection No.");
                    DirectDebitCollectionEntry.SetRange(Status, DirectDebitCollectionEntry.Status::New);
                    if DirectDebitCollectionEntry.IsEmpty() then
                        Error(ResetTransferDateNotAllowedErr, Rec."Direct Debit Collection No.");

                    if ConfirmMgt.GetResponse(ResetTransferDateQst, false) then
                        Rec.SetTodayAsTransferDateForOverdueEnries();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Export_Promoted; Export)
                {
                }
                actionref(Reject_Promoted; Reject)
                {
                }
                actionref(Close_Promoted; Close)
                {
                }
                actionref(Post_Promoted; Post)
                {
                }
                actionref(ResetTransferDate_Promoted; ResetTransferDate)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        HasLineErrors := Rec.HasPaymentFileErrors();
        LineIsEditable := Rec.Status = Rec.Status::New;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Rec.TestField(Status, Rec.Status::New);
        Rec.CalcFields("Direct Debit Collection Status");
        Rec.TestField("Direct Debit Collection Status", Rec."Direct Debit Collection Status"::New);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.CalcFields("Direct Debit Collection Status");
        Rec.TestField("Direct Debit Collection Status", Rec."Direct Debit Collection Status"::New);
    end;

    trigger OnModifyRecord(): Boolean
    var
        IsHandled: Boolean;
    begin
        Rec.TestField(Status, Rec.Status::New);
        Rec.CalcFields("Direct Debit Collection Status");
        Rec.TestField("Direct Debit Collection Status", Rec."Direct Debit Collection Status"::New);
        IsHandled := false;
        OnBeforeRunSEPACheckLine(Rec, IsHandled);
        if not IsHandled then
            CODEUNIT.Run(CODEUNIT::"SEPA DD-Check Line", Rec);
        HasLineErrors := Rec.HasPaymentFileErrors();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        LineIsEditable := true;
        HasLineErrors := false;
    end;

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Direct Debit Collection No.", Rec.GetRangeMin("Direct Debit Collection No."));
        Rec.FilterGroup(0);
    end;

    var
        HasLineErrors: Boolean;
        LineIsEditable: Boolean;
        ResetTransferDateQst: Label 'Do you want to insert today''s date in the Transfer Date field on all overdue entries?';
        ResetTransferDateNotAllowedErr: Label 'You cannot change the transfer date because the status of all entries for the direct debit collection %1 is not New.', Comment = '%1 - Direct Debit Collection No.';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunSEPACheckLine(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var IsHandled: Boolean)
    begin
    end;
}

