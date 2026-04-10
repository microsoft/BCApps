namespace System.Environment.Configuration;

using System.Tooling;

page 9196 "Profile Import Diagnostics"
{
    PageType = List;
    SourceTable = "Designer Diagnostic";
    SourceTableView = where(Severity = filter(<> Hidden));
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Caption = 'Diagnostics';

    layout
    {
        area(Content)
        {
            repeater(repeater)
            {
                field(Severity; Rec.Severity)
                {
                    ApplicationArea = All;
                    width = 5;
                    ToolTip = 'Specifies the severity of this diagnostics message.';
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the diagnostics message from the compiler.';
                }
            }
        }
    }
}
