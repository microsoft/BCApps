#pragma warning disable AA0247
#if not CLEAN30
#pragma warning disable AA0247
codeunit 104100 "Upg Local Functionality"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteReason = 'Obsolete schema migration code has been removed.';
    ObsoleteTag = '30.0';

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
    end;

    procedure SetReportSelectionForGLVATReconciliation()
    begin
    end;

    procedure SetReportSelectionForVATStatementSchedule()
    begin
    end;

    procedure SetReportSelectionForIssuedDeliveryReminder()
    begin
    end;

    procedure SetReportSelectionForDeliveryReminderTest()
    begin
    end;

    procedure UpdateVendorRegistrationNo()
    begin
    end;
}
#endif
