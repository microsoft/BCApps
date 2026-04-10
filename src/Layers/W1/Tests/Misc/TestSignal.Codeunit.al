codeunit 139324 "Test Signal" implements "Onboarding Signal"
{
    Access = Internal;

    procedure IsOnboarded(): Boolean
    begin
        exit(true);
    end;
}