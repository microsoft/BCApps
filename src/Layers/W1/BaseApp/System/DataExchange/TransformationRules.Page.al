namespace System.IO;

page 1237 "Transformation Rules"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Transformation Rules';
    CardPageID = "Transformation Rule Card";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Transformation Rule";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Dynamics 365.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
                field("Transformation Type"; Rec."Transformation Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
                field("Find Value"; Rec."Find Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
                field("Replace Value"; Rec."Replace Value")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
                field("Start Position"; Rec."Start Position")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
                field("Data Format"; Rec."Data Format")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
                field("Data Formatting Culture"; Rec."Data Formatting Culture")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies rules for how text that was imported from an external file is transformed to a supported value that can be mapped to the specified field in Business Central.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then
            Rec.CreateDefaultTransformations();
        Rec.OnCreateTransformationRules();
    end;
}

