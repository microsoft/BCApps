namespace Microsoft.Sample.Loyalty;

interface INotificationSender
{
    procedure Send(Recipient: Text; Body: Text)
}
