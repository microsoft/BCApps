codeunit 130617 "Create Users for Tests"
{

    trigger OnRun()
    var
        UsersCreateSuperUser: Codeunit "Users - Create Super User";
        WindowsIdentity: DotNet "System.Security.Principal.WindowsIdentity";
        SecurityIdentifier: DotNet "System.Security.Principal.SecurityIdentifier";
        WidowsUserID: Code[50];
        WindowsSID: Text[119];
    begin
        WindowsIdentity := WindowsIdentity.GetCurrent();
        WidowsUserID := WindowsIdentity.Name;
        SecurityIdentifier := WindowsIdentity.User;
        WindowsSID := SecurityIdentifier.ToString();

        // Create Windows Network User
        UsersCreateSuperUser.SafeCreateUser(WidowsUserID, WindowsSID);

        // Create Local User
        UsersCreateSuperUser.SafeCreateUser(UserId, Sid());
    end;
}

