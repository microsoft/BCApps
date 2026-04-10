codeunit 135417 "Experience Tier Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        NewRoleIdLbl: Label 'TEST SET', Locked = true;
        NewNameLbl: Label 'Test Set', Locked = true;
        CannotInsertErr: Label 'You cannot insert into table %1. Premium features are blocked since you are accessing a non-premium company.', Locked = true;
        BusFullAccessRoleIdTok: Label 'D365 BUS FULL ACCESS';
        BusPremiumRoleIdTok: Label 'D365 BUS PREMIUM';
        NullGuid: Guid;

    [Test]
    [Scope('OnPrem')]
    procedure TestPremiumPermissionsAreAddedToExperienceTier()
    var
        TempExclusivePremiumExpandedPermissions: Record "Expanded Permission" temporary;
        ServiceExperienceTier: Codeunit "Service Experience Tier";
        MfgExperienceTier: Codeunit "Mfg. Experience Tier";
    begin
        // This test verifies that all table permissions in the D365 BUS PREMIUM permission set also has subscribers in codeunit 257 "Experience Tier"
        // If this test fails, it means you added a new table that is for the premium license only, but you did not add a subscriber in the experience tier codeunit.
        // Solution: Add an OnBeforeInsertEvent subscriber in codeunit 257 "Experience Tier".
        GetExclusivePremiumTablePermissions(TempExclusivePremiumExpandedPermissions);

        BindSubscription(MfgExperienceTier);
        BindSubscription(ServiceExperienceTier);

        TempExclusivePremiumExpandedPermissions.FindSet();
        repeat
            if TempExclusivePremiumExpandedPermissions."Insert Permission" <> TempExclusivePremiumExpandedPermissions."Insert Permission"::" " then
                VerifyErrorOnInsert(TempExclusivePremiumExpandedPermissions."Object ID");
        until TempExclusivePremiumExpandedPermissions.Next() = 0;

        UnbindSubscription(ServiceExperienceTier);
        UnbindSubscription(MfgExperienceTier);
    end;

    local procedure GetExclusivePremiumTablePermissions(var TempExpandedPermission: Record "Expanded Permission" temporary)
    var
        ExpandedPermission: Record "Expanded Permission";
        AggregatePermissionSet: Record "Aggregate Permission Set";
        TenantPermissionSet: Record "Tenant Permission Set";
        PermissionSetRelation: Codeunit "Permission Set Relation";
        PermissionSetCopyType: Enum "Permission Set Copy Type";
        PermissionType: Option Include,Exclude;
    begin
        TenantPermissionSet.SetRange("Role ID", NewRoleIdLbl);
        TenantPermissionSet.DeleteAll();

        // Copy PREMIUM
        AggregatePermissionSet.SetRange("Role ID", BusPremiumRoleIdTok);
        Assert.IsTrue(AggregatePermissionSet.FindFirst(), 'D365 BUS FULL permission set not found');
        PermissionSetRelation.CopyPermissionSet(NewRoleIdLbl, NewNameLbl, AggregatePermissionSet."Role ID", AggregatePermissionSet."App ID", AggregatePermissionSet.Scope, PermissionSetCopyType::Reference);

        // Exclude BUS FULL
        AggregatePermissionSet.SetRange("Role ID", BusFullAccessRoleIdTok);
        Assert.IsTrue(AggregatePermissionSet.FindFirst(), 'D365 BUS FULL ACCESS permission set not found');
        PermissionSetRelation.AddNewPermissionSetRelation(NullGuid, NewRoleIdLbl, AggregatePermissionSet.Scope::Tenant, AggregatePermissionSet."App ID", AggregatePermissionSet."Role ID", AggregatePermissionSet.Scope, PermissionType::Exclude);

        // Copy all exclusive PREMIUM table permissions
        ExpandedPermission.SetRange("Role ID", NewRoleIdLbl);
        ExpandedPermission.SetRange("Object Type", ExpandedPermission."Object Type"::"Table Data");
        if ExpandedPermission.FindSet() then
            repeat
                TempExpandedPermission := ExpandedPermission;
                TempExpandedPermission.Insert();
            until ExpandedPermission.Next() = 0;
        TempExpandedPermission.Reset();
    end;

    local procedure VerifyErrorOnInsert(TableNo: Integer)
    var
        RecordRef: RecordRef;
    begin
        RecordRef.Open(TableNo);

        asserterror RecordRef.Insert();

        Assert.ExpectedError(StrSubstNo(CannotInsertErr, RecordRef.Caption()));
    end;
}