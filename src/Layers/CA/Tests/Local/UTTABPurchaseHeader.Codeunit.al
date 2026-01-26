codeunit 144050 "UT TAB Purchase Header"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Sales Tax] [Purchase]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibrarVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateLocationCodePurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        TaxAreaCode: Code[20];
    begin
        // Purpose of the test is to validate Trigger OnValidate of Location Code for Table 38 - Purchase Header.

        // Setup.
        UpdatePurchasePayablesSetup();
        TaxAreaCode := CreateTaxArea();
        CreatePurchaseHeader(PurchaseHeader, CreateVendor(TaxAreaCode), '', '');
        RecRef.GetTable(PurchaseHeader);
        FieldRef := RecRef.Field(PurchaseHeader.FieldNo("Location Code"));

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        FieldRef.Validate();

        // Verify.
        RecRef.SetTable(PurchaseHeader);
        PurchaseHeader.TestField("Tax Area Code", TaxAreaCode);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnValidateLocCodeVendorLocBusiPresPurchHeader()
    begin
        // Purpose of the test is to validate Trigger OnValidate of Location Code when Business Presence is false for Table 38 - Purchase Header.
        ValidateVendorLocationTaxAreaCode('');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TaxAreaOnPurchaseOrderWithResponsibilityCenter()
    begin
        // Purpose of the test is to verify Tax Area Code when Responsibility Center is updated on Purchase Order.
        ValidateVendorLocationTaxAreaCode(CreateResponsibilityCenter());
    end;

    local procedure ValidateVendorLocationTaxAreaCode(ResponsibilityCenter: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        VendorAltTaxAreaCode: Code[20];
        VendorNo: Code[20];
    begin
        // Setup.
        VendorNo := CreateVendor('');
        VendorAltTaxAreaCode := CreateVendorLocation(VendorNo, '');
        CreatePurchaseHeader(PurchaseHeader, VendorNo, '', '');
        PurchaseHeader."Responsibility Center" := ResponsibilityCenter;
        PurchaseHeader.Modify();
        RecRef.GetTable(PurchaseHeader);
        FieldRef := RecRef.Field(PurchaseHeader.FieldNo("Location Code"));

        // Exercise: Validate statement to call OnValidate Trigger of the respective fields.
        FieldRef.Validate();

        // Verify.
        RecRef.SetTable(PurchaseHeader);
        PurchaseHeader.TestField("Tax Area Code", VendorAltTaxAreaCode);
    end;

    [Test]
    [HandlerFunctions('ReqWorksheetTemplateListHandler,CarryOutActionMsgHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    [Scope('OnPrem')]
    procedure TaxAreaOnPurchaseOrderThroughRequisitionLine()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorAltTaxAreaCode: Code[20];
        LocationCode: Code[10];
        VendorNo: Code[20];
        RequisitionWkshName: Code[10];
    begin
        // Purpose of the test is to verify Tax Area Code when Purchase Order is created from Requisition Worksheet using Carry out action message.

        // Setup.
        VendorNo := CreateVendor('');
        LocationCode := CreateLocation();
        VendorAltTaxAreaCode := CreateVendorLocation(VendorNo, LocationCode);
        RequisitionWkshName := CreateRequisitionLine(VendorNo, LocationCode);

        // Exercise.
        OpenReqWorksheet(RequisitionWkshName, VendorNo);

        // Verify.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst();
        PurchaseHeader.TestField("Tax Area Code", VendorAltTaxAreaCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ArchivePurchaseOrderWithTaxArea()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
        VendorNo: Code[20];
    begin
        // Purpose of the test is to verify Tax Area Code when Archive Document functionality is used on Purchase Order.

        // Setup.
        VendorNo := CreateVendor('');
        CreatePurchaseOrder(PurchaseHeader, VendorNo, '', CreateTaxArea());

        // Exercise.
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        // Verify.
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.FindFirst();
        PurchaseHeaderArchive.TestField("Tax Area Code", PurchaseHeader."Tax Area Code");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item."Inventory Posting Group" := LibraryUTUtility.GetNewCode10();
        Item."Gen. Prod. Posting Group" := LibraryUTUtility.GetNewCode10();
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.Code := LibraryUTUtility.GetNewCode10();
        Location.Insert();
        exit(Location.Code);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; LocationCode: Code[10]; TaxAreaCode: Code[20])
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := VendorNo;
        PurchaseHeader."Location Code" := LocationCode;
        PurchaseHeader."Tax Area Code" := TaxAreaCode;
        PurchaseHeader."Pay-to Vendor No." := PurchaseHeader."Buy-from Vendor No.";
        PurchaseHeader.Insert();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; LocationCode: Code[10]; TaxAreaCode: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, VendorNo, LocationCode, TaxAreaCode);
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine."Buy-from Vendor No." := PurchaseHeader."Buy-from Vendor No.";
        PurchaseLine."Pay-to Vendor No." := PurchaseHeader."Pay-to Vendor No.";
        PurchaseLine."Line No." := LibraryRandom.RandInt(10);
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := CreateItem();
        PurchaseLine.Insert();
    end;

    local procedure CreateRequisitionLine(VendorNo: Code[20]; LocationCode: Code[10]): Code[10]
    var
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.Name := LibraryUTUtility.GetNewCode10();
        ReqWkshTemplate.Type := ReqWkshTemplate.Type::"Req.";
        ReqWkshTemplate."Page ID" := PAGE::"Req. Worksheet";
        ReqWkshTemplate.Insert();

        RequisitionWkshName.Name := LibraryUTUtility.GetNewCode10();
        RequisitionWkshName."Worksheet Template Name" := ReqWkshTemplate.Name;
        RequisitionWkshName."Template Type" := RequisitionWkshName."Template Type"::"Req.";
        RequisitionWkshName.Insert();

        RequisitionLine."Worksheet Template Name" := RequisitionWkshName."Worksheet Template Name";
        RequisitionLine."Journal Batch Name" := RequisitionWkshName.Name;
        RequisitionLine."Line No." := LibraryRandom.RandInt(10);
        RequisitionLine.Type := RequisitionLine.Type::Item;
        RequisitionLine."No." := CreateItem();
        RequisitionLine."Action Message" := RequisitionLine."Action Message"::New;
        RequisitionLine."Accept Action Message" := true;
        RequisitionLine.Quantity := LibraryRandom.RandInt(10);
        RequisitionLine."Vendor No." := VendorNo;
        RequisitionLine."Location Code" := LocationCode;
        RequisitionLine.Insert();
        LibrarVariableStorage.Enqueue(RequisitionWkshName."Worksheet Template Name");  // Enqueue value for ReqWorksheetTemplateListHandler.
        exit(RequisitionWkshName.Name);
    end;

    local procedure CreateResponsibilityCenter(): Code[10]
    var
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        ResponsibilityCenter.Code := LibraryUTUtility.GetNewCode10();
        ResponsibilityCenter.Insert();
        exit(ResponsibilityCenter.Code);
    end;

    local procedure CreateTaxArea(): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        TaxArea.Code := LibraryUTUtility.GetNewCode();
        TaxArea."Country/Region" := TaxArea."Country/Region"::CA;
        TaxArea.Insert();
        exit(TaxArea.Code);
    end;

    local procedure CreateVendor(TaxAreaCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor."Tax Area Code" := TaxAreaCode;
        Vendor."Vendor Posting Group" := LibraryUTUtility.GetNewCode10();
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure CreateVendorLocation(VendorNo: Code[20]; LocationCode: Code[10]): Code[20]
    var
        VendorLocation: Record "Vendor Location";
    begin
        VendorLocation."Vendor No." := VendorNo;
        VendorLocation."Alt. Tax Area Code" := CreateTaxArea();
        VendorLocation."Location Code" := LocationCode;
        VendorLocation.Insert();
        exit(VendorLocation."Alt. Tax Area Code");
    end;

    local procedure OpenReqWorksheet(RequisitionWkshName: Code[10]; VendorNo: Code[20])
    var
        ReqWorksheet: TestPage "Req. Worksheet";
    begin
        Commit();  // COMMIT is required to open the Requisition Worksheet.
        ReqWorksheet.OpenEdit();
        ReqWorksheet.CurrentJnlBatchName.SetValue(RequisitionWkshName);
        ReqWorksheet.FILTER.SetFilter("Vendor No.", VendorNo);
        ReqWorksheet.CarryOutActionMessage.Invoke();
    end;

    local procedure UpdatePurchasePayablesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup."Use Vendor's Tax Area Code" := true;
        PurchasesPayablesSetup.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CarryOutActionMsgHandler(var CarryOutActionMsgReq: TestRequestPage "Carry Out Action Msg. - Req.")
    begin
        CarryOutActionMsgReq.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReqWorksheetTemplateListHandler(var ReqWorksheetTemplateList: TestPage "Req. Worksheet Template List")
    var
        Name: Variant;
    begin
        LibrarVariableStorage.Dequeue(Name);
        ReqWorksheetTemplateList.FILTER.SetFilter(Name, Name);
        ReqWorksheetTemplateList.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

