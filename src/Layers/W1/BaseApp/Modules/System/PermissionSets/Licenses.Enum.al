namespace System.Security.AccessControl;

/// <summary>
/// Specifies the type of license.
/// </summary>
#pragma warning disable AA0247
enum 5557 Licenses
{
    Extensible = false;

    value(0; Basic)
    { }
    value(1; "Team Member")
    { }
    value(2; Essential)
    { }
    value(3; Premium)
    { }
    value(4; Device)
    { }
    value(5; "External Accountant")
    { }
    value(6; "Internal Admin")
    { }
    value(7; "Delegated Admin")
    { }
    value(8; HelpDesk)
    { }
    value(9; Viral)
    { }
    value(10; "D365 Admin")
    { }
}
