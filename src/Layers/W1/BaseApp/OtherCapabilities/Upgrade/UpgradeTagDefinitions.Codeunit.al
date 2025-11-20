// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

using Microsoft.API.Upgrade;
using System.Upgrade;

codeunit 9998 "Upgrade Tag Definitions"
{
    // Tag Structure - MS-[TFSID]-[Description]-[DateChangeWasDoneToSeeHowOldItWas]
    // Tags must be the same in all branches

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetTimeRegistrationUpgradeTag());
        PerCompanyUpgradeTags.Add(GetJobQueueEntryMergeErrorMessageFieldsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNotificationEntryMergeErrorMessageFieldsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewSalesInvoiceEntityAggregateUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewPurchInvEntityAggregateUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewSalesOrderEntityBufferUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewSalesQuoteEntityBufferUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewSalesCrMemoEntityBufferUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewSalesShipmentLineUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDataverseAuthenticationUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCleanupDataExchUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDefaultDimensionAPIUpgradeTag());
        PerCompanyUpgradeTags.Add(GetBalAccountNoOnJournalAPIUpgradeTag());
        PerCompanyUpgradeTags.Add(GetContactBusinessRelationUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemCategoryOnItemAPIUpgradeTag());
        PerCompanyUpgradeTags.Add(GetMoveCurrencyISOCodeTag());
        PerCompanyUpgradeTags.Add(GetItemTrackingCodeUseExpirationDatesTag());
        PerCompanyUpgradeTags.Add(GetCountryApplicationAreasTag());
        PerCompanyUpgradeTags.Add(GetVATRepSetupPeriodRemCalcUpgradeTag());
        PerCompanyUpgradeTags.Add(GetGLBankAccountNoTag());
        PerCompanyUpgradeTags.Add(GetServicePasswordToIsolatedStorageTag());
        PerCompanyUpgradeTags.Add(GetAddingIDToJobsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetJobPlanningLinePlanningDueDateUpgradeTag());
        PerCompanyUpgradeTags.Add(GetEncryptedKeyValueToIsolatedStorageTag());
        PerCompanyUpgradeTags.Add(GetGraphMailRefreshCodeToIsolatedStorageTag());
        PerCompanyUpgradeTags.Add(GetStandardSalesCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetStandardPurchaseCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesOrderShipmentMethodUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesCrMemoShipmentMethodUpgradeTag());
        PerCompanyUpgradeTags.Add(GetLastUpdateInvoiceEntryNoUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIncomingDocumentURLUpgradeTag());
        PerCompanyUpgradeTags.Add(GetUpdateProfileReferencesForCompanyTag());
        PerCompanyUpgradeTags.Add(GetCashFlowCortanaFieldsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCortanaIntelligenceUsageUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPriceCalcMethodInSetupTag());
        PerCompanyUpgradeTags.Add(GetPowerBiEmbedUrlTooShortUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSearchEmailUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemVariantItemIdUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewVendorTemplatesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewCustomerTemplatesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewItemTemplatesUpgradeTag());
        PerCompanyUpgradeTags.Add(PurchRcptLineOverReceiptCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIntegrationTableMappingUpgradeTag());
        PerCompanyUpgradeTags.Add(GetAddExtraIntegrationFieldMappingsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIntegrationTableMappingFilterForOpportunitiesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIntegrationFieldMappingForOpportunitiesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIntegrationFieldMappingForContactsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIntegrationFieldMappingForInvoicesUpgradeTag());
        PerCompanyUpgradeTags.Add(WorkflowStepArgumentUpgradeTag());
        PerCompanyUpgradeTags.Add(GetMoveAzureADAppSetupSecretToIsolatedStorageTag());
        PerCompanyUpgradeTags.Add(GetDefaultDimensionParentTypeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDimensionValueDimensionIdUpgradeTag());
        PerCompanyUpgradeTags.Add(GetGLAccountAPITypeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPostCodeServiceKeyUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSetReviewRequiredOnBankPmtApplRulesTag());
        PerCompanyUpgradeTags.Add(GetFixAPISalesInvoicesCreatedFromOrders());
        PerCompanyUpgradeTags.Add(GetFixAPIPurchaseInvoicesCreatedFromOrders());
        PerCompanyUpgradeTags.Add(GetCheckLedgerEntriesMoveFromRecordIDToSystemIdUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDeleteSalesOrdersOrphanedRecords());
        PerCompanyUpgradeTags.Add(GetDeletePurchaseOrdersOrphanedRecords());
        PerCompanyUpgradeTags.Add(GetDimensionSetEntryUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewPurchRcptLineUpgradeTag());
        PerCompanyUpgradeTags.Add(GetRemoveOldWorkflowTableRelationshipRecordsTag());
        PerCompanyUpgradeTags.Add(GetNewPurchaseOrderEntityBufferUpgradeTag());
        PerCompanyUpgradeTags.Add(GetUserTaskDescriptionToUTF8UpgradeTag());
        PerCompanyUpgradeTags.Add(GetDefaultWordTemplateAllowedTablesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesCreditMemoReasonCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPowerBIWorkspacesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPowerBIDisplayedElementUpgradeTag());
        PerCompanyUpgradeTags.Add(GetClearTemporaryTablesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetClearVATAmountLineTableUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDimSetEntryGlobalDimNoUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPriceSourceGroupUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPriceSourceGroupFixedUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSyncPriceListLineStatusUpgradeTag());
        PerCompanyUpgradeTags.Add(GetUpdateEditInExcelPermissionSetUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesInvoiceShortcutDimensionsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPurchInvoiceShortcutDimensionsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPurchaseOrderShortcutDimensionsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesOrderShortcutDimensionsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesQuoteShortcutDimensionsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesCrMemoShortcutDimensionsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemPostingGroupsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCreditTransferIBANUpgradeTag());
        PerCompanyUpgradeTags.Add(GetVendorTemplatesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCustomerTemplatesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemTemplatesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetAzureADSetupFixTag());
        PerCompanyUpgradeTags.Add(GetRemoveSmartListManualSetupEntryUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDocumentDefaultLineTypeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetJobShipToSellToFunctionalityUpgradeTag());
        PerCompanyUpgradeTags.Add(GetEnableOnlineMapUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDataExchOCRVendorNoTag());
        PerCompanyUpgradeTags.Add(GetJobReportSelectionUpgradeTag());
        PerCompanyUpgradeTags.Add(GetConfigFieldMapUpgradeTag());
        PerCompanyUpgradeTags.Add(GetICSetupUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemCrossReferenceInPEPPOLUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemChargeHandleQtyUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemCrossReferenceUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPowerBIUploadsStatusUpgradeTag());
        PerCompanyUpgradeTags.Add(GetUseCustomLookupUpgradeTag());
        PerCompanyUpgradeTags.Add(SanitizeCloudMigratedDataUpgradeTag());
        PerCompanyUpgradeTags.Add(GetAccountSchedulesToFinancialReportsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCRMUnitGroupMappingUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCRMSDK90UpgradeTag());
        PerCompanyUpgradeTags.Add(GetCRMSDK91UpgradeTag());
        PerCompanyUpgradeTags.Add(GetVATDateFieldGLEntriesUpgrade());
        PerCompanyUpgradeTags.Add(GetVATDateFieldVATEntriesUpgrade());
        PerCompanyUpgradeTags.Add(GetVATDateFieldSalesPurchUpgrade());
        PerCompanyUpgradeTags.Add(GetVATDateFieldVATEntriesBlankUpgrade());
        PerCompanyUpgradeTags.Add(GetVATDateFieldGLEntriesBlankUpgrade());
        PerCompanyUpgradeTags.Add(GetVATDateFieldSalesPurchBlankUpgrade());
        PerCompanyUpgradeTags.Add(GetVATDateFieldIssuedDocsBlankUpgrade());
        PerCompanyUpgradeTags.Add(GetSendCloudMigrationUpgradeTelemetryBaseAppTag());
        PerCompanyUpgradeTags.Add(GetVATDateFieldIssuedDocsUpgrade());
        PerCompanyUpgradeTags.Add(GetICPartnerGLAccountNoUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCheckWhseClassOnLocationUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDeferralSourceCodeUpdateTag());
        PerCompanyUpgradeTags.Add(GetServiceLineOrderNoUpgradeTag());
        PerCompanyUpgradeTags.Add(GetMapCurrencySymbolUpgradeTag());
        PerCompanyUpgradeTags.Add(GetOptionMappingUpgradeTag());
        PerCompanyUpgradeTags.Add(GetProductionSourceCodeUpdateTag());
        PerCompanyUpgradeTags.Add(GetPurchaseCreditMemoUpgradeTag());
        PerCompanyUpgradeTags.Add(GetWorkflowDelegatedAdminSetupTemplateUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPurchasesPayablesAndSalesReceivablesSetupsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetLocationBinPolicySetupsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetAllowInventoryAdjmtUpgradeTag());
        PerCompanyUpgradeTags.Add(GetLocationGranularWarehouseHandlingSetupsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetVATSetupUpgradeTag());
        PerCompanyUpgradeTags.Add(GetVATSetupAllowVATDateTag());
        PerCompanyUpgradeTags.Add(GetBankExportImportSetupSEPACT09UpgradeTag());
        PerCompanyUpgradeTags.Add(GetSalesShipmentCustomerIdUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCustomReportLayoutUpgradeTag());
        PerCompanyUpgradeTags.Add(GetFixedAssetLocationIdUpgradeTag());
        PerCompanyUpgradeTags.Add(GetFixedAssetResponsibleEmployeeIdUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCopyItemSalesBlockedToServiceBlockedUpgradeTag());
        PerCompanyUpgradeTags.Add(GetJobTaskReportSelectionUpgradeTag());
        PerCompanyUpgradeTags.Add(GetEmployeeLedgerEntryCurrencyFactorUpgradeTag());
        PerCompanyUpgradeTags.Add(GetInitShipToPhoneNoUpgradeTag());
        PerCompanyUpgradeTags.Add(GetMultilineReminderTextUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCountryVATSchemeDKTag());
        PerCompanyUpgradeTags.Add(GetDefaultConsCalcBasedOnUpgradeTag());
        PerCompanyUpgradeTags.Add(GetUpgradeJobConsumpWhseHandlingForDirectedPutAwayAndPickLocationUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIntegrationTableMappingTemplatesUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPopulateUserSetupEmailUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPurchaseCreditMemoVendorCrMemoNoUpgradeTag());
        PerCompanyUpgradeTags.Add(GetICOutboxTransactionSourceTypeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetInventoryPlanningSetupUpgradeTag());
        PerCompanyUpgradeTags.Add(GetICTransactionSourceTypeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetFinancialReportDefaultsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNewSalesPricingFeatureKeyStateTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetNewISVPlansUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetWorkflowWebhookWebServicesUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetExcelTemplateWebServicesUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetAddDeviceISVEmbUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetExcelExportActionPermissionSetUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetAddBackupRestorePermissionSetUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetUpdateProfileReferencesForDatabaseTag());
        PerDatabaseUpgradeTags.Add(GetRemoveExtensionManagementFromPlanUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetRemoveExtensionManagementFromUsersUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetSharePointConnectionUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetCreateDefaultAADApplicationTag());
        PerDatabaseUpgradeTags.Add(GetCreateDefaultPowerPagesAADApplicationsTag());
        PerDatabaseUpgradeTags.Add(GetMonitorSensitiveFieldPermissionUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetUpdateInitialPrivacyNoticesTag());
        PerDatabaseUpgradeTags.Add(GetDataOutOfGeoAppUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetUpgradePowerBIOptinImageUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetUserGroupsSetAppIdUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetAutomateActionPermissionSetUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetAutomateActionAccessControlUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetEmployeeProfileUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetTeamsUsersUserGroupUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetUserGroupsMigrationUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetCustLedgerEntryYourReferenceUpdateTag());
        PerDatabaseUpgradeTags.Add(GetEssentialAttachUserGroupUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetBCUserGroupUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetRenderWordReportsInPlatformFeatureKeyUpgradeTag());
        PerDatabaseUpgradeTags.Add(GetRegisterBankAccRecCopilotCapabilityUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"API Data Upgrade", 'OnGetAPIUpgradeTags', '', false, false)]
    local procedure RegisterAPIUpgradeTags(var APIUpgradeTags: Dictionary of [Code[250], Text[250]])
    begin
        APIUpgradeTags.Add(GetSalesCreditMemoReasonCodeUpgradeTag(), 'API Upgrade - SalesCreditMemoReasonCode');
        APIUpgradeTags.Add(GetSalesInvoiceShortcutDimensionsUpgradeTag(), 'API Upgrade - SalesInvoiceShortcutDimensions');
        APIUpgradeTags.Add(GetPurchInvoiceShortcutDimensionsUpgradeTag(), 'API Upgrade - PurchInvoiceShortcutDimensions');
        APIUpgradeTags.Add(GetPurchaseOrderShortcutDimensionsUpgradeTag(), 'API Upgrade - PurchaseOrderShortcutDimensions');
        APIUpgradeTags.Add(GetSalesOrderShortcutDimensionsUpgradeTag(), 'API Upgrade - SalesOrderShortcutDimensions');
        APIUpgradeTags.Add(GetSalesQuoteShortcutDimensionsUpgradeTag(), 'API Upgrade - SalesQuoteShortcutDimensions');
        APIUpgradeTags.Add(GetSalesCrMemoShortcutDimensionsUpgradeTag(), 'API Upgrade - SalesCrMemoShortcutDimensions');
    end;

    internal procedure GetConfigFieldMapUpgradeTag(): Code[250]
    begin
        exit('MS-417047-ConfigFieldMap-20211112')
    end;

    internal procedure GetUserGroupsSetAppIdUpgradeTag(): Code[250]
    begin
        exit('MS-392765-UserGroupsSetAppId-20210309')
    end;

    internal procedure GetUserGroupsMigrationUpgradeTag(): Code[250]
    begin
        exit('MS-458366-UserGroupsMigration-20230205')
    end;

    internal procedure GetJobQueueEntryMergeErrorMessageFieldsUpgradeTag(): Code[250]
    begin
        exit('291121-JobQueueEntryMergingErrorMessageFields-20190307')
    end;

    internal procedure GetNotificationEntryMergeErrorMessageFieldsUpgradeTag(): Code[250]
    begin
        exit('323517-NotificationEntryMergingErrorMessageFields-20190823')
    end;

    internal procedure GetTimeRegistrationUpgradeTag(): Code[250]
    begin
        exit('284963-TimeRegistrationAPI-ReadOnly-20181010');
    end;

    internal procedure GetSalesInvoiceEntityAggregateUpgradeTag(): Code[250]
    begin
        exit('298839-SalesInvoiceAddingMultipleAddresses-20190213');
    end;

    internal procedure GetPurchInvEntityAggregateUpgradeTag(): Code[250]
    begin
        exit('294917-PurchInvoiceAddingMultipleAddresses-20190213');
    end;

    internal procedure GetPriceCalcMethodInSetupTag(): Code[250]
    begin
        exit('344135-PriceCalcMethodInSetup-20200210');
    end;

    internal procedure GetSalesOrderEntityBufferUpgradeTag(): Code[250]
    begin
        exit('298839-SalesOrderAddingMultipleAddresses-20190213');
    end;

    internal procedure GetSalesQuoteEntityBufferUpgradeTag(): Code[250]
    begin
        exit('298839-SalesQuoteAddingMultipleAddresses-20190213');
    end;

    internal procedure GetSalesCrMemoEntityBufferUpgradeTag(): Code[250]
    begin
        exit('298839-SalesCrMemoAddingMultipleAddresses-20190213');
    end;

    internal procedure GetNewSalesInvoiceEntityAggregateUpgradeTag(): Code[250]
    begin
        exit('MS-317081-SalesInvoiceAddingMultipleAddresses-20190731');
    end;

    internal procedure GetNewPurchInvEntityAggregateUpgradeTag(): Code[250]
    begin
        exit('MS-317081-PurchInvoiceAddingMultipleAddresses-20190731');
    end;

    internal procedure GetNewSalesOrderEntityBufferUpgradeTag(): Code[250]
    begin
        exit('MS-317081-SalesOrderAddingMultipleAddresses-20190731');
    end;

    internal procedure GetNewSalesQuoteEntityBufferUpgradeTag(): Code[250]
    begin
        exit('MS-317081-SalesQuoteAddingMultipleAddresses-20190731');
    end;

    internal procedure GetNewSalesCrMemoEntityBufferUpgradeTag(): Code[250]
    begin
        exit('MS-317081-SalesCrMemoAddingMultipleAddresses-20190731');
    end;

    procedure GetNewSalesShipmentLineUpgradeTag(): Code[250]
    begin
        exit('MS-383010-SalesShipmentLineDocumentId-20201210');
    end;

    internal procedure GetNewISVPlansUpgradeTag(): Code[250]
    begin
        exit('MS-287563-NewISVPlansAdded-20181105');
    end;

    internal procedure GetWorkflowWebhookWebServicesUpgradeTag(): Code[250]
    begin
        exit('MS-281716-WorkflowWebhookWebServices-20180907');
    end;

    internal procedure GetExcelTemplateWebServicesUpgradeTag(): Code[250]
    begin
        exit('MS-281716-ExcelTemplateWebServices-20180907');
    end;

    internal procedure GetCleanupDataExchUpgradeTag(): Code[250]
    begin
        exit('MS-CleanupDataExchUpgrade-20180821');
    end;

    internal procedure GetDefaultDimensionAPIUpgradeTag(): Code[250]
    begin
        exit('MS-275427-DefaultDimensionAPI-20180719');
    end;

    internal procedure GetBalAccountNoOnJournalAPIUpgradeTag(): Code[250]
    begin
        exit('MS-275328-BalAccountNoOnJournalAPI-20180823');
    end;

    procedure GetItemCategoryOnItemAPIUpgradeTag(): Code[250]
    begin
        exit('MS-279686-ItemCategoryOnItemAPI-20180903');
    end;

    internal procedure GetContactBusinessRelationUpgradeTag(): Code[250]
    begin
        exit('MS-383899-ContactBusinessRelation-20210119');
    end;

    internal procedure GetContactBusinessRelationEnumUpgradeTag(): Code[250]
    begin
        exit('MS-395036-ContactBusinessRelation-20210324');
    end;

    procedure GetMoveCurrencyISOCodeTag(): Code[250]
    begin
        exit('MS-267101-MoveCurrencyISOCode-20190209');
    end;

    internal procedure GetItemTrackingCodeUseExpirationDatesTag(): Code[250]
    begin
        exit('MS-296384-GetItemTrackingCodeUseExpirationDates-20190305');
    end;

    internal procedure GetCountryApplicationAreasTag(): Code[250]
    begin
        exit('MS-GetCountryApplicationAreas-20190315');
    end;

    internal procedure GetGLBankAccountNoTag(): Code[250]
    begin
        exit('MS-305176-GetGLBankAccountNoTag-20190408');
    end;

    internal procedure GetVATRepSetupPeriodRemCalcUpgradeTag(): Code[250]
    begin
        exit('MS-306583-VATReportSetup-20190402');
    end;

    internal procedure GetServicePasswordToIsolatedStorageTag(): Code[250]
    begin
        exit('MS-308119-ServicePassword-20190429');
    end;

    internal procedure GetAddingIDToJobsUpgradeTag(): Code[250]
    begin
        exit('MS-310839-GETAddingIDToJobs-20190506');
    end;

    internal procedure GetEncryptedKeyValueToIsolatedStorageTag(): Code[250]
    begin
        exit('MS-308119-EncKeyValue-20190429');
    end;

    internal procedure GetGraphMailRefreshCodeToIsolatedStorageTag(): Code[250]
    begin
        exit('MS-304318-GraphMailRefreshCode-20190429');
    end;

    internal procedure GetStandardSalesCodeUpgradeTag(): Code[250]
    begin
        exit('MS-311677-StandardSalesCode-20190517');
    end;

    internal procedure GetStandardPurchaseCodeUpgradeTag(): Code[250]
    begin
        exit('MS-311677-StandardPurchaseCode-20190517');
    end;

    internal procedure GetSalesOrderShipmentMethodUpgradeTag(): Code[250]
    begin
        exit('MS-313998-SalesOrderShipmentMethod-20190606');
    end;

    internal procedure GetUpdateProfileReferencesForCompanyTag(): Code[250]
    begin
        exit('315647-ProfilesReferencesCompany-20190814');
    end;

    internal procedure GetUpdateProfileReferencesForDatabaseTag(): Code[250]
    begin
        exit('315647-ProfileReferencesDatabase-20190814');
    end;

    internal procedure GetSalesCrMemoShipmentMethodUpgradeTag(): Code[250]
    begin
        exit('MS-313998-SalesCrMemoShipmentMethod-20190606');
    end;

    internal procedure GetLastUpdateInvoiceEntryNoUpgradeTag(): Code[250]
    begin
        exit('MS-310795-LastUpdateInvoiceEntryNo-20190607');
    end;

    internal procedure GetAddDeviceISVEmbUpgradeTag(): Code[250]
    begin
        exit('MS-312516-AddDeviceISVEmbPlan-20190601');
    end;

    internal procedure GetIncomingDocumentURLUpgradeTag(): Code[250]
    begin
        exit('319444-DeprecateURLFieldsIncomingDocs-20190724');
    end;

    internal procedure GetRemoveExtensionManagementFromPlanUpgradeTag(): Code[250];
    begin
        exit('MS-323197-RemoveExtensionManagementFromPlan-20190821');
    end;

    internal procedure GetRemoveExtensionManagementFromUsersUpgradeTag(): Code[250];
    begin
        exit('MS-323197-RemoveExtensionManagementFromUsers-20190821');
    end;

    internal procedure GetAddBackupRestorePermissionSetUpgradeTag(): Code[250];
    begin
        exit('MS-317694-AddBackupRestorePermissionset-20190812');
    end;

    internal procedure GetAddFeatureDataUpdatePermissionsUpgradeTag(): Code[250];
    begin
        exit('MS-375048-AddBackupRestorePermissionset-20201028');
    end;

    internal procedure GetCashFlowCortanaFieldsUpgradeTag(): Code[250];
    begin
        exit('MS-318837-RenameCashFlowCortanaIntelligenceFields-20190820');
    end;

    internal procedure GetCortanaIntelligenceUsageUpgradeTag(): Code[250];
    begin
        exit('MS-318837-RenameCortanaIntelligenceUsage-20190820');
    end;

    internal procedure GetSetReviewRequiredOnBankPmtApplRulesTag(): Code[250]
    begin
        exit('MS-327612-SetReviewRequiredOnBankPmtApplRules-20200204');
    end;

    internal procedure GetLoadNamedForwardLinksUpgradeTag(): Code[250];
    begin
        exit('MS-328639-LoadNamedForwardLinks-20191003');
    end;

    internal procedure GetRecordLinkURLUpgradeTag(): Code[250]
    begin
        exit('MS-326679-DeprecateURLFieldsRecordLink-20191022');
    end;

    internal procedure GetExcelExportActionPermissionSetUpgradeTag(): Code[250];
    begin
        exit('MS-328760-ExcelExportActionPermissionset-20191022');
    end;

    internal procedure GetPowerBiEmbedUrlTooShortUpgradeTag(): Code[250];
    begin
        exit('MS-343007-PowerBiEmbedUrlTooShort-20200220');
    end;

    internal procedure GetSearchEmailUpgradeTag(): Code[250];
    begin
        exit('MS-346850-SearchEmail-20200302');
    end;

    internal procedure GetItemVariantItemIdUpgradeTag(): Code[250];
    begin
        exit('MS-345848-ItemVariantsItemId-20200319');
    end;

    internal procedure GetSmartListDesignerPermissionSetUpgradeTag(): Code[250];
    begin
        exit('MS-334180-ExcelExportActionPermissionset-20200317');
    end;

    internal procedure GetCompanyHubPermissionSetUpgradeTag(): Code[250];
    begin
        exit('MS-342774-IntroduceCompanyHubPermissionSet-20200707');
    end;

    internal procedure GetNewVendorTemplatesUpgradeTag(): Code[250];
    begin
        exit('MS-332155-NewVendorTemplates-20200531');
    end;

    internal procedure GetNewCustomerTemplatesUpgradeTag(): Code[250];
    begin
        exit('MS-332155-NewCustomerTemplates-20200531');
    end;

    internal procedure GetNewItemTemplatesUpgradeTag(): Code[250];
    begin
        exit('MS-332155-NewItemTemplates-20200531');
    end;

    internal procedure PurchRcptLineOverReceiptCodeUpgradeTag(): Code[250];
    begin
        exit('MS-360362-PurchRcptLineOverReceiptCode-20200612');
    end;

    procedure GetNewPurchRcptLineUpgradeTag(): Code[250]
    begin
        exit('MS-383010-PurchRcptLineDocumentId-20201210');
    end;

    internal procedure GetIntegrationTableMappingUpgradeTag(): Code[250];
    begin
        exit('MS-368854-IntegrationTableMapping-20200818');
    end;

    internal procedure GetAddExtraIntegrationFieldMappingsUpgradeTag(): Code[250];
    begin
        exit('MS-481366-AddExtraIntegrationFieldMappings-20230818');
    end;

    internal procedure GetDataverseAuthenticationUpgradeTag(): Code[250];
    begin
        exit('MS-423171-DataverseAuthentication-20220127');
    end;

    internal procedure GetIntegrationTableMappingCouplingCodeunitIdUpgradeTag(): Code[250];
    begin
        exit('MS-394964-IntegrationTableMappingCouplingCodeunitId-20210412');
    end;

    internal procedure GetIntegrationTableMappingFilterForOpportunitiesUpgradeTag(): Code[250];
    begin
        exit('MS-381295-IntegrationTableMappingFilterForOpportunities-20201202');
    end;

    internal procedure GetIntegrationFieldMappingForOpportunitiesUpgradeTag(): Code[250];
    begin
        exit('MS-381299-IntegrationFieldMappingForOpportunities-20201215');
    end;

    internal procedure GetIntegrationFieldMappingForContactsUpgradeTag(): Code[250];
    begin
        exit('MS-387286-IntegrationFieldMappingForContacts-20210125');
    end;

    internal procedure GetIntegrationFieldMappingForInvoicesUpgradeTag(): Code[250];
    begin
        exit('MS-3411596-IntegrationFieldMappingForInvoices-20210916');
    end;

    internal procedure WorkflowStepArgumentUpgradeTag(): Code[250];
    begin
        exit('MS-355773-WorkflowStepArgumentUpgradeTag-20200617');
    end;

    internal procedure GetMoveAzureADAppSetupSecretToIsolatedStorageTag(): Code[250];
    begin
        exit('MS-361172-MoveAzureADAppSetupSecretToIsolatedStorageTag-20200716');
    end;

    internal procedure GetSharePointConnectionUpgradeTag(): Code[250]
    begin
        exit('MS-358407-SharePointConnection-20200709');
    end;

    internal procedure ContactMobilePhoneNoUpgradeTag(): Code[250];
    begin
        exit('MS-365063-ContactMobilePhoneNo-20200803');
    end;

    internal procedure GetCreateDefaultAADApplicationTag(): Code[250]
    begin
        exit('MS-366236-CreateDefaultAADApplication-20200813');
    end;

    internal procedure GetCreateDefaultPowerPagesAADApplicationsTag(): Code[250]
    begin
        exit('MS-486050-CreateDefaultAADApplication-20230927');
    end;

    internal procedure GetMonitorSensitiveFieldPermissionUpgradeTag(): Code[250];
    begin
        exit('MS-366164-AddD365MonitorFieldsToSecurityUserGroup-20200811');
    end;

    internal procedure GetDefaultDimensionParentTypeUpgradeTag(): Code[250];
    begin
        exit('MS-367190-DefaultDimensionParentType-20200816');
    end;

    internal procedure GetDimensionValueDimensionIdUpgradeTag(): Code[250];
    begin
        exit('MS-367190-DimensionValueDimensionId-20200816');
    end;

    procedure GetGLAccountAPITypeUpgradeTag(): Code[250];
    begin
        exit('MS-367190-GLAccountAPIType-20200816');
    end;

    internal procedure GetPostCodeServiceKeyUpgradeTag(): Code[250];
    begin
        exit('MS-369092-PostCodeServiceKey-20200915')
    end;

    internal procedure GetDimensionSetEntryUpgradeTag(): Code[250]
    begin
        exit('MS-352854-ShortcutDimensionsInGLEntry-20201204');
    end;

    internal procedure GetRemoveOldWorkflowTableRelationshipRecordsTag(): Code[250]
    begin
        exit('MS-384473-RemoveOldWorkflowTableRelationshipRecords-20201222');
    end;

    internal procedure GetNewPurchaseOrderEntityBufferUpgradeTag(): Code[250]
    begin
        exit('MS-385184-PurchaseOrderEntityBuffer-20210104');
    end;

    procedure GetUpdateInitialPrivacyNoticesTag(): Code[250]
    begin
        exit('MS-411954-InitialPrivacyNoticesTag-20220211');
    end;

    procedure GetDataOutOfGeoAppUpgradeTag(): Code[250]
    begin
        exit('MS-370438-DataOutOfGeoAppTag-20210121');
    end;

    internal procedure GetUserTaskDescriptionToUTF8UpgradeTag(): Code[250]
    begin
        exit('MS-385481-UserTaskDescriptionToUTF8-20210112');
    end;

    internal procedure GetUpgradeNativeAPIWebServiceUpgradeTag(): Code[250]
    begin
        exit('MS-386191-NativeAPIWebService-20210121');
    end;

    internal procedure GetDefaultWordTemplateAllowedTablesUpgradeTag(): Code[250]
    begin
        exit('MS-375813-DefaultWordTemplateAllowedTables-20210119');
    end;

    internal procedure GetPowerBIWorkspacesUpgradeTag(): Code[250]
    begin
        exit('MS-363514-AddPowerBIWorkspaces-20210503');
    end;

    internal procedure GetUpgradePowerBIOptinImageUpgradeTag(): Code[250]
    begin
        exit('MS-330739-PowerBIOptinImage-20210129');
    end;

    internal procedure GetPowerBIDisplayedElementUpgradeTag(): Code[250]
    begin
        exit('MS-460555-PowerBIDisplayedElement-20230824');
    end;

    internal procedure GetUpgradeMonitorNotificationUpgradeTag(): Code[250]
    begin
        exit('MS-391008-MonitorFields-20210318');
    end;

    internal procedure GetPriceSourceGroupUpgradeTag(): Code[250]
    begin
        exit('MS-388025-PriceSourceGroup-20210331');
    end;

    internal procedure GetAllJobsResourcePriceUpgradeTag(): Code[250]
    begin
        exit('MS-412932-AllJobsResourcePrice-20210929');
    end;

    internal procedure GetPriceSourceGroupFixedUpgradeTag(): Code[250]
    begin
        exit('MS-400024-PriceSourceGroup-20210519');
    end;

    internal procedure GetSalesCreditMemoReasonCodeUpgradeTag(): Code[250]
    begin
        exit('MS-395664-SalesCrMemoAPIReasonCode-20210406');
    end;

    internal procedure GetClearTemporaryTablesUpgradeTag(): Code[250]
    begin
        exit('MS-396184-CleanTemporaryTables-20210427');
    end;

    internal procedure GetClearVATAmountLineTableUpgradeTag(): Code[250]
    begin
        exit('MS-396184-CleanVATAmountLineTable-20240819');
    end;

    internal procedure GetBankExportImportSetupSEPACT09UpgradeTag(): Code[250]
    begin
        exit('MS-533446-BankExportImportSetupSEPACT09-20240528');
    end;

    internal procedure GetDimSetEntryGlobalDimNoUpgradeTag(): Code[250]
    begin
        exit('MS-396220-DimSetEntryGlobalDimNo-20210503');
    end;

    internal procedure GetUpdateEditInExcelPermissionSetUpgradeTag(): Code[250]
    begin
        exit('MS-385783-UseEditInExcelExecPermissionSet-20210526');
    end;

    internal procedure GetItemCrossReferenceUpgradeTag(): Code[250]
    begin
        exit('MS-398144-ItemCrossReference-20210625');
    end;

    internal procedure GetSalesInvoiceShortcutDimensionsUpgradeTag(): Code[250]
    begin
        exit('MS-403657-SalesInvoiceShortcutDimensions-20210628');
    end;

    internal procedure GetPurchInvoiceShortcutDimensionsUpgradeTag(): Code[250]
    begin
        exit('MS-403657-PurchInvoiceShortcutDimensions-20210628');
    end;

    internal procedure GetPurchaseOrderShortcutDimensionsUpgradeTag(): Code[250]
    begin
        exit('MS-403657-PurchaseOrderShortcutDimensions-20210628');
    end;

    internal procedure GetSalesOrderShortcutDimensionsUpgradeTag(): Code[250]
    begin
        exit('MS-403657-SalesOrderShortcutDimensions-20210628');
    end;

    internal procedure GetSalesQuoteShortcutDimensionsUpgradeTag(): Code[250]
    begin
        exit('MS-403657-GetSalesQuoteShortcutDimensions-20210628');
    end;

    internal procedure GetSalesCrMemoShortcutDimensionsUpgradeTag(): Code[250]
    begin
        exit('MS-403657-SalesCrMemoShortcutDimensions-20210628');
    end;

    internal procedure GetItemPostingGroupsUpgradeTag(): Code[250]
    begin
        exit('MS-405484-GenItemPostingGroups-20210719')
    end;

    internal procedure GetJobPlanningLinePlanningDueDateUpgradeTag(): Code[250]
    begin
        exit('MS-402915-JobPlanningLinePlanningDueDate-20210809');
    end;

    internal procedure GetCreditTransferIBANUpgradeTag(): Code[250]
    begin
        exit('MS-326295-CreditTransferIBAN-20210812');
    end;

    internal procedure GetVendorTemplatesUpgradeTag(): Code[250];
    begin
        exit('MS-332155-VendorTemplates-20210817');
    end;

    internal procedure GetCustomerTemplatesUpgradeTag(): Code[250];
    begin
        exit('MS-332155-CustomerTemplates-20210817');
    end;

    internal procedure GetitemTemplatesUpgradeTag(): Code[250];
    begin
        exit('MS-332155-ItemTemplates-20210817');
    end;

    internal procedure GetAzureADSetupFixTag(): Code[250];
    begin
        exit('MS-408786-FixAzureAdSetup-20210826');
    end;

    internal procedure GetDocumentDefaultLineTypeUpgradeTag(): Code[250]
    begin
        exit('MS-410225-DocumentDefaultLineType');
    end;

    internal procedure GetJobShipToSellToFunctionalityUpgradeTag(): Code[250]
    begin
        exit('MS-327705-JobShipToSellToFunctionality');
    end;

    internal procedure GetSyncPriceListLineStatusUpgradeTag(): Code[250]
    begin
        exit('MS-400024-PriceLineStatusSync-20210519');
    end;

    procedure GetRemoveSmartListManualSetupEntryUpgradeTag(): Code[250]
    begin
        exit('MS-401573-SmartListManualSetup-20210609');
    end;

    internal procedure GetFixAPISalesInvoicesCreatedFromOrders(): Code[250];
    begin
        exit('MS-377282-GetFixAPISalesInvoicesCreatedFromOrders-20201029');
    end;

    internal procedure GetFixAPIPurchaseInvoicesCreatedFromOrders(): Code[250];
    begin
        exit('MS-377282-GetFixAPIPurchaseInvoicesCreatedFromOrders-20201029');
    end;

    internal procedure GetDeleteSalesOrdersOrphanedRecords(): Code[250];
    begin
        exit('MS-377433-DeleteSalesOrdersOrphanedRecords-20201102');
    end;

    internal procedure GetDeletePurchaseOrdersOrphanedRecords(): Code[250];
    begin
        exit('MS-385184-DeletePurchaseOrdersOrphanedRecords-20210104');
    end;

    internal procedure GetEnableOnlineMapUpgradeTag(): Code[250];
    begin
        exit('MS-413441-EnableOnlineMap-20211005');
    end;

    procedure GetDataExchOCRVendorNoTag(): Code[250]
    begin
        exit('MS-415627-DataExchOCRVendorNo-20211111');
    end;

    internal procedure GetJobReportSelectionUpgradeTag(): Code[250]
    begin
        exit('MS-404082-JobReportSelection-20211021');
    end;

    internal procedure GetJobTaskReportSelectionUpgradeTag(): Code[250]
    begin
        exit('MS-348602-JobTaskReportSelection-20240122');
    end;

    internal procedure GetICSetupUpgradeTag(): Code[250]
    begin
        exit('MS-290460-IntercompanySetup-20211110');
    end;

    internal procedure GetItemCrossReferenceInPEPPOLUpgradeTag(): Code[250]
    begin
        exit('MS-422103-GetItemCrossReferenceInPEPPOLUpgradeTag-20220114');
    end;

    internal procedure GetEmployeeProfileUpgradeTag(): Code[250]
    begin
        exit('MS-427396-GetEmployeeProfileUpgradeTag-20220825');
    end;

    internal procedure GetTeamsUsersUserGroupUpgradeTag(): Code[250];
    begin
        exit('MS-427396-GetTeamsUsersUserGroupUpgradeTag-20220825');
    end;

    internal procedure GetEssentialAttachUserGroupUpgradeTag(): Code[250];
    begin
        exit('MS-483944-GetD365EssentialAttachUserGroupUpgradeTag-20230911');
    end;

    internal procedure GetBCUserGroupUpgradeTag(): Code[250];
    begin
        exit('MS-498639-GetBCUserGroupUpgradeTag-20240502');
    end;

    internal procedure GetItemChargeHandleQtyUpgradeTag(): Code[250]
    begin
        exit('MS-424468-GetItemChargeHandleQtyUpgradeTag-20220524');
    end;

    internal procedure GetUseCustomLookupUpgradeTag(): Code[250]
    begin
        exit('MS-426799-GetUseCustomLookupUpgradeTag-20220406');
    end;

    internal procedure SanitizeCloudMigratedDataUpgradeTag(): Code[250]
    begin
        exit('MS-433866-GetSanitizeCloudMigrationOnce-20220426');
    end;

    internal procedure GetAutomateActionPermissionSetUpgradeTag(): Code[250];
    begin
        exit('MS-433748-AutomateActionPermissionSet-20220627');
    end;

    internal procedure GetAutomateActionAccessControlUpgradeTag(): Code[250];
    begin
        exit('MS-460562-AutomateActionAccessControl-20230116');
    end;

    internal procedure GetPowerBIUploadsStatusUpgradeTag(): Code[250];
    begin
        exit('MS-430659-PowerBIUploadsStatus-20230703');
    end;

    internal procedure GetAccountSchedulesToFinancialReportsUpgradeTag(): Code[250]
    begin
        exit('MS-441563-GetAccountSchedulesToFinancialReportsUpgradeTag-20220705');
    end;

    internal procedure GetCRMUnitGroupMappingUpgradeTag(): Code[250]
    begin
        exit('MS-433866-GetCRMUnitGroupMappingUpgradeTag-20220622');
    end;

    internal procedure GetCRMSDK90UpgradeTag(): Code[250]
    begin
        exit('MS-444855-GetCRMSDK90UpgradeTag-20220805');
    end;

    internal procedure GetCRMSDK91UpgradeTag(): Code[250]
    begin
        exit('MS-470055-GetCRMSDK91UpgradeTag-20230415');
    end;

    procedure GetVATDateFieldGLEntriesUpgrade(): Code[250]
    begin
        exit('MS-447067-GetVATDateFieldGLEntriesUpgrade-20220830');
    end;

    procedure GetVATDateFieldVATEntriesUpgrade(): Code[250]
    begin
        exit('MS-447067-GetVATDateFieldVATEntriesUpgrade-20220830');
    end;

    internal procedure GetVATDateFieldVATEntriesBlankUpgrade(): Code[250]
    begin
        exit('MS-465444-GetVATDateFieldVATEntriesBlankUpgrade-20230301');
    end;

    internal procedure GetVATDateFieldGLEntriesBlankUpgrade(): Code[250]
    begin
        exit('MS-465444-GetVATDateFieldGLEntriesBlankUpgrade-20230301');
    end;

    procedure GetVATDateFieldSalesPurchUpgrade(): Code[250]
    begin
        exit('MS-447067-GetVATDateFieldSalesPurchUpgrade-20220830');
    end;

    internal procedure GetVATDateFieldSalesPurchBlankUpgrade(): Code[250]
    begin
        exit('MS-465444-GetVATDateFieldSalesPurchBlankUpgrade-20230301');
    end;

    procedure GetVATDateFieldIssuedDocsUpgrade(): Code[250]
    begin
        exit('MS-447067-GetVATDateFieldIssuedDocsUpgrade-20220830');
    end;

    internal procedure GetVATDateFieldIssuedDocsBlankUpgrade(): Code[250]
    begin
        exit('MS-465444-GetVATDateFieldIssuedDocsBlankUpgrade-20230301');
    end;

    procedure GetPurchaserOnRequisitionLineUpdateTag(): Code[250]
    begin
        exit('MS-449640-GetPurchaserOnRequisitionLineUpdateTag-20221117');
    end;

    procedure GetCustLedgerEntryYourReferenceUpdateTag(): Code[250]
    begin
        exit('MS-GIT-118-GetCustLedgerEntryYourReferenceUpdateTag-20230123');
    end;

    internal procedure GetErrorMessageDescriptionUpgradeTag(): Code[250]
    begin
        exit('MS-459826-GetErrorMessageDescriptionUpgradeTag-20220109');
    end;

    internal procedure GetErrorMessageRegisterDescriptionUpgradeTag(): Code[250]
    begin
        exit('MS-459826-GetErrorMessageRegisterDescriptionUpgradeTag-20220109');
    end;

    internal procedure GetSendCloudMigrationUpgradeTelemetryBaseAppTag(): Text[250]
    begin
        exit('MS-456494-CloudMigrationUptakeBaseApp-20240201');
    end;

    internal procedure GetICPartnerGLAccountNoUpgradeTag(): Code[250]
    begin
        exit('MS-290460-IntercompanySetup-20230117');
    end;

    internal procedure GetCheckWhseClassOnLocationUpgradeTag(): Code[250]
    begin
        exit('MS-345452-GetCheckWhseClassOnLocationUpgradeTag-20230127');
    end;

    internal procedure GetDeferralSourceCodeUpdateTag(): Code[250]
    begin
        exit('MS-422924-GetDeferralSourceCodeUpdateTag-20230124');
    end;

    internal procedure GetServiceLineOrderNoUpgradeTag(): Code[250]
    begin
        exit('97-GetServiceLineOrderNoUpgradeTag-20230403');
    end;

    internal procedure GetMapCurrencySymbolUpgradeTag(): Code[250]
    begin
        exit('MS-461764-GetMapCurrencySymbolUpgradeTag-20230130');
    end;

    internal procedure GetOptionMappingUpgradeTag(): Code[250]
    begin
        exit('MS-461766-GetOptionMappingUpgradeTag-20230130');
    end;

    internal procedure GetProductionSourceCodeUpdateTag(): Code[250]
    begin
        exit('MS-462109-GetProductionSourceCodeUpdateTag-20230209');
    end;

    procedure GetPurchaseCreditMemoUpgradeTag(): Code[250]
    begin
        exit('MS-466523-PurchaseCreditMemoUpgradeTag-20230323');
    end;

    procedure GetPurchasesPayablesAndSalesReceivablesSetupsUpgradeTag(): Code[250]
    begin
        exit('MS-325010-PurchasesPayablesAndSalesReceivablesSetupsUpgrade-20230414');
    end;

    procedure GetRegisterBankAccRecCopilotCapabilityUpgradeTag(): Code[250]
    begin
        exit('MS-491277-RegisterBankAccRecCopilotCapability-20231113');
    end;

    internal procedure GetReceivedFromCountryCodeUpgradeTag(): Code[250]
    begin
        exit('MS-474260-ReceivedFromCountryCode-20230531');
    end;

    internal procedure GetWorkflowDelegatedAdminSetupTemplateUpgradeTag(): Code[250]
    begin
        exit('MS-473204-GetWorkflowDelegatedAdminSetupTemplateUpgradeTag-20230531');
    end;

    internal procedure GetLocationBinPolicySetupsUpgradeTag(): Code[250]
    begin
        exit('MS-464698-LocationBinPolicySetupsUpgrade-20230602');
    end;

    internal procedure GetAllowInventoryAdjmtUpgradeTag(): Code[250]
    begin
        exit('MS-474798-AllowInventoryAdjmtUpgradeTag-20230518');
    end;

    internal procedure GetLocationGranularWarehouseHandlingSetupsUpgradeTag(): Code[250]
    begin
        exit('MS-321913-LocationGranularWarehouseHandlingSetupsUpgrade-20230710');
    end;

    internal procedure GetCheckLedgerEntriesMoveFromRecordIDToSystemIdUpgradeTag(): Code[250]
    begin
        exit('MS-484689-CheckLedgerEntriesMoveFromRecordIDToSystemIdUpgrade-20230919');
    end;

    internal procedure GetVATSetupUpgradeTag(): Code[250]
    begin
        exit('MS-478432-VATSetupUpgrade-20230717');
    end;

    internal procedure GetVATSetupAllowVATDateTag(): Code[250]
    begin
        exit('MS-474992-VATSetupAllowVATDateUpgrade-20230905');
    end;

    internal procedure GetRenderWordReportsInPlatformFeatureKeyUpgradeTag(): Code[250]
    begin
        exit('MS-487929-TurnOnRenderWordReportsInPlatformFeatureKey-20231018');
    end;

    internal procedure GetSalesShipmentCustomerIdUpgradeTag(): Code[250]
    begin
        exit('MS-487893-SalesShipmentCustomerIdUpgradeTag-20231023');
    end;

    internal procedure GetCustomReportLayoutUpgradeTag(): Code[250]
    begin
        exit('MS-491178-CustomReportLayoutUpgradeTag-20231110');
    end;

    internal procedure GetFixedAssetLocationIdUpgradeTag(): Code[250]
    begin
        exit('MS-490888-FixedAssetLocationIdUpgradeTag-20231114');
    end;

    internal procedure GetFixedAssetResponsibleEmployeeIdUpgradeTag(): Code[250]
    begin
        exit('MS-490888-FixedAssetResponsibleEmployeeIdUpgradeTag-20231114');
    end;

    internal procedure GetCopyItemSalesBlockedToServiceBlockedUpgradeTag(): Code[250]
    begin
        exit('MS-378441_CopyItemSalesBlockedToServiceBlockedUpgradeTag-20240401');
    end;

    internal procedure GetEmployeeLedgerEntryCurrencyFactorUpgradeTag(): Code[250]
    begin
        exit('MS-GIT-768_CopyItemSalesBlockedToServiceBlockedUpgradeTag-20240516');
    end;

    internal procedure GetInitShipToPhoneNoUpgradeTag(): Code[250]
    begin
        exit('MS-GIT-517-InitShipToPhoneNoUpgradeTag-20240120');
    end;

    internal procedure GetMultilineReminderTextUpgradeTag(): Code[250]
    begin
        exit('MS-535852-MultilineReminderText-20240531');
    end;

    internal procedure GetCountryVATSchemeDKTag(): Code[250]
    begin
        exit('MS-GetCountryVATSchemeDKTag-20240624');
    end;

    internal procedure GetUpgradeJobConsumpWhseHandlingForDirectedPutAwayAndPickLocationUpgradeTag(): Code[250]
    begin
        exit('MS-485770-UpgradeJobConsumpWhseHandlingForDirectedPutAwayAndPickLocationUpgradeTag-20241001');
    end;

    internal procedure GetIntegrationTableMappingTemplatesUpgradeTag(): Code[250]
    begin
        exit('MS-527500-IntegrationTableMappingTemplatesUpgradeTag-20240710');
    end;

    internal procedure GetPopulateUserSetupEmailUpgradeTag(): Code[250]
    begin
        exit('MS-GIT-736-PopulateUserSetupEmailUpgradeTag-20241117');
    end;

    internal procedure GetPurchaseCreditMemoVendorCrMemoNoUpgradeTag(): Code[250]
    begin
        exit('MS-559602-PurchaseCreditMemoVendorCrMemoNoUpgradeTag-20241206');
    end;

    internal procedure GetDefaultConsCalcBasedOnUpgradeTag(): Code[250]
    begin
        exit('MS-GIT-1052-GetDefaultConsCalcBasedOnUpgradeTag-20250203');
    end;

    internal procedure GetICOutboxTransactionSourceTypeUpgradeTag(): Code[250]
    begin
        exit('MS-557872-ICOutboxTransactionSourceTypeUpgradeTag-20251202');
    end;

    internal procedure GetManufacturingFlushingMethodActivateManualWithoutPickUpgradeTag(): Code[250]
    begin
        exit('MS-356273-ManufacturingFlushingMethodActivateManualWithoutPickUpgradeTag-20250401');
    end;

    internal procedure GetInventoryPlanningSetupUpgradeTag(): Code[250]
    begin
        exit('MS-556824-InventoryPlanningSetupUpgradeTag-20250401');
    end;

    internal procedure GetICTransactionSourceTypeUpgradeTag(): Code[250]
    begin
        exit('MS-578201-ICOutboxTransactionSourceTypeUpgradeTag-20250807');
    end;

    internal procedure GetFinancialReportDefaultsUpgradeTag(): Code[250]
    begin
        exit('GIT-1494-FinancialReportDefaultsUpgradeTag-20250801');
    end;

    internal procedure GetNewSalesPricingFeatureKeyStateTag(): Code[250]
    begin
        exit('MS-600753-NewSalesPricingFeatureKeyStateUpgradeTag-20251015');
    end;
}
