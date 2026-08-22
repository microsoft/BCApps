// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 8483 "Expense GL Account Names FI"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Otherreceivables1Tok: Label 'Otherreceivables1', MaxLength = 100;
        EmployeesPayableTok: Label 'Employees Payable', MaxLength = 100;
        SalesofgoodsdomTok: Label 'Salesofgoodsdom', MaxLength = 100;

    procedure Otherreceivables1Name(): Text[100]
    begin
        exit(Otherreceivables1Tok);
    end;

    procedure EmployeesPayableName(): Text[100]
    begin
        exit(EmployeesPayableTok);
    end;

    procedure SalesofgoodsdomName(): Text[100]
    begin
        exit(SalesofgoodsdomTok);
    end;
}
