// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Period;
using System.Environment.Configuration;
using System.IO;
using System.Threading;
using System.Environment;
using System.Media;
using System.Globalization;
using System;

#pragma warning disable AS0018, AS0025
codeunit 1800 "Assisted Company Setup"
{
    Permissions = tabledata "Assisted Company Setup Status" = r,
                  tabledata "G/L Entry" = r;
    InherentPermissions = X;
    InherentEntitlements = X;

    trigger OnRun()
    begin
    end;

    var
        EnableWizardErr: Label 'You cannot enable the assisted company setup for an already active company.';
        NoConfigPackageFileMsg: Label 'There are no configuration package files defined in your system. Assisted company setup will not be fully functional. Please contact your system administrator.';
        CreatingCompanyMsg: Label 'Creating company...';
        NoPermissionsErr: Label 'You do not have permissions to create a new company. Contact your system administrator.';
        InitialCompanySetupTxt: Label 'Enter company details';
        InitialCompanySetupShortTitleTxt: Label 'Company details';
        InitialCompanySetupHelpTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2115383', Locked = true;
        InitialCompanySetupDescTxt: Label 'Provide your company''s name, address, logo, and other basic information.';

    local procedure EnableAssistedCompanySetup(SetupCompanyName: Text[30]; AssistedSetupEnabled: Boolean)
    var
        GLEntry: Record "G/L Entry";
        ConfigurationPackageFile: Record "Configuration Package File";
    begin
        if AssistedSetupEnabled then begin
            GLEntry.ChangeCompany(SetupCompanyName);
            if not GLEntry.IsEmpty() then
                Error(EnableWizardErr);
            if ConfigurationPackageFile.IsEmpty() then
                Message(NoConfigPackageFileMsg);
        end;
    end;

    local procedure RunAssistedCompanySetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        GuidedExperienceType: Enum "Guided Experience Type";
    begin
        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;

        if not GuiAllowed then
            exit;

        if CompanyActive() then
            exit;

        if not AssistedSetupEnabled() then
            exit;

        if GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Assisted Company Setup Wizard") then
            exit;

        Commit(); // Make sure all data is committed before we run the wizard

        GuidedExperience.Run(GuidedExperienceType::"Assisted Setup", ObjectType::Page, PAGE::"Assisted Company Setup Wizard");
    end;

    procedure ApplyUserInput(var TempConfigSetup: Record "Config. Setup" temporary; var BankAccount: Record "Bank Account"; AccountingPeriodStartDate: Date; SkipSetupCompanyInfo: Boolean)
    begin
        if not SkipSetupCompanyInfo then
            TempConfigSetup.CopyCompInfo();
        CreateAccountingPeriod(AccountingPeriodStartDate);
        SetupCompanyBankAccount(BankAccount);
    end;

    procedure CreateAccountingPeriod(StartDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
        CreateFiscalYear: Report "Create Fiscal Year";
        DateFormulaVariable: DateFormula;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateAccountingPeriod(StartDate, IsHandled);
        if IsHandled then
            exit;

        // The wizard should only setup accounting periods, if non exist.
        if (not AccountingPeriod.IsEmpty) or (StartDate = 0D) then
            exit;

        Evaluate(DateFormulaVariable, '<1M>');
        CreateFiscalYear.InitializeRequest(12, DateFormulaVariable, StartDate);
        CreateFiscalYear.UseRequestPage(false);
        CreateFiscalYear.HideConfirmationDialog(true);
        CreateFiscalYear.RunModal();
    end;

    local procedure SetupCompanyBankAccount(var BankAccount: Record "Bank Account")
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        CompanyInformation.Get();
        CompanyInformationMgt.UpdateCompanyBankAccount(CompanyInformation, '', BankAccount);
    end;

    local procedure AssistedSetupEnabled(): Boolean
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        exit(AssistedCompanySetupStatus.Get(CompanyName) and AssistedCompanySetupStatus.Enabled);
    end;

    local procedure CompanyActive(): Boolean
    var
        GLEntry: Record "G/L Entry";
    begin
        if not GLEntry.ReadPermission then
            exit(true);

        exit(not GLEntry.IsEmpty);
    end;

    local procedure FindJobQueueLogEntries(Name: Text[30]; var JobQueueLogEntry: Record "Job Queue Log Entry"): Boolean
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        if not AssistedCompanySetupStatus.Get(Name) then
            exit(false);
        if IsNullGuid(AssistedCompanySetupStatus."Task ID") then
            exit(false);
        JobQueueLogEntry.SetRange(ID, AssistedCompanySetupStatus."Task ID");
        exit(JobQueueLogEntry.FindLast());
    end;

    local procedure GetCompanySetupStatus(Name: Text[30]): Enum "Company Setup Status"
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        if AssistedCompanySetupStatus.Get(Name) then
            if IsNullGuid(AssistedCompanySetupStatus."Task ID") then
                exit(Enum::"Company Setup Status"::Completed);

        if not JobQueueLogEntry.ChangeCompany(Name) then
            exit(Enum::"Company Setup Status"::"Missing Permission");

        if not JobQueueLogEntry.ReadPermission then
            exit(Enum::"Company Setup Status"::"Missing Permission");

        if IsCompanySetupInProgress(Name) then
            exit(Enum::"Company Setup Status"::"In Progress");

        if FindJobQueueLogEntries(Name, JobQueueLogEntry) then
            exit(Enum::"Company Setup Status".FromInteger(JobQueueLogEntry.Status + 1));

        exit(Enum::"Company Setup Status"::" ");
    end;

    procedure IsCompanySetupInProgress(NewCompanyName: Text): Boolean
    var
        ActiveSession: Record "Active Session";
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        if AssistedCompanySetupStatus.Get(NewCompanyName) then
            if AssistedCompanySetupStatus."Company Setup Session ID" <> 0 then
                exit(ActiveSession.Get(AssistedCompanySetupStatus."Server Instance ID", AssistedCompanySetupStatus."Company Setup Session ID"));
    end;

    local procedure SetApplicationArea(NewCompanyName: Text[30])
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        ExperienceTierSetup."Company Name" := NewCompanyName;
        ExperienceTierSetup.Essential := true;
        ExperienceTierSetup.Insert();

        ApplicationAreaMgmt.SetExperienceTierOtherCompany(ExperienceTierSetup, NewCompanyName);
    end;

    procedure SetupCompanyWithoutDemodata(NewCompanyName: Text[30]; NewCompanyData: Enum "Company Demo Data Type")
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
    begin
        SetApplicationArea(NewCompanyName);

        AssistedCompanySetupStatus.SetEnabled(NewCompanyName, false, false);

        OnAfterAssistedCompanySetupStatusEnabled(NewCompanyName);

        if NewCompanyData in [NewCompanyData::"Evaluation - Contoso Sample Data"] then
            DataClassificationEvalData.CreateEvaluationData();
    end;

    procedure SetUpNewCompany(NewCompanyName: Text[30]; NewCompanyData: Enum "Company Demo Data Type")
    var
        CompanyCreationDemoData: codeunit "Company Creation Demo Data";
    begin
        SetupCompanyWithoutDemodata(NewCompanyName, NewCompanyData);

        if NewCompanyData in [NewCompanyData::"Production - Setup Data Only", NewCompanyData::"Evaluation - Contoso Sample Data"] then
            if CompanyCreationDemoData.CheckAndPromptUserToInstallContosoRequiredApps() then
                OnSetupNewCompanyWithDemoData(NewCompanyName, NewCompanyData)
            else
                error('Could not run demo data setup');
    end;

    procedure CreateNewCompany(NewCompanyName: Text[30])
    var
        Company: Record Company;
        GeneralLedgerSetup: Record "General Ledger Setup";
        Window: Dialog;
    begin
        Window.Open(CreatingCompanyMsg);

        Company.Init();
        Company.Name := NewCompanyName;
        Company."Display Name" := NewCompanyName;
        Company.Insert();

        if not GeneralLedgerSetup.ChangeCompany(NewCompanyName) then
            Error(NoPermissionsErr);
        if not GeneralLedgerSetup.WritePermission then
            Error(NoPermissionsErr);

        Commit();

        Window.Close();
    end;

    [Scope('OnPrem')]
    procedure GetAllowedCompaniesForCurrentUser(var TempCompany: Record Company temporary)
    var
        Company: Record Company;
        UserAccountHelper: DotNet NavUserAccountHelper;
        CompanyName: Text[30];
    begin
        TempCompany.DeleteAll();
        foreach CompanyName in UserAccountHelper.GetAllowedCompanies() do
            if Company.Get(CompanyName) then begin
                TempCompany := Company;
                TempCompany.Insert();
            end;
    end;

    [Scope('OnPrem')]
    procedure IsAllowedCompanyForCurrentUser(CompanyName: Text[30]): Boolean
    var
        UserAccountHelper: DotNet NavUserAccountHelper;
        AllowedCompanyName: Text;
    begin
        foreach AllowedCompanyName in UserAccountHelper.GetAllowedCompanies() do
            if CompanyName = AllowedCompanyName then
                exit(true);
        exit(false);
    end;

    procedure AddAssistedCompanySetup()
    var
        GuidedExperience: Codeunit "Guided Experience";
        Language: Codeunit Language;
        Info: ModuleInfo;
        AssistedSetupGroup: Enum "Assisted Setup Group";
        VideoCategory: Enum "Video Category";
        GuidedExperienceType: Enum "Guided Experience Type";
        CurrentGlobalLanguage: Integer;
    begin
        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;

        CurrentGlobalLanguage := GLOBALLANGUAGE;
        NavApp.GetCurrentModuleInfo(Info);
        GuidedExperience.InsertAssistedSetup(InitialCompanySetupTxt, InitialCompanySetupShortTitleTxt, InitialCompanySetupDescTxt, 3,
            ObjectType::Page, Page::"Assisted Company Setup Wizard", AssistedSetupGroup::GettingStarted, '', VideoCategory::GettingStarted, InitialCompanySetupHelpTxt);

        GlobalLanguage(Language.GetDefaultApplicationLanguageId());

        GuidedExperience.AddTranslationForSetupObjectTitle(GuidedExperienceType::"Assisted Setup", ObjectType::Page,
            Page::"Assisted Company Setup Wizard", Language.GetDefaultApplicationLanguageId(), InitialCompanySetupTxt);
        GLOBALLANGUAGE(CurrentGlobalLanguage);
    end;

    local procedure AssistedCompanySetupIsVisible(): Boolean
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
    begin
        if AssistedCompanySetupStatus.Get(CompanyName) then
            exit(AssistedCompanySetupStatus.Enabled);
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitialize()
    begin
        if AssistedCompanySetupIsVisible() then
            AddAssistedCompanySetup();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assisted Company Setup Status", 'OnEnabled', '', false, false)]
    local procedure OnEnableAssistedCompanySetup(SetupCompanyName: Text[30]; AssistedSetupEnabled: Boolean)
    begin
        EnableAssistedCompanySetup(SetupCompanyName, AssistedSetupEnabled);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterCompanyOpenRunAssistedCompanySetup()
    begin
        RunAssistedCompanySetup();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Accessible Companies", 'OnBeforeActionEvent', 'Create New Company', false, false)]
    local procedure OnBeforeCreateNewCompanyActionAccessibleCompanies(var Rec: Record Company)
    begin
        PAGE.RunModal(PAGE::"Company Creation Wizard");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Companies", 'OnBeforeActionEvent', 'Create New Company', false, false)]
    local procedure OnBeforeCreateNewCompanyActionOnCompanyPageOpenCompanyCreationWizard(var Rec: Record Company)
    begin
        PAGE.RunModal(PAGE::"Company Creation Wizard");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"User Settings", 'OnCompanyChange', '', false, false)]
    local procedure OnCompanyChangeCheckForSetupCompletion(NewCompanyName: Text; var IsSetupInProgress: Boolean)
    begin
        IsSetupInProgress := IsCompanySetupInProgress(NewCompanyName);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assisted Company Setup Status", 'OnGetCompanySetupStatusValue', '', false, false)]
    local procedure OnGetIsCompanySetupInProgressValue(Name: Text[30]; var SetupStatus: Enum "Company Setup Status")
    begin
        SetupStatus := GetCompanySetupStatus(Name);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Assisted Company Setup Status", 'OnSetupStatusDrillDown', '', false, false)]
    local procedure OnSetupStatusDrillDown(Name: Text[30])
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        if not JobQueueLogEntry.ChangeCompany(Name) then
            exit;
        if FindJobQueueLogEntries(Name, JobQueueLogEntry) then
            PAGE.RunModal(PAGE::"Job Queue Log Entries", JobQueueLogEntry);
    end;

#pragma warning disable AS0072
    [IntegrationEvent(false, false)]
    local procedure OnAfterAssistedCompanySetupStatusEnabled(NewCompanyName: Text[30])
    begin
    end;
#pragma warning restore AS0072

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAccountingPeriod(StartDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetupNewCompanyWithDemoData(NewCompanyName: Text[30]; NewCompanyData: Enum "Company Demo Data Type")
    begin
    end;
}

#pragma warning restore AS0018, AS0025
