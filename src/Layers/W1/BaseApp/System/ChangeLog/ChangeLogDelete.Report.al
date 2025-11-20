namespace System.Diagnostics;

using System.Utilities;
using System.Reflection;

report 510 "Change Log - Delete"
{
    Caption = 'Change Log - Delete';
    Permissions = TableData "Change Log Entry" = rid;
    ProcessingOnly = true;
    Extensible = false;

    dataset
    {
        dataitem("Change Log Entry"; "Change Log Entry")
        {
            DataItemTableView = sorting("Table No.", "Primary Key Field 1 Value");
            RequestFilterFields = "Date and Time", "Table No.";

            trigger OnPostDataItem()
            begin
                TryDeleteProtectedRecords();
            end;

            trigger OnPreDataItem()
            var
                TableKey: Codeunit "Table Key";
            begin
                if ShouldDisableIndexes then
                    TableKey.DisableAll(Database::"Change Log Entry");

                SetRange(Protected, false);
                SetRange("Field Log Entry Feature", "Field Log Entry Feature"::"Change Log");
                DeleteAll();
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(DisableIndexes; ShouldDisableIndexes)
                    {
                        ApplicationArea = All;
                        Caption = 'Disable Indexes';
                        ToolTip = 'Specifies if indexes should be disabled on the Change Log Entry table before deleting the records. This may speed up the process when a lot of records are deleted at once.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            if "Change Log Entry".GetFilter("Date and Time") = '' then
                "Change Log Entry".SetFilter("Date and Time", '..%1', CreateDateTime(CalcDate('<-1Y>', Today), 0T));
        end;

        trigger OnQueryClosePage(CloseAction: Action): Boolean
        var
            ChangeLogEntry: Record "Change Log Entry";
            ConfirmManagement: Codeunit "Confirm Management";
        begin
            if CloseAction = Action::Cancel then
                exit(true);
            if "Change Log Entry".GetFilter("Date and Time") <> '' then begin
                ChangeLogEntry.CopyFilters("Change Log Entry");
                if not ChangeLogEntry.FindLast() then
                    Error(NothingToDeleteErr);
                if DT2Date(ChangeLogEntry."Date and Time") > CalcDate('<-1Y>', Today) then
                    if not ConfirmManagement.GetResponse(RecentEntriesDeleteQst, false) then
                        exit(false);
            end else
                if not ConfirmManagement.GetResponse(NoDateFilterQst, false) then
                    exit(false);
            exit(true);
        end;
    }

    trigger OnPostReport()
    var
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if not GuiAllowed() then
            exit;
        Window.Close();
        if not TempErrorMessage.IsEmpty() then begin
            if ConfirmManagement.GetResponse(SomeEntriesNotDeletedQst, true) then
                Page.RunModal(Page::"Error Messages", TempErrorMessage);
        end else
            Message(DeletedMsg);
    end;

    trigger OnPreReport()
    begin
        if GuiAllowed() then
            Window.Open(DialogMsg);
    end;

    var
        TempErrorMessage: Record "Error Message" temporary;
        ShouldDisableIndexes: Boolean;
        Window: Dialog;
        DialogMsg: Label 'Entries are being deleted...\\@1@@@@@@@@@@@@';
        CounterTotal: Integer;
        Counter: Integer;
        NoDateFilterQst: Label 'You have not defined a date filter. Do you want to continue?';
        RecentEntriesDeleteQst: Label 'Your date filter allows deletion of entries that are less than one year old. Do you want to continue?';
        NothingToDeleteErr: Label 'There are no entries within the filter.';
        DeletedMsg: Label 'The selected entries were deleted.';
        SomeEntriesNotDeletedQst: Label 'One or more entries cannot be deleted.\\Do you want to open the list of errors?';

    local procedure TryDeleteProtectedRecords()
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        ChangeLogEntry.CopyFilters("Change Log Entry");
        ChangeLogEntry.SetRange(Protected, true);
        CounterTotal := ChangeLogEntry.Count();
        if ChangeLogEntry.FindSet(true) then
            repeat
                Counter += 1;
                if GuiAllowed() then
                    Window.Update(1, Round(Counter / CounterTotal * 10000, 1));
                Commit();
                if not Codeunit.Run(Codeunit::"Change Log Entry - Delete", ChangeLogEntry) then
                    TempErrorMessage.LogLastError();
            until ChangeLogEntry.Next() = 0;
    end;
}