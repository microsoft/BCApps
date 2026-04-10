codeunit 135800 "User List Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        User001Tok: Label 'User001';
        User002Tok: Label 'User002';

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsYes')]
    procedure PlansVisibleInUserListTest()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PlanIds: Codeunit "Plan Ids";
        Users: TestPage "Users";
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        User: Record User;
    begin
        // [SCENARIO] User plans are visible on user card
        CreateUser(User001Tok);
        CreateUser(User002Tok);

        // [GIVEN] A system setup as SaaS solution
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] The User has assigned some plans
        User.SetRange("User Name", User002Tok);
        User.FindFirst();

        AzureADPlanTestLibrary.AssignUserToPlan(User."User Security ID", PlanIds.GetBasicPlanId());

        User.SetRange("User Name", User001Tok);
        User.FindFirst();

        AzureADPlanTestLibrary.AssignUserToPlan(User."User Security ID", PlanIds.GetEssentialPlanId());
        AzureADPlanTestLibrary.AssignUserToPlan(User."User Security ID", PlanIds.GetExternalAccountantPlanId());

        // [THEN] The Plans are visible 
        Users.OpenView();
        Users.GoToRecord(User);

        Assert.IsTrue(Users.Plans.First(), 'The plans in User card are not visible.');
        Assert.IsTrue(Users.Plans.Name.Visible(), 'The plans in User card are not visible.');
        Assert.IsTrue(Users.Plans.Next(), 'The plans in User card are not visible.');
        Assert.IsFalse(Users.Plans.Next(), 'More plans than expected are visible in User card.');

        Users.Close();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerAnsYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure CreateUser(UserName: Text)
    var
        User: Record User;
        UserCardPage: TestPage "User Card";
    begin
        User.SetRange("User Name", UserName);
        if User.FindFirst() then
            exit;

        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := UserName;
        UserCardPage.Close();
        Commit();
    end;

}