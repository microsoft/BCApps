namespace System.Globalization;

/// <summary>
/// Page that shows the list of supported languages which is enabled for this environment. If nothing is specified, then the user will be able to use all available languages.
/// </summary>
page 50100 "Supported Languages"
{
    Caption = 'Supported Languages';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Supported Language";
    HelpLink = 'https://go.microsoft.com/fwlink/?linkid=2149387';
    AdditionalSearchTerms = 'company,role center,role,language';
    Permissions = tabledata "Supported Language" = r;

    layout
    {
        area(Content)
        {
            repeater(SupportedLanguages)
            {
                field("Language Id"; Rec."Language Id")
                { }
                field(Language; Rec.Language)
                { }
            }
        }
    }
}