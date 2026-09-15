codeunit 103423 Corsica_ExactCostReversing
{
    // Unsupported version tags:
    // ES: Unable to Compile
    // NA: Skipped for Execution
    // DE: Skipped for Execution
    // 
    // This codeunit is only ment as a tool for speeding up testing of Use Case 3 Costing Corsica
    // It is NOT part of the automated C/AL Testsuite
    // The test itself has to be done manually as described in the TCS for this use case
    // You can provide the data needed to perform the test case you want by the following steps
    // Remove the '//' infront of the Test Case you want to test
    // Make sure all other Procedures, named TestCaseXX are commented out
    // Save the codeunit
    // Run the codeunit


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        WMSTestscriptManagement.SetGlobalPreconditions();
        // "TestCase1-1";
        // "TestCase1-2";
        // "TestCase1-3";
        // "TestCase1-4";
        // "TestCase1-5";
        // TestCase2;
        // "TestCase3-1";
        // "TestCase3-2";
        // "TestCase3-3";
        // "TestCase3-4";
        // "TestCase3-5";
        // TestCase4;
        // "TestCase5-1";
        // "TestCase5-2";
        // "TestCase5-3";
        // "TestCase5-4";
        // "TestCase5-5";
        // "TestCase5-6";
        // "TestCase5-7";
        // "TestCase6-1";
        // "TestCase6-2";
        // TestCase7;
        // "TestCase8-1";
        // "TestCase8-2";
        // "TestCase8-3";
        // "TestCase8-4";
        // "TestCase8-5";
        // "TestCase8-6";
        // "TestCase8-7";
        // "TestCase8-8";
        // "TestCase9-1";
        // "TestCase9-2";
        // "TestCase10-1";
        // "TestCase10-2";
        // TestCase11_12;
        // "TestCase13-1";
        // "TestCase13-2";
        // "TestCase13-3";
        // "TestCase13-4";
    end;
}

