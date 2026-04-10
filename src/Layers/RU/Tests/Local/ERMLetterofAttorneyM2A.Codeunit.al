codeunit 144713 "ERM Letter of Attorney M-2A"
{
    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        NoSeriesChangedErr: Label 'No Series changed after running report with preview.';
        NoSeriesNotChangedErr: Label 'No Series not changed after running report without preview.';
        isInitialized: Boolean;
        IncorrectValueErr: Label 'Incorrect value for field %1';

    [Test]
    [Scope('OnPrem')]
    procedure LetterOfAttorney_PrintPreview_EmptyDocumentNo()
    begin
        GetNoseriesAndPrintM2a(true);

        LibraryReportValidation.VerifyCellValue(9, 45, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LetterOfAttorney_PrintPreview_NoSeriesNotChanged()
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        NoSeries: Codeunit "No. Series";
        NoBefore: Code[20];
    begin
        NoBefore := GetNoseriesAndPrintM2a(true);

        PurchaseSetup.Get();
        Assert.AreEqual(NoBefore, NoSeries.PeekNextNo(PurchaseSetup."Released Letter of Attor. Nos."), NoSeriesChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LetterOfAttorney_Print_DocumentNoFilled()
    begin
        LibraryReportValidation.VerifyCellValue(9, 45, GetNoseriesAndPrintM2a(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LetterOfAttorney_Print_NoSeriesChanged()
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        NoSeries: Codeunit "No. Series";
        NoBefore: Code[20];
    begin
        NoBefore := GetNoseriesAndPrintM2a(false);

        PurchaseSetup.Get();
        Assert.AreNotEqual(
          NoBefore,
          NoSeries.PeekNextNo(PurchaseSetup."Released Letter of Attor. Nos."),
          NoSeriesNotChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAttLetterLinesFromPurchaseDoc()
    var
        LetterOfAttorneyHeader: Record "Letter of Attorney Header";
        PurchaseLine: Record "Purchase Line";
        LetterOfAttorneyLine: Record "Letter of Attorney Line";
    begin
        Initialize();
        CreateAttHeader(LetterOfAttorneyHeader);

        CreateAttLines(LetterOfAttorneyHeader, LetterOfAttorneyLine, PurchaseLine);

        Assert.AreEqual(LetterOfAttorneyLine.Type::Item, LetterOfAttorneyLine.Type,
          StrSubstNo(IncorrectValueErr, LetterOfAttorneyLine.Type));
        Assert.AreEqual(PurchaseLine."No.", LetterOfAttorneyLine."No.",
          StrSubstNo(IncorrectValueErr, LetterOfAttorneyLine."No."));
        Assert.AreEqual(PurchaseLine.Quantity, LetterOfAttorneyLine.Quantity,
          StrSubstNo(IncorrectValueErr, LetterOfAttorneyLine.Quantity));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if isInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
    end;

    local procedure GetNoseriesAndPrintM2a(Preview: Boolean) NoSeriesBefore: Code[20]
    var
        PurchaseSetup: Record "Purchases & Payables Setup";
        NoSeries: Codeunit "No. Series";
    begin
        Initialize();
        PurchaseSetup.Get();
        NoSeriesBefore := NoSeries.PeekNextNo(PurchaseSetup."Released Letter of Attor. Nos.");
        CreateLetterOfAttorneyAndPrint(Preview);
    end;

    local procedure CreateLetterOfAttorneyAndPrint(Preview: Boolean)
    var
        LetterOfAttorneyHeader: Record "Letter of Attorney Header";
        Employee: Record Employee;
        LetterOfAttorneyM2A: Report "Letter of Attorney M-2A";
    begin
        CreateAttHeader(LetterOfAttorneyHeader);

        Employee.Get(LetterOfAttorneyHeader."Employee No.");

        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        LetterOfAttorneyM2A.InitializeRequest(LibraryReportValidation.GetFileName(), Preview);
        LetterOfAttorneyM2A.SetTableView(LetterOfAttorneyHeader);
        LetterOfAttorneyM2A.UseRequestPage(false);
        LetterOfAttorneyM2A.Run();
    end;

    local procedure CreateAttHeader(var LetterOfAttorneyHeader: Record "Letter of Attorney Header")
    var
        Vendor: Record Vendor;
    begin
        LetterOfAttorneyHeader.Init();
        LetterOfAttorneyHeader."No." :=
          LibraryUtility.GenerateRandomCode(LetterOfAttorneyHeader.FieldNo("No."), DATABASE::"Letter of Attorney Header");
        LetterOfAttorneyHeader.Validate(
          "Employee No.", LibraryHumanResource.CreateEmployeeNo());

        LetterOfAttorneyHeader.Insert(true);
        LibraryPurchase.CreateVendor(Vendor);
        LetterOfAttorneyHeader.Validate("Buy-from Vendor No.", Vendor."No.");
        LetterOfAttorneyHeader.Modify(true);
    end;

    local procedure CreateAttLines(LetterOfAttorneyHeader: Record "Letter of Attorney Header"; var LetterOfAttorneyLine: Record "Letter of Attorney Line"; var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, LetterOfAttorneyHeader."Buy-from Vendor No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));

        LetterOfAttorneyHeader.Validate("Source Document Type", PurchaseHeader."Document Type".AsInteger() + 1);
        LetterOfAttorneyHeader.Validate("Source Document No.", PurchaseHeader."No.");
        LetterOfAttorneyHeader.Modify(true);

        LetterOfAttorneyHeader.CreateAttorneyLetterLines();

        LetterOfAttorneyLine.SetRange("Letter of Attorney No.", LetterOfAttorneyHeader."No.");
        LetterOfAttorneyLine.FindFirst();
    end;
}

