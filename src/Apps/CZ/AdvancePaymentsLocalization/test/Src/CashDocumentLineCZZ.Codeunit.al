// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.AdvancePayments;

using Microsoft.Finance.CashDesk;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Sales.Customer;

codeunit 148133 "Cash Document Line CZZ"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CashDocLineTestHandlerCZZ: Codeunit "Cash Doc Line Test Handler CZZ";
        LibraryCashDeskCZP: Codeunit "Library - Cash Desk CZP";
        LibraryCashDocumentCZP: Codeunit "Library - Cash Document CZP";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";

    [Test]
    procedure ValidateAdvanceLetterNoCanBeHandled()
    var
        CashDocumentLineCZP: Record "Cash Document Line CZP";
        AdvanceLetterNo: Code[20];
    begin
        // [SCENARIO] Validation of the advance letter number can be handled by a subscriber
        Initialize();
        AdvanceLetterNo := CopyStr(LibraryUtility.GenerateRandomCode(
                                          CashDocumentLineCZP.FieldNo("Advance Letter No. CZZ"), Database::"Cash Document Line CZP"), 1, MaxStrLen(CashDocumentLineCZP."Advance Letter No. CZZ"));
        BindSubscription(CashDocLineTestHandlerCZZ);

        // [WHEN] An advance letter number is validated on an otherwise invalid cash document line
        CashDocumentLineCZP.Validate("Advance Letter No. CZZ", AdvanceLetterNo);
        UnbindSubscription(CashDocLineTestHandlerCZZ);

        // [THEN] The subscriber handles the validation before the standard checks are run
        Assert.IsTrue(CashDocLineTestHandlerCZZ.GetValidateAdvanceLetterNoEventRaised(), 'The before validate event must be raised.');
        CashDocumentLineCZP.TestField("Advance Letter No. CZZ", AdvanceLetterNo);
    end;

    [Test]
    procedure LookupAdvanceLetterNoCanBeHandled()
    var
        CashDeskCZP: Record "Cash Desk CZP";
        CashDeskUserCZP: Record "Cash Desk User CZP";
        CashDocumentHeaderCZP: Record "Cash Document Header CZP";
        CashDocumentLineCZP: Record "Cash Document Line CZP";
        Customer: Record Customer;
        CashDocumentSubformCZP: TestPage "Cash Document Subform CZP";
    begin
        // [SCENARIO] Lookup of the advance letter number can be handled by a subscriber
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibraryCashDeskCZP.CreateCashDeskCZP(CashDeskCZP);
        LibraryCashDeskCZP.SetupCashDeskCZP(CashDeskCZP, false);
        LibraryCashDeskCZP.CreateCashDeskUserCZP(CashDeskUserCZP, CashDeskCZP."No.", true, true, true);
        LibraryCashDocumentCZP.CreateCashDocumentHeaderCZP(CashDocumentHeaderCZP, CashDocumentHeaderCZP."Document Type"::Receipt, CashDeskCZP."No.");
        LibraryCashDocumentCZP.CreateCashDocumentLineCZP(
            CashDocumentLineCZP, CashDocumentHeaderCZP,
            Enum::"Cash Document Account Type CZP"::Customer, Customer."No.", 0);
        CashDocumentLineCZP."Gen. Document Type" := CashDocumentLineCZP."Gen. Document Type"::" ";
        CashDocumentLineCZP.Modify();
        BindSubscription(CashDocLineTestHandlerCZZ);

        // [WHEN] The advance letter number lookup is invoked on an otherwise invalid cash document line
        CashDocumentSubformCZP.OpenEdit();
        CashDocumentSubformCZP.GoToRecord(CashDocumentLineCZP);
        CashDocumentSubformCZP."Advance Letter No. CZZ".Lookup();
        CashDocumentSubformCZP.Close();
        UnbindSubscription(CashDocLineTestHandlerCZZ);

        // [THEN] The subscriber handles the lookup before the standard checks are run
        Assert.IsTrue(CashDocLineTestHandlerCZZ.GetLookupAdvanceLetterNoEventRaised(), 'The before lookup event must be raised.');
    end;

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        Clear(CashDocLineTestHandlerCZZ);

        GeneralLedgerSetup.Get();
        if GeneralLedgerSetup."Cash Desk Nos. CZP" = '' then begin
            GeneralLedgerSetup.Validate("Cash Desk Nos. CZP", LibraryUtility.GetGlobalNoSeriesCode());
            GeneralLedgerSetup.Modify(true);
        end;
    end;
}
