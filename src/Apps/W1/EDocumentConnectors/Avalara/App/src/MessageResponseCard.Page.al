/// <summary>
/// Displays message response data from Avalara API.
/// Read-only diagnostic page showing message status and events.
/// </summary>
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
page 6380 "Message Response Card"
{
    ApplicationArea = All;
    Caption = 'Message Response';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Message Response Header";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(id; Rec.id)
                {
                    ApplicationArea = All;
                    Caption = 'Message ID';
                    ToolTip = 'Specifies the unique identifier for the message from Avalara.';
                }
                field(companyId; Rec.companyId)
                {
                    ApplicationArea = All;
                    Caption = 'Company ID';
                    ToolTip = 'Specifies the company identifier in the Avalara system.';
                }
                field(status; Rec.status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the current processing status of the message.';
                }
            }

            part(Events; "Message Events Subform")
            {
                ApplicationArea = All;
                SubPageLink = id = field(id);
            }
        }
    }

    var
        EmptyResponseErr: Label 'Response text cannot be empty.';

    /// <summary>
    /// Loads API response data into the page from JSON text.
    /// </summary>
    /// <param name="ResponseText">JSON text containing the API response.</param>
    /// <param name="EDocument">The E-Document record to associate with the response.</param>
    procedure SetResponse(ResponseText: Text; EDocument: Record "E-Document")
    var
        Processing: Codeunit Processing;
    begin
        if ResponseText = '' then
            Error(EmptyResponseErr);

        Processing.LoadStatusFromJson(ResponseText, EDocument);
    end;
}
