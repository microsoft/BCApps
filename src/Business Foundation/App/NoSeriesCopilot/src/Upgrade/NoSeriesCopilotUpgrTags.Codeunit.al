codeunit 328 "No. Series Copilot Upgr. Tags"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetImplementationUpgradeTag(): Code[250]
    begin
        exit('MS-659-AddImplementationExtensibility-20240304 '); //659 is the id of the issue https://github.com/microsoft/BCApps/issues/659
    end;
}
