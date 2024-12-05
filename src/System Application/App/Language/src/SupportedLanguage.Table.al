namespace System.Globalization;

/// <summary>
/// Table that contains a list of specific application languages available for the users. If the table is empty, then all installed application languages will be available.
/// </summary>
table 50100 "Supported Language"
{
    Caption = 'Supported Language';
    DataClassification = SystemMetadata;
    DataPerCompany = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    fields
    {
        field(1; "Language Id"; Integer)
        {
            Caption = 'Language Id';
            NotBlank = true;
            BlankZero = true;
            TableRelation = "Windows Language" where("Localization Exist" = const(true), "Globally Enabled" = const(true));
            ToolTip = 'Specifies the language id(s) that should be enabled for this environment.';
        }
        field(2; Language; Text[80])
        {
            Caption = 'Language';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Windows Language".Name where("Language ID" = field("Language Id")));
            ToolTip = 'Specifies the language that should be enabled for this environment.';
        }
    }

    keys
    {
        key(PK; "Language Id")
        {
            Clustered = true;
        }
    }
}