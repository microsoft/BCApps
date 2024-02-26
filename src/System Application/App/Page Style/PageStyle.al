enum 50000 "Page Style"
{
    Extensible = false;

    value(0; None)
    {
        Caption = 'None', Comment = 'None';
    }
    value(1; Standard)
    {
        Caption = 'Standard', Comment = 'Standard';
    }
    value(2; StandardAccend)
    {
        Caption = 'StandardAccent', Comment = 'Blue';
    }
    value(3; Strong)
    {
        Caption = 'Strong', Comment = 'Bold';
    }
    value(4; StrongAccent)
    {
        Caption = 'StrongAccent', Comment = 'Blue + Bold';
    }
    value(5; Attention)
    {
        Caption = 'Attention', Comment = 'Red + Italic';
    }
    value(6; AttentionAccent)
    {
        Caption = 'AttentionAccent', Comment = 'Blue + Italic';
    }
    value(7; Favorable)
    {
        Caption = 'Favorable', Comment = 'Bold + Green';
    }
    value(8; Unfavorable)
    {
        Caption = 'Unfavorable', Comment = 'Bold + Italic + Red';
    }
    value(9; Ambiguous)
    {
        Caption = 'Ambiguous', Comment = 'Yellow';
    }
    value(10; Subordinate)
    {
        Caption = 'Subordinate', Comment = 'Grey';
    }
}