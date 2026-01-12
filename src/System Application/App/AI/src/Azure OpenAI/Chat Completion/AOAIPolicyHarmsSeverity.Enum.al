namespace System.AI;

enum 7788 "AOAI Policy Harms Severity"
{
    Extensible = false;

    /// <summary>
    /// Recommended. Strictest policy controls: Requests containing harms with a low severity are blocked.
    /// For more information, see https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/content-filter-severity-levels?view=foundry-classic&amp;tabs=definitions#hate-and-fairness-severity-levels
    /// </summary>
    value(1; Low)
    {
        Caption = 'Low', Locked = true;
    }

    /// <summary>
    /// Moderately strict policy controls: Requests containing harms with a medium severity are blocked.
    /// For more information, see https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/content-filter-severity-levels?view=foundry-classic&amp;tabs=definitions#hate-and-fairness-severity-levels
    /// </summary>
    value(2; Medium)
    {
        Caption = 'Medium', Locked = true;
    }
}
