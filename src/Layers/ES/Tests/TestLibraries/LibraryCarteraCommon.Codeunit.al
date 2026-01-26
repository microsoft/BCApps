codeunit 143030 "Library - Cartera Common"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";

    procedure CreateCarteraCurrency(BillGroupsCollection: Boolean; BillGroupsDiscount: Boolean; PaymentOrders: Boolean) CurrencyCode: Code[10]
    var
        Currency: Record Currency;
        Rate: Decimal;
    begin
        Rate := LibraryRandom.RandDecInRange(2, 5, 2);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(CalcDate('<-1Y>', WorkDate()), Rate, Rate);

        Currency.Get(CurrencyCode);
        Currency.Validate("Bill Groups - Collection", BillGroupsCollection);
        Currency.Validate("Bill Groups - Discount", BillGroupsDiscount);
        Currency.Validate("Payment Orders", PaymentOrders);
        Currency.Modify(true);
    end;

    procedure SetupUnrealizedVAT(var SalesVATAccount: Code[20]; var PurchVATAccount: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseUnrVAT_GLAccount: Record "G/L Account";
        SalesUnrVAT_GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", true);
        GeneralLedgerSetup.Modify(true);

        LibraryERM.CreateGLAccount(PurchaseUnrVAT_GLAccount);
        LibraryERM.CreateGLAccount(SalesUnrVAT_GLAccount);

        VATPostingSetup.ModifyAll("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage, true);
        VATPostingSetup.ModifyAll("Sales VAT Unreal. Account", SalesUnrVAT_GLAccount."No.", true);
        VATPostingSetup.ModifyAll("Purch. VAT Unreal. Account", PurchaseUnrVAT_GLAccount."No.", true);
        SalesVATAccount := SalesUnrVAT_GLAccount."No.";
        PurchVATAccount := PurchaseUnrVAT_GLAccount."No.";
    end;

    procedure RevertUnrealizedVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.ModifyAll("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ", true);
        VATPostingSetup.ModifyAll("Sales VAT Unreal. Account", '', true);
        VATPostingSetup.ModifyAll("Purch. VAT Unreal. Account", '', true);
    end;

    procedure CreatePaymentMethod(var PaymentMethod: Record "Payment Method"; CreateBills: Boolean; InvoicesToCartera: Boolean)
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Create Bills", CreateBills);
        PaymentMethod.Validate("Invoices to Cartera", InvoicesToCartera);
        PaymentMethod.Modify(true);
    end;
}

