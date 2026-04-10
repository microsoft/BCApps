#pragma warning disable AA0247
page 17249 "Lookup Code (RecordRef)"
{
    Caption = 'Lookup Code (RecordRef)';
    DataCaptionExpression = FormTitle;
    Editable = false;
    PageType = List;
    SourceTable = "Lookup Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control100)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'This field is used internally.';
                }
                field(Text; Rec.Text)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description of the record or entry.';
                }
            }
        }
    }

    actions
    {
    }

    var
        LookupMgt: Codeunit "Lookup Management";
        xRecordRef: RecordRef;
        xFieldRefCode: FieldRef;
        xFieldRefText: FieldRef;
        FormTitle: Text[1024];
        RecordRefID: Integer;
        FieldCodeID: Integer;
        FieldTextID: Integer;

    [Scope('OnPrem')]
    procedure GetCodeRecordRef(): Code[20]
    begin
        exit(Rec.Code);
    end;

    [Scope('OnPrem')]
    procedure SetRecordRef(TableID: Integer; FieldID: Integer; TableRelationID: Integer; FieldRelationNo: Integer): Boolean
    begin
        if LookupMgt.PrepeareLookupCode(TableID, FieldID, RecordRefID, FieldCodeID, FieldTextID, TableRelationID, FieldRelationNo) then begin
            xRecordRef.Open(RecordRefID);
            FormTitle := xRecordRef.Caption;
            if xRecordRef.Find('-') then begin
                xFieldRefCode := xRecordRef.Field(FieldCodeID);
                xFieldRefText := xRecordRef.Field(FieldTextID);
                repeat
                    Rec.Code := xFieldRefCode.Value();
                    Rec.Text := xFieldRefText.Value();
                    Rec.Insert();
                until xRecordRef.Next() = 0;
            end;
            xRecordRef.Close();
            exit(true);
        end;
    end;
}

