namespace System.Utilities;
using Microsoft.Utilities;

pageextension 706 "Error Messages Part Extension" extends "Error Messages Part"
{
    layout
    {
        modify(Description)
        {
            trigger OnDrillDown()
            begin
                if not DisableOpenRelatedEntity then
                    PageManagement.PageRun(Rec."Record ID");
            end;
        }
    }

    actions
    {
        addfirst(processing)
        {
            action(OpenRelatedRecord)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open Related Record';
                Enabled = EnableOpenRelatedEntity;
                Image = View;
                ToolTip = 'Open the record that is associated with this error message.';

                trigger OnAction()
                begin
                    PageManagement.PageRun(Rec."Record ID");
                end;
            }
        }
    }

    var
        PageManagement: Codeunit "Page Management";
}
