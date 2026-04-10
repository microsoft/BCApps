namespace System.Environment.Configuration;

using Microsoft.Foundation.Company;
using Microsoft.Upgrade;
using System.Upgrade;

codeunit 8821 "AAD Application Setup"
{
    trigger OnRun()
    begin
    end;

    var
        Dynamics365BusinessCentralforVirtualEntitiesDesTok: Label '%1 for Virtual Tables', Comment = '%1 product name';
        Dynamics365BusinessCentralforVirtualEntitiesGuidTok: Label 'af30e371-ad4a-4097-88c1-5555e7ada96f', Locked = true;

        MicrosoftPowerPagesAuthenticatedUsersDesTok: Label 'Power Pages Authenticated External Users', MaxLength = 50;
        MicrosoftPowerPagesAuthenticatedUsersAppGuidTok: Label 'bf9c07cb-3385-4de3-a63a-b630340b14be', Locked = true;

        MicrosoftPowerPagesAnonymousUsersDesTok: Label 'Power Pages Anonymous External Users', MaxLength = 50;
        MicrosoftPowerPagesAnonymousUsersAppGuidTok: Label 'ea76fed3-daf0-4865-a0c5-8d40c168791a', Locked = true;

        MicrosoftExpenseAgentDesTok: Label 'Dynamics 365 Business Central Expense Agent', MaxLength = 50;
        MicrosoftExpenseAgentAppGuidTok: Label 'ee1eb5fd-719b-44f2-97d0-0efd34bc4148', Locked = true;

    procedure CreateDynamics365BusinessCentralforVirtualEntitiesAAdApplication()
    var
        AADApplicationInterface: Codeunit "AAD Application Interface";
        ClientID: Text;
        ClientDescription: Text[50];
        ContactInformation: Text[50];
    begin
        ClientDescription :=
            CopyStr(StrSubstno(Dynamics365BusinessCentralforVirtualEntitiesDesTok, ProductName.Full()), 1, MaxStrLen(ClientDescription));
        ClientID := GetD365BCForVEAppId();
        ContactInformation := CopyStr(ProductName.Full(), 1, MaxStrLen(ContactInformation));
        AADApplicationInterface.CreateAADApplication(ClientID, ClientDescription, ContactInformation);
    end;

    procedure CreatePowerPagesAAdApplications()
    var
        AADApplicationInterface: Codeunit "AAD Application Interface";
        ClientID: Text;
        ClientDescription: Text[50];
        ContactInformation: Text[50];
    begin
        // Create app registration for Power Pages authenticated access
        ClientDescription := MicrosoftPowerPagesAuthenticatedUsersDesTok;
        ClientID := MicrosoftPowerPagesAuthenticatedUsersAppGuidTok;
        ContactInformation := CopyStr(ProductName.Full(), 1, MaxStrLen(ContactInformation));
        AADApplicationInterface.CreateAADApplication(ClientID, ClientDescription, ContactInformation);

        // Create app registration for Power Pages anonymous access
        ClientDescription := MicrosoftPowerPagesAnonymousUsersDesTok;
        ClientID := MicrosoftPowerPagesAnonymousUsersAppGuidTok;
        ContactInformation := CopyStr(ProductName.Full(), 1, MaxStrLen(ContactInformation));
        AADApplicationInterface.CreateAADApplication(ClientID, ClientDescription, ContactInformation);
    end;

    procedure CreateExpenseAgentAADApplications()
    var
        AADApplicationInterface: Codeunit "AAD Application Interface";
        ClientID: Text;
        ClientDescription: Text[50];
        ContactInformation: Text[50];
    begin
        // Create app registration for Expense Agent authenticated access
        ClientDescription := MicrosoftExpenseAgentDesTok;
        ClientID := MicrosoftExpenseAgentAppGuidTok;
        ContactInformation := CopyStr(ProductName.Full(), 1, MaxStrLen(ContactInformation));
        AADApplicationInterface.CreateAADApplication(ClientID, ClientDescription, ContactInformation);
    end;

    procedure ModifyDescriptionOfDynamics365BusinessCentralforVirtualEntitiesAAdApplication()
    var
        AADApplicationInterface: Codeunit "AAD Application Interface";
        ClientID: Text;
        ClientDescription: Text[50];
    begin
        ClientDescription :=
            CopyStr(StrSubstno(Dynamics365BusinessCentralforVirtualEntitiesDesTok, ProductName.Full()), 1, MaxStrLen(ClientDescription));
        ClientID := GetD365BCForVEAppId();
        AADApplicationInterface.ModifyAADApplicationDescription(ClientID, ClientDescription);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure InitSetup()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Upgrade Tag Definitions";
    begin
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultAADApplicationTag()) then begin
            CreateDynamics365BusinessCentralforVirtualEntitiesAAdApplication();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultAADApplicationTag());
        end;
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultPowerPagesAADApplicationsTag()) then begin
            CreatePowerPagesAAdApplications();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCreateDefaultPowerPagesAADApplicationsTag());
        end;
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetCreateExpenseAgentAADApplicationsTag()) then begin
            CreateExpenseAgentAADApplications();
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetCreateExpenseAgentAADApplicationsTag());
        end;
    end;

    [Scope('OnPrem')]
    internal procedure GetD365BCForVEAppId(): Guid
    begin
        exit(Dynamics365BusinessCentralforVirtualEntitiesGuidTok);
    end;

    [Scope('OnPrem')]
    internal procedure GetPowerPagesAnonymousAppId(): Guid
    begin
        exit(MicrosoftPowerPagesAnonymousUsersAppGuidTok);
    end;

    [Scope('OnPrem')]
    internal procedure GetPowerPagesAuthenticatedAppId(): Guid
    begin
        exit(MicrosoftPowerPagesAuthenticatedUsersAppGuidTok);
    end;

    [Scope('OnPrem')]
    internal procedure GetExpenseAgentAuthenticatedAppId(): Guid
    begin
        exit(MicrosoftExpenseAgentAppGuidTok);
    end;
}
