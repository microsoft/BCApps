codeunit 101981 "Create D365 Permission Sets"
{
    // This codeunit contains D365 permission sets that will be released as part of our SaaS offering.
    // This codeunit should not have any local modifications, for localized permission sets, see COD101982.
    //
    // Before modifying this file there are some things you should be aware of:
    // - You should always add your permissions to more than just the full permission set.
    // - All permissions you add must also exist in the D365 Full permission set with at least the same level of permissions (SNAP gate)
    // - The permission sets has the following hiearchy (SNAP gate):
    //
    // "D365 Sales Doc, Edit" (part of) "D365 Sales Doc, Post" (part of) "D365 Acc. Receivable"
    // "D365 Purch Doc, Edit" (part of) "D365 Purch Doc, Post" (part of) "D365 Acc. Payable"
    // "D365 Vendor, Edit", "D365 Customer, Edit" and "D365 Item" (part of) "D365 Setup"
    // "D365 Journals, Edit" (part of) "D365 Journals, Post" (part of) (D365 Acc. Receivable and D365 Acc. Payable)
    // "D365 Vendor, View" (part of) "D365 Vendor, Edit"
    // "D365 Customer, View" (part of) "D365 Customer, Edit"
    //
    // This means if a permission exists in "D365 Sales Doc, Edit" then it must also exist in
    // "D365 Sales Doc, Post" and "D365 Acc. Receivable" with the same permissions (and of course also in D365 Full Access)
    // Please keep alphabetical order of permissions within one permission set.

    var
        FullTok: Label 'D365 FULL ACCESS', Locked = true;
        BusFullTok: Label 'D365 BUS FULL ACCESS', Locked = true;
        PremiumBusFullTok: Label 'D365 BUS PREMIUM', Locked = true;
        ExtenMgtAdminTok: Label 'Exten. Mgt. - Admin', Locked = true;
        D365MonitorFields: Label 'D365 Monitor Fields', Locked = true;
        CustomerViewTok: Label 'D365 CUSTOMER, VIEW', Locked = true;
        CustomerEditTok: Label 'D365 CUSTOMER, EDIT', Locked = true;
        ItemViewTok: Label 'D365 ITEM, VIEW', Locked = true;
        ItemEditTok: Label 'D365 ITEM, EDIT', Locked = true;
        SalesDocCreateTok: Label 'D365 SALES DOC, EDIT', Locked = true;
        SalesDocPostTok: Label 'D365 SALES DOC, POST', Locked = true;
        BasicTok: Label 'D365 BASIC', Locked = true;
        SetupTok: Label 'D365 SETUP', Locked = true;
        AccountsReceivableTok: Label 'D365 ACC. RECEIVABLE', Locked = true;
        BankingTok: Label 'D365 BANKING', Locked = true;
        FinancialReportsTok: Label 'D365 FINANCIAL REP.', Locked = true;
        JournalsEditTok: Label 'D365 JOURNALS, EDIT', Locked = true;
        JournalsPostTok: Label 'D365 JOURNALS, POST', Locked = true;
        AccountsPayableTok: Label 'D365 ACC. PAYABLE', Locked = true;
        VendorViewTok: Label 'D365 VENDOR, VIEW', Locked = true;
        VendorEditTok: Label 'D365 VENDOR, EDIT', Locked = true;
        SecurityTok: Label 'SECURITY', Locked = true;
        PurchDocCreateTok: Label 'D365 PURCH DOC, EDIT', Locked = true;
        PurchDocPostTok: Label 'D365 PURCH DOC, POST', Locked = true;
        OppMgtTok: Label 'D365 OPPORTUNITY MGT', Locked = true;
        RMSetupTok: Label 'D365 RM SETUP', Locked = true;
        DynCrmMgtTok: Label 'D365 DYN CRM MGT', Locked = true;
        CashFlowTok: Label 'D365 CASH FLOW', Locked = true;
        FixedAssetsSetupTok: Label 'D365 FA, SETUP', Locked = true;
        FixedAssetsViewTok: Label 'D365 FA, VIEW', Locked = true;
        FixedAssetsEditTok: Label 'D365 FA, EDIT', Locked = true;
        IntercompanyPostingsSetupTok: Label 'D365 IC, SETUP', Locked = true;
        IntercompanyPostingsViewTok: Label 'D365 IC, VIEW', Locked = true;
        IntercompanyPostingsEditTok: Label 'D365 IC, EDIT', Locked = true;
        BasicHumanResoursesSetupTok: Label 'D365 HR, SETUP', Locked = true;
        BasicHumanResoursesViewTok: Label 'D365 HR, VIEW', Locked = true;
        BasicHumanResoursesEditTok: Label 'D365 HR, EDIT', Locked = true;
        TeamMemberTok: Label 'D365 TEAM MEMBER', Locked = true;
        ReadTok: Label 'D365 READ', Locked = true;
        InventorySetupTok: Label 'D365 INV, SETUP', Locked = true;
        InventoryCreateTok: Label 'D365 INV DOC, CREATE', Locked = true;
        InventoryPostTok: Label 'D365 INV DOC, POST', Locked = true;
        RapidStartTok: Label 'D365 RAPIDSTART', Locked = true;
        AssemblyViewTok: Label 'D365 ASSEMBLY, VIEW', Locked = true;
        AssemblyEditTok: Label 'D365 ASSEMBLY, EDIT', Locked = true;
        WebhookSubscriptionTok: Label 'D365 WEBHOOK SUBSCR', Locked = true;
        AccountantPortalTok: Label 'D365 ACCOUNTANTS', Locked = true;
        CompanyHubTok: Label 'D365 COMPANY HUB', Locked = true;
        CostAccountingSetupTok: Label 'D365 COSTACC, SETUP', Locked = true;
        CostAccountingEditTok: Label 'D365 COSTACC, EDIT', Locked = true;
        CostAccountingViewTok: Label 'D365 COSTACC, VIEW', Locked = true;
        GlobalDimMgtTok: Label 'D365 GLOBAL DIM MGT', Locked = true;
        JobsEditTok: Label 'D365 JOBS, EDIT', Locked = true;
        JobsViewTok: Label 'D365 JOBS, VIEW', Locked = true;
        JobsSetupTok: Label 'D365 JOBS, SETUP', Locked = true;
        ServiceManagementSetupTok: Label 'D365PREM SMG, SETUP', Locked = true;
        ServiceManagementViewTok: Label 'D365PREM SMG, VIEW', Locked = true;
        ServiceManagementEditTok: Label 'D365PREM SMG, EDIT', Locked = true;
        IntelligentCloudTok: Label 'INTELLIGENT CLOUD', Locked = true;
        MergeDuplicatesTok: Label 'MERGE DUPLICATES', Locked = true;
        TestToolTok: Label 'TEST TOOL', Locked = true;
        TroubleshootToolsTok: Label 'TROUBLESHOOT TOOLS', Locked = true;
        BackupRestoreDataTok: Label 'D365 BACKUP/RESTORE', Locked = true;
        ExcelExportActionTok: Label 'Edit in Excel - View', Locked = true;
        RetentionPolAdminTok: Label 'Retention Pol. Admin', Locked = true;
        EmailAdminTok: Label 'Email - Admin', Locked = true;
        AutomateActionPermissionSetTok: Label 'Automate - Exec', MaxLength = 20, Locked = true;
        SnapshotDebugTok: Label 'D365 SNAPSHOT DEBUG', Locked = true;
        AutomationTok: Label 'D365 AUTOMATION', MaxLength = 20, Locked = true;
        DimensionCorrectionTok: Label 'D365 DIM CORRECTION', MaxLength = 20, Locked = true;
        ExportReportExcelTok: Label 'Export Report Excel', MaxLength = 20, Locked = true;

    procedure GetD365BusFull(): Code[20]
    begin
        exit(BusFullTok);
    end;

    procedure GetD365Full(): Code[20]
    begin
        exit(FullTok);
    end;

    procedure GetD365GlobalDimMgt(): Code[20]
    begin
        exit(GlobalDimMgtTok);
    end;

    procedure GetD365TeamMember(): Code[20]
    begin
        exit(TeamMemberTok);
    end;

    procedure GetD365Basic(): Code[20]
    begin
        exit(BasicTok);
    end;

    procedure GetD365Read(): Code[20]
    begin
        exit(ReadTok);
    end;

    procedure GetD365ExtensionMgt(): Code[20]
    begin
        exit(ExtenMgtAdminTok);
    end;

    procedure GetD365MonitorFieldChange(): Code[20]
    begin
        exit(D365MonitorFields);
    end;

    procedure GetD365CustomerView(): Code[20]
    begin
        exit(CustomerViewTok);
    end;

    procedure GetD365CustomerEdit(): Code[20]
    begin
        exit(CustomerEditTok);
    end;

    procedure GetD365ItemView(): Code[20]
    begin
        exit(ItemViewTok);
    end;

    procedure GetD365ItemEdit(): Code[20]
    begin
        exit(ItemEditTok);
    end;

    procedure GetD365SalesDocCreate(): Code[20]
    begin
        exit(SalesDocCreateTok);
    end;

    procedure GetD365SalesDocPost(): Code[20]
    begin
        exit(SalesDocPostTok);
    end;

    procedure GetD365Setup(): Code[20]
    begin
        exit(SetupTok);
    end;

    procedure GetD365AccountsReceivable(): Code[20]
    begin
        exit(AccountsReceivableTok);
    end;

    procedure GetD365Banking(): Code[20]
    begin
        exit(BankingTok);
    end;

    procedure GetD365FinancialReports(): Code[20]
    begin
        exit(FinancialReportsTok);
    end;

    procedure GetD365JournalsEdit(): Code[20]
    begin
        exit(JournalsEditTok);
    end;

    procedure GetD365JournalsPost(): Code[20]
    begin
        exit(JournalsPostTok);
    end;

    procedure GetD365AccountsPayable(): Code[20]
    begin
        exit(AccountsPayableTok);
    end;

    procedure GetD365VendorView(): Code[20]
    begin
        exit(VendorViewTok);
    end;

    procedure GetD365VendorEdit(): Code[20]
    begin
        exit(VendorEditTok);
    end;

    procedure GetD365Security(): Code[20]
    begin
        exit(SecurityTok);
    end;

    procedure GetD365PurchDocCreate(): Code[20]
    begin
        exit(PurchDocCreateTok);
    end;

    procedure GetD365PurchDocPost(): Code[20]
    begin
        exit(PurchDocPostTok);
    end;

    procedure GetD365OppManagement(): Code[20]
    begin
        exit(OppMgtTok);
    end;

    procedure GetD365RMSetup(): Code[20]
    begin
        exit(RMSetupTok);
    end;

    procedure GetD365DynCrmMgt(): Code[20]
    begin
        exit(DynCrmMgtTok);
    end;

    procedure GetD365CashFlow(): Code[20]
    begin
        exit(CashFlowTok);
    end;

    procedure GetD365FixedAssetsSetup(): Code[20]
    begin
        exit(FixedAssetsSetupTok);
    end;

    procedure GetD365FixedAssetsView(): Code[20]
    begin
        exit(FixedAssetsViewTok);
    end;

    procedure GetD365FixedAssetsEdit(): Code[20]
    begin
        exit(FixedAssetsEditTok);
    end;

    procedure GetD365BasicHumanResoursesSetup(): Code[20]
    begin
        exit(BasicHumanResoursesSetupTok);
    end;

    procedure GetD365BasicHumanResoursesView(): Code[20]
    begin
        exit(BasicHumanResoursesViewTok);
    end;

    procedure GetD365BasicHumanResoursesEdit(): Code[20]
    begin
        exit(BasicHumanResoursesEditTok);
    end;

    procedure GetD365InventorySetup(): Code[20]
    begin
        exit(InventorySetupTok);
    end;

    procedure GetD365InventoryCreate(): Code[20]
    begin
        exit(InventoryCreateTok);
    end;

    procedure GetD365InventoryPost(): Code[20]
    begin
        exit(InventoryPostTok);
    end;

    procedure GetD365RapidStart(): Code[20]
    begin
        exit(RapidStartTok);
    end;

    procedure GetD365AssemblyView(): Code[20]
    begin
        exit(AssemblyViewTok);
    end;

    procedure GetD365AssemblyEdit(): Code[20]
    begin
        exit(AssemblyEditTok);
    end;

    procedure GetD365WebhookSubscription(): Code[20]
    begin
        exit(WebhookSubscriptionTok);
    end;

    procedure GetD365Accountants(): Code[20]
    begin
        exit(AccountantPortalTok);
    end;

    procedure GetD365CompanyHub(): Code[20]
    begin
        exit(CompanyHubTok);
    end;

    procedure GetD365PremiumBusFull(): Code[20]
    begin
        exit(PremiumBusFullTok);
    end;

    procedure GetD365ICPostingsSetup(): Code[20]
    begin
        exit(IntercompanyPostingsSetupTok);
    end;

    procedure GetD365ICPostingsView(): Code[20]
    begin
        exit(IntercompanyPostingsViewTok);
    end;

    procedure GetExportReportDatasetToExcelPermissionSetName(): Code[20]
    begin
        exit(ExportReportExcelTok);
    end;

    procedure GetD365ICPostingsEdit(): Code[20]
    begin
        exit(IntercompanyPostingsEditTok);
    end;

    procedure GetD365CostAccountingSetup(): Code[20]
    begin
        exit(CostAccountingSetupTok);
    end;

    procedure GetD365CostAccountingView(): Code[20]
    begin
        exit(CostAccountingViewTok);
    end;

    procedure GetD365CostAccountingEdit(): Code[20]
    begin
        exit(CostAccountingEditTok);
    end;

    procedure GetD365ServiceManagementEdit(): Code[20]
    begin
        exit(ServiceManagementEditTok);
    end;

    procedure GetD365ServiceManagementView(): Code[20]
    begin
        exit(ServiceManagementViewTok);
    end;

    procedure GetD365ServiceManagementSetup(): Code[20]
    begin
        exit(ServiceManagementSetupTok);
    end;

    procedure GetD365JobsEdit(): Code[20]
    begin
        exit(JobsEditTok);
    end;

    procedure GetD365JobsView(): Code[20]
    begin
        exit(JobsViewTok);
    end;

    procedure GetD365JobsSetup(): Code[20]
    begin
        exit(JobsSetupTok);
    end;

    procedure GetD365IntelligentCloud(): Code[20]
    begin
        exit(IntelligentCloudTok);
    end;

    procedure GetD365MergeDuplicates(): Code[20]
    begin
        exit(MergeDuplicatesTok);
    end;

    procedure GetD365TestTool(): Code[20]
    begin
        exit(TestToolTok)
    end;

    procedure GetTroubleshootToolsPermissionSetName(): Code[20]
    begin
        exit(TroubleshootToolsTok);
    end;

    procedure GetBackupRestoreDataPermissionSetName(): Code[20]
    begin
        exit(BackupRestoreDataTok);
    end;

    procedure GetExcelExportActionPermissionSetName(): Code[20]
    begin
        exit(ExcelExportActionTok);
    end;

    procedure GetAutomateActionExecPermissionSetName(): Code[20]
    begin
        exit(AutomateActionPermissionSetTok);
    end;

    procedure GetRetentionPolicySetupPermissionSetName(): Code[20]
    begin
        exit(RetentionPolAdminTok)
    end;

    procedure GetEmailSetupPermissionSetName(): Code[20]
    begin
        exit(EmailAdminTok)
    end;

    procedure GetSnapshotDebugPermissionSetName(): Code[20]
    begin
        exit(SnapshotDebugTok)
    end;

    procedure GetAutomationPermissionSetName(): Code[20]
    begin
        exit(AutomationTok);
    end;

    procedure GetDimensionCorrectionPermissionSetName(): Code[20]
    begin
        exit(DimensionCorrectionTok)
    end;
}
