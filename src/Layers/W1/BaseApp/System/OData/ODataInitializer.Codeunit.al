namespace System.Integration;

using System.Environment;
using System.Environment.Configuration;
using System.Utilities;

codeunit 1738 "OData Initializer"
{
    Access = Internal;

    var
        EnvironmentInfo: Codeunit "Environment Information";
        CategoryTxt: Label 'AL OData Initialization', Locked = true;
        MetadataEndpointCallFailedTxt: Label 'Metadata endpoint call failed.', Locked = true;

    trigger OnRun()
    begin
        CallMetadataEndpoint();
    end;

    local procedure CallMetadataEndpoint()
    var
        ODataUtility: Codeunit ODataUtility;
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        TempBlob: Codeunit "Temp Blob";
        ResponseInStream: InStream;
    begin
        TempBlob.CreateInStream(ResponseInStream);

        if ODataUtility.CreateMetadataWebRequest(HttpWebRequestMgt) then begin
            HttpWebRequestMgt.SetUserAgent('BusinessCentral-Warmup'); // Overwrite user agent
            if HttpWebRequestMgt.GetResponseStream(ResponseInStream) then
                exit;
        end;

        Session.LogMessage('0000E52', MetadataEndpointCallFailedTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    begin
        if not EnvironmentInfo.IsSaaS() then
            exit;

        if not TaskScheduler.CanCreateTask() then
            exit;

        if not UpdateODataInitializedStatus() then
            exit;

        TaskScheduler.CreateTask(Codeunit::"OData Initializer", 0, true, CompanyName(), CurrentDateTime() + 60 * 1000); // Run codeunit in 1 minute
    end;

    local procedure UpdateODataInitializedStatus(): Boolean
    var
        ODataInitializedStatus: Record "OData Initialized Status";
        [SecurityFiltering(SecurityFilter::Ignored)]
        ODataInitializedStatus2: Record "OData Initialized Status";
        moduleInfo: ModuleInfo;
    begin
        if not NavApp.GetCurrentModuleInfo(moduleInfo) then
            exit(false);

        if not (ODataInitializedStatus.ReadPermission() and ODataInitializedStatus2.WritePermission()) then
            exit(false);

        if ODataInitializedStatus.FindFirst() and (ODataInitializedStatus."Initialized version" = Format(moduleInfo.AppVersion())) then
            exit(false);

        // Make sure we only call this initialization once
        ODataInitializedStatus."Initialized version" := Format(moduleInfo.AppVersion());
        if ODataInitializedStatus.IsEmpty() then
            exit(ODataInitializedStatus.Insert())
        else
            exit(ODataInitializedStatus.Modify());
    end;
}
