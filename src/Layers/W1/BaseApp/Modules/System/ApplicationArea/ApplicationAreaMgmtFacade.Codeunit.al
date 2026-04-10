namespace System.Environment.Configuration;

codeunit 9179 "Application Area Mgmt. Facade"
{
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetApplicationAreaSetupRecFromCompany(var ApplicationAreaSetup: Record "Application Area Setup"; CompanyName: Text): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName))
    end;

    procedure GetApplicationAreaSetup(): Text
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.GetApplicationAreas());
    end;

    procedure SetupApplicationArea()
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        ApplicationAreaMgmt.SetupApplicationArea();
    end;

    procedure IsFoundationEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsFoundationEnabled());
    end;

    procedure IsBasicOnlyEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsBasicOnlyEnabled());
    end;

    procedure IsAdvancedEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsAdvancedEnabled());
    end;

    procedure IsFixedAssetEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsFixedAssetEnabled());
    end;

    procedure IsJobsEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsJobsEnabled());
    end;

    procedure IsBasicHREnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsBasicHREnabled());
    end;

    procedure IsDimensionEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsDimensionEnabled());
    end;

    procedure IsLocationEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsLocationEnabled());
    end;

    procedure IsAssemblyEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsAssemblyEnabled());
    end;

    procedure IsItemChargesEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsItemChargesEnabled());
    end;

    procedure IsItemReferencesEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsItemReferencesEnabled());
    end;

    procedure IsItemTrackingEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsItemTrackingEnabled());
    end;

    procedure IsIntercompanyEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsIntercompanyEnabled());
    end;

    procedure IsSalesReturnOrderEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsSalesReturnOrderEnabled());
    end;

    procedure IsPurchaseReturnOrderEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsPurchaseReturnOrderEnabled());
    end;

    procedure IsCostAccountingEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsCostAccountingEnabled());
    end;

    procedure IsSalesBudgetEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsSalesBudgetEnabled());
    end;

    procedure IsPurchaseBudgetEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsPurchaseBudgetEnabled());
    end;

    procedure IsItemBudgetEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsItemBudgetEnabled());
    end;

    procedure IsSalesAnalysisEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsSalesAnalysisEnabled());
    end;

    procedure IsPurchaseAnalysisEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsPurchaseAnalysisEnabled());
    end;

    procedure IsInventoryAnalysisEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsInventoryAnalysisEnabled());
    end;

    procedure IsManufacturingEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsManufacturingEnabled());
    end;

    procedure IsPlanningEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsPlanningEnabled());
    end;

    procedure IsRelationshipMgmtEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsRelationshipMgmtEnabled());
    end;

    procedure IsServiceEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsServiceEnabled());
    end;

    procedure IsWarehouseEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsWarehouseEnabled());
    end;

    procedure IsReservationEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsReservationEnabled());
    end;

    procedure IsOrderPromisingEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsOrderPromisingEnabled());
    end;

    procedure IsCommentsEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsCommentsEnabled());
    end;

    procedure IsRecordLinksEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsRecordLinksEnabled());
    end;

    procedure IsNotesEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsNotesEnabled());
    end;

    procedure IsVATEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsVATEnabled());
    end;

    procedure IsSalesTaxEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsSalesTaxEnabled());
    end;

    procedure IsBasicCountryEnabled(CountryCode: Code[10]): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsBasicCountryEnabled(CountryCode));
    end;

    procedure IsSuiteEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsSuiteEnabled());
    end;

    procedure IsAllDisabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsAllDisabled());
    end;

    procedure IsPremiumEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsPremiumEnabled());
    end;

    procedure CheckAppAreaOnlyBasic()
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        ApplicationAreaMgmt.CheckAppAreaOnlyBasic();
    end;

    procedure IsValidExperienceTierSelected(SelectedExperienceTier: Text): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsValidExperienceTierSelected(SelectedExperienceTier));
    end;

    procedure LookupExperienceTier(var NewExperienceTier: Text): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.LookupExperienceTier(NewExperienceTier));
    end;

    procedure SaveExperienceTierCurrentCompany(NewExperienceTier: Text): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.SaveExperienceTierCurrentCompany(NewExperienceTier));
    end;

    procedure GetExperienceTierCurrentCompany(var ExperienceTier: Text): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.GetExperienceTierCurrentCompany(ExperienceTier));
    end;

    procedure RefreshExperienceTierCurrentCompany()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        if not ExperienceTierSetup.Get(CompanyName) then
            exit;
        ApplicationAreaMgmt.SetExperienceTierCurrentCompany(ExperienceTierSetup);
    end;

    procedure IsBasicExperienceEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsBasicExperienceEnabled());
    end;

    procedure IsEssentialExperienceEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsEssentialExperienceEnabled());
    end;

    procedure IsPremiumExperienceEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsPremiumExperienceEnabled());
    end;

    procedure IsCustomExperienceEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsCustomExperienceEnabled());
    end;

    procedure IsAdvancedExperienceEnabled(): Boolean
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        exit(ApplicationAreaMgmt.IsAdvancedExperienceEnabled());
    end;

    procedure GetBasicApplicationAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        ApplicationAreaMgmt.GetBasicExperienceAppAreas(TempApplicationAreaSetup);
    end;

    procedure GetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        ApplicationAreaMgmt.GetEssentialExperienceAppAreas(TempApplicationAreaSetup);
    end;

    procedure GetPremiumExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        ApplicationAreaMgmt.GetPremiumExperienceAppAreas(TempApplicationAreaSetup);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnGetBasicExperienceAppAreas', '', false, false)]
    local procedure RaiseOnGetBasicExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        OnGetBasicExperienceAppAreas(TempApplicationAreaSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBasicExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnGetEssentialExperienceAppAreas', '', false, false)]
    local procedure RaiseOnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        OnGetEssentialExperienceAppAreas(TempApplicationAreaSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnGetPremiumExperienceAppAreas', '', false, false)]
    local procedure RaiseOnGetPremiumExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        OnGetPremiumExperienceAppAreas(TempApplicationAreaSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPremiumExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnBeforeLookupExperienceTier', '', false, false)]
    local procedure RaiseOnBeforeLookupExperienceTier(var TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary)
    begin
        OnBeforeLookupExperienceTier(TempExperienceTierBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupExperienceTier(var TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnSetExperienceTier', '', false, false)]
    local procedure RaiseOnSetExperienceTier(ExperienceTierSetup: Record "Experience Tier Setup"; var TempApplicationAreaSetup: Record "Application Area Setup" temporary; var ApplicationAreasSet: Boolean)
    begin
        OnSetExperienceTier(ExperienceTierSetup, TempApplicationAreaSetup, ApplicationAreasSet);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetExperienceTier(ExperienceTierSetup: Record "Experience Tier Setup"; var TempApplicationAreaSetup: Record "Application Area Setup" temporary; var ApplicationAreasSet: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Application Area Mgmt.", 'OnValidateApplicationAreas', '', false, false)]
    local procedure RaiseOnValidateApplicationAreas(ExperienceTierSetup: Record "Experience Tier Setup"; TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        OnValidateApplicationAreas(ExperienceTierSetup, TempApplicationAreaSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateApplicationAreas(ExperienceTierSetup: Record "Experience Tier Setup"; TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
    end;

    procedure SetHideApplicationAreaError(NewHideApplicationAreaError: Boolean)
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        ApplicationAreaMgmt.SetHideApplicationAreaError(NewHideApplicationAreaError);
    end;
}

