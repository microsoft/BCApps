namespace System.TestLibraries.Agents;

/// <summary>
/// Selects the sender used to execute an AIT query. Providers supply their own implementation.
/// </summary>
enum 130560 "AIT Request Provider" implements "IAITRequestSender"
{
    Extensible = true;

    value(0; "Business Central")
    {
        Caption = 'Business Central';
        Implementation = IAITRequestSender = "Library - Agent Impl.";
    }
}