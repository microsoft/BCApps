#if CLEAN28
namespace Microsoft.SubscriptionBilling.PowerBIReports;

using Microsoft.PowerBIReports;

tableextension 8011 "Power BI Setup SubBilling" extends "PowerBI Reports Setup"
{
    fields
    {
        field(37000; "Subs. Billing Report Name"; Text[200])
        {
            Caption = 'Subscription Billing Report Name';
            DataClassification = CustomerContent;
            MovedFrom = 'e4e86220-cac0-4ec3-b853-7c2fa610399d';
        }
        field(37001; "Subscription Billing Report Id"; Guid)
        {
            Caption = 'Subscription Billing Report Id';
            DataClassification = CustomerContent;
            MovedFrom = 'e4e86220-cac0-4ec3-b853-7c2fa610399d';
        }
    }
}
#endif