codeunit 144120 RemittancePaymentorderTests
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Remittance] [Payment Order]
    end;

    var
        RemittancePaymentOrder: Record "Remittance Payment Order";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure TestCascadingDelete()
    var
        PaymentOrderData: Record "Payment Order Data";
        WaitingJournal: Record "Waiting Journal";
    begin
        // Purpose of the test is to validate Trigger OnDelete

        // Setup
        RemittancePaymentOrder.DeleteAll();
        PaymentOrderData.DeleteAll();
        WaitingJournal.DeleteAll();

        RemittancePaymentOrder.ID := LibraryRandom.RandInt(10);
        RemittancePaymentOrder.Insert();
        PaymentOrderData."Payment Order No." := RemittancePaymentOrder.ID;
        PaymentOrderData.Insert();
        WaitingJournal.Reference := RemittancePaymentOrder.ID;
        WaitingJournal.Insert();

        // Exercise
        RemittancePaymentOrder.Delete(true);

        // Verify
        Assert.IsFalse(RemittancePaymentOrder.Get(RemittancePaymentOrder.ID), 'Does not Expect a record');
        Assert.IsFalse(PaymentOrderData.Get(RemittancePaymentOrder.ID), 'Does not Expect a record');
        Assert.IsFalse(WaitingJournal.Get(RemittancePaymentOrder.ID), 'Does not Expect a record');
    end;
}

