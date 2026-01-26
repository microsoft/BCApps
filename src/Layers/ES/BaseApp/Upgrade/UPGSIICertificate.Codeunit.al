#pragma warning disable AA0247
#if not CLEAN26
codeunit 104103 "UPG SII Certificate"
{
    Subtype = Upgrade;
    ObsoleteReason = 'Certificate field on "SII Setup" has been deleted.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';
}

#endif
