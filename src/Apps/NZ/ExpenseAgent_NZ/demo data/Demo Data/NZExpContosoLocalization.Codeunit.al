#if not CLEAN30
#pragma warning disable AL0432
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Finance;
using Microsoft.DemoTool;

codeunit 17223 "NZ Exp. Contoso Localization"
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
                            Codeunit.Run(Codeunit::"Update Exp. Emp Posting Grp NZ");
                            Codeunit.Run(Codeunit::"Create Expense Posting Grp NZ");
                        end;
                    Enum::"Contoso Demo Data Level"::"Master Data":
                        begin
                            Codeunit.Run(Codeunit::"Create Expense Categories NZ");
                            Codeunit.Run(Codeunit::"Create Exp. SubCategories NZ");
                            Codeunit.Run(Codeunit::"Create Expense Rule Header NZ");
                            Codeunit.Run(Codeunit::"Create Exp. Rule Condition NZ");
                        end;
                    Enum::"Contoso Demo Data Level"::"Transactional Data":
                        Codeunit.Run(Codeunit::"Create Expense NZ");
                    Enum::"Contoso Demo Data Level"::"Historical Data":
                        Codeunit.Run(Codeunit::"Create Posted Exp. Report NZ");
                end;
        end;
    end;

    // Bind subscription for localization events
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnBeforeGeneratingDemoData', '', false, false)]
    local procedure OnBeforeGeneratingDemoData(ContosoDemoDataLevel: Enum "Contoso Demo Data Level"; Module: Enum "Contoso Demo Data Module")
    var
        CreateExpensePostingGroupNZ: Codeunit "Create Expense Posting Grp NZ";
    begin
        case Module of
            Enum::"Contoso Demo Data Module"::"Expense Agent":
                if ContosoDemoDataLevel = Enum::"Contoso Demo Data Level"::"Setup Data" then
                    BindSubscription(CreateExpensePostingGroupNZ);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Contoso Demo Tool", 'OnAfterGeneratingDemoData', '', false, false)]
    local procedure OnAfterGeneratingDemoData(ContosoDemoDataLevel: Enum "Contoso Demo Data Level"; Module: Enum "Contoso Demo Data Module")
    var
        CreateExpensePostingGroupNZ: Codeunit "Create Expense Posting Grp NZ";
    begin
        case Module of
            Enum::"Contoso Demo Data Module"::"Expense Agent":
                if ContosoDemoDataLevel = Enum::"Contoso Demo Data Level"::"Setup Data" then
                    UnbindSubscription(CreateExpensePostingGroupNZ);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Posted Expense Report", OnDefineExpenseAccountNo, '', false, false)]
    local procedure OnDefineExpenseAccountNo(var AccountNo: Code[20])
    var
        CreateGLAccount: Codeunit "Create G/L Account";
        ExpenseGLAccount: Codeunit "Create Expense G/L Account";
    begin
        AccountNo := ExpenseGLAccount.FindGLAccountByName(CreateGLAccount.SalesResourcesExportName());
    end;
}
#endif