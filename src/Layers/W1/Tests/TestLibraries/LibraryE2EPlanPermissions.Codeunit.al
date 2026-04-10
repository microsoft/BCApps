codeunit 132230 "Library - E2E Plan Permissions"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        PlanIds: Codeunit "Plan Ids";

    local procedure SetProfileID(ProfileID: Code[30])
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        AllProfile.SetRange("Profile ID", ProfileID);
        AllProfile.FindFirst();
        ConfPersonalizationMgt.SetCurrentProfile(AllProfile);
        Commit();
    end;

    procedure SetTeamMemberPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetProfileID('TEAM MEMBER');
        SetUserPlan(PlanIds.GetTeamMemberPlanId());
        SetPlanPermissions(PlanIds.GetTeamMemberPlanId());
        Commit();
    end;

    procedure SetExternalAccountantPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetProfileID('ACCOUNTANT');
        SetUserPlan(PlanIds.GetExternalAccountantPlanId());
        SetPlanPermissions(PlanIds.GetExternalAccountantPlanId());
        Commit();
    end;

    procedure SetBusinessManagerPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetEssentialPlanId());
        SetPlanPermissions(PlanIds.GetEssentialPlanId());
        Commit();
    end;

    procedure SetPremiumUserPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetPremiumPlanId());
        SetPlanPermissions(PlanIds.GetPremiumPlanId());
        Commit();
    end;

    procedure SetTeamMemberISVEmbPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetProfileID('TEAM MEMBER');
        SetUserPlan(PlanIds.GetTeamMemberISVPlanId());
        SetPlanPermissions(PlanIds.GetTeamMemberISVPlanId());
        Commit();
    end;

    procedure SetEssentialISVEmbUserPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetEssentialISVPlanId());
        SetPlanPermissions(PlanIds.GetEssentialISVPlanId());
        Commit();
    end;

    procedure SetPremiumISVEmbUserPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetPremiumISVPlanId());
        SetPlanPermissions(PlanIds.GetPremiumISVPlanId());
        Commit();
    end;

    procedure SetDeviceISVEmbUserPlan()
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetDeviceISVPlanId());
        SetPlanPermissions(PlanIds.GetDeviceISVPlanId());
        Commit();
    end;

    local procedure SetUserPlan(PlanID: Text[50])
    var
        AzureADPlan: Codeunit "Azure AD Plan";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
    begin
        if AzureADPlan.IsPlanAssignedToUser(PlanID, UserSecurityId()) then
            exit;

        if AzureADPlan.DoesUserHavePlans(UserSecurityId()) then
            AzureADPlanTestLibrary.ReassignPlanToUser(UserSecurityId(), PlanID)
        else
            AzureADPlanTestLibrary.AssignUserToPlan(UserSecurityId(), PlanID);
    end;

    procedure SetViralSignupPlan()
    var
        PlanIds: Codeunit "Plan Ids";
    begin
        LibraryLowerPermissions.SetOutsideO365Scope();
        SetProfileID('BUSINESS MANAGER');
        SetUserPlan(PlanIds.GetViralSignupPlanId());
        SetPlanPermissions(PlanIds.GetViralSignupPlanId());
    end;

    local procedure SetPlanPermissions(PlanID: Guid)
    var
        PlanConfiguration: Codeunit "Plan Configuration";
        PermissionSetInPlanBuffer: Record "Permission Set In Plan Buffer";
    begin
        PlanConfiguration.GetDefaultPermissions(PermissionSetInPlanBuffer);
        PermissionSetInPlanBuffer.SetRange("Plan ID", PlanID);
        if PermissionSetInPlanBuffer.FindSet() then begin
                LibraryLowerPermissions.PushPermissionSet(PermissionSetInPlanBuffer."Role ID");
            while PermissionSetInPlanBuffer.Next() > 0 do
                LibraryLowerPermissions.AddPermissionSet(PermissionSetInPlanBuffer."Role ID")
        end;
    end;
}

