namespace Microsoft.Sample.Loyalty;

enum 50101 "Loyalty Channel" implements INotificationSender
{
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; Email)
    {
        Caption = 'Email';
        Implementation = INotificationSender = "Loyalty Email Sender";
    }
    value(2; SMS)
    {
        Caption = 'SMS';
        Implementation = INotificationSender = "Loyalty SMS Sender";
    }
}
