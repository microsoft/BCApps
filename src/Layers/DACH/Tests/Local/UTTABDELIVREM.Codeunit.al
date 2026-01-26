codeunit 142029 "UT TAB DELIVREM"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteIssuedDelivReminderHeader()
    var
        IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header";
        DeliveryReminderCommentLine: Record "Delivery Reminder Comment Line";
    begin
        // Purpose of the test is to validate Trigger OnDelete on Issued Deliv. Reminder Header Table.
        // Setup: Create Issued Delivery Reminder Header and Delivery Reminder Comment Line.
        IssuedDelivReminderHeader."No." := LibraryUTUtility.GetNewCode();
        IssuedDelivReminderHeader."No. Printed" := 1;
        IssuedDelivReminderHeader.Insert();

        DeliveryReminderCommentLine."Document Type" := DeliveryReminderCommentLine."Document Type"::"Issued Delivery Reminder";
        DeliveryReminderCommentLine."No." := IssuedDelivReminderHeader."No.";
        DeliveryReminderCommentLine."Line No." := 1;
        DeliveryReminderCommentLine.Insert();

        // Exercise: Delete Issued Delivery Reminder Header.
        IssuedDelivReminderHeader.Delete(true);

        // Verify: Verify Issued Delivery Reminder Header deleted and Delivery Reminder Comment Line deleted.
        Assert.IsFalse(IssuedDelivReminderHeader.Get(IssuedDelivReminderHeader."No."), 'Issued Deliv. Reminder Header not exist.');
        Assert.IsFalse(DeliveryReminderCommentLine.Get(DeliveryReminderCommentLine."Document Type"::"Issued Delivery Reminder", DeliveryReminderCommentLine."No.", DeliveryReminderCommentLine."Line No."), 'Delivery Reminder Comment Line not exist.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteDeliveryReminderTerm()
    var
        DeliveryReminderTerm: Record "Delivery Reminder Term";
        DeliveryReminderLevel: Record "Delivery Reminder Level";
    begin
        // Purpose of the test is to validate Trigger OnDelete on Delivery Reminder Term Table.
        // Setup: Create Delivery Reminder Term and Delivery Reminder Level.
        DeliveryReminderTerm.Code := '1';
        DeliveryReminderTerm.Insert();

        CreateDeliveryReminderLevel(DeliveryReminderLevel, DeliveryReminderTerm.Code);

        // Exercise: Delete Delivery Reminder Term.
        DeliveryReminderTerm.Delete(true);

        // Verify: Verify Delivery Reminder Term deleted and Delivery Reminder Level deleted.
        Assert.IsFalse(DeliveryReminderTerm.Get(DeliveryReminderTerm.Code), 'Delivery Reminder Term not exist.');
        Assert.IsFalse(DeliveryReminderLevel.Get(DeliveryReminderLevel."Reminder Terms Code", DeliveryReminderLevel."No."), 'Delivery Reminder Level not exist.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteDeliveryReminderLevel()
    var
        DeliveryReminderText: Record "Delivery Reminder Text";
        DeliveryReminderLevel: Record "Delivery Reminder Level";
    begin
        // Purpose of the test is to validate Trigger OnDelete on Delivery Reminder Level Table.
        // Setup: Create Delivery Reminder Level and Delivery Reminder Text.
        CreateDeliveryReminderLevel(DeliveryReminderLevel, '1');

        DeliveryReminderText."Reminder Terms Code" := DeliveryReminderLevel."Reminder Terms Code";
        DeliveryReminderText."Reminder Level" := DeliveryReminderLevel."No.";
        DeliveryReminderText.Position := DeliveryReminderText.Position::Beginning;
        DeliveryReminderText."Line No." := 1;
        DeliveryReminderText.Insert();

        // Exercise: Delete Delivery Reminder Level.
        DeliveryReminderLevel.Delete(true);

        // Verify: Verify Delivery Reminder Level deleted and Delivery Reminder Text deleted.
        Assert.IsFalse(DeliveryReminderLevel.Get(DeliveryReminderLevel."Reminder Terms Code", DeliveryReminderLevel."No."), 'Delivery Reminder Level not exist.');
        Assert.IsFalse(DeliveryReminderText.Get(DeliveryReminderText."Reminder Terms Code", DeliveryReminderText."Reminder Level", DeliveryReminderText.Position, DeliveryReminderText."Line No."), 'Delivery Reminder Text not exist.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure NewRecordDeliveryReminderLevel()
    var
        DeliveryReminderLevel: Record "Delivery Reminder Level";
        No: Integer;
    begin
        // Purpose of the test is to validate Function NewRecord on Delivery Reminder Level Table.
        // Setup: Create Delivery Reminder Level.
        CreateDeliveryReminderLevel(DeliveryReminderLevel, '1');
        No := DeliveryReminderLevel."No.";

        // Exercise: Create Delivery Reminder Level using NewRecord.
        DeliveryReminderLevel.NewRecord();

        // Verify: Verify Delivery Reminder Level No increased by 1.
        DeliveryReminderLevel.TestField("No.", No + 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnDeleteDeliveryReminderLine()
    var
        DeliveryReminderLine: Record "Delivery Reminder Line";
        DeliveryReminderLine2: Record "Delivery Reminder Line";
    begin
        // Purpose of the test is to validate Trigger OnDelete on Delivery Reminder Line Table.
        // Setup: Create two Delivery Reminder Line with relation Attached to Line No.
        CreateDeliveryReminderLine(DeliveryReminderLine, LibraryUTUtility.GetNewCode(), 1);  // Line No as 1.
        CreateDeliveryReminderLine(DeliveryReminderLine2, DeliveryReminderLine."Document No.", 2);  // Line No as 2.
        DeliveryReminderLine2."Attached to Line No." := DeliveryReminderLine."Line No.";
        DeliveryReminderLine2.Modify();

        // Exercise: Delete Delivery Reminder Line.
        DeliveryReminderLine.Delete(true);

        // Verify: Verify Relative Delivery Reminder line deleted.
        Assert.IsFalse(DeliveryReminderLine2.Get(DeliveryReminderLine2."Document No.", DeliveryReminderLine2."Line No."), 'Delivery Reminder Line not exist.');
    end;

    local procedure CreateDeliveryReminderLevel(var DeliveryReminderLevel: Record "Delivery Reminder Level"; ReminderTermsCode: Code[10])
    begin
        DeliveryReminderLevel."Reminder Terms Code" := ReminderTermsCode;
        DeliveryReminderLevel."No." := 1;
        DeliveryReminderLevel.Insert();
    end;

    local procedure CreateDeliveryReminderLine(var DeliveryReminderLine: Record "Delivery Reminder Line"; DocumentNo: Code[20]; LineNo: Integer)
    begin
        DeliveryReminderLine."Document No." := DocumentNo;
        DeliveryReminderLine."Line No." := LineNo;
        DeliveryReminderLine.Insert();
    end;
}

