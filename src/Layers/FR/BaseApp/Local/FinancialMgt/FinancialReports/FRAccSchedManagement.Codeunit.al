// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

codeunit 10802 "FR AccSchedManagement"
{
    TableNo = "FR Acc. Schedule Line";

    trigger OnRun()
    begin
    end;

    var
        Text1120000: Label 'DEFAULT';
        Text1120001: Label 'Default Schedule';

    [Scope('OnPrem')]
    procedure OpenSchedule(var CurrentSchedName: Code[10]; var AccSchedLine: Record "FR Acc. Schedule Line")
    begin
        CheckTemplateName(CurrentSchedName);
        AccSchedLine.FilterGroup(2);
        AccSchedLine.SetRange("Schedule Name", CurrentSchedName);
        AccSchedLine.FilterGroup(0);
    end;

    [Scope('OnPrem')]
    procedure CheckTemplateName(var CurrentSchedName: Code[10])
    var
        AccSchedName: Record "FR Acc. Schedule Name";
    begin
        if not AccSchedName.Get(CurrentSchedName) then begin
            if not AccSchedName.FindFirst() then begin
                AccSchedName.Init();
                AccSchedName.Name := Text1120000;
                AccSchedName.Description := Text1120001;
                AccSchedName.Insert();
                Commit();
            end;
            CurrentSchedName := AccSchedName.Name;
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckName(CurrentSchedName: Code[10])
    var
        AccSchedName: Record "FR Acc. Schedule Name";
    begin
        AccSchedName.Get(CurrentSchedName);
    end;

    [Scope('OnPrem')]
    procedure SetName(CurrentSchedName: Code[10]; var AccSchedLine: Record "FR Acc. Schedule Line")
    begin
        AccSchedLine.FilterGroup(2);
        AccSchedLine.SetRange("Schedule Name", CurrentSchedName);
        AccSchedLine.FilterGroup(0);
        if AccSchedLine.Find('-') then;
    end;

    [Scope('OnPrem')]
    procedure LookupName(CurrentSchedName: Code[10]; var EntrdSchedName: Text[10]): Boolean
    var
        AccSchedName: Record "FR Acc. Schedule Name";
    begin
        AccSchedName.Name := CurrentSchedName;
        if PAGE.RunModal(0, AccSchedName) <> ACTION::LookupOK then
            exit(false);

        EntrdSchedName := AccSchedName.Name;
        exit(true);
    end;
}

