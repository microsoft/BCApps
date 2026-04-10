codeunit 132496 MockOnPostNotificationRequest
{
    EventSubscriberInstance = Manual;
    SingleInstance = false;

    trigger OnRun()
    begin
    end;

    var
        ReturnType: Text;
        ReceivedErr: Label 'abc';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Webhook Notification", 'OnPostNotificationRequest', '', false, false)]
    [TryFunction]
    [Normal]
    [Scope('OnPrem')]
    procedure MockOnPostNotificationRequest(var Sender: Codeunit "Workflow Webhook Notification"; DataID: Guid; WorkflowStepInstanceID: Guid; NotificationUrl: Text)
    var
        HttpWebRequest: DotNet HttpWebRequest;
        HttpWebResponse: DotNet HttpWebResponse;
    begin
        case ReturnType of
            'NoErrorReceived':
                exit;
            'ErrorReceived':
                Error(ReceivedErr);
            'ErrorSuccess':
                begin
                    if Sender.GetCurrentRetryCounter() = 1 then
                        Error(ReceivedErr);
                    exit;
                end;
            'DotNetException':
                HttpWebRequest := HttpWebRequest.Create('d');
            'WebException':
                if Sender.GetCurrentRetryCounter() = 1 then begin
                    HttpWebRequest := HttpWebRequest.Create('https://www.bingsdf.com');
                    HttpWebRequest.Method := 'POST';
                    HttpWebRequest.ContentType('application/json');
                    HttpWebResponse := HttpWebRequest.GetResponse();
                    HttpWebResponse.Close(); // close connection
                    HttpWebResponse.Dispose(); // cleanup of IDisposable
                end else
                    exit;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetReturnType(Value: Text)
    begin
        ReturnType := Value;
    end;
}

