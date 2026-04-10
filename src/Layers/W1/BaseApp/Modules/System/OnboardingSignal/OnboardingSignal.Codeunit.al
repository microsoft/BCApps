namespace System.Feedback;

using System.Environment;
using System.Telemetry;


codeunit 7580 "Onboarding Signal"
{
    Access = Public;
    Permissions = tabledata "Onboarding Signal" = rimd;

    var
        Telemetry: Codeunit Telemetry;

    /// <summary> Register a new Onboarding Signal to keep track of. </summary>
    /// <param name="CompanyName"> The name of the company you want to register the onboarding signal for. </param>
    /// <param name="OnboardingSignalType"> A new Onboarding Signal. </param>
    procedure RegisterNewOnboardingSignal(CompanyName: Text[30]; OnboardingSignalType: Enum "Onboarding Signal Type")
    var
        OnboardingSignal: Record "Onboarding Signal";
        CallerModuleInfo: ModuleInfo;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        OnboardingSignal.SetRange("Company Name", CompanyName);
        OnboardingSignal.SetRange("Onboarding Signal Type", OnboardingSignalType);

        if OnboardingSignal.IsEmpty() then begin
            NavApp.GetCallerModuleInfo(CallerModuleInfo);

            OnboardingSignal.Init();
            OnboardingSignal."No." := 0;
            OnboardingSignal."Company Name" := CompanyName;
            OnboardingSignal."Onboarding Signal Type" := OnboardingSignalType;
            OnboardingSignal."Onboarding Completed" := false;
            OnboardingSignal."Onboarding Start Date" := Today();
            OnboardingSignal."Onboarding Complete Date" := 0D;
            OnboardingSignal."Extension ID" := CallerModuleInfo.Id();
            OnboardingSignal.Insert();

            AddOnboardingSignalDimensions(OnboardingSignal, CustomDimensions);

            Telemetry.LogMessage('0000EIW', 'Onboarding Signal Started: ' + Format(OnboardingSignal."Onboarding Signal Type"), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, CustomDimensions);
        end;
    end;

    /// <summary>
    /// Check the status on all registered onboarding signals, and emit corresponding Telemetry when the criteria is met. This is run automatically once a day when login.
    /// </summary>
    procedure CheckAndEmitOnboardingSignals()
    var
        Company: Record Company;
        OnboardingSignal: Record "Onboarding Signal";
        EnvironmentInformation: Codeunit "Environment Information";
        OnboardingSignalProvider: Interface "Onboarding Signal";
        TelemetryScope: TelemetryScope;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        if not Company.Get(CompanyName()) then
            exit;

        if Company."Evaluation Company" then
            exit;

        if EnvironmentInformation.IsSandbox() then
            exit;

        OnboardingSignal.SetRange("Company Name", CompanyName());
        OnboardingSignal.SetRange("Onboarding Completed", false);
        OnboardingSignal.SetFilter("Onboarding Signal Type", CreateFilterForValidEnum());

        if OnboardingSignal.FindSet() then
            repeat
                OnboardingSignalProvider := OnboardingSignal."Onboarding Signal Type";

                if OnboardingSignalProvider.IsOnboarded() then begin
                    OnboardingSignal."Onboarding Completed" := true;
                    OnboardingSignal."Onboarding Complete Date" := Today();
                    OnboardingSignal.Modify();

                    AddOnboardingSignalDimensions(OnboardingSignal, CustomDimensions);

                    Telemetry.LogMessage('0000EIV', 'Onboarding Signal Completed: ' + Format(OnboardingSignal."Onboarding Signal Type"), Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, CustomDimensions);
                end;
            until OnboardingSignal.Next() = 0;
    end;

    /// <summary>
    /// Check if a company has onboarded
    /// </summary>
    /// <param name="CompanyName"> The Company's name to check. </param>
    /// <returns> True if all the signals for the current company has completed, except for the Company Signal </returns>
    procedure HasCompanyOnboarded(CompanyName: Text): Boolean
    var
        OnboardingSignal: Record "Onboarding Signal";
        OnboardingSignalType: Enum "Onboarding Signal Type";
    begin
        OnboardingSignal.SetRange("Company Name", CompanyName);
        OnboardingSignal.SetRange("Onboarding Signal Type", OnboardingSignalType::Company);

        if OnboardingSignal."Onboarding Completed" then
            exit(true)
        else begin
            OnboardingSignal.Reset();
            OnboardingSignal.SetRange("Company Name", CompanyName);
            OnboardingSignal.SetFilter("Onboarding Signal Type", '<>%1', OnboardingSignalType::Company);
            OnboardingSignal.SetRange("Onboarding Completed", false);

            exit(OnboardingSignal.IsEmpty());
        end;
    end;

    /// <summary>
    /// Get all Onboarding Signals with Read access
    /// </summary>
    /// <param name="OnboardingSignalBuffer"> The variable holds all the onboarding signals </param>
    procedure GetOnboardingSignals(var OnboardingSignalBuffer: Record "Onboarding Signal Buffer" temporary)
    var
        OnboardingSignal: Record "Onboarding Signal";
    begin
        OnboardingSignalBuffer.DeleteAll();

        if OnboardingSignal.FindSet() then
            repeat
                OnboardingSignalBuffer.TransferFields(OnboardingSignal);
                OnboardingSignalBuffer.Insert();
            until OnboardingSignal.Next() = 0;
    end;

    /// <summary>
    /// Create a filter for all valid Enum Onboarding Signal Types.
    /// This is needed to filter out Enum values that no longer exist in the current runtime (e.g. extensions that are uninstalled).
    /// </summary>
    local procedure CreateFilterForValidEnum() FilterText: Text
    var
        OnboardingSignalType: Enum "Onboarding Signal Type";
    begin
        foreach OnboardingSignalType in Enum::"Onboarding Signal Type".Ordinals() do
            FilterText += Format(OnboardingSignalType) + '|';
        FilterText := FilterText.TrimEnd('|');
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteCompany(Rec: Record Company)
    var
        OnboardingSignal: Record "Onboarding Signal";
    begin
        OnboardingSignal.SetRange("Company Name", Rec.Name);

        if not OnboardingSignal.IsEmpty() then
            OnboardingSignal.DeleteAll();
    end;

    local procedure AddOnboardingSignalDimensions(OnboardingSignal: Record "Onboarding Signal"; var CustomDimensions: Dictionary of [Text, Text])
    begin
        CustomDimensions.Set('StartDate', Format(OnboardingSignal."Onboarding Start Date", 10, 9));
        CustomDimensions.Set('CompleteDate', Format(OnboardingSignal."Onboarding Complete Date", 10, 9));
        CustomDimensions.Set('CriteriaName', Format(OnboardingSignal."Onboarding Signal Type"));
        CustomDimensions.Set('CriteriaId', Format(OnboardingSignal."Onboarding Signal Type".AsInteger()));
        CustomDimensions.Set('RegisterExtensionId', Format(OnboardingSignal."Extension ID"));
    end;
}
