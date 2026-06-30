namespace System.Integration;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 6110 "GL Acc. Data Migration Facade"
{
    TableNo = "Data Migration Parameters";

    trigger OnRun()
    begin
        if Rec.FindSet() then
            repeat
                OnMigrateGlAccount(Rec."Staging Table RecId To Process");
                OnMigrateGlAccountDimensions(Rec."Staging Table RecId To Process");
                OnCreateOpeningBalanceTrx(Rec."Staging Table RecId To Process");
                OnMigratePostingGroups(Rec."Staging Table RecId To Process");
                OnMigrateAccountTransactions(Rec."Staging Table RecId To Process");
                GLAccountIsSet := false;
            until Rec.Next() = 0;
    end;

    var
        GlobalGLAccount: Record "G/L Account";
        GlobalGenJournalLine: Record "Gen. Journal Line";
        DataMigrationFacadeHelper: Codeunit "Data Migration Facade Helper";
        GLAccountIsSet: Boolean;
        InternalGLAccountNotSetErr: Label 'Internal G/L Account is not set. Create it first.';
        InternalGeneralPostingSetupNotSetErr: Label 'Internal General Posting Setup is not set. Create it first.';

    [IntegrationEvent(true, false)]
    local procedure OnMigrateGlAccount(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreateOpeningBalanceTrx(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigratePostingGroups(RecordIdToMigrate: RecordID)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateAccountTransactions(RecordIdToMigrate: RecordID)
    begin
    end;

    procedure ModifyGLAccount(RunTrigger: Boolean)
    begin
        if not GLAccountIsSet then
            Error(InternalGLAccountNotSetErr);

        GlobalGLAccount.Modify(RunTrigger);
    end;

    procedure CreateGLAccountIfNeeded(AccountNoToSet: Code[20]; AccountNameToSet: Text[50]; AccountTypeToSet: Option Posting,Heading,Total,"Begin-Total","End-Total"): Boolean
    var
        GLAccount: Record "G/L Account";
    begin
        if GLAccount.Get(AccountNoToSet) then begin
            GlobalGLAccount := GLAccount;
            GLAccountIsSet := true;
            exit;
        end;

        GLAccount.Init();

        GLAccount.Validate("No.", AccountNoToSet);
        GLAccount.Validate(Name, AccountNameToSet);
        GLAccount.Validate("Account Type", AccountTypeToSet);

        GLAccount.Insert(true);

        GlobalGLAccount := GLAccount;
        GLAccountIsSet := true;
        exit(true);
    end;

    procedure CreateGeneralPostingSetupIfNeeded(GeneralPostingGroupCode: Code[10])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingGroupCode, GeneralPostingGroupCode) then begin
            GeneralPostingSetup.Init();
            GeneralPostingSetup.Validate("Gen. Bus. Posting Group", GeneralPostingGroupCode);
            GeneralPostingSetup.Validate("Gen. Prod. Posting Group", GeneralPostingGroupCode);
            GeneralPostingSetup.Insert(true);
        end;

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingGroupCode) then begin
            GeneralPostingSetup.Init();
            GeneralPostingSetup.Validate("Gen. Bus. Posting Group", '');
            GeneralPostingSetup.Validate("Gen. Prod. Posting Group", GeneralPostingGroupCode);
            GeneralPostingSetup.Insert(true);
        end;
    end;

    procedure CreateGenProductPostingGroupIfNeeded(PostingGroupCode: Code[20]; PostingGroupDescription: Text[50])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        if GenProductPostingGroup.Get(PostingGroupCode) then
            exit;

        GenProductPostingGroup.Init();
        GenProductPostingGroup.Validate(Code, PostingGroupCode);
        GenProductPostingGroup.Validate(Description, PostingGroupDescription);
        GenProductPostingGroup.Validate("Auto Insert Default", true);
        GenProductPostingGroup.Insert(true);
    end;

    procedure CreateGenBusinessPostingGroupIfNeeded(PostingGroupCode: Code[20]; PostingGroupDescription: Text[50])
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        if GenBusinessPostingGroup.Get(PostingGroupCode) then
            exit;

        GenBusinessPostingGroup.Init();
        GenBusinessPostingGroup.Validate(Code, PostingGroupCode);
        GenBusinessPostingGroup.Validate(Description, PostingGroupDescription);
        GenBusinessPostingGroup.Validate("Auto Insert Default", true);
        GenBusinessPostingGroup.Insert(true);
    end;

    procedure CreateGeneralJournalLine(GeneralJournalBatchCode: Code[10]; DocumentNo: Code[20]; Description: Text[50]; PostingDate: Date; DueDate: Date; Amount: Decimal; AmountLCY: Decimal; Currency: Code[10]; BalancingAccount: Code[20])
    begin
        DataMigrationFacadeHelper.CreateGeneralJournalLine(
          GlobalGenJournalLine,
          GeneralJournalBatchCode,
          DocumentNo,
          Description,
          GlobalGenJournalLine."Account Type"::"G/L Account",
          GlobalGLAccount."No.",
          PostingDate,
          DueDate,
          Amount,
          AmountLCY,
          Currency,
          BalancingAccount);
    end;

    procedure CreateGeneralJournalBatchIfNeeded(GeneralJournalBatchCode: Code[10]; NoSeriesCode: Code[20]; PostingNoSeriesCode: Code[20])
    begin
        DataMigrationFacadeHelper.CreateGeneralJournalBatchIfNeeded(
          GeneralJournalBatchCode,
          NoSeriesCode,
          PostingNoSeriesCode);
    end;

    procedure SetGlobalGLAccount(GLAccountNo: Code[20]): Boolean
    begin
        GLAccountIsSet := GlobalGLAccount.Get(GLAccountNo);
        exit(GLAccountIsSet);
    end;

    procedure SetIncomeBalanceType(IncomeBalanceTypeToSet: Option "Income Statement","Balance Sheet")
    begin
        if not GLAccountIsSet then
            Error(InternalGLAccountNotSetErr);

        GlobalGLAccount.Validate("Income/Balance", IncomeBalanceTypeToSet);
    end;

    procedure SetTotaling(TotalingToSet: Text[250])
    begin
        if not GLAccountIsSet then
            Error(InternalGLAccountNotSetErr);

        GlobalGLAccount.Validate(Totaling, TotalingToSet);
    end;

    procedure SetDebitCreditType(DebitCreditTypeToSet: Option Both,Debit,Credit)
    begin
        if not GLAccountIsSet then
            Error(InternalGLAccountNotSetErr);

        GlobalGLAccount.Validate("Debit/Credit", DebitCreditTypeToSet);
    end;

    procedure SetExchangeRateAdjustmentType(ExchangeRateAdjustmentTypeToSet: Option "No Adjustment","Adjust Amount","Adjust Additional-Currency Amount")
    begin
        if not GLAccountIsSet then
            Error(InternalGLAccountNotSetErr);

        GlobalGLAccount.Validate("Exchange Rate Adjustment", ExchangeRateAdjustmentTypeToSet);
    end;

    procedure SetDirectPosting(DirectPostingToSet: Boolean)
    begin
        if not GLAccountIsSet then
            Error(InternalGLAccountNotSetErr);

        GlobalGLAccount.Validate("Direct Posting", DirectPostingToSet);
    end;

    procedure SetBlocked(BlockedToSet: Boolean)
    begin
        if not GLAccountIsSet then
            Error(InternalGLAccountNotSetErr);

        GlobalGLAccount.Validate(Blocked, BlockedToSet);
    end;

    procedure SetLastModifiedDateTime(LastModifiedDateTimeToSet: DateTime)
    begin
        if not GLAccountIsSet then
            Error(InternalGLAccountNotSetErr);

        GlobalGLAccount.Validate("Last Modified Date Time", LastModifiedDateTimeToSet);
    end;

    procedure SetLastDateModified(LastDateModifiedToSet: Date)
    begin
        if not GLAccountIsSet then
            Error(InternalGLAccountNotSetErr);

        GlobalGLAccount.Validate("Last Date Modified", LastDateModifiedToSet);
    end;

    procedure SetAccountCategory(AccountCategoryToSet: Option " ",Assets,Liabilities,Equity,Income,"Cost of Goods Sold",Expense)
    begin
        if not GLAccountIsSet then
            Error(InternalGLAccountNotSetErr);

        GlobalGLAccount.Validate("Account Category", AccountCategoryToSet);
    end;

    procedure SetAccountSubCategory(AccountSubCategoryToSet: Integer)
    begin
        if not GLAccountIsSet then
            Error(InternalGLAccountNotSetErr);

        GlobalGLAccount.Validate("Account Subcategory Entry No.", AccountSubCategoryToSet);
    end;

    procedure SetGeneralPostingSetupSalesAccount(GeneralPostingSetupCode: Code[20]; SalesAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Sales Account", SalesAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Sales Account", SalesAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupSalesLineDiscAccount(GeneralPostingSetupCode: Code[20]; SalesLineDiscAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Sales Line Disc. Account", SalesLineDiscAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Sales Line Disc. Account", SalesLineDiscAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupSalesInvDiscAccount(GeneralPostingSetupCode: Code[20]; SalesInvDiscAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", SalesInvDiscAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", SalesInvDiscAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupSalesPmtDiscDebitAccount(GeneralPostingSetupCode: Code[20]; SalesPmtDiscDebitAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", SalesPmtDiscDebitAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", SalesPmtDiscDebitAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupPurchAccount(GeneralPostingSetupCode: Code[20]; PurchAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purch. Account", PurchAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purch. Account", PurchAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupPurchLineDiscAccount(GeneralPostingSetupCode: Code[20]; PurchLineDiscAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purch. Line Disc. Account", PurchLineDiscAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purch. Line Disc. Account", PurchLineDiscAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupPurchInvDiscAccount(GeneralPostingSetupCode: Code[20]; PurchInvDiscAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", PurchInvDiscAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", PurchInvDiscAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupPurchCreditMemoAccount(GeneralPostingSetupCode: Code[20]; PurchCreditMemoAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purch. Credit Memo Account", PurchCreditMemoAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purch. Credit Memo Account", PurchCreditMemoAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupCOGSAccount(GeneralPostingSetupCode: Code[20]; CogsAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("COGS Account", CogsAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("COGS Account", CogsAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupInventoryAdjmtAccount(GeneralPostingSetupCode: Code[20]; InventoryAdjmtAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Inventory Adjmt. Account", InventoryAdjmtAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Inventory Adjmt. Account", InventoryAdjmtAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupSalesCreditMemoAccount(GeneralPostingSetupCode: Code[20]; SalesCreditMemoAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Sales Credit Memo Account", SalesCreditMemoAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Sales Credit Memo Account", SalesCreditMemoAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupPurchPmtDiscDebitAccount(GeneralPostingSetupCode: Code[20]; PurchPmtDiscDebitAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Debit Acc.", PurchPmtDiscDebitAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purch. Pmt. Disc. Debit Acc.", PurchPmtDiscDebitAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupPurchPrepaymentsAccount(GeneralPostingSetupCode: Code[20]; PurchPrepaymentsAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purch. Prepayments Account", PurchPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purch. Prepayments Account", PurchPrepaymentsAccount);
        GeneralPostingSetup.Modify(true);
    end;

    procedure SetGeneralPostingSetupPurchaseVarianceAccount(GeneralPostingSetupCode: Code[20]; PurchaseVarianceAccount: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        if not GeneralPostingSetup.Get(GeneralPostingSetupCode, GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purchase Variance Account", PurchaseVarianceAccount);
        GeneralPostingSetup.Modify(true);

        GeneralPostingSetup.Reset();
        if not GeneralPostingSetup.Get('', GeneralPostingSetupCode) then
            Error(InternalGeneralPostingSetupNotSetErr);

        GeneralPostingSetup.Validate("Purchase Variance Account", PurchaseVarianceAccount);
        GeneralPostingSetup.Modify(true);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnMigrateGlAccountDimensions(RecordIdToMigrate: RecordID)
    begin
    end;

    procedure CreateDefaultDimensionAndRequirementsIfNeeded(DimensionCode: Text[20]; DimensionDescription: Text[50]; DimensionValueCode: Code[20]; DimensionValueName: Text[50])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        if not GLAccountIsSet then
            Error(InternalGLAccountNotSetErr);

        DataMigrationFacadeHelper.GetOrCreateDimension(DimensionCode, DimensionDescription, Dimension);
        DataMigrationFacadeHelper.GetOrCreateDimensionValue(Dimension.Code, DimensionValueCode, DimensionValueName,
          DimensionValue);
        DataMigrationFacadeHelper.CreateOnlyDefaultDimensionIfNeeded(Dimension.Code, DimensionValue.Code,
          DATABASE::"G/L Account", GlobalGLAccount."No.");
    end;

    procedure SetGeneralJournalLineDimension(var GenJournalLine: Record "Gen. Journal Line"; DimensionCode: Code[20]; DimensionDescription: Text[50]; DimensionValueCode: Code[20]; DimensionValueName: Text[50])
    var
        DataMigrationFacadeHelper: Codeunit "Data Migration Facade Helper";
    begin
        GenJournalLine.Validate("Dimension Set ID",
          DataMigrationFacadeHelper.CreateDimensionSetId(GenJournalLine."Dimension Set ID",
            DimensionCode, DimensionDescription,
            DimensionValueCode, DimensionValueName));
        GenJournalLine.Modify(true);
    end;
}

