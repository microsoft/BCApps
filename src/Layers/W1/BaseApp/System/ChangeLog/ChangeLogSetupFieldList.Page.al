namespace System.Diagnostics;

using System.Reflection;

page 594 "Change Log Setup (Field) List"
{
    Caption = 'Change Log Setup (Field) List';
    DataCaptionExpression = PageCaptionText;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Field";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'No.';
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the number of the field.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Caption';
                    DrillDown = false;
                    Editable = false;
                    ToolTip = 'Specifies the caption of the field, that is, the name that will be shown in the user interface.';
                }
                field("Log Insertion"; LogIns)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Insertion';
                    ToolTip = 'Specifies whether to log the insertion for the selected line on the change log.';
                    Editable = PageIsEditable;
                    Enabled = PageIsEditable;
                    Visible = LogInsertionVisible;

                    trigger OnValidate()
                    begin
                        if not InsVisible then begin
                            LogInsertionVisible := false;
                            Error(CannotChangeColumnErr);
                        end;
                        UpdateRec();
                    end;
                }
                field("Log Modification"; LogMod)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Modification';
                    ToolTip = 'Specifies whether to log the modification for the selected line on the change log.';
                    Editable = PageIsEditable;
                    Enabled = PageIsEditable;
                    Visible = LogModificationVisible;

                    trigger OnValidate()
                    begin
                        if not ModVisible then begin
                            LogModificationVisible := false;
                            Error(CannotChangeColumnErr);
                        end;
                        UpdateRec();
                    end;
                }
                field("Log Deletion"; LogDel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Deletion';
                    ToolTip = 'Specifies whether to log the deletion for the selected line on the change log.';
                    Editable = PageIsEditable;
                    Enabled = PageIsEditable;
                    Visible = LogDeletionVisible;

                    trigger OnValidate()
                    begin
                        if not DelVisible then begin
                            LogDeletionVisible := false;
                            Error(CannotChangeColumnErr);
                        end;
                        UpdateRec();
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetRec();
        TransFromRec();
    end;

    trigger OnAfterGetRecord()
    begin
        PageIsEditable := CurrPage.Editable();
        GetRec();
        TransFromRec();
    end;

    trigger OnInit()
    begin
        LogDeletionVisible := true;
        LogModificationVisible := true;
        LogInsertionVisible := true;
    end;

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange(Class, Rec.Class::Normal);
        Rec.FilterGroup(0);
        PageCaptionText := Format(Rec.TableNo) + ' ' + Rec.TableName;
    end;

    var
        ChangeLogSetupField: Record "Change Log Setup (Field)";
        CannotChangeColumnErr: Label 'You cannot change this column.';
        LogIns: Boolean;
        LogMod: Boolean;
        LogDel: Boolean;
        InsVisible: Boolean;
        ModVisible: Boolean;
        DelVisible: Boolean;
        LogInsertionVisible: Boolean;
        LogModificationVisible: Boolean;
        LogDeletionVisible: Boolean;
        PageCaptionText: Text[250];
        PageIsEditable: Boolean;

    procedure SelectColumn(NewInsVisible: Boolean; NewModVisible: Boolean; NewDelVisible: Boolean)
    begin
        InsVisible := NewInsVisible;
        ModVisible := NewModVisible;
        DelVisible := NewDelVisible;

        LogInsertionVisible := InsVisible;
        LogModificationVisible := ModVisible;
        LogDeletionVisible := DelVisible;
    end;

    local procedure UpdateRec()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRec(Rec, LogIns, LogMod, LogDel, IsHandled);
        if IsHandled then
            exit;

        GetRec();
        TransToRec();
        if not (ChangeLogSetupField."Log Insertion" or ChangeLogSetupField."Log Modification" or ChangeLogSetupField."Log Deletion") then begin
            if ChangeLogSetupField.Delete() then;
        end else
            if not ChangeLogSetupField.Modify() then
                ChangeLogSetupField.Insert();
    end;

    local procedure GetRec()
    begin
        if not ChangeLogSetupField.Get(Rec.TableNo, Rec."No.") then begin
            ChangeLogSetupField.Init();
            ChangeLogSetupField."Table No." := Rec.TableNo;
            ChangeLogSetupField."Table Caption" := Rec.TableName;
            ChangeLogSetupField."Field No." := Rec."No.";
            ChangeLogSetupField."Field Caption" := Rec."Field Caption";
        end;
    end;

    local procedure TransFromRec()
    begin
        LogIns := ChangeLogSetupField."Log Insertion";
        LogMod := ChangeLogSetupField."Log Modification";
        LogDel := ChangeLogSetupField."Log Deletion";
    end;

    local procedure TransToRec()
    begin
        ChangeLogSetupField."Log Insertion" := LogIns;
        ChangeLogSetupField."Log Modification" := LogMod;
        ChangeLogSetupField."Log Deletion" := LogDel;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRec(Field: Record Field; LogIns: Boolean; LogMod: Boolean; LogDel: Boolean; var IsHandled: Boolean)
    begin
    end;
}

