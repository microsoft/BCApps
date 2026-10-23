// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using Microsoft.DemoData.Bank;
using Microsoft.DemoData.CRM;
using Microsoft.DemoData.Foundation;
using Microsoft.DemoTool;
using Microsoft.DemoTool.Helpers;

codeunit 8223 "Create Corp Card Bank Account"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    var
        ContosoCoffeeDemoDataSetup: Record "Contoso Coffee Demo Data Setup";
        ContosoBank: Codeunit "Contoso Bank";
        CreateBankExImportSetup: Codeunit "Create Bank Ex/Import Setup";
        CreateCorpCardSetup: Codeunit "EA Create Corp Card Setup";
        CreateNoSeries: Codeunit "Create No. Series";
        SalespersonPurchaser: Codeunit "Create Salesperson/Purchaser";
        CorpCardBankAccountPostingGroup: Code[20];
    begin
        ContosoCoffeeDemoDataSetup.Get();
        CorpCardBankAccountPostingGroup := CreateCorpCardSetup.EnsureCorpCardBankAccountPostingGroup();
        ContosoBank.InsertBankAccount(
            CorpCardBankAccount(), CorpCardBankAccountNameLbl, '', '', '', CorpCardBankAccountNoTok, 0,
            CorpCardBankAccountPostingGroup, SalespersonPurchaser.OtisFalls(),
            ContosoCoffeeDemoDataSetup."Country/Region Code", '', CreateNoSeries.PaymentReconciliationJournals(),
            '', '', '', CreateBankExImportSetup.SEPACAMT());
        CreateCorpCardSetup.CreateDefaults();
    end;

    procedure CorpCardBankAccount(): Code[20]
    begin
        exit(CorpCardBankAccountTok);
    end;

    var
        CorpCardBankAccountTok: Label 'CORPCARD', Locked = true;
        CorpCardBankAccountNameLbl: Label 'Corporate Card Settlement Account', MaxLength = 100;
        CorpCardBankAccountNoTok: Label '99-55-000', Locked = true;
}
