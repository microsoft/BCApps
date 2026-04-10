codeunit 135416 "Premium Plans Activ Plan-based"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Plan] [Premium]
    end;

    var
        LibraryE2EPlanPermissions: Codeunit "Library - E2E Plan Permissions";
        PremiumIsNotEnabledErr: Label '%1 is not enabled as Premium.', Locked = true;
        NonPremiumAsPremiumErr: Label '%1 is enabled as Premium.', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure TestPremiumPlanIsEnabledForPremiums()
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        // [SCENARIO] Set Premium Plan and check IsPremiumEnabled for it

        LibraryE2EPlanPermissions.SetPremiumUserPlan();

        if not ApplicationAreaMgmt.IsPremiumEnabled() then
            Error(PremiumIsNotEnabledErr, 'Premium User Plan');

        LibraryE2EPlanPermissions.SetPremiumISVEmbUserPlan();

        if not ApplicationAreaMgmt.IsPremiumEnabled() then
            Error(PremiumIsNotEnabledErr, 'Premium ISV Embedded User Plan');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPremiumPlanIsEnabledForNonPremiums()
    var
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
    begin
        // [SCENARIO] Set non Premium Plan and check IsPremiumEnabled for it

        LibraryE2EPlanPermissions.SetBusinessManagerPlan();

        if ApplicationAreaMgmt.IsPremiumEnabled() then
            Error(NonPremiumAsPremiumErr, 'Essential Plan');

        LibraryE2EPlanPermissions.SetExternalAccountantPlan();

        if ApplicationAreaMgmt.IsPremiumEnabled() then
            Error(NonPremiumAsPremiumErr, 'External Accountant Plan');

        LibraryE2EPlanPermissions.SetTeamMemberPlan();

        if ApplicationAreaMgmt.IsPremiumEnabled() then
            Error(NonPremiumAsPremiumErr, 'Team Member Plan');

        LibraryE2EPlanPermissions.SetEssentialISVEmbUserPlan();

        if ApplicationAreaMgmt.IsPremiumEnabled() then
            Error(NonPremiumAsPremiumErr, 'Essential ISV Embedded Plan');

        LibraryE2EPlanPermissions.SetTeamMemberISVEmbPlan();

        if ApplicationAreaMgmt.IsPremiumEnabled() then
            Error(NonPremiumAsPremiumErr, 'Team Member ISV Embedded Plan');
    end;
}

