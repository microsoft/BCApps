namespace System.Text.Test;

using System.AI;
using System.TestTools.AITestToolkit;

codeunit 133552 "MT Tests Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        DatasetPaths: List of [Text];
        TestSuitePaths: List of [Text];
        ResourcePath: Text;
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Marketing Text Evaluation") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Marketing Text Evaluation",
                Enum::"Copilot Availability"::Preview, Enum::"Copilot Billing Type"::"Microsoft Billed",
                'https://learn.microsoft.com/dynamics365/business-central/');

        // Load Datasets
        DatasetPaths := NavApp.ListResources('*.yaml');
        foreach ResourcePath in DatasetPaths do
            SetupDataInput(ResourcePath);

        Commit();
        // Load Test Suites
        TestSuitePaths := NavApp.ListResources('*.xml');
        foreach ResourcePath in TestSuitePaths do
            SetupTestSuite(ResourcePath);
    end;

    local procedure SetupDataInput(FilePath: Text)
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
        FileName: Text;
        ResInStream: InStream;
    begin
        // Get the filename from the path
        FileName := FilePath.Substring(FilePath.LastIndexOf('/') + 1);

        NavApp.GetResource(FilePath, ResInStream);
        AITALTestSuiteMgt.ImportTestInputs(FileName, ResInStream);
    end;

    local procedure SetupTestSuite(Filepath: Text)
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
        XMLSetupInStream: InStream;
    begin
        NavApp.GetResource(Filepath, XMLSetupInStream);
        AITALTestSuiteMgt.ImportAITestSuite(XMLSetupInStream);
    end;
}