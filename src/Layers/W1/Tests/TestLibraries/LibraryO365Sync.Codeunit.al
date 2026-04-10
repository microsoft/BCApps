codeunit 131013 "Library - O365 Sync"
{

    trigger OnRun()
    begin
    end;

    var
        AuthenticationEmailTxt: Label 'navtest@M365B409112.onmicrosoft.com';
        User: Record User;

    procedure SetupNavUser()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        // Sets up the user if it doesn't exist (e.g. we're using Windows Auth and have no users defined)
        User.SetRange("User Name", UserId);
        if not User.FindFirst() then begin
            User.Init();
            User."User Security ID" := CreateGuid();
            User."User Name" := UserId;
            User."Full Name" := User."User Name";
            if not EnvironmentInformation.IsSaaSInfrastructure() then
                User."Windows Security ID" := Sid(User."User Name");
            User.Insert(true);
        end;

        User."Authentication Email" := AuthenticationEmailTxt;
        User.Modify(true);
    end;
}

