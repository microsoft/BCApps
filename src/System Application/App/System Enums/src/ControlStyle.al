namespace System.Visualization;

/// <summary>
/// This enum has the styles for the label or field controls on pages.
/// </summary>
enum 1 "Control Style"
{
    Extensible = false;

    /// <summary>
    /// None
    /// </summary>
    value(0; None)
    {
        Caption = 'None', Locked = true;
    }

    /// <summary>
    /// Standard
    /// </summary>
    value(1; Standard)
    {
        Caption = 'Standard', Locked = true;
    }

    /// <summary>
    /// Blue
    /// </summary>
    value(2; StandardAccent)
    {
        Caption = 'StandardAccent', Locked = true;
    }

    /// <summary>
    /// Bold
    /// </summary>
    value(3; Strong)
    {
        Caption = 'Strong', Locked = true;
    }

    /// <summary>
    /// Blue + Bold
    /// </summary>
    value(4; StrongAccent)
    {
        Caption = 'StrongAccent', Locked = true;
    }

    /// <summary>
    /// Red + Italic
    /// </summary>
    value(5; Attention)
    {
        Caption = 'Attention', Locked = true;
    }

    /// <summary>
    /// Blue + Italic
    /// </summary>
    value(6; AttentionAccent)
    {
        Caption = 'AttentionAccent', Locked = true;
    }

    /// <summary>
    /// Bold + Green
    /// </summary>
    value(7; Favorable)
    {
        Caption = 'Favorable', Locked = true;
    }

    /// <summary>
    /// Bold + Italic + Red
    /// </summary>
    value(8; Unfavorable)
    {
        Caption = 'Unfavorable', Locked = true;
    }

    /// <summary>
    /// Yellow
    /// </summary>
    value(9; Ambiguous)
    {
        Caption = 'Ambiguous', Locked = true;
    }

    /// <summary>
    /// Grey
    /// </summary>
    value(10; Subordinate)
    {
        Caption = 'Subordinate', Locked = true;
    }
}