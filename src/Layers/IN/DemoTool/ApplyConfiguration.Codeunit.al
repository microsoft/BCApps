codeunit 101940 "Apply Configuration"
{

    trigger OnRun()
    begin
    end;

    var
        PackLanguageCode: Code[10];

    procedure ApplyEvaluationConfiguration()
    var
        DataClassificationEvalData: Codeunit "Data Classification Eval. Data";
        DataType: Option Evaluation,Standard;
    begin
        SetDefaultRoleCenter();
        SetExperienceTierToEssential();
        SetupAndRunAssistedCompanySetup(DataType::Evaluation);
        RunCashFlowForecastWizard();
        DataClassificationEvalData.CreateEvaluationData();
    end;

    procedure ApplyStandardConfiguration()
    var
        DataType: Option Evaluation,Standard;
    begin
        SetDefaultRoleCenter();
        SetExperienceTierToEssential();
        SetupAndRunAssistedCompanySetup(DataType::Standard);
    end;

    local procedure SetExperienceTierToEssential()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
    end;

    local procedure SetDefaultRoleCenter()
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        AllProfile.SetFilter("Role Center ID", '=%1', ConfPersonalizationMgt.DefaultRoleCenterID());
        AllProfile.SetRange("Scope", AllProfile.Scope::Tenant);
        AllProfile.FindFirst();
        ConfPersonalizationMgt.ChangeDefaultRoleCenter(AllProfile);
    end;

    local procedure ImportConfigurationPackageFiles(DataType: Option Evaluation,Standard)
    var
        ConfigurationPackageFile: Record "Configuration Package File";
        TaxType: Record "Tax Type";
        TaxEngineAssistedSetup: Codeunit "Tax Engine Assisted Setup";
        CreateD365BaseData: Codeunit "Create D365 Base Data";
        CreateTaxAccPeriod: Codeunit "Create Tax Accounting Period";
    begin
        if DataType = DataType::Evaluation then
            BindSubscription(CreateD365BaseData);

        if TaxType.IsEmpty() then begin
            TaxEngineAssistedSetup.SetupTaxEngine();
            CreateTaxAccPeriod.CreateTaxTypeSetup();
        end;

        if PackLanguageCode <> '' then
            ConfigurationPackageFile.SetFilter(Code, '*' + PackLanguageCode + '.' + Format(DataType) + '*')
        else
            ConfigurationPackageFile.SetFilter(Code, '*' + Format(DataType) + '*');

        CODEUNIT.Run(CODEUNIT::"Import Config Package Files", ConfigurationPackageFile);
    end;

    local procedure SetupAndRunAssistedCompanySetup(DataType: Option Evaluation,Standard)
    var
        AssistedCompanySetupStatus: Record "Assisted Company Setup Status";
        Enabled: Boolean;
    begin
        if (DataType <> DataType::Evaluation) and (DataType <> DataType::Standard) then
            Enabled := true;

        AssistedCompanySetupStatus.SetEnabled(CompanyName, Enabled, false);
        ImportConfigurationPackageFiles(DataType);
    end;

    local procedure RunCashFlowForecastWizard()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        GuidedExperience: Codeunit "Guided Experience";
        CashFlowManagement: Codeunit "Cash Flow Management";
        LogInManagement: Codeunit LogInManagement;
        TaxablePeriod: Option Monthly,Quarterly,"Accounting Period",Yearly;
        TaxPaymentWindow: DateFormula;
    begin
        // Imitate that the user has run the Cash Flow Forecasting Setup wizard
        WorkDate := LogInManagement.GetDefaultWorkDate();

        CashFlowManagement.SetupCashFlow(CopyStr(CashFlowManagement.GetCashAccountFilter(), 1, 250));

        CashFlowSetup.UpdateTaxPaymentInfo(TaxablePeriod::Quarterly, TaxPaymentWindow, CashFlowSetup."Tax Bal. Account Type"::" ", '');

        CashFlowSetup.Get();
        CashFlowSetup.Validate("Automatic Update Frequency", CashFlowSetup."Automatic Update Frequency"::Weekly);
        CashFlowSetup.Modify();

        CashFlowManagement.UpdateCashFlowForecast(false);

        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Cash Flow Forecast Wizard");
    end;

    procedure ApplyEvaluationConfigurationWithCulture(PackLanguage: Code[10])
    begin
        PackLanguageCode := PackLanguage;
        ApplyEvaluationConfiguration();
    end;

    procedure ApplyStandardConfigurationWithCulture(PackLanguage: Code[10])
    begin
        PackLanguageCode := PackLanguage;
        ApplyStandardConfiguration();
    end;

    procedure CleanUpConfigPackages()
    var
        ConfigurationPackageFile: Record "Configuration Package File";
    begin
        ConfigurationPackageFile.DeleteAll();
    end;
}

