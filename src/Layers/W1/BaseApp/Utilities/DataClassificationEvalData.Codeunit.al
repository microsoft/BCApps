// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft;
using Microsoft.AccountantPortal;
using Microsoft.API;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Payment;
using Microsoft.Bank.PositivePay;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Setup;
using Microsoft.Bank.Statement;
using Microsoft.Booking;
using Microsoft.CashFlow.Account;
using Microsoft.CashFlow.Comment;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.CashFlow.Worksheet;
using Microsoft.CostAccounting.Account;
using Microsoft.CostAccounting.Allocation;
using Microsoft.CostAccounting.Budget;
using Microsoft.CostAccounting.Journal;
using Microsoft.CostAccounting.Ledger;
using Microsoft.CostAccounting.Setup;
using Microsoft.EServices.EDocument;
using Microsoft.EServices.OnlineMap;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension.Correction;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.Payroll;
using Microsoft.Finance.RoleCenters;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Reporting;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.Task;
using Microsoft.Foundation.UOM;
using Microsoft.HumanResources.Absence;
using Microsoft.HumanResources.Comment;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.Entity;
using Microsoft.Integration.Graph;
using Microsoft.Integration.SyncEngine;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.DataExchange;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Inbox;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Analysis;
using Microsoft.RoleCenters;
using System.Agents;
using System.AI;
using System.Apps;
using System.Automation;
using System.Azure.Identity;
using System.DataAdministration;
using System.Device;
using System.Diagnostics;
using System.Reflection;
using System.EMail;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Integration.PowerBI;
using System.IO;
using System.Privacy;
using System.Globalization;
using System.Security;
using System.Security.AccessControl;
using System.Security.Authentication;
using System.Security.Encryption;
using System.Security.User;
using System.TestTools;
using System.TestTools.TestRunner;
using System.Text;
using System.Threading;
using System.Tooling;
using System.Visualization;
using System.Utilities;
using System.Xml;
using System.PerformanceProfile;

