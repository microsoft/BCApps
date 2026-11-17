// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.TestLibraries.Security.AccessControl;

codeunit 148240 "Banking FI Permission Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        PermissionsMock: Codeunit "Permissions Mock";

    [Test]
    procedure LocalReadCanInspectButCannotWritePaymentHistory()
    var
        Payment: Record "Ref. Payment - Exported FI";
        Affiliated: Record "Ref. Payment - Exported FI";
        Unrelated: Record "Ref. Payment - Exported FI";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] LOCAL READ includes replacement payment history without granting processing write access.
        Initialize();

        // [GIVEN] Payment "P", its affiliate "A" and unrelated payment "U".
        CreatePayments(Payment, Affiliated, Unrelated);

        // [WHEN] The user has LOCAL READ rather than SUPER or LOCAL.
        PermissionsMock.Set('LOCAL READ');

        // [THEN] Retained payment history is readable, but processing cannot write its transfer state.
        VerifyReadOnlyPayment(Payment);
        VerifyReadOnlyPayment(Affiliated);
        VerifyReadOnlyPayment(Unrelated);
    end;

    [Test]
    procedure LocalCanTransferAffiliatedPaymentsWithoutSuper()
    var
        Payment: Record "Ref. Payment - Exported FI";
        Affiliated: Record "Ref. Payment - Exported FI";
        Unrelated: Record "Ref. Payment - Exported FI";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] LOCAL supplies the replacement processing rights without relying on SUPER.
        Initialize();

        // [GIVEN] Payment "P", its affiliate "A" and unrelated payment "U".
        CreatePayments(Payment, Affiliated, Unrelated);
        PermissionsMock.Set('LOCAL');

        // [WHEN] Production processing propagates the successful transfer to affiliates.
        Payment.MarkAffiliatedAsTransferred();

        // [THEN] Only the affiliated payment is marked transferred.
        VerifyTransferStates(Affiliated, Unrelated);
    end;

    local procedure Initialize()
    begin
        if not PermissionsMock.IsStarted() then
            PermissionsMock.Start();
        PermissionsMock.ClearAssignments();
    end;

    local procedure CreatePayments(var Payment: Record "Ref. Payment - Exported FI"; var Affiliated: Record "Ref. Payment - Exported FI"; var Unrelated: Record "Ref. Payment - Exported FI")
    var
        NextNo: Integer;
    begin
        Payment.LockTable();
        NextNo := 1;
        if Payment.FindLast() then
            NextNo := Payment."No." + 1;
        Payment.Init();
        Payment."No." := NextNo;
        Payment."Affiliated to Line" := Payment."No.";
        Payment.Transferred := true;
        Payment.Insert();

        Affiliated."No." := Payment."No." + 1;
        Affiliated."Affiliated to Line" := Payment."No.";
        Affiliated.Insert();

        Unrelated."No." := Affiliated."No." + 1;
        Unrelated.Insert();
    end;

    local procedure VerifyReadOnlyPayment(Payment: Record "Ref. Payment - Exported FI")
    begin
        Payment.Get(Payment."No.");
        Assert.IsTrue(Payment.ReadPermission(), 'LOCAL READ must retain access to replacement payment history.');
        Assert.IsFalse(Payment.WritePermission(), 'LOCAL READ must not acquire the write permissions needed for payment processing.');
    end;

    local procedure VerifyTransferStates(Affiliated: Record "Ref. Payment - Exported FI"; Unrelated: Record "Ref. Payment - Exported FI")
    begin
        Affiliated.Get(Affiliated."No.");
        Assert.IsTrue(Affiliated.Transferred, 'LOCAL must allow the production affiliation update without SUPER.');
        Unrelated.Get(Unrelated."No.");
        Assert.IsFalse(Unrelated.Transferred, 'The affiliation update must not transfer unrelated payments.');
    end;
}
