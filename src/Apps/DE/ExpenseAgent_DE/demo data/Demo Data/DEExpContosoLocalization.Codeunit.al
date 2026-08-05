// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoTool;

codeunit 11339 "DE Exp. Contoso Localization"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnAfterGeneratingDemoData', '', false, false)]
    local procedure LocalizationContosoDemoData(Module: Enum "Contoso Demo Data Module"; ContosoDemoDataLevel: Enum "Contoso Demo Data Level")
    begin
        case Module of
            Enum::"Contoso Demo Data Module"::"Expense Agent":
                case ContosoDemoDataLevel of
                    Enum::"Contoso Demo Data Level"::"Setup Data":
                        begin
                            Codeunit.Run(Codeunit::"Update Exp. Emp Posting Grp DE");
                            Codeunit.Run(Codeunit::"Create Expense Posting Grp DE");
                        end;
                    Enum::"Contoso Demo Data Level"::"Master Data":
                        begin
                            Codeunit.Run(Codeunit::"Create Expense Categories DE");
                            Codeunit.Run(Codeunit::"Create Exp. SubCategories DE");
                            Codeunit.Run(Codeunit::"Create Expense Rule Header DE");
                            Codeunit.Run(Codeunit::"Create Exp. Rule Condition DE");
                        end;
                    Enum::"Contoso Demo Data Level"::"Transactional Data":
                        Codeunit.Run(Codeunit::"Create Expense DE");
                    Enum::"Contoso Demo Data Level"::"Historical Data":
                        Codeunit.Run(Codeunit::"Create Posted Exp. Report DE");
                end;
        end;
    end;

    // Bind subscription for localization events
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnBeforeGeneratingDemoData', '', false, false)]
    local procedure OnBeforeGeneratingDemoData(ContosoDemoDataLevel: Enum "Contoso Demo Data Level"; Module: Enum "Contoso Demo Data Module")
    var
        CreateExpensePostingGroupDE: Codeunit "Create Expense Posting Grp DE";
    begin
        case Module of
            Enum::"Contoso Demo Data Module"::"Expense Agent":
                if ContosoDemoDataLevel = Enum::"Contoso Demo Data Level"::"Setup Data" then
                    BindSubscription(CreateExpensePostingGroupDE);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnAfterGeneratingDemoData', '', false, false)]
    local procedure OnAfterGeneratingDemoData(ContosoDemoDataLevel: Enum "Contoso Demo Data Level"; Module: Enum "Contoso Demo Data Module")
    var
        CreateExpensePostingGroupDE: Codeunit "Create Expense Posting Grp DE";
    begin
        case Module of
            Enum::"Contoso Demo Data Module"::"Expense Agent":
                if ContosoDemoDataLevel = Enum::"Contoso Demo Data Level"::"Setup Data" then
                    UnbindSubscription(CreateExpensePostingGroupDE);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Posted Expense Report", OnDefineExpenseAccountNo, '', false, false)]
    local procedure OnDefineExpenseAccountNo(var AccountNo: Code[20])
    var
        CreateGLAccountDE: Codeunit "Create DE GL Acc.";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
    begin
        AccountNo := ExpenseGLAccount.FindGLAccountByName(CreateGLAccountDE.SaleofResourcesName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Expense Agent", OnBeforeValidateCurrencyCodeInExpense, '', false, false)]
    local procedure OnBeforeValidateCurrencyCodeInExpense(var CurrencyCode: Code[10])
    var
        CreateCurrency: Codeunit "Create Currency";
    begin
        if CurrencyCode = CreateCurrency.EUR() then
            CurrencyCode := CreateCurrency.USD();
    end;
}