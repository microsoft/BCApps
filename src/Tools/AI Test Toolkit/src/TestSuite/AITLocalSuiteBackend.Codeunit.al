namespace System.TestTools.AITestToolkit;

codeunit 149050 "AIT Local Suite Backend" implements "AIT Suite Backend"
{
    Access = Internal;

    procedure CheckBeforeRun(AITTestSuite: Record "AIT Test Suite")
    begin
    end;

    procedure UsesLocalTestRunner(): Boolean
    begin
        exit(true);
    end;

    procedure Execute(AITTestSuite: Record "AIT Test Suite"): Boolean
    var
        SuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        SuiteMgt.RunLocalTests(AITTestSuite);
        exit(true);
    end;

    procedure Cancel(var AITTestSuite: Record "AIT Test Suite")
    var
        SuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        SuiteMgt.CancelLocalRun(AITTestSuite);
    end;
}