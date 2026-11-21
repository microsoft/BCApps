// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura;

using Microsoft.eServices.EDocument.Processing.Message;

page 3357 "E-Doc. Payment Occurrences MX"
{
    ApplicationArea = All;
    Caption = 'CFDI Payment Complement Occurrences';
    PageType = List;
    SourceTable = "E-Doc. Payment Occurrence";
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
            repeater(Occurrences)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number of the payment occurrence.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the payment was applied or reversed.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount of the payment occurrence.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency code of the payment occurrence.';
                }
                field("Event Date"; Rec."Event Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the posting date of the payment application or reversal.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                    ToolTip = 'Specifies the processing status of the payment occurrence.';
                }
                field("Last Error"; Rec."Last Error")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the error from the latest processing attempt.';
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of failed processing attempts.';
                }
                field("Last Attempt At"; Rec."Last Attempt At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the payment occurrence was last processed.';
                }
                field("Next Attempt At"; Rec."Next Attempt At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when automatic processing can next retry the payment occurrence.';
                }
                field("Detailed Ledger Entry No."; Rec."Detailed Ledger Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the detailed customer ledger entry that created the payment occurrence.';
                }
                field("Source Occurrence ID"; Rec."Source Occurrence ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the unique identifier of the source payment application or reversal.';
                }
                field("Original Occurrence Entry No."; Rec."Original Occurrence Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the original applied occurrence that this reversal refers to.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the payment occurrence was created.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RetryNow)
            {
                ApplicationArea = All;
                Caption = 'Retry now';
                Enabled = RetryEnabled;
                Image = Refresh;
                Scope = Repeater;
                ToolTip = 'Retry processing the selected payment occurrence immediately.';

                trigger OnAction()
                var
                    EDocPaymentOccurrenceMgt: Codeunit "E-Doc. Payment Occurrence Mgt.";
                begin
                    EDocPaymentOccurrenceMgt.RetryPaymentOccurrence(Rec."Entry No.");
                    CurrPage.Update(false);
                end;
            }
        }

        area(Promoted)
        {
            actionref(RetryNowPromoted; RetryNow) { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StatusStyle := GetStatusStyle();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        RetryEnabled := Rec.Status in [Rec.Status::Error, Rec.Status::"Retry Pending"];
    end;

    local procedure GetStatusStyle(): Text
    begin
        case Rec.Status of
            Rec.Status::Processed:
                exit('Favorable');
            Rec.Status::Error:
                exit('Unfavorable');
            Rec.Status::Processing,
            Rec.Status::"Retry Pending":
                exit('Attention');
            else
                exit('Ambiguous');
        end;
    end;

    var
        RetryEnabled: Boolean;
        StatusStyle: Text;
}