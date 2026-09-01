namespace System.Utilities;

page 701 "Error Messages Part"
{
    Caption = 'Error Messages';
    DeleteAllowed = false;
    Editable = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    SourceTable = "Error Message";
    SourceTableTemporary = true;
    SourceTableView = sorting("Message Type", ID)
                      order(ascending);

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the message is an error, a warning, or information.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies error messages that occur during data processing.';
                    Visible = false;
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field where the error occurred.';
                    Width = 10;
                }
                field(Description; Rec."Message")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    Enabled = EnableOpenRelatedEntity;
                    StyleExpr = StyleText;
                    ToolTip = 'Specifies the message.';

                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ViewDetails)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'View Details';
                Image = ViewDetails;
                ToolTip = 'Show more information about this error message.';

                trigger OnAction()
                begin
                    PAGE.Run(PAGE::"Error Messages", Rec);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        EnableActions();
    end;

    trigger OnAfterGetRecord()
    begin
        SetStyle();
    end;

    var
        RecordIDToHighlight: RecordID;
        StyleText: Text[20];

    protected var
        EnableOpenRelatedEntity: Boolean;
        DisableOpenRelatedEntity: Boolean;

    procedure SetRecords(var TempErrorMessage: Record "Error Message" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        TempErrorMessage.Reset();
        if TempErrorMessage.FindFirst() then
            Rec.Copy(TempErrorMessage, true);
    end;

    procedure SetRecordID(RecID: RecordID)
    var
        ErrorMessage: Record "Error Message";
        TempErrorMessage: Record "Error Message" temporary;
    begin
        ErrorMessage.SetRange("Record ID", RecId);
        ErrorMessage.CopyToTemp(TempErrorMessage);
        SetRecords(TempErrorMessage);
        CurrPage.Update();
    end;

    procedure GetStyleOfRecord(RecordVariant: Variant; var StyleExpression: Text)
    var
        RecordRef: RecordRef;
    begin
        if not RecordVariant.IsRecord then
            exit;

        RecordRef.GetTable(RecordVariant);
        RecordIDToHighlight := RecordRef.RecordId;

        if Rec.HasErrorMessagesRelatedTo(RecordVariant) then
            StyleExpression := 'Attention'
        else
            StyleExpression := 'None';
    end;

    local procedure SetStyle()
    var
        RecID: RecordID;
    begin
        RecID := Rec."Record ID";

        case Rec."Message Type" of
            Rec."Message Type"::Error:
                if RecID = RecordIDToHighlight then
                    StyleText := 'Unfavorable'
                else
                    StyleText := 'Attention';
            Rec."Message Type"::Warning,
          Rec."Message Type"::Information:
                if RecID = RecordIDToHighlight then
                    StyleText := 'Strong'
                else
                    StyleText := 'None';
        end;
    end;

    local procedure EnableActions()
    var
        RecID: RecordID;
    begin
        RecID := Rec."Record ID";
        if DisableOpenRelatedEntity then
            EnableOpenRelatedEntity := false
        else
            EnableOpenRelatedEntity := RecID.TableNo <> 0;
    end;

    procedure DisableActions()
    begin
        DisableOpenRelatedEntity := true;
    end;
}

