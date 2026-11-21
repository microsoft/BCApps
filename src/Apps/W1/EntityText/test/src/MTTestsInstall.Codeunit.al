namespace System.Text.Test;

using System.TestTools.AITestToolkit;

codeunit 133552 "MT Tests Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        this.SetupTestData();
        Commit();
        this.SetupTestSuites();
    end;

    internal procedure SetupTestData()
    var
        DatasetPaths: List of [Text];
        ResourcePath: Text;
    begin
        // Load Datasets
        DatasetPaths := NavApp.ListResources('*.yaml');
        foreach ResourcePath in DatasetPaths do
            SetupDataInput(ResourcePath);
    end;

    internal procedure SetupTestSuites()
    var
        TestSuitePaths: List of [Text];
        ResourcePath: Text;
    begin
        // Load Test Suites
        TestSuitePaths := NavApp.ListResources('*.xml');
        foreach ResourcePath in TestSuitePaths do
            SetupTestSuite(ResourcePath);
    end;

    local procedure SetupDataInput(FilePath: Text)
    var
        MTTestHelpers: Codeunit "MT Test Helpers";
    begin
        MTTestHelpers.ImportTestInputs(FilePath);
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