namespace Microsoft.Integration.Shopify;

using System.TestTools.AITestToolkit;

codeunit 30490 "Shpfy CTM Tests Install"
{
    Subtype = Install;
    Access = Internal;

    trigger OnInstallAppPerCompany()
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
        DatasetPaths: List of [Text];
        TestSuitePaths: List of [Text];
        ResourcePath: Text;
        FileName: Text;
        ResInStream: InStream;
    begin
        DatasetPaths := NavApp.ListResources('*.yaml');
        foreach ResourcePath in DatasetPaths do begin
            FileName := ResourcePath.Substring(ResourcePath.LastIndexOf('/') + 1);
            NavApp.GetResource(ResourcePath, ResInStream, TextEncoding::UTF8);
            AITALTestSuiteMgt.ImportTestInputs(FileName, ResInStream);
        end;

        TestSuitePaths := NavApp.ListResources('*.xml');
        foreach ResourcePath in TestSuitePaths do begin
            NavApp.GetResource(ResourcePath, ResInStream);
            AITALTestSuiteMgt.ImportAITestSuite(ResInStream);
        end;
    end;
}
