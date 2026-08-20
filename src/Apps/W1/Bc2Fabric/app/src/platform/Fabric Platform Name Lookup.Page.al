namespace Microsoft.Bc2Fabric;

using Microsoft.Utilities;

page 150009 "Fabric Platform Name Lookup"
{
    Caption = 'Select';
    PageType = List;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Name; Rec.Name)
                {
                    Caption = 'Name';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the item to select.';
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(Select_Promoted; Select) { }
        }
        area(Processing)
        {
            action(Select)
            {
                Caption = 'Select';
                ApplicationArea = All;
                ToolTip = 'Select the highlighted record.';

                trigger OnAction()
                var
                    LookupState: Codeunit "Fabric Platform Lookup State";
                begin
                    LookupState.SetSelected(Rec.Name, Rec.Value);
                    CurrPage.Close();
                end;
            }
        }
    }

    procedure SetSource(var TempBuffer: Record "Name/Value Buffer" temporary)
    begin
        Rec.Copy(TempBuffer, true);
        if Rec.FindFirst() then;
    end;

    procedure GetSelectedRecord(var TempBuffer: Record "Name/Value Buffer" temporary)
    var
        LookupState: Codeunit "Fabric Platform Lookup State";
    begin
        TempBuffer.Name := CopyStr(LookupState.GetSelectedName(), 1, MaxStrLen(TempBuffer.Name));
        TempBuffer.Value := CopyStr(LookupState.GetSelectedValue(), 1, MaxStrLen(TempBuffer.Value));
    end;

    procedure IsRecordSelected(): Boolean
    var
        LookupState: Codeunit "Fabric Platform Lookup State";
    begin
        exit(LookupState.IsSelected());
    end;
}
