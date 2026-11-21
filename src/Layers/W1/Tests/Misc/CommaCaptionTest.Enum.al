namespace Microsoft.Test.Utilities;

enum 135000 "Comma Caption Test"
{
    Extensible = false;

    value(0; First)
    {
        Caption = 'First value';
    }
#pragma warning disable AL0649 // Accepted: the comma in this test-only caption is the scenario under test (issue 10082).
    value(1; WithComma)
    {
        Caption = 'Received, not invoiced';
    }
#pragma warning restore AL0649
    value(2; AfterComma)
    {
        Caption = 'Fully invoiced';
    }
}
