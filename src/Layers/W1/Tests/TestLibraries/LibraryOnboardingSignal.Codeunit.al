// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 131017 "Library - Onboarding Signal"
{
    Access = Public;
    Permissions = tabledata "Onboarding Signal" = rd;

    /// <summary>
    /// Instead of checking the criteria for the entry, this procedure checks if the entry has been set to onboarding completed.
    /// </summary>
    /// <param name="CompanyName"></param>
    /// <param name="OnboardingSignalType"></param>
    /// <returns>True if field "Onboarding Completed" has been set to True </returns>
    procedure IsOnboardingCompleted(CompanyName: Text[30]; OnboardingSignalType: Enum "Onboarding Signal Type"): Boolean
    var
        OnboardingSignal: Record "Onboarding Signal";
    begin
        OnboardingSignal.SetRange("Company Name", CompanyName);
        OnboardingSignal.SetRange("Onboarding Signal Type", OnboardingSignalType);

        if OnboardingSignal.FindFirst() then
            exit(OnboardingSignal."Onboarding Completed");

        exit(false);
    end;

    /// <summary>
    /// Initialize onboarding signal testing environment:
    /// 1. setting "Evaluation Comany" to False
    /// 2. setting testing environment to SaaS
    /// 3. setting testing ClientType to Web
    /// 4. reset OnboardingSignal table to empty
    /// </summary>
    procedure InitializeOnboardingSignalTestingEnv()
    var
        OnboardingSignal: Record "Onboarding Signal";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        TestClientTypeSubscriber: Codeunit "Test Client Type Subscriber";
    begin
        SetEvaluationPropertyForCompany(false);
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        TestClientTypeSubscriber.SetClientType(ClientType::Web);

        OnboardingSignal.Reset();
        OnboardingSignal.DeleteAll();
    end;

    local procedure SetEvaluationPropertyForCompany(IsEvaluationCompany: Boolean)
    var
        Company: Record Company;
    begin
        Company.Get(CompanyName());

        Company."Evaluation Company" := IsEvaluationCompany;
        Company.Modify();
    end;
}