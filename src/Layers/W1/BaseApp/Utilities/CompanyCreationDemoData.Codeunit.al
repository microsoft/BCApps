// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 9192 "Company Creation Demo Data"
{
    Access = Internal;

    procedure CheckDemoDataAppsAvailability()
    var
        MissingDemoAppsErr: ErrorInfo;
    begin
        // Check if Contoso required apps are installed
        // Prompt the user to install them
        if not CheckAndPromptUserToInstallContosoRequiredApps() then begin
            MissingDemoAppsErr.Message := DemoDataAppsNotAvailableErr;

            MissingDemoAppsErr.PageNo := Page::"Extension Management";
            MissingDemoAppsErr.AddNavigationAction(GoToExtensionManagementMsg);
            Error(MissingDemoAppsErr);
        end
    end;

    procedure CheckAndPromptUserToInstallContosoRequiredApps(): Boolean
    var
        DemoDataAppIDs: List of [Guid];
    begin
        GetRequireDemoDataAppIDs(DemoDataAppIDs);

        if AreAppsInstalled(DemoDataAppIDs) then
            exit(true);

        if GuiAllowed then
            if not Confirm(ContosoNotInstalledMsg, true) then
                exit(false);

        InstallApps(DemoDataAppIDs);

        // If the code reaches here, most likely the apps are not installed, because session fresh will be triggered after extension installation
        // Check again if demo data apps are installed
        exit(AreAppsInstalled(DemoDataAppIDs));
    end;

    local procedure InstallApps(DemoDataAppIDs: List of [Guid])
    var
        DemoDataAppID: Guid;
    begin
        foreach DemoDataAppID in DemoDataAppIDs do
            TryInstallApp(DemoDataAppID);
    end;

    [TryFunction]
    local procedure TryInstallApp(AppID: Guid)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        MySessionSettings: SessionSettings;
        PackageId: Guid;
    begin
        PackageId := ExtensionManagement.GetLatestVersionPackageIdByAppId(AppID);

        if ExtensionManagement.InstallExtension(PackageId, GlobalLanguage(), true) then begin
            MySessionSettings.Init();
            MySessionSettings.RequestSessionUpdate(false);
        end else
            if EnvironmentInformation.IsSaaS() then
                ExtensionManagement.InstallMarketplaceExtension(AppID);
    end;

    local procedure AreAppsInstalled(DemoDataApps: List of [Guid]): Boolean
    var
        DemoDataApp: Guid;
    begin
        foreach DemoDataApp in DemoDataApps do
            if not ExtensionManagement.IsInstalledByAppId(DemoDataApp) then
                exit(false);

        exit(true);
    end;

    local procedure GetRequireDemoDataAppIDs(var DemoDataApps: List of [Guid])
    var
        CountryApp: Guid;
    begin
        CountryApp := GetCountryContosoAppId();
        if not IsNullGuid(CountryApp) then
            DemoDataApps.Add(CountryApp);

        // The W1 app is only needed when there are no country specific apps
        // Because country specific apps will have the W1 app as a dependency
        // We want to avoid installing multiple apps because each installation will trigger session refresh
        if DemoDataApps.Count() = 0 then
            DemoDataApps.Add('5a0b41e9-7a42-4123-d521-2265186cfb31');
    end;

    local procedure GetCountryContosoAppId(): Guid
    var
        EnvironmentInformation: Codeunit "Environment Information";
        ApplicationFamily: Text;
        EmptyGuid: Guid;
    begin
        ApplicationFamily := EnvironmentInformation.GetApplicationFamily();

        case ApplicationFamily of
            'AT':
                exit('4b0b41f9-7a13-4231-d521-1465186cfb32');
            'AU':
                exit('4b0b41f9-7a13-4231-d521-2465186cfb32');
            'BE':
                exit('5b0b41a1-7b42-4123-a521-2265186cfb33');
            'CA':
                exit('5b0b41a1-7b42-3113-a521-2265186cfb33');
            'CH':
                exit('4b1c41f9-7a13-4231-d521-2465194cfb32');
            'CZ':
                exit('acbbfbc7-75c1-436f-8b22-926d741b2616');
            'DE':
                exit('4b1c41f9-7a13-4122-d521-2465194cfb32');
            'DK':
                exit('5b0b41a1-7b42-1134-a521-2265186cfb33');
            'ES':
                exit('5b0a41a1-7b42-4123-a521-2265186cfb31');
            'FI':
                exit('5b0a31a1-6b42-4123-a521-2265186cfb31');
            'FR':
                exit('5b0a41a1-7b42-4123-a631-2265186cfb31');
            'GB':
                exit('5b0b41a1-7b42-4153-b521-2265186cfb33');
            'IS':
                exit('5b1c41a1-6b42-4123-a521-2265186cfb31');
            'IT':
                exit('5b0a41a1-7b42-4123-a622-2265186cfb35');
            'MX':
                exit('5b0a41b5-7b42-4123-a521-2265186cfb31');
            'NL':
                exit('5b0a41a1-6c42-4123-a521-2265186cfb35');
            'NO':
                exit('5b0a41a1-7b42-1719-a521-2265186cfb31');
            'NZ':
                exit('5b0e32a1-7b42-4123-a521-2265186cfb31');
            'SE':
                exit('5b0a41a1-7b42-4123-a521-2265356bab31');
            'US':
                exit('3a3f33b1-7b42-4123-a521-2265186cfb31');
        end;

        exit(EmptyGuid);
    end;

    var
        ExtensionManagement: Codeunit "Extension Management";
        ContosoNotInstalledMsg: Label 'Contoso Demo Data app(s) are not installed, do you want to install them?\\Note: An automatic session refresh will be triggered after the installation';
        GoToExtensionManagementMsg: Label 'Go to Extension Management';
        DemoDataAppsNotAvailableErr: Label 'Could not install Contoso demo data apps, you will have to go to Extension Management and install them manually';
}
