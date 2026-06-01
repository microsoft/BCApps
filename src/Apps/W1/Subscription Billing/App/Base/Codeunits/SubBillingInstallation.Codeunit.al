namespace Microsoft.SubscriptionBilling;

using Microsoft.Foundation.Company;
using System.Upgrade;

codeunit 8051 "Sub. Billing Installation"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        ServiceContractSetup: Record "Subscription Contract Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        ServiceContractSetup.InitRecord();
        UpgradeTag.SetAllUpgradeTags();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", OnCompanyInitialize, '', false, false)]
    local procedure OnCompanyInitialize()
    var
        ServiceContractSetup: Record "Subscription Contract Setup";
    begin
        ServiceContractSetup.InitRecord();
    end;
}
