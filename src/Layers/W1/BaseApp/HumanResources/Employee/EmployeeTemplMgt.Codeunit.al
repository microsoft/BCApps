// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.Finance.Dimension;
using Microsoft.Foundation.NoSeries;
using Microsoft.Utilities;
using System.Utilities;

codeunit 1387 "Employee Templ. Mgt."
{
    trigger OnRun()
    begin
    end;

    var
        UpdateExistingValuesQst: Label 'You are about to apply the template to selected records. Data from the template will replace data for the records in fields that do not already contain data. Do you want to continue?';

    procedure InsertEmployeeFromTemplate(var Employee: Record Employee): Boolean
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        if not IsEnabled() then
            exit(false);

        if not SelectEmployeeTemplate(EmployeeTempl) then
            exit(false);

        Employee.Init();
        InitEmployeeNo(Employee, EmployeeTempl);
        Employee.Insert(true);

        ApplyEmployeeTemplate(Employee, EmployeeTempl);

        exit(true);
    end;

    local procedure ApplyTemplate(var Employee: Record Employee; EmployeeTempl: Record "Employee Templ.")
    begin
        Employee.City := EmployeeTempl.City;
        Employee."Post Code" := EmployeeTempl."Post Code";
        Employee.County := EmployeeTempl.County;
        Employee.Gender := EmployeeTempl.Gender;
        Employee."Country/Region Code" := EmployeeTempl."Country/Region Code";
        Employee."Statistics Group Code" := EmployeeTempl."Statistics Group Code";
        Employee."Employee Posting Group" := EmployeeTempl."Employee Posting Group";
        Employee."Application Method" := EmployeeTempl."Application Method";
        Employee."Cost Center Code" := EmployeeTempl."Cost Center Code";
        Employee."Cost Object Code" := EmployeeTempl."Cost Object Code";
        OnApplyTemplateOnBeforeEmployeeModify(Employee, EmployeeTempl);
        Employee.Modify(true);
    end;

    procedure SelectEmployeeTemplateFromContact(var EmployeeTempl: Record "Employee Templ."): Boolean
    begin
        exit(SelectEmployeeTemplate(EmployeeTempl));
    end;

    local procedure SelectEmployeeTemplate(var EmployeeTempl: Record "Employee Templ."): Boolean
    var
        SelectEmployeeTemplList: Page "Select Employee Templ. List";
    begin
        if EmployeeTempl.Count = 1 then begin
            EmployeeTempl.FindFirst();
            exit(true);
        end;

        if (EmployeeTempl.Count > 1) and GuiAllowed then begin
            SelectEmployeeTemplList.SetTableView(EmployeeTempl);
            SelectEmployeeTemplList.LookupMode(true);
            if SelectEmployeeTemplList.RunModal() = Action::LookupOK then begin
                SelectEmployeeTemplList.GetRecord(EmployeeTempl);
                exit(true);
            end;
        end;

        exit(false);
    end;

    local procedure InsertDimensions(DestNo: Code[20]; SourceNo: Code[20]; DestTableId: Integer; SourceTableId: Integer)
    var
        SourceDefaultDimension: Record "Default Dimension";
        DestDefaultDimension: Record "Default Dimension";
    begin
        SourceDefaultDimension.SetRange("Table ID", SourceTableId);
        SourceDefaultDimension.SetRange("No.", SourceNo);
        if SourceDefaultDimension.FindSet() then
            repeat
                DestDefaultDimension.Init();
                DestDefaultDimension.Validate("Table ID", DestTableId);
                DestDefaultDimension.Validate("No.", DestNo);
                DestDefaultDimension.Validate("Dimension Code", SourceDefaultDimension."Dimension Code");
                DestDefaultDimension.Validate("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
                DestDefaultDimension.Validate("Value Posting", SourceDefaultDimension."Value Posting");
                if not DestDefaultDimension.Get(DestDefaultDimension."Table ID", DestDefaultDimension."No.", DestDefaultDimension."Dimension Code") then
                    DestDefaultDimension.Insert(true);
            until SourceDefaultDimension.Next() = 0;
    end;

    procedure TemplatesAreNotEmpty(): Boolean
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        if not IsEnabled() then
            exit(false);

        exit(not EmployeeTempl.IsEmpty);
    end;

    procedure ApplyEmployeeTemplate(var Employee: Record Employee; EmployeeTempl: Record "Employee Templ.")
    begin
        ApplyEmployeeTemplate(Employee, EmployeeTempl, false);
    end;

    procedure ApplyEmployeeTemplate(var Employee: Record Employee; EmployeeTempl: Record "Employee Templ."; UpdateExistingValues: Boolean)
    begin
        ApplyTemplate(Employee, EmployeeTempl);
        InsertDimensions(Employee."No.", EmployeeTempl.Code, Database::Employee, Database::"Employee Templ.");
        Employee.Get(Employee."No.");
    end;

    procedure IsEnabled() Result: Boolean
    var
        TemplateFeatureMgt: Codeunit "Template Feature Mgt.";
    begin
        Result := TemplateFeatureMgt.IsEnabled();

        OnAfterIsEnabled(Result);
    end;

    procedure InitEmployeeNo(var Employee: Record Employee; EmployeeTempl: Record "Employee Templ.")
    var
        NoSeries: Codeunit "No. Series";
    begin
        if EmployeeTempl."No. Series" = '' then
            exit;

            Employee."No. Series" := EmployeeTempl."No. Series";
            Employee."No." := NoSeries.GetNextNo(Employee."No. Series");
    end;

    procedure SaveAsTemplate(Employee: Record Employee)
    begin
        CreateTemplateFromEmployee(Employee);
    end;

    local procedure CreateTemplateFromEmployee(Employee: Record Employee)
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        if not IsEnabled() then
            exit;

        InsertTemplateFromEmployee(EmployeeTempl, Employee);
        InsertDimensions(EmployeeTempl.Code, Employee."No.", Database::"Employee Templ.", Database::Employee);
        EmployeeTempl.Get(EmployeeTempl.Code);
        ShowEmployeeTemplCard(EmployeeTempl);
    end;

    local procedure InsertTemplateFromEmployee(var EmployeeTempl: Record "Employee Templ."; Employee: Record Employee)
    begin
        EmployeeTempl.Init();
        EmployeeTempl.Code := GetEmployeeTemplCode();

        EmployeeTempl.City := Employee.City;
        EmployeeTempl."Post Code" := Employee."Post Code";
        EmployeeTempl.County := Employee.County;
        EmployeeTempl.Gender := Employee.Gender;
        EmployeeTempl."Country/Region Code" := Employee."Country/Region Code";
        EmployeeTempl."Statistics Group Code" := Employee."Statistics Group Code";
        EmployeeTempl."Employee Posting Group" := Employee."Employee Posting Group";
        EmployeeTempl."Application Method" := Employee."Application Method";
        EmployeeTempl."Cost Center Code" := Employee."Cost Center Code";
        EmployeeTempl."Cost Object Code" := Employee."Cost Object Code";
        OnInsertTemplateFromEmployeeOnBeforeEmployeeTemplInsert(EmployeeTempl, Employee);
        EmployeeTempl.Insert();
    end;

    local procedure GetEmployeeTemplCode() EmployeeTemplCode: Code[20]
    var
        Employee: Record Employee;
        EmployeeTempl: Record "Employee Templ.";
    begin
        if EmployeeTempl.FindLast() and (IncStr(EmployeeTempl.Code) <> '') then
            EmployeeTemplCode := EmployeeTempl.Code
        else
            EmployeeTemplCode := CopyStr(Employee.TableCaption(), 1, 4) + '000001';

        while EmployeeTempl.Get(EmployeeTemplCode) do
            EmployeeTemplCode := IncStr(EmployeeTemplCode);
    end;

    local procedure ShowEmployeeTemplCard(EmployeeTempl: Record "Employee Templ.")
    var
        EmployeeTemplCard: Page "Employee Templ. Card";
    begin
        if not GuiAllowed then
            exit;

        Commit();
        EmployeeTemplCard.SetRecord(EmployeeTempl);
        EmployeeTemplCard.LookupMode := true;
        if EmployeeTemplCard.RunModal() = Action::LookupCancel then begin
            EmployeeTempl.Get(EmployeeTempl.Code);
            EmployeeTempl.Delete(true);
        end;
    end;

    procedure UpdateEmployeeFromTemplate(var Employee: Record Employee)
    begin
        UpdateFromTemplate(Employee);
    end;

    local procedure UpdateFromTemplate(var Employee: Record Employee)
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        if not CanBeUpdatedFromTemplate(EmployeeTempl) then
            exit;

        if not GetUpdateExistingValuesParam() then
            exit;

        ApplyEmployeeTemplate(Employee, EmployeeTempl, true);
    end;

    local procedure CanBeUpdatedFromTemplate(var EmployeeTempl: Record "Employee Templ."): Boolean
    begin
        if not IsEnabled() then
            exit(false);

        if not SelectEmployeeTemplate(EmployeeTempl) then
            exit(false);

        exit(true);
    end;

    procedure UpdateEmployeesFromTemplate(var Employee: Record Employee)
    begin
        UpdateMultipleFromTemplate(Employee);
    end;

    local procedure UpdateMultipleFromTemplate(var Employee: Record Employee)
    var
        EmployeeTempl: Record "Employee Templ.";
    begin
        if not CanBeUpdatedFromTemplate(EmployeeTempl) then
            exit;

        if Employee.FindSet() then
            repeat
                ApplyEmployeeTemplate(Employee, EmployeeTempl, GetUpdateExistingValuesParam());
            until Employee.Next() = 0;
    end;

    local procedure GetUpdateExistingValuesParam() Result: Boolean
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUpdateExistingValuesParam(Result, IsHandled);
        if not IsHandled then
            Result := ConfirmManagement.GetResponseOrDefault(UpdateExistingValuesQst, false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsEnabled(var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnApplyTemplateOnBeforeEmployeeModify(var Employee: Record Employee; EmployeeTempl: Record "Employee Templ.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTemplateFromEmployeeOnBeforeEmployeeTemplInsert(var EmployeeTempl: Record "Employee Templ."; Employee: Record Employee)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUpdateExistingValuesParam(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}
