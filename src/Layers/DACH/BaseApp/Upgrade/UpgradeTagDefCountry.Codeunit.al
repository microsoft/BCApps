#pragma warning disable AA0247
codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetReportSelectionForGLVATReconciliationTag());
        PerCompanyUpgradeTags.Add(GetReportSelectionForVATStatementScheduleTag());
        PerCompanyUpgradeTags.Add(GetReportSelectionForIssuedDeliveryReminderTag());
        PerCompanyUpgradeTags.Add(GetReportSelectionForDeliveryReminderTestTag());
        PerCompanyUpgradeTags.Add(GetPhysInvntOrdersUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCleanupPhysOrders());
    end;

    procedure GetPhysInvntOrdersUpgradeTag(): Code[250]
    begin
        exit('302317-PhysInvntOrders-20192702');
    end;

    procedure GetReportSelectionForGLVATReconciliationTag(): Code[250]
    begin
        exit('MS-306584-GLVATReconciliation-20190403');
    end;

    procedure GetReportSelectionForVATStatementScheduleTag(): Code[250]
    begin
        exit('MS-306585-VATStatementSchedule-20250422');
    end;

    procedure GetReportSelectionForIssuedDeliveryReminderTag(): Code[250]
    begin
        exit('MS-306586-IssuedDeliveryReminder-20250422');
    end;

    procedure GetReportSelectionForDeliveryReminderTestTag(): Code[250]
    begin
        exit('MS-306587-DeliveryReminderTest-20250422');
    end;

    procedure GetCleanupPhysOrders(): Code[250]
    begin
        exit('MS-327839-CleanupPhysOrders-20191007');
    end;

    procedure GetVendorRegistrationNoTag(): Code[250]
    begin
        exit('MS-359959-GetVendorRegistrationNo-20230208');
    end;
}

