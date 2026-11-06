#pragma warning disable AA0247
#if not CLEAN30
#pragma warning disable AA0247
codeunit 104155 "Upgrade CFDI RFC Number"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteReason = 'Obsolete schema migration code has been removed.';
    ObsoleteTag = '30.0';

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
    end;
}
#endif
