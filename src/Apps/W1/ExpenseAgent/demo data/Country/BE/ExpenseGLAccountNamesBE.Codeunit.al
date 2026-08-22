// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8479 "Expense GL Account Names BE"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        EmployeesPayableTok: Label 'Employees Payable', MaxLength = 100;
        TravelTok: Label 'Travel', MaxLength = 100;
        EntertainmentAndPRTok: Label 'Entertainment and PR', MaxLength = 100;
        SalesResourcesDomTok: Label 'Sales, Resources - Dom.', MaxLength = 100;

    procedure EmployeesPayableName(): Text[100]
    begin
        exit(EmployeesPayableTok);
    end;

    procedure TravelName(): Text[100]
    begin
        exit(TravelTok);
    end;

    procedure EntertainmentAndPRName(): Text[100]
    begin
        exit(EntertainmentAndPRTok);
    end;

    procedure SalesResourcesDomName(): Text[100]
    begin
        exit(SalesResourcesDomTok);
    end;
}
