namespace Microsoft.CRM.Outlook;

enum 7120 "ContactSyncDirection"
{
    value(0; "Sync from BC to M365")
    {
        Caption = 'Only Outlook';
    }
    value(1; "Full Sync")
    {
        Caption = 'Business Central and Outlook';
    }
}