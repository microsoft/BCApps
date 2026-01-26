#pragma warning disable AA0247
codeunit 104100 "Upg Local Functionality"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

#if not CLEAN27
        SetReportSelectionForGLVATReconciliation();
        SetReportSelectionForVATStatementSchedule();
        SetReportSelectionForIssuedDeliveryReminder();
        SetReportSelectionForDeliveryReminderTest();
#endif
        UpdateVendorRegistrationNo();
    end;

#if not CLEAN27
    [Obsolete('Replaced by ReportSelections table setup', '25.0')]
    procedure SetReportSelectionForGLVATReconciliation()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportSelections: Record "Report Selections";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        ReportID: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForGLVATReconciliationTag()) then
            exit;

        DACHReportSelections.SetRange(Usage, DACHReportSelections.Usage::"Sales VAT Acc. Proof");
        if DACHReportSelections.FindFirst() then
            ReportID := DACHReportSelections."Report ID"
        else
            ReportID := 11;

        if ReportSelections.Get(ReportSelections.Usage::"Sales VAT Acc. Proof", '1') then begin
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Modify();
        end else begin
            ReportSelections.Init();
            ReportSelections.Usage := ReportSelections.Usage::"Sales VAT Acc. Proof";
            ReportSelections.Sequence := '1';
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Insert();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForGLVATReconciliationTag());
    end;
#endif

#if not CLEAN27
    [Obsolete('Replaced by ReportSelections table setup', '27.0')]
    procedure SetReportSelectionForVATStatementSchedule()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportSelections: Record "Report Selections";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        ReportID: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForVATStatementScheduleTag()) then
            exit;

        DACHReportSelections.SetRange(Usage, DACHReportSelections.Usage::"VAT Statement Schedule");
        if DACHReportSelections.FindFirst() then
            ReportID := DACHReportSelections."Report ID"
        else
            ReportID := Report::"VAT Statement Schedule";

        if ReportSelections.Get(ReportSelections.Usage::"VAT Statement Schedule", '1') then begin
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Modify();
        end else begin
            ReportSelections.Init();
            ReportSelections.Usage := ReportSelections.Usage::"VAT Statement Schedule";
            ReportSelections.Sequence := '1';
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Insert();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForVATStatementScheduleTag());
    end;
#endif

#if not CLEAN27
    [Obsolete('Replaced by ReportSelections table setup', '27.0')]
    procedure SetReportSelectionForIssuedDeliveryReminder()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportSelections: Record "Report Selections";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        ReportID: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForIssuedDeliveryReminderTag()) then
            exit;

        DACHReportSelections.SetRange(Usage, DACHReportSelections.Usage::"Issued Delivery Reminder");
        if DACHReportSelections.FindFirst() then
            ReportID := DACHReportSelections."Report ID"
        else
            ReportID := Report::"Issued Delivery Reminder";

        if ReportSelections.Get(ReportSelections.Usage::"Issued Delivery Reminder", '1') then begin
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Modify();
        end else begin
            ReportSelections.Init();
            ReportSelections.Usage := ReportSelections.Usage::"Issued Delivery Reminder";
            ReportSelections.Sequence := '1';
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Insert();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForIssuedDeliveryReminderTag());
    end;
#endif

#if not CLEAN27
    [Obsolete('Replaced by ReportSelections table setup', '27.0')]
    procedure SetReportSelectionForDeliveryReminderTest()
    var
        DACHReportSelections: Record "DACH Report Selections";
        ReportSelections: Record "Report Selections";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        ReportID: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForDeliveryReminderTestTag()) then
            exit;

        DACHReportSelections.SetRange(Usage, DACHReportSelections.Usage::"Delivery Reminder Test");
        if DACHReportSelections.FindFirst() then
            ReportID := DACHReportSelections."Report ID"
        else
            ReportID := Report::"Delivery Reminder - Test";

        if ReportSelections.Get(ReportSelections.Usage::"Delivery Reminder Test", '1') then begin
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Modify();
        end else begin
            ReportSelections.Init();
            ReportSelections.Usage := ReportSelections.Usage::"Delivery Reminder Test";
            ReportSelections.Sequence := '1';
            ReportSelections."Report ID" := ReportID;
            ReportSelections.Insert();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetReportSelectionForDeliveryReminderTestTag());
    end;
#endif

    procedure UpdateVendorRegistrationNo()
    var
        Vendor: Record Vendor;
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
        VendorDataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetVendorRegistrationNoTag()) then
            exit;

        VendorDataTransfer.SetTables(Database::Vendor, Database::Vendor);
        VendorDataTransfer.AddFieldValue(Vendor.FieldNo("Registration No."), Vendor.FieldNo("Registration Number"));
        VendorDataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetVendorRegistrationNoTag());
    end;
}
