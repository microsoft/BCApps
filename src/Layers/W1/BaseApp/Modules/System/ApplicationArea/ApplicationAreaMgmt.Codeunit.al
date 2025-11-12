namespace System.Environment.Configuration;

using System.Azure.Identity;
using System.Environment;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

codeunit 9178 "Application Area Mgmt."
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        OnlyBasicAppAreaMsg: Label 'You do not have access to this page, because your experience is set to Basic.';
        ValuesNotAllowedErr: Label 'The selected experience is not supported.\\In the Application Area window, you define what is shown in the user interface.';
        HideApplicationAreaError: Boolean;
        PremiumSubscriptionNeededMsg: Label 'You cannot upgrade to the Premium experience because you do not have a Premium license assigned to you. Your administrator must assign the license to you in Office 365 and then synchronize the license information in Business Central from the Users page.';
        AppAreaNotSupportedErr: Label 'Application area Basic %1 is not supported.', Comment = '%1 = application area';
        DelegatedAdminExperienceTierMsg: Label 'Congratulations on the upgrade to Premium. To help ensure a smooth process, make sure that all users are assigned the license in Office 365, and that the license information is synchronized with Business Central.';

    local procedure GetApplicationAreaSetupRec(var ApplicationAreaSetup: Record "Application Area Setup"): Boolean
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        if ApplicationAreaSetup.IsEmpty() then
            exit(false);

        if not ApplicationAreaSetup.Get('', '', UserId()) then begin
            ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
            if not ApplicationAreaSetup.Get('', AllProfile."Profile ID") then
                if not GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName()) then
                    exit(ApplicationAreaSetup.Get());
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure GetApplicationAreaSetupRecFromCompany(var ApplicationAreaSetup: Record "Application Area Setup"; CompanyName: Text): Boolean
    begin
        exit(ApplicationAreaSetup.Get(CompanyName));
    end;

    procedure GetApplicationAreas() ApplicationAreas: Text
    var
        ApplicationAreaCache: Codeunit "Application Area Cache";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetApplicationAreas(ApplicationAreas, IsHandled);
        if IsHandled then
            exit(ApplicationAreas);

        if ApplicationAreaCache.GetApplicationAreasForUser(ApplicationAreas) then
            exit(ApplicationAreas);

        if ApplicationAreaCache.GetApplicationAreasForProfile(ApplicationAreas) then
            exit(ApplicationAreas);

        if ApplicationAreaCache.GetApplicationAreasForCompany(ApplicationAreas) then
            exit(ApplicationAreas);

        if ApplicationAreaCache.GetApplicationAreasCrossCompany(ApplicationAreas) then
            exit(ApplicationAreas);

        exit('');
    end;

    [Scope('OnPrem')]
    procedure GetApplicationAreaBuffer(var TempApplicationAreaBuffer: Record "Application Area Buffer" temporary)
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldIndex: Integer;
    begin
        GetApplicationAreaSetupRec(ApplicationAreaSetup);
        RecRef.GetTable(ApplicationAreaSetup);

        for FieldIndex := GetFirstPublicAppAreaFieldIndex() to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(FieldIndex);
            if not IsInPrimaryKey(FieldRef) then begin
                TempApplicationAreaBuffer."Field No." := FieldRef.Number();
                TempApplicationAreaBuffer."Application Area" :=
                  CopyStr(FieldRef.Caption, 1, MaxStrLen(TempApplicationAreaBuffer."Application Area"));
                TempApplicationAreaBuffer.Selected := FieldRef.Value();
                TempApplicationAreaBuffer.Insert(true);
            end;
        end;
    end;

    local procedure SaveApplicationArea(var TempApplicationAreaBuffer: Record "Application Area Buffer" temporary; ApplicationAreaSetup: Record "Application Area Setup"; NoApplicationAreasExist: Boolean)
    var
        TempExistingApplicationAreaBuffer: Record "Application Area Buffer" temporary;
        UserPreference: Record "User Preference";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        ApplicationAreasChanged: Boolean;
    begin
        GetApplicationAreaBuffer(TempExistingApplicationAreaBuffer);
        RecRef.GetTable(ApplicationAreaSetup);

        TempApplicationAreaBuffer.FindSet();
        TempExistingApplicationAreaBuffer.FindSet();
        repeat
            FieldRef := RecRef.Field(TempApplicationAreaBuffer."Field No.");
            FieldRef.Value := TempApplicationAreaBuffer.Selected;
            if TempApplicationAreaBuffer.Selected <> TempExistingApplicationAreaBuffer.Selected then
                ApplicationAreasChanged := true;
        until (TempApplicationAreaBuffer.Next() = 0) and (TempExistingApplicationAreaBuffer.Next() = 0);

        if NoApplicationAreasExist then begin
            if ApplicationAreasChanged then
                RecRef.Insert(true);
        end else
            RecRef.Modify(true);

        UserPreference.SetFilter("User ID", UserId);
        UserPreference.DeleteAll();

        SetupApplicationArea();
    end;

    local procedure TrySaveApplicationArea(var TempApplicationAreaBuffer: Record "Application Area Buffer" temporary; ApplicationAreaSetup: Record "Application Area Setup"; NoApplicationAreaExist: Boolean) IsApplicationAreaChanged: Boolean
    var
        OldApplicationArea: Text;
    begin
        OldApplicationArea := ApplicationArea();
        SaveApplicationArea(TempApplicationAreaBuffer, ApplicationAreaSetup, NoApplicationAreaExist);
        IsApplicationAreaChanged := OldApplicationArea <> ApplicationArea();
    end;

    [Scope('OnPrem')]
    procedure TrySaveApplicationAreaCurrentCompany(var TempApplicationAreaBuffer: Record "Application Area Buffer" temporary) IsApplicationAreaChanged: Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        NoCompanyApplicationAreasExist: Boolean;
    begin
        if not ApplicationAreaSetup.Get(CompanyName) then begin
            ApplicationAreaSetup."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(ApplicationAreaSetup."Company Name"));
            NoCompanyApplicationAreasExist := true;
        end;

        IsApplicationAreaChanged :=
          TrySaveApplicationArea(TempApplicationAreaBuffer, ApplicationAreaSetup, NoCompanyApplicationAreasExist);
    end;

    [Scope('OnPrem')]
    procedure TrySaveApplicationAreaCurrentUser(var TempApplicationAreaBuffer: Record "Application Area Buffer" temporary) IsApplicationAreaChanged: Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        NoUserApplicationAreasExist: Boolean;
    begin
        if not ApplicationAreaSetup.Get('', '', UserId()) then begin
            ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(ApplicationAreaSetup."User ID"));
            NoUserApplicationAreasExist := true;
        end;

        IsApplicationAreaChanged :=
          TrySaveApplicationArea(TempApplicationAreaBuffer, ApplicationAreaSetup, NoUserApplicationAreasExist);
    end;

    [Scope('OnPrem')]
    procedure SetupApplicationArea()
    begin
        ApplicationArea(GetApplicationAreas());
    end;

    local procedure GetApplicationAreaSetupFromSession() ApplicationAreas: Text
    begin
        ApplicationAreas := ApplicationArea();
        if ApplicationAreas = '' then
            ApplicationAreas := GetApplicationAreas();
    end;

    local procedure IsApplicationAreaEnabled(ApplicationAreaName: Text): Boolean
    var
        ApplicationAreaList: List of [Text];
    begin
        ApplicationAreaList := GetApplicationAreaSetupFromSession().Split(',');
        exit(ApplicationAreaList.Contains('#' + ApplicationAreaName.Replace(' ', '')));
    end;

    [Scope('OnPrem')]
    procedure IsBasicEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Basic)));
    end;

    [Scope('OnPrem')]
    procedure IsFoundationEnabled(): Boolean
    begin
        exit(IsBasicEnabled() or IsSuiteEnabled());
    end;

    [Scope('OnPrem')]
    procedure IsBasicOnlyEnabled(): Boolean
    begin
        exit(IsBasicEnabled() and not IsSuiteEnabled() and not IsAdvancedEnabled());
    end;

    [Scope('OnPrem')]
    procedure IsAdvancedEnabled(): Boolean
    begin
        exit(not IsFoundationEnabled());
    end;

    [Scope('OnPrem')]
    procedure IsFixedAssetEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Fixed Assets")));
    end;

    [Scope('OnPrem')]
    procedure IsJobsEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Jobs)));
    end;

    [Scope('OnPrem')]
    procedure IsBasicHREnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(BasicHR)));
    end;

    [Scope('OnPrem')]
    procedure IsDimensionEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Dimensions)));
    end;

    [Scope('OnPrem')]
    procedure IsLocationEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Location)));
    end;

    [Scope('OnPrem')]
    procedure IsAssemblyEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Assembly)));
    end;

    [Scope('OnPrem')]
    procedure IsItemChargesEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Item Charges")));
    end;

    [Scope('OnPrem')]
    procedure IsItemTrackingEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Item Tracking")));
    end;

    [Scope('OnPrem')]
    procedure IsIntercompanyEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Intercompany)));
    end;

    [Scope('OnPrem')]
    procedure IsSalesReturnOrderEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Sales Return Order")));
    end;

    [Scope('OnPrem')]
    procedure IsPurchaseReturnOrderEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Purch Return Order")));
    end;

    [Scope('OnPrem')]
    procedure IsCostAccountingEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Cost Accounting")));
    end;

    [Scope('OnPrem')]
    procedure IsSalesBudgetEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Sales Budget")));
    end;

    [Scope('OnPrem')]
    procedure IsPurchaseBudgetEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Purchase Budget")));
    end;

    [Scope('OnPrem')]
    procedure IsItemBudgetEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Item Budget")));
    end;

    [Scope('OnPrem')]
    procedure IsItemReferencesEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Item References")));
    end;

    [Scope('OnPrem')]
    procedure IsSalesAnalysisEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Sales Analysis")));
    end;

    [Scope('OnPrem')]
    procedure IsPurchaseAnalysisEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Purchase Analysis")));
    end;

    [Scope('OnPrem')]
    procedure IsInventoryAnalysisEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Inventory Analysis")));
    end;

    [Scope('OnPrem')]
    procedure IsReservationEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Reservation)));
    end;

    [Scope('OnPrem')]
    procedure IsManufacturingEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Manufacturing)));
    end;

    [Scope('OnPrem')]
    procedure IsPlanningEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Planning)));
    end;

    [Scope('OnPrem')]
    procedure IsRelationshipMgmtEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Relationship Mgmt")));
    end;

    [Scope('OnPrem')]
    procedure IsServiceEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Service)));
    end;

    [Scope('OnPrem')]
    procedure IsWarehouseEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Warehouse)));
    end;

    [Scope('OnPrem')]
    procedure IsOrderPromisingEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Order Promising")));
    end;

    [Scope('OnPrem')]
    procedure IsCommentsEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Comments)));
    end;

    [Scope('OnPrem')]
    procedure IsRecordLinksEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Record Links")));
    end;

    [Scope('OnPrem')]
    procedure IsNotesEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Notes)));
    end;

    procedure IsVATEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(VAT)));
    end;

    procedure IsSalesTaxEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Sales Tax")));
    end;

    procedure IsBasicCountryEnabled(CountryCode: Code[10]): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        IsHandled: Boolean;
        IsEnabled: Boolean;
    begin
        case CountryCode of
            // used for functinality specific to all EU countries
            'EU':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic EU")));
            // used for country specific functionality
            'AU':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic AU")));
            'AT':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic AT")));
            'CH':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic CH")));
            'DE':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic DE")));
            'BE':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic BE")));
            'CA':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic CA")));
            'CZ':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic CZ")));
            'DK':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic DK")));
            'ES':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic ES")));
            'FI':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic FI")));
            'FR':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic FR")));
            'GB':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic GB")));
            'IS':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic IS")));
            'IT':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic IT")));
            'MX':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic MX")));
            'NL':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic NL")));
            'NO':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic NO")));
            'NZ':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic NZ")));
            'RU':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic RU")));
            'SE':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic SE")));
            'US':
                exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName("Basic US")));
            else begin
                IsHandled := false;
                OnIsBasicCountryEnabled(CountryCode, IsEnabled, IsHandled);
                if IsHandled then
                    exit(IsEnabled);
                Error(AppAreaNotSupportedErr, CountryCode);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure IsSuiteEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        exit(IsApplicationAreaEnabled(ApplicationAreaSetup.FieldName(Suite)));
    end;

    [Scope('OnPrem')]
    procedure IsAllDisabled(): Boolean
    begin
        exit(not IsAnyEnabled());
    end;

    local procedure IsAnyEnabled(): Boolean
    begin
        exit(ApplicationArea() <> '');
    end;

    [Scope('OnPrem')]
    procedure IsPremiumEnabled(): Boolean
    var
        PlanIds: Codeunit "Plan Ids";
        AzureADPlan: Codeunit "Azure AD Plan";
    begin
        if AzureADPlan.IsPlanAssignedToUser(PlanIds.GetPremiumPlanId()) then
            exit(true);

        if AzureADPlan.IsPlanAssignedToUser(PlanIds.GetPremiumISVPlanId()) then
            exit(true);

        if AzureADPlan.IsPlanAssignedToUser(PlanIds.GetViralSignupPlanId()) then
            exit(true);

        if AzureADPlan.IsPlanAssignedToUser(PlanIds.GetPremiumPartnerSandboxPlanId()) then
            exit(true);
    end;

    [Scope('OnPrem')]
    procedure CheckAppAreaOnlyBasic()
    begin
        if IsBasicOnlyEnabled() then begin
            Message(OnlyBasicAppAreaMsg);
            Error('');
        end;
    end;

    [Scope('OnPrem')]
    procedure IsValidExperienceTierSelected(SelectedExperienceTier: Text): Boolean
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        EnvironmenInformation: Codeunit "Environment Information";
        IdentityMgmt: Codeunit "Identity Management";
    begin
        if EnvironmenInformation.IsOnPrem() then
            exit(true);

        if (SelectedExperienceTier <> ExperienceTierSetup.FieldName(Premium)) or IsPremiumEnabled() then
            exit(true);

        if (SelectedExperienceTier = ExperienceTierSetup.FieldName(Premium)) and IdentityMgmt.IsUserDelegatedAdmin() then begin
            Message(DelegatedAdminExperienceTierMsg);
            exit(true);
        end;

        Message(PremiumSubscriptionNeededMsg);
        exit(false);
    end;

    local procedure IsInPrimaryKey(FieldRef: FieldRef): Boolean
    var
        RecRef: RecordRef;
        KeyRef: KeyRef;
        FieldIndex: Integer;
    begin
        RecRef := FieldRef.Record();

        KeyRef := RecRef.KeyIndex(1);
        for FieldIndex := 1 to KeyRef.FieldCount() do
            if KeyRef.FieldIndex(FieldIndex).Number() = FieldRef.Number() then
                exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetFirstPublicAppAreaFieldIndex(): Integer
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        RecRef: RecordRef;
        FirstPublicAppAreaFieldRef: FieldRef;
        i: Integer;
    begin
        RecRef.GetTable(ApplicationAreaSetup);
        FirstPublicAppAreaFieldRef := RecRef.Field(ApplicationAreaSetup.FieldNo(Basic));
        for i := 1 to RecRef.FieldCount do
            if RecRef.FieldIndex(i).Number() = FirstPublicAppAreaFieldRef.Number() then
                exit(i);
    end;

    local procedure GetExperienceTierRec(var ExperienceTierSetup: Record "Experience Tier Setup"): Boolean
    begin
        exit(ExperienceTierSetup.Get(CompanyName));
    end;

    [Scope('OnPrem')]
    procedure GetExperienceTierBuffer(var TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary)
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldIndex: Integer;
    begin
        GetExperienceTierRec(ExperienceTierSetup);
        RecRef.GetTable(ExperienceTierSetup);

        for FieldIndex := 1 to RecRef.FieldCount() do begin
            FieldRef := RecRef.FieldIndex(FieldIndex);
            if not IsInPrimaryKey(FieldRef) then begin
                TempExperienceTierBuffer."Field No." := FieldRef.Number();
                TempExperienceTierBuffer."Experience Tier" := CopyStr(FieldRef.Caption(), 1, MaxStrLen(TempExperienceTierBuffer."Experience Tier"));
                TempExperienceTierBuffer.Selected := FieldRef.Value();
                TempExperienceTierBuffer.Insert(true);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure LookupExperienceTier(var NewExperienceTier: Text): Boolean
    var
        TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary;
        ExperienceTierSetup: Record "Experience Tier Setup";
    begin
        GetExperienceTierBuffer(TempExperienceTierBuffer);
        if NewExperienceTier <> '' then begin
            TempExperienceTierBuffer.SetRange("Experience Tier", NewExperienceTier);
            if TempExperienceTierBuffer.FindFirst() then;
            TempExperienceTierBuffer.SetRange("Experience Tier");
        end;

        // Always remove Preview from ExpTier options, because Preview features have gradated to premium
        if TempExperienceTierBuffer.Get(ExperienceTierSetup.FieldNo(Preview)) then
            TempExperienceTierBuffer.Delete();

        // Always remove Advanced from ExpTier options
        if TempExperienceTierBuffer.Get(ExperienceTierSetup.FieldNo(Advanced)) then
            TempExperienceTierBuffer.Delete();

        if TempExperienceTierBuffer.Get(ExperienceTierSetup.FieldNo(Basic)) then
            TempExperienceTierBuffer.Delete();

        GetExperienceTierRec(ExperienceTierSetup);
        if not ExperienceTierSetup.Custom then
            if TempExperienceTierBuffer.Get(ExperienceTierSetup.FieldNo(Custom)) then
                TempExperienceTierBuffer.Delete();

        OnBeforeLookupExperienceTier(TempExperienceTierBuffer);
        if page.RunModal(0, TempExperienceTierBuffer, TempExperienceTierBuffer."Experience Tier") = action::LookupOK then begin
            NewExperienceTier := TempExperienceTierBuffer."Experience Tier";
            OnLookupExperienceTierOnAfterGetNewExperienceTier(NewExperienceTier);
            exit(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure SaveExperienceTierCurrentCompany(NewExperienceTier: Text) ExperienceTierChanged: Boolean
    var
        TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary;
        ExperienceTierSetup: Record "Experience Tier Setup";
        Company: Record Company;
        RecRef: RecordRef;
        FieldRef: FieldRef;
        CurrentExperienceTier: Text;
        SelectedAlreadySaved: Boolean;
    begin
        GetExperienceTierCurrentCompany(CurrentExperienceTier);
        ExperienceTierChanged := CurrentExperienceTier <> NewExperienceTier;

        GetExperienceTierBuffer(TempExperienceTierBuffer);
        TempExperienceTierBuffer.SetRange("Experience Tier", NewExperienceTier);
        if not TempExperienceTierBuffer.FindFirst() then
            exit(false);

        if not GetExperienceTierRec(ExperienceTierSetup) then begin
            ExperienceTierSetup."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(ExperienceTierSetup."Company Name"));
            ExperienceTierSetup.Insert();
        end else
            if not ExperienceTierChanged then begin
                Company.Get(CompanyName());
                if (NewExperienceTier = ExperienceTierSetup.FieldCaption(Custom)) or Company."Evaluation Company" then
                    exit(false);
            end;

        RecRef.GetTable(ExperienceTierSetup);
        FieldRef := RecRef.Field(TempExperienceTierBuffer."Field No.");
        SelectedAlreadySaved := FieldRef.Value();
        if not SelectedAlreadySaved then begin
            RecRef.Init();
            FieldRef.Value := true;
            RecRef.SetTable(ExperienceTierSetup);
            ExperienceTierSetup.Modify();
        end;

        SetExperienceTierCurrentCompany(ExperienceTierSetup);
    end;

    [Scope('OnPrem')]
    procedure GetExperienceTierCurrentCompany(var ExperienceTier: Text): Boolean
    var
        TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary;
    begin
        Clear(ExperienceTier);
        GetExperienceTierBuffer(TempExperienceTierBuffer);
        TempExperienceTierBuffer.SetRange(Selected, true);
        if TempExperienceTierBuffer.FindFirst() then
            ExperienceTier := TempExperienceTierBuffer."Experience Tier";
        exit(ExperienceTier <> '');
    end;

    local procedure SetExperienceTier(CompanyName: Text; ExperienceTierSetup: Record "Experience Tier Setup")
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        TempApplicationAreaSetup: Record "Application Area Setup" temporary;
        ApplicationAreasSet: Boolean;
    begin
        if ExperienceTierSetup.Custom then
            Error(ValuesNotAllowedErr);

        if not GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName) then begin
            ApplicationAreaSetup."Company Name" := CopyStr(CompanyName, 1, MaxStrLen(ApplicationAreaSetup."Company Name"));
            ApplicationAreaSetup.Insert();
        end;

        case true of
            ExperienceTierSetup.Basic:
                GetBasicExperienceAppAreas(TempApplicationAreaSetup);
            ExperienceTierSetup.Essential:
                GetEssentialExperienceAppAreas(TempApplicationAreaSetup);
            ExperienceTierSetup.Premium:
                GetPremiumExperienceAppAreas(TempApplicationAreaSetup);
            else begin
                OnSetExperienceTier(ExperienceTierSetup, TempApplicationAreaSetup, ApplicationAreasSet);
                if not ApplicationAreasSet then
                    exit;
            end;
        end;

        if not ValidateApplicationAreasSet(ExperienceTierSetup, TempApplicationAreaSetup) then begin
            if HideApplicationAreaError then
                exit;
            Error(GetLastErrorText);
        end;

        ApplicationAreaSetup.TransferFields(TempApplicationAreaSetup, false);
        ApplicationAreaSetup.Modify();
        SetupApplicationArea();
    end;

    [Scope('OnPrem')]
    procedure SetExperienceTierCurrentCompany(ExperienceTierSetup: Record "Experience Tier Setup")
    begin
        SetExperienceTier(CompanyName, ExperienceTierSetup);
    end;

    [Scope('OnPrem')]
    procedure SetExperienceTierOtherCompany(ExperienceTierSetup: Record "Experience Tier Setup"; CompanyName: Text)
    begin
        SetExperienceTier(CompanyName, ExperienceTierSetup);
    end;

    local procedure ApplicationAreaSetupsMatch(ApplicationAreaSetup: Record "Application Area Setup"; TempApplicationAreaSetup: Record "Application Area Setup" temporary; CheckBaseOnly: Boolean): Boolean
    var
        RecRef: RecordRef;
        RecRef2: RecordRef;
        FieldRef: FieldRef;
        FieldRef2: FieldRef;
        FieldIndex: Integer;
    begin
        RecRef.GetTable(ApplicationAreaSetup);
        RecRef2.GetTable(TempApplicationAreaSetup);

        for FieldIndex := 1 to RecRef.FieldCount do begin
            FieldRef := RecRef.FieldIndex(FieldIndex);
            if CheckBaseOnly and (FieldRef.Number() >= 49999) then
                exit(true);
            FieldRef2 := RecRef2.FieldIndex(FieldIndex);
            if not IsInPrimaryKey(FieldRef) then
                if not (FieldRef.Value() = FieldRef2.Value()) then
                    exit(false);
        end;
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure IsBasicExperienceEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        TempApplicationAreaSetup: Record "Application Area Setup" temporary;
    begin
        if not GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName) then
            exit(false);

        GetBasicExperienceAppAreas(TempApplicationAreaSetup);

        exit(ApplicationAreaSetupsMatch(ApplicationAreaSetup, TempApplicationAreaSetup, false));
    end;

    [Scope('OnPrem')]
    procedure IsEssentialExperienceEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        TempApplicationAreaSetup: Record "Application Area Setup" temporary;
    begin
        if not GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName) then
            exit(false);

        GetEssentialExperienceAppAreas(TempApplicationAreaSetup);

        exit(ApplicationAreaSetupsMatch(ApplicationAreaSetup, TempApplicationAreaSetup, false));
    end;

    [Scope('OnPrem')]
    procedure IsPremiumExperienceEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        TempApplicationAreaSetup: Record "Application Area Setup" temporary;
    begin
        if not GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName) then
            exit(false);

        GetPremiumExperienceAppAreas(TempApplicationAreaSetup);

        exit(ApplicationAreaSetupsMatch(ApplicationAreaSetup, TempApplicationAreaSetup, false));
    end;

    [Scope('OnPrem')]
    procedure IsCustomExperienceEnabled(): Boolean
    var
        IsPreDefinedExperience: Boolean;
    begin
        IsPreDefinedExperience :=
          IsBasicExperienceEnabled() or IsEssentialExperienceEnabled() or IsPremiumExperienceEnabled() or
          IsAdvancedExperienceEnabled();

        exit(not IsPreDefinedExperience);
    end;

    [Scope('OnPrem')]
    procedure IsAdvancedExperienceEnabled(): Boolean
    var
        ApplicationAreaSetup: Record "Application Area Setup";
        TempApplicationAreaSetup: Record "Application Area Setup" temporary;
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSandbox() then
            exit(true);

        if not GetApplicationAreaSetupRecFromCompany(ApplicationAreaSetup, CompanyName()) then
            exit(true);

        exit(ApplicationAreaSetupsMatch(ApplicationAreaSetup, TempApplicationAreaSetup, false));
    end;

    [Scope('OnPrem')]
    procedure GetBasicExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup.Basic := true;
        TempApplicationAreaSetup."Relationship Mgmt" := true;
        TempApplicationAreaSetup."Record Links" := true;
        TempApplicationAreaSetup.Notes := true;

        OnGetBasicExperienceAppAreas(TempApplicationAreaSetup);
    end;

    [Scope('OnPrem')]
    procedure GetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        GetBasicExperienceAppAreas(TempApplicationAreaSetup);
        TempApplicationAreaSetup.Suite := true;
        TempApplicationAreaSetup.Jobs := true;
        TempApplicationAreaSetup."Fixed Assets" := true;
        TempApplicationAreaSetup.Location := true;
        TempApplicationAreaSetup.BasicHR := true;
        TempApplicationAreaSetup.Assembly := true;
        TempApplicationAreaSetup."Item Charges" := true;
        TempApplicationAreaSetup."Item References" := true;
        TempApplicationAreaSetup.Intercompany := true;
        TempApplicationAreaSetup."Sales Return Order" := true;
        TempApplicationAreaSetup."Purch Return Order" := true;
        TempApplicationAreaSetup.Prepayments := true;
        TempApplicationAreaSetup."Cost Accounting" := true;
        TempApplicationAreaSetup."Sales Budget" := true;
        TempApplicationAreaSetup."Purchase Budget" := true;
        TempApplicationAreaSetup."Item Budget" := true;
        TempApplicationAreaSetup."Sales Analysis" := true;
        TempApplicationAreaSetup."Purchase Analysis" := true;
        TempApplicationAreaSetup."Inventory Analysis" := true;
        TempApplicationAreaSetup."Item Tracking" := true;
        TempApplicationAreaSetup.Warehouse := true;
        TempApplicationAreaSetup."Order Promising" := true;
        TempApplicationAreaSetup.Reservation := true;
        TempApplicationAreaSetup.Dimensions := true;
        TempApplicationAreaSetup.ADCS := true;
        TempApplicationAreaSetup.Planning := true;
        TempApplicationAreaSetup.Comments := true;

        OnGetEssentialExperienceAppAreas(TempApplicationAreaSetup);
    end;

    [Scope('OnPrem')]
    procedure GetPremiumExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        GetEssentialExperienceAppAreas(TempApplicationAreaSetup);
        TempApplicationAreaSetup.Service := true;
        TempApplicationAreaSetup.Manufacturing := true;

        OnGetPremiumExperienceAppAreas(TempApplicationAreaSetup);
    end;

    [TryFunction]
    local procedure ValidateApplicationAreasSet(ExperienceTierSetup: Record "Experience Tier Setup"; TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
        TempApplicationAreaSetup.TestField(Basic, true);

        OnValidateApplicationAreas(ExperienceTierSetup, TempApplicationAreaSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBasicExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetEssentialExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPremiumExperienceAppAreas(var TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetApplicationAreas(var ApplicationAreas: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupExperienceTier(var TempExperienceTierBuffer: Record "Experience Tier Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsBasicCountryEnabled(CountryCode: Code[10]; var IsEnabled: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupExperienceTierOnAfterGetNewExperienceTier(NewExperienceTier: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetExperienceTier(ExperienceTierSetup: Record "Experience Tier Setup"; var TempApplicationAreaSetup: Record "Application Area Setup" temporary; var ApplicationAreasSet: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateApplicationAreas(ExperienceTierSetup: Record "Experience Tier Setup"; TempApplicationAreaSetup: Record "Application Area Setup" temporary)
    begin
    end;

    [Scope('OnPrem')]
    procedure SetHideApplicationAreaError(NewHideApplicationAreaError: Boolean)
    begin
        HideApplicationAreaError := NewHideApplicationAreaError;
    end;
}

