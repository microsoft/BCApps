namespace System.AI;

enum 7787 "AOAI Policy Harms Severity"
{
    Extensible = false;

    /// <summary>
    /// Applies the strictest policy controls.
    /// </summary>
    value(1; Low)
    {
    }

    /// <summary>
    /// Applies moderately strict policy controls.
    /// </summary>
    value(2; Medium)
    {
    }
}
