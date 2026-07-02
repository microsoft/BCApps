// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
codeunit 1309 "O365 Getting Started Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";

    procedure LaunchWizard(UserInitiated: Boolean; TourCompleted: Boolean): Boolean
    begin
        exit(CheckOrLaunchWizard(UserInitiated, TourCompleted, true));
    end;

    procedure WizardHasToBeLaunched(UserInitiated: Boolean): Boolean
    begin
        exit(CheckOrLaunchWizard(UserInitiated, false, false));
    end;

    local procedure CheckOrLaunchWizard(UserInitiated: Boolean; TourCompleted: Boolean; Launch: Boolean): Boolean
    var
        O365GettingStarted: Record "O365 Getting Started";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
        WizardHasBeenShownToUser: Boolean;
        PageToStart: Integer;
    begin
        if not UserHasPermissionsToRunGettingStarted() then
            exit(false);

        if not CompanyInformationMgt.IsDemoCompany() then
            exit(false);

        PageToStart := GetPageToStart();
        if PageToStart <= 0 then
            exit(false);

        WizardHasBeenShownToUser := O365GettingStarted.Get(UserId, ClientTypeManagement.GetCurrentClientType());

        if not WizardHasBeenShownToUser then begin
            O365GettingStarted.OnO365DemoCompanyInitialize();
            if Launch then begin
                Commit();
                PAGE.RunModal(PageToStart);
            end;
            exit(true);
        end;

        if (not O365GettingStarted."Tour in Progress") and (not UserInitiated) then
            exit(false);

        if UserInitiated then begin
            if Launch then begin
                Commit();
                PAGE.RunModal(PageToStart);
            end;
            exit(true);
        end;

        if O365GettingStarted."Tour in Progress" then begin
            if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Phone, CLIENTTYPE::Tablet, CLIENTTYPE::Desktop] then
                exit(false);

            if Launch then begin
                Commit();
                if TourCompleted and not EnvironmentInfo.IsSandbox() then
                    PAGE.RunModal(PAGE::"O365 Tour Complete")
                else
                    PAGE.RunModal(PageToStart);
            end;
            exit(true);
        end;

        exit(false);
    end;

    procedure UpdateGettingStartedVisible(var TileGettingStartedVisible: Boolean; var TileRestartGettingStartedVisible: Boolean)
    var
        O365GettingStarted: Record "O365 Getting Started";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        TileGettingStartedVisible := false;
        TileRestartGettingStartedVisible := false;

        if not UserHasPermissionsToRunGettingStarted() then
            exit;

        if not IsGettingStartedSupported() then
            exit;

        if EnvironmentInfo.IsSandbox() then
            exit;

        TileRestartGettingStartedVisible := true;

        if not O365GettingStarted.Get(UserId, ClientTypeManagement.GetCurrentClientType()) then
            exit;

        TileGettingStartedVisible := O365GettingStarted."Tour in Progress";
        TileRestartGettingStartedVisible := not TileGettingStartedVisible;
    end;

    procedure IsGettingStartedSupported(): Boolean
    begin
        exit(false);
    end;

    procedure AreUserToursEnabled(): Boolean
    begin
        exit(ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Web);
    end;

    procedure GetGettingStartedTourID(): Integer
    begin
        exit(173706);
    end;

    procedure GetInvoicingTourID(): Integer
    begin
        exit(174204);
    end;

    procedure GetReportingTourID(): Integer
    begin
        exit(174207);
    end;

    procedure GetChangeCompanyTourID(): Integer
    begin
        exit(174206);
    end;

    procedure GetWizardDoneTourID(): Integer
    begin
        exit(176849);
    end;

    procedure GetReturnToGettingStartedTourID(): Integer
    begin
        exit(176291);
    end;

    procedure GetDevJourneyTourID(): Integer
    begin
        exit(195457);
    end;

    procedure GetWhatIsNewTourID(): Integer
    begin
        exit(199410);
    end;

    procedure GetAddItemTourID(): Integer
    begin
        exit(237373);
    end;

    procedure GetAddCustomerTourID(): Integer
    begin
        exit(239510);
    end;

    procedure GetCreateSalesOrderTourID(): Integer
    begin
        exit(240566);
    end;

    procedure GetCreateSalesInvoiceTourID(): Integer
    begin
        exit(240561);
    end;

    procedure WizardShouldBeOpenedForDevices(): Boolean
    var
        O365GettingStarted: Record "O365 Getting Started";
    begin
        if not WizardCanBeOpenedForDevices() then
            exit(false);

        exit(not O365GettingStarted.Get(UserId, ClientTypeManagement.GetCurrentClientType()));
    end;

    procedure GetAccountantTourID(): Integer
    begin
        exit(363941);
    end;

    local procedure GetPageToStart(): Integer
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSandbox() then begin
            if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Web then
                exit(PAGE::"O365 Developer Welcome");
            exit(-1)
        end;

        if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Phone, CLIENTTYPE::Tablet, CLIENTTYPE::Desktop] then begin
            if EnvironmentInfo.IsSaaS() then
                exit(PAGE::"O365 Getting Started Device");
            exit(-1);
        end;
        exit(PAGE::"O365 Getting Started");
    end;

    procedure UserHasPermissionsToRunGettingStarted(): Boolean
    var
        DummyO365GettingStarted: Record "O365 Getting Started";
    begin
        if not DummyO365GettingStarted.ReadPermission then
            exit(false);

        if not DummyO365GettingStarted.WritePermission then
            exit(false);

        exit(true);
    end;

    procedure WizardCanBeOpenedForDevices(): Boolean
    var
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not (ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Tablet, CLIENTTYPE::Phone, CLIENTTYPE::Desktop]) then
            exit(false);

        if not UserHasPermissionsToRunGettingStarted() then
            exit(false);

        if not EnvironmentInfo.IsSaaS() then
            exit(false);

        if not CompanyInformationMgt.IsDemoCompany() then
            exit(false);

        exit(true)
    end;
}

