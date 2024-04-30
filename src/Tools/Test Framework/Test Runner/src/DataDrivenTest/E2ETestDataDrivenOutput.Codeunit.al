//TODO: Delete, do not check-in
codeunit 130478 "UTDataDrivenTests"
{
    Subtype = Test;

    [Test]
    procedure TestDataOutput()
    var
        TestOutput: Codeunit "Test Output";
        TestJson: Interface "Test Json";
        ListJson: Interface "Test Json";
    begin
        TestOutput.TestData().Add('Time', Format(CurrentDateTime(), 0, 9));
        TestOutput.TestData().AddArray('TestList');
        TestOutput.TestData().Element('TestList').Add('Item1', 'aaa');
        TestOutput.TestData().Add('CopilotKPis', '').Add('Number of calls', Format(111, 0, 9));
        TestOutput.TestData().Element('CopilotKPis').Add('Number of tokens', Format(122, 0, 9));
        // TODO: Add overloads for decimals, integers, boolean and other commonly used types
        TestOutput.TestData().Element('TestList').Add('Amount', '123.11');
    end;

    [Test]
    procedure TestDataOutput2()
    var
        TestOutput: Codeunit "Test Output";
        TestJson: Interface "Test Json";
        ListJson: Interface "Test Json";
    begin
        TestOutput.TestData().Add('Time 2', Format(CurrentDateTime(), 0, 9));
        TestOutput.TestData().AddArray('TestList 2');
        TestOutput.TestData().Element('TestList 2').Add('Item1', 'aaa');
        TestOutput.TestData().Add('CopilotKPis 2', '').Add('Number of calls', Format(111, 0, 9));
        TestOutput.TestData().Element('CopilotKPis 2').Add('Number of tokens', Format(122, 0, 9));
        // TODO: Add overloads for decimals, integers, boolean and other commonly used types
        TestOutput.TestData().Element('TestList 2').Add('Amount', '123.11');
    end;

}