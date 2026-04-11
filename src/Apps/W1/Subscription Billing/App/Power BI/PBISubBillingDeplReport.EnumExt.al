namespace Microsoft.SubscriptionBilling;
using System.Integration.PowerBI;

enumextension 8103 "PBI Sub. Billing Depl. Report" extends "Power BI Deployable Report"
{
    value(8101; "Subscription Billing App")
    {
        Caption = 'Subscription Billing';
        Implementation = "Power BI Deployable Report" = "PBI Sub. Billing App";
    }
}
