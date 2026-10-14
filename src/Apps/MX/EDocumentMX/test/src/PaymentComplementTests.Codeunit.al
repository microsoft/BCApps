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
    procedure PaymentComplementPaymentEntryNoMustBeUnique()
    var
        PaymentComplement: Record "MX Payment Complement";
        DuplicatePaymentComplement: Record "MX Payment Complement";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Only one payment complement can exist for a payment ledger entry
        Initialize();

        // [GIVEN] A payment complement for payment ledger entry 1
        PaymentComplement.Init();
        PaymentComplement."Payment Entry No." := 1;
        PaymentComplement.Insert();

        // [WHEN] Another payment complement is inserted for the same payment ledger entry
        DuplicatePaymentComplement.Init();
        DuplicatePaymentComplement."Payment Entry No." := PaymentComplement."Payment Entry No.";
        asserterror DuplicatePaymentComplement.Insert();

        // [THEN] The duplicate payment complement is rejected
        Assert.ExpectedError('Ya existe un registro');
        Assert.ExpectedErrorCode('DB:RecordExists');
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

    local procedure Initialize()
    begin
    end;
}
