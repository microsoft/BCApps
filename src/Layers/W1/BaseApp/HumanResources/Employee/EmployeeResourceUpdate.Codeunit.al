// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.HumanResources.Employee;

using Microsoft.Projects.Resources.Resource;

codeunit 5200 "Employee/Resource Update"
{
    Permissions = TableData Resource = rimd;

    trigger OnRun()
    begin
    end;

    var
        Res: Record Resource;

    procedure HumanResToRes(OldEmployee: Record Employee; Employee: Record Employee)
    begin
        if (Employee."Resource No." <> '') and IsResourceUpdateNeeded(OldEmployee, Employee) then
            ResUpdate(Employee)
        else
            exit;
    end;

    procedure ResUpdate(Employee: Record Employee)
    begin
        Res.Get(Employee."Resource No.");
        Res."Job Title" := Employee."Job Title";
        Res.Name := CopyStr(Employee.FullName(), 1, MaxStrLen(Res.Name));
        Res.Address := Employee.Address;
        Res."Address 2" := Employee."Address 2";
        Res."Post Code" := Employee."Post Code";
        Res.County := Employee.County;
        Res.City := Employee.City;
        Res."Country/Region Code" := Employee."Country/Region Code";
        Res."Social Security No." := Employee."Social Security No.";
        Res."Employment Date" := Employee."Employment Date";
        OnAfterUpdateResource(Res, Employee);
        Res.Modify(true)
    end;

    local procedure IsResourceUpdateNeeded(OldEmployee: Record Employee; Employee: Record Employee): Boolean
    var
        UpdateNeeded: Boolean;
    begin
        UpdateNeeded :=
          (OldEmployee."Resource No." <> Employee."Resource No.") or
          (OldEmployee."Job Title" <> Employee."Job Title") or
          (OldEmployee."First Name" <> Employee."First Name") or
          (OldEmployee."Last Name" <> Employee."Last Name") or
          (OldEmployee.Address <> Employee.Address) or
          (OldEmployee."Address 2" <> Employee."Address 2") or
          (OldEmployee."Post Code" <> Employee."Post Code") or
          (OldEmployee.County <> Employee.County) or
          (OldEmployee.City <> Employee.City) or
          (OldEmployee."Country/Region Code" <> Employee."Country/Region Code") or
          (OldEmployee."Social Security No." <> Employee."Social Security No.") or
          (OldEmployee."Employment Date" <> Employee."Employment Date");

        OnAfterCalculateResourceUpdateNeeded(Employee, OldEmployee, UpdateNeeded);

        exit(UpdateNeeded);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateResource(var Resource: Record Resource; Employee: Record Employee)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateResourceUpdateNeeded(Employee: Record Employee; xEmployee: Record Employee; var UpdateNeeded: Boolean)
    begin
    end;
}

