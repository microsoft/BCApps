// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany;

using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;

page 9071 "Intercompany Activities"
{
    Caption = 'Intercompany';
    PageType = CardPart;
    RefreshOnActivate = true;
    Permissions = tabledata "IC Inbox Transaction" = r, tabledata "IC Outbox Transaction" = r;

    layout
    {
        area(content)
        {
            cuegroup(IncomingTransactions)
            {
                Caption = 'Incoming Transactions';
                field(NewIncoming; NewIncomingCount)
                {
                    ApplicationArea = Intercompany;
                    StyleExpr = NewIncomingStyle;
                    Caption = 'New Intercompany Transactions';
                    ToolTip = 'Incoming intercompany transactions not yet accepted.';
                    trigger OnDrillDown()
                    begin
                        ICInboxTransactions.Run();
                    end;
                }
                field(Rejected; RejectedCount)
                {
                    ApplicationArea = Intercompany;
                    StyleExpr = RejectedStyle;
                    Caption = 'Rejected Intercompany Transactions by Partner Companies';
                    ToolTip = 'Incoming rejections from other partner companies.';
                    trigger OnDrillDown()
                    begin
                        ICInboxTransactions.Run();
                    end;
                }
            }
            cuegroup(OutgoingTransactions)
            {
                Caption = 'Outgoing Transactions';
                field(ToSend; ToSendCount)
                {
                    ApplicationArea = Intercompany;
                    StyleExpr = ToSendStyle;
                    Caption = 'Intercompany Transactions to Send';
                    ToolTip = 'Outgoing transactions to be sent.';
                    trigger OnDrillDown()
                    begin
                        ICOutboxTransactions.Run();
                    end;
                }
            }
        }
    }

    var
        ICInboxTransactions: Page "IC Inbox Transactions";
        ICOutboxTransactions: Page "IC Outbox Transactions";
        NewIncomingCount: Integer;
        ToSendCount: Integer;
        RejectedCount: Integer;
        NewIncomingStyle: Text;
        ToSendStyle: Text;
        RejectedStyle: Text;

    trigger OnOpenPage()
    var
        ICInboxTransaction: Record "IC Inbox Transaction";
        ICOutboxTransaction: Record "IC Outbox Transaction";
        TotalInbox: Integer;
    begin
        ICInboxTransaction.ReadIsolation(IsolationLevel::ReadUncommitted);
        TotalInbox := ICInboxTransaction.Count();

        if TotalInbox <> 0 then begin
            ICInboxTransaction.SetRange("Transaction Source", ICInboxTransaction."Transaction Source"::"Returned by Partner");
            RejectedCount := ICInboxTransaction.Count();
        end else
            RejectedCount := 0;

        NewIncomingCount := TotalInbox - RejectedCount;

        ICOutboxTransaction.ReadIsolation(IsolationLevel::ReadUncommitted);
        ToSendCount := ICOutboxTransaction.Count();

        SetStyle(NewIncomingCount, NewIncomingStyle);
        SetStyle(ToSendCount, ToSendStyle);
        SetStyle(RejectedCount, RejectedStyle);
    end;

    local procedure SetStyle(TransactionsCount: Integer; var Style: Text)
    begin
        if TransactionsCount <> 0 then
            Style := 'Unfavorable'
        else
            Style := 'Favorable';
    end;

}
