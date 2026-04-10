#pragma warning disable AA0247
page 17303 "Tax Diff. Journal Templates"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Tax Diff. Journal Templates';
    PageType = List;
    SourceTable = "Tax Diff. Journal Template";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name associated with the tax differences journal template.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the tax differences journal template.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type associated with the tax differences journal template.';
                }
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series from which entry or record numbers are assigned to new entries or records.';
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Page ID"; Rec."Page ID")
                {
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the form ID associated with the tax differences journal template.';
                    Visible = false;
                }
                field("Page Name"; Rec."Page Name")
                {
                    DrillDown = false;
                    ToolTip = 'Specifies the form name associated with the tax differences journal template.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Te&mplate")
            {
                Caption = 'Te&mplate';
                Image = Template;
                action(Batches)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Batches';
                    Image = Description;
                    RunObject = Page "Tax Difference Journal Batches";
                    RunPageLink = "Journal Template Name" = field(Name);
                }
            }
        }
    }
}

