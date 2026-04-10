namespace System.Feedback;


enum 7580 "Onboarding Signal Type" implements "Onboarding Signal"
{
    Access = Public;
    Caption = 'Onboarding Signal Type';
    Extensible = true;

    value(4; Company)
    {
        Implementation = "Onboarding Signal" = "Company Signal";
    }
}
