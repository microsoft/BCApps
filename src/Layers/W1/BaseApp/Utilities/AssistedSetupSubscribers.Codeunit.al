// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.AccountantPortal;
using Microsoft.Bank.Setup;
using Microsoft.CashFlow.Forecast;
using Microsoft.System.Threading;
using Microsoft.CRM.Outlook;
using Microsoft.EServices.EDocument;
using Microsoft.Finance.Currency;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Projects.Timesheet;
using System.AI;
using System.Automation;
using System.Azure.Identity;
using System.Email;
using System.Environment;
using System.Environment.Configuration;
using System.ExternalFileStorage;
using System.Globalization;
using System.Integration;
using System.Integration.Excel;
using System.Media;
using System.Security.User;
using System.Apps;

codeunit 1814 "Assisted Setup Subscribers"
{

    var
        ApprovalWorkflowSetupTitleTxt: Label 'Set up approval workflows';
        ApprovalWorkflowSetupShortTitleTxt: Label 'Set up approval workflows', MaxLength = 50;
        ApprovalWorkflowSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115466', Locked = true;
        ApprovalWorkflowSetupDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user tries to create or change certain values, such as an amount above a specified limit.';
        EmailSetupTxt: Label 'Set up outgoing email';
        EmailSetupShortTxt: Label 'Outgoing email';
        EmailAccountSetupDescriptionTxt: Label 'Set up the email accounts your business will use to send out invoices and other documents. You can use a Microsoft 365 account or another provider.';
        OutlookAddinCentralizedSetupTitleTxt: Label 'Outlook Add-in Centralized Deployment';
        OutlookAddinCentralizedSetupShortTitleTxt: Label 'Outlook Add-in Centralized Deployment', MaxLength = 50;
        PowerAutomateEnvironmentTitleTxt: Label 'Power Automate Environment';
        PowerAutomateEnvironmentShortTitleTxt: Label 'Power Automate Environment', MaxLength = 50;
        PowerAutomateEnvironmentDescriptionTxt: Label 'Override the default setting and choose a specific Power Automate environment to be used by Business Central.';
        OutlookAddinCentralizedSetupDescriptionTxt: Label 'Deploy Outlook add-in for specific users, groups, or the entire organization.';
        TeamsAppCentralizedDeploymentTitleTxt: Label 'Teams App Centralized Deployment';
        TeamsAppCentralizedDeploymentShortTitleTxt: Label 'Teams App Centralized Deployment', MaxLength = 50;
        TeamsAppCentralizedDeploymentDescriptionTxt: Label 'Deploy the Business Central app for Teams for specific users, groups, or the entire organization.';
        CardSettingsTitleTxt: Label 'Card Settings';
        CardSettingsShortTitleTxt: Label 'Card Settings', MaxLength = 50;
        CardSettingsDescriptionTxt: Label 'Configure security settings that determine whether content is summarized and displayed directly on any compact card.';
        M365LicenseSetupTitleTxt: Label 'Access data with Microsoft 365 licenses';
        M365LicenseSetupTitleTxtShortTitleTxt: Label 'Access data with Microsoft 365 licenses', MaxLength = 50;
        M365LicenseSetupTitleTxtDescriptionTxt: Label 'Unlock data across your organization by setting up access to Business Central with Microsoft 365 licenses';
        ExcelAddinCentralizedDeploymentTitleTxt: Label 'Excel Add-in Centralized Deployment';
        ExcelAddinCentralizedDeploymentShortTitleTxt: Label 'Excel Add-in Centralized Deployment', MaxLength = 50;
        ExcelAddinCentralizedDeploymentDescriptionTxt: Label 'Deploy the Excel add-in for specific users, groups, or the entire organization.';
        OneDriveSetupTitleTxt: Label 'Connect your files to the cloud';
        OneDriveSetupShortTitleTxt: Label 'Co-author documents', MaxLength = 50;
        OneDriveSetupDescriptionTxt: Label 'Configure which features can work with OneDrive for Business to open files in the browser, share with others, or co-author online.';
        OneDriveSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2195963', Locked = true;
        ExtFileStorageSetupTitleTxt: Label 'Connect to external file accounts';
        ExtFileStorageSetupShortTitleTxt: Label 'Connect to external file accounts', MaxLength = 50;
        ExtFileStorageSetupDescriptionTxt: Label 'Configure external file accounts to be used in app scenarios, for export of data out of Business Central.';
        DataMigrationTitleTxt: Label 'Migrate business data';
        DataMigrationShortTitleTxt: Label 'Migrate data', MaxLength = 50;
        DataMigrationDescriptionTxt: Label 'Import existing data to Business Central from your former system.';
        SetupExchangeRatesTitleTxt: Label 'Set up exchange rates service';
        SetupExchangeRatesShortTitleTxt: Label 'Set up exchange rates', MaxLength = 50;
        SetupExchangeRatesHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115182', Locked = true;
        SetupExchangeRatesVideoTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2117931', Locked = true;
        SetupExchangeRatesDescriptionTxt: Label 'View or update currencies and exchange rates if you buy or sell in currencies other than your local currency or record G/L transactions in different currencies.';
        CustomizeDocumentLayoutsTitleTxt: Label 'Customize document layouts';
        CustomizeDocumentLayoutsShortTitleTxt: Label 'Customize document layouts', MaxLength = 50;
        CustomizeDocumentLayoutsHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115464', Locked = true;
        CustomizeDocumentLayoutsDescTxt: Label 'Make invoices and other documents look right for your business.';
        CustomerAppWorkflowTitleTxt: Label 'Set up a customer approval workflow';
        CustomerAppWorkflowShortTitleTxt: Label 'Set up customer approval workflow', MaxLength = 50;
        CustomerAppWorkflowDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user tries to create or change a customer.';
        ItemAppWorkflowTitleTxt: Label 'Set up an approval workflow to manage inventory items';
        ItemAppWorkflowShortTitleTxt: Label 'Set up an item approval workflow', MaxLength = 50;
        ItemAppWorkflowDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user tries to create or change an item.';
        PmtJnlAppWorkflowTitleTxt: Label 'Set up an approval workflow to manage payments';
        PmtJnlAppWorkflowShortTitleTxt: Label 'Set up a payment approval workflow', MaxLength = 50;
        PmtJnlAppWorkflowDescriptionTxt: Label 'Create approval workflows that automatically notify an approver when a user sends payment journal lines for approval.';
        VATSetupWizardShortTitleTxt: Label 'Set up VAT', MaxLength = 50;
        VATSetupWizardTitleTxt: Label 'Set up Value-Added Tax (VAT)';
        VATSetupWizardDescriptionTxt: Label 'Set up VAT to specify the rates to use to calculate tax amounts based on who you sell to, who you buy from, what you sell, and what you buy.';
        VATSetupWizardLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=850305', Locked = true;
        CashFlowForecastTitleTxt: Label 'Configure the Cash Flow Forecast chart';
        CashFlowForecastShortTitleTxt: Label 'Set up cash flow forecasting', MaxLength = 50;
        CashFlowForecastDescriptionTxt: Label 'Specify the accounts to use for the Cash Flow Forecast chart. The guide also helps you specify information about when you pay taxes, and whether to turn on Azure AI.';
        CRMConnectionSetupTitleTxt: Label 'Set up a connection to %1', Comment = '%1 = CRM product name';
        CRMConnectionSetupShortTitleTxt: Label 'Connect to %1', Comment = '%1 = CRM product name', MaxLength = 32;
        CRMConnectionSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115256', Locked = true;
        CRMConnectionSetupDescriptionTxt: Label 'Connect your Dynamics 365 services for better insights. Data is exchanged between the apps for better productivity.';
        CDSConnectionSetupTitleTxt: Label 'Set up a connection to Dataverse';
        CDSConnectionSetupShortTitleTxt: Label 'Connect to Dataverse', MaxLength = 50;
        CDSConnectionSetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115257', Locked = true;
        CDSConnectionSetupDescriptionTxt: Label 'Connect to Dataverse for better insights across business applications. Data will flow between the apps for better productivity.', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated';
        AzureAdSetupTitleTxt: Label 'Set up your Microsoft Entra ID accounts';
        AzureAdSetupShortTitleTxt: Label 'Set up Microsoft Entra ID', MaxLength = 50;
        AzureAdSetupDescriptionTxt: Label 'Register an Microsoft Entra app so that you can use Power BI, Power Automate, Exchange, and other Azure services from on-premises.';
        HelpSetupCashFlowForecastTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828693', Locked = true;
        HelpSetupEmailTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828689', Locked = true;
        HelpImportbusinessdataTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828687', Locked = true;
        VideoWorkwithextensionsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828686', Locked = true;
        VideoWorkwithExcelTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828685', Locked = true;
        VideoWorkwithPowerBITxt: Label 'https://go.microsoft.com/fwlink/?linkid=828684', Locked = true;
        VideoRunyourbusinesswithOffice365Txt: Label 'https://go.microsoft.com/fwlink/?linkid=828683', Locked = true;
        VideoWorkwithgeneraljournalsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828682', Locked = true;
        VideoIntrotoDynamics365forFinancialsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828681', Locked = true;
        VideoAzureAIforFinancialsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828680', Locked = true;
        VideoImportbusinessdataTxt: Label 'https://go.microsoft.com/fwlink/?linkid=828660', Locked = true;
        HelpSetupOutlookCentralizedDeploymentTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2170959', Locked = true;
        HelpPowerAutomateEnvironmentTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2224167', Locked = true;
        HelpSetupTeamsCentralizedDeploymentTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2170851', Locked = true;
        HelpSetupM365LicenseTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2209653', Locked = true;
        HelpSetupExcelCentralizedDeploymentTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2163968', Locked = true;
        HelpCardSettingsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2219744', Locked = true;
        HelpWorkwithPowerBINameTxt: Label 'Work with Power BI';
        VideoWorkwithextensionsNameTxt: Label 'Install extensions to add features and integrations';
        VideoWorkwithExcelNameTxt: Label 'Work with Excel';
        VideoWorkwithgeneraljournalsNameTxt: Label 'Work with general journals';
        VideoIntrotoDynamics365forFinancialsNameTxt: Label 'Learn about Dynamics 365';
        VideoAzureAIforFinancialsNameTxt: Label 'Azure AI with Dynamics 365';
        VideoUrlSetupCRMConnectionTxt: Label '', Locked = true;
        VideoUrlSetupApprovalsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843246', Locked = true;
        CreateJobTxt: Label 'Create a project';
        VideoUrlCreateJobTxt: Label 'https://go.microsoft.com/fwlink/?linkid=843363', Locked = true;
        InviteExternalAccountantTitleTxt: Label 'Invite your external accountant to the company';
        InviteExternalAccountantShortTitleTxt: Label 'Invite your external accountant', MaxLength = 50;
        InviteExternalAccountantHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2114063', Locked = true;
        InviteExternalAccountantDescTxt: Label 'Send a link to your external accountant so that they can access your Business Central and manage your books from a dedicated home page.';
        SetupPaymentServicesTitleTxt: Label 'Connect to a payment service';
        SetupPaymentServicesShortTitleTxt: Label 'Set up payment services', MaxLength = 50;
        SetupPaymentServicesHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115183', Locked = true;
        SetupPaymentServicesDescriptionTxt: Label 'Connect to a payment service so that your customers can pay you electronically.';
#if not CLEAN25
        SetupConsolidationReportingTitleTxt: Label 'Process Consolidations';
        SetupConsolidationReportingShortTitleTxt: Label 'Consolidate companies', MaxLength = 50;
        SetupConsolidationReportingDescriptionTxt: Label 'Consolidate the general ledger entries of two or more separate companies (subsidiaries) into a consolidated company.';
#endif
        AccessAllFeaturesTxt: Label 'Access all features';
        VideoAccessAllFeaturesTxt: Label 'https://go.microsoft.com/fwlink/?linkid=857610', Locked = true;
        AnalyzeDataUsingAccSchedulesTxt: Label 'Analyze data using account schedules';
        VideoAnalyzeDataUsingAccSchedulesTxt: Label 'https://go.microsoft.com/fwlink/?linkid=857611', Locked = true;
        WorkWithLocAndTransfOrdTxt: Label 'Work with locations and transfer orders';
        VideoWorkWithLocAndTransfOrdTxt: Label 'https://go.microsoft.com/fwlink/?linkid=857612', Locked = true;
        WorkWithPostingGroupsTxt: Label 'Work with posting groups';
        VideoWorkWithPostingGroupsTxt: Label 'https://go.microsoft.com/fwlink/?linkid=857613', Locked = true;
        WorkWithVatTxt: Label 'Work with VAT';
        VideoWorkWithVatTxt: Label 'https://go.microsoft.com/fwlink/?linkid=857614', Locked = true;
        IntroductionTxt: Label 'Introduction';
        VideoUrlIntroductionTxt: Label 'https://go.microsoft.com/fwlink/?linkid=867632', Locked = true;
        GettingStartedTxt: Label 'Getting Started';
        VideoUrlGettingStartedTxt: Label 'https://go.microsoft.com/fwlink/?linkid=867634', Locked = true;
        AdditionalReourcesTxt: Label 'Additional Resources';
        VideoUrlAdditionalReourcesTxt: Label 'https://go.microsoft.com/fwlink/?linkid=867635', Locked = true;
        CompanyAlreadySetUpQst: Label 'This company is already set up. To change settings for it, go to the Company Information page.\\Go there now?';
        EmailAlreadySetUpQst: Label 'One or more email accounts are already set up. To change settings for email, go to the Email Accounts page.\\Go there now?';
        Info: ModuleInfo;
        UpdateUsersFromOfficeTitleTxt: Label 'Fetch users from Microsoft 365';
        UpdateUsersFromOfficeShortTitleTxt: Label 'Update users', MaxLength = 50;
        UpdateUsersFromOfficeDescriptionTxt: Label 'Get the latest information about users and licenses for Business Central from Microsoft 365.';
        SetupTimeSheetsTitleTxt: Label 'Set Up Time Sheets';
        SetupTimeSheetsShortTitleTxt: Label 'Set up Time Sheets', MaxLength = 50;
        SetupTimeSheetsHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2166666';
        SetupTimeSheetsDescriptionTxt: Label 'Track the time used on projects, register absences, or create simple time registrations for team members on any device.';
        SetupCopilotAICapabilitiesTitleTxt: Label 'Set up Copilot & agent capabilities';
        SetupCopilotAICapabilitiesShortTitleTxt: Label 'Set up Copilot & agent capabilities', MaxLength = 50;
        SetupCopilotAICapabilitiesDescriptionTxt: Label 'Set up Copilot & agent capabilities to unlock AI-powered experiences.';
        SetupCopilotAICapabilitiesHelpTxt: Label 'https://aka.ms/bcai', Locked = true;
        SetupJobQueueNotificationTitleTxt: Label 'Set up Job Queue Notifications';
        SetupJobQueueNotificationShortTitleTxt: Label 'Set up Job Queue Notifications', MaxLength = 50;
        SetupJobQueueNotificationDescriptionTxt: Label 'Set up Job Queue Notifications to receive notifications when jobs are failed.';
        SetupJobQueueNotificationHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2282396', Locked = true;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnRegisterAssistedSetup', '', false, false)]
    local procedure Initialize()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        CRMProductName: Codeunit "CRM Product Name";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        AssistedCompanySetup: Codeunit "Assisted Company Setup";
        GuidedExperience: Codeunit "Guided Experience";
        Language: Codeunit Language;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        GuidedExperienceType: Enum "Guided Experience Type";
        CurrentGlobalLanguage: Integer;
    begin
        CurrentGlobalLanguage := GlobalLanguage;
        // Getting Started
        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then
            AssistedCompanySetup.AddAssistedCompanySetup();

        GuidedExperience.InsertAssistedSetup(SetupCopilotAICapabilitiesTitleTxt, SetupCopilotAICapabilitiesShortTitleTxt, SetupCopilotAICapabilitiesDescriptionTxt, 5, ObjectType::Page,
            Page::"Copilot AI Capabilities", AssistedSetupGroup::GettingStarted, '', VideoCategory::GettingStarted, SetupCopilotAICapabilitiesHelpTxt);

        GuidedExperience.InsertAssistedSetup(VATSetupWizardTitleTxt, VATSetupWizardShortTitleTxt, VATSetupWizardDescriptionTxt, 15,
            ObjectType::Page, Page::"VAT Setup Wizard", AssistedSetupGroup::GettingStarted, '', VideoCategory::GettingStarted, VATSetupWizardLinkTxt);
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"VAT Setup Wizard", Language.GetDefaultApplicationLanguageId(), VATSetupWizardTitleTxt);
        GlobalLanguage(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(UpdateUsersFromOfficeTitleTxt, UpdateUsersFromOfficeShortTitleTxt, UpdateUsersFromOfficeDescriptionTxt, 5, ObjectType::Page,
            Page::"Azure AD User Update Wizard", AssistedSetupGroup::GettingStarted, '', VideoCategory::Uncategorized, '');
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Azure AD User Update Wizard", Language.GetDefaultApplicationLanguageId(), UpdateUsersFromOfficeTitleTxt);
        GlobalLanguage(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(DataMigrationTitleTxt, DataMigrationShortTitleTxt, DataMigrationDescriptionTxt, 15, ObjectType::Page,
            Page::"Data Migration Wizard", AssistedSetupGroup::ReadyForBusiness, VideoImportbusinessdataTxt, VideoCategory::ReadyForBusiness, HelpImportbusinessdataTxt);
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Data Migration Wizard", Language.GetDefaultApplicationLanguageId(), DataMigrationTitleTxt);
        GlobalLanguage(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(SetupExchangeRatesTitleTxt, SetupExchangeRatesShortTitleTxt, SetupExchangeRatesDescriptionTxt, 10, ObjectType::Page,
            Page::"Curr. Exch. Rate Service List", AssistedSetupGroup::GettingStarted, SetupExchangeRatesVideoTxt, VideoCategory::GettingStarted, SetupExchangeRatesHelpTxt);
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Curr. Exch. Rate Service List", Language.GetDefaultApplicationLanguageId(), SetupExchangeRatesTitleTxt);
        GlobalLanguage(CurrentGlobalLanguage);
        GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Outlook Individual Deployment");


        GuidedExperience.InsertAssistedSetup(OutlookAddinCentralizedSetupTitleTxt, OutlookAddinCentralizedSetupShortTitleTxt, OutlookAddinCentralizedSetupDescriptionTxt, 5, ObjectType::Page,
            Page::"Outlook Centralized Deployment", AssistedSetupGroup::DoMoreWithBC, VideoRunyourbusinesswithOffice365Txt, VideoCategory::DoMoreWithBC, HelpSetupOutlookCentralizedDeploymentTxt);
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Outlook Centralized Deployment", Language.GetDefaultApplicationLanguageId(), OutlookAddinCentralizedSetupTitleTxt);
        GlobalLanguage(CurrentGlobalLanguage);

        if EnvironmentInfo.IsSaaS() then begin
            GuidedExperience.InsertAssistedSetup(PowerAutomateEnvironmentTitleTxt, PowerAutomateEnvironmentShortTitleTxt, PowerAutomateEnvironmentDescriptionTxt, 5, ObjectType::Page,
                Page::"Automate Environment Picker", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, HelpPowerAutomateEnvironmentTxt);
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                Page::"Automate Environment Picker", Language.GetDefaultApplicationLanguageId(), PowerAutomateEnvironmentTitleTxt);
            GlobalLanguage(CurrentGlobalLanguage);

            GuidedExperience.InsertAssistedSetup(TeamsAppCentralizedDeploymentTitleTxt, TeamsAppCentralizedDeploymentShortTitleTxt, TeamsAppCentralizedDeploymentDescriptionTxt, 5, ObjectType::Page,
                Page::"Teams Centralized Deployment", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, HelpSetupTeamsCentralizedDeploymentTxt);
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                Page::"Teams Centralized Deployment", Language.GetDefaultApplicationLanguageId(), TeamsAppCentralizedDeploymentTitleTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);

            GuidedExperience.InsertAssistedSetup(CardSettingsTitleTxt, CardSettingsShortTitleTxt, CardSettingsDescriptionTxt, 5, ObjectType::Page,
                Page::"Page Summary Settings", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, HelpCardSettingsTxt);
            GLOBALLANGUAGE(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                PAGE::"Page Summary Settings", Language.GetDefaultApplicationLanguageId(), CardSettingsTitleTxt);
            GLOBALLANGUAGE(CurrentGlobalLanguage);
        end;
        GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"Teams Individual Deployment");

        if EnvironmentInfo.IsSaaS() then begin
            GuidedExperience.InsertAssistedSetup(M365LicenseSetupTitleTxt, M365LicenseSetupTitleTxtShortTitleTxt, M365LicenseSetupTitleTxtDescriptionTxt, 10, ObjectType::Page,
                Page::"MS 365 License Setup Wizard", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, HelpSetupM365LicenseTxt);
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                Page::"MS 365 License Setup Wizard", Language.GetDefaultApplicationLanguageId(), M365LicenseSetupTitleTxt);
            GlobalLanguage(CurrentGlobalLanguage);
        end;

        GuidedExperience.InsertAssistedSetup(ExcelAddinCentralizedDeploymentTitleTxt, ExcelAddinCentralizedDeploymentShortTitleTxt, ExcelAddinCentralizedDeploymentDescriptionTxt, 5, ObjectType::Page,
            Page::"Excel Centralized Depl. Wizard", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, HelpSetupExcelCentralizedDeploymentTxt);
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Excel Centralized Depl. Wizard", Language.GetDefaultApplicationLanguageId(), ExcelAddinCentralizedDeploymentTitleTxt);
        GlobalLanguage(CurrentGlobalLanguage);

        // Analysis
        GuidedExperience.InsertAssistedSetup(CashFlowForecastTitleTxt, CashFlowForecastShortTitleTxt, CashFlowForecastDescriptionTxt, 5, ObjectType::Page,
            Page::"Cash Flow Forecast Wizard", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, HelpSetupCashFlowForecastTxt);
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Cash Flow Forecast Wizard", Language.GetDefaultApplicationLanguageId(), CashFlowForecastTitleTxt);
        GlobalLanguage(CurrentGlobalLanguage);

        // Customize for your need
        InitializeCustomize();

        GuidedExperience.Remove(GuidedExperienceType::"Assisted Setup", ObjectType::Page, Page::"OData Setup Wizard");

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(ItemAppWorkflowTitleTxt, ItemAppWorkflowShortTitleTxt, ItemAppWorkflowDescriptionTxt, 3, ObjectType::Page,
                Page::"Item Approval WF Setup Wizard", AssistedSetupGroup::ApprovalWorkflows, '', VideoCategory::ApprovalWorkflows, '');
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                Page::"Item Approval WF Setup Wizard", Language.GetDefaultApplicationLanguageId(), ItemAppWorkflowTitleTxt);
            GlobalLanguage(CurrentGlobalLanguage);
        end;

        if not EnvironmentInfo.IsSaaSInfrastructure() then begin
            GuidedExperience.InsertAssistedSetup(AzureAdSetupTitleTxt, AzureAdSetupShortTitleTxt, AzureAdSetupDescriptionTxt, 5, ObjectType::Page,
                Page::"Azure AD App Setup Wizard", AssistedSetupGroup::Connect, '', VideoCategory::Uncategorized, '');
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                Page::"Azure AD App Setup Wizard", Language.GetDefaultApplicationLanguageId(), AzureAdSetupTitleTxt);
            GlobalLanguage(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(PmtJnlAppWorkflowTitleTxt, PmtJnlAppWorkflowShortTitleTxt, PmtJnlAppWorkflowDescriptionTxt, 3, ObjectType::Page,
                Page::"Pmt. App. Workflow Setup Wzrd.", AssistedSetupGroup::ApprovalWorkflows, '', VideoCategory::ApprovalWorkflows, '');
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                Page::"Pmt. App. Workflow Setup Wzrd.", Language.GetDefaultApplicationLanguageId(), PmtJnlAppWorkflowTitleTxt);
            GlobalLanguage(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(CDSConnectionSetupTitleTxt, CDSConnectionSetupShortTitleTxt, CDSConnectionSetupDescriptionTxt, 10, ObjectType::Page,
                Page::"CDS Connection Setup Wizard", AssistedSetupGroup::Connect, '', VideoCategory::Connect, CDSConnectionSetupHelpTxt);
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                Page::"CDS Connection Setup Wizard", Language.GetDefaultApplicationLanguageId(), CDSConnectionSetupTitleTxt);
            GlobalLanguage(CurrentGlobalLanguage);
        end;

        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(STRSUBSTNO(CRMConnectionSetupTitleTxt, CRMProductName.SHORT()),
                STRSUBSTNO(CRMConnectionSetupShortTitleTxt, CRMProductName.SHORT()), CRMConnectionSetupDescriptionTxt, 10, ObjectType::Page,
                Page::"CRM Connection Setup Wizard", AssistedSetupGroup::Connect, VideoUrlSetupCRMConnectionTxt, VideoCategory::Connect, CRMConnectionSetupHelpTxt);
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                Page::"CRM Connection Setup Wizard", Language.GetDefaultApplicationLanguageId(), STRSUBSTNO(CRMConnectionSetupTitleTxt, CRMProductName.SHORT()));
            GlobalLanguage(CurrentGlobalLanguage);
        end;

        GuidedExperience.InsertAssistedSetup(OneDriveSetupTitleTxt, OneDriveSetupShortTitleTxt, OneDriveSetupDescriptionTxt, 5, ObjectType::Page,
            Page::"Document Service Setup", AssistedSetupGroup::Connect, '', VideoCategory::Connect, OneDriveSetupHelpTxt);
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Document Service Setup", Language.GetDefaultApplicationLanguageId(), OneDriveSetupTitleTxt);
        GlobalLanguage(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(ExtFileStorageSetupTitleTxt, ExtFileStorageSetupShortTitleTxt, ExtFileStorageSetupDescriptionTxt, 5, ObjectType::Page,
            Page::"File Account Wizard", AssistedSetupGroup::Connect, '', VideoCategory::Connect, '');
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"File Account Wizard", Language.GetDefaultApplicationLanguageId(), ExtFileStorageSetupTitleTxt);
        GlobalLanguage(CurrentGlobalLanguage);

        if EnvironmentInfo.IsSaaS() then begin
            GuidedExperience.InsertAssistedSetup(InviteExternalAccountantTitleTxt, InviteExternalAccountantShortTitleTxt, InviteExternalAccountantDescTxt, 5, ObjectType::Page,
                Page::"Invite External Accountant", AssistedSetupGroup::ReadyForBusiness, '', VideoCategory::ReadyForBusiness, InviteExternalAccountantHelpTxt);
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                Page::"Invite External Accountant", Language.GetDefaultApplicationLanguageId(), InviteExternalAccountantTitleTxt);
            GlobalLanguage(CurrentGlobalLanguage);
        end;

        GuidedExperience.InsertAssistedSetup(SetupPaymentServicesTitleTxt, SetupPaymentServicesShortTitleTxt, SetupPaymentServicesDescriptionTxt, 5, ObjectType::Page,
            Page::"Payment Services", AssistedSetupGroup::ReadyForBusiness, '', VideoCategory::ReadyForBusiness, SetupPaymentServicesHelpTxt);
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Payment Services", Language.GetDefaultApplicationLanguageId(), SetupPaymentServicesTitleTxt);
#if not CLEAN25
        GlobalLanguage(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(SetupConsolidationReportingTitleTxt, SetupConsolidationReportingShortTitleTxt, SetupConsolidationReportingDescriptionTxt, 5, ObjectType::Page,
            Page::"Company Consolidation Wizard", AssistedSetupGroup::FinancialReporting, '', VideoCategory::Uncategorized, '');
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Company Consolidation Wizard", Language.GetDefaultApplicationLanguageId(), SetupConsolidationReportingTitleTxt);
#endif
        GlobalLanguage(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(SetupJobQueueNotificationTitleTxt, SetupJobQueueNotificationShortTitleTxt, SetupJobQueueNotificationDescriptionTxt, 5, ObjectType::Page,
            Page::"Job Queue Notification Wizard", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, SetupJobQueueNotificationHelpTxt);
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Job Queue Notification Wizard", Language.GetDefaultApplicationLanguageId(), SetupJobQueueNotificationTitleTxt);
        GlobalLanguage(CurrentGlobalLanguage);

        UpdateStatus();
    end;

    local procedure InitializeCustomize()
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        GuidedExperience: Codeunit "Guided Experience";
        Language: Codeunit Language;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        GuidedExperienceType: Enum "Guided Experience Type";
        CurrentGlobalLanguage: Integer;
    begin
        CurrentGlobalLanguage := GlobalLanguage;
        if not ApplicationAreaMgmtFacade.IsBasicOnlyEnabled() then begin
            GuidedExperience.InsertAssistedSetup(ApprovalWorkflowSetupTitleTxt, ApprovalWorkflowSetupShortTitleTxt, ApprovalWorkflowSetupDescriptionTxt, 3, ObjectType::Page,
                Page::"Approval Workflow Setup Wizard", AssistedSetupGroup::ApprovalWorkflows, VideoUrlSetupApprovalsTxt, VideoCategory::ApprovalWorkflows, ApprovalWorkflowSetupHelpTxt);
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                Page::"Approval Workflow Setup Wizard", Language.GetDefaultApplicationLanguageId(), ApprovalWorkflowSetupTitleTxt);
            GlobalLanguage(CurrentGlobalLanguage);

            GuidedExperience.InsertAssistedSetup(CustomerAppWorkflowTitleTxt, CustomerAppWorkflowShortTitleTxt, CustomerAppWorkflowDescriptionTxt, 5, ObjectType::Page,
                Page::"Cust. Approval WF Setup Wizard", AssistedSetupGroup::ApprovalWorkflows, '', VideoCategory::ApprovalWorkflows, '');
            GlobalLanguage(Language.GetDefaultApplicationLanguageId());
            GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
                Page::"Cust. Approval WF Setup Wizard", Language.GetDefaultApplicationLanguageId(), CustomerAppWorkflowTitleTxt);
            GlobalLanguage(CurrentGlobalLanguage);
        end;

        GuidedExperience.InsertAssistedSetup(EmailSetupTxt, CopyStr(EmailSetupShortTxt, 1, 50), EmailAccountSetupDescriptionTxt, 5, ObjectType::Page,
            Page::"Email Account Wizard", AssistedSetupGroup::FirstInvoice, '', VideoCategory::FirstInvoice, HelpSetupEmailTxt);
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Email Account Wizard", Language.GetDefaultApplicationLanguageId(), EmailSetupTxt);
        GlobalLanguage(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(SetupTimeSheetsTitleTxt, SetupTimeSheetsShortTitleTxt, SetupTimeSheetsDescriptionTxt, 10, ObjectType::Page,
            Page::"Time Sheet Setup Wizard", AssistedSetupGroup::DoMoreWithBC, '', VideoCategory::DoMoreWithBC, SetupTimeSheetsHelpTxt);
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Time Sheet Setup Wizard", Language.GetDefaultApplicationLanguageId(), SetupTimeSheetsTitleTxt);
        GlobalLanguage(CurrentGlobalLanguage);

        GuidedExperience.InsertAssistedSetup(CustomizeDocumentLayoutsTitleTxt, CustomizeDocumentLayoutsShortTitleTxt, CustomizeDocumentLayoutsDescTxt, 10, ObjectType::Page,
            Page::"Custom Report Layouts", AssistedSetupGroup::FirstInvoice, '', VideoCategory::FirstInvoice, CustomizeDocumentLayoutsHelpTxt);
        GlobalLanguage(Language.GetDefaultApplicationLanguageId());
        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Custom Report Layouts", Language.GetDefaultApplicationLanguageId(), CustomizeDocumentLayoutsTitleTxt);
        GlobalLanguage(CurrentGlobalLanguage);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnReRunOfCompletedAssistedSetup', '', false, false)]
    local procedure OnReRunOfCompletedSetup(ExtensionId: Guid; ObjectType: ObjectType; ObjectID: Integer; var Handled: Boolean)
    begin
        if ExtensionId <> GetAppId() then
            exit;
        case ObjectID of
            Page::"Assisted Company Setup Wizard":
                begin
                    if Confirm(CompanyAlreadySetUpQst, true) then
                        Page.Run(Page::"Company Information");

                    Handled := true;
                end;
            Page::"Email Account Wizard":
                begin
                    if not EmailAccountIsSetup() then
                        exit;

                    if Confirm(EmailAlreadySetUpQst, true) then
                        Page.Run(Page::"Email Accounts");

                    Handled := true;
                end;
        end;
    end;

    local procedure GetAppId(): Guid
    var
        EmptyGuid: Guid;
    begin
        if Info.Id() = EmptyGuid then
            NavApp.GetCurrentModuleInfo(Info);
        exit(Info.Id());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::Video, 'OnRegisterVideo', '', false, false)]
    local procedure OnRegisterVideo(sender: Codeunit Video)
    var
        EnvironmentInfo: Codeunit "Environment Information";
        VideoCategory: Enum "Video Category";
    begin

        sender.Register(GetAppId(), VideoIntrotoDynamics365forFinancialsNameTxt, VideoIntrotoDynamics365forFinancialsTxt, VideoCategory::GettingStarted);
        sender.Register(GetAppId(), IntroductionTxt, VideoUrlIntroductionTxt, VideoCategory::GettingStarted);
        sender.Register(GetAppId(), GettingStartedTxt, VideoUrlGettingStartedTxt, VideoCategory::GettingStarted);
        sender.Register(GetAppId(), AdditionalReourcesTxt, VideoUrlAdditionalReourcesTxt, VideoCategory::GettingStarted);
        sender.Register(GetAppId(), AccessAllFeaturesTxt, VideoAccessAllFeaturesTxt, VideoCategory::GettingStarted);

        if EnvironmentInfo.IsSaaS() then
            sender.Register(GetAppId(), CreateJobTxt, VideoUrlCreateJobTxt, VideoCategory::GettingStarted);

        // Warehouse Management
        sender.Register(GetAppId(), WorkWithLocAndTransfOrdTxt, VideoWorkWithLocAndTransfOrdTxt, VideoCategory::Warehouse);

        // Journals
        sender.Register(GetAppId(), VideoWorkwithgeneraljournalsNameTxt, VideoWorkwithgeneraljournalsTxt, VideoCategory::Journals);
        sender.Register(GetAppId(), WorkWithPostingGroupsTxt, VideoWorkWithPostingGroupsTxt, VideoCategory::Journals);
        sender.Register(GetAppId(), WorkWithVatTxt, VideoWorkWithVatTxt, VideoCategory::Journals);

        sender.Register(GetAppId(), VideoAzureAIforFinancialsNameTxt, VideoAzureAIforFinancialsTxt, VideoCategory::Analysis);
        sender.Register(GetAppId(), VideoWorkwithExcelNameTxt, VideoWorkwithExcelTxt, VideoCategory::Analysis);
        sender.Register(GetAppId(), HelpWorkwithPowerBINameTxt, VideoWorkwithPowerBITxt, VideoCategory::Analysis);
        sender.Register(GetAppId(), AnalyzeDataUsingAccSchedulesTxt, VideoAnalyzeDataUsingAccSchedulesTxt, VideoCategory::Analysis);

        sender.Register(GetAppId(), VideoWorkwithextensionsNameTxt, VideoWorkwithextensionsTxt, VideoCategory::Extensions);
    end;

    local procedure UpdateStatus()
    begin
        UpdateSetUpEmail();
        UpdateSetUpApprovalWorkflow();
    end;

    local procedure UpdateSetUpEmail()
    var
        EmailAccount: Codeunit "Email Account";
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if not EmailAccount.IsAnyAccountRegistered() then
            exit;
        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Email Account Wizard");
    end;

    local procedure UpdateSetUpApprovalWorkflow()
    var
        ApprovalUserSetup: Record "User Setup";
        GuidedExperience: Codeunit "Guided Experience";
    begin
        ApprovalUserSetup.SetFilter("Approver ID", '<>%1', '');
        if ApprovalUserSetup.IsEmpty() then
            exit;

        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Approval Workflow Setup Wizard");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Guided Experience", 'OnAfterRunAssistedSetup', '', false, false)]
    local procedure CompleteEmailAssistedSetup(ExtensionID: Guid; ObjectType: ObjectType; ObjectID: Integer)
    var
        GuidedExperience: Codeunit "Guided Experience";
    begin
        if ObjectID <> Page::"Email Account Wizard" then
            exit;

        if not EmailAccountIsSetup() then
            exit;

        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Email Account Wizard");
    end;

    local procedure EmailAccountIsSetup(): Boolean
    var
        EmailAccount: Codeunit "Email Account";
    begin
        exit(EmailAccount.IsAnyAccountRegistered());
    end;
}
