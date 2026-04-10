namespace System.Security.AccessControl;

pageextension 9871 "BaseApp Security Groups" extends "Security Groups"
{
    actions
    {
        addafter(SecurityGroupPermissionSets)
        {
            action(PagePermissionSetBySecurityGroup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Permission Set by Security Group';
                Image = Permission;
                RunObject = Page "Permission Set By Sec. Group";
                ToolTip = 'View or edit the available permission sets and apply permission sets to existing security groups.';
                Enabled = AreRecordsPresent;
            }
        }
        addafter(SecurityGroupPermissionSets_Promoted)
        {
            group(Category_Permissions)
            {
                Caption = 'Permissions';
                ShowAs = SplitButton;

                actionref(SecurityGroupPermissions_Promoted; SecurityGroupPermissionSets)
                {
                }

                actionref(PagePermissionSetBySecurityGroup_Promoted; PagePermissionSetBySecurityGroup)
                {
                }
            }
        }
        modify(SecurityGroupPermissionSets_Promoted)
        {
            Visible = false;
        }
        modify(NewSecurityGroup)
        {
            trigger OnAfterAction()
            var
                BaseAppSecurityGroupImpl: Codeunit "BaseApp Security Group Impl.";
            begin
                BaseAppSecurityGroupImpl.SendLicenseConfigurationNotificationOnFirstRecord(Rec);
            end;
        }
    }
}