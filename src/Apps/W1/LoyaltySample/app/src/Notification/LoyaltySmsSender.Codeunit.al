namespace Microsoft.Sample.Loyalty;

codeunit 50104 "Loyalty SMS Sender" implements INotificationSender
{
    Access = Internal;

    procedure Send(Recipient: Text; Body: Text)
    begin
        // Dispatches the message to the SMS channel.
    end;
}
