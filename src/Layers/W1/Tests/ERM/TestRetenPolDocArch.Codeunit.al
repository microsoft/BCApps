codeunit 134065 "Test Reten. Pol. Doc. Arch."
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ArchiveSalesDocQst: Label 'Archive Order no.: %1?', Comment = '%1 is a document number';
        ArchiveSalesDocMsg: Label 'Document %1 has been archived.', Comment = '%1 is a document number';

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestSalesDocArchiveRetenPolThreeDaysSourceExists()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreateSalesHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreateSalesDocument(SalesHeader);
        ArchiveSalesDocuments(SalesHeader); // creates 3 versions

        // age the archive
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.ModifyAll("Date Archived", CalcDate('<-3D>', Today()));
        Assert.AreEqual(3, SalesHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        Assert.AreEqual(3, SalesHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestSalesDocArchiveRetenPolThreeDays()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreateSalesHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreateSalesDocument(SalesHeader);
        ArchiveSalesDocuments(SalesHeader); // creates 3 versions

        // age the archive
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.ModifyAll("Date Archived", CalcDate('<-3D>', Today()));
        Assert.AreEqual(3, SalesHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        Assert.AreEqual(3, SalesHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestSalesDocArchiveRetenPolTwoWeeksSourceExists()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreateSalesHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreateSalesDocument(SalesHeader);
        ArchiveSalesDocuments(SalesHeader); // creates 3 versions

        // age the archive
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.ModifyAll("Date Archived", CalcDate('<-2W>', Today()));
        Assert.AreEqual(3, SalesHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        Assert.AreEqual(3, SalesHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestSalesDocArchiveRetenPolSixWeeksSourceExists()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreateSalesHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreateSalesDocument(SalesHeader);
        ArchiveSalesDocuments(SalesHeader); // creates 3 versions

        // age the archive
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.ModifyAll("Date Archived", CalcDate('<-6W>', Today()));
        Assert.AreEqual(3, SalesHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        Assert.AreEqual(3, SalesHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestSalesDocArchiveRetenPolTwoWeeks()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreateSalesHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreateSalesDocument(SalesHeader);
        ArchiveSalesDocuments(SalesHeader); // creates 3 versions
        SalesHeader.Delete();

        // age the archive
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.ModifyAll("Date Archived", CalcDate('<-2W>', Today()));
        Assert.AreEqual(3, SalesHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        Assert.AreEqual(1, SalesHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestSalesDocArchiveRetenPolSixWeeks()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreateSalesHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreateSalesDocument(SalesHeader);
        ArchiveSalesDocuments(SalesHeader); // creates 3 versions
        SalesHeader.Delete();

        // age the archive
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.ModifyAll("Date Archived", CalcDate('<-6W>', Today()));
        Assert.AreEqual(3, SalesHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        Assert.RecordIsEmpty(SalesHeaderArchive);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestPurchaseDocArchiveRetenPolThreeDaysourceExists()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreatePurchaseHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreatePurchaseDocument(PurchaseHeader);
        ArchivePurchaseDocuments(PurchaseHeader); // creates 3 versions

        // age the archive
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.ModifyAll("Date Archived", CalcDate('<-3D>', Today()));
        Assert.AreEqual(3, PurchaseHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        Assert.AreEqual(3, PurchaseHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestPurchaseDocArchiveRetenPolThreeDays()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreatePurchaseHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreatePurchaseDocument(PurchaseHeader);
        ArchivePurchaseDocuments(PurchaseHeader); // creates 3 versions

        // age the archive
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.ModifyAll("Date Archived", CalcDate('<-3D>', Today()));
        Assert.AreEqual(3, PurchaseHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        Assert.AreEqual(3, PurchaseHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestPurchaseDocArchiveRetenPolTwoWeeksSourceExists()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreatePurchaseHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreatePurchaseDocument(PurchaseHeader);
        ArchivePurchaseDocuments(PurchaseHeader); // creates 3 versions

        // age the archive
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.ModifyAll("Date Archived", CalcDate('<-2W>', Today()));
        Assert.AreEqual(3, PurchaseHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        Assert.AreEqual(3, PurchaseHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestPurchaseDocArchiveRetenPolSixWeeksSourceExists()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreatePurchaseHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreatePurchaseDocument(PurchaseHeader);
        ArchivePurchaseDocuments(PurchaseHeader); // creates 3 versions

        // age the archive
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.ModifyAll("Date Archived", CalcDate('<-6W>', Today()));
        Assert.AreEqual(3, PurchaseHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        Assert.AreEqual(3, PurchaseHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestPurchaseDocArchiveRetenPolTwoWeeks()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreatePurchaseHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreatePurchaseDocument(PurchaseHeader);
        ArchivePurchaseDocuments(PurchaseHeader); // creates 3 versions
        PurchaseHeader.Delete();

        // age the archive
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.ModifyAll("Date Archived", CalcDate('<-2W>', Today()));
        Assert.AreEqual(3, PurchaseHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        Assert.AreEqual(1, PurchaseHeaderArchive.Count(), 'Unexpected number of archive records');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,MessageHandler')]
    procedure TestPurchaseDocArchiveRetenPolSixWeeks()
    var
        RetentionPolicySetup: Record "Retention Policy Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        ApplyRetentionPolicy: Codeunit "Apply Retention Policy";
    begin
        Initialize();
        // Setup
        CreatePurchaseHeaderArchiveRetentionPolicySetup(RetentionPolicySetup);
        CreatePurchaseDocument(PurchaseHeader);
        ArchivePurchaseDocuments(PurchaseHeader); // creates 3 versions
        PurchaseHeader.Delete();

        // age the archive
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.ModifyAll("Date Archived", CalcDate('<-6W>', Today()));
        Assert.AreEqual(3, PurchaseHeaderArchive.Count(), 'Unexpected number of archive records');

        // Exercise
        ApplyRetentionPolicy.ApplyRetentionPolicy(RetentionPolicySetup, false);

        // Verify
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        Assert.RecordIsEmpty(PurchaseHeaderArchive);
    end;

    local procedure Initialize()
    var
        SalesHeaderArchive: Record "Sales Header Archive";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        RetentionPolicySetup: Record "Retention Policy Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Test Reten. Pol. Doc. Arch.");
        LibraryVariableStorage.AssertEmpty();
        SalesHeaderArchive.DeleteAll(true);
        PurchaseHeaderArchive.DeleteAll(true);
        RetentionPolicySetup.SetFilter("Table Id", '%1|%2', Database::"Sales Header Archive", Database::"Purchase Header Archive");
        RetentionPolicySetup.DeleteAll(true);

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Test Reten. Pol. Doc. Arch.");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Test Reten. Pol. Doc. Arch.");
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header");
    begin
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader.InitInsert();
        SalesHeader.Insert();
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header");
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader.InitInsert();
        PurchaseHeader.Insert();
    end;

    local procedure ArchiveSalesDocuments(SalesHeader: Record "Sales Header")
    var
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
    end;

    local procedure ArchivePurchaseDocuments(PurchaseHeader: Record "Purchase Header")
    var
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);
    end;

    local procedure CreateOneWeekRetentionPeriod(var RetentionPeriod: Record "Retention Period")
    begin
        CreateRetentionPeriod(RetentionPeriod, RetentionPeriod."Retention Period"::"1 Week");
    end;

    local procedure CreateOneMonthRetentionPeriod(var RetentionPeriod: Record "Retention Period")
    begin
        CreateRetentionPeriod(RetentionPeriod, RetentionPeriod."Retention Period"::"1 Month");
    end;

    local procedure CreateRetentionPeriod(var RetentionPeriod: Record "Retention Period"; RetentionPeriodEnum: Enum "Retention Period Enum")
    begin
        RetentionPeriod.SetRange("Retention Period", RetentionPeriodEnum);
        if not RetentionPeriod.FindFirst() then begin
            RetentionPeriod.Code := Format(RetentionPeriodEnum);
            RetentionPeriod.Validate("Retention Period", RetentionPeriodEnum);
            RetentionPeriod.Insert();
        end;
    end;

    local procedure CreateSalesHeaderArchiveRetentionPolicySetup(var RetentionPolicySetup: Record "Retention Policy Setup")
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RetentionPeriod: Record "Retention Period";
    begin
        // mandatory: keep all if source doc exists
        // delete all except last version after 1 week
        // delete all after 1 month
        RetentionPolicySetup.Validate("Table Id", Database::"Sales Header Archive");
        RetentionPolicySetup.Validate("Apply to all records", false);
        RetentionPolicySetup."Date Field No." := 5045; // "Date Archived" -> bypass system created at issue
        RetentionPolicySetup.Validate(Enabled, true);
        RetentionPolicySetup.Insert(true);

        RetentionPolicySetupLine.SetRange("Table ID", Database::"Sales Header Archive");
        RetentionPolicySetupLine.FindLast();
        RetentionPolicySetupLine.Init();

        CreateOneMonthRetentionPeriod(RetentionPeriod);
        RetentionPolicySetupLine.Validate("Table ID", Database::"Sales Header Archive");
        RetentionPolicySetupLine."Line No." += 1;
        RetentionPolicySetupLine."Date Field No." := RetentionPolicySetup."Date Field No.";
        RetentionPolicySetupLine.Validate("Retention Period", RetentionPeriod.Code);
        RetentionPolicySetupLine."Keep Last Version" := false;
        RetentionPolicySetupLine.Insert(true);

        CreateOneWeekRetentionPeriod(RetentionPeriod);
        RetentionPolicySetupLine.Validate("Table ID", Database::"Sales Header Archive");
        RetentionPolicySetupLine."Line No." += 1;
        RetentionPolicySetupLine."Date Field No." := RetentionPolicySetup."Date Field No.";
        RetentionPolicySetupLine.Validate("Retention Period", RetentionPeriod.Code);
        RetentionPolicySetupLine."Keep Last Version" := true;
        RetentionPolicySetupLine.Insert(true);
    end;

    local procedure CreatePurchaseHeaderArchiveRetentionPolicySetup(var RetentionPolicySetup: Record "Retention Policy Setup")
    var
        RetentionPolicySetupLine: Record "Retention Policy Setup Line";
        RetentionPeriod: Record "Retention Period";
    begin
        // mandatory: keep all if source doc exists
        // delete all except last version after 1 week
        // delete all after 1 month
        RetentionPolicySetup.Validate("Table Id", Database::"Purchase Header Archive");
        RetentionPolicySetup.Validate("Apply to all records", false);
        RetentionPolicySetup."Date Field No." := 5045; // "Date Archived" -> bypass system created at issue
        RetentionPolicySetup.Validate(Enabled, true);
        RetentionPolicySetup.Insert(true);

        RetentionPolicySetupLine.SetRange("Table ID", Database::"Purchase Header Archive");
        RetentionPolicySetupLine.FindLast();
        RetentionPolicySetupLine.Init();

        CreateOneMonthRetentionPeriod(RetentionPeriod);
        RetentionPolicySetupLine.Validate("Table ID", Database::"Purchase Header Archive");
        RetentionPolicySetupLine."Line No." += 1;
        RetentionPolicySetupLine."Date Field No." := RetentionPolicySetup."Date Field No.";
        RetentionPolicySetupLine.Validate("Retention Period", RetentionPeriod.Code);
        RetentionPolicySetupLine."Keep Last Version" := false;
        RetentionPolicySetupLine.Insert(true);

        CreateOneWeekRetentionPeriod(RetentionPeriod);
        RetentionPolicySetupLine.Validate("Table ID", Database::"Purchase Header Archive");
        RetentionPolicySetupLine."Line No." += 1;
        RetentionPolicySetupLine."Date Field No." := RetentionPolicySetup."Date Field No.";
        RetentionPolicySetupLine.Validate("Retention Period", RetentionPeriod.Code);
        RetentionPolicySetupLine."Keep Last Version" := true;
        RetentionPolicySetupLine.Insert(true);
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(StrSubstNo(ArchiveSalesDocQst, LibraryVariableStorage.DequeueText()), Question);
        Reply := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(StrSubstNo(ArchiveSalesDocMsg, LibraryVariableStorage.DequeueText()), Message);
    end;
}