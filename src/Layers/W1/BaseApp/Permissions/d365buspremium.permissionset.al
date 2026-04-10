namespace System.Security.AccessControl;

permissionset 4716 "D365 BUS PREMIUM"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dyn. 365 Prem. Bus. Full Acc.';

    IncludedPermissionSets = "D365 BUS FULL ACCESS",
                             "D365PREM MFG, EDIT",
                             "D365PREM SMG, EDIT",
                             "D365PREM SMG, SETUP";
}
