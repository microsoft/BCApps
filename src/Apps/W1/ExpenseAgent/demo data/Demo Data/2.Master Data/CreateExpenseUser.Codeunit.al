// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.HumanResources;

codeunit 8214 "Create Expense User"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        CreateEmployee: Codeunit "Create Employee";
        CreateExpenseTeam: Codeunit "Create Expense Team";
        ContosoExpenseAgent: Codeunit "Contoso Expense Agent";
    begin
        ContosoExpenseAgent.InsertExpenseUser(EH(), CreateEmployee.ManagingDirector(), CreateExpenseTeam.Default(), true);
        ContosoExpenseAgent.InsertExpenseUser(JO(), CreateEmployee.SalesManager(), CreateExpenseTeam.Default(), false);
        ContosoExpenseAgent.InsertExpenseUser(LT(), CreateEmployee.Designer(), CreateExpenseTeam.Default(), false);
        ContosoExpenseAgent.InsertExpenseUser(MH(), CreateEmployee.ProductionAssistant(), CreateExpenseTeam.Default(), false);
        ContosoExpenseAgent.InsertExpenseUser("OF"(), CreateEmployee.ProductionManager(), CreateExpenseTeam.Default(), false);
        ContosoExpenseAgent.InsertExpenseUser(RB(), CreateEmployee.Secretary(), CreateExpenseTeam.Default(), false);
        ContosoExpenseAgent.InsertExpenseUser(TD(), CreateEmployee.InventoryManager(), CreateExpenseTeam.Default(), false);
    end;

    var
        EHTok: Label 'EH', MaxLength = 20, Locked = true;
        JOTok: Label 'JO', MaxLength = 20, Locked = true;
        LTTok: Label 'LT', MaxLength = 20, Locked = true;
        MHTok: Label 'MH', MaxLength = 20, Locked = true;
        OFTok: Label 'OF', MaxLength = 20, Locked = true;
        RBTok: Label 'RB', MaxLength = 20, Locked = true;
        TDTok: Label 'TD', MaxLength = 20, Locked = true;

    procedure EH(): Code[20]
    begin
        exit(EHTok);
    end;

    procedure JO(): Code[20]
    begin
        exit(JOTok);
    end;

    procedure LT(): Code[20]
    begin
        exit(LTTok);
    end;

    procedure MH(): Code[20]
    begin
        exit(MHTok);
    end;

    procedure "OF"(): Code[20]
    begin
        exit(OFTok);
    end;

    procedure RB(): Code[20]
    begin
        exit(RBTok);
    end;

    procedure TD(): Code[20]
    begin
        exit(TDTok);
    end;
}