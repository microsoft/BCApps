// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.CashFlow.Setup;
using Microsoft.CostAccounting.Setup;
using Microsoft.Foundation.Reporting;
using System.Email;
using Microsoft.Projects.Project.Setup;
using Microsoft.Inventory.Setup;
using Microsoft.HumanResources.Setup;
using Microsoft.Inventory.Transfer;
using System.Security.User;
using System.Security.AccessControl;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Item;
using Microsoft.FixedAssets.Setup;
using Microsoft.Warehouse.Setup;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Task;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Interaction;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Setup;
using Microsoft.Intercompany.Setup;
using Microsoft.EServices.OnlineMap;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Dimension;
using System.Environment.Configuration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Period;
using Microsoft.Bank.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.VAT.Clause;

codeunit 1876 "Business Setup Subscribers"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyShortTitleTxt: Label 'Company';
        CompanyTitleTxt: Label 'Company information';
        CompanyDescriptionTxt: Label 'Make general company settings.';
        CompanyKeywordsTxt: Label 'Company';
        CountriesRegionsTitleTxt: Label 'Define Countries and Regions';
        CountriesRegionsShortTitleTxt: Label 'Countries/Regions';
        CountriesRegionsDescriptionTxt: Label 'Define which countries and regions you trade in.';
        CountriesRegionsKeywordsTxt: Label 'Reference data, Country, Region, System';
        CurrenciesTitleTxt: Label 'Currencies';
        CurrenciesShortTitleTxt: Label 'Currencies';
        CurrenciesDescriptionTxt: Label 'Define how you trade in foreign currencies.';
        CurrenciesKeywordsTxt: Label 'Finance, Currency, Money';
        GeneralLedgerSetupTitleTxt: Label 'Set up the general ledger';
        GeneralLedgerSetupShortTitleTxt: Label 'General Ledger';
        GeneralLedgerSetupDescriptionTxt: Label 'Specify general information about how the company keeps its accounts, such as the rounding precision, the local currency, address formats, and document number series.';
        GeneralLedgerSetupKeywordsTxt: Label 'Ledger, Finance';
        JobsSetupTitleTxt: Label 'Set up policies for projects';
        JobsSetupShortTitleTxt: Label 'Configure projects';
        JobsSetupDescriptionTxt: Label 'Set up policies for project management (projects), including the treatment of work in process (WIP) in your organization.';
        JobsSetupKeywordsTxt: Label 'Projects, Project Management';
        FixedAssetSetupTitleTxt: Label 'Set up accounting policies for fixed assets';
        FixedAssetSetupShortTitleTxt: Label 'Fixed assets setup';
        FixedAssetSetupDescriptionTxt: Label 'Set up accounting policies for fixed assets, such as posting period and number series.';
        FixedAssetSetupKeywordsTxt: Label 'Fixed Assets';
        HumanResourcesSetupTitleTxt: Label 'Set up human resources';
        HumanResourcesSetupShortTitleTxt: Label 'Human resources setup';
        HumanResourcesSetupDescriptionTxt: Label 'Define basic information about how to manage employee data.';
        HumanResourcesSetupKeywordsTxt: Label 'Human Resources, HR';
        InventorySetupTitleTxt: Label 'Inventory setup';
        InventorySetupShortTitleTxt: Label 'Set up inventory management';
        InventorySetupDescriptionTxt: Label 'Set up policies for inventory items.';
        InventorySetupKeywordsTxt: Label 'Inventory, Number Series, Product';
        LocationsTitleTxt: Label 'Locations';
        LocationsShortTitleTxt: Label 'Locations';
        LocationsDescriptionTxt: Label 'View or change your locations, such as warehouses and distribution centers.';
        LocationsKeywordsTxt: Label 'Inventory, Location';
        TransferRoutesTitleTxt: Label 'Transfer routes';
        TransferRoutesShortTitleTxt: Label 'Transfer routes';
        TransferRoutesDescriptionTxt: Label 'View or change transfer routes that are the combination of a transfer-from location and a transfer-to location.';
        TransferRoutesKeywordsTxt: Label 'Inventory, Location, Transfer';
        ItemChargesTitleTxt: Label 'Item charges';
        ItemChargesShortTitleTxt: Label 'Item charges';
        ItemChargesDescriptionTxt: Label 'Set up item charge numbers and their associated relations, such as general product posting group and tax group.';
        ItemChargesKeywordsTxt: Label 'Inventory, Item Charges';
        NoSeriesTitleTxt: Label 'Number Series';
        NoSeriesShortTitleTxt: Label 'Number Series';
        NoSeriesDescriptionTxt: Label 'Manage number series for master data, documents, and transaction records.';
        NoSeriesKeywordsTxt: Label 'Finance, Number Series';
        PostCodesTitleTxt: Label 'Post Codes';
        PostCodesShortTitleTxt: Label 'Post Codes';
        PostCodesDescriptionTxt: Label 'Set up or update post codes.';
        PostCodesKeywordsTxt: Label 'Mail, System, Code';
        ReasonCodesTitleTxt: Label 'Reason Codes';
        ReasonCodesShortTitleTxt: Label 'Reason Codes';
        ReasonCodesDescriptionTxt: Label 'Set up reasons to assign to transactions, such as returns.';
        ReasonCodesKeywordsTxt: Label 'Reference data, Reason, Code';
        SourceCodesTitleTxt: Label 'Source Codes';
        SourceCodesShortTitleTxt: Label 'Source Codes';
        SourceCodesDescriptionTxt: Label 'Set up sources to assign to transactions for identification.';
        SourceCodesKeywordsTxt: Label 'Reference data, Source, Code';
        PurchasePayablesSetupTitleTxt: Label 'Set up purchases and payables';
        PurchasePayablesSetupShortTitleTxt: Label 'Purchase & payables setup';
        PurchasePayablesSetupDescriptionTxt: Label 'Define how you want to manage certain aspects of purchases and outgoing payments.';
        PurchasePayablesSetupKeywordsTxt: Label 'Purchase, Payables, Finance, Payment';
        SalesReceivablesSetupTitleTxt: Label 'Set up sales and receivables';
        SalesReceivablesSetupShortTitleTxt: Label 'Sales & receivables setup';
        SalesReceivablesSetupDescriptionTxt: Label 'Define how you process sales and incoming payments.';
        SalesReceivablesSetupKeywordsTxt: Label 'Sales, Receivables, Finance, Payment';
        PermissionSetsTitleTxt: Label 'Permission sets';
        PermissionSetsShortTitleTxt: Label 'Permission sets';
        PermissionSetsDescriptionTxt: Label 'Define the permissions that you can assign to one or more users.';
        PermissionSetsKeywordsTxt: Label 'User, Permission, System';
        ReportLayoutsTitleTxt: Label 'Report layout selection';
        ReportLayoutsShortTitleTxt: Label 'Report layout selection';
        ReportLayoutsDescriptionTxt: Label 'Define the appearance for PDF or printed documents and reports.';
        ReportLayoutsKeywordsTxt: Label 'Report, Layout, Design';
        EmailAccountMailSetupTitleTxt: Label 'Email account setup';
        EmailAccountMailSetupShortTitleTxt: Label 'Email account setup';
        EmailAccountSetupDescriptionTxt: Label 'Set up your email accounts.';
        EmailAccountSetupKeywordsTxt: Label 'System, SMTP, Mail, Outlook';
        UsersTitleTxt: Label 'Give permissions to users';
        UsersShortTitleTxt: Label 'User permissions';
        UsersDescriptionTxt: Label 'Manage who has access to what based on permissions.';
        UsersKeywordsTxt: Label 'System, User, Permission, Authentication, Password';
        ResponsibilityCentersTitleTxt: Label 'Set up responsibility centers';
        ResponsibilityCentersShortTitleTxt: Label 'Responsibility centers';
        ResponsibilityCentersDescriptionTxt: Label 'Set up additional company locations, such as sales offices or warehouses.';
        ResponsibilityCentersKeywordsTxt: Label 'Location, Distributed, Office';
        OnlineMapSetupTitleTxt: Label 'Set up default online map';
        OnlineMapSetupShortTitleTxt: Label 'Online map setup';
        OnlineMapSetupDescriptionTxt: Label 'Specify the map to use when you choose the Online Map action on a customer or contact card, for example.';
        OnlineMapSetupKeywordsTxt: Label 'Map, Geo, Reference data';
        AccountingPeriodsTitleTxt: Label 'Accounting Periods';
        AccountingPeriodsShortTitleTxt: Label 'Accounting Periods';
        AccountingPeriodsDescriptionTxt: Label 'Set up the number of accounting periods within a fiscal year, such as 12 monthly periods, and specify which period is the start of the new fiscal year.';
        AccountingPeriodsKeywordsTxt: Label 'Accounting, Periods';
        DimensionsTitleTxt: Label 'Dimensions';
        DimensionsShortTitleTxt: Label 'Dimensions';
        DimensionsDescriptionTxt: Label 'Set up dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
        DimensionsKeywordsTxt: Label 'Dimensions';
        CashFlowSetupTitleTxt: Label 'Set up cash flows';
        CashFlowSetupShortTitleTxt: Label 'Cash flow setup';
        CashFlowSetupDescriptionTxt: Label 'Set up the accounts where cash flow figures for sales, purchase, and fixed-asset transactions are stored.';
        CashFlowSetupKeywordsTxt: Label 'Cash Flow';
        BankExportImportSetupTitleTxt: Label 'Set up export/import of bank data';
        BankExportImportSetupShortTitleTxt: Label 'Bank export/import';
        BankExportImportSetupDescriptionTxt: Label 'Set up file formats for exporting vendor payments and for importing bank statements.';
        BankExportImportSetupKeywordsTxt: Label 'Bank, Statement, Export, Import';
        GeneralPostingSetupTitleTxt: Label 'Set up general posting';
        GeneralPostingSetupShortTitleTxt: Label 'General Posting Setup';
        GeneralPostingSetupDescriptionTxt: Label 'Set up combinations of general business and general product posting groups by specifying account numbers for posting of sales and purchase transactions.';
        GeneralPostingSetupKeywordsTxt: Label 'Posting, General';
        GenBusinessPostingGroupsTitleTxt: Label 'General business posting groups';
        GenBusinessPostingGroupsShortTitleTxt: Label 'General business posting groups';
        GenBusinessPostingGroupsDescriptionTxt: Label 'Set up the trade-type posting groups that you assign to customer and vendor cards to link transactions with the appropriate general ledger account.';
        GenBusinessPostingGroupsKeywordsTxt: Label 'Posting, General';
        GenProductPostingGroupsTitleTxt: Label 'General product posting groups';
        GenProductPostingGroupsShortTitleTxt: Label 'General product posting groups';
        GenProductPostingGroupsDescriptionTxt: Label 'Set up the item-type posting groups that you assign to customer and vendor cards to link transactions with the appropriate general ledger account.';
        GenProductPostingGroupsKeywordsTxt: Label 'Posting, Product';
        VATPostingSetupTitleTxt: Label 'Set up VAT posting';
        VATPostingSetupShortTitleTxt: Label 'VAT Posting Setup';
        VATPostingSetupDescriptionTxt: Label 'Define how tax is posted to the general ledger. The VAT posting setup consists of combinations of VAT business posting groups and VAT product posting groups.';
        VATPostingSetupKeywordsTxt: Label 'VAT, Posting';
        VATBusinessPostingGroupsTitleTxt: Label 'VAT business posting groups';
        VATBusinessPostingGroupsShortTitleTxt: Label 'VAT business posting groups';
        VATBusinessPostingGroupsDescriptionTxt: Label 'Set up the trade-type posting groups that you assign to customer and vendor cards to link VAT amounts with the appropriate general ledger account.';
        VATBusinessPostingGroupsKeywordsTxt: Label 'VAT, Posting, Business';
        VATProductPostingGroupsTitleTxt: Label 'VAT product posting groups';
        VATProductPostingGroupsShortTitleTxt: Label 'VAT product posting groups';
        VATProductPostingGroupsDescriptionTxt: Label 'Set up the item-type posting groups that you assign to customer and vendor cards to link VAT amounts with the appropriate general ledger account.';
        VATProductPostingGroupsKeywordsTxt: Label 'VAT, Posting';
        VATReportSetupTitleTxt: Label 'Set up VAT reporting';
        VATReportSetupShortTitleTxt: Label 'VAT Report Setup';
        VATReportSetupDescriptionTxt: Label 'Set up number series and options for the report that you periodically send to the authorities to declare your VAT.';
        VATReportSetupKeywordsTxt: Label 'VAT, Report';
        BankAccountPostingGroupsTitleTxt: Label 'Bank account posting groups';
        BankAccountPostingGroupsShortTitleTxt: Label 'Bank account posting groups';
        BankAccountPostingGroupsDescriptionTxt: Label 'Set up posting groups, so that payments in and out of each bank account are posted to the specified general ledger account.';
        BankAccountPostingGroupsKeywordsTxt: Label 'Bank Account, Posting';
        GeneralJournalTemplatesTitleTxt: Label 'General journal templates';
        GeneralJournalTemplatesShortTitleTxt: Label 'General journal templates';
        GeneralJournalTemplatesDescriptionTxt: Label 'Set up templates for the journals that you use for bookkeeping tasks. Templates allow you to work in a journal window that is designed for a specific purpose.';
        GeneralJournalTemplatesKeywordsTxt: Label 'Journal, Templates';
        VATStatementTemplatesTitleTxt: Label 'VAT statement templates';
        VATStatementTemplatesShortTitleTxt: Label 'VAT statement templates';
        VATStatementTemplatesDescriptionTxt: Label 'Set up the reports that you use to settle VAT and report to the customs and tax authorities.';
        VATStatementTemplatesKeywordsTxt: Label 'VAT, Statement, Templates';
        BusinessRelationsTitleTxt: Label 'Business relation types';
        BusinessRelationsShortTitleTxt: Label 'Business relation types';
        BusinessRelationsDescriptionTxt: Label 'Set up the types of business relations specifications that you can list with your contact companies. For example, customer, vendor, lawyer, and so on.';
        BusinessRelationsKeywordsTxt: Label 'Business Relations.';
        IndustryGroupsTitleTxt: Label 'Industry groups';
        IndustryGroupsShortTitleTxt: Label 'Industry groups';
        IndustryGroupsDescriptionTxt: Label 'Set up the industry groups that you can assign to contact companies, such as retail. The list also shows the number of contacts you have assigned to each industry group.';
        IndustryGroupsKeywordsTxt: Label 'Industry Groups';
        WebSourcesTitleTxt: Label 'Web sources';
        WebSourcesShortTitleTxt: Label 'Web sources';
        WebSourcesDescriptionTxt: Label 'View or edit the search engines that you can use when accessing information about your contact companies, such as Bing.';
        WebSourcesKeywordsTxt: Label 'Web Sources';
        JobResponsibilitiesTitleTxt: Label 'Job responsibilities';
        JobResponsibilitiesShortTitleTxt: Label 'Job responsibilities';
        JobResponsibilitiesDescriptionTxt: Label 'View or edit the job responsibilities you have assigned to each contact person. Once you have assigned job responsibilities, you can use this information to create segments.';
        JobResponsibilitiesKeywordsTxt: Label 'Job Responsibilities';
        OrganizationalLevelsTitleTxt: Label 'Organizational levels';
        OrganizationalLevelsShortTitleTxt: Label 'Organizational levels';
        OrganizationalLevelsDescriptionTxt: Label 'View or edit the organizational levels that you can assign to contacts. You can set up as many organizational levels as you want.';
        OrganizationalLevelsKeywordsTxt: Label 'Organizational Levels';
        InteractionGroupsTitleTxt: Label 'Interaction groups';
        InteractionGroupsShortTitleTxt: Label 'Interaction groups';
        InteractionGroupsDescriptionTxt: Label 'View or edit the groups that relate to the different interaction templates. Interaction groups are made up of interaction templates that have the same characteristics.';
        InteractionGroupsKeywordsTxt: Label 'Interaction Groups';
        InteractionTemplatesTitleTxt: Label 'Interaction templates';
        InteractionTemplatesShortTitleTxt: Label 'Interaction templates';
        InteractionTemplatesDescriptionTxt: Label 'View or edit the templates that you can use when you create interactions, such as their unit cost and duration, whether or not they contain an attachment, and so on.';
        InteractionTemplatesKeywordsTxt: Label 'Interaction Templates';
        SalutationsTitleTxt: Label 'Salutations';
        SalutationsShortTitleTxt: Label 'Salutations';
        SalutationsDescriptionTxt: Label 'View or edit codes for your salutations and add a brief description.';
        SalutationsKeywordsTxt: Label 'Salutations';
        MailingGroupsTitleTxt: Label 'Mailing groups';
        MailingGroupsShortTitleTxt: Label 'Mailing groups';
        MailingGroupsDescriptionTxt: Label 'View or edit the mailing groups that you can assign to contacts.';
        MailingGroupsKeywordsTxt: Label 'Mailing Groups';
        SalesCyclesTitleTxt: Label 'Sales cycles';
        SalesCyclesShortTitleTxt: Label 'Sales cycles';
        SalesCyclesDescriptionTxt: Label 'View or edit general information about the different sales cycles that you use to manage sales opportunities.';
        SalesCyclesKeywordsTxt: Label 'Sales Cycles';
        CloseOpportunityCodesTitleTxt: Label 'Codes for closing opportunities';
        CloseOpportunityCodesShortTitleTxt: Label 'Codes for closing opportunities';
        CloseOpportunityCodesDescriptionTxt: Label 'Set up codes that you can use to indicate the reason you have closed your opportunities.';
        CloseOpportunityCodesKeywordsTxt: Label 'Close Opportunity Codes';
        QuestionnaireSetupTitleTxt: Label 'Set up questionnaires';
        QuestionnaireSetupShortTitleTxt: Label 'Questionnaire setup';
        QuestionnaireSetupDescriptionTxt: Label 'View or edit the questionnaires that you use to establish the profile of your contacts. For example, you can create a questionnaire for companies that are prospective customers.';
        QuestionnaireSetupKeywordsTxt: Label 'Questionnaire Setup';
        ActivitiesTitleTxt: Label 'Activities';
        ActivitiesShortTitleTxt: Label 'Activities';
        ActivitiesDescriptionTxt: Label 'Set up activities when you want to assign a task to a salesperson that is complex and could be divided into several steps.';
        ActivitiesKeywordsTxt: Label 'Activities.';
        MarketingSetupTitleTxt: Label 'Set up marketing';
        MarketingSetupShortTitleTxt: Label 'Marketing setup';
        MarketingSetupDescriptionTxt: Label 'Set up how you want to set up your contacts, campaigns, segments, interactions, opportunities, and to-dos.';
        MarketingSetupKeywordsTxt: Label 'Marketing Setup';
        InteractionTemplateSetupTitleTxt: Label 'Set up interaction templates';
        InteractionTemplateSetupShortTitleTxt: Label 'Interaction template setup';
        InteractionTemplateSetupDescriptionTxt: Label 'Set up the interaction templates you want to use when interactions are recorded.';
        InteractionTemplateSetupKeywordsTxt: Label 'Interaction Template Setup';
        VATClausesTitleTxt: Label 'VAT clauses';
        VATClausesShortTitleTxt: Label 'VAT clauses';
        VATClausesDescriptionTxt: Label 'Set up descriptions of VAT types if required in your country or region. The clauses are printed on invoices based on your VAT posting setup for non-standard VAT rates.';
        VATClausesKeywordsTxt: Label 'VAT, Invoice, Clause';
        AnalysisViewsTitleTxt: Label 'Analysis by Dimensions';
        AnalysisViewsShortTitleTxt: Label 'Analysis by dimensions';
        AnalysisViewsDescriptionTxt: Label 'Set up which dimension values and filters are used when you use analysis views to analyze amounts in your general ledger by dimensions.';
        AnalysisViewsKeywordsTxt: Label 'Dimensions, Reporting, Analysis Views';
        VATReportConfigTitleTxt: Label 'VAT report configuration';
        VATReportConfigShortTitleTxt: Label 'VAT report configuration';
        VATReportConfigDescriptionTxt: Label 'Configure the objects that you use to process VAT reports.';
        VATReportConfigKeywordsTxt: Label 'VAT Report, Return, EC Sales List';
        ICSetupTitleTxt: Label 'Set up intercompany postings';
        ICSetupShortTitleTxt: Label 'Intercompany setup';
        ICSetupDescriptionTxt: Label 'Set up how you want to electronically transfer transactions between the current company and partner companies.';
        ICSetupKeywordsTxt: Label 'Intercompany';
        ICPartnersTitleTxt: Label 'Intercompany partners';
        ICPartnersShortTitleTxt: Label 'Intercompany partners';
        ICPartnersDescriptionTxt: Label 'View or edit the codes for partners that you have intercompany transactions with.';
        ICPartnersKeywordsTxt: Label 'Intercompany, Partners';
        ICChartOfAccountsTitleTxt: Label 'Intercompany chart of accounts';
        ICChartOfAccountsShortTitleTxt: Label 'Intercompany chart of accounts';
        ICChartOfAccountsDescriptionTxt: Label 'Specify how you want to map the current company''s chart of accounts to the charts of accounts of your intercompany partners.';
        ICChartOfAccountsKeywordsTxt: Label 'Intercompany, Ledger, Finance';
        ICDimensionsTitleTxt: Label 'Intercompany dimensions';
        ICDimensionsShortTitleTxt: Label 'Intercompany dimensions';
        ICDimensionsDescriptionTxt: Label 'Specify how you want to map the current company''s dimension codes to the dimension codes of your intercompany partners.';
        ICDimensionsKeywordsTxt: Label 'Intercompany, Dimensions';
        CostAccountingSetupTitleTxt: Label 'Set up cost accounting';
        CostAccountingSetupShortTitleTxt: Label 'Cost accounting setup';
        CostAccountingSetupDescriptionTxt: Label 'Set up general ledger transfers to cost accounting, dimension links to cost centers and objects, and how to handle allocation document numbers and IDs.';
        CostAccountingSetupKeywordsTxt: Label 'Cost, Accounting';
        WarehouseSetupTitleTxt: Label 'Warehouse setup';
        WarehouseSetupShortTitleTxt: Label 'Set up warehouse management';
        WarehouseSetupDescriptionTxt: Label 'Set up number series for warehouse documents, error policies for posting receipts and shipments, and activity requirements for warehouse functionality.';
        WarehouseSetupKeywordsTxt: Label 'Inventory, Location, Number series';
        UserSettingsTitleTxt: Label 'Manage user settings';
        UserSettingsShortTitleTxt: Label 'User settings';
        UserSettingsDescriptionTxt: Label 'Manage role, language, and regional settings for users.';
        UserSettingsKeywordsTxt: Label 'Role, Language, Regional Settings';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterManualSetup', '', false, false)]
    local procedure InsertSetupOnRegisterManualSetup(var Sender: Codeunit "Guided Experience")
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        Info: ModuleInfo;
        ManualSetupCategory: Enum "Manual Setup Category";
    begin
        NavApp.GetCurrentModuleInfo(Info);

        // General
        if ApplicationAreaMgmtFacade.IsFoundationEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then begin
            Sender.InsertManualSetup(CompanyTitleTxt, CompanyShortTitleTxt, CompanyDescriptionTxt, 3, ObjectType::Page,
              Page::"Company Information", ManualSetupCategory::General, CompanyKeywordsTxt);
            Sender.InsertManualSetup(CountriesRegionsTitleTxt, CountriesRegionsShortTitleTxt, CountriesRegionsDescriptionTxt, 5, ObjectType::Page,
              Page::"Countries/Regions", ManualSetupCategory::General, CountriesRegionsKeywordsTxt);
            Sender.InsertManualSetup(NoSeriesTitleTxt, NoSeriesShortTitleTxt, NoSeriesDescriptionTxt, 10, ObjectType::Page,
              Page::"No. Series", ManualSetupCategory::General, NoSeriesKeywordsTxt);
            Sender.InsertManualSetup(PostCodesTitleTxt, PostCodesShortTitleTxt, PostCodesDescriptionTxt, 2, ObjectType::Page,
              Page::"Post Codes", ManualSetupCategory::General, PostCodesKeywordsTxt);
            Sender.InsertManualSetup(ReasonCodesTitleTxt, ReasonCodesShortTitleTxt, ReasonCodesDescriptionTxt, 3, ObjectType::Page,
              Page::"Reason Codes", ManualSetupCategory::General, ReasonCodesKeywordsTxt);
            Sender.InsertManualSetup(SourceCodesTitleTxt, SourceCodesShortTitleTxt, SourceCodesDescriptionTxt, 3, ObjectType::Page,
              Page::"Source Codes", ManualSetupCategory::General, SourceCodesKeywordsTxt);
            Sender.InsertManualSetup(UserSettingsTitleTxt, UserSettingsShortTitleTxt, UserSettingsDescriptionTxt, 5, ObjectType::Page,
              Page::"User Settings List", ManualSetupCategory::General, UserSettingsKeywordsTxt);
        end;

        if ApplicationAreaMgmtFacade.IsSuiteEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(CurrenciesTitleTxt, CurrenciesShortTitleTxt, CurrenciesDescriptionTxt, 2, ObjectType::Page,
              Page::Currencies, ManualSetupCategory::General, CurrenciesKeywordsTxt);

        // Finance
        if ApplicationAreaMgmtFacade.IsFoundationEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then begin
            Sender.InsertManualSetup(GeneralLedgerSetupTitleTxt, GeneralLedgerSetupShortTitleTxt, GeneralLedgerSetupDescriptionTxt, 15, ObjectType::Page,
              Page::"General Ledger Setup", ManualSetupCategory::Finance, GeneralLedgerSetupKeywordsTxt);
            Sender.InsertManualSetup(AccountingPeriodsTitleTxt, AccountingPeriodsShortTitleTxt, AccountingPeriodsDescriptionTxt, 7, ObjectType::Page,
              Page::"Accounting Periods", ManualSetupCategory::Finance, AccountingPeriodsKeywordsTxt);
            Sender.InsertManualSetup(BankExportImportSetupTitleTxt, BankExportImportSetupShortTitleTxt, BankExportImportSetupDescriptionTxt, 5, ObjectType::Page,
              Page::"Bank Export/Import Setup", ManualSetupCategory::Finance, BankExportImportSetupKeywordsTxt);
            Sender.InsertManualSetup(GeneralPostingSetupTitleTxt, GeneralPostingSetupShortTitleTxt, GeneralPostingSetupDescriptionTxt, 10, ObjectType::Page,
              Page::"General Posting Setup", ManualSetupCategory::Finance, GeneralPostingSetupKeywordsTxt);
            Sender.InsertManualSetup(GenBusinessPostingGroupsTitleTxt, GenBusinessPostingGroupsShortTitleTxt, GenBusinessPostingGroupsDescriptionTxt, 10, ObjectType::Page,
              Page::"Gen. Business Posting Groups", ManualSetupCategory::Finance, GenBusinessPostingGroupsKeywordsTxt);
            Sender.InsertManualSetup(GenProductPostingGroupsTitleTxt, GenProductPostingGroupsShortTitleTxt, GenProductPostingGroupsDescriptionTxt, 7, ObjectType::Page,
              Page::"Gen. Product Posting Groups", ManualSetupCategory::Finance, GenProductPostingGroupsKeywordsTxt);
            Sender.InsertManualSetup(VATPostingSetupTitleTxt, VATPostingSetupShortTitleTxt, VATPostingSetupDescriptionTxt, 10, ObjectType::Page,
              Page::"VAT Posting Setup", ManualSetupCategory::Finance, VATPostingSetupKeywordsTxt);
            Sender.InsertManualSetup(VATBusinessPostingGroupsTitleTxt, VATBusinessPostingGroupsShortTitleTxt, VATBusinessPostingGroupsDescriptionTxt, 10, ObjectType::Page,
              Page::"VAT Business Posting Groups", ManualSetupCategory::Finance, VATBusinessPostingGroupsKeywordsTxt);
            Sender.InsertManualSetup(VATProductPostingGroupsTitleTxt, VATProductPostingGroupsShortTitleTxt, VATProductPostingGroupsDescriptionTxt, 10, ObjectType::Page,
              Page::"VAT Product Posting Groups", ManualSetupCategory::Finance, VATProductPostingGroupsKeywordsTxt);
            Sender.InsertManualSetup(VATReportSetupTitleTxt, VATReportSetupShortTitleTxt, VATReportSetupDescriptionTxt, 3, ObjectType::Page,
              Page::"VAT Report Setup", ManualSetupCategory::Finance, VATReportSetupKeywordsTxt);
            Sender.InsertManualSetup(BankAccountPostingGroupsTitleTxt, BankAccountPostingGroupsShortTitleTxt, BankAccountPostingGroupsDescriptionTxt, 2, ObjectType::Page,
              Page::"Bank Account Posting Groups", ManualSetupCategory::Finance, BankAccountPostingGroupsKeywordsTxt);
            Sender.InsertManualSetup(GeneralJournalTemplatesTitleTxt, GeneralJournalTemplatesShortTitleTxt, GeneralJournalTemplatesDescriptionTxt, 10, ObjectType::Page,
              Page::"General Journal Templates", ManualSetupCategory::Finance, GeneralJournalTemplatesKeywordsTxt);
            Sender.InsertManualSetup(VATStatementTemplatesTitleTxt, VATStatementTemplatesShortTitleTxt, VATStatementTemplatesDescriptionTxt, 10, ObjectType::Page,
              Page::"VAT Statement Templates", ManualSetupCategory::Finance, VATStatementTemplatesKeywordsTxt);
            Sender.InsertManualSetup(VATClausesTitleTxt, VATClausesShortTitleTxt, VATClausesDescriptionTxt, 10, ObjectType::Page,
              Page::"VAT Clauses", ManualSetupCategory::Finance, VATClausesKeywordsTxt);
            Sender.InsertManualSetup(VATReportConfigTitleTxt, VATReportConfigShortTitleTxt, VATReportConfigDescriptionTxt, 2, ObjectType::Page,
              Page::"VAT Reports Configuration", ManualSetupCategory::Finance, VATReportConfigKeywordsTxt);
            Sender.InsertManualSetup(CashFlowSetupTitleTxt, CashFlowSetupShortTitleTxt, CashFlowSetupDescriptionTxt, 5, ObjectType::Page,
              Page::"Cash Flow Setup", ManualSetupCategory::Finance, CashFlowSetupKeywordsTxt);
        end;

        if ApplicationAreaMgmtFacade.IsSuiteEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then begin
            Sender.InsertManualSetup(DimensionsTitleTxt, DimensionsShortTitleTxt, DimensionsDescriptionTxt, 15, ObjectType::Page,
              Page::Dimensions, ManualSetupCategory::Finance, DimensionsKeywordsTxt);
            Sender.InsertManualSetup(AnalysisViewsTitleTxt, AnalysisViewsShortTitleTxt, AnalysisViewsDescriptionTxt, 10, ObjectType::Page,
              Page::"Analysis View List", ManualSetupCategory::Finance, AnalysisViewsKeywordsTxt);
            Sender.InsertManualSetup(CostAccountingSetupTitleTxt, CostAccountingSetupShortTitleTxt, CostAccountingSetupDescriptionTxt, 30, ObjectType::Page,
              Page::"Cost Accounting Setup", ManualSetupCategory::Finance, CostAccountingSetupKeywordsTxt);
        end;

        if ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(ResponsibilityCentersTitleTxt, ResponsibilityCentersShortTitleTxt, ResponsibilityCentersDescriptionTxt, 10, ObjectType::Page,
              Page::"Responsibility Center List", ManualSetupCategory::Finance, ResponsibilityCentersKeywordsTxt);

        // System
        if ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(PermissionSetsTitleTxt, PermissionSetsShortTitleTxt, PermissionSetsDescriptionTxt, 15, ObjectType::Page,
              Page::"Permission Sets", ManualSetupCategory::System, PermissionSetsKeywordsTxt);

        if ApplicationAreaMgmtFacade.IsFoundationEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then begin
            Sender.InsertManualSetup(ReportLayoutsTitleTxt, ReportLayoutsShortTitleTxt, ReportLayoutsDescriptionTxt, 15, ObjectType::Page,
              Page::"Report Layout Selection", ManualSetupCategory::System, ReportLayoutsKeywordsTxt);

            Sender.InsertManualSetup(EmailAccountMailSetupTitleTxt, EmailAccountMailSetupShortTitleTxt, EmailAccountSetupDescriptionTxt, 7, ObjectType::Page,
              Page::"Email Accounts", ManualSetupCategory::System, EmailAccountSetupKeywordsTxt);

            Sender.InsertManualSetup(UsersTitleTxt, UsersShortTitleTxt, UsersDescriptionTxt, 10, ObjectType::Page,
              Page::Users, ManualSetupCategory::System, UsersKeywordsTxt);
        end;

        // Jobs
        if ApplicationAreaMgmtFacade.IsJobsEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(JobsSetupTitleTxt, JobsSetupShortTitleTxt, JobsSetupDescriptionTxt, 5, ObjectType::Page,
              Page::"Jobs Setup", ManualSetupCategory::Jobs, JobsSetupKeywordsTxt);

        // Fixed Assets
        if ApplicationAreaMgmtFacade.IsFixedAssetEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(FixedAssetSetupTitleTxt, FixedAssetSetupShortTitleTxt, FixedAssetSetupDescriptionTxt, 10, ObjectType::Page,
              Page::"Fixed Asset Setup", ManualSetupCategory::"Fixed Assets", FixedAssetSetupKeywordsTxt);

        // HR
        if ApplicationAreaMgmtFacade.IsBasicHREnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(HumanResourcesSetupTitleTxt, HumanResourcesSetupShortTitleTxt, HumanResourcesSetupDescriptionTxt, 30, ObjectType::Page,
              Page::"Human Resources Setup", ManualSetupCategory::HR, HumanResourcesSetupKeywordsTxt);

        // Inventory
        if ApplicationAreaMgmtFacade.IsFoundationEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(InventorySetupTitleTxt, InventorySetupShortTitleTxt, InventorySetupDescriptionTxt, 5, ObjectType::Page,
              Page::"Inventory Setup", ManualSetupCategory::Inventory, InventorySetupKeywordsTxt);

        if ApplicationAreaMgmtFacade.IsSuiteEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(WarehouseSetupTitleTxt, WarehouseSetupShortTitleTxt, WarehouseSetupDescriptionTxt, 10, ObjectType::Page,
                  Page::"Warehouse Setup", ManualSetupCategory::Inventory, WarehouseSetupKeywordsTxt);

        // Location
        if ApplicationAreaMgmtFacade.IsLocationEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then begin
            Sender.InsertManualSetup(LocationsTitleTxt, LocationsShortTitleTxt, LocationsDescriptionTxt, 2, ObjectType::Page,
              Page::"Location List", ManualSetupCategory::Inventory, LocationsKeywordsTxt);

            Sender.InsertManualSetup(TransferRoutesTitleTxt, TransferRoutesShortTitleTxt, TransferRoutesDescriptionTxt, 5, ObjectType::Page,
              Page::"Transfer Routes", ManualSetupCategory::Inventory, TransferRoutesKeywordsTxt);
        end;

        // Item Charges
        if ApplicationAreaMgmtFacade.IsItemChargesEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(ItemChargesTitleTxt, ItemChargesShortTitleTxt, ItemChargesDescriptionTxt, 10, ObjectType::Page,
              Page::"Item Charges", ManualSetupCategory::Inventory, ItemChargesKeywordsTxt);

        // Relationship Management
        if ApplicationAreaMgmtFacade.IsSuiteEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then begin
            Sender.InsertManualSetup(BusinessRelationsTitleTxt, BusinessRelationsShortTitleTxt, BusinessRelationsDescriptionTxt, 3, ObjectType::Page,
              Page::"Business Relations", ManualSetupCategory::"Relationship Mgt", BusinessRelationsKeywordsTxt);

            Sender.InsertManualSetup(IndustryGroupsTitleTxt, IndustryGroupsShortTitleTxt, IndustryGroupsDescriptionTxt, 3, ObjectType::Page,
              Page::"Industry Groups", ManualSetupCategory::"Relationship Mgt", IndustryGroupsKeywordsTxt);

            Sender.InsertManualSetup(WebSourcesTitleTxt, WebSourcesShortTitleTxt, WebSourcesDescriptionTxt, 2, ObjectType::Page,
              Page::"Web Sources", ManualSetupCategory::"Relationship Mgt", WebSourcesKeywordsTxt);

            Sender.InsertManualSetup(JobResponsibilitiesTitleTxt, JobResponsibilitiesShortTitleTxt, JobResponsibilitiesDescriptionTxt, 3, ObjectType::Page,
              Page::"Job Responsibilities", ManualSetupCategory::"Relationship Mgt", JobResponsibilitiesKeywordsTxt);

            Sender.InsertManualSetup(OrganizationalLevelsTitleTxt, OrganizationalLevelsShortTitleTxt, OrganizationalLevelsDescriptionTxt, 2, ObjectType::Page,
              Page::"Organizational Levels", ManualSetupCategory::"Relationship Mgt", OrganizationalLevelsKeywordsTxt);

            Sender.InsertManualSetup(InteractionGroupsTitleTxt, InteractionGroupsShortTitleTxt, InteractionGroupsDescriptionTxt, 3, ObjectType::Page,
              Page::"Interaction Groups", ManualSetupCategory::"Relationship Mgt", InteractionGroupsKeywordsTxt);

            Sender.InsertManualSetup(InteractionTemplatesTitleTxt, InteractionTemplatesShortTitleTxt, InteractionTemplatesDescriptionTxt, 10, ObjectType::Page,
              Page::"Interaction Templates", ManualSetupCategory::"Relationship Mgt", InteractionTemplatesKeywordsTxt);

            Sender.InsertManualSetup(SalutationsTitleTxt, SalutationsShortTitleTxt, SalutationsDescriptionTxt, 2, ObjectType::Page,
              Page::Salutations, ManualSetupCategory::"Relationship Mgt", SalutationsKeywordsTxt);

            Sender.InsertManualSetup(MailingGroupsTitleTxt, MailingGroupsShortTitleTxt, MailingGroupsDescriptionTxt, 3, ObjectType::Page,
              Page::"Mailing Groups", ManualSetupCategory::"Relationship Mgt", MailingGroupsKeywordsTxt);

            Sender.InsertManualSetup(SalesCyclesTitleTxt, SalesCyclesShortTitleTxt, SalesCyclesDescriptionTxt, 10, ObjectType::Page,
              Page::"Sales Cycles", ManualSetupCategory::"Relationship Mgt", SalesCyclesKeywordsTxt);

            Sender.InsertManualSetup(CloseOpportunityCodesTitleTxt, CloseOpportunityCodesShortTitleTxt, CloseOpportunityCodesDescriptionTxt, 2, ObjectType::Page,
              Page::"Close Opportunity Codes", ManualSetupCategory::"Relationship Mgt", CloseOpportunityCodesKeywordsTxt);

            Sender.InsertManualSetup(QuestionnaireSetupTitleTxt, QuestionnaireSetupShortTitleTxt, QuestionnaireSetupDescriptionTxt, 10, ObjectType::Page,
              Page::"Profile Questionnaires", ManualSetupCategory::"Relationship Mgt", QuestionnaireSetupKeywordsTxt);

            Sender.InsertManualSetup(ActivitiesTitleTxt, ActivitiesShortTitleTxt, ActivitiesDescriptionTxt, 2, ObjectType::Page,
              Page::"Activity List", ManualSetupCategory::"Relationship Mgt", ActivitiesKeywordsTxt);

            Sender.InsertManualSetup(MarketingSetupTitleTxt, MarketingSetupShortTitleTxt, MarketingSetupDescriptionTxt, 5, ObjectType::Page,
              Page::"Marketing Setup", ManualSetupCategory::"Relationship Mgt", MarketingSetupKeywordsTxt);

            Sender.InsertManualSetup(InteractionTemplateSetupTitleTxt, InteractionTemplateSetupShortTitleTxt, InteractionTemplateSetupDescriptionTxt, 10, ObjectType::Page,
              Page::"Interaction Template Setup", ManualSetupCategory::"Relationship Mgt", InteractionTemplateSetupKeywordsTxt);
        end;

        // Service
        if ApplicationAreaMgmtFacade.IsFoundationEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(OnlineMapSetupTitleTxt, OnlineMapSetupShortTitleTxt, OnlineMapSetupDescriptionTxt, 2, ObjectType::Page,
              Page::"Online Map Setup", ManualSetupCategory::Service, OnlineMapSetupKeywordsTxt);

        // Sales
        if ApplicationAreaMgmtFacade.IsFoundationEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(SalesReceivablesSetupTitleTxt, SalesReceivablesSetupShortTitleTxt, SalesReceivablesSetupDescriptionTxt, 15, ObjectType::Page,
              Page::"Sales & Receivables Setup", ManualSetupCategory::Sales, SalesReceivablesSetupKeywordsTxt);

        // Purchasing
        if ApplicationAreaMgmtFacade.IsFoundationEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then
            Sender.InsertManualSetup(PurchasePayablesSetupTitleTxt, PurchasePayablesSetupShortTitleTxt, PurchasePayablesSetupDescriptionTxt, 15, ObjectType::Page,
              Page::"Purchases & Payables Setup", ManualSetupCategory::Purchasing, PurchasePayablesSetupKeywordsTxt);

        // Intercompany
        if ApplicationAreaMgmtFacade.IsIntercompanyEnabled() or ApplicationAreaMgmtFacade.IsAllDisabled() then begin
            Sender.InsertManualSetup(
                ICSetupTitleTxt, ICSetupShortTitleTxt, ICSetupDescriptionTxt, 2, ObjectType::Page,
                Page::"Intercompany Setup", ManualSetupCategory::Intercompany, ICSetupKeywordsTxt);

            Sender.InsertManualSetup(ICPartnersTitleTxt, ICPartnersShortTitleTxt, ICPartnersDescriptionTxt, 5, ObjectType::Page,
              Page::"IC Partner List", ManualSetupCategory::Intercompany, ICPartnersKeywordsTxt);

            Sender.InsertManualSetup(ICChartOfAccountsTitleTxt, ICChartOfAccountsShortTitleTxt, ICChartOfAccountsDescriptionTxt, 10, ObjectType::Page,
              Page::"IC Chart of Accounts", ManualSetupCategory::Intercompany, ICChartOfAccountsKeywordsTxt);

            Sender.InsertManualSetup(ICDimensionsTitleTxt, ICDimensionsShortTitleTxt, ICDimensionsDescriptionTxt, 3, ObjectType::Page,
              Page::"IC Dimension List", ManualSetupCategory::Intercompany, ICDimensionsKeywordsTxt);
        end;
    end;
}

