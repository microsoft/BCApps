// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using System.Utilities;

page 15000012 "Payment Order - Settl. Status"
{
    Caption = 'Payment Order - Settlement Status';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPlus;
    SourceTable = "Integer";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("RemPaymOrder.ID"; RemPaymOrder.ID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Payment order ID';
                    TableRelation = "Remittance Payment Order";
                    ToolTip = 'Specifies the ID of the payment order.';

                    trigger OnValidate()
                    begin
                        RemPaymOrder.Get(RemPaymOrder.ID);
                        CheckPaymOrderStatus(RemPaymOrder);
                        UpdateInfo();
                        CurrPage.Update();
                    end;
                }
                field("RemPaymOrder.Comment"; RemPaymOrder.Comment)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies a description of the payment.';
                }
            }
            group(Control1080000)
            {
                ShowCaption = false;
                label(Control13)
                {
                    ApplicationArea = Basic, Suite;
                    CaptionClass = Text19066747;
                    MultiLine = true;
                    ShowCaption = false;
                }
            }
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field("ReturnTemplateName[Number]"; ReturnTemplateName[Rec.Number])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Journal, template name';
                    ToolTip = 'Specifies the journal template that is used for posting.';
                }
                field("ReturnJournalName[Number]"; ReturnJournalName[Rec.Number])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Journal name';
                    ToolTip = 'Specifies the journal that is used for posting.';
                }
                field("ReturnNumber[Number]"; ReturnNumber[Rec.Number])
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Number of payments';
                    ToolTip = 'Specifies how many payment to make.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        UpdateInfo();
    end;

    var
        RemPaymOrder: Record "Remittance Payment Order";
        WaitingJournalLine: Record "Waiting Journal";
        ReturnTemplateName: array[20] of Code[10];
        ReturnJournalName: array[20] of Code[10];
        ReturnNumber: array[20] of Integer;
        NumberOfLines: Integer;
        Text19066747: Label 'Settled payments in this payment order are imported and transferred to following journals:';
        MaxNumberOfLinesMsg: Label 'Return data is imported into more than 20 journals.\Return information is displayed only for the first 20 journals.';

    procedure SetPaymOrder(SetRemPaymOrder: Record "Remittance Payment Order")
    begin
        CheckPaymOrderStatus(SetRemPaymOrder);
        RemPaymOrder := SetRemPaymOrder;
    end;

    local procedure UpdateInfo()
    var
        i: Integer;
        JournalFound: Boolean;
    begin
        // Update info shown on form
        Clear(ReturnTemplateName);
        Clear(ReturnJournalName);
        Clear(ReturnNumber);
        NumberOfLines := 0;

        WaitingJournalLine.SetCurrentKey("Payment Order ID - Settled");
        WaitingJournalLine.SetRange("Payment Order ID - Settled", RemPaymOrder.ID);

        // Count the number of payments placed in each journal
        if WaitingJournalLine.Find('-') then
            repeat
                JournalFound := false;
                for i := 1 to NumberOfLines do
                    if (WaitingJournalLine."Journal, Settlement Template" = ReturnTemplateName[i]) and
                       (WaitingJournalLine."Journal - Settlement" = ReturnJournalName[i])
                    then begin
                        ReturnNumber[i] := ReturnNumber[i] + 1;
                        JournalFound := true;
                    end;
                if not JournalFound then begin
                    NumberOfLines := NumberOfLines + 1;
                    if NumberOfLines > ArrayLen(ReturnTemplateName) then
                        Message(MaxNumberOfLinesMsg)
                    else begin
                        ReturnTemplateName[NumberOfLines] := WaitingJournalLine."Journal, Settlement Template";
                        ReturnJournalName[NumberOfLines] := WaitingJournalLine."Journal - Settlement";
                        ReturnNumber[NumberOfLines] := 1;
                    end;
                end;
            until WaitingJournalLine.Next() = 0;

        // Select lines to be shown
        Rec.SetRange(Number, 1, NumberOfLines);
    end;

    local procedure CheckPaymOrderStatus(CheckRemPaymOrder: Record "Remittance Payment Order")
    begin
        CheckRemPaymOrder.TestField(Type, CheckRemPaymOrder.Type::Return);
    end;
}

