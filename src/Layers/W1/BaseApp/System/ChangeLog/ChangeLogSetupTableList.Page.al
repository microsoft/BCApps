namespace System.Diagnostics;

using System.Reflection;
using System.Utilities;

page 593 "Change Log Setup (Table) List"
{
    Caption = 'Change Log Setup (Table) List';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = true;
    PageType = List;
    SourceTable = AllObjWithCaption;
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ID';
                    Editable = false;
                    ToolTip = 'Specifies the ID of the table. ';
                }
                field("Object Caption"; Rec."Object Caption")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the table.';
                }
                field(LogInsertion; ChangeLogSetupTable."Log Insertion")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Insertion';
                    Editable = PageIsEditable;
                    Enabled = PageIsEditable;
                    OptionCaption = ' ,Some Fields,All Fields';
                    ToolTip = 'Specifies where insertions of new data are logged. Blank: No insertions in any fields are logged. Some fields: Insertions are logged for selected fields. All fields: Insertions are logged for all fields.';

                    trigger OnAssistEdit()
                    begin
                        ChangeLogSetupTable.TestField("Log Insertion", ChangeLogSetupTable."Log Insertion"::"Some Fields");
                        AssistEdit();
                    end;

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                        NewValue: Option;
                    begin
                        if ChangeLogSetupTable."Table No." <> Rec."Object ID" then begin
                            NewValue := ChangeLogSetupTable."Log Insertion";
                            GetRec();
                            ChangeLogSetupTable."Log Insertion" := NewValue;
                        end;

                        if xChangeLogSetupTable.Get(ChangeLogSetupTable."Table No.") then
                            if (xChangeLogSetupTable."Log Insertion" = xChangeLogSetupTable."Log Insertion"::"Some Fields") and
                               (xChangeLogSetupTable."Log Insertion" <> ChangeLogSetupTable."Log Insertion")
                            then
                                if ConfirmManagement.GetResponseOrDefault(
                                     StrSubstNo(RemoveSelectionsQst, xChangeLogSetupTable.FieldCaption("Log Insertion"), xChangeLogSetupTable."Log Insertion"), true)
                                then
                                    ChangeLogSetupTable.DelChangeLogFields(0);

                        ChangeLogSetupTableLogInsertio();
                    end;
                }
                field(LogModification; ChangeLogSetupTable."Log Modification")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Modification';
                    Editable = PageIsEditable;
                    Enabled = PageIsEditable;
                    OptionCaption = ' ,Some Fields,All Fields';
                    ToolTip = 'Specifies that any modification of data is logged.';

                    trigger OnAssistEdit()
                    begin
                        ChangeLogSetupTable.TestField("Log Modification", ChangeLogSetupTable."Log Modification"::"Some Fields");
                        AssistEdit();
                    end;

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                        NewValue: Option;
                    begin
                        if ChangeLogSetupTable."Table No." <> Rec."Object ID" then begin
                            NewValue := ChangeLogSetupTable."Log Modification";
                            GetRec();
                            ChangeLogSetupTable."Log Modification" := NewValue;
                        end;

                        if xChangeLogSetupTable.Get(ChangeLogSetupTable."Table No.") then
                            if (xChangeLogSetupTable."Log Modification" = xChangeLogSetupTable."Log Modification"::"Some Fields") and
                               (xChangeLogSetupTable."Log Modification" <> ChangeLogSetupTable."Log Modification")
                            then
                                if ConfirmManagement.GetResponseOrDefault(
                                     StrSubstNo(RemoveSelectionsQst, xChangeLogSetupTable.FieldCaption("Log Modification"), xChangeLogSetupTable."Log Modification"), true)
                                then
                                    ChangeLogSetupTable.DelChangeLogFields(1);
                        ChangeLogSetupTableLogModifica();
                    end;
                }
                field(LogDeletion; ChangeLogSetupTable."Log Deletion")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Deletion';
                    Editable = PageIsEditable;
                    Enabled = PageIsEditable;
                    OptionCaption = ' ,Some Fields,All Fields';
                    ToolTip = 'Specifies that any deletion of data is logged.';

                    trigger OnAssistEdit()
                    begin
                        ChangeLogSetupTable.TestField("Log Deletion", ChangeLogSetupTable."Log Deletion"::"Some Fields");
                        AssistEdit();
                    end;

                    trigger OnValidate()
                    var
                        ConfirmManagement: Codeunit "Confirm Management";
                        NewValue: Option;
                    begin
                        if ChangeLogSetupTable."Table No." <> Rec."Object ID" then begin
                            NewValue := ChangeLogSetupTable."Log Deletion";
                            GetRec();
                            ChangeLogSetupTable."Log Deletion" := NewValue;
                        end;

                        if xChangeLogSetupTable.Get(ChangeLogSetupTable."Table No.") then
                            if (xChangeLogSetupTable."Log Deletion" = xChangeLogSetupTable."Log Deletion"::"Some Fields") and
                               (xChangeLogSetupTable."Log Deletion" <> ChangeLogSetupTable."Log Deletion")
                            then
                                if ConfirmManagement.GetResponseOrDefault(
                                     StrSubstNo(RemoveSelectionsQst, xChangeLogSetupTable.FieldCaption("Log Deletion"), xChangeLogSetupTable."Log Deletion"), true)
                                then
                                    ChangeLogSetupTable.DelChangeLogFields(2);
                        ChangeLogSetupTableLogDeletion();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        GetRec();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        PageIsEditable := CurrPage.Editable();
    end;

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Object Type", Rec."Object Type"::Table);
        Rec.SetRange("Object ID", 0, 2000000000);
        MonitorSensitiveField.ExcludeMonitorTablesFromChangeLog(Rec);
        Rec.FilterGroup(0);
    end;

    var
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        xChangeLogSetupTable: Record "Change Log Setup (Table)";
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
        RemoveSelectionsQst: Label 'You have changed the %1 field to no longer be %2. Do you want to remove the field selections?', Comment = '%1: Field caption, %2: The selected log action. Example: You have changed the Log Modification field to no longer be Some Fields';
        CannotSelectTableErr: Label 'Change log cannot be enabled for the table %1.', Comment = '%1: Table caption.';
        PageIsEditable: Boolean;
        ChangeLogSettingsUpdated: Boolean;

    local procedure AssistEdit()
    var
        "Field": Record "Field";
        ChangeLogSetupFieldList: Page "Change Log Setup (Field) List";
    begin
        Field.FilterGroup(2);
        Field.SetRange(TableNo, Rec."Object ID");
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.FilterGroup(0);
        ChangeLogSetupFieldList.SelectColumn(
              ChangeLogSetupTable."Log Insertion" = ChangeLogSetupTable."Log Insertion"::"Some Fields",
              ChangeLogSetupTable."Log Modification" = ChangeLogSetupTable."Log Modification"::"Some Fields",
              ChangeLogSetupTable."Log Deletion" = ChangeLogSetupTable."Log Deletion"::"Some Fields");
        ChangeLogSetupFieldList.SetTableView(Field);
        ChangeLogSetupFieldList.Run();
    end;

    local procedure UpdateRec()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRec(Rec, ChangeLogSetupTable, IsHandled);
        if IsHandled then
            exit;

        if ChangeLogSetupTable."Table No." = Database::"Change Log Entry" then begin
            ChangeLogSetupTable.CalcFields("Table Caption");
            Error(CannotSelectTableErr, ChangeLogSetupTable."Table Caption");
        end;

        if (ChangeLogSetupTable."Log Insertion" = ChangeLogSetupTable."Log Insertion"::" ") and
           (ChangeLogSetupTable."Log Modification" = ChangeLogSetupTable."Log Modification"::" ") and
           (ChangeLogSetupTable."Log Deletion" = ChangeLogSetupTable."Log Deletion"::" ")
        then begin
            if ChangeLogSetupTable.Delete() then;
        end else
            if not ChangeLogSetupTable.Modify() then
                ChangeLogSetupTable.Insert();

        ChangeLogSettingsUpdated := true;
    end;

    local procedure GetRec()
    begin
        if not ChangeLogSetupTable.Get(Rec."Object ID") then begin
            ChangeLogSetupTable.Init();
            ChangeLogSetupTable."Table No." := Rec."Object ID";
        end;
        OnAfterGetRec(ChangeLogSetupTable);
    end;

    procedure SetSource()
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        Rec.DeleteAll();

        AllObjWithCaption.SetCurrentKey("Object Type", "Object ID");
        AllObjWithCaption.SetRange("Object Type", Rec."Object Type"::Table);
        AllObjWithCaption.SetRange("Object ID", 0, 2000000006);

        if AllObjWithCaption.Find('-') then
            repeat
                Rec := AllObjWithCaption;
                Rec.Insert();
            until AllObjWithCaption.Next() = 0;

        Rec.FindFirst();
    end;

    procedure IsChangeLogSettingsUpdated(): Boolean
    begin
        exit(ChangeLogSettingsUpdated);
    end;

    local procedure ChangeLogSetupTableLogInsertio()
    begin
        UpdateRec();
    end;

    local procedure ChangeLogSetupTableLogModifica()
    begin
        UpdateRec();
    end;

    local procedure ChangeLogSetupTableLogDeletion()
    begin
        UpdateRec();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetRec(var ChangeLogSetupTable: Record "Change Log Setup (Table)")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRec(var AllObjWithCaption: Record AllObjWithCaption; ChangeLogSetupTable: Record "Change Log Setup (Table)"; var IsHandled: Boolean)
    begin
    end;
}
