namespace Microsoft.API.Webhooks;

using Microsoft.Utilities;

page 5461 "API Webhook Logs"
{
    APIGroup = 'runtime';
    APIPublisher = 'microsoft';
    Caption = 'webhookLogs', Locked = true;
    DelayedInsert = true;
    DeleteAllowed = false;
    Editable = false;
    EntityName = 'webhookLog';
    EntitySetName = 'webhookLogs';
    Extensible = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = ID;
    PageType = API;
    SourceTable = "Activity Log";
    SourceTableView = sorting("Activity Date")
                      order(descending)
                      where("Table No Filter" = const(2000000095),
                            Context = const('APIWEBHOOK'));

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(id; Rec.ID)
                {
                    ApplicationArea = All;
                    Caption = 'ID', Locked = true;
                    ToolTip = 'Specifies the activity ID.';
                }
                field(time; Rec."Activity Date")
                {
                    ApplicationArea = All;
                    Caption = 'time', Locked = true;
                    ToolTip = 'Specifies the activity time.';
                }
                field(status; Rec.Status)
                {
                    ApplicationArea = All;
                    Caption = 'status', Locked = true;
                    ToolTip = 'Specifies the activity status.';
                }
                field(message; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'message', Locked = true;
                    ToolTip = 'Specifies the activity message.';
                }
                field(details; Details)
                {
                    ApplicationArea = All;
                    Caption = 'details', Locked = true;
                    ToolTip = 'Specifies the activity details.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    var
        ContentInStream: InStream;
        TextLine: Text;
    begin
        if not Rec."Detailed Info".HasValue() then
            Details := Rec."Activity Message"
        else begin
            Details := '';
            Rec."Detailed Info".CreateInStream(ContentInStream);
            while not ContentInStream.EOS() do begin
                ContentInStream.ReadText(TextLine);
                Details += TextLine;
            end;
        end
    end;

    trigger OnOpenPage()
    begin
        Rec.SetAutoCalcFields("Detailed Info");
    end;

    var
        Details: Text;
}

