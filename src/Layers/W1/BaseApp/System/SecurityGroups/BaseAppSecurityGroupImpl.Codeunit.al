namespace System.Security.AccessControl;

using System.Azure.Identity;
using System.Environment;

codeunit 9873 "BaseApp Security Group Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        NotificationIdLbl: Label 'be01c53d-4e90-422a-aea8-b00cee30f950', Locked = true;
        OpenLicenseConfigurationTok: Label 'Open License Configuration', Comment = 'License Configuration is the name of the page in BC';
        LicenseConfigurationNotificationTxt: Label 'New users who are members of security groups will also get permissions associated with their license. If you want to only use Security Groups for controlling permissions of new users, you need to clear the license configurations.';

    procedure SendLicenseConfigurationNotificationOnFirstRecord(var SecurityGroupBuffer: Record "Security Group Buffer")
    var
        LocalSecurityGroupBuffer: Record "Security Group Buffer";
        PermissionSetInPlanBuffer: Record "Permission Set In Plan Buffer";
        EnvironmentInformation: Codeunit "Environment Information";
        PlanConfiguration: Codeunit "Plan Configuration";
        LicenseConfigurationNotification: Notification;
    begin
        if not EnvironmentInformation.IsSaaS() then
            exit;

        // Check that it's the first security group being added
        LocalSecurityGroupBuffer.Copy(SecurityGroupBuffer, true);
        LocalSecurityGroupBuffer.Reset();
        if LocalSecurityGroupBuffer.Count() <> 1 then
            exit;

        // Check that there is a default a custom license configuration defined
        PlanConfiguration.GetDefaultPermissions(PermissionSetInPlanBuffer);
        if PermissionSetInPlanBuffer.IsEmpty() then begin
            PlanConfiguration.GetCustomPermissions(PermissionSetInPlanBuffer);
            if PermissionSetInPlanBuffer.IsEmpty() then
                exit;
        end;

        // Send the notification
        LicenseConfigurationNotification.Id := NotificationIdLbl;
        LicenseConfigurationNotification.Scope := NotificationScope::LocalScope;
        LicenseConfigurationNotification.Message(LicenseConfigurationNotificationTxt);
        LicenseConfigurationNotification.AddAction(OpenLicenseConfigurationTok, Codeunit::"BaseApp Security Group Impl.", 'OpenLicenseConfiguration');
        LicenseConfigurationNotification.Send();
    end;

    procedure OpenLicenseConfiguration(Notification: Notification)
    var
        PlanConfigurationList: Page "Plan Configuration List";
    begin
        PlanConfigurationList.Run();
    end;
}