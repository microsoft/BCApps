// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Read-only detail view for a single LLM log entry. Shows the full system prompt,
/// user payload, raw response, and extracted reply.
/// </summary>
page 8434 "Perf. Analysis LLM Log Card"
{
    Caption = 'Performance Analysis LLM Log';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "Perf. Analysis LLM Log";
    Editable = false;
    Permissions = tabledata "Perf. Analysis LLM Log" = R;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                Caption = 'Call';
                field("Entry No."; Rec."Entry No.") { ApplicationArea = All; ToolTip = 'Specifies the unique entry number.'; }
                field("Logged At"; Rec."Logged At") { ApplicationArea = All; ToolTip = 'Specifies when the LLM call was made.'; }
                field("Purpose"; Rec."Purpose") { ApplicationArea = All; ToolTip = 'Specifies which Performance Center AI entry point produced this call.'; }
                field("Analysis Id"; Rec."Analysis Id") { ApplicationArea = All; ToolTip = 'Specifies the Performance Analysis that triggered this call.'; }
                field("Success"; Rec."Success") { ApplicationArea = All; ToolTip = 'Specifies whether the call succeeded.'; }
                field("Status Code"; Rec."Status Code") { ApplicationArea = All; ToolTip = 'Specifies the HTTP status code returned by the AOAI endpoint.'; }
                field("Duration (ms)"; Rec."Duration (ms)") { ApplicationArea = All; ToolTip = 'Specifies the round-trip duration of the LLM call in milliseconds.'; }
                field("Error Text"; Rec."Error Text") { ApplicationArea = All; ToolTip = 'Specifies the error message returned by the AOAI endpoint, if any.'; MultiLine = true; }
            }
            group(RawRequestGroup)
            {
                Caption = 'Raw request';
                field(RawRequestCtl; RawRequestTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Raw request';
                    ShowCaption = false;
                    MultiLine = true;
                }
            }
            group(RawResponseGroup)
            {
                Caption = 'Raw response (AOAI Operation Response Result)';
                field(RawResponseCtl; RawResponseTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Raw response';
                    ShowCaption = false;
                    MultiLine = true;
                }
            }
            group(ReplyGroup)
            {
                Caption = 'Extracted reply';
                field(ReplyCtl; ReplyTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Reply';
                    ShowCaption = false;
                    MultiLine = true;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        RawRequestTxt := Rec.GetRawRequestText();
        ReplyTxt := Rec.GetReplyText();
        RawResponseTxt := Rec.GetRawResponseText();
    end;

    var
        RawRequestTxt: Text;
        ReplyTxt: Text;
        RawResponseTxt: Text;
}
