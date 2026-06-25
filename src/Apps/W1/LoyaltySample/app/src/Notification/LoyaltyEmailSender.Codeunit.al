namespace Microsoft.Sample.Loyalty;

codeunit 50103 "Loyalty Email Sender" implements INotificationSender
{
    Access = Internal;

    procedure Send(Recipient: Text; Body: Text)
    begin
        // Dispatches the message to the e-mail channel.
    end;
}
