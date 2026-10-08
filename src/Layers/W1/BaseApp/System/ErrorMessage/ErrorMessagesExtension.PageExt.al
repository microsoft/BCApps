namespace System.Utilities;
using Microsoft.Utilities;

pageextension 705 "Error Messages Extension" extends "Error Messages"
{
    layout
    {
        addafter(Description)
        {
            field(Context; Format(Rec."Context Record ID"))
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Context';
                ToolTip = 'Specifies the context record.';
                trigger OnDrillDown()
                begin
                    Rec.HandleDrillDown(Rec.FieldNo("Context Record ID"));
                end;
            }
        }
        addafter("Context Field Name")
        {
            field(Source; Format(Rec."Record ID"))
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Source';
                ToolTip = 'Specifies the record source of the error.';

                trigger OnDrillDown()
                begin
                    Rec.HandleDrillDown(Rec.FieldNo("Record ID"));
                end;
            }
        }
    }

    actions
    {
        addfirst(processing)
        {
            action(OpenRelatedRecord)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open related record';
                Enabled = EnableOpenRelatedEntity;
                Image = View;
                ToolTip = 'Open the record that is associated with this error message.';

                trigger OnAction()
                var
                    PageManagement: Codeunit "Page Management";
                    IsHandled: Boolean;
                begin
                    OnOpenRelatedRecord(Rec, IsHandled);
                    if not IsHandled then
                        PageManagement.PageRun(Rec."Record ID");
                end;
            }
        }
        addafter(Category_Process)
        {
            actionref(OpenRelatedRecord_Promoted; OpenRelatedRecord)
            {
            }
        }
    }

    var
        EnableOpenRelatedEntity: Boolean;

    trigger OnAfterGetCurrRecord()
    begin
        EnableActions();
    end;

    local procedure EnableActions()
    var
        RecID: RecordID;
    begin
        RecID := Rec."Record ID";
        EnableOpenRelatedEntity := RecID.TableNo <> 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenRelatedRecord(ErrorMessage: Record "Error Message"; var IsHandled: Boolean)
    begin
    end;
}
