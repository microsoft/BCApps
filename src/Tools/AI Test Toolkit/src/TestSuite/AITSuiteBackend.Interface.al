namespace System.TestTools.AITestToolkit;

interface "AIT Suite Backend"
{
    procedure CheckBeforeRun(AITTestSuite: Record "AIT Test Suite");
    procedure UsesLocalTestRunner(): Boolean;
    procedure Execute(AITTestSuite: Record "AIT Test Suite"): Boolean;
    procedure Cancel(var AITTestSuite: Record "AIT Test Suite");
}