#if not CLEAN30
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoTool;

codeunit 13684 "DK Exp. Contoso Localization"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    ObsoleteState = Pending;
    ObsoleteReason = 'The country-specific Expense Agent demo data is being consolidated into a single app in W1 and will be removed in a future release.';
    ObsoleteTag = '30.0';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnAfterGeneratingDemoData', '', false, false)]
    local procedure LocalizationContosoDemoData(Module: Enum "Contoso Demo Data Module"; ContosoDemoDataLevel: Enum "Contoso Demo Data Level")
    begin
        case Module of
            Enum::"Contoso Demo Data Module"::"Expense Agent":
                case ContosoDemoDataLevel of
                    Enum::"Contoso Demo Data Level"::"Setup Data":
                        begin
                            Codeunit.Run(Codeunit::"Update Exp. Emp Posting Grp DK");
                            Codeunit.Run(Codeunit::"Create Expense Posting Grp DK");
                        end;
                    Enum::"Contoso Demo Data Level"::"Master Data":
                        begin
                            Codeunit.Run(Codeunit::"Create Expense Categories DK");
                            Codeunit.Run(Codeunit::"Create Exp. SubCategories DK");
                            Codeunit.Run(Codeunit::"Create Expense Rule Header DK");
                            Codeunit.Run(Codeunit::"Create Exp. Rule Condition DK");
                        end;
                    Enum::"Contoso Demo Data Level"::"Transactional Data":
                        Codeunit.Run(Codeunit::"Create Expense DK");
                    Enum::"Contoso Demo Data Level"::"Historical Data":
                        Codeunit.Run(Codeunit::"Create Posted Exp. Report DK");
                end;
        end;
    end;

    // Bind subscription for localization events
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnBeforeGeneratingDemoData', '', false, false)]
    local procedure OnBeforeGeneratingDemoData(ContosoDemoDataLevel: Enum "Contoso Demo Data Level"; Module: Enum "Contoso Demo Data Module")
    var
        CreateExpensePostingGroupDK: Codeunit "Create Expense Posting Grp DK";
    begin
        case Module of
            Enum::"Contoso Demo Data Module"::"Expense Agent":
                if ContosoDemoDataLevel = Enum::"Contoso Demo Data Level"::"Setup Data" then
                    BindSubscription(CreateExpensePostingGroupDK);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnAfterGeneratingDemoData', '', false, false)]
    local procedure OnAfterGeneratingDemoData(ContosoDemoDataLevel: Enum "Contoso Demo Data Level"; Module: Enum "Contoso Demo Data Module")
    var
        CreateExpensePostingGroupDK: Codeunit "Create Expense Posting Grp DK";
    begin
        case Module of
            Enum::"Contoso Demo Data Module"::"Expense Agent":
                if ContosoDemoDataLevel = Enum::"Contoso Demo Data Level"::"Setup Data" then
                    UnbindSubscription(CreateExpensePostingGroupDK);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Posted Expense Report", OnDefineExpenseAccountNo, '', false, false)]
    local procedure OnDefineExpenseAccountNo(var AccountNo: Code[20])
    var
        CreateDKGLAccounts: Codeunit "Create GL Acc. DK";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
    begin
        AccountNo := ExpenseGLAccount.FindGLAccountByName(CreateDKGLAccounts.DomesticsalesofgoodsandservicesName());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Expense Agent", OnBeforeValidateCurrencyCodeInExpense, '', false, false)]
    local procedure OnBeforeValidateCurrencyCodeInExpense(var CurrencyCode: Code[10])
    var
        CreateCurrency: Codeunit "Create Currency";
    begin
        if CurrencyCode = CreateCurrency.DKK() then
            CurrencyCode := '';
    end;
}
#endif