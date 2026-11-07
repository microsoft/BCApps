codeunit 119202 "Create D365 Base Data"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        Codeunit.Run(Codeunit::"Create Profiles");
        CreatePermissions();
        CreateWebServices();
        SetupAPIs();
        SetupApplicationArea();
        Codeunit.Run(Codeunit::"Create Getting Started Data");
        Codeunit.Run(Codeunit::"Create Media Repository");
        Codeunit.Run(Codeunit::"Create Excel Templates");
        Codeunit.Run(Codeunit::"Create Late Payment Model");
    end;

    var
    // Note: Those strings are used only for upgrade from 14.x to 15.0 for translations, and should be deleted afterwards
    // End of strings used for upgrade from 14.x to 15.0

    local procedure CreatePermissions()
    begin
        Codeunit.Run(Codeunit::"Create Default Permissions");
    end;

    local procedure CreateWebServices()
    var
        WebService: Record "Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
        CreateWebServices: Codeunit "Create Web Services";
    begin
        WebService.DeleteAll();

        WebServiceManagement.CreateWebService(
          WebService."Object Type"::Codeunit, Codeunit::"Company Setup Service", 'CompanySetupService', true);

        WebServiceManagement.CreateWebService(
          WebService."Object Type"::Codeunit, Codeunit::"Exchange Service Setup", 'ExchangeServiceSetup', true);
        WebServiceManagement.CreateWebService(
          WebService."Object Type"::Codeunit, Codeunit::"Page Summary Provider", 'SummaryProvider', true);

        WebServiceManagement.CreateWebService(
          WebService."Object Type"::Codeunit, Codeunit::"Page Action Provider", 'PageActionProvider', true);

        CreateWebServices.CreatePowerBIWebServices();
        CreateWebServices.CreateSegmentWebService();
        CreateWebServices.CreateJobWebServices();
        CreateWebServices.CreatePowerBITenantWebServices();
        CreateWebServices.CreateAccountantPortalWebServices();
        CreateWebServices.CreateWorkflowWebhookWebServices();
        CreateWebServices.CreateExcelTemplateWebServices();
    end;

    local procedure SetupApplicationArea()
    var
        ExperienceTierSetup: Record "Experience Tier Setup";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
    begin
        ApplicationAreaMgmtFacade.SaveExperienceTierCurrentCompany(ExperienceTierSetup.FieldCaption(Essential));
    end;

    local procedure SetupAPIs()
    var
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        GraphMgtGeneralTools.ApiSetup();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'OnGetIsAPIEnabled', '', false, false)]
    local procedure GetIsAPIEnabled(var Handled: Boolean; var IsAPIEnabled: Boolean)
    begin
        Handled := true;
        IsAPIEnabled := true;
    end;
}

