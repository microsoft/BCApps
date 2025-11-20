namespace System.Feedback;

using System.Environment;
using Microsoft.Foundation.Company;

codeunit 7582 "Register Company Signal"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        RegisterCompanySignal();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitialize()
    begin
        RegisterCompanySignal();
    end;

    local procedure RegisterCompanySignal()
    var
        Company: Record Company;
        OnboardingSignal: Codeunit "Onboarding Signal";
        EnvironmentInformation: Codeunit "Environment Information";
        OnboardingSignalType: Enum "Onboarding Signal Type";
    begin
        if not Company.Get(CompanyName()) then
            exit;

        if Company."Evaluation Company" then
            exit;

        if EnvironmentInformation.IsSandbox() then
            exit;

        OnboardingSignal.RegisterNewOnboardingSignal(Company.Name, OnboardingSignalType::Company);
    end;
}