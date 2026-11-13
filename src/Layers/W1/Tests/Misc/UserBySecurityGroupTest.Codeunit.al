codeunit 139495 UserBySecurityGroupTest
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryUtility: Codeunit "Library - Utility";
        AzureADGraphTestLibrary: Codeunit "Azure AD Graph Test Library";
        SecurityGroupsTestLibrary: Codeunit "Security Groups Test Library";
        MockGraphQueryTestLibrary: Codeunit "MockGraphQuery Test Library";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Assert: Codeunit Assert;

    [Test]
    procedure UserBySecurityGroupFilterByUserAndGroup()
    var
        GraphUser: array[2] of Record User;
        TempSecurityGroupBuffer: array[2] of Record "Security Group Buffer";
        UserBySecurityGroup: TestPage "User by Security Group";
    begin
        // [SCENARIO] User by Security Group filters correctly by user and group
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        AssertUserBySecurityGroupColumnCount();

        // [GIVEN] Two users and security groups
        CreateGraphUserAndGroup(GraphUser[1], TempSecurityGroupBuffer[1]);
        CreateGraphUserAndGroup(GraphUser[2], TempSecurityGroupBuffer[2]);

        UserBySecurityGroup.OpenEdit();

        // [WHEN] The user and group filters are applied
        UserBySecurityGroup.UserFilter.SetValue(GraphUser[1]."User Name");
        UserBySecurityGroup.SecurityGroupFilter.SetValue(TempSecurityGroupBuffer[1].Code);

        // [THEN] Only the filtered user is displayed
        Assert.IsTrue(UserBySecurityGroup.First(), 'The filtered user should be displayed.');
        Assert.IsFalse(UserBySecurityGroup.Next(), 'No other users should be displayed.');
        UserBySecurityGroup."User Name".AssertEquals(GraphUser[1]."User Name");

        // [THEN] Only the filtered security group is displayed
        Assert.AreEqual(TempSecurityGroupBuffer[1].Code, UserBySecurityGroup.IsSecurityGroupMember1.Caption(), 'The filtered security group code should be the 1st column caption.');
        UserBySecurityGroup.IsSecurityGroupMember1.AssertEquals(true);
        UserBySecurityGroup.IsSecurityGroupMember2.AssertEquals(false);
        UserBySecurityGroup.IsSecurityGroupMember3.AssertEquals(false);
        UserBySecurityGroup.IsSecurityGroupMember4.AssertEquals(false);
        UserBySecurityGroup.IsSecurityGroupMember5.AssertEquals(false);
        UserBySecurityGroup.IsSecurityGroupMember6.AssertEquals(false);
        UserBySecurityGroup.IsSecurityGroupMember7.AssertEquals(false);
        UserBySecurityGroup.IsSecurityGroupMember8.AssertEquals(false);
        UserBySecurityGroup.IsSecurityGroupMember9.AssertEquals(false);
        UserBySecurityGroup.IsSecurityGroupMember10.AssertEquals(false);
    end;

    [Test]
    procedure UserBySecurityGroupShiftColumn()
    var
        GraphUser: Record User;
        TempSecurityGroupBuffer, TempSecurityGroupBufferCopy : Record "Security Group Buffer";
        UserBySecurityGroupPage: Page "User by Security Group";
        UserBySecurityGroup: TestPage "User by Security Group";
        i: Integer;
    begin
        // [SCENARIO] When number of security groups exceeds the visible columns, shifting left and right correctly pages between the groups on the user by security group page
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        Initialize();
        AssertUserBySecurityGroupColumnCount();

        // [GIVEN] A set of security groups exceeding the visible columns by one
        CreateGraphUserAndGroup(GraphUser, TempSecurityGroupBuffer);
        TempSecurityGroupBufferCopy := TempSecurityGroupBuffer;
        TempSecurityGroupBufferCopy.Insert();
        for i := 2 to UserBySecurityGroupPage.GetColumnCount() + 1 do begin
            CreateSecurityGroup(TempSecurityGroupBuffer);
            TempSecurityGroupBufferCopy := TempSecurityGroupBuffer;
            TempSecurityGroupBufferCopy.Insert();
        end;

        // [WHEN] The user by security group page is opened
        UserBySecurityGroup.OpenEdit();

        // [THEN] The visible column correctly accounts for all by one of the security groups
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember1.Caption(), TempSecurityGroupBuffer);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember2.Caption(), TempSecurityGroupBuffer);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember3.Caption(), TempSecurityGroupBuffer);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember4.Caption(), TempSecurityGroupBuffer);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember5.Caption(), TempSecurityGroupBuffer);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember6.Caption(), TempSecurityGroupBuffer);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember7.Caption(), TempSecurityGroupBuffer);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember8.Caption(), TempSecurityGroupBuffer);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember9.Caption(), TempSecurityGroupBuffer);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember10.Caption(), TempSecurityGroupBuffer);
        Assert.AreEqual(1, TempSecurityGroupBuffer.Count, 'Expected 1 unaccounted security group after the first set');
        TempSecurityGroupBufferCopy := TempSecurityGroupBuffer;
        TempSecurityGroupBufferCopy.Delete();

        // [WHEN] All columns are shifted to the right
        UserBySecurityGroup.NextSet.Invoke();

        // [THEN] The first column shows the last unaccounted for security group, with the remaining columns blank
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember1.Caption(), TempSecurityGroupBuffer);
        AssertBlankCaption(UserBySecurityGroup.IsSecurityGroupMember2.Caption());
        AssertBlankCaption(UserBySecurityGroup.IsSecurityGroupMember3.Caption());
        AssertBlankCaption(UserBySecurityGroup.IsSecurityGroupMember4.Caption());
        AssertBlankCaption(UserBySecurityGroup.IsSecurityGroupMember5.Caption());
        AssertBlankCaption(UserBySecurityGroup.IsSecurityGroupMember6.Caption());
        AssertBlankCaption(UserBySecurityGroup.IsSecurityGroupMember7.Caption());
        AssertBlankCaption(UserBySecurityGroup.IsSecurityGroupMember8.Caption());
        AssertBlankCaption(UserBySecurityGroup.IsSecurityGroupMember9.Caption());
        AssertBlankCaption(UserBySecurityGroup.IsSecurityGroupMember10.Caption());

        // [WHEN] All columns are shifted back to the left
        UserBySecurityGroup.PreviousSet.Invoke();

        // [THEN] Then same set of security groups is displayed as before the shift right
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember1.Caption(), TempSecurityGroupBufferCopy);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember2.Caption(), TempSecurityGroupBufferCopy);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember3.Caption(), TempSecurityGroupBufferCopy);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember4.Caption(), TempSecurityGroupBufferCopy);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember5.Caption(), TempSecurityGroupBufferCopy);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember6.Caption(), TempSecurityGroupBufferCopy);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember7.Caption(), TempSecurityGroupBufferCopy);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember8.Caption(), TempSecurityGroupBufferCopy);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember9.Caption(), TempSecurityGroupBufferCopy);
        AssertSecurityGroupCaption(UserBySecurityGroup.IsSecurityGroupMember10.Caption(), TempSecurityGroupBufferCopy);
        Assert.AreEqual(0, TempSecurityGroupBufferCopy.Count, 'All security group should be accounted for after shift left.');
    end;

    local procedure AssertSecurityGroupCaption(Caption: Text; var SecurityGroupBuffer: Record "Security Group Buffer")
    var
        Found: Boolean;
    begin
        Assert.IsTrue(SecurityGroupBuffer.FindSet(), 'No security group records found.');
        repeat
            Found := SecurityGroupBuffer.Code = Caption;
            if Found then
                SecurityGroupBuffer.Delete();
        until (SecurityGroupBuffer.Next() = 0) or Found;
        Assert.IsTrue(Found, 'Unexpected security group caption ' + Caption);
    end;

    local procedure AssertBlankCaption(Caption: Text)
    begin
        Assert.AreEqual('', Caption, 'Expected blank caption.');
    end;

    local procedure Initialize()
    var
        TempSecurityGroupBuffer: Record "Security Group Buffer";
        SecurityGroup: Codeunit "Security Group";
    begin
        Clear(AzureADGraphTestLibrary);
        Clear(SecurityGroupsTestLibrary);
        Clear(MockGraphQueryTestLibrary);

        BindSubscription(SecurityGroupsTestLibrary);
        MockGraphQueryTestLibrary.SetupMockGraphQuery();
        AzureADGraphTestLibrary.SetMockGraphQuery(MockGraphQueryTestLibrary);
        BindSubscription(AzureADGraphTestLibrary);

        SecurityGroup.GetGroups(TempSecurityGroupBuffer);
        if TempSecurityGroupBuffer.FindSet() then
            repeat
                SecurityGroup.Delete(TempSecurityGroupBuffer.Code);
            until TempSecurityGroupBuffer.Next() = 0;
    end;

    local procedure AssertUserBySecurityGroupColumnCount()
    var
        TempSecurityGroupBuffer: Record "Security Group Buffer";
        SecurityGroup: Codeunit "Security Group";
        UserBySecurityGroup: Page "User by Security Group";
    begin
        Assert.AreEqual(10, UserBySecurityGroup.GetColumnCount(), 'Unexpected number of columns for this test.');
        SecurityGroup.GetGroups(TempSecurityGroupBuffer);
        Assert.AreEqual(0, TempSecurityGroupBuffer.Count(), 'Expected no security groups initially.');
    end;

    local procedure CreateGraphUserAndGroup(
        var GraphUser: Record User;
        var SecurityGroupBuffer: Record "Security Group Buffer")
    var
        UserInfo: DotNet UserInfo;
    begin
        CreateSecurityGroup(SecurityGroupBuffer);
        CreateUser(UserInfo, GraphUser."User Security ID");

        GraphUser.Reset();
        GraphUser.SetRange("User Security ID", GraphUser."User Security ID");
        GraphUser.FindFirst();

        MockGraphQueryTestLibrary.AddGraphUserToGroup(UserInfo, SecurityGroupBuffer."Group Name", SecurityGroupBuffer."Group ID");
    end;

    local procedure CreateSecurityGroup(var SecurityGroupBuffer: Record "Security Group Buffer")
    var
        SecurityGroup: Codeunit "Security Group";
    begin
        SecurityGroupBuffer.Code := LibraryUtility.GenerateRandomCode(SecurityGroupBuffer.FieldNo(Code), Database::"Security Group Buffer");
        SecurityGroupBuffer."Group Name" := SecurityGroupBuffer.Code;
        SecurityGroupBuffer."Group ID" := CreateGuid();
        SecurityGroupBuffer.Insert();
        MockGraphQueryTestLibrary.AddGroup(SecurityGroupBuffer."Group Name", SecurityGroupBuffer."Group ID");
        SecurityGroup.Create(SecurityGroupBuffer.Code, SecurityGroupBuffer."Group ID");
    end;

    local procedure CreateUser(var GraphUser: DotNet UserInfo; var UserSecId: Guid)
    var
        User: Record User;
        NavUserAccountHelper: DotNet NavUserAccountHelper;
    begin
        UserSecId := CreateGuid();
        MockGraphQueryTestLibrary.AddAndReturnGraphUser(GraphUser, CreateGuid(), '', '', '');
        User."User Security ID" := UserSecId;
        User."User Name" := Format(UserSecId);
        User.Insert();
        NavUserAccountHelper.SetAuthenticationObjectId(UserSecId, GraphUser.ObjectId);
    end;
}