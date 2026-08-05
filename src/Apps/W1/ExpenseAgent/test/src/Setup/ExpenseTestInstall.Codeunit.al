// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;
using System.Integration;

codeunit 148308 "Expense Test Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        RegisterExpenseTestHandlerService();
    end;

    local procedure RegisterExpenseTestHandlerService()
    var
        WebService: Record "Web Service";
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        WebServiceManagement.CreateWebService(WebService."Object Type"::Codeunit, Codeunit::"Expense Test Handler API", 'ExpenseTestHandler',
          true);
    end;
}