codeunit 1751 "Data Classification Eval. Data"
{
    procedure CreateEvaluationData()
    var
        Company: Record Company;
        "Field": Record "Field";
        DataSensitivity: Record "Data Sensitivity";
        TableMetadata: Record "Table Metadata";
        DataClassEvalDataCountry: Codeunit "Data Class. Eval. Data Country";
    begin
        if not Company.Get(CompanyName) then
            exit;

        if not Company."Evaluation Company" then
            exit;

        Field.SetFilter(DataClassification, '%1|%2|%3',
            Field.DataClassification::CustomerContent,
            Field.DataClassification::EndUserIdentifiableInformation,
            Field.DataClassification::EndUserPseudonymousIdentifiers);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);

        if Field.FindSet() then
            repeat
                DataSensitivity."Company Name" := CopyStr(CompanyName, 1, MaxStrLen(DataSensitivity."Company Name"));
                DataSensitivity."Table No" := Field.TableNo;
                DataSensitivity."Field No" := Field."No.";
                DataSensitivity."Data Sensitivity" := DataSensitivity."Data Sensitivity"::Unclassified;
                if DataSensitivity.Insert() then;
            until Field.Next() = 0;

        ClassifyTablesPart1();
        ClassifyTablesPart2();
        ClassifyTablesPart3();

        ClassifyTablesToNormalPart1();
        ClassifyTablesToNormalPart2();
        ClassifyTablesToNormalPart3();
        ClassifyTablesToNormalPart4();
        ClassifyTablesToNormalPart5();
        ClassifyTablesToNormalPart6();
        ClassifyTablesToNormalPart7();
        ClassifyTablesToNormalPart8();
        ClassifyTablesToNormalPart9();
        ClassifyTablesToNormalPart10();
        ClassifyTablesToNormalPart11();

        OnCreateEvaluationDataOnAfterClassifyTablesToNormal();

        DataClassEvalDataCountry.ClassifyCountrySpecificTables();

        // All EUII and EUPI Fields are set to Personal
        DataSensitivity.SetFilter("Data Classification", '%1|%2',
            DataSensitivity."Data Classification"::EndUserIdentifiableInformation,
            DataSensitivity."Data Classification"::EndUserPseudonymousIdentifiers);
        DataSensitivity.ModifyAll("Data Sensitivity", DataSensitivity."Data Sensitivity"::Personal);

        TableMetadata.SetRange(ObsoleteState, TableMetadata.ObsoleteState::Removed);
        if TableMetadata.FindSet() then
            repeat
                DataSensitivity.Reset();
                DataSensitivity.SetRange("Table No", TableMetadata.ID);
                DataSensitivity.DeleteAll();
            until TableMetadata.Next() = 0;
    end;

    local procedure ClassifyTablesPart1()
    begin
        ClassifyCreditTransferEntry();
        ClassifyActiveSession();
        ClassifySEPADirectDebitMandate();
        ClassifyPurchInvEntityAggregate();
        ClassifySalesInvoiceEntityAggregate();
        ClassifySalesOrderEntityBuffer();
        ClassifySalesQuoteEntityBuffer();
        ClassifySalesCrMemoEntityBuffer();
        ClassifyPurchaseOrderEntityBuffer();
        ClassifyPurchCrMemoEntityBuffer();
        ClassifyCashFlowForecastEntry();
        ClassifyDirectDebitCollection();
        ClassifyActivityLog();
        ClassifyUserSecurityStatus();
        ClassifyCueSetup();
        ClassifyVATReportArchive();
        ClassifySessionEvent();
        ClassifyUserDefaultStyleSheet();
        ClassifyUserPlan();
        ClassifyAADApplication();
        ClassifyTokenCache();
        ClassifyTenantLicenseState();
        ClassifyFAJournalSetup();
        ClassifyCustomizedCalendarEntry();
        ClassifyAccessControl();
        ClassifyUserProperty();
        ClassifyUser();
        ClassifyConfidentialInformation();
        ClassifyOverdueApprovalEntry();
        ClassifyApplicationAreaSetup();
        ClassifyDateComprRegister();
        ClassifyEmployeeAbsence();
        ClassifyWorkflowStepInstanceArchive();
        ClassifyAlternativeAddress();
        ClassifyWorkflowStepArgument();
        ClassifyPageDataPersonalization();
        ClassifySentNotificationEntry();
        ClassifyICOutboxPurchaseHeader();
        ClassifyNotificationEntry();
        ClassifyUserPersonalization();
        ClassifyWorkflowStepInstance();
        ClassifySession();
        ClassifyIsolatedStorage();
        ClassifyNavAppSetting();
        ClassifyApprovalCommentLine();
        ClassifyJobQueueLogEntry();
        ClassifyJobQueueEntry();
        ClassifyPostedApprovalCommentLine();
        ClassifyPostedApprovalEntry();
        ClassifyApprovalEntry();
        ClassifyHandledICInboxPurchHeader();
        ClassifyHandledICInboxSalesHeader();
        ClassifyICInboxPurchaseHeader();
        ClassifyICInboxSalesHeader();
        ClassifyHandledICOutboxPurchHdr();
        ClassifyPersistentBlob();
        ClassifyPublishedApplication();
    end;

    local procedure ClassifyTablesPart2()
    begin
        ClassifyUserPageMetadata();
        ClassifyICPartner();
        ClassifyChangeLogEntry();
        ClassifyInsCoverageLedgerEntry();
        ClassifyTermsAndConditionsState();
        ClassifyDetailedCVLedgEntryBuffer();
        ClassifyAccPayablesRoleCenter();
        ClassifyPostedPaymentReconLine();
        ClassifyAppliedPaymentEntry();
        ClassifySelectedDimension();
        ClassifyConfigLine();
        ClassifyConfigPackageTable();
        ClassifyPositivePayEntryDetail();
        ClassifyICOutboxSalesHeader();
        ClassifyDirectDebitCollectionEntry();
        ClassifyCreditTransferRegister();
        ClassifyBankAccReconciliationLine();
        ClassifyBankAccRecMatchBuffer();
        ClassifyCheckLedgerEntry();
        ClassifyBankAccountLedgerEntry();
        ClassifyBookingSync();
        ClassifyVATEntry();
        ClassifyVATRegistrationLog();
        ClassifyInsuranceRegister();
        ClassifyCustomReportLayout();
        ClassifyCostBudgetRegister();
        ClassifyCostBudgetEntry();
        ClassifyCostAllocationTarget();
        ClassifyCostAllocationSource();
        ClassifyCostRegister();
        ClassifyCostEntry();
        ClassifyCostType();
        ClassifyReversalEntry();
        ClassifyIncomingDocument();
        ClassifyMaintenanceLedgerEntry();
        ClassifyFARegister();
        ClassifyMaintenanceRegistration();
        ClassifyWorkflowStepArgumentArchive();
        ClassifyGLBudgetEntry();
        ClassifyUserSetup();
        ClassifyFALedgerEntry();
    end;

    local procedure ClassifyTablesPart3()
    begin
        ClassifyHandledICOutboxSalesHeader();
        ClassifyGenJournalLine();
        ClassifyPrinterSelection();
        ClassifyGLRegister();
        ClassifyEntityText();
        ClassifyMyAccount();
        ClassifyGLEntry();
        ClassifyApiWebhookSubscripitonFields();
        ClassifyExternalEventSubscriptionFields();
        ClassifySupportInformation();
        ClassifyCRMSynchStatus();
        ClassifyRetentionPolicyLogEntry();
        ClassifyDocumentSharing();
        ClassifyEmailConnectorLogo();
        ClassifyEmailError();
        ClassifyEmailInbox();
        ClassifyEmailOutbox();
        ClassifySentEmail();
        ClassifyEmailScenarioAttachments();
        ClassifyRateLimit();
        ClassifyEmailMessage();
        ClassifyEmailRecipient();
        ClassifyEmailMessageAttachment();
        ClassifyEmailRelatedAttachments();
        ClassifyEmailLookup();
        ClassifyEmailRetry();
        ClassifyPostedGenJournalLine();
        ClassifyWordTemplate();
        ClassifyBatchProcessingSessionMap();
        ClassifyConfigPackageError();
        ClassifyBankAccount();
        ClassifyCRMOptionMapping();
        ClassifyDataExch();
        ClassifyDataMigrationError();
        ClassifyDataMigrationParameters();
        ClassifyErrorMessage();
        ClassifyIntegrationSynchJobErrors();
        ClassifyNotificationContext();
        ClassifyPaymentReportingArgument();
        ClassifyPaymentServiceSetup();
        ClassifyRestrictedRecord();
        ClassifyServiceConnection();
        ClassifyStandardAddress();
        ClassifyTempStack();
        ClassifyVATRateChangeLogEntry();
        ClassifyWorkflowEventQueue();
        ClassifyWorkflowRecordChange();
        ClassifyWorkflowRecordChangeArchive();
        ClassifyWorkflowTableRelationValue();
        ClassifyWorkflowWebhookEntry();
        ClassifyTenantWebServiceOData();
        ClassifyTenantWebServiceColumns();
        ClassifyTenantWebServiceFilter();
        ClassifyCouplingRecordBuffer();
        ClassifyCRMAnnotationBuffer();
        ClassifyCRMAnnotationCoupling();
        ClassifyCRMPostBuffer();
        ClassifyCRMSynchConflictBuffer();
        ClassifyRecordSetBuffer();
        ClassifyRecordBuffer();
        ClassifyRecordExportBuffer();
        ClassifyParallelSessionEntry();
        ClassifyWorkflowsEntriesBuffer();
        ClassifyRecordSetTree();
        ClassifyApplicationUserSettings();
        ClassifyPermissionSetInPlan();
        ClassifyFinancialReports();
        ClassifyICBankAccount();
        ClassifyAllocationAccounts();
        ClassifyAgents();
        ClassifyOrderTakerAgent();
        ClassifyExpenseAgent();
        ClasifyScheduledPerformanceProfiling();
    end;

    local procedure ClassifyFinancialReports()
    var
        FinancialReportUserFilters: Record "Financial Report User Filters";
    begin
        SetTableFieldsToNormal(Database::"Financial Report");
        SetTableFieldsToNormal(Database::"Financial Report Schedule");
        SetTableFieldsToNormal(Database::"Financial Report Export Log");
        SetTableFieldsToNormal(Database::"Financial Report Recipient");
        SetTableFieldsToNormal(Database::"Financial Report User Filters");
        SetTableFieldsToNormal(Database::"Fin. Report Excel Template");
        SetTableFieldsToNormal(Database::"Sheet Definition Name");
        SetTableFieldsToNormal(Database::"Sheet Definition Line");
        SetFieldToPersonal(Database::"Financial Report User Filters", FinancialReportUserFilters.FieldNo("User ID"));
    end;

    local procedure ClassifyTablesToNormalPart1()
    begin
        SetTableFieldsToNormal(DATABASE::"Payment Terms");
        SetTableFieldsToNormal(DATABASE::Currency);
        SetTableFieldsToNormal(DATABASE::"Standard Text");
        SetTableFieldsToNormal(DATABASE::Language);
        SetTableFieldsToNormal(DATABASE::"Country/Region");
        SetTableFieldsToNormal(DATABASE::"Shipment Method");
        SetTableFieldsToNormal(DATABASE::"Country/Region Translation");
        SetTableFieldsToNormal(DATABASE::"G/L Account");
        SetTableFieldsToNormal(DATABASE::"Rounding Method");
        SetTableFieldsToNormal(DATABASE::"Accounting Period");
        SetTableFieldsToNormal(DATABASE::"Batch Processing Parameter");
        SetTableFieldsToNormal(DATABASE::"Document Sending Profile");
        SetTableFieldsToNormal(DATABASE::"Electronic Document Format");
        SetTableFieldsToNormal(DATABASE::"Report Selections");
        SetTableFieldsToNormal(DATABASE::"Company Information");
        SetTableFieldsToNormal(DATABASE::"Gen. Journal Template");
        SetTableFieldsToNormal(DATABASE::"Acc. Schedule Name");
        SetTableFieldsToNormal(DATABASE::"Acc. Schedule Line");
        SetTableFieldsToNormal(DATABASE::"Exch. Rate Adjmt. Reg.");
        SetTableFieldsToNormal(DATABASE::"Exch. Rate Adjmt. Ledg. Entry");
        SetTableFieldsToNormal(DATABASE::"G/L Budget Name");
        SetTableFieldsToNormal(DATABASE::"Comment Line");
        SetTableFieldsToNormal(DATABASE::"Comment Line Archive");
        SetTableFieldsToNormal(DATABASE::"General Ledger Setup");
        SetTableFieldsToNormal(DATABASE::"Incoming Documents Setup");
        SetTableFieldsToNormal(DATABASE::"Acc. Sched. KPI Web Srv. Setup");
        SetTableFieldsToNormal(DATABASE::"Acc. Sched. KPI Web Srv. Line");
        SetTableFieldsToNormal(DATABASE::"Unlinked Attachment");
        SetTableFieldsToNormal(DATABASE::"ECSL VAT Report Line Relation");
        SetTableFieldsToNormal(DATABASE::"G/L Account Source Currency");
        SetTableFieldsToNormal(DATABASE::"G/L Account Where-Used");
        SetTableFieldsToNormal(DATABASE::"Work Type");
        SetTableFieldsToNormal(DATABASE::"Unit of Measure");
        SetTableFieldsToNormal(DATABASE::"Journal User Preferences");
        SetTableFieldsToNormal(DATABASE::"Business Unit");
        SetTableFieldsToNormal(DATABASE::"Gen. Jnl. Allocation");
        SetTableFieldsToNormal(DATABASE::"Post Code");
        SetTableFieldsToNormal(DATABASE::"Source Code");
        SetTableFieldsToNormal(DATABASE::"Reason Code");
        SetTableFieldsToNormal(DATABASE::"Gen. Journal Batch");
        SetTableFieldsToNormal(DATABASE::"Source Code Setup");
        SetTableFieldsToNormal(DATABASE::"VAT Reg. No. Srv Config");
        SetTableFieldsToNormal(DATABASE::"VAT Reg. No. Srv. Template");
        SetTableFieldsToNormal(DATABASE::"Gen. Business Posting Group");
        SetTableFieldsToNormal(DATABASE::"Gen. Product Posting Group");
        SetTableFieldsToNormal(DATABASE::"General Posting Setup");
        SetTableFieldsToNormal(DATABASE::"VAT Statement Template");
        SetTableFieldsToNormal(DATABASE::"VAT Statement Line");
        SetTableFieldsToNormal(DATABASE::"VAT Statement Name");
        SetTableFieldsToNormal(DATABASE::"Currency Amount");
        SetTableFieldsToNormal(DATABASE::"G/L Account Net Change");
        SetTableFieldsToNormal(DATABASE::"Bank Acc. Reconciliation");
        SetTableFieldsToNormal(DATABASE::"Ledger Entry Matching Buffer");
        SetTableFieldsToNormal(DATABASE::"Bank Account Statement");
        SetTableFieldsToNormal(DATABASE::"Bank Account Statement Line");
        SetTableFieldsToNormal(DATABASE::"Bank Account Posting Group");
        SetTableFieldsToNormal(DATABASE::"Bank Account Balance Buffer");
        SetTableFieldsToNormal(DATABASE::"Bank Pmt. Appl. Settings");
        SetTableFieldsToNormal(DATABASE::"Bank Statement Matching Buffer");
        SetTableFieldsToNormal(DATABASE::"Custom Address Format");
        SetTableFieldsToNormal(DATABASE::"Custom Address Format Line");
        SetTableFieldsToNormal(Database::"Posted Gen. Journal Batch");
        SetTableFieldsToNormal(Database::"Copy Gen. Journal Parameters");
    end;

    local procedure ClassifyTablesToNormalPart2()
    begin
        SetTableFieldsToNormal(DATABASE::"Extended Text Header");
        SetTableFieldsToNormal(DATABASE::"Extended Text Line");
        SetTableFieldsToNormal(DATABASE::"Payment Method");
        SetTableFieldsToNormal(DATABASE::"VAT Amount Line");
        SetTableFieldsToNormal(DATABASE::"Shipping Agent");
        SetTableFieldsToNormal(DATABASE::"No. Series");
        SetTableFieldsToNormal(DATABASE::"No. Series Line");
        SetTableFieldsToNormal(DATABASE::"No. Series Relationship");
        SetTableFieldsToNormal(DATABASE::"Tax Area Translation");
        SetTableFieldsToNormal(DATABASE::"Tax Area");
        SetTableFieldsToNormal(DATABASE::"Tax Area Line");
        SetTableFieldsToNormal(DATABASE::"Tax Jurisdiction");
        SetTableFieldsToNormal(DATABASE::"Tax Group");
        SetTableFieldsToNormal(DATABASE::"Tax Detail");
        SetTableFieldsToNormal(DATABASE::"VAT Business Posting Group");
        SetTableFieldsToNormal(DATABASE::"VAT Product Posting Group");
        SetTableFieldsToNormal(DATABASE::"VAT Posting Setup");
        SetTableFieldsToNormal(DATABASE::"VAT Reporting Code");
        SetTableFieldsToNormal(DATABASE::"VAT Setup");
        SetTableFieldsToNormal(DATABASE::"Alt. Cust. VAT Reg.");
        SetTableFieldsToNormal(DATABASE::"Tax Setup");
        SetTableFieldsToNormal(DATABASE::"Tax Jurisdiction Translation");
        SetTableFieldsToNormal(DATABASE::"Currency Exchange Rate");
        SetTableFieldsToNormal(DATABASE::"Column Layout Name");
        SetTableFieldsToNormal(DATABASE::"Column Layout");
        SetTableFieldsToNormal(DATABASE::"Acc. Sched. Cell Value");
        SetTableFieldsToNormal(DATABASE::Dimension);
        SetTableFieldsToNormal(DATABASE::"Dimension Value");
        SetTableFieldsToNormal(DATABASE::"Dimension Combination");
        SetTableFieldsToNormal(DATABASE::"Dimension Value Combination");
        SetTableFieldsToNormal(DATABASE::"Default Dimension");
        SetTableFieldsToNormal(DATABASE::"Default Dimension Priority");
        SetTableFieldsToNormal(DATABASE::"Dimension Set ID Filter Line");
        SetTableFieldsToNormal(DATABASE::"ECSL VAT Report Line");
        SetTableFieldsToNormal(DATABASE::"Analysis View");
        SetTableFieldsToNormal(DATABASE::"Analysis View Filter");
        SetTableFieldsToNormal(DATABASE::"G/L Account (Analysis View)");
        SetTableFieldsToNormal(DATABASE::"Object Translation");
        SetTableFieldsToNormal(DATABASE::"Report List Translation");
        SetTableFieldsToNormal(DATABASE::"VAT Registration No. Format");
        SetTableFieldsToNormal(DATABASE::"Dimension Translation");
        SetTableFieldsToNormal(DATABASE::"Change Log Setup");
        SetTableFieldsToNormal(DATABASE::"Change Log Setup (Table)");
        SetTableFieldsToNormal(DATABASE::"Change Log Setup (Field)");
        SetTableFieldsToNormal(DATABASE::"IC G/L Account");
        SetTableFieldsToNormal(DATABASE::"IC Dimension");
        SetTableFieldsToNormal(DATABASE::"IC Dimension Value");
        SetTableFieldsToNormal(DATABASE::"IC Outbox Transaction");
        SetTableFieldsToNormal(DATABASE::"IC Outbox Jnl. Line");
        SetTableFieldsToNormal(DATABASE::"Handled IC Outbox Trans.");
        SetTableFieldsToNormal(DATABASE::"Handled IC Outbox Jnl. Line");
        SetTableFieldsToNormal(DATABASE::"IC Inbox Transaction");
        SetTableFieldsToNormal(DATABASE::"IC Inbox Jnl. Line");
        SetTableFieldsToNormal(DATABASE::"Handled IC Inbox Trans.");
        SetTableFieldsToNormal(DATABASE::"Handled IC Inbox Jnl. Line");
        SetTableFieldsToNormal(DATABASE::"IC Inbox/Outbox Jnl. Line Dim.");
        SetTableFieldsToNormal(DATABASE::"IC Comment Line");
        SetTableFieldsToNormal(DATABASE::"IC Outbox Sales Line");
        SetTableFieldsToNormal(DATABASE::"IC Outbox Purchase Line");
        SetTableFieldsToNormal(DATABASE::"Handled IC Outbox Sales Line");
        SetTableFieldsToNormal(DATABASE::"Handled IC Outbox Purch. Line");
        SetTableFieldsToNormal(DATABASE::"IC Inbox Sales Line");
        SetTableFieldsToNormal(DATABASE::"IC Inbox Purchase Line");
        SetTableFieldsToNormal(DATABASE::"Handled IC Inbox Sales Line");
        SetTableFieldsToNormal(DATABASE::"Handled IC Inbox Purch. Line");
        SetTableFieldsToNormal(DATABASE::"IC Document Dimension");
        SetTableFieldsToNormal(Database::"Gen. Jnl. Dim. Filter");
    end;

    local procedure ClassifyTablesToNormalPart3()
    begin
        SetTableFieldsToNormal(DATABASE::"Payment Term Translation");
        SetTableFieldsToNormal(DATABASE::"Shipment Method Translation");
        SetTableFieldsToNormal(DATABASE::"Payment Method Translation");
        SetTableFieldsToNormal(DATABASE::"Job Queue Category");
        SetTableFieldsToNormal(DATABASE::"Dimension Set Tree Node");
        SetTableFieldsToNormal(DATABASE::"Business Chart Map");
        SetTableFieldsToNormal(DATABASE::"VAT Rate Change Setup");
        SetTableFieldsToNormal(DATABASE::"VAT Rate Change Conversion");
        SetTableFieldsToNormal(DATABASE::"VAT Clause");
        SetTableFieldsToNormal(DATABASE::"VAT Clause Translation");
        SetTableFieldsToNormal(DATABASE::"VAT Clause by Doc. Type");
        SetTableFieldsToNormal(DATABASE::"VAT Clause by Doc. Type Trans.");
        SetTableFieldsToNormal(DATABASE::"G/L Account Category");
        SetTableFieldsToNormal(DATABASE::"VAT Statement Report Line");
        SetTableFieldsToNormal(DATABASE::"VAT Report Setup");
        SetTableFieldsToNormal(DATABASE::"VAT Report Line Relation");
        SetTableFieldsToNormal(DATABASE::"VAT Report Error Log");
        SetTableFieldsToNormal(DATABASE::"VAT Reports Configuration");
        SetTableFieldsToNormal(DATABASE::"Standard General Journal");
        SetTableFieldsToNormal(DATABASE::"Standard General Journal Line");
        SetTableFieldsToNormal(DATABASE::"Online Bank Acc. Link");
        SetTableFieldsToNormal(DATABASE::"Certificate of Supply");
        SetTableFieldsToNormal(DATABASE::"Online Map Setup");
        SetTableFieldsToNormal(DATABASE::"Online Map Parameter Setup");
        SetTableFieldsToNormal(DATABASE::Geolocation);
        SetTableFieldsToNormal(DATABASE::"Cash Flow Account");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Account Comment");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Availability Buffer");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Setup");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Worksheet Line");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Manual Revenue");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Manual Expense");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Azure AI Buffer");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Report Selection");
        SetTableFieldsToNormal(DATABASE::"Excel Template Storage");
        SetTableFieldsToNormal(DATABASE::"Document Search Result");
        SetTableFieldsToNormal(DATABASE::"Cost Journal Template");
        SetTableFieldsToNormal(DATABASE::"Cost Journal Line");
        SetTableFieldsToNormal(DATABASE::"Cost Journal Batch");
        SetTableFieldsToNormal(DATABASE::"Cost Accounting Setup");
        SetTableFieldsToNormal(DATABASE::"Cost Budget Buffer");
        SetTableFieldsToNormal(DATABASE::"Cost Budget Name");
        SetTableFieldsToNormal(DATABASE::"Cost Center");
        SetTableFieldsToNormal(DATABASE::"Cost Object");
        SetTableFieldsToNormal(DATABASE::"Document Attachment");
        SetTableFieldsToNormal(DATABASE::"Bank Export/Import Setup");
        SetTableFieldsToNormal(DATABASE::"Data Exchange Type");
        SetTableFieldsToNormal(DATABASE::"Intermediate Data Import");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Field");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Def");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Column Def");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Mapping");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Field Grouping");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Field Mapping");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Table Filter");
        SetTableFieldsToNormal(DATABASE::"Payment Export Data");
        SetTableFieldsToNormal(DATABASE::"Data Exch. Line Def");
        SetTableFieldsToNormal(DATABASE::"Payment Jnl. Export Error Text");
        SetTableFieldsToNormal(DATABASE::"Payment Export Remittance Text");
        SetTableFieldsToNormal(DATABASE::"Payment Registration Buffer");
        SetTableFieldsToNormal(DATABASE::"Payment Rec. Related Entry");
        SetTableFieldsToNormal(DATABASE::"Pmt. Rec. Applied-to Entry");
        SetTableFieldsToNormal(DATABASE::"Transformation Rule");
        SetTableFieldsToNormal(DATABASE::"Positive Pay Header");
        SetTableFieldsToNormal(DATABASE::"Positive Pay Detail");
        SetTableFieldsToNormal(DATABASE::"Positive Pay Footer");
        SetTableFieldsToNormal(DATABASE::"Bank Stmt Multiple Match Line");
        SetTableFieldsToNormal(DATABASE::"Text-to-Account Mapping");
        SetTableFieldsToNormal(DATABASE::"Bank Pmt. Appl. Rule");
        SetTableFieldsToNormal(DATABASE::"OCR Service Document Template");
        SetTableFieldsToNormal(DATABASE::"Bank Clearing Standard");
        SetTableFieldsToNormal(DATABASE::"Outstanding Bank Transaction");
        SetTableFieldsToNormal(DATABASE::"Payment Application Proposal");
    end;

    local procedure ClassifyTablesToNormalPart4()
    begin
        SetTableFieldsToNormal(DATABASE::"Posted Payment Recon. Hdr");
        SetTableFieldsToNormal(DATABASE::"Payment Matching Details");
        SetTableFieldsToNormal(DATABASE::"Dimensions Template");
        SetTableFieldsToNormal(DATABASE::"O365 Device Setup Instructions");
        SetTableFieldsToNormal(DATABASE::"O365 Getting Started Page Data");
        SetTableFieldsToNormal(DATABASE::"Chart Definition");
        SetTableFieldsToNormal(DATABASE::"Last Used Chart");
        SetTableFieldsToNormal(DATABASE::"Trial Balance Setup");
        SetTableFieldsToNormal(DATABASE::"Activities Cue");
        SetTableFieldsToNormal(DATABASE::"Approvals Activities Cue");
        SetTableFieldsToNormal(1432); // Net Promoter Score Setup
        SetTableFieldsToNormal(1471); // Table "Product Video Category"
        SetTableFieldsToNormal(DATABASE::Workflow);
        SetTableFieldsToNormal(DATABASE::"Workflow Step");
        SetTableFieldsToNormal(DATABASE::"Workflow - Table Relation");
        SetTableFieldsToNormal(DATABASE::"Workflow Category");
        SetTableFieldsToNormal(DATABASE::"WF Event/Response Combination");
        SetTableFieldsToNormal(DATABASE::"Dynamic Request Page Entity");
        SetTableFieldsToNormal(DATABASE::"Dynamic Request Page Field");
        SetTableFieldsToNormal(DATABASE::"Workflow Event");
        SetTableFieldsToNormal(DATABASE::"Workflow Response");
        SetTableFieldsToNormal(DATABASE::"Workflow Rule");
        SetTableFieldsToNormal(DATABASE::"Workflow User Group");
        SetTableFieldsToNormal(DATABASE::"Flow Service Configuration");
        SetTableFieldsToNormal(DATABASE::"Flow User Environment Config");
        SetTableFieldsToNormal(DATABASE::"Invoiced Booking Item");
        SetTableFieldsToNormal(DATABASE::"Curr. Exch. Rate Update Setup");
        SetTableFieldsToNormal(DATABASE::"Import G/L Transaction");
        SetTableFieldsToNormal(DATABASE::"Deferral Template");
        SetTableFieldsToNormal(DATABASE::"Deferral Header");
        SetTableFieldsToNormal(DATABASE::"Deferral Line");
        SetTableFieldsToNormal(DATABASE::"Posted Deferral Header");
        SetTableFieldsToNormal(DATABASE::"Posted Deferral Line");
        SetTableFieldsToNormal(DATABASE::"Data Migration Status");
        SetTableFieldsToNormal(DATABASE::"Data Migrator Registration");
        SetTableFieldsToNormal(DATABASE::"Data Migration Entity");
        SetTableFieldsToNormal(DATABASE::"Assisted Company Setup Status");
        SetTableFieldsToNormal(1803); // Assisted Setup table
        SetTableFieldsToNormal(DATABASE::"Data Migration Setup");
        SetTableFieldsToNormal(1807); // Assisted Setup Log table
        SetTableFieldsToNormal(1808); // Aggregated Assisted Setup table
        SetTableFieldsToNormal(1810); // Assisted Setup Icons table
        SetTableFieldsToNormal(DATABASE::"Business Unit Setup");
        SetTableFieldsToNormal(DATABASE::"Business Unit Information");
        SetTableFieldsToNormal(DATABASE::"Consolidation Account");
        SetTableFieldsToNormal(Database::"Consolidation Process");
        SetTableFieldsToNormal(Database::"Bus. Unit In Cons. Process");
        SetTableFieldsToNormal(Database::"Consolidation Setup");
        SetTableFieldsToNormal(3700); // "Manual Setup" table
        SetTableFieldsToNormal(1876); // "Business Setup Icon" table
        SetTableFieldsToNormal(DATABASE::"VAT Setup Posting Groups");
        SetTableFieldsToNormal(DATABASE::"VAT Assisted Setup Templates");
        SetTableFieldsToNormal(DATABASE::"VAT Assisted Setup Bus. Grp.");
        SetTableFieldsToNormal(DATABASE::"Cancelled Document");
        SetTableFieldsToNormal(DATABASE::"Time Series Forecast");
        SetTableFieldsToNormal(2004); // Azure AI Usage table
        SetTableFieldsToNormal(DATABASE::"Image Analysis Setup");
        SetTableFieldsToNormal(DATABASE::"Image Analysis Scenario");
        SetTableFieldsToNormal(DATABASE::"O365 HTML Template");
        SetTableFieldsToNormal(DATABASE::"O365 Payment Service Logo");
        SetTableFieldsToNormal(DATABASE::"O365 Brand Color");
        SetTableFieldsToNormal(Database::"Employee Templ.");
    end;

    local procedure ClassifyTablesToNormalPart5()
    begin
        SetTableFieldsToNormal(DATABASE::"Deferral Header Archive");
        SetTableFieldsToNormal(DATABASE::"Deferral Line Archive");
        SetTableFieldsToNormal(DATABASE::"Alternative Address");
        SetTableFieldsToNormal(DATABASE::Qualification);
        SetTableFieldsToNormal(DATABASE::Relative);
        SetTableFieldsToNormal(DATABASE::"Human Resource Comment Line");
        SetTableFieldsToNormal(Database::Nationality);
        SetTableFieldsToNormal(DATABASE::Union);
        SetTableFieldsToNormal(DATABASE::"Cause of Inactivity");
        SetTableFieldsToNormal(DATABASE::"Employment Contract");
        SetTableFieldsToNormal(DATABASE::"Employee Statistics Group");
        SetTableFieldsToNormal(DATABASE::"Misc. Article");
        SetTableFieldsToNormal(DATABASE::"Misc. Article Information");
        SetTableFieldsToNormal(DATABASE::Confidential);
        SetTableFieldsToNormal(DATABASE::"Grounds for Termination");
        SetTableFieldsToNormal(DATABASE::"Human Resources Setup");
        SetTableFieldsToNormal(DATABASE::"HR Confidential Comment Line");
        SetTableFieldsToNormal(DATABASE::"Human Resource Unit of Measure");
        SetTableFieldsToNormal(DATABASE::"CRM Redirect");
        SetTableFieldsToNormal(DATABASE::"CRM Integration Record");
        SetTableFieldsToNormal(DATABASE::"Integration Table Mapping");
        SetTableFieldsToNormal(DATABASE::"Integration Field Mapping");
        SetTableFieldsToNormal(DATABASE::"Man. Integration Table Mapping");
        SetTableFieldsToNormal(DATABASE::"Temp Integration Field Mapping");
        SetTableFieldsToNormal(DATABASE::"Man. Int. Field Mapping");
        SetTableFieldsToNormal(DATABASE::"Integration Synch. Job");
        SetTableFieldsToNormal(DATABASE::"CRM Systemuser");
        SetTableFieldsToNormal(DATABASE::"CRM Account");
        SetTableFieldsToNormal(DATABASE::"CRM Contact");
        SetTableFieldsToNormal(DATABASE::"CRM Opportunity");
        SetTableFieldsToNormal(DATABASE::"CRM Post");
        SetTableFieldsToNormal(DATABASE::"CRM Transactioncurrency");
        SetTableFieldsToNormal(DATABASE::"CRM Pricelevel");
        SetTableFieldsToNormal(DATABASE::"CRM Productpricelevel");
        SetTableFieldsToNormal(DATABASE::"CRM Product");
        SetTableFieldsToNormal(DATABASE::"CRM Incident");
        SetTableFieldsToNormal(DATABASE::"CRM Incidentresolution");
        SetTableFieldsToNormal(DATABASE::"CRM Quote");
        SetTableFieldsToNormal(DATABASE::"CDS Company");
        SetTableFieldsToNormal(DATABASE::"CDS Solution");
        SetTableFieldsToNormal(DATABASE::"CDS Teamroles");
        SetTableFieldsToNormal(DATABASE::"CDS Teammembership");
        SetTableFieldsToNormal(DATABASE::"CRM Company");
        SetTableFieldsToNormal(DATABASE::"CRM BC Virtual Table Config.");
    end;

    local procedure ClassifyTablesToNormalPart6()
    begin
        SetTableFieldsToNormal(DATABASE::"CRM Quotedetail");
        SetTableFieldsToNormal(DATABASE::"CRM Salesorder");
        SetTableFieldsToNormal(DATABASE::"CRM Salesorderdetail");
        SetTableFieldsToNormal(DATABASE::"CRM Invoice");
        SetTableFieldsToNormal(DATABASE::"CRM Invoicedetail");
        SetTableFieldsToNormal(DATABASE::"CRM Contract");
        SetTableFieldsToNormal(DATABASE::"CRM Team");
        SetTableFieldsToNormal(DATABASE::"CRM Customeraddress");
        SetTableFieldsToNormal(DATABASE::"CRM Uom");
        SetTableFieldsToNormal(DATABASE::"CRM Uomschedule");
        SetTableFieldsToNormal(DATABASE::"CRM Organization");
        SetTableFieldsToNormal(DATABASE::"CRM Businessunit");
        SetTableFieldsToNormal(DATABASE::"CRM Discount");
        SetTableFieldsToNormal(DATABASE::"CRM Discounttype");
        SetTableFieldsToNormal(DATABASE::"CRM Account Statistics");
        SetTableFieldsToNormal(DATABASE::"CRM NAV Connection");
        SetTableFieldsToNormal(DATABASE::"CRM Synch. Job Status Cue");
        SetTableFieldsToNormal(DATABASE::"CRM Full Synch. Review Line");
        SetTableFieldsToNormal(DATABASE::"Unit of Measure Translation");
        SetTableFieldsToNormal(DATABASE::"API Entities Setup");
        SetTableFieldsToNormal(DATABASE::"Sales Invoice Line Aggregate");
        SetTableFieldsToNormal(DATABASE::"Purch. Inv. Line Aggregate");
        SetTableFieldsToNormal(DATABASE::"Aged Report Entity");
        SetTableFieldsToNormal(DATABASE::"Acc. Schedule Line Entity");
        SetTableFieldsToNormal(DATABASE::"Fixed Asset");
        SetTableFieldsToNormal(DATABASE::"FA Setup");
        SetTableFieldsToNormal(DATABASE::"FA Posting Type Setup");
        SetTableFieldsToNormal(DATABASE::"FA Posting Group");
        SetTableFieldsToNormal(DATABASE::"FA Class");
        SetTableFieldsToNormal(DATABASE::"FA Subclass");
        SetTableFieldsToNormal(DATABASE::"FA Location");
        SetTableFieldsToNormal(DATABASE::"Depreciation Book");
        SetTableFieldsToNormal(DATABASE::"FA Depreciation Book");
        SetTableFieldsToNormal(DATABASE::"FA Allocation");
        SetTableFieldsToNormal(DATABASE::"FA Journal Template");
        SetTableFieldsToNormal(DATABASE::"FA Journal Batch");
        SetTableFieldsToNormal(DATABASE::"FA Journal Line");
        SetTableFieldsToNormal(DATABASE::"FA Reclass. Journal Template");
        SetTableFieldsToNormal(DATABASE::"FA Reclass. Journal Batch");
        SetTableFieldsToNormal(DATABASE::"FA Reclass. Journal Line");
        SetTableFieldsToNormal(DATABASE::Maintenance);
        SetTableFieldsToNormal(DATABASE::Insurance);
        SetTableFieldsToNormal(DATABASE::"Insurance Type");
        SetTableFieldsToNormal(DATABASE::"Insurance Journal Template");
        SetTableFieldsToNormal(DATABASE::"Insurance Journal Batch");
        SetTableFieldsToNormal(DATABASE::"Insurance Journal Line");
        SetTableFieldsToNormal(DATABASE::"Main Asset Component");
        SetTableFieldsToNormal(DATABASE::"Depreciation Table Header");
        SetTableFieldsToNormal(DATABASE::"Depreciation Table Line");
        SetTableFieldsToNormal(DATABASE::"FA Posting Type");
        SetTableFieldsToNormal(DATABASE::"FA Date Type");
        SetTableFieldsToNormal(DATABASE::"FA Matrix Posting Type");
        SetTableFieldsToNormal(DATABASE::"Total Value Insured");
    end;

    local procedure ClassifyTablesToNormalPart7()
    begin
        SetTableFieldsToNormal(DATABASE::"Shipping Agent Services");
        SetTableFieldsToNormal(DATABASE::"Azure AD App Setup");
        SetTableFieldsToNormal(DATABASE::"Azure AD Mgt. Setup");
        SetTableFieldsToNormal(DATABASE::"Return Reason");
        SetTableFieldsToNormal(DATABASE::"Booking Service");
        SetTableFieldsToNormal(DATABASE::"Booking Mailbox");
        SetTableFieldsToNormal(DATABASE::"Booking Staff");
        SetTableFieldsToNormal(DATABASE::"Booking Service Mapping");
        SetTableFieldsToNormal(DATABASE::"Booking Item");
        SetTableFieldsToNormal(DATABASE::"Booking Mgr. Setup");
        SetTableFieldsToNormal(DATABASE::"Price Calculation Buffer");
        SetTableFieldsToNormal(DATABASE::"Price Calculation Setup");
        SetTableFieldsToNormal(DATABASE::"Dtld. Price Calculation Setup");
        SetTableFieldsToNormal(DATABASE::"Price List Header");
        SetTableFieldsToNormal(DATABASE::"Price List Line");
        SetTableFieldsToNormal(DATABASE::"Price Asset");
        SetTableFieldsToNormal(DATABASE::"Price Source");
        SetTableFieldsToNormal(DATABASE::"Price Worksheet Line");
    end;

    local procedure ClassifyTablesToNormalPart8()
    begin
        SetTableFieldsToNormal(DATABASE::"Base Calendar");
        SetTableFieldsToNormal(DATABASE::"Base Calendar Change");
        SetTableFieldsToNormal(DATABASE::"Customized Calendar Change");
        SetTableFieldsToNormal(DATABASE::"Where Used Base Calendar");
        SetTableFieldsToNormal(DATABASE::"MS-QBD Setup");
        SetTableFieldsToNormal(DATABASE::"Dimensions Field Map");
        SetTableFieldsToNormal(DATABASE::"Record Set Definition");
        SetTableFieldsToNormal(DATABASE::"Config. Questionnaire");
        SetTableFieldsToNormal(DATABASE::"Config. Question Area");
        SetTableFieldsToNormal(DATABASE::"Config. Question");
        SetTableFieldsToNormal(DATABASE::"Config. Package Record");
        SetTableFieldsToNormal(DATABASE::"Config. Package Data");
        SetTableFieldsToNormal(DATABASE::"Config. Package Field");
        SetTableFieldsToNormal(DATABASE::"Config. Template Header");
        SetTableFieldsToNormal(DATABASE::"Config. Template Line");
        SetTableFieldsToNormal(DATABASE::"Config. Tmpl. Selection Rules");
        SetTableFieldsToNormal(DATABASE::"Config. Selection");
        SetTableFieldsToNormal(DATABASE::"Config. Package");
        SetTableFieldsToNormal(DATABASE::"Config. Related Field");
        SetTableFieldsToNormal(DATABASE::"Config. Related Table");
        SetTableFieldsToNormal(DATABASE::"Config. Package Filter");
        SetTableFieldsToNormal(DATABASE::"Config. Setup");
        SetTableFieldsToNormal(DATABASE::"Config. Field Map");
        SetTableFieldsToNormal(DATABASE::"Config. Table Processing Rule");
        SetTableFieldsToNormal(DATABASE::"Config. Record For Processing");
        SetTableFieldsToNormal(9020); // Security Group
        SetTableFieldsToNormal(DATABASE::"Team Member Cue");
        SetTableFieldsToNormal(DATABASE::"Finance Cue");
        SetTableFieldsToNormal(DATABASE::"Administration Cue");
        SetTableFieldsToNormal(DATABASE::"SB Owner Cue");
        SetTableFieldsToNormal(DATABASE::"RapidStart Services Cue");
        SetTableFieldsToNormal(DATABASE::"User Security Status");
    end;

    local procedure ClassifyTablesToNormalPart9()
    begin
        SetTableFieldsToNormal(DATABASE::"Accounting Services Cue");
        SetTableFieldsToNormal(DATABASE::"Autocomplete Address");
        SetTableFieldsToNormal(DATABASE::"Postcode Service Config");
        SetTableFieldsToNormal(DATABASE::"Experience Tier Setup");
        SetTableFieldsToNormal(DATABASE::"Generic Chart Setup");
        SetTableFieldsToNormal(DATABASE::"Generic Chart Filter");
        SetTableFieldsToNormal(DATABASE::"Generic Chart Y-Axis");
        SetTableFieldsToNormal(DATABASE::"Generic Chart Query Column");
        SetTableFieldsToNormal(DATABASE::"Terms And Conditions");
        SetTableFieldsToNormal(DATABASE::"Media Repository");
        SetTableFieldsToNormal(DATABASE::"Email Item");
        SetTableFieldsToNormal(DATABASE::"Email Parameter");
        SetTableFieldsToNormal(DATABASE::"XML Schema");
        SetTableFieldsToNormal(DATABASE::"XML Schema Element");
        SetTableFieldsToNormal(DATABASE::"XML Schema Restriction");
        SetTableFieldsToNormal(DATABASE::"Referenced XML Schema");
        SetTableFieldsToNormal(DATABASE::"Report Layout Selection");
        SetTableFieldsToNormal(DATABASE::"Report Layout Update Log");
        SetTableFieldsToNormal(DATABASE::"Custom Report Selection");
        SetTableFieldsToNormal(DATABASE::"Table Filter");
        SetTableFieldsToNormal(DATABASE::"Web Service Aggregate");
        SetTableFieldsToNormal(DATABASE::"CAL Test Suite");
        SetTableFieldsToNormal(DATABASE::"CAL Test Line");
        SetTableFieldsToNormal(DATABASE::"CAL Test Codeunit");
        SetTableFieldsToNormal(DATABASE::"CAL Test Enabled Codeunit");
        SetTableFieldsToNormal(DATABASE::"CAL Test Method");
        SetTableFieldsToNormal(DATABASE::"CAL Test Result");
        SetTableFieldsToNormal(DATABASE::"CAL Test Coverage Map");
        SetTableFieldsToNormal(DATABASE::"Semi-Manual Test Wizard");
        SetTableFieldsToNormal(DATABASE::"Semi-Manual Execution Log");
        SetTableFieldsToNormal(DATABASE::"Company Size");
    end;

    local procedure ClassifyTablesToNormalPart10()
    begin
        SetTableFieldsToNormal(DATABASE::"Incoming Document Attachment");
        SetTableFieldsToNormal(DATABASE::"License Agreement");
        SetTableFieldsToNormal(DATABASE::"G/L Entry - VAT Entry Link");
        SetTableFieldsToNormal(DATABASE::"Document Entry");
        SetTableFieldsToNormal(DATABASE::"Analysis View Entry");
        SetTableFieldsToNormal(DATABASE::"Analysis View Budget Entry");
        SetTableFieldsToNormal(DATABASE::"Workflow Webhook Notification");
        SetTableFieldsToNormal(DATABASE::"Workflow Webhook Subscription");
        SetTableFieldsToNormal(DATABASE::"Report Inbox");
        SetTableFieldsToNormal(DATABASE::"Dimension Set Entry");
        SetTableFieldsToNormal(DATABASE::"Change Global Dim. Log Entry");
        SetTableFieldsToNormal(DATABASE::"Business Chart User Setup");
        SetTableFieldsToNormal(DATABASE::"VAT Report Line");
        SetTableFieldsToNormal(DATABASE::"Account Schedules Chart Setup");
        SetTableFieldsToNormal(DATABASE::"Acc. Sched. Chart Setup Line");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Forecast");
        SetTableFieldsToNormal(DATABASE::"Cash Flow Chart Setup");
        SetTableFieldsToNormal(DATABASE::"Payment Registration Setup");
        SetTableFieldsToNormal(DATABASE::"User Task");
        SetTableFieldsToNormal(DATABASE::"User Task Group");
        SetTableFieldsToNormal(DATABASE::"User Task Group Member");
        SetTableFieldsToNormal(DATABASE::"Job Queue Role Center Cue");
        SetTableFieldsToNormal(DATABASE::"Job Queue Notified Admin");
        SetTableFieldsToNormal(DATABASE::"Job Queue Notification Setup");
        SetTableFieldsToNormal(DATABASE::"Credit Trans Re-export History");
        SetTableFieldsToNormal(DATABASE::"Positive Pay Entry");
        SetTableFieldsToNormal(DATABASE::"OCR Service Setup");
        SetTableFieldsToNormal(DATABASE::"Doc. Exch. Service Setup");
        SetTableFieldsToNormal(DATABASE::"User Preference");
        SetTableFieldsToNormal(DATABASE::"O365 Getting Started");
        SetTableFieldsToNormal(DATABASE::"User Tours");
        SetTableFieldsToNormal(DATABASE::"Role Center Notifications");
        SetTableFieldsToNormal(1433); // Net Promoter Score
        SetTableFieldsToNormal(DATABASE::"Notification Setup");
        SetTableFieldsToNormal(DATABASE::"Notification Schedule");
        SetTableFieldsToNormal(DATABASE::"My Notifications");
        SetTableFieldsToNormal(DATABASE::"Workflow User Group Member");
        SetTableFieldsToNormal(DATABASE::"Payroll Setup");
        SetTableFieldsToNormal(DATABASE::"Approval Workflow Wizard");
    end;

    local procedure ClassifyTablesToNormalPart11()
    begin
        SetTableFieldsToNormal(DATABASE::"CRM Connection Setup");
        SetTableFieldsToNormal(DATABASE::"Power BI Selection Element");
        SetTableFieldsToNormal(DATABASE::"Power BI Displayed Element");
        SetTableFieldsToNormal(DATABASE::"Power BI Report Uploads");
        SetTableFieldsToNormal(DATABASE::"Power BI Context Settings");
        SetTableFieldsToNormal(DATABASE::"Power BI Customer Reports");
        SetTableFieldsToNormal(DATABASE::"Power BI Blob");
        SetTableFieldsToNormal(DATABASE::"Power BI Default Selection");
        SetTableFieldsToNormal(DATABASE::"Profile Designer Diagnostic");
        SetTableFieldsToNormal(DATABASE::"Designer Diagnostic");
        SetTableFieldsToNormal(DATABASE::"Profile Import");
        SetTableFieldsToNormal(9004); // Plan
        SetTableFieldsToNormal(9008); // User Login
        SetTableFieldsToNormal(9010); // "Azure AD User Update"
        SetTableFieldsToNormal(DATABASE::"Order Tracking Entry");
        SetTableFieldsToNormal(DATABASE::"Record Link");
        SetTableFieldsToNormal(DATABASE::"Document Service");
        SetTableFieldsToNormal(DATABASE::"Data Privacy Entities");
        SetTableFieldsToNormal(DATABASE::"Isolated Certificate");
        SetTableFieldsToNormal(DATABASE::"No. Series Tenant");
        SetTableFieldsToNormal(DATABASE::"OAuth 2.0 Setup");
        SetTableFieldsToNormal(DATABASE::"SWIFT Code");
        SetTableFieldsToNormal(DATABASE::"Trial Balance Cache Info");
        SetTableFieldsToNormal(DATABASE::"Trial Balance Cache");
        SetTableFieldsToNormal(3712); // Translation
        SetTableFieldsToNormal(DATABASE::"CRM Synch Status");
        SetTableFieldsToNormal(DATABASE::"Designed Query");
        SetTableFieldsToNormal(DATABASE::"Designed Query Caption");
        SetTableFieldsToNormal(DATABASE::"Designed Query Category");
        SetTableFieldsToNormal(DATABASE::"Designed Query Column Filter");
        SetTableFieldsToNormal(DATABASE::"Designed Query Column");
        SetTableFieldsToNormal(DATABASE::"Designed Query Data Item");
        SetTableFieldsToNormal(DATABASE::"Designed Query Filter");
        SetTableFieldsToNormal(DATABASE::"Designed Query Join");
        SetTableFieldsToNormal(DATABASE::"Designed Query Order By");
        SetTableFieldsToNormal(Database::"Dim Correct Selection Criteria");
        SetTableFieldsToNormal(Database::"Dim Correction Blocked Setup");
        SetTableFieldsToNormal(Database::"Dim Correction Change");
        SetTableFieldsToNormal(Database::"Dim Correction Set Buffer");
        SetTableFieldsToNormal(Database::"Dim Correction Entry Log");
        SetTableFieldsToNormal(Database::"Dimension Correction");
        SetTableFieldsToNormal(Database::"Invalidated Dim Correction");
        SetTableFieldsToNormal(Database::"Retention Period");
        SetTableFieldsToNormal(Database::"Retention Policy Setup");
        SetTableFieldsToNormal(Database::"Retention Policy Setup Line");
        SetTableFieldsToNormal(3903); // Database::"Reten. Pol. Allowed Table"
        SetTableFieldsToNormal(Database::"Feature Data Update Status");
        SetTableFieldsToNormal(Database::"OData Initialized Status");
        SetTableFieldsToNormal(149000); // Database::"BCPT Header"
        SetTableFieldsToNormal(149001); // Database::"BCPT Line"
        SetTableFieldsToNormal(149002); // Database::"BCPT Log Entry"
        SetTableFieldsToNormal(149003); // Database::"BCPT Parameter Line"
        SetTableFieldsToNormal(Database::"IC Setup");
        SetTableFieldsToNormal(Database::"Net Balances Parameters");
        SetTableFieldsToNormal(9017); // Database::"Plan Configuration"
        SetTableFieldsToNormal(Database::"Buffer IC Comment Line");
        SetTableFieldsToNormal(Database::"Buffer IC Document Dimension");
        SetTableFieldsToNormal(Database::"Buffer IC Inbox Jnl. Line");
        SetTableFieldsToNormal(Database::"Buffer IC Inbox Purch Header");
        SetTableFieldsToNormal(Database::"Buffer IC Inbox Purchase Line");
        SetTableFieldsToNormal(Database::"Buffer IC Inbox Sales Header");
        SetTableFieldsToNormal(Database::"Buffer IC Inbox Sales Line");
        SetTableFieldsToNormal(Database::"Buffer IC Inbox Transaction");
        SetTableFieldsToNormal(Database::"Buffer IC InOut Jnl. Line Dim.");
        SetTableFieldsToNormal(Database::"IC Incoming Notification");
        SetTableFieldsToNormal(Database::"IC Outgoing Notification");
    end;

    procedure SetTableFieldsToNormal(TableNo: Integer)
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SetTableFieldsToNormal(TableNo);
    end;

    local procedure SetFieldToPersonal(TableNo: Integer; FieldNo: Integer)
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SetFieldToPersonal(TableNo, FieldNo);
    end;

    local procedure SetFieldToSensitive(TableNo: Integer; FieldNo: Integer)
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SetFieldToSensitive(TableNo, FieldNo);
    end;

    local procedure SetFieldToCompanyConfidential(TableNo: Integer; FieldNo: Integer)
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SetFieldToCompanyConfidential(TableNo, FieldNo);
    end;

    local procedure ClassifyCouplingRecordBuffer()
    var
        DummyCouplingRecordBuffer: Record "Coupling Record Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Coupling Record Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCouplingRecordBuffer.FieldNo("NAV Record ID"));
    end;

    local procedure ClassifyCRMAnnotationBuffer()
    var
        DummyCRMAnnotationBuffer: Record "CRM Annotation Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"CRM Annotation Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCRMAnnotationBuffer.FieldNo("Related Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCRMAnnotationBuffer.FieldNo("Record ID"));
    end;

    local procedure ClassifyCRMAnnotationCoupling()
    var
        DummyCRMAnnotationCoupling: Record "CRM Annotation Coupling";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"CRM Annotation Coupling";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCRMAnnotationCoupling.FieldNo("Record Link Record ID"));
    end;

    local procedure ClassifyAllocationAccounts()
    begin
        SetTableFieldsToNormal(DATABASE::"Alloc. Acc. Manual Override");
        SetTableFieldsToNormal(DATABASE::"Alloc. Account Distribution");
        SetTableFieldsToNormal(DATABASE::"Allocation Account");
        SetTableFieldsToNormal(DATABASE::"Allocation Line");
    end;

    local procedure ClassifyCRMPostBuffer()
    var
        DummyCRMPostBuffer: Record "CRM Post Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"CRM Post Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCRMPostBuffer.FieldNo(RecId));
    end;

    local procedure ClassifyCRMSynchConflictBuffer()
    var
        DummyCRMSynchConflictBuffer: Record "CRM Synch. Conflict Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"CRM Synch. Conflict Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCRMSynchConflictBuffer.FieldNo("Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCRMSynchConflictBuffer.FieldNo("Int. Record ID"));
    end;

    local procedure ClassifyRecordSetBuffer()
    var
        DummyRecordSetBuffer: Record "Record Set Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Record Set Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyRecordSetBuffer.FieldNo("Value RecordID"));
    end;

    local procedure ClassifyRecordBuffer()
    var
        DummyRecordBuffer: Record "Record Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Record Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyRecordBuffer.FieldNo("Record Identifier"));
    end;

    local procedure ClassifyRecordExportBuffer()
    var
        DummyRecordExportBuffer: Record "Record Export Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Record Export Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyRecordExportBuffer.FieldNo(RecordID));
    end;

    local procedure ClassifyParallelSessionEntry()
    var
        DummyParallelSessionEntry: Record "Parallel Session Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Parallel Session Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyParallelSessionEntry.FieldNo("Record ID to Process"));
    end;

    local procedure ClassifyWorkflowsEntriesBuffer()
    var
        DummyWorkflowsEntriesBuffer: Record "Workflows Entries Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflows Entries Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowsEntriesBuffer.FieldNo("Record ID"));
    end;

    local procedure ClassifyTenantWebServiceOData()
    var
        DummyTenantWebServiceOData: Record "Tenant Web Service OData";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Tenant Web Service OData";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyTenantWebServiceOData.FieldNo(TenantWebServiceID));
    end;

    local procedure ClassifyTenantWebServiceColumns()
    var
        DummyTenantWebServiceColumns: Record "Tenant Web Service Columns";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Tenant Web Service Columns";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyTenantWebServiceColumns.FieldNo(TenantWebServiceID));
    end;

    local procedure ClassifyTenantWebServiceFilter()
    var
        DummyTenantWebServiceFilter: Record "Tenant Web Service Filter";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Tenant Web Service Filter";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyTenantWebServiceFilter.FieldNo(TenantWebServiceID));
    end;

    local procedure ClassifyWorkflowWebhookEntry()
    var
        DummyWorkflowWebhookEntry: Record "Workflow Webhook Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Webhook Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowWebhookEntry.FieldNo("Record ID"));
    end;

    local procedure ClassifyWorkflowTableRelationValue()
    var
        DummyWorkflowTableRelationValue: Record "Workflow Table Relation Value";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Table Relation Value";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowTableRelationValue.FieldNo("Record ID"));
    end;

    local procedure ClassifyWorkflowRecordChangeArchive()
    var
        DummyWorkflowRecordChangeArchive: Record "Workflow Record Change Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Record Change Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowRecordChangeArchive.FieldNo("Record ID"));
    end;

    local procedure ClassifyWorkflowRecordChange()
    var
        DummyWorkflowWorkflowRecordChange: Record "Workflow - Record Change";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow - Record Change";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowWorkflowRecordChange.FieldNo("Record ID"));
    end;

    local procedure ClassifyWorkflowEventQueue()
    var
        DummyWorkflowEventQueue: Record "Workflow Event Queue";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Event Queue";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowEventQueue.FieldNo("Step Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowEventQueue.FieldNo("Record ID"));
    end;

    local procedure ClassifyVATRateChangeLogEntry()
    var
        DummyVATRateChangeLogEntry: Record "VAT Rate Change Log Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"VAT Rate Change Log Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyVATRateChangeLogEntry.FieldNo("Record ID"));
    end;

    local procedure ClassifyTempStack()
    var
        DummyTempStack: Record TempStack;
        TableNo: Integer;
    begin
        TableNo := DATABASE::TempStack;
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyTempStack.FieldNo(Value));
    end;

    local procedure ClassifyStandardAddress()
    var
        DummyStandardAddress: Record "Standard Address";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Standard Address";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyStandardAddress.FieldNo("Related RecordID"));
    end;

    local procedure ClassifyServiceConnection()
    var
        DummyServiceConnection: Record "Service Connection";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Service Connection";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyServiceConnection.FieldNo("Record ID"));
    end;

    local procedure ClassifyRestrictedRecord()
    var
        DummyRestrictedRecord: Record "Restricted Record";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Restricted Record";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyRestrictedRecord.FieldNo("Record ID"));
    end;

    local procedure ClassifyRecordSetTree()
    var
        DummyRecordSetTree: Record "Record Set Tree";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Record Set Tree";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyRecordSetTree.FieldNo(Value));
    end;

    local procedure ClassifyPaymentServiceSetup()
    var
        DummyPaymentServiceSetup: Record "Payment Service Setup";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Payment Service Setup";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyPaymentServiceSetup.FieldNo("Setup Record ID"));
    end;

    local procedure ClassifyPaymentReportingArgument()
    var
        DummyPaymentReportingArgument: Record "Payment Reporting Argument";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Payment Reporting Argument";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyPaymentReportingArgument.FieldNo("Document Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPaymentReportingArgument.FieldNo("Setup Record ID"));
    end;

    local procedure ClassifyNotificationContext()
    var
        DummyClassifyNotificationContext: Record "Notification Context";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Notification Context";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyClassifyNotificationContext.FieldNo("Record ID"));
    end;

    local procedure ClassifyIntegrationSynchJobErrors()
    var
        DummyIntegrationSynchJobErrors: Record "Integration Synch. Job Errors";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Integration Synch. Job Errors";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyIntegrationSynchJobErrors.FieldNo("Source Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyIntegrationSynchJobErrors.FieldNo("Destination Record ID"));
    end;

    local procedure ClassifyErrorMessage()
    var
        DummyErrorMessage: Record "Error Message";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Error Message";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyErrorMessage.FieldNo("Record ID"));
        SetFieldToCompanyConfidential(TableNo, DummyErrorMessage.FieldNo("Context Record ID"));
    end;

    local procedure ClassifyDataMigrationParameters()
    var
        DummyDataMigrationParameters: Record "Data Migration Parameters";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Data Migration Parameters";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyDataMigrationParameters.FieldNo("Staging Table RecId To Process"));
    end;

    local procedure ClassifyDataMigrationError()
    var
        DummyDataMigrationError: Record "Data Migration Error";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Data Migration Error";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyDataMigrationError.FieldNo("Source Staging Table Record ID"));
    end;

    local procedure ClassifyDataExch()
    var
        DummyDataExch: Record "Data Exch.";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Data Exch.";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyDataExch.FieldNo("Related Record"));
    end;

    local procedure ClassifyCRMOptionMapping()
    var
        DummyCRMOptionMapping: Record "CRM Option Mapping";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"CRM Option Mapping";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCRMOptionMapping.FieldNo("Record ID"));
    end;

    local procedure ClassifyBatchProcessingSessionMap()
    var
        DummyBatchProcessingSessionMap: Record "Batch Processing Session Map";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Batch Processing Session Map";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyBatchProcessingSessionMap.FieldNo("Record ID"));
    end;

    local procedure ClassifyConfigPackageError()
    var
        DummyConfigPackageError: Record "Config. Package Error";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Config. Package Error";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyConfigPackageError.FieldNo("Record ID"));
    end;

    local procedure ClassifyBankAccount()
    var
        DummyBankAccount: Record "Bank Account";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Bank Account";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyBankAccount.FieldNo("Bank Stmt. Service Record ID"));
    end;

    local procedure ClassifyCreditTransferEntry()
    var
        DummyCreditTransferEntry: Record "Credit Transfer Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Credit Transfer Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Message to Recipient"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Recipient Bank Acc. No."));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Recipient Bank Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Recipient IBAN"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Recipient Name"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Transaction ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Transfer Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Transfer Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Applies-to Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCreditTransferEntry.FieldNo("Credit Transfer Register No."));
    end;

    local procedure ClassifyActiveSession()
    var
        DummyActiveSession: Record "Active Session";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Active Session";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyActiveSession.FieldNo("Session Unique ID"));
        SetFieldToPersonal(TableNo, DummyActiveSession.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyActiveSession.FieldNo("Session ID"));
        SetFieldToPersonal(TableNo, DummyActiveSession.FieldNo("User SID"));
    end;

    local procedure ClassifySEPADirectDebitMandate()
    var
        DummySEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"SEPA Direct Debit Mandate";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo(Closed));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Debit Counter"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Expected Number of Debits"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo(Blocked));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Type of Payment"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Date of Signature"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Valid To"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Valid From"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Customer Bank Account Code"));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo("Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummySEPADirectDebitMandate.FieldNo(ID));
    end;

    local procedure ClassifyPurchInvEntityAggregate()
    var
        DummyPurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purch. Inv. Entity Aggregate";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Document Type"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Your Reference"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Shipment Method Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Vendor Posting Group"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Purchaser Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Order No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Recalculate Invoice Disc."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo(Amount));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Vendor Invoice No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Vendor Ledger Entry No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Contact No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo(Posted));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Discount Applied Before Tax"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Buy-from Vendor No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Vendor No."));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to County"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Pay-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyPurchInvEntityAggregate.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifySalesInvoiceEntityAggregate()
    var
        DummySalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Invoice Entity Aggregate";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Document Type"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Your Reference"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Posting Date"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Shipment Method Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Customer Posting Group"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Salesperson Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Order No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Recalculate Invoice Disc."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo(Amount));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("External Document No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Tax Liable"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("VAT Bus. Posting Group"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Invoice Discount Calculation"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Invoice Discount Value"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo(IsTest));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Cust. Ledger Entry No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Contact No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo(Posted));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Subtotal Amount"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Discount Applied Before Tax"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Contact Graph Id"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Customer No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to Phone No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Sell-to E-Mail"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Customer No."));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Name"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Bill-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummySalesInvoiceEntityAggregate.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifyCashFlowForecastEntry()
    var
        DummyCashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cash Flow Forecast Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("G/L Budget Name"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo(Positive));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Recurring Method"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Associated Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Associated Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Payment Discount"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo(Overdue));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Cash Flow Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Cash Flow Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Cash Flow Forecast No."));
        SetFieldToPersonal(TableNo, DummyCashFlowForecastEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCashFlowForecastEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyDirectDebitCollection()
    var
        DummyDirectDebitCollection: Record "Direct Debit Collection";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Direct Debit Collection";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyDirectDebitCollection.FieldNo("Created by User"));
    end;

    local procedure ClassifyActivityLog()
    var
        DummyActivityLog: Record "Activity Log";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Activity Log";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyActivityLog.FieldNo("Record ID"));
        SetFieldToPersonal(TableNo, DummyActivityLog.FieldNo("User ID"));
    end;

    local procedure ClassifyUserSecurityStatus()
    var
        DummyUserSecurityStatus: Record "User Security Status";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Security Status";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserSecurityStatus.FieldNo("User Security ID"));
    end;

    local procedure ClassifyCueSetup()
    var
        TableNo: Integer;
    begin
        // Cannot reference Internal table through DATABASE::<Table name>
        TableNo := 9701; // Cue Setup
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, 1); // User Name
    end;

    local procedure ClassifyVATReportArchive()
    var
        DummyVATReportArchive: Record "VAT Report Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"VAT Report Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyVATReportArchive.FieldNo("Submitted By"));
    end;

    local procedure ClassifySessionEvent()
    var
        DummySessionEvent: Record "Session Event";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Session Event";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySessionEvent.FieldNo("Session Unique ID"));
        SetFieldToPersonal(TableNo, DummySessionEvent.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummySessionEvent.FieldNo("Session ID"));
        SetFieldToPersonal(TableNo, DummySessionEvent.FieldNo("User SID"));
    end;

    local procedure ClassifyUserDefaultStyleSheet()
    var
        DummyUserDefaultStyleSheet: Record "User Default Style Sheet";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Default Style Sheet";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserDefaultStyleSheet.FieldNo("User ID"));
    end;

    local procedure ClassifyUserPlan()
    var
        TableNo: Integer;
    begin
        TableNo := 9005; // UserPlan
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, 1); // "UserPlan"."User Security ID"
    end;

    local procedure ClassifyAADApplication()
    var
        DummyAADApplication: Record "AAD Application";
        TableNo: Integer;
    begin
        // Cannot reference Internal table through DATABASE::<Table name>
        TableNo := Database::"AAD Application"; // Persistent Blob
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAADApplication.FieldNo("User ID"));
    end;

    local procedure ClassifyApplicationUserSettings()
    var
        TableNo: Integer;
    begin
        // Cannot reference Internal table through DATABASE::<Table name>
        TableNo := 9222; // Application User Settings
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, 1); // User Security ID
    end;

    local procedure ClassifyTokenCache()
    var
        DummyTokenCache: Record "Token Cache";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Token Cache";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyTokenCache.FieldNo("Tenant ID"));
        SetFieldToPersonal(TableNo, DummyTokenCache.FieldNo("User Unique ID"));
        SetFieldToPersonal(TableNo, DummyTokenCache.FieldNo("User Security ID"));
    end;

    local procedure ClassifyTenantLicenseState()
    var
        DummyTenantLicenseState: Record "Tenant License State";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Tenant License State";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyTenantLicenseState.FieldNo("User Security ID"));
    end;

    local procedure ClassifyFAJournalSetup()
    var
        DummyFAJournalSetup: Record "FA Journal Setup";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"FA Journal Setup";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyFAJournalSetup.FieldNo("User ID"));
    end;

    local procedure ClassifyCustomizedCalendarEntry()
    var
        DummyCustomizedCalendarEntry: Record "Customized Calendar Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Customized Calendar Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo(Nonworking));
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo(Date));
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo("Base Calendar Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo("Additional Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCustomizedCalendarEntry.FieldNo("Source Type"));
    end;

    local procedure ClassifyAccessControl()
    var
        DummyAccessControl: Record "Access Control";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Access Control";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAccessControl.FieldNo("User Security ID"));
    end;

    local procedure ClassifyUserProperty()
    var
        DummyUserProperty: Record "User Property";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Property";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserProperty.FieldNo(Password));
        SetFieldToPersonal(TableNo, DummyUserProperty.FieldNo("User Security ID"));
    end;

    local procedure ClassifyUser()
    var
        DummyUser: Record User;
        TableNo: Integer;
    begin
        TableNo := DATABASE::User;
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("Exchange Identifier"));
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("Contact Email"));
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("Authentication Email"));
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("Windows Security ID"));
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("Full Name"));
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("User Name"));
        SetFieldToPersonal(TableNo, DummyUser.FieldNo("User Security ID"));
    end;

    local procedure ClassifyConfidentialInformation()
    var
        DummyConfidentialInformation: Record "Confidential Information";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Confidential Information";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyConfidentialInformation.FieldNo(Description));
    end;

    local procedure ClassifyOverdueApprovalEntry()
    var
        DummyOverdueApprovalEntry: Record "Overdue Approval Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Overdue Approval Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Limit Type"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Approval Type"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Approval Code"));
        SetFieldToPersonal(TableNo, DummyOverdueApprovalEntry.FieldNo("Approver ID"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Due Date"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Sequence No."));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Sent to Name"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("E-Mail"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Sent Date"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Sent Time"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Sent to ID"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Table ID"));
        SetFieldToCompanyConfidential(TableNo, DummyOverdueApprovalEntry.FieldNo("Record ID to Approve"));
    end;

    local procedure ClassifyApplicationAreaSetup()
    var
        DummyApplicationAreaSetup: Record "Application Area Setup";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Application Area Setup";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyApplicationAreaSetup.FieldNo("User ID"));
    end;

    local procedure ClassifyDateComprRegister()
    var
        DummyDateComprRegister: Record "Date Compr. Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Date Compr. Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyDateComprRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyEmployeeAbsence()
    var
        DummyEmployeeAbsence: Record "Employee Absence";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Employee Absence";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("Qty. per Unit of Measure"));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("Quantity (Base)"));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("Unit of Measure Code"));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("Cause of Absence Code"));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("To Date"));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("From Date"));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyEmployeeAbsence.FieldNo("Employee No."));
    end;

    local procedure ClassifyWorkflowStepInstanceArchive()
    var
        DummyWorkflowStepInstanceArchive: Record "Workflow Step Instance Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Step Instance Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWorkflowStepInstanceArchive.FieldNo("Last Modified By User ID"));
        SetFieldToPersonal(TableNo, DummyWorkflowStepInstanceArchive.FieldNo("Created By User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowStepInstanceArchive.FieldNo("Record ID"));
    end;

    local procedure ClassifyAlternativeAddress()
    var
        DummyAlternativeAddress: Record "Alternative Address";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Alternative Address";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo("Fax No."));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo("Phone No."));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo(County));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo("Post Code"));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo(City));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo("Address 2"));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo(Address));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo("Name 2"));
        SetFieldToPersonal(TableNo, DummyAlternativeAddress.FieldNo(Name));
    end;

    local procedure ClassifyWorkflowStepArgument()
    var
        DummyWorkflowStepArgument: Record "Workflow Step Argument";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Step Argument";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWorkflowStepArgument.FieldNo("Response User ID"));
        SetFieldToPersonal(TableNo, DummyWorkflowStepArgument.FieldNo("Approver User ID"));
        SetFieldToPersonal(TableNo, DummyWorkflowStepArgument.FieldNo("Notification User ID"));
    end;

    local procedure ClassifyPageDataPersonalization()
    var
        DummyPageDataPersonalization: Record "Page Data Personalization";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Page Data Personalization";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPageDataPersonalization.FieldNo("User SID"));
    end;

    local procedure ClassifySentNotificationEntry()
    var
        DummySentNotificationEntry: Record "Sent Notification Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sent Notification Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Aggregated with Entry"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Notification Method"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Notification Content"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Sent Date-Time"));
        SetFieldToPersonal(TableNo, DummySentNotificationEntry.FieldNo("Created By"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Created Date-Time"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Custom Link"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Link Target Page"));
        SetFieldToPersonal(TableNo, DummySentNotificationEntry.FieldNo("Recipient User ID"));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo(Type));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo(ID));
        SetFieldToCompanyConfidential(TableNo, DummySentNotificationEntry.FieldNo("Triggered By Record"));
    end;

    local procedure ClassifyICOutboxPurchaseHeader()
    var
        DummyICOutboxPurchaseHeader: Record "IC Outbox Purchase Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Outbox Purchase Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyICOutboxPurchaseHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyNotificationEntry()
    var
        DummyNotificationEntry: Record "Notification Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Notification Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyNotificationEntry.FieldNo("Created By"));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo("Created Date-Time"));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo("Error Message"));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo("Custom Link"));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo("Link Target Page"));
        SetFieldToPersonal(TableNo, DummyNotificationEntry.FieldNo("Recipient User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo(Type));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo(ID));
        SetFieldToCompanyConfidential(TableNo, DummyNotificationEntry.FieldNo("Triggered By Record"));
    end;

    local procedure ClassifyUserPersonalization()
    var
        DummyUserPersonalization: Record "User Personalization";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Personalization";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserPersonalization.FieldNo("User SID"));
    end;

    local procedure ClassifyWorkflowStepInstance()
    var
        DummyWorkflowStepInstance: Record "Workflow Step Instance";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Step Instance";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWorkflowStepInstance.FieldNo("Last Modified By User ID"));
        SetFieldToPersonal(TableNo, DummyWorkflowStepInstance.FieldNo("Created By User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowStepInstance.FieldNo("Record ID"));
    end;

    local procedure ClassifySession()
    var
        DummySession: Record Session;
        TableNo: Integer;
    begin
        TableNo := DATABASE::Session;
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySession.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummySession.FieldNo("Connection ID"));
    end;

    local procedure ClassifyIsolatedStorage()
    var
        DummyIsolatedStorage: Record "Isolated Storage";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Isolated Storage";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyIsolatedStorage.FieldNo("User Id"));
        SetFieldToPersonal(TableNo, DummyIsolatedStorage.FieldNo(Key));
        SetFieldToPersonal(TableNo, DummyIsolatedStorage.FieldNo(Value));
    end;

    local procedure ClassifyNavAppSetting()
    var
        DummyNavAppSetting: Record "NAV App Setting";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"NAV App Setting";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyNavAppSetting.FieldNo("Allow HttpClient Requests"));
    end;

    local procedure ClassifyPublishedApplication()
    var
        DummyPublishedApplication: Record "Published Application";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Published Application";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPublishedApplication.FieldNo(Description));
        SetFieldToPersonal(TableNo, DummyPublishedApplication.FieldNo(Blob));
        SetFieldToPersonal(TableNo, DummyPublishedApplication.FieldNo(Brief));
        SetFieldToPersonal(TableNo, DummyPublishedApplication.FieldNo(Logo));
        SetFieldToPersonal(TableNo, DummyPublishedApplication.FieldNo(Documentation));
        SetFieldToPersonal(TableNo, DummyPublishedApplication.FieldNo(Screenshots));
    end;

    local procedure ClassifyApprovalCommentLine()
    var
        DummyApprovalCommentLine: Record "Approval Comment Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Approval Comment Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyApprovalCommentLine.FieldNo("Record ID to Approve"));
        SetFieldToPersonal(TableNo, DummyApprovalCommentLine.FieldNo("User ID"));
    end;

    local procedure ClassifyJobQueueLogEntry()
    var
        DummyJobQueueLogEntry: Record "Job Queue Log Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Queue Log Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("Job Queue Category Code"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("Error Message"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo(Status));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("Object ID to Run"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("Object Type to Run"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("End Date/Time"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("Start Date/Time"));
        SetFieldToPersonal(TableNo, DummyJobQueueLogEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo(ID));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueLogEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyJobQueueEntry()
    var
        DummyJobQueueEntry: Record "Job Queue Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Job Queue Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Manual Recurrence"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("System Task ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Rerun Delay (sec.)"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Report Request Page Options"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Printer Name"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("User Language ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Notify On Success"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("User Session Started"));
        SetFieldToPersonal(TableNo, DummyJobQueueEntry.FieldNo("User Service Instance ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Error Message"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Job Queue Category Code"));
        SetFieldToPersonal(TableNo, DummyJobQueueEntry.FieldNo("User Session ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run in User Session"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Reference Starting Time"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Ending Time"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Starting Time"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Sundays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Saturdays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Fridays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Thursdays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Wednesdays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Tuesdays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Run on Mondays"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("No. of Minutes between Runs"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Recurring Job"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Parameter String"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo(Status));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("No. of Attempts to Run"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Maximum No. of Attempts to Run"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Report Output Type"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Object ID to Run"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Object Type to Run"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Earliest Start Date/Time"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Expiration Date/Time"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Last Ready State"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo(XML));
        SetFieldToPersonal(TableNo, DummyJobQueueEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo(ID));
        SetFieldToCompanyConfidential(TableNo, DummyJobQueueEntry.FieldNo("Record ID to Process"));
    end;

    local procedure ClassifyPostedApprovalCommentLine()
    var
        DummyPostedApprovalCommentLine: Record "Posted Approval Comment Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Approval Comment Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPostedApprovalCommentLine.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalCommentLine.FieldNo("Posted Record ID"));
    end;

    local procedure ClassifyPostedApprovalEntry()
    var
        DummyPostedApprovalEntry: Record "Posted Approval Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Approval Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Iteration No."));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Number of Rejected Requests"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Number of Approved Requests"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Delegation Date Formula"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Available Credit Limit (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Limit Type"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Approval Type"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Due Date"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Last Modified By ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Last Date-Time Modified"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Date-Time Sent for Approval"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummyPostedApprovalEntry.FieldNo("Approver ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Salespers./Purch. Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Sender ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Approval Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Sequence No."));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Table ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPostedApprovalEntry.FieldNo("Posted Record ID"));
    end;

    local procedure ClassifyApprovalEntry()
    var
        DummyApprovalEntry: Record "Approval Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Approval Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Workflow Step Instance ID"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Delegation Date Formula"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Available Credit Limit (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Limit Type"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Approval Type"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummyApprovalEntry.FieldNo("Last Modified By User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Last Date-Time Modified"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Date-Time Sent for Approval"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummyApprovalEntry.FieldNo("Approver ID"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Salespers./Purch. Code"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Sender ID"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Approval Code"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Sequence No."));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Table ID"));
        SetFieldToCompanyConfidential(TableNo, DummyApprovalEntry.FieldNo("Record ID to Approve"));
    end;

    local procedure ClassifyHandledICInboxPurchHeader()
    var
        DummyHandledICInboxPurchHeader: Record "Handled IC Inbox Purch. Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Handled IC Inbox Purch. Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxPurchHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyHandledICInboxSalesHeader()
    var
        DummyHandledICInboxSalesHeader: Record "Handled IC Inbox Sales Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Handled IC Inbox Sales Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyHandledICInboxSalesHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyICInboxPurchaseHeader()
    var
        DummyICInboxPurchaseHeader: Record "IC Inbox Purchase Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Inbox Purchase Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyICInboxPurchaseHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyICInboxSalesHeader()
    var
        DummyICInboxSalesHeader: Record "IC Inbox Sales Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Inbox Sales Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyICInboxSalesHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyHandledICOutboxPurchHdr()
    var
        DummyHandledICOutboxPurchHdr: Record "Handled IC Outbox Purch. Hdr";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Handled IC Outbox Purch. Hdr";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxPurchHdr.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyHandledICOutboxSalesHeader()
    var
        DummyHandledICOutboxSalesHeader: Record "Handled IC Outbox Sales Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Handled IC Outbox Sales Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyHandledICOutboxSalesHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyUserPageMetadata()
    var
        DummyUserPageMetadata: Record "User Page Metadata";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Page Metadata";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserPageMetadata.FieldNo("User SID"));
    end;

    local procedure ClassifyICPartner()
    var
        DummyICPartner: Record "IC Partner";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Partner";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyICPartner.FieldNo(Name));
    end;

    local procedure ClassifyChangeLogEntry()
    var
        DummyChangeLogEntry: Record "Change Log Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Change Log Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key Field 3 Value"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key Field 3 No."));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key Field 2 Value"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key Field 2 No."));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key Field 1 Value"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key Field 1 No."));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Primary Key"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("New Value"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Old Value"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Type of Change"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Field No."));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Table No."));
        SetFieldToPersonal(TableNo, DummyChangeLogEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo(Time));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Date and Time"));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyChangeLogEntry.FieldNo("Record ID"));
    end;

    local procedure ClassifyInsCoverageLedgerEntry()
    var
        DummyInsCoverageLedgerEntry: Record "Ins. Coverage Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Ins. Coverage Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Index Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyInsCoverageLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("FA Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("FA Subclass Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("FA Class Code"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("FA Description"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("FA No."));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Disposed FA"));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Insurance No."));
        SetFieldToCompanyConfidential(TableNo, DummyInsCoverageLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyEmailConnectorLogo()
    begin
        SetTableFieldsToNormal(8887);
    end;

    local procedure ClassifyEmailError()
    begin
        SetFieldToPersonal(8901, 3); // Error Message
    end;

    local procedure ClassifyEmailOutbox()
    begin
        SetFieldToPersonal(8888, 6); // Description / Email subject
        SetFieldToPersonal(8888, 13); // Send from
        SetFieldToPersonal(8888, 14); // Error Message
        SetFieldToPersonal(8888, 16); // External Message Id
    end;

    local procedure ClassifyEmailInbox()
    begin
        SetFieldToPersonal(8886, 6); // Description / Email subject
        SetFieldToPersonal(8886, 7); // Conversation Id
        SetFieldToPersonal(8886, 8); // External Message Id
        SetFieldToPersonal(8886, 11); // Received DateTime
        SetFieldToPersonal(8886, 12); // Sent DateTime
        SetFieldToPersonal(8886, 13); // Is Read
        SetFieldToPersonal(8886, 14); // Is Draft
    end;

    local procedure ClassifySentEmail()
    begin
        SetFieldToPersonal(8889, 6); // Description / Email subject
        SetFieldToPersonal(8889, 13); // Send from
    end;

    local procedure ClassifyEmailScenarioAttachments()
    begin
        SetFieldToPersonal(8911, 3); // Attachment Name
        SetFieldToPersonal(8911, 4); // Email Attachment
    end;

    local procedure ClassifyRateLimit()
    begin
        SetFieldToPersonal(8912, 2); // Email Address
    end;

    local procedure ClassifyEmailLookup()
    begin
        SetFieldToPersonal(8944, 1); // Name;
        SetFieldToPersonal(8944, 2); // Email;
        SetFieldToPersonal(8944, 3); // Company;
    end;

    local procedure ClassifyEmailMessage()
    begin
        SetFieldToPersonal(8900, 2); // Subject
        SetFieldToPersonal(8900, 3); // Body
        SetFieldToPersonal(8900, 7); // External message id
    end;

    local procedure ClassifyEmailRetry()
    begin
        SetFieldToCompanyConfidential(8890, 3); // "Account Id"
        SetFieldToPersonal(8890, 5); // "User Security ID"
        SetFieldToPersonal(8890, 6); // Description
        SetFieldToPersonal(8890, 12); // Send From
        SetFieldToPersonal(8890, 13); // "Error Message
    end;

    local procedure ClassifyEmailRecipient()
    begin
        SetFieldToPersonal(8903, 2); // Email Address
    end;

    local procedure ClassifyEmailMessageAttachment()
    begin
        SetFieldToPersonal(8904, 3); // Attachment
        SetFieldToPersonal(8904, 4); // Attachment Name
        SetFieldToPersonal(8904, 9); // Media Attachment
    end;

    local procedure ClassifyWordTemplate()
    begin
        SetFieldToPersonal(9988, 1); // Code
        SetFieldToPersonal(9988, 2); // Name
        SetFieldToPersonal(9988, 4); // Template
        SetFieldToPersonal(9990, 1); // Code
        SetFieldToPersonal(9990, 7); // Related Table Code
        SetFieldToPersonal(9989, 1); // Word Template Code
        SetFieldToPersonal(9989, 5); // Exclude
    end;

    local procedure ClassifyDocumentSharing()
    begin
        SetFieldToPersonal(9560, 2); // Data
        SetFieldToPersonal(9560, 3); // Name
        SetFieldToPersonal(9560, 6); // Token
        SetFieldToPersonal(9560, 7); // Document Root Uri
        SetFieldToPersonal(9560, 8); // Document Uri
        SetFieldToPersonal(9560, 9); // Document Preview Uri
    end;

    local procedure ClassifyEmailRelatedAttachments()
    begin
        SetFieldToPersonal(8910, 2); // Attachment Name
    end;

    local procedure ClassifyTermsAndConditionsState()
    var
        DummyTermsAndConditionsState: Record "Terms And Conditions State";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Terms And Conditions State";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyTermsAndConditionsState.FieldNo("User ID"));
    end;

    local procedure ClassifyDetailedCVLedgEntryBuffer()
    var
        DummyDetailedCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Detailed CV Ledg. Entry Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCVLedgEntryBuffer.FieldNo("Non-Deductible VAT Amount LCY"));
        SetFieldToCompanyConfidential(TableNo, DummyDetailedCVLedgEntryBuffer.FieldNo("Non-Deductible VAT Amount ACY"));
    end;

    local procedure ClassifyAccPayablesRoleCenter()
    var
        PurchByVendGrpChartSetup: Record "Purch. by Vend.Grp.Chart Setup";
        TopVendorsByPurch: Record "Top Vendors By Purchase";
    begin
        SetTableFieldsToNormal(Database::"Acc. Payable Performance Chart");
        SetTableFieldsToNormal(Database::"Account Payable Cue");
        SetTableFieldsToNormal(Database::"Purch. by Vend.Grp.Chart Setup");
        SetFieldToPersonal(Database::"Acc. Payable Performance Chart", PurchByVendGrpChartSetup.FieldNo("User ID"));
        SetTableFieldsToNormal(Database::"Top Vendors By Purchase");
        SetFieldToPersonal(Database::"Top Vendors By Purchase", TopVendorsByPurch.FieldNo(VendorNo));
        SetFieldToPersonal(Database::"Top Vendors By Purchase", TopVendorsByPurch.FieldNo(VendorName));
    end;

    local procedure ClassifyPostedPaymentReconLine()
    var
        DummyPostedPaymentReconLine: Record "Posted Payment Recon. Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Payment Recon. Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPostedPaymentReconLine.FieldNo("Related-Party Name"));
    end;

    local procedure ClassifyAppliedPaymentEntry()
    var
        DummyAppliedPaymentEntry: Record "Applied Payment Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Applied Payment Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Due Date"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo(Quality));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Applied Pmt. Discount"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Applied Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Applies-to Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Statement Type"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Match Confidence"));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Statement Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Statement No."));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("Bank Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyAppliedPaymentEntry.FieldNo("External Document No."));
    end;

    local procedure ClassifySelectedDimension()
    var
        DummySelectedDimension: Record "Selected Dimension";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Selected Dimension";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySelectedDimension.FieldNo("User ID"));
    end;

    local procedure ClassifyConfigLine()
    var
        DummyConfigLine: Record "Config. Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Config. Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyConfigLine.FieldNo("Responsible ID"));
    end;

    local procedure ClassifyConfigPackageTable()
    var
        DummyConfigPackageTable: Record "Config. Package Table";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Config. Package Table";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyConfigPackageTable.FieldNo("Created by User ID"));
        SetFieldToPersonal(TableNo, DummyConfigPackageTable.FieldNo("Imported by User ID"));
    end;


    local procedure ClassifyPositivePayEntryDetail()
    var
        DummyPositivePayEntryDetail: Record "Positive Pay Entry Detail";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Positive Pay Entry Detail";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Update Date"));
        SetFieldToPersonal(TableNo, DummyPositivePayEntryDetail.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo(Payee));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Check No."));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("No."));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Upload Date-Time"));
        SetFieldToCompanyConfidential(TableNo, DummyPositivePayEntryDetail.FieldNo("Bank Account No."));
    end;

    local procedure ClassifyICOutboxSalesHeader()
    var
        DummyICOutboxSalesHeader: Record "IC Outbox Sales Header";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Outbox Sales Header";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummyICOutboxSalesHeader.FieldNo("Ship-to Name"));
    end;

    local procedure ClassifyDirectDebitCollectionEntry()
    var
        DummyDirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Direct Debit Collection Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Mandate ID"));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo(Status));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Sequence Type"));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Transaction ID"));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Transfer Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Transfer Date"));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Applies-to Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Customer No."));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyDirectDebitCollectionEntry.FieldNo("Direct Debit Collection No."));
    end;

    local procedure ClassifyCreditTransferRegister()
    var
        DummyCreditTransferRegister: Record "Credit Transfer Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Credit Transfer Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCreditTransferRegister.FieldNo("Created by User"));
    end;

    local procedure ClassifyBankAccReconciliationLine()
    var
        DummyBankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Bank Acc. Reconciliation Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyBankAccReconciliationLine.FieldNo("Related-Party City"));
        SetFieldToPersonal(TableNo, DummyBankAccReconciliationLine.FieldNo("Related-Party Address"));
        SetFieldToPersonal(TableNo, DummyBankAccReconciliationLine.FieldNo("Related-Party Bank Acc. No."));
        SetFieldToPersonal(TableNo, DummyBankAccReconciliationLine.FieldNo("Related-Party Name"));
    end;

    local procedure ClassifyCheckLedgerEntry()
    var
        DummyCheckLedgerEntry: Record "Check Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Check Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Positive Pay Exported"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Data Exch. Voided Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Data Exch. Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("External Document No."));
        SetFieldToPersonal(TableNo, DummyCheckLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Statement Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Statement No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Statement Status"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo(Open));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Original Entry Status"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Entry Status"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Bank Payment Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Check Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Check No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Check Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Bank Account Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Bank Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyCheckLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyBankAccountLedgerEntry()
    var
        DummyBankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Bank Account Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Reversed Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Reversed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo(Reversed));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Credit Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Debit Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Statement Line No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Statement No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Statement Status"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Closed at Date"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Closed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo(Positive));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo(Open));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyBankAccountLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Our Contact Code"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Bank Acc. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Remaining Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Bank Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyBankAccountLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyBookingSync()
    var
        DummyBookingSync: Record "Booking Sync";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Booking Sync";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyBookingSync.FieldNo("User ID"));
    end;

    local procedure ClassifyVATEntry()
    var
        DummyVATEntry: Record "VAT Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"VAT Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("EU Service"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Reversed Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Reversed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo(Reversed));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("VAT Registration No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Ship-to/Order Address Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Add.-Curr. VAT Difference"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("VAT Difference"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Add.-Curr. Rem. Unreal. Base"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Add.-Curr. Rem. Unreal. Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("VAT Base Discount %"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Add.-Currency Unrealized Base"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Add.-Currency Unrealized Amt."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Additional-Currency Base"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Additional-Currency Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("VAT Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("VAT Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Unrealized VAT Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Sales Tax Connection No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax on Tax"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax Type"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax Group Used"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax Jurisdiction Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Use Tax"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax Liable"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Tax Area Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Remaining Unrealized Base"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Remaining Unrealized Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Unrealized Base"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Unrealized Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Internal Ref. No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Country/Region Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo(Closed));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Closed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyVATEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("EU 3-Party Trade"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Bill-to/Pay-to No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("VAT Calculation Type"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo(Base));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo(Type));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyVATEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyVATRegistrationLog()
    var
        DummyVATRegistrationLog: Record "VAT Registration Log";
        DummyVATRegistrationLogDetails: Record "VAT Registration Log Details";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"VAT Registration Log";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("Verified City"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("Verified Postcode"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("Verified Street"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("Verified Address"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("Verified Name"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLog.FieldNo("VAT Registration No."));

        TableNo := Database::"VAT Registration Log Details";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyVATRegistrationLogDetails.FieldNo(Requested));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLogDetails.FieldNo(Response));
        SetFieldToPersonal(TableNo, DummyVATRegistrationLogDetails.FieldNo("Current Value"));
    end;

    local procedure ClassifyInsuranceRegister()
    var
        DummyInsuranceRegister: Record "Insurance Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Insurance Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyInsuranceRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyCustomReportLayout()
    var
        DummyCustomReportLayout: Record "Custom Report Layout";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Custom Report Layout";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCustomReportLayout.FieldNo("Last Modified by User"));
    end;

    local procedure ClassifyCostBudgetRegister()
    var
        DummyCostBudgetRegister: Record "Cost Budget Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Budget Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCostBudgetRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyCostBudgetEntry()
    var
        DummyCostBudgetEntry: Record "Cost Budget Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Budget Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Last Date Modified"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Allocated with Journal No."));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo(Allocated));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("System-Created Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Allocation ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Allocation Description"));
        SetFieldToPersonal(TableNo, DummyCostBudgetEntry.FieldNo("Last Modified By User"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Cost Object Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Cost Center Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo(Date));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Cost Type No."));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Budget Name"));
        SetFieldToCompanyConfidential(TableNo, DummyCostBudgetEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyCostAllocationTarget()
    var
        DummyCostAllocationTarget: Record "Cost Allocation Target";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Allocation Target";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCostAllocationTarget.FieldNo("User ID"));
    end;

    local procedure ClassifyCostAllocationSource()
    var
        DummyCostAllocationSource: Record "Cost Allocation Source";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Allocation Source";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCostAllocationSource.FieldNo("User ID"));
    end;

    local procedure ClassifyCostRegister()
    var
        DummyCostRegister: Record "Cost Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCostRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyCostEntry()
    var
        DummyCostEntry: Record "Cost Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Allocated with Journal No."));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo(Allocated));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("System-Created Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("G/L Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("G/L Account"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Additional-Currency Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Cost Object Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Cost Center Code"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Allocation ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Allocation Description"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Add.-Currency Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Cost Type No."));
        SetFieldToPersonal(TableNo, DummyCostEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Add.-Currency Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyCostEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyCostType()
    var
        DummyCostType: Record "Cost Type";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Cost Type";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyCostType.FieldNo("Modified By"));
    end;

    local procedure ClassifyReversalEntry()
    var
        DummyReversalEntry: Record "Reversal Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Reversal Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Reversal Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("FA Posting Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("FA Posting Category"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Account Name"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("VAT Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Credit Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Debit Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Currency Code"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("G/L Register No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyReversalEntry.FieldNo("Line No."));
    end;

    local procedure ClassifyIncomingDocument()
    var
        DummyIncomingDocument: Record "Incoming Document";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Incoming Document";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Vendor Phone No."));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Vendor Bank Account No."));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Vendor Bank Branch No."));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Vendor IBAN"));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Vendor VAT Registration No."));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Vendor Name"));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Last Modified By User ID"));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Released By User ID"));
        SetFieldToPersonal(TableNo, DummyIncomingDocument.FieldNo("Created By User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyIncomingDocument.FieldNo("Related Record ID"));
    end;

    local procedure ClassifyMaintenanceLedgerEntry()
    var
        DummyMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Maintenance Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Reversed Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Reversed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo(Reversed));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("VAT Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("VAT Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Use Tax"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Tax Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Tax Liable"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Tax Area Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Automatic Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Index Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo(Correction));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Maintenance Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA Exchange Rate"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Depreciation Book Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA Class Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Gen. Posting Type"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("VAT Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToPersonal(TableNo, DummyMaintenanceLedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA Subclass Code"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA No./Budgeted FA No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("FA No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("G/L Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyMaintenanceLedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyFARegister()
    var
        DummyFARegister: Record "FA Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"FA Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyFARegister.FieldNo("User ID"));
    end;

    local procedure ClassifyMaintenanceRegistration()
    var
        DummyMaintenanceRegistration: Record "Maintenance Registration";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Maintenance Registration";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyMaintenanceRegistration.FieldNo("Service Agent Mobile Phone"));
        SetFieldToPersonal(TableNo, DummyMaintenanceRegistration.FieldNo("Service Agent Phone No."));
        SetFieldToPersonal(TableNo, DummyMaintenanceRegistration.FieldNo("Service Agent Name"));
    end;

    local procedure ClassifyWorkflowStepArgumentArchive()
    var
        DummyWorkflowStepArgumentArchive: Record "Workflow Step Argument Archive";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Workflow Step Argument Archive";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyWorkflowStepArgumentArchive.FieldNo("Response User ID"));
        SetFieldToPersonal(TableNo, DummyWorkflowStepArgumentArchive.FieldNo("Approver User ID"));
        SetFieldToPersonal(TableNo, DummyWorkflowStepArgumentArchive.FieldNo("Notification User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyWorkflowStepArgumentArchive.FieldNo("Original Record ID"));
    end;

    local procedure ClassifyGLBudgetEntry()
    var
        DummyGLBudgetEntry: Record "G/L Budget Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"G/L Budget Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Last Date Modified"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Budget Dimension 4 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Budget Dimension 3 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Budget Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Budget Dimension 1 Code"));
        SetFieldToPersonal(TableNo, DummyGLBudgetEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Business Unit Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo(Date));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("G/L Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Budget Name"));
        SetFieldToCompanyConfidential(TableNo, DummyGLBudgetEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyApiWebhookSubscripitonFields()
    var
        DummyAPIWebhookSubscription: Record "API Webhook Subscription";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"API Webhook Subscription";
        SetTableFieldsToNormal(TableNo);
        SetFieldToSensitive(TableNo, DummyAPIWebhookSubscription.FieldNo("Client State"));
    end;

    local procedure ClassifyExternalEventSubscriptionFields()
    var
        DummyExternalEventSubscription: Record "External Event Subscription";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"External Event Subscription";
        SetTableFieldsToNormal(TableNo);
        SetFieldToSensitive(TableNo, DummyExternalEventSubscription.FieldNo("Client State"));
    end;

    local procedure ClassifyUserSetup()
    var
        DummyUserSetup: Record "User Setup";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"User Setup";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyUserSetup.FieldNo("E-Mail"));
        SetFieldToPersonal(TableNo, DummyUserSetup.FieldNo(Substitute));
        SetFieldToPersonal(TableNo, DummyUserSetup.FieldNo("Approver ID"));
        SetFieldToPersonal(TableNo, DummyUserSetup.FieldNo("User ID"));
    end;

    local procedure ClassifySupportInformation()
    var
        DummySupportContactInformation: Record "Support Contact Information";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Support Contact Information";
        SetTableFieldsToNormal(TableNo);

        SetFieldToPersonal(TableNo, DummySupportContactInformation.FieldNo(Name));
        SetFieldToPersonal(TableNo, DummySupportContactInformation.FieldNo(Email));
        SetFieldToPersonal(TableNo, DummySupportContactInformation.FieldNo(URL));
    end;

    local procedure ClassifyCRMSynchStatus()
    var
        DummyCRMSynchStatus: Record "CRM Synch Status";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"CRM Synch Status";
        SetTableFieldsToNormal(TableNo);

        SetFieldToPersonal(TableNo, DummyCRMSynchStatus.FieldNo("Primary Key"));
        SetFieldToPersonal(TableNo, DummyCRMSynchStatus.FieldNo("Last Update Invoice Entry No."));
    end;

    local procedure ClassifyRetentionPolicyLogEntry()
    var
        TableNo: Integer;
    begin
        TableNo := 3905; // Database::"Retention Policy Log Entry"
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, 4); // FieldNo("User Id")
    end;

    local procedure ClassifyFALedgerEntry()
    var
        DummyFALedgerEntry: Record "FA Ledger Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"FA Ledger Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Reversed Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Reversed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo(Reversed));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("VAT Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("VAT Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Use Tax"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Tax Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Tax Liable"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Tax Area Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Property Class (Custom 1)"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depr. % this year (Custom 1)"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Accum. Depr. % (Custom 1)"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depr. Ending Date (Custom 1)"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depr. Starting Date (Custom 1)"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Automatic Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Use FA Ledger Check"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depreciation Ending Date"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Canceled from FA No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Index Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo(Correction));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Result on Disposal"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Amount (LCY)"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Exchange Rate"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Class Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Gen. Posting Type"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("VAT Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Source Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depreciation Table Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Declining-Balance %"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Fixed Depr. Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("No. of Depreciation Years"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Straight-Line %"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depreciation Starting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depreciation Method"));
        SetFieldToPersonal(TableNo, DummyFALedgerEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Location Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Subclass Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA No./Budgeted FA No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("No. of Depreciation Days"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Disposal Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Disposal Calculation Method"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Part of Depreciable Basis"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Part of Book Value"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Reclassification Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Posting Type"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Posting Category"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Depreciation Book Code"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("FA No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("G/L Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyFALedgerEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifyGenJournalLine()
    var
        DummyGenJournalLine: Record "Gen. Journal Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Gen. Journal Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyGenJournalLine.FieldNo("VAT Registration No."));
    end;

    local procedure ClassifyPrinterSelection()
    var
        DummyPrinterSelection: Record "Printer Selection";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Printer Selection";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPrinterSelection.FieldNo("User ID"));
    end;

    local procedure ClassifyGLRegister()
    var
        DummyGLRegister: Record "G/L Register";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"G/L Register";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyGLRegister.FieldNo("User ID"));
    end;

    local procedure ClassifyEntityText()
    begin
        SetTableFieldsToNormal(Database::"Entity Text");
        SetTableFieldsToNormal(2010); // Azure OpenAi Settings
        SetFieldToCompanyConfidential(2010, 4); // Secret
    end;

    local procedure ClassifyMyAccount()
    var
        DummyMyAccount: Record "My Account";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"My Account";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyMyAccount.FieldNo("User ID"));
    end;

    local procedure ClassifyGLEntry()
    var
        DummyGLEntry: Record "G/L Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"G/L Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Last Modified DateTime"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("FA Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("FA Entry Type"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Account Id"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Reversed Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Reversed by Entry No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo(Reversed));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("IC Partner Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Close Income Statement Dim. ID"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Add.-Currency Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Add.-Currency Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Additional-Currency Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("VAT Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("VAT Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Use Tax"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Tax Group Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Tax Liable"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Tax Area Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("No. Series"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Source No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Source Type"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("External Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Document Date"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Credit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Debit Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Transaction No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Bal. Account Type"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Gen. Prod. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Gen. Bus. Posting Group"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Gen. Posting Type"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Reason Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Journal Batch Name"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Business Unit Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("VAT Amount"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo(Quantity));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Job No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Prod. Order No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Dimension Set ID"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Prior-Year Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("System-Created Entry"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Source Code"));
        SetFieldToPersonal(TableNo, DummyGLEntry.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Global Dimension 2 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Global Dimension 1 Code"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo(Amount));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Bal. Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo(Description));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Document No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Document Type"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Posting Date"));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("G/L Account No."));
        SetFieldToCompanyConfidential(TableNo, DummyGLEntry.FieldNo("Entry No."));
    end;

    local procedure ClassifySalesOrderEntityBuffer()
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Order Entity Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Customer No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Customer Posting Group"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Salesperson Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Recalculate Invoice Disc."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo(Amount));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Country/Region Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("External Document No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Cust. Ledger Entry No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-To Contact No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Shipping Advice"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Completely Shipped"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Requested Delivery Date"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo(Status));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Discount Applied Before Tax"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to Phone No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Sell-to E-Mail"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Customer No."));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Name"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Bill-to Country/Region Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Country/Region Code"));
        SetFieldToPersonal(TableNo, SalesOrderEntityBuffer.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifySalesQuoteEntityBuffer()
    var
        DummySalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Quote Entity Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Document Type"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Customer No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Your Reference"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Posting Date"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Shipment Method Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Customer Posting Group"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Salesperson Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo(Amount));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("VAT Registration No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("External Document No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Tax Area Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Tax Liable"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("VAT Bus. Posting Group"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Invoice Discount Calculation"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Invoice Discount Value"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Quote Valid Until Date"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Quote Sent to Customer"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Quote Accepted"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Quote Accepted Date"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Cust. Ledger Entry No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Contact No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo(Posted));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Subtotal Amount"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Discount Applied Before Tax"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to Phone No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Sell-to E-Mail"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Customer No."));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Name"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Bill-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummySalesQuoteEntityBuffer.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifySalesCrMemoEntityBuffer()
    var
        DummySalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Sales Cr. Memo Entity Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Customer No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Customer Posting Group"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Salesperson Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Applies-to Doc. Type"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Applies-to Doc. No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Recalculate Invoice Disc."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo(Amount));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Customer Name"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Address"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to City"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to County"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("External Document No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Cust. Ledger Entry No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Contact No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Shipping Advice"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Completely Shipped"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Requested Delivery Date"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo(Posted));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Discount Applied Before Tax"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to Phone No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Sell-to E-Mail"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Customer No."));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Name"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Address"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Address 2"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to City"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Contact"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Post Code"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to County"));
        SetFieldToPersonal(TableNo, DummySalesCrMemoEntityBuffer.FieldNo("Bill-to Country/Region Code"));
    end;

    local procedure ClassifyPurchCrMemoEntityBuffer()
    var
        DummyPurchCrMemoEntityBuffer: Record "Purch. Cr. Memo Entity Buffer";
        TableNo: Integer;
    begin
        TableNo := Database::"Purch. Cr. Memo Entity Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Vendor No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Vendor No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Posting Date"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Due Date"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Shipment Method Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Vendor Posting Group"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Purchaser Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Applies-to Doc. Type"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Applies-to Doc. No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo(Amount));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Reason Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Contact No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Buy-from Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Name"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Post Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to County"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Pay-to Country/Region Code"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Vendor Ledger Entry No."));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo(Status));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo(Posted));
        SetFieldToPersonal(TableNo, DummyPurchCrMemoEntityBuffer.FieldNo("Discount Applied Before Tax"));
    end;

    local procedure ClassifyPersistentBlob()
    var
        TableNo: Integer;
    begin
        // Cannot reference Internal table through DATABASE::<Table name>
        TableNo := 4151; // Persistent Blob
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, 2); // Blob
    end;

    local procedure ClassifyPostedGenJournalLine()
    var
        DummyPostedGenJournalLine: Record "Posted Gen. Journal Line";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Posted Gen. Journal Line";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyPostedGenJournalLine.FieldNo("VAT Registration No."));
    end;

    local procedure ClassifyPurchaseOrderEntityBuffer()
    var
        PurchOrderEntityBufer: Record "Purchase Order Entity Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Purchase Order Entity Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Vendor No."));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("No."));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Payment Terms Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Vendor Posting Group"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Currency Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Prices Including VAT"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Purchaser Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Recalculate Invoice Disc."));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo(Amount));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Amount Including VAT"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Vendor Name"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Address"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Address 2"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from City"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Contact"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Post Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from County"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Country/Region Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Document Date"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Vendor Ledger Entry No."));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Invoice Discount Amount"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Buy-from Contact No."));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Completely Received"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Requested Receipt Date"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Total Tax Amount"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo(Status));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Discount Applied Before Tax"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Vendor No."));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Name"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Address"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Address 2"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to City"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Contact"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Post Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to County"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Pay-to Country/Region Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Name"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Address"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Address 2"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to City"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Contact"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Post Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to County"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Country/Region Code"));
        SetFieldToPersonal(TableNo, PurchOrderEntityBufer.FieldNo("Ship-to Phone No."));
    end;

    local procedure ClassifyBankAccRecMatchBuffer()
    var
        BankAccRecMatchBuffer: Record "Bank Acc. Rec. Match Buffer";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Bank Acc. Rec. Match Buffer";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, BankAccRecMatchBuffer.FieldNo("Statement Line No."));
        SetFieldToCompanyConfidential(TableNo, BankAccRecMatchBuffer.FieldNo("Statement No."));
        SetFieldToCompanyConfidential(TableNo, BankAccRecMatchBuffer.FieldNo("Ledger Entry No."));
        SetFieldToCompanyConfidential(TableNo, BankAccRecMatchBuffer.FieldNo("Bank Account No."));
    end;

    local procedure ClassifyPermissionSetInPlan()
    var
        TableNo: Integer;
    begin
        TableNo := 9018; // Database::"Custom Permission Set In Plan"
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, 3); // FieldNo("Role ID")
        SetFieldToCompanyConfidential(TableNo, 8); // FieldNo("Company Name")

        TableNo := 9019; // Database::"Default Permission Set In Plan"
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, 3); // FieldNo("Role ID")
    end;

    local procedure ClassifyICBankAccount()
    var
        RemitAddress: Record "IC Bank Account";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"IC Bank Account";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo(Name));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo("Bank Account No."));
        SetFieldToPersonal(TableNo, RemitAddress.FieldNo(IBAN));
    end;

    local procedure ClassifyOrderTakerAgent()
    begin
        SetTableFieldsToNormal(4305); // "SOA Instruction Template"
        SetTableFieldsToNormal(4306); // "SOA Instruction Phase"
        SetTableFieldsToNormal(4307); // "SOA Instruction Phase Step"
        SetTableFieldsToNormal(4308); // "SOA Instruction Task/Policy"
        SetTableFieldsToNormal(4309); // "SOA Instruction Prompt"
        SetFieldToCompanyConfidential(4309, 2); // Prompt
        SetTableFieldsToNormal(4592); // SOA KPI Entry
        SetFieldToPersonal(4592, 5); // Created by User ID
        SetTableFieldsToNormal(4593); // SOA KPI
        SetTableFieldsToNormal(4585); // SOA Email
        SetTableFieldsToNormal(4586); // SOA Billing Log
        SetTableFieldsToNormal(4587); // SOA Billing Task Setup
        SetFieldToPersonal(4592, 9); // Sender Email
        SetFieldToPersonal(4592, 10); // Sender Name
    end;

    local procedure ClassifyExpenseAgent()
    begin
        SetTableFieldsToNormal(6900); // Expense
        SetTableFieldsToNormal(6901); // ExpenseCommentLine
        SetTableFieldsToNormal(6902); // ExpenseItemization
        SetTableFieldsToNormal(6903); // ExpenseItemizationLine
        SetTableFieldsToNormal(6904); // ExpenseParticipant
        SetTableFieldsToNormal(6905); // ExpensePerDiem
        SetTableFieldsToNormal(6906); // ExpenseReportHeader
        SetTableFieldsToNormal(6907); // ExpenseReportLine
        SetTableFieldsToNormal(6908); // ExpenseReportLineParticip
        SetTableFieldsToNormal(6909); // ExpenseReportLinePerDiem
        SetTableFieldsToNormal(6910); // ExpReportItemizationLine
        SetTableFieldsToNormal(6911); // ExpReportLineItemization
        SetTableFieldsToNormal(6912); // ExpenseLedgerEntry
        SetTableFieldsToNormal(6915); // PostedExpenseReportHeader
        SetTableFieldsToNormal(6916); // PostedExpenseReportLine
        SetTableFieldsToNormal(6917); // PostedExpReportLinePcpt
        SetTableFieldsToNormal(6918); // PstdExpRepItemLine
        SetTableFieldsToNormal(6919); // PstdExpRepLineItem
        SetTableFieldsToNormal(6920); // PstdExpRepLinePerDiem
        SetTableFieldsToNormal(6921); // ExpenseCategory
        SetTableFieldsToNormal(6922); // ExpenseCreditCardFeed
        SetTableFieldsToNormal(6923); // ExpenseEmployee
        SetTableFieldsToNormal(6924); // ExpenseGroup
        SetTableFieldsToNormal(6925); // ExpenseLocation
        SetTableFieldsToNormal(6926); // ExpensePolicyCondition
        SetTableFieldsToNormal(6927); // ExpensePolicyHeader
        SetTableFieldsToNormal(6928); // ExpensePostingGroup
        SetTableFieldsToNormal(6929); // ExpenseSubcategory
        SetTableFieldsToNormal(6930); // ExpenseAgentSetup
    end;

    local procedure ClassifyAgents()
    var
        DummyAgent: Record "Agent";
        DummyAgentAccessControl: Record "Agent Access Control";
        DummyAgentTask: Record "Agent Task";
        DummyAgentTaskMessage: Record "Agent Task Message";
        DummyAgentTaskMemoryEntry: Record "Agent Task Memory Entry";
        DummyAgentTaskFile: Record "Agent Task File";
        DummyAgentTaskTimelineStep: Record "Agent Task Timeline Step";
        DummyAgentTaskTimelineStepDetail: Record "Agent Task Timeline Step Det.";
        DummyAgentTaskTimeline: Record "Agent Task Timeline";
        DummyAgentTaskLogEntry: Record "Agent Task Log Entry";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Agent";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAgent.FieldNo("User Security ID"));

        TableNo := DATABASE::"Agent Access Control";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAgentAccessControl.FieldNo("Agent User Security ID"));
        SetFieldToPersonal(TableNo, DummyAgentAccessControl.FieldNo("User Security ID"));

        TableNo := DATABASE::"Agent Task";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAgentTask.FieldNo("Agent User Security ID"));
        SetFieldToPersonal(TableNo, DummyAgentTask.FieldNo("Created By"));

        TableNo := DATABASE::"Agent Task Message";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskMessage.FieldNo("Content"));

        TableNo := DATABASE::"Agent Task Memory Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAgentTaskMemoryEntry.FieldNo("User Security ID"));
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskMemoryEntry.FieldNo("Details"));
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskMemoryEntry.FieldNo("Description"));

        TableNo := DATABASE::"Agent Task File";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskFile.FieldNo("Content"));

        TableNo := DATABASE::"Agent Task Message Attachment";
        SetTableFieldsToNormal(TableNo);

        TableNo := DATABASE::"Agent Task Timeline Step";
        SetTableFieldsToNormal(TableNo);
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskTimelineStep.FieldNo("Title"));
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskTimelineStep.FieldNo("Description"));
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskTimelineStep.FieldNo("Primary Page Summary"));
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskTimelineStep.FieldNo("Primary Page Query"));

        TableNo := DATABASE::"Agent Task Timeline Step Det.";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAgentTaskTimelineStepDetail.FieldNo("User Security ID"));
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskTimelineStepDetail.FieldNo("Client Context"));

        TableNo := DATABASE::"Agent Task Timeline";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAgentTaskTimeline.FieldNo("Created By"));
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskTimeline.FieldNo(Summary));
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskTimeline.FieldNo(Title));

        TableNo := DATABASE::"Agent Task Log Entry";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, DummyAgentTaskLogEntry.FieldNo("User Security ID"));
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskLogEntry.FieldNo("Details"));
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskLogEntry.FieldNo("Description"));
        SetFieldToCompanyConfidential(TableNo, DummyAgentTaskLogEntry.FieldNo("Page Caption"));

        // Agent developer toolkit
        SetTableFieldsToNormal(4301); // "Agent Task Template"
        SetTableFieldsToNormal(4302); // "Agent Message Template"
        SetTableFieldsToNormal(4315); // "Developer Agent"
        SetFieldToCompanyConfidential(4315, 2); // Instructions

        // No-code agent 
        SetTableFieldsToNormal(4387); // No-Code Agent Setup
        SetFieldToPersonal(4387, 1); // Agent User Security Id
        SetFieldToPersonal(4387, 2); // Agent Initials

        // following tables are internal but still require classification
        SetTableFieldsToNormal(2000000258); // Agent Data table
        SetFieldToPersonal(2000000258, 1); // User Security Id
        SetFieldToCompanyConfidential(2000000258, 3); // Instructions

        SetTableFieldsToNormal(2000000259); // Agent Access Control Data table
        SetFieldToPersonal(2000000259, 1); // Agent User Security Id
        SetFieldToPersonal(2000000259, 2); // User Security Id

        SetTableFieldsToNormal(2000000267); // Agent Task Data table
        SetFieldToPersonal(2000000267, 2); // Agent User Security Id
        SetFieldToPersonal(2000000267, 3); // Created By

        SetTableFieldsToNormal(2000000268); // Agent Task Message Data table
        SetFieldToCompanyConfidential(2000000268, 5); // Content

        SetTableFieldsToNormal(2000000269); // Agent Task Memory Entry Data table
        SetFieldToPersonal(2000000269, 3); // User Security Id
        SetFieldToCompanyConfidential(2000000269, 5); // Details
        SetFieldToCompanyConfidential(2000000269, 6); // Description
        SetFieldToCompanyConfidential(2000000269, 8); // Internal Details

        SetTableFieldsToNormal(2000000271); // Agent Task Timeline Step Data table
        SetFieldToCompanyConfidential(2000000271, 4); // Description
        SetFieldToCompanyConfidential(2000000271, 6); // Primary Page Bookmark
        SetFieldToCompanyConfidential(2000000271, 7); // Primary Page Summary
        SetFieldToCompanyConfidential(2000000271, 8); // Primary Page Query
        SetFieldToPersonal(2000000271, 13); // Task Agent User Security ID

        SetTableFieldsToNormal(2000000272); // Agent Task File Data table
        SetFieldToCompanyConfidential(2000000272, 6); // Content

        SetTableFieldsToNormal(2000000273); // Agent Task Msg Attach Data table

        SetTableFieldsToNormal(2000000281); // Agent Task Log Entry Data table
        SetFieldToPersonal(2000000281, 3); // User Security ID
        SetFieldToCompanyConfidential(2000000281, 5); // Details
        SetFieldToCompanyConfidential(2000000281, 6); // Description
        SetFieldToCompanyConfidential(2000000281, 8); // Page Caption
        SetFieldToCompanyConfidential(2000000281, 9); // Client Context
    end;

    local procedure ClasifyScheduledPerformanceProfiling()
    var
        PerformanceProfileScheduler: Record "Performance Profile Scheduler";
        PerformanceProfiles: Record "Performance Profiles";
        TableNo: Integer;
    begin
        TableNo := DATABASE::"Performance Profile Scheduler";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, PerformanceProfileScheduler.FieldNo("User ID"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfileScheduler.FieldNo("Starting Date-Time"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfileScheduler.FieldNo("Ending Date-Time"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfileScheduler.FieldNo("Client Type"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfileScheduler.FieldNo("Enabled"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfileScheduler.FieldNo("Description"));

        TableNo := DATABASE::"Performance Profiles";
        SetTableFieldsToNormal(TableNo);
        SetFieldToPersonal(TableNo, PerformanceProfiles.FieldNo("User ID"));
        SetFieldToPersonal(TableNo, PerformanceProfiles.FieldNo("User Name"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfiles.FieldNo(Profile));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfiles.FieldNo("Starting Date-Time"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfiles.FieldNo("Activity Description"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfiles.FieldNo("Client Type"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfiles.FieldNo("Client Session ID"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfiles.FieldNo("Duration"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfiles.FieldNo("Declaring App"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfiles.FieldNo("Object Display Name"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfiles.FieldNo("Object Type"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfiles.FieldNo("Object ID"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfiles.FieldNo("Http Call Duration"));
        SetFieldToCompanyConfidential(TableNo, PerformanceProfiles.FieldNo("Http Call Number"));
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateEvaluationDataOnAfterClassifyTablesToNormal()
    begin
    end;
}