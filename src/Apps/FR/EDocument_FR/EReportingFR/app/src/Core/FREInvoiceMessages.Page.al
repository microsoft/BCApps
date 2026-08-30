// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;

page 10973 "FR E-Invoice Messages"
{
    ApplicationArea = Basic, Suite;
    Caption = 'French E-Invoice Lifecycle';
    PageType = List;
    SourceTable = "FR E-Invoice Message";
    SourceTableView = sorting("Entry No.") order(descending);
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(Messages)
            {
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the French lifecycle status represented by this message.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment amount reported by a collected or negative collected message.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of the reported payment amount.';
                }
                field("Event Date"; Rec."Event Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the business date on which the lifecycle event occurred.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code supplied for the lifecycle status.';
                }
                field("Reason Description"; Rec."Reason Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason description supplied for the lifecycle status.';
                }
                field("Source Occurrence ID"; Rec."Source Occurrence ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the immutable source identifier used to prevent duplicate lifecycle messages.';
                }
                field("Original Entry No."; Rec."Original Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original collected message reversed by a negative collected message.';
                }
                field("E-Document Message Entry No."; Rec."E-Document Message Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the related generic E-Document message entry.';
                }
                field(MessageStatus; MessageStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Processing Status';
                    ToolTip = 'Specifies the processing status of the related E-Document message.';
                }
                field(MessageRetryCount; MessageRetryCount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Retry Count';
                    ToolTip = 'Specifies how many background processing attempts have failed for the related E-Document message.';
                }
                field(MessageLastError; MessageLastError)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Last Error';
                    ToolTip = 'Specifies the error returned by the most recent failed processing attempt.';
                }
                field("External Message ID"; Rec."External Message ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the identifier assigned to an incoming lifecycle message by the external service.';
                }
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the incoming lifecycle message was received.';
                }
                field("Sender Platform ID"; Rec."Sender Platform ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the frozen identifier of the sender platform.';
                }
                field("Sender Platform Scheme"; Rec."Sender Platform Scheme")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the frozen identifier scheme of the sender platform.';
                }
                field("Sender Platform Name"; Rec."Sender Platform Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the frozen name of the sender platform.';
                }
                field("Invoice Issue Date"; Rec."Invoice Issue Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the frozen issue date of the invoice.';
                }
                field("Invoice Receipt At"; Rec."Invoice Receipt At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the frozen date and time when the sender platform received the invoice.';
                }
                field("Invoice Issuer ID"; Rec."Invoice Issuer ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the frozen SIREN identifier of the invoice issuer.';
                }
                field("Invoice Issuer Scheme"; Rec."Invoice Issuer Scheme")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the frozen identifier scheme of the invoice issuer.';
                }
                field("Invoice Issuer Name"; Rec."Invoice Issuer Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the frozen name of the invoice issuer.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the French lifecycle message was created.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Retry)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Retry';
                Enabled = RetryEnabled;
                Image = Refresh;
                Scope = Repeater;
                ToolTip = 'Retry the failed lifecycle message transmission or response polling operation using its existing payload.';

                trigger OnAction()
                var
                    EDocumentMessageAPI: Codeunit "E-Document Message API";
                begin
                    EDocumentMessageAPI.RetryMessage(Rec."E-Document Message Entry No.");
                    CurrPage.Update(false);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        LoadMessageState();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        LoadMessageState();
    end;

    var
        MessageStatus: Enum "E-Doc. Message Status";
        MessageLastError: Text[2048];
        MessageRetryCount: Integer;
        RetryEnabled: Boolean;

    local procedure LoadMessageState()
    var
        EDocumentMessage: Record "E-Document Message";
    begin
        Clear(MessageStatus);
        Clear(MessageLastError);
        Clear(MessageRetryCount);
        RetryEnabled := false;
        if (Rec."E-Document Message Entry No." = 0) or not EDocumentMessage.Get(Rec."E-Document Message Entry No.") then
            exit;

        MessageStatus := EDocumentMessage.Status;
        MessageLastError := EDocumentMessage."Last Error";
        MessageRetryCount := EDocumentMessage."Retry Count";
        RetryEnabled := (EDocumentMessage.Direction = EDocumentMessage.Direction::Outgoing) and
            (EDocumentMessage.Status in [EDocumentMessage.Status::Error, EDocumentMessage.Status::"Response Error"]);
    end;
}