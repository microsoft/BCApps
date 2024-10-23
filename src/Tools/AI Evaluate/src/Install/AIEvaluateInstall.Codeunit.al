codeunit 50010 "AI Evaluate Install"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;
    Access = Internal;

    trigger OnInstallAppPerDatabase()
    var
        AIEvaluateImpl: Codeunit "AI Evaluate Impl.";
    begin
        AIEvaluateImpl.RegisterCapability();
    end;
}