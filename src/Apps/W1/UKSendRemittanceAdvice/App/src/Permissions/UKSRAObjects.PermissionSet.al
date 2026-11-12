namespace Microsoft.Purchases.Vendor.RemittanceAdvice;

#if not CLEAN29
permissionset 4022 "UKSRA - Objects"
{
    Assignable = false;
    Access = Public;
    Caption = 'UK Send Remittance Advice - Objects';
    ObsoleteReason = 'SetupRemittanceReports codeunit is obsoleted - report selection setup for V.Remittance and P.V.Remit. is now seeded by Microsoft.Foundation.Reporting."Report Selection Mgt.".InitReportSelectionPurch, called from CompanyInitialize.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';

    Permissions = codeunit SetupRemittanceReports = X;
}
#endif