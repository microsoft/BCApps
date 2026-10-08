// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.DataExchange;

page 679 "IC API Log Entry"
{
    Caption = 'IC API Log Entry';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "IC API Log";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the unique identifier of the log entry.';
                }
                field("Created at"; Rec.SystemCreatedAt)
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Created at';
                    ToolTip = 'Specifies the date and time when the log entry was created.';
                }
                field("IC Partner Code"; Rec."IC Partner Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the intercompany partner code related to this API call.';
                }
                field(Direction; Rec.Direction)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies whether this was an outgoing or incoming API call.';
                }
                field(Method; Rec.Method)
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the HTTP method used for the API call.';
                }
                field("Status Code"; Rec."Status Code")
                {
                    ApplicationArea = Intercompany;
                    ToolTip = 'Specifies the HTTP status code returned by the API call.';
                }
            }
            group(RequestGroup)
            {
                Caption = 'Request';
                field(RequestURI; Rec.GetRequestURIAsText())
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Request URI';
                    MultiLine = true;
                    ToolTip = 'Specifies the full URI of the API request.';
                }
                field(RequestBody; Rec.GetRequestBodyAsText())
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Request Body';
                    MultiLine = true;
                    ToolTip = 'Specifies the JSON body sent in the API request.';
                }
            }
            group(ResponseGroup)
            {
                Caption = 'Response';
                field(ResponseBody; Rec.GetResponseBodyAsText())
                {
                    ApplicationArea = Intercompany;
                    Caption = 'Response Body';
                    MultiLine = true;
                    ToolTip = 'Specifies the JSON body received in the API response.';
                }
            }
        }
    }
}
