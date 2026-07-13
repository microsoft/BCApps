#pragma warning disable AA0247
page 12448 "Report Selection - Print"
{
    Caption = 'Report Selection - Print';
    PageType = Worksheet;
    SourceTable = "Report Selections";

    layout
    {
        area(content)
        {
            repeater(Control1210000)
            {
                ShowCaption = false;
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the display name of the report.';
                }
                field(Default; Rec.Default)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Report';
                    ToolTip = 'Specifies if the report ID is the default for the report selection.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Functions")
            {
                Caption = '&Functions';
                Image = "Action";
                action("Set All")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set All';
                    Image = Registered;
                    ToolTip = 'Select the Print Report check box for all reports.';

                    trigger OnAction()
                    begin
                        Rec.ModifyAll(Default, true);
                    end;
                }
                action("Clear All")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Clear All';
                    Image = Reject;

                    trigger OnAction()
                    begin
                        Rec.ModifyAll(Default, false);
                    end;
                }
            }
        }
    }
}

