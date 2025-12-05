namespace Microsoft.SubscriptionBilling;

using System.Security.User;

tableextension 8012 "User Setup" extends "User Setup"
{
    fields
    {
        field(8000; "Auto Contract Billing"; Boolean)
        {
            Caption = 'Auto Contract Billing';
            ToolTip = 'Specifies, whether the user can automate contract billing. It allows to work with and edit automated Billing Templates.';
            DataClassification = SystemMetadata;
        }
    }
    internal procedure AutoContractBillingAllowed(): Boolean
    begin
        if Get(UserId()) then
            exit("Auto Contract Billing")
        else
            exit(false);
    end;
}
