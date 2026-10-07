// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument.Processing.Message;

page 10970 "E-Document Payment Occurrences"
{
    ApplicationArea = Basic, Suite;
    Caption = 'E-Document Payment Occurrences';
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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry number of the payment occurrence.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether the payment was applied or reversed.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the payment occurrence.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code of the payment occurrence.';
                }
                field("Event Date"; Rec."Event Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posting date of the payment application or reversal.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StatusStyle;
                    ToolTip = 'Specifies the processing status of the payment occurrence.';
                }
                field("Last Error"; Rec."Last Error")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the error from the latest processing attempt.';
                }
                field("Retry Count"; Rec."Retry Count")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of failed processing attempts.';
                }
                field("Last Attempt At"; Rec."Last Attempt At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the payment occurrence was last processed.';
                }
                field("Next Attempt At"; Rec."Next Attempt At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when automatic processing can next retry the payment occurrence.';
                }
                field("Detailed Ledger Entry No."; Rec."Detailed Ledger Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the detailed customer ledger entry that created the payment occurrence.';
                }
                field("Source Occurrence ID"; Rec."Source Occurrence ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unique identifier of the source payment application or reversal.';
                }
                field("Original Occurrence Entry No."; Rec."Original Occurrence Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original applied occurrence that this reversal refers to.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = Basic, Suite;
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
                ApplicationArea = Basic, Suite;
                Caption = 'Retry Now';
                Enabled = Rec.Status = Rec.Status::Error;
                Image = Refresh;
                ToolTip = 'Retry processing the selected payment occurrence immediately.';

                trigger OnAction()
                begin
                    Codeunit.Run(Codeunit::"E-Doc. Payment Occurrence Mgt.", Rec);
                    CurrPage.Update(false);
                end;
            }
        }

        area(Promoted)
        {
            actionref(RetryNowPromoted; RetryNow)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StatusStyle := GetStatusStyle();
    end;

    local procedure GetStatusStyle(): Text
    begin
        case Rec.Status of
            Rec.Status::Processed:
                exit('Favorable');
            Rec.Status::Error:
                exit('Unfavorable');
            Rec.Status::Processing:
                exit('Attention');
            else
                exit('Ambiguous');
        end;
    end;

    var
        StatusStyle: Text;
}
