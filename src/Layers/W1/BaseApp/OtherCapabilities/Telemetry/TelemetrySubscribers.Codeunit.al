namespace System.Telemetry;

using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.BankAccount;
using Microsoft.Finance.FinancialReports;
using Microsoft.Sales.History;
using System.Environment;
using System.Environment.Configuration;
using System.Feedback;
using System.Reflection;
using System.Security.AccessControl;
using System.Threading;
using System.IO;

codeunit 1351 "Telemetry Subscribers"
{
    Permissions = TableData "Permission Set Link" = r;
    SingleInstance = true;

    var
        Telemetry: Codeunit Telemetry;
        ProfileChangedTelemetryMsg: Label 'Profile changed from %1 to %2.', Comment = '%1=Previous profile id, %2=New profile id', Locked = true;
        ProfileChangedTelemetryCategoryTxt: Label 'AL User Profile', Locked = true;
        PermissionSetCategoryTxt: Label 'AL PermissionSet', Locked = true;
        PermissionSetLinkAddedTelemetryTxt: Label 'A Permission Set Link was added between Source Permission Set %1 and Permission Set %2. Total count of Permission Set Links are %3.', Locked = true;
        PermissionSetLinkAddedTelemetryScopeAllTxt: Label 'Permission set link added: %1 -> %2', Locked = true;
        PermissionSetLinkRemovedTelemetryScopeAllTxt: Label 'Permission set link removed: %1 -> %2', Locked = true;
        PermissionSetAddedTelemetryScopeAllTxt: Label 'User-defined permission set added: %1', Locked = true;
        PermissionSetRemovedTelemetryScopeAllTxt: Label 'User-defined permission set removed: %1', Locked = true;
        PermissionSetSystemAddedTelemetryScopeAllTxt: Label 'Permission set added: %1', Locked = true;
        PermissionSetSystemRemovedTelemetryScopeAllTxt: Label 'Permission set removed: %1', Locked = true;
        PermissionSetAssignedToUserTelemetryScopeAllTxt: Label 'Permission set assigned to user: %1', Locked = true;
        PermissionSetRemovedFromUserTelemetryScopeAllTxt: Label 'Permission set removed from user: %1', Locked = true;
        EffectivePermsCalculatedTxt: Label 'Effective permissions were calculated for company %1, object type %2, object ID %3.', Locked = true, Comment = '%1 = company name, %2 = object type, %3 = object Id';
        TenantPermissionsChangedFromEffectivePermissionsPageTxt: Label 'Tenant permission set %1 was changed.', Locked = true, Comment = '%1 = permission set id';
        JobQueueEntriesCategoryTxt: Label 'AL JobQueueEntries', Locked = true;
        JobQueueEntrySkippedTxt: Label 'Job queue entry skipped: %1', Comment = '%1 = Job queue id', Locked = true;
        JobQueueEntryNotReadyToStartTxt: Label 'Job queue entry not ready to start: %1', Comment = '%1 = Job queue id', Locked = true;
        UndoSalesShipmentCategoryTxt: Label 'AL UndoSalesShipmentNoOfLines', Locked = true;
        UndoSalesShipmentNoOfLinesTxt: Label 'UndoNoOfLines = %1', Locked = true;
        BankAccountRecCategoryLbl: Label 'AL Bank Account Rec', Locked = true;
        FeatureManagementTok: Label 'Feature Management', Locked = true;
        BankAccountRecPostedWithBankAccCurrencyCodeMsg: Label 'Bank Account Reconciliation posted with CurrencyCode set to: %1', Locked = true;
        BankAccountRecTextToAccountCountLbl: Label 'Number of lines where Text-To-Applied was used: %1', Locked = true;
        BankAccountRecTransferToGJMsg: Label 'Lines of Bank Statement to transfer to GJ: %1', Locked = true;
        FinancialReportFeatureTok: Label 'Financial Report', Locked = true;
        FinancialReportEventTxt: Label 'Financial Report %1: %2', Comment = '%1 = event type, %2 = report', Locked = true;
        FinancialReportRowEventTxt: Label 'Financial Report Row Definition %1: %2', Comment = '%1 = event type, %2 = row definition', Locked = true;
        FinancialReportColumnEventTxt: Label 'Financial Report Column Definition %1: %2', Comment = '%1 = event type, %2 = column definition', Locked = true;
        FinancialReportOperationLbl: Label '%1 by UserSecurityId %2.', Comment = '%1 event description, %2 = user security id', Locked = true;
        CreatedTok: Label 'created', Locked = true;
        ModifiedTok: Label 'modified', Locked = true;
        RenameTok: Label 'renamed', Locked = true;
        DeletedTok: Label 'deleted', Locked = true;
        AuditNewTok: Label 'New', Locked = true;
        AuditEditTok: Label 'Edit', Locked = true;
        AuditDeleteTok: Label 'Delete', Locked = true;

    procedure SendJobQueueSkippedTelemetry(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();
        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Telemetry.LogMessage('0000P8K',
                                StrSubstNo(JobQueueEntrySkippedTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);
        TranslationHelper.RestoreGlobalLanguage();
    end;

    procedure SendJobQueueNotReadyToStartTelemetry(var JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();
        SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);
        Telemetry.LogMessage('0000P8L',
                                StrSubstNo(JobQueueEntryNotReadyToStartTxt, Format(JobQueueEntry.ID, 0, 4)),
                                Verbosity::Normal,
                                DataClassification::OrganizationIdentifiableInformation,
                                TelemetryScope::All,
                                Dimensions);
        TranslationHelper.RestoreGlobalLanguage();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Conf./Personalization Mgt.", 'OnProfileChanged', '', true, true)]
    local procedure SendTraceOnProfileChanged(PrevAllProfile: Record "All Profile"; CurrentAllProfile: Record "All Profile")
    begin
        if not IsSaaS() then
            exit;

        Session.LogMessage('00001O5', StrSubstNo(ProfileChangedTelemetryMsg, PrevAllProfile."Profile ID", CurrentAllProfile."Profile ID"), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', ProfileChangedTelemetryCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Permission Set Link", 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetLinkAdded(var Rec: Record "Permission Set Link"; RunTrigger: Boolean)
    var
        PermissionSetLink: Record "Permission Set Link";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Session.LogMessage('0000250', StrSubstNo(PermissionSetLinkAddedTelemetryTxt, Rec."Permission Set ID", Rec."Linked Permission Set ID", PermissionSetLink.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', PermissionSetCategoryTxt);

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('SourcePermissionSetId', Rec."Permission Set ID");
        Dimensions.Add('LinkedPermissionSetId', Rec."Linked Permission Set ID");
        Dimensions.Add('NumberOfUserDefinedPermissionSetLinks', Format(PermissionSetLink.Count));
        Session.LogMessage('0000E28', StrSubstNo(PermissionSetLinkAddedTelemetryScopeAllTxt, Rec."Permission Set ID", Rec."Linked Permission Set ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Permission Set Link", 'OnBeforeDeleteEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetLinkRemoved(var Rec: Record "Permission Set Link"; RunTrigger: Boolean)
    var
        PermissionSetLink: Record "Permission Set Link";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('SourcePermissionSetId', Rec."Permission Set ID");
        Dimensions.Add('LinkedPermissionSetId', Rec."Linked Permission Set ID");
        Dimensions.Add('NumberOfUserDefinedPermissionSetLinks', Format(PermissionSetLink.Count - 1));
        Session.LogMessage('0000E29', StrSubstNo(PermissionSetLinkRemovedTelemetryScopeAllTxt, Rec."Permission Set ID", Rec."Linked Permission Set ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Metadata Permission Set", 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetIsAdded(var Rec: Record "Metadata Permission Set"; RunTrigger: Boolean)
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('NumberOfSystemPermissionSets', Format(MetadataPermissionSet.Count));
        Session.LogMessage('0000GMG', StrSubstNo(PermissionSetSystemAddedTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Metadata Permission Set", 'OnBeforeDeleteEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetIsRemoved(var Rec: Record "Metadata Permission Set"; RunTrigger: Boolean)
    var
        MetadataPermissionSet: Record "Metadata Permission Set";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('NumberOfSystemPermissionSets', Format(MetadataPermissionSet.Count - 1));
        Session.LogMessage('0000GMH', StrSubstNo(PermissionSetSystemRemovedTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tenant Permission Set", 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnUserDefinedPermissionSetIsAdded(var Rec: Record "Tenant Permission Set"; RunTrigger: Boolean)
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        if not IsNullGuid(Rec."App ID") then
            exit;

        TenantPermissionSet.SetRange("App ID", Rec."App ID");

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('NumberOfUserDefinedPermissionSets', Format(TenantPermissionSet.Count));
        Session.LogMessage('0000E2A', StrSubstNo(PermissionSetAddedTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Tenant Permission Set", 'OnBeforeDeleteEvent', '', true, true)]
    local procedure SendTraceOnUserDefinedPermissionSetIsRemoved(var Rec: Record "Tenant Permission Set"; RunTrigger: Boolean)
    var
        TenantPermissionSet: Record "Tenant Permission Set";
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        if not IsNullGuid(Rec."App ID") then
            exit;

        TenantPermissionSet.SetRange("App ID", Rec."App ID");

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('NumberOfUserDefinedPermissionSets', Format(TenantPermissionSet.Count - 1));
        Session.LogMessage('0000E2B', StrSubstNo(PermissionSetRemovedTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Access Control", 'OnAfterInsertEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetIsAssignedToAUser(var Rec: Record "Access Control"; RunTrigger: Boolean)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('PermissionSetAppId', Rec."App ID");
        Dimensions.Add('PermissionSetScope', Format(Rec.Scope));
        Session.LogMessage('0000E2C', StrSubstNo(PermissionSetAssignedToUserTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Access Control", 'OnBeforeDeleteEvent', '', true, true)]
    local procedure SendTraceOnPermissionSetIsRemovedFromAUser(var Rec: Record "Access Control"; RunTrigger: Boolean)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        Dimensions.Add('Category', PermissionSetCategoryTxt);
        Dimensions.Add('PermissionSetId', Rec."Role ID");
        Dimensions.Add('PermissionSetAppId', Rec."App ID");
        Dimensions.Add('PermissionSetScope', Format(Rec.Scope));
        Session.LogMessage('0000E2D', StrSubstNo(PermissionSetRemovedFromUserTelemetryScopeAllTxt, Rec."Role ID"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Undo Sales Shipment Line", 'OnAfterCode', '', false, false)]
    local procedure SendTraceUndoSalesShipmentNoOfLines(var SalesShipmentLine: Record "Sales Shipment Line")
    begin
        if not IsSaaS() then
            exit;

        SalesShipmentLine.SetRange(Correction, true);
        Session.LogMessage('000085N', StrSubstNo(UndoSalesShipmentNoOfLinesTxt, SalesShipmentLine.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', UndoSalesShipmentCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Effective Permissions", 'OnEffectivePermissionsPopulated', '', true, true)]
    local procedure EffectivePermissionsFetchedInPage(CurrUserId: Guid; CurrCompanyName: Text[30]; CurrObjectType: Integer; CurrObjectId: Integer)
    begin
        if not IsSaaS() then
            exit;

        Session.LogMessage('000027E', StrSubstNo(EffectivePermsCalculatedTxt, CurrCompanyName, CurrObjectType, CurrObjectId), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, 'Category', PermissionSetCategoryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Effective Permissions Mgt.", 'OnTenantPermissionModified', '', true, true)]
    local procedure EffectivePermissionsChangeInPage(PermissionSetId: Code[20])
    begin
        if not IsSaaS() then
            exit;

        Session.LogMessage('000027G', StrSubstNo(TenantPermissionsChangedFromEffectivePermissionsPageTxt, PermissionSetId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PermissionSetCategoryTxt);
    end;

    local procedure IsSaaS(): Boolean
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        exit(EnvironmentInfo.IsSaaS());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Bank Acc. Reconciliation Post", 'OnAfterFinalizePost', '', true, true)]
    local procedure LogTelemetryOnBankAccRecPostOnAfterFinalizePost(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccReconciliation."Bank Account No.");
        Session.LogMessage(
            '0000AHX', StrSubstNo(BankAccountRecPostedWithBankAccCurrencyCodeMsg, BankAccount."Currency Code"), Verbosity::Normal,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Payment Reconciliation Journal", 'OnBeforeInvokePost', '', true, true)]
    local procedure LogTelemetryOnPaymentRecJournalOnBeforeInvokePost(BankAccReconciliation: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Bank Account No.", BankAccReconciliation."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", BankAccReconciliation."Statement No.");
        BankAccReconciliationLine.SetRange("Statement Type", BankAccReconciliation."Statement Type");
        BankAccReconciliationLine.SetRange("Match Confidence", BankAccReconciliationLine."Match Confidence"::"High - Text-to-Account Mapping");

        Session.LogMessage('0000AI8', StrSubstNo(BankAccountRecTextToAccountCountLbl, BankAccReconciliationLine.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Bank Acc. Reconciliation", 'OnAfterActionEvent', 'Transfer to General Journal', true, true)]
    local procedure LogTelemetryOnBankAccReconciliationAfterTransfToGJ(var Rec: Record "Bank Acc. Reconciliation")
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
    begin
        BankAccReconciliationLine.SetRange("Statement Type", Rec."Statement Type");
        BankAccReconciliationLine.SetRange("Bank Account No.", Rec."Bank Account No.");
        BankAccReconciliationLine.SetRange("Statement No.", Rec."Statement No.");
        BankAccReconciliationLine.SetFilter(Difference, '<>%1', 0);
        Session.LogMessage('0000AHW', StrSubstNo(BankAccountRecTransferToGJMsg, BankAccReconciliationLine.Count), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BankAccountRecCategoryLbl);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Feature Management", 'OnOpenPageEvent', '', false, false)]
    local procedure LogFeatureTeletryOnBeforeModifyFeatureKey(var Rec: Record "Feature Key")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000JT0', FeatureManagementTok, Enum::"Feature Uptake Status"::Discovered);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Feature Key", 'OnBeforeModifyEvent', '', false, false)]
    local procedure LogFeatureTelemetryOnBeforeModifyFeatureKey(RunTrigger: Boolean; var Rec: Record "Feature Key"; var xRec: Record "Feature Key")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if Rec.IsTemporary() then
            exit;

        if xRec.Enabled = Rec.Enabled then
            exit;

        FeatureTelemetry.LogUptake('0000JT1', FeatureManagementTok, Enum::"Feature Uptake Status"::"Set up");
        FeatureTelemetry.LogUptake('0000JT2', FeatureManagementTok, Enum::"Feature Uptake Status"::Used, GetFeatureManagementTelemetryDimensions(Rec));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Feature Key", 'OnAfterModifyEvent', '', false, false)]
    local procedure LogFeatureTelemetryOnAftereModifyFeatureKey(RunTrigger: Boolean; var Rec: Record "Feature Key"; var xRec: Record "Feature Key")
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        if Rec.IsTemporary() then
            exit;

        if xRec.Enabled = Rec.Enabled then
            exit;

        FeatureTelemetry.LogUsage('0000JT3', FeatureManagementTok, 'Feature switch has been flipped', GetFeatureManagementTelemetryDimensions(Rec));
    end;

    local procedure GetFeatureManagementTelemetryDimensions(FeatureKey: Record "Feature Key"): Dictionary of [Text, Text]
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions.Add('FeatureId', FeatureKey.ID);
        CustomDimensions.Add('FeatureDescription', FeatureKey.Description);

        if FeatureKey.Enabled = FeatureKey.Enabled::"All Users" then
            CustomDimensions.Add('Status', 'Enabled')
        else
            CustomDimensions.Add('Status', 'Disabled');

        CustomDimensions.Add('ClientType', Format(Session.CurrentClientType()));

        exit(CustomDimensions);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Management", 'OnSendDailyTelemetry', '', true, true)]
    local procedure SendDailyTelemetry()
    var
        OnboardingSignal: Codeunit "Onboarding Signal";
    begin
        Codeunit.Run(Codeunit::"Emit Database Wait Statistics");
        OnboardingSignal.CheckAndEmitOnboardingSignals();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Financial Report", OnAfterInsertEvent, '', true, true)]
    local procedure LogFinancialReportLifecycleInsert(var Rec: Record "Financial Report")
    begin
        LogFinancialReportTelemetry(Rec, '0000O77', CreatedTok, AuditNewTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Financial Report", OnAfterModifyEvent, '', true, true)]
    local procedure LogFinancialReportLifecycleModify(var Rec: Record "Financial Report")
    begin
        LogFinancialReportTelemetry(Rec, '0000O78', ModifiedTok, AuditEditTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Financial Report", OnAfterRenameEvent, '', true, true)]
    local procedure LogFinancialReportLifecycleRename(var Rec: Record "Financial Report")
    begin
        LogFinancialReportTelemetry(Rec, '0000O79', RenameTok, AuditEditTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Financial Report", OnAfterDeleteEvent, '', true, true)]
    local procedure LogFinancialReportLifecycleDelete(var Rec: Record "Financial Report")
    begin
        LogFinancialReportTelemetry(Rec, '0000O80', DeletedTok, AuditDeleteTok);
    end;

    local procedure LogFinancialReportTelemetry(FinancialReport: Record "Financial Report"; EventId: Text; EventType: Text; AuditAction: Text)
    var
        AuditLog: Codeunit "Audit Log";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
        AuditDimensions: Dictionary of [Text, Text];
    begin
        if FinancialReport.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        TelemetryDimensions.Add('ReportDefinitionCode', FinancialReport.Name);
        FeatureTelemetry.LogUsage(EventId, FinancialReportFeatureTok, StrSubstNo(FinancialReportEventTxt, EventType, FinancialReport.Name), TelemetryDimensions);

        AuditDimensions.Add('ReportDefinitionCode', FinancialReport.Name);
        AuditDimensions.Add('ReportDefinitionDesc', FinancialReport.Description);
        AuditDimensions.Add('Action', AuditAction);
        AuditLog.LogAuditMessage(
            StrSubstNo(FinancialReportOperationLbl, StrSubstNo(FinancialReportEventTxt, AuditAction, FinancialReport.Name), UserSecurityId()),
            SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0, AuditDimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Acc. Schedule Name", OnAfterInsertEvent, '', true, true)]
    local procedure LogAccScheduleNameLifecycleInsert(var Rec: Record "Acc. Schedule Name")
    begin
        LogAccScheduleNameTelemetry(Rec, '0000O81', CreatedTok, AuditNewTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Acc. Schedule Name", OnAfterModifyEvent, '', true, true)]
    local procedure LogAccScheduleNameLifecycleModify(var Rec: Record "Acc. Schedule Name")
    begin
        LogAccScheduleNameTelemetry(Rec, '0000O82', ModifiedTok, AuditEditTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Acc. Schedule Name", OnAfterRenameEvent, '', true, true)]
    local procedure LogAccScheduleNameLifecycleRename(var Rec: Record "Acc. Schedule Name")
    begin
        LogAccScheduleNameTelemetry(Rec, '0000O83', RenameTok, AuditEditTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Acc. Schedule Name", OnAfterDeleteEvent, '', true, true)]
    local procedure LogAccScheduleNameLifecycleDelete(var Rec: Record "Acc. Schedule Name")
    begin
        LogAccScheduleNameTelemetry(Rec, '0000O84', DeletedTok, AuditDeleteTok);
    end;

    local procedure LogAccScheduleNameTelemetry(AccScheduleName: Record "Acc. Schedule Name"; EventId: Text; EventType: Text; AuditAction: Text)
    var
        AuditLog: Codeunit "Audit Log";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
        AuditDimensions: Dictionary of [Text, Text];
    begin
        if AccScheduleName.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        TelemetryDimensions.Add('RowDefinitionCode', AccScheduleName.Name);
        FeatureTelemetry.LogUsage(EventId, FinancialReportFeatureTok, StrSubstNo(FinancialReportRowEventTxt, EventType, AccScheduleName.Name), TelemetryDimensions);

        AuditDimensions.Add('RowDefinitionCode', AccScheduleName.Name);
        AuditDimensions.Add('RowDefinitionDesc', AccScheduleName.Description);
        AuditDimensions.Add('Action', AuditAction);
        AuditLog.LogAuditMessage(
            StrSubstNo(FinancialReportOperationLbl, StrSubstNo(FinancialReportRowEventTxt, AuditAction, AccScheduleName.Name), UserSecurityId()),
            SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0, AuditDimensions);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Column Layout Name", OnAfterInsertEvent, '', true, true)]
    local procedure LogColumnLayoutNameLifecycleInsert(var Rec: Record "Column Layout Name")
    begin
        LogColumnLayoutNameTelemetry(Rec, '0000O85', CreatedTok, AuditNewTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Column Layout Name", OnAfterModifyEvent, '', true, true)]
    local procedure LogColumnLayoutNameLifecycleModify(var Rec: Record "Column Layout Name")
    begin
        LogColumnLayoutNameTelemetry(Rec, '0000O86', ModifiedTok, AuditEditTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Column Layout Name", OnAfterRenameEvent, '', true, true)]
    local procedure LogColumnLayoutNameLifecycleRename(var Rec: Record "Column Layout Name")
    begin
        LogColumnLayoutNameTelemetry(Rec, '0000O87', RenameTok, AuditEditTok);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Column Layout Name", OnAfterDeleteEvent, '', true, true)]
    local procedure LogColumnLayoutNameLifecycleDelete(var Rec: Record "Column Layout Name")
    begin
        LogColumnLayoutNameTelemetry(Rec, '0000O88', DeletedTok, AuditDeleteTok);
    end;

    local procedure LogColumnLayoutNameTelemetry(ColumnLayoutName: Record "Column Layout Name"; EventId: Text; EventType: Text; AuditAction: Text)
    var
        AuditLog: Codeunit "Audit Log";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
        AuditDimensions: Dictionary of [Text, Text];
    begin
        if ColumnLayoutName.IsTemporary() then
            exit;

        if not IsSaaS() then
            exit;

        TelemetryDimensions.Add('ColumnDefinitionCode', ColumnLayoutName.Name);
        FeatureTelemetry.LogUsage(EventId, FinancialReportFeatureTok, StrSubstNo(FinancialReportColumnEventTxt, EventType, ColumnLayoutName.Name), TelemetryDimensions);

        AuditDimensions.Add('ColumnDefinitionCode', ColumnLayoutName.Name);
        AuditDimensions.Add('ColumnDefinitionDesc', ColumnLayoutName.Description);
        AuditDimensions.Add('Action', AuditAction);
        AuditLog.LogAuditMessage(
            StrSubstNo(FinancialReportOperationLbl, StrSubstNo(FinancialReportColumnEventTxt, AuditAction, ColumnLayoutName.Name), UserSecurityId()),
            SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 4, 0, AuditDimensions);
    end;

    internal procedure SetJobQueueTelemetryDimensions(var JobQueueEntry: Record "Job Queue Entry"; var Dimensions: Dictionary of [Text, Text])
    begin
        JobQueueEntry.CalcFields("Object Caption to Run");
        Dimensions.Add('Category', JobQueueEntriesCategoryTxt);
        Dimensions.Add('JobQueueId', Format(JobQueueEntry.ID, 0, 4));
        Dimensions.Add('JobQueueObjectName', Format(JobQueueEntry."Object Caption to Run"));
        Dimensions.Add('JobQueueObjectDescription', Format(JobQueueEntry.Description));
        Dimensions.Add('JobQueueObjectType', Format(JobQueueEntry."Object Type to Run"));
        Dimensions.Add('JobQueueObjectId', Format(JobQueueEntry."Object ID to Run"));
        Dimensions.Add('JobQueueStatus', Format(JobQueueEntry.Status));
        Dimensions.Add('JobQueueIsRecurring', Format(JobQueueEntry."Recurring Job"));
        Dimensions.Add('JobQueueEarliestStartDateTime', Format(JobQueueEntry."Earliest Start Date/Time", 0, 9)); // UTC time
        Dimensions.Add('JobQueueCompanyName', JobQueueEntry.CurrentCompany());
        Dimensions.Add('JobQueueScheduledTaskId', Format(JobQueueEntry."System Task ID", 0, 4));
        Dimensions.Add('JobQueueMaxNumberOfAttemptsToRun', Format(JobQueueEntry."Maximum No. of Attempts to Run"));
        Dimensions.Add('JobQueueNumberOfAttemptsToRun', Format(JobQueueEntry."No. of Attempts to Run"));
        Dimensions.Add('JobQueueCategory', Format(JobQueueEntry."Job Queue Category Code"));
    end;
}
