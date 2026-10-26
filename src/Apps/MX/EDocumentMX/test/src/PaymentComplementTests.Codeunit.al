// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.Sales.Receivables;
using Microsoft.EServices.EDocument.Interfactura;
using System.Utilities;

codeunit 148757 "Payment Complement Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    Permissions = tabledata "MX Payment Complement" = rimd;

    var
        Assert: Codeunit Assert;
        PaymentComplementBuilder: Codeunit "MX Payment Complement Builder";
        MXPaymentComplCancel: Codeunit "MX Payment Compl. Cancel";

    [Test]
    procedure BuildPaymentComplementFailsWhenCustomerDoesNotExist()
    var
        Payment: Record "Cust. Ledger Entry";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Building a payment complement fails when the payment customer does not exist
        Initialize();

        // [GIVEN] A payment ledger entry referencing a non-existing customer
        Payment."Customer No." := 'NONEXISTENT';

        // [WHEN] The payment complement is built
        asserterror PaymentComplementBuilder.Build(Payment, TempBlob);

        // [THEN] The customer validation error is raised
        Assert.ExpectedError('Customer');
        Assert.ExpectedErrorCode('DB:RecordNotFound');
    end;

    [Test]
    procedure ReappliedPaymentKeepsReversedComplement()
    var
        ReversedPaymentComplement: Record "MX Payment Complement";
        NewPaymentComplement: Record "MX Payment Complement";
        PaymentComplement: Record "MX Payment Complement";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A payment that is unapplied and reapplied keeps the reversed complement next to the new one
        Initialize();

        // [GIVEN] A reversed payment complement for payment ledger entry 1
        ReversedPaymentComplement.Init();
        ReversedPaymentComplement."Payment Entry No." := 1;
        ReversedPaymentComplement.Reversed := true;
        ReversedPaymentComplement.Insert();

        // [WHEN] A new payment complement is created for the same payment ledger entry
        NewPaymentComplement.Init();
        NewPaymentComplement."Payment Entry No." := ReversedPaymentComplement."Payment Entry No.";
        NewPaymentComplement.Insert();

        // [THEN] Both complements exist and only the new one is current
        PaymentComplement.SetRange("Payment Entry No.", 1);
        Assert.RecordCount(PaymentComplement, 2);
        PaymentComplement.SetRange(Reversed, false);
        PaymentComplement.FindFirst();
        Assert.AreEqual(NewPaymentComplement."Entry No.", PaymentComplement."Entry No.", 'The current payment complement is incorrect.');
    end;

    [Test]
    procedure PaymentComplementCanBeCreatedForDifferentPayments()
    var
        FirstPaymentComplement: Record "MX Payment Complement";
        SecondPaymentComplement: Record "MX Payment Complement";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Separate payment complements can be created for different payments
        Initialize();

        // [GIVEN] A payment complement for payment ledger entry 1
        FirstPaymentComplement.Init();
        FirstPaymentComplement."Payment Entry No." := 1;
        FirstPaymentComplement.Insert();

        // [WHEN] A payment complement is created for payment ledger entry 2
        SecondPaymentComplement.Init();
        SecondPaymentComplement."Payment Entry No." := 2;
        SecondPaymentComplement.Insert();

        // [THEN] Both payment complements are stored independently
        Assert.AreNotEqual(FirstPaymentComplement."Entry No.", SecondPaymentComplement."Entry No.", 'Payment complements must have different entry numbers.');
        Assert.AreEqual(1, FirstPaymentComplement."Payment Entry No.", 'The first payment entry number is incorrect.');
        Assert.AreEqual(2, SecondPaymentComplement."Payment Entry No.", 'The second payment entry number is incorrect.');
    end;

    [Test]
    procedure CancellationResponseCanceledMarksComplementCanceled()
    var
        PaymentComplement: Record "MX Payment Complement";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A canceled response from the PAC marks the payment complement as canceled
        Initialize();

        // [GIVEN] A stamped payment complement
        CreateStampedComplement(PaymentComplement);

        // [WHEN] The PAC answers that the complement was canceled
        MXPaymentComplCancel.ApplyCancellationResponse(PaymentComplement, '<Resultado IdRespuesta="1" Estatus="Cancelado"><Evento Fecha="2026-10-25T10:00:00"/></Resultado>');

        // [THEN] The complement is canceled with the cancellation date
        PaymentComplement.Get(PaymentComplement."Entry No.");
        Assert.AreEqual(PaymentComplement."Cancellation Status"::Canceled, PaymentComplement."Cancellation Status", 'The cancellation status is incorrect.');
        Assert.AreEqual('2026-10-25T10:00:00', PaymentComplement."Date/Time Canceled", 'The cancellation date is incorrect.');
    end;

    [Test]
    procedure CancellationResponseInProgressStoresCancellationId()
    var
        PaymentComplement: Record "MX Payment Complement";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A cancellation in progress keeps the cancellation ID to check the status later
        Initialize();

        // [GIVEN] A stamped payment complement
        CreateStampedComplement(PaymentComplement);

        // [WHEN] The PAC accepts the request and returns a cancellation ID
        MXPaymentComplCancel.ApplyCancellationResponse(PaymentComplement, '<Resultado IdRespuesta="1" ConsultaCancelacionId="CANCEL-001"/>');

        // [THEN] The complement is in progress with the cancellation ID
        PaymentComplement.Get(PaymentComplement."Entry No.");
        Assert.AreEqual(PaymentComplement."Cancellation Status"::"Cancel In Progress", PaymentComplement."Cancellation Status", 'The cancellation status is incorrect.');
        Assert.AreEqual('CANCEL-001', PaymentComplement."CFDI Cancellation ID", 'The cancellation ID is incorrect.');
    end;

    [Test]
    procedure CancellationResponseRejectedStoresError()
    var
        PaymentComplement: Record "MX Payment Complement";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A rejected cancellation keeps the complement valid and stores the PAC error
        Initialize();

        // [GIVEN] A stamped payment complement
        CreateStampedComplement(PaymentComplement);

        // [WHEN] The PAC rejects the cancellation
        MXPaymentComplCancel.ApplyCancellationResponse(PaymentComplement, '<Resultado IdRespuesta="2" Descripcion="UUID no encontrado"/>');

        // [THEN] The complement has a cancellation error with the PAC description
        PaymentComplement.Get(PaymentComplement."Entry No.");
        Assert.AreEqual(PaymentComplement."Cancellation Status"::"Cancel Error", PaymentComplement."Cancellation Status", 'The cancellation status is incorrect.');
        Assert.AreEqual('UUID no encontrado', PaymentComplement."Cancellation Error", 'The cancellation error is incorrect.');
        PaymentComplement.CalcFields("Cancellation Response XML");
        Assert.IsTrue(PaymentComplement."Cancellation Response XML".HasValue(), 'The cancellation response must be saved.');
    end;

    [Test]
    procedure CancelRequestFailsWhenComplementNotStamped()
    var
        PaymentComplement: Record "MX Payment Complement";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A payment complement that was not stamped cannot be canceled
        Initialize();

        // [GIVEN] A payment complement without a PAC response
        PaymentComplement.Init();
        PaymentComplement."Payment Entry No." := 1;
        PaymentComplement.Insert();

        // [WHEN] The cancellation is requested
        asserterror MXPaymentComplCancel.CancelRequest(PaymentComplement, false);

        // [THEN] An error is raised
        Assert.ExpectedError('The payment complement has not been stamped, so there is nothing to cancel.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure MarkAsCanceledSetsCanceledStatus()
    var
        PaymentComplement: Record "MX Payment Complement";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Mark as Canceled closes a requested cancellation in Business Central without contacting the PAC
        Initialize();

        // [GIVEN] A stamped payment complement whose cancellation is in progress
        CreateStampedComplement(PaymentComplement);
        PaymentComplement."Cancellation Status" := PaymentComplement."Cancellation Status"::"Cancel In Progress";
        PaymentComplement.Modify();

        // [WHEN] The complement is marked as canceled
        MXPaymentComplCancel.MarkAsCanceled(PaymentComplement);

        // [THEN] The complement is canceled and flagged as manually canceled
        PaymentComplement.Get(PaymentComplement."Entry No.");
        Assert.AreEqual(PaymentComplement."Cancellation Status"::Canceled, PaymentComplement."Cancellation Status", 'The cancellation status is incorrect.');
        Assert.IsTrue(PaymentComplement."Marked as Canceled", 'The complement must be flagged as manually canceled.');
    end;

    [Test]
    procedure MarkAsCanceledFailsWithoutCancellationRequest()
    var
        PaymentComplement: Record "MX Payment Complement";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] A complement whose cancellation was never requested cannot be marked as canceled
        Initialize();

        // [GIVEN] A stamped payment complement without a cancellation request
        CreateStampedComplement(PaymentComplement);

        // [WHEN] The complement is marked as canceled
        asserterror MXPaymentComplCancel.MarkAsCanceled(PaymentComplement);

        // [THEN] An error is raised
        Assert.ExpectedError('Only a payment complement with a cancellation in progress or a cancellation error can be marked as canceled.');
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure CreateStampedComplement(var PaymentComplement: Record "MX Payment Complement")
    begin
        PaymentComplement.Init();
        PaymentComplement."Payment Entry No." := 1;
        PaymentComplement."Stamped UUID" := '11111111-2222-3333-4444-555555555555';
        PaymentComplement.Insert();
    end;

    local procedure Initialize()
    var
        PaymentComplement: Record "MX Payment Complement";
    begin
        PaymentComplement.DeleteAll();
    end;
}
