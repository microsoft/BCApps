codeunit 132863 "PowerBI Upgrade Data Setup"
{
    Subtype = Upgrade;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerDatabase', '', false, false)]
    local procedure SetupPowerBIOptinImage()
    var
        MediaRepository: Record "Media Repository";
    begin
        MediaRepository.SetFilter("Display Target", '<>%1', Format(ClientType::Web));
        MediaRepository.SetRange("File Name", 'PowerBi-OptIn-480px.png');
        MediaRepository.DeleteAll();

        MediaRepository.Reset();
        MediaRepository.Init();
        MediaRepository."File Name" := 'PowerBi-OptIn-480px.png';
        MediaRepository."Display Target" := Format(ClientType::Web);
        if MediaRepository.Insert() then;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Test Data Setup Mgt.", 'OnSetupDataPerCompany', '', false, false)]
    local procedure SetupPowerBIUploadsData()
    var
        PowerBIReportUploads: Record "Power BI Report Uploads";
    begin
        PowerBIReportUploads.Init();
        PowerBIReportUploads."Should Retry" := false;
        PowerBIReportUploads."PBIX BLOB ID" := '90757427-ed00-0000-0000-000000000001';
        PowerBIReportUploads.Insert();

        PowerBIReportUploads.Init();
        PowerBIReportUploads."Should Retry" := true;
        PowerBIReportUploads."PBIX BLOB ID" := '90757427-ed00-0000-0000-000000000002';
        PowerBIReportUploads.Insert();

        PowerBIReportUploads.Init();
        PowerBIReportUploads."Should Retry" := true;
        PowerBIReportUploads."Import ID" := CreateGuid();
        PowerBIReportUploads."PBIX BLOB ID" := '90757427-ed00-0000-0000-000000000003';
        PowerBIReportUploads.Insert();

        PowerBIReportUploads.Init();
        PowerBIReportUploads."Should Retry" := false;
        PowerBIReportUploads."Import ID" := CreateGuid();
        PowerBIReportUploads."PBIX BLOB ID" := 'fa17ed00-0000-0000-0000-000000000001';
        PowerBIReportUploads.Insert();

        PowerBIReportUploads.Init();
        PowerBIReportUploads."Needs Deletion" := true;
        PowerBIReportUploads."Should Retry" := true;
        PowerBIReportUploads."Report Embed Url" := 'https://microsoft.com';
        PowerBIReportUploads."Uploaded Report ID" := CreateGuid();
        PowerBIReportUploads."Import ID" := CreateGuid();
        PowerBIReportUploads."PBIX BLOB ID" := 'de7e7ed0-0000-0000-0000-000000000001';
        PowerBIReportUploads.Insert();

        PowerBIReportUploads.Init();
        PowerBIReportUploads."Needs Deletion" := true;
        PowerBIReportUploads."Should Retry" := false;
        PowerBIReportUploads."Report Embed Url" := 'https://microsoft.com/123456';
        PowerBIReportUploads."Uploaded Report ID" := CreateGuid();
        PowerBIReportUploads."Import ID" := CreateGuid();
        PowerBIReportUploads."PBIX BLOB ID" := 'de7e7ed0-0000-0000-0000-000000000002';
        PowerBIReportUploads.Insert();

        PowerBIReportUploads.Init();
        PowerBIReportUploads."Needs Deletion" := true;
        PowerBIReportUploads."PBIX BLOB ID" := 'de7e7ed0-0000-0000-0000-000000000003';
        PowerBIReportUploads.Insert();

        PowerBIReportUploads.Init();
        PowerBIReportUploads."Is Selection Done" := true;
        PowerBIReportUploads."Report Embed Url" := 'https://microsoft.com';
        PowerBIReportUploads."Uploaded Report ID" := CreateGuid();
        PowerBIReportUploads."Import ID" := CreateGuid();
        PowerBIReportUploads."PBIX BLOB ID" := '5e7ec7ed-0000-0000-0000-000000000001';
        PowerBIReportUploads.Insert();

        PowerBIReportUploads.Init();
        PowerBIReportUploads."Is Selection Done" := false;
        PowerBIReportUploads."Report Embed Url" := 'https://microsoft.com';
        PowerBIReportUploads."Uploaded Report ID" := CreateGuid();
        PowerBIReportUploads."Import ID" := CreateGuid();
        PowerBIReportUploads."PBIX BLOB ID" := '5e7ec7ed-0000-0000-0000-000000000002';
        PowerBIReportUploads.Insert();
    end;

}