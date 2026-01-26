#pragma warning disable AA0247
#if not CLEAN26
codeunit 104152 "UPG.VAT Report IT"
{
    Subtype = Upgrade;

    ObsoleteReason = 'Field "Tax Auth. Doc. No."has been deleted in version 22.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    procedure UpgradeVATReportHeader();
    begin
    end;
}

#endif
