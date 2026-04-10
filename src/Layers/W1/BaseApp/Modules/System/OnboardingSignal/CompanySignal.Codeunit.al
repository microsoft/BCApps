namespace System.Feedback;


codeunit 7581 "Company Signal" implements "Onboarding Signal"
{
    Access = Internal;
    Description = 'A special signal to track if all signals for the company has completed.';

    procedure IsOnboarded(): Boolean
    var
        OnboardingSignal: Codeunit "Onboarding Signal";
    begin
        exit(OnboardingSignal.HasCompanyOnboarded(CompanyName()));
    end;
}