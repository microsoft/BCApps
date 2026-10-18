// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.DemoTool;

using Microsoft.DemoData.FixedAsset;
using Microsoft.DemoTool.Helpers;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;

codeunit 148452 "Contoso Fixed Asset Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ContosoFixedAsset: Codeunit "Contoso Fixed Asset";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertFADepreciationBookPreservesDerogatoryRelationship()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Inserting an FA book preserves an existing tax-to-accounting book relationship.
        Initialize();

        // [GIVEN] Asset A and tax book T linked to accounting book C.
        CreateDerogatoryBookFixture(FixedAsset, DepreciationBook);

        // [WHEN] The helper inserts the FA book without a posting group.
        ContosoFixedAsset.InsertFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, WorkDate(), 5);

        // [THEN] The FA book is stored and the shared relationship is unchanged.
        VerifyFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, WorkDate(), 5, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure InsertFADepreciationBookWithPostingGroupPreservesRelationship()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Inserting an FA book with a posting group preserves the shared book relationship.
        Initialize();

        // [GIVEN] Asset A, tax book T linked to accounting book C, and posting group P.
        CreateDerogatoryBookFixture(FixedAsset, DepreciationBook);
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);

        // [WHEN] The helper inserts the FA book with posting group P.
        ContosoFixedAsset.InsertFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, WorkDate(), 5, FAPostingGroup.Code);

        // [THEN] The FA book and posting group are stored without changing the shared relationship.
        VerifyFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, WorkDate(), 5, FAPostingGroup.Code);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverwriteFADepreciationBookPreservesDerogatoryRelationship()
    var
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Updating an existing FA book preserves the shared book relationship.
        Initialize();

        // [GIVEN] Asset A already has tax book T linked to accounting book C.
        CreateDerogatoryBookFixture(FixedAsset, DepreciationBook);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        ContosoFixedAsset.SetOverwriteData(true);

        // [WHEN] The helper updates the existing FA book without a posting group.
        ContosoFixedAsset.InsertFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, WorkDate(), 6);

        // [THEN] The FA book is updated and the shared relationship is unchanged.
        VerifyFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, WorkDate(), 6, '');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure OverwriteFADepreciationBookWithPostingGroupPreservesRelationship()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        FixedAsset: Record "Fixed Asset";
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Updating an FA book with a posting group preserves the shared book relationship.
        Initialize();

        // [GIVEN] Asset A has tax book T linked to accounting book C, and posting group P exists.
        CreateDerogatoryBookFixture(FixedAsset, DepreciationBook);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        LibraryERM.CreateGeneralPostingSetupInvt(GeneralPostingSetup);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        ContosoFixedAsset.SetOverwriteData(true);

        // [WHEN] The helper updates the existing FA book with posting group P.
        ContosoFixedAsset.InsertFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, WorkDate(), 6, FAPostingGroup.Code);

        // [THEN] The FA book and posting group are updated without changing the shared relationship.
        VerifyFADepreciationBook(FixedAsset."No.", DepreciationBook.Code, WorkDate(), 6, FAPostingGroup.Code);
    end;

    local procedure Initialize()
    begin
        Clear(ContosoFixedAsset);
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(Database::"FA Setup");
        IsInitialized := true;
    end;

    local procedure CreateDerogatoryBookFixture(var FixedAsset: Record "Fixed Asset"; var DepreciationBook: Record "Depreciation Book")
    var
        AccountingDepreciationBook: Record "Depreciation Book";
        CreateFADepreciationBook: Codeunit "Create FA Depreciation Book";
    begin
        if not AccountingDepreciationBook.Get(CreateFADepreciationBook.Company()) then begin
            LibraryFixedAsset.CreateDepreciationBook(AccountingDepreciationBook);
            AccountingDepreciationBook.Rename(CreateFADepreciationBook.Company());
        end;

        DepreciationBook.SetRange("Derogatory Calc.", AccountingDepreciationBook.Code);
        if not DepreciationBook.FindFirst() then begin
            DepreciationBook.Reset();
            LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
            DepreciationBook.Validate("Derogatory Calc.", AccountingDepreciationBook.Code);
            DepreciationBook.Modify(true);
        end;

        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
    end;

    local procedure VerifyFADepreciationBook(FixedAssetNo: Code[20]; DepreciationBookCode: Code[10]; ExpectedStartingDate: Date; ExpectedDepreciationYears: Decimal; ExpectedPostingGroup: Code[20])
    var
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBook: Record "Depreciation Book";
        AccountingDepreciationBook: Record "Depreciation Book";
        CreateFADepreciationBook: Codeunit "Create FA Depreciation Book";
    begin
        FADepreciationBook.Get(FixedAssetNo, DepreciationBookCode);
        Assert.AreEqual(ExpectedStartingDate, FADepreciationBook."Depreciation Starting Date", 'The depreciation starting date must be stored.');
        Assert.AreEqual(ExpectedDepreciationYears, FADepreciationBook."No. of Depreciation Years", 'The depreciation period must be stored.');
        Assert.AreEqual(ExpectedPostingGroup, FADepreciationBook."FA Posting Group", 'The FA posting group must be preserved or updated as requested.');

        DepreciationBook.Get(DepreciationBookCode);
        Assert.AreEqual(CreateFADepreciationBook.Company(), DepreciationBook."Derogatory Calc.", 'The tax book relationship must remain unchanged.');
        AccountingDepreciationBook.Get(CreateFADepreciationBook.Company());
        Assert.AreEqual('', AccountingDepreciationBook."Derogatory Calc.", 'The accounting book must not become a tax book.');
    end;
}
