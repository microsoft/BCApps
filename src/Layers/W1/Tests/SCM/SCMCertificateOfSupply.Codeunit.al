codeunit 137112 "SCM Certificate Of Supply"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Certificate of Supply] [SCM]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        DateCannotBeEmptyErr: Label 'The Receipt Date cannot be empty when Status is Received.';
        NoCannotBeEmptyErr: Label 'The No. field cannot be empty when the status of the Certificate of Supply is set to Required, Received, or Not Received.';
        CertRecDateBeforeShipPostDateMsg: Label 'The Receipt Date of the certificate cannot be earlier than the Shipment/Posting Date.';
        VehicleRegNoCannotBeChangedErr: Label 'The %1 field cannot be changed when the status of the Certificate of Supply is set to %2.';

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyNotRequiredPostSalesOrder()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // acceptance criteria 2 - Certificate of Supply posted with Ship option, then shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, false);

        // verify
        asserterror CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        Assert.ExpectedErrorCannotFind(Database::"Certificate of Supply");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredPostSalesOrder()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // acceptance criteria 2 - Certificate of Supply posted with Ship option, then shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);

        // verify
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");

        // verify cert properties
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", CertificateOfSupply.Status::Required, SalesShipmentHeader."No.", 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredPostSalesOrderFirstLineRequired()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // acceptance criteria 2 - Certificate of Supply posted with Ship option, then shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        PostMultilineSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);

        // verify
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");

        // verify cert properties
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", CertificateOfSupply.Status::Required, SalesShipmentHeader."No.", 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredPostSalesOrderSecondLineRequired()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // acceptance criteria 2 - Certificate of Supply posted with Ship option, then shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        PostMultilineSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, false);

        // verify
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");

        // verify cert properties
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", CertificateOfSupply.Status::Required, SalesShipmentHeader."No.", 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyNotRequiredPostServiceOrder()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // acceptance criteria 2 - Certificate of Supply posted with Ship option, then shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        PostServiceDoc(ServiceShipmentHeader, ServiceHeader."Document Type"::Order, false);

        // verify
        asserterror CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Service Shipment", ServiceShipmentHeader."No.");
        Assert.ExpectedErrorCannotFind(Database::"Certificate of Supply");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredPostServiceOrder()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // acceptance criteria 2 - Certificate of Supply posted with Ship option, then shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        PostServiceDoc(ServiceShipmentHeader, ServiceHeader."Document Type"::Order, true);

        // verify
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Service Shipment", ServiceShipmentHeader."No.");

        // verify cert properties
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Service Shipment",
          ServiceShipmentHeader."No.", CertificateOfSupply.Status::Required, ServiceShipmentHeader."No.", 0D);
        VerifyCertServiceShipmentProperties(CertificateOfSupply, ServiceShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredPostServiceOrderFirstLineRequired()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // acceptance criteria 2 - Certificate of Supply posted with Ship option, then shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        PostMultilineServiceDoc(ServiceShipmentHeader, ServiceHeader."Document Type"::Order, true);

        // verify
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Service Shipment", ServiceShipmentHeader."No.");

        // verify cert properties
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Service Shipment",
          ServiceShipmentHeader."No.", CertificateOfSupply.Status::Required, ServiceShipmentHeader."No.", 0D);
        VerifyCertServiceShipmentProperties(CertificateOfSupply, ServiceShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredPostServiceOrderSecondLineRequired()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // acceptance criteria 2 - Certificate of Supply posted with Ship option, then shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        PostMultilineServiceDoc(ServiceShipmentHeader, ServiceHeader."Document Type"::Order, false);

        // verify
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Service Shipment", ServiceShipmentHeader."No.");

        // verify cert properties
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Service Shipment",
          ServiceShipmentHeader."No.", CertificateOfSupply.Status::Required, ServiceShipmentHeader."No.", 0D);
        VerifyCertServiceShipmentProperties(CertificateOfSupply, ServiceShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyNotRequiredPostPurchaseReturnOrder()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        // acceptance criteria 2 - Certificate of Supply posted with Ship option, then shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        PostPurchaseDoc(ReturnShipmentHeader, PurchaseHeader."Document Type"::"Return Order", false);

        asserterror CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Return Shipment", ReturnShipmentHeader."No.");
        Assert.ExpectedErrorCannotFind(Database::"Certificate of Supply");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredPostPurchaseReturnOrder()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        // acceptance criteria 2 - Certificate of Supply posted with Ship option, then shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        PostPurchaseDoc(ReturnShipmentHeader, PurchaseHeader."Document Type"::"Return Order", true);

        // verify
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Return Shipment", ReturnShipmentHeader."No.");

        // verify cert properties
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Return Shipment",
          ReturnShipmentHeader."No.", CertificateOfSupply.Status::Required, ReturnShipmentHeader."No.", 0D);
        VerifyCertReturnShipmentProperties(CertificateOfSupply, ReturnShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredPostPurchaseReturnOrderFirstLineRequired()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        // acceptance criteria 2 - Certificate of Supply posted with Ship option, then shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        PostMultilinePurchaseDoc(ReturnShipmentHeader, PurchaseHeader."Document Type"::"Return Order", true);

        // verify
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Return Shipment", ReturnShipmentHeader."No.");

        // verify cert properties
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Return Shipment",
          ReturnShipmentHeader."No.", CertificateOfSupply.Status::Required, ReturnShipmentHeader."No.", 0D);
        VerifyCertReturnShipmentProperties(CertificateOfSupply, ReturnShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredPostPurchaseReturnOrderSecondLineRequired()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        // acceptance criteria 2 - Certificate of Supply posted with Ship option, then shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        PostMultilinePurchaseDoc(ReturnShipmentHeader, PurchaseHeader."Document Type"::"Return Order", false);

        // verify
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Return Shipment", ReturnShipmentHeader."No.");

        // verify cert properties
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Return Shipment",
          ReturnShipmentHeader."No.", CertificateOfSupply.Status::Required, ReturnShipmentHeader."No.", 0D);
        VerifyCertReturnShipmentProperties(CertificateOfSupply, ReturnShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredPostReceiveDropShipment()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        Purchasing: Record Purchasing;
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // acceptance criteria - Post Sales Order with Purch. Code set to Drop Shipment and linked Purchase Order as Receive
        // then Sales shipment created from that order will have Certificate of Supply Status set to Required

        // setup
        Initialize();

        // exercise
        CreateVATPostingGroup(VATPostingSetup);
        SetCertofSupplyRequired(VATPostingSetup, true);
        CreatePurchasing(Purchasing);

        ReleaseSalesOrderDropShipment(SalesHeader, VATPostingSetup, Purchasing.Code);

        SalesShipmentHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentHeader.FindFirst();

        // verify
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");

        // verify cert properties
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", CertificateOfSupply.Status::Required, SalesShipmentHeader."No.", 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader);

        // tear down
        Purchasing.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredToNotReceived()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
    begin
        // acceptance criteria 7 - Certificate of Supply status can be manually changed to Not Received from status Required
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::"Not Received";
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", CertificateOfSupply.Status::"Not Received", SalesShipmentHeader."No.", 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredToReceivedNoRcptDate()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
    begin
        // acceptance criteria 7 - Certificate of Supply status can be manually changed to Received from status Required (Receipt Date blank)
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::Received;
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, SalesShipmentHeader."No.", SalesShipmentHeader."Shipment Date");
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredToReceivedRcptDateDefined()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        RcptDate: Date;
        ExpectedStatus: Option;
    begin
        // acceptance criteria 7 - Certificate of Supply status can be manually changed to Received from status Required (Receipt Date not blank)
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        RcptDate := CalcDate('<+2W>', WorkDate());

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::Received;
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);
        SetCertofSupplyRcptDate(CertificateOfSupply, RcptDate);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, SalesShipmentHeader."No.", RcptDate);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyNotApplicableToRequired()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
    begin
        // acceptance criteria 8 - Certificate of Supply status can be manually changed to Required from status Not Applicable
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, false);
        CertificateOfSupply.InitFromSales(SalesShipmentHeader);

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::Required;
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, SalesShipmentHeader."No.", 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyReceivedToRequired()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
        CertificateNo: Code[20];
    begin
        // acceptance criteria 8 - Certificate of Supply status can be manually changed to Required from status Received
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::Received);
        CertificateNo := LibraryUtility.GenerateGUID();
        SetCertofSupplyNo(CertificateOfSupply, CertificateNo);

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::Required;
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, CertificateNo, 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyReceivedToNotReceived()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
        CertificateNo: Code[20];
    begin
        // acceptance criteria 12 - Certificate of Supply status can be manually changed to Not Received from status Received
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::Received);
        CertificateNo := LibraryUtility.GenerateGUID();
        SetCertofSupplyNo(CertificateOfSupply, CertificateNo);

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::"Not Received";
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, CertificateNo, 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyNotApplicableToNotReceived()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
    begin
        // acceptance criteria 12 - Certificate of Supply status can be manually changed to Not Received from status Not Applicable
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, false);
        CertificateOfSupply.InitFromSales(SalesShipmentHeader);

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::"Not Received";
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, SalesShipmentHeader."No.", 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyReceivedToNotApplicable()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
    begin
        // acceptance criteria 24 - Certificate of Supply status can be manually changed to Not Applicable from status Received
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::Received);

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::"Not Applicable";
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, '', 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyNotReceivedToNotApplicable()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
    begin
        // acceptance criteria 24 - Certificate of Supply status can be manually changed to Not Applicable from status Not Received
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::"Not Received");

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::"Not Applicable";
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, '', 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredToNotApplicable()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
    begin
        // acceptance criteria 24 - Certificate of Supply status can be manually changed to Not Applicable from status Required
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::"Not Applicable";
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, '', 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyNotReceivedToRequired()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
        CertificateNo: Code[20];
    begin
        // acceptance criteria 8 - Certificate of Supply status can be manually changed to Required from status Not Received
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::"Not Received");
        CertificateNo := LibraryUtility.GenerateGUID();
        SetCertofSupplyNo(CertificateOfSupply, CertificateNo);

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::Required;
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, CertificateNo, 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyNotReceivedToReceived()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
        CertificateNo: Code[20];
    begin
        // acceptance criteria 8 - Certificate of Supply status can be manually changed to Received from status Not Received
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::"Not Received");
        CertificateNo := LibraryUtility.GenerateGUID();
        SetCertofSupplyNo(CertificateOfSupply, CertificateNo);

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::Received;
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, CertificateNo, SalesShipmentHeader."Shipment Date");
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyNotApplicableToReceived()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
    begin
        // acceptance criteria 12 - Certificate of Supply status can be manually changed to Received from status Not Applicable
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, false);
        CertificateOfSupply.InitFromSales(SalesShipmentHeader);

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::Received;
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, SalesShipmentHeader."No.", SalesShipmentHeader."Shipment Date");
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyReceivedClearRcptDate()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // acceptance criteria 23 - If user clears Certificate Receipt Date value and the  Certificate of Supply Status is Received then error is thrown
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::Received);

        // exercise & verify
        asserterror SetCertofSupplyRcptDate(CertificateOfSupply, 0D);
        Assert.ExpectedError(DateCannotBeEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredClearCertificateNo()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // acceptance criteria 25 - If user clears Certificate No. value and the  Certificate of Supply Status is Received then error is thrown
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");

        // exercise & verify
        asserterror SetCertofSupplyNo(CertificateOfSupply, '');
        Assert.ExpectedError(NoCannotBeEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyReceivedClearCertificateNo()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // acceptance criteria 25 - If user clears Certificate No.  value and the  Certificate of Supply Status is Received then error is thrown
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::Received);

        // exercise & verify
        asserterror SetCertofSupplyNo(CertificateOfSupply, '');
        Assert.ExpectedError(NoCannotBeEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyReceivedChangeVehicleRegNo()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // acceptance criteria 25 - If user changes Vehicle Reg. No. and the  Certificate of Supply Status is Received then error is thrown
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        SetCertofSupplyVehicleRegNo(CertificateOfSupply,
          LibraryUtility.GenerateRandomCode(CertificateOfSupply.FieldNo("Vehicle Registration No."), DATABASE::"Certificate of Supply"));

        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::Received);

        // exercise & verify
        asserterror CertificateOfSupply.Validate("Vehicle Registration No.", '');
        Assert.ExpectedError(
          StrSubstNo(VehicleRegNoCannotBeChangedErr, CertificateOfSupply.FieldCaption("Vehicle Registration No."),
            CertificateOfSupply.Status::Received));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyNotReceivedClearCertificateNo()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // acceptance criteria 25 - If user clears Certificate No. value and the  Certificate of Supply Status is Received then error is thrown
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::"Not Received");

        // exercise & verify
        asserterror SetCertofSupplyNo(CertificateOfSupply, '');
        Assert.ExpectedError(NoCannotBeEmptyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyReceivedRcptDateBeforeShipmentDateSales()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // acceptance criteria 18 - Certificate Receipt Date must be after Shipment Date
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::Received);

        // exercise & verify
        asserterror SetCertofSupplyRcptDate(CertificateOfSupply,
            CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', SalesShipmentHeader."Shipment Date"));
        Assert.ExpectedError(CertRecDateBeforeShipPostDateMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyReceivedRcptDateBeforeShipmentDateService()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // acceptance criteria 18 - Certificate Receipt Date must be after Shipment Date
        Initialize();

        // setup
        PostServiceDoc(ServiceShipmentHeader, ServiceHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Service Shipment", ServiceShipmentHeader."No.");
        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::Received);

        // exercise & verify
        asserterror SetCertofSupplyRcptDate(CertificateOfSupply,
            CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', ServiceShipmentHeader."Posting Date"));
        Assert.ExpectedError(CertRecDateBeforeShipPostDateMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyReceivedRcptDateBeforeShipmentDatePurchase()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        // acceptance criteria 18 - Certificate Receipt Date must be after Shipment Date
        Initialize();

        // setup
        PostPurchaseDoc(ReturnShipmentHeader, PurchaseHeader."Document Type"::"Return Order", true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Return Shipment", ReturnShipmentHeader."No.");
        SetCertofSupplyStatus(CertificateOfSupply, CertificateOfSupply.Status::Received);

        // exercise & verify
        asserterror SetCertofSupplyRcptDate(CertificateOfSupply,
            CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', ReturnShipmentHeader."Posting Date"));
        Assert.ExpectedError(CertRecDateBeforeShipPostDateMsg);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredToNotReceivedCustomCertificateID()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
        CertificateNo: Code[20];
    begin
        // acceptance criteria 26 - Certificate of Supply status can be manually changed to Not Received from status Required (not-default Certificate No.)
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        CertificateNo := LibraryUtility.GenerateGUID();
        SetCertofSupplyNo(CertificateOfSupply, CertificateNo);

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::"Not Received";
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, CertificateNo, 0D);
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CertofSupplyRequiredToReceivedCustomCertificateID()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ExpectedStatus: Option;
        CertificateNo: Code[20];
    begin
        // acceptance criteria 26 - Certificate of Supply status can be manually changed to Received from status Required (not-default Certificate No.)
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        CertificateNo := LibraryUtility.GenerateGUID();
        SetCertofSupplyNo(CertificateOfSupply, CertificateNo);

        // exercise
        ExpectedStatus := CertificateOfSupply.Status::Received;
        SetCertofSupplyStatus(CertificateOfSupply, ExpectedStatus);

        // verify
        VerifyCertofSupplyProperties(CertificateOfSupply, CertificateOfSupply."Document Type"::"Sales Shipment",
          SalesShipmentHeader."No.", ExpectedStatus, CertificateNo, SalesShipmentHeader."Shipment Date");
        VerifyCertSalesShipmentProperties(CertificateOfSupply, SalesShipmentHeader)
    end;

    [Test]
    [HandlerFunctions('CertofSupplyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CertofSupplyReportValidationSale()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
    begin
        // Test verifies the content of the Certificate of Supply report for Sales Shipment Header as source
        Initialize();

        // setup
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        SetCertofSupplyVehicleRegNo(CertificateOfSupply,
          LibraryUtility.GenerateRandomCode(CertificateOfSupply.FieldNo("Vehicle Registration No."), DATABASE::"Certificate of Supply"));

        // exercise
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document Type");
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document No.");
        LibraryVariableStorage.Enqueue(false);
        CertificateOfSupply.Print();

        // verify
        VerifyReportSalesDoc(CertificateOfSupply, SalesShipmentHeader);
    end;

    [Test]
    [HandlerFunctions('CertofSupplyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CertofSupplyReportValidationSaleMultiline()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesHeader: Record "Sales Header";
    begin
        // Test verifies the content of the Certificate of Supply report for Sales Shipment Header as source for multiline document
        Initialize();

        // setup
        PostMultilineSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");

        // exercise
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document Type");
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document No.");
        LibraryVariableStorage.Enqueue(true);
        CertificateOfSupply.Print();

        // verify
        VerifyMultilineReportSalesDoc(CertificateOfSupply, SalesShipmentHeader);
    end;

    [Test]
    [HandlerFunctions('ServCertofSupplyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CertofSupplyReportValidationService()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceHeader: Record "Service Header";
    begin
        // Test verifies the content of the Certificate of Supply report for Service Shipment Header as source
        Initialize();

        // setup
        PostServiceDoc(ServiceShipmentHeader, ServiceHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Service Shipment", ServiceShipmentHeader."No.");
        SetCertofSupplyVehicleRegNo(CertificateOfSupply,
          LibraryUtility.GenerateRandomCode(CertificateOfSupply.FieldNo("Vehicle Registration No."), DATABASE::"Certificate of Supply"));

        // exercise
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document Type");
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document No.");
        LibraryVariableStorage.Enqueue(false);
        CertificateOfSupply.Print();

        // verify
        VerifyReportServiceDoc(CertificateOfSupply, ServiceShipmentHeader);
    end;

    [Test]
    [HandlerFunctions('ServCertofSupplyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CertofSupplyReportValidationServiceMultiline()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceHeader: Record "Service Header";
    begin
        // Test verifies the content of the Certificate of Supply report for Service Shipment Header as source for multiline document
        Initialize();

        // setup
        PostMultilineServiceDoc(ServiceShipmentHeader, ServiceHeader."Document Type"::Order, true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Service Shipment", ServiceShipmentHeader."No.");

        // exercise
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document Type");
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document No.");
        LibraryVariableStorage.Enqueue(true);
        CertificateOfSupply.Print();

        // verify
        VerifyMultilineReportServiceDoc(CertificateOfSupply, ServiceShipmentHeader);
    end;

    [Test]
    [HandlerFunctions('CertofSupplyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CertofSupplyReportValidationPurchase()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test verifies the content of the Certificate of Supply report for Return Shipment Header as source
        Initialize();

        // setup
        PostPurchaseDoc(ReturnShipmentHeader, PurchaseHeader."Document Type"::"Return Order", true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Return Shipment", ReturnShipmentHeader."No.");
        SetCertofSupplyVehicleRegNo(CertificateOfSupply,
          LibraryUtility.GenerateRandomCode(CertificateOfSupply.FieldNo("Vehicle Registration No."), DATABASE::"Certificate of Supply"));

        // exercise
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document Type");
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document No.");
        LibraryVariableStorage.Enqueue(false);
        CertificateOfSupply.Print();

        // verify
        VerifyReportReturnShipmentDoc(CertificateOfSupply, ReturnShipmentHeader);
    end;

    [Test]
    [HandlerFunctions('CertofSupplyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CertofSupplyReportValidationPurchaseMultiline()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test verifies the content of the Certificate of Supply report for Return Shipment Header as source
        Initialize();

        // setup
        PostMultilinePurchaseDoc(ReturnShipmentHeader, PurchaseHeader."Document Type"::"Return Order", true);
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Return Shipment", ReturnShipmentHeader."No.");

        // exercise
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document Type");
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document No.");
        LibraryVariableStorage.Enqueue(true);
        CertificateOfSupply.Print();

        // verify
        VerifyMultilineReportReturnShipmentDoc(CertificateOfSupply, ReturnShipmentHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesShpmntWithCertOfSupply()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentNo: Code[20];
    begin
        // acceptance criteria 27 - Delete Sales/Service/Return Shipment must delete associated Certificate of Supply

        // setup
        Initialize();

        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);
        SalesShipmentNo := SalesShipmentHeader."No.";

        SalesShipmentHeader.Validate("No. Printed", LibraryRandom.RandInt(10));
        SalesShipmentHeader.Modify(true);

        // [GIVEN] "Sales Setup"."Allow Document Deletion Before"
        LibrarySales.SetAllowDocumentDeletionBeforeDate(SalesShipmentHeader."Posting Date" + 1);

        // exercise
        SalesShipmentHeader.Delete(true);

        // verify
        asserterror CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentNo);
        Assert.ExpectedErrorCannotFind(Database::"Certificate of Supply");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteServiceShpmntWithCertOfSupply()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        ServiceHeader: Record "Service Header";
        ServiceShipmentHeader: Record "Service Shipment Header";
        ServiceShipmentNo: Code[20];
    begin
        // acceptance criteria 27 - Delete Sales/Service/Return Shipment must delete associated Certificate of Supply

        // setup
        Initialize();

        PostServiceDoc(ServiceShipmentHeader, ServiceHeader."Document Type"::Order, true);
        ServiceShipmentNo := ServiceShipmentHeader."No.";

        ServiceShipmentHeader.Validate("No. Printed", LibraryRandom.RandInt(10));
        ServiceShipmentHeader.Modify(true);

        // exercise
        ServiceShipmentHeader.Delete(true);

        // verify
        asserterror CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Service Shipment", ServiceShipmentNo);
        Assert.ExpectedErrorCannotFind(Database::"Certificate of Supply");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteReturnShpmntWithCertOfSupply()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ReturnShipmentNo: Code[20];
    begin
        // acceptance criteria 27 - Delete Sales/Service/Return Shipment must delete associated Certificate of Supply

        // setup
        Initialize();

        PostPurchaseDoc(ReturnShipmentHeader, PurchaseHeader."Document Type"::"Return Order", true);
        ReturnShipmentNo := ReturnShipmentHeader."No.";

        ReturnShipmentHeader.Validate("No. Printed", LibraryRandom.RandInt(10));
        ReturnShipmentHeader.Modify(true);

        // [GIVEN] "Sales Setup"."Allow Document Deletion Before"
        LibraryPurchase.SetAllowDocumentDeletionBeforeDate(ReturnShipmentHeader."Posting Date" + 1);

        // exercise
        ReturnShipmentHeader.Delete(true);

        // verify
        asserterror CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Return Shipment", ReturnShipmentNo);
        Assert.ExpectedErrorCannotFind(Database::"Certificate of Supply");
    end;

    [Test]
    [HandlerFunctions('CertofSupplySaveAsPDFRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintCertificateOfSupply()
    var
        CertificateOfSupply: Record "Certificate of Supply";
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // [SCENARIO 333888] Report "Certificate of Supply" can be printed without errors
        Initialize();

        // [GIVEN] Prepare Certificate of Supply
        PostSalesDoc(SalesShipmentHeader, SalesHeader."Document Type"::Order, true);

        // [WHEN] Report Certificate of Supply is being printed to PDF
        CertificateOfSupply.Get(CertificateOfSupply."Document Type"::"Sales Shipment", SalesShipmentHeader."No.");
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document Type");
        LibraryVariableStorage.Enqueue(CertificateOfSupply."Document No.");
        LibraryVariableStorage.Enqueue(false);
        report.Run(Report::"Certificate of Supply");

        // [THEN] No RDLC error
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Certificate Of Supply");
        LibraryVariableStorage.Clear();
    end;

    local procedure AddSalesLine(var SalesHeader: Record "Sales Header"; CertOfSupplyRequired: Boolean)
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        Customer: Record Customer;
        ItemNo: Code[20];
    begin
        Customer.Get(SalesHeader."Bill-to Customer No.");
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group", VATProdPostingGroup.Code);
        SetCertofSupplyRequired(VATPostingSetup, CertOfSupplyRequired);

        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
    end;

    local procedure AddServiceLine(var ServiceHeader: Record "Service Header"; CertOfSupplyRequired: Boolean)
    var
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        Customer: Record Customer;
        ItemNo: Code[20];
    begin
        Customer.Get(ServiceHeader."Bill-to Customer No.");
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group", VATProdPostingGroup.Code);
        SetCertofSupplyRequired(VATPostingSetup, CertOfSupplyRequired);

        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetFilter("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst();

        CreateServiceLine(ServiceLine, ServiceHeader, ItemNo, ServiceItemLine."Line No.");
    end;

    local procedure AddPurchaseLine(var PurchaseHeader: Record "Purchase Header"; CertOfSupplyRequired: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        Vendor: Record Vendor;
        ItemNo: Code[20];
    begin
        Vendor.Get(PurchaseHeader."Pay-to Vendor No.");
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group", VATProdPostingGroup.Code);
        SetCertofSupplyRequired(VATPostingSetup, CertOfSupplyRequired);

        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
    end;

    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; DocType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);

        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchasing(var Purchasing: Record Purchasing)
    begin
        Purchasing.Init();
        Purchasing.Validate(Code, LibraryUtility.GenerateRandomText(10));
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Insert();
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; DocType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);

        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        LibrarySales.CreateSalesHeader(SalesHeader, DocType, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; VATPostingSetup: Record "VAT Posting Setup"; DocType: Enum "Service Document Type")
    var
        Customer: Record Customer;
        ServiceLine: Record "Service Line";
        ServiceItemLine: Record "Service Item Line";
        ItemNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);

        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");

        LibraryService.CreateServiceHeader(ServiceHeader, DocType, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, '');
        CreateServiceLine(ServiceLine, ServiceHeader, ItemNo, ServiceItemLine."Line No.");
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; No: Code[20]; ServiceItemLineNo: Integer)
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, No);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLineNo);
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(50));
        ServiceLine.Modify(true);
    end;

    local procedure CreateVATPostingGroup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProdPostingGroup.Code);
    end;

    local procedure PostMultilinePurchaseDoc(var ReturnShipmentHeader: Record "Return Shipment Header"; DocumentType: Enum "Purchase Document Type"; CertOfSupplyRequired: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateVATPostingGroup(VATPostingSetup);
        SetCertofSupplyRequired(VATPostingSetup, CertOfSupplyRequired);
        CreatePurchaseOrder(PurchaseHeader, VATPostingSetup, DocumentType);
        AddPurchaseLine(PurchaseHeader, not CertOfSupplyRequired);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ReturnShipmentHeader.SetRange("Return Order No.", PurchaseHeader."No.");
        ReturnShipmentHeader.FindFirst();
    end;

    local procedure PostMultilineSalesDoc(var SalesShipmentHeader: Record "Sales Shipment Header"; DocumentType: Enum "Sales Document Type"; CertOfSupplyRequired: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        CreateVATPostingGroup(VATPostingSetup);
        SetCertofSupplyRequired(VATPostingSetup, CertOfSupplyRequired);
        CreateSalesOrder(SalesHeader, VATPostingSetup, DocumentType);
        AddSalesLine(SalesHeader, not CertOfSupplyRequired);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
    end;

    local procedure PostMultilineServiceDoc(var ServiceShipmentHeader: Record "Service Shipment Header"; DocumentType: Enum "Service Document Type"; CertOfSupplyRequired: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
    begin
        CreateVATPostingGroup(VATPostingSetup);
        SetCertofSupplyRequired(VATPostingSetup, CertOfSupplyRequired);
        CreateServiceOrder(ServiceHeader, VATPostingSetup, DocumentType);
        AddServiceLine(ServiceHeader, not CertOfSupplyRequired);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();
    end;

    local procedure PostPurchaseDoc(var ReturnShipmentHeader: Record "Return Shipment Header"; DocumentType: Enum "Purchase Document Type"; CertOfSupplyRequired: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        CreateVATPostingGroup(VATPostingSetup);
        SetCertofSupplyRequired(VATPostingSetup, CertOfSupplyRequired);
        CreatePurchaseOrder(PurchaseHeader, VATPostingSetup, DocumentType);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        ReturnShipmentHeader.SetRange("Return Order No.", PurchaseHeader."No.");
        ReturnShipmentHeader.FindFirst();
    end;

    local procedure PostSalesDoc(var SalesShipmentHeader: Record "Sales Shipment Header"; DocumentType: Enum "Sales Document Type"; CertOfSupplyRequired: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        CreateVATPostingGroup(VATPostingSetup);
        SetCertofSupplyRequired(VATPostingSetup, CertOfSupplyRequired);
        CreateSalesOrder(SalesHeader, VATPostingSetup, DocumentType);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
    end;

    local procedure PostServiceDoc(var ServiceShipmentHeader: Record "Service Shipment Header"; DocumentType: Enum "Service Document Type"; CertOfSupplyRequired: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceHeader: Record "Service Header";
    begin
        CreateVATPostingGroup(VATPostingSetup);
        SetCertofSupplyRequired(VATPostingSetup, CertOfSupplyRequired);
        CreateServiceOrder(ServiceHeader, VATPostingSetup, DocumentType);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        ServiceShipmentHeader.SetRange("Order No.", ServiceHeader."No.");
        ServiceShipmentHeader.FindFirst();
    end;

    local procedure ReleaseSalesOrderDropShipment(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; PurchasingCode: Code[10])
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        Vendor: Record Vendor;
        ItemNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        ItemNo := CreateItem(VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);

        RunGetSalesOrders(RequisitionLine, SalesHeader);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        RequisitionLine.Validate("Vendor No.", Vendor."No.");
        RequisitionLine.Modify(true);

        ReqWkshCarryOutActionMessage(RequisitionLine);

        PurchaseHeader.SetRange("Buy-from Vendor No.", Vendor."No.");
        PurchaseHeader.FindFirst();

        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;

    local procedure SetCertofSupplyNo(var CertificateOfSupply: Record "Certificate of Supply"; No: Code[20])
    begin
        CertificateOfSupply.Validate("No.", No);
        CertificateOfSupply.Modify(true)
    end;

    local procedure SetCertofSupplyStatus(var CertificateOfSupply: Record "Certificate of Supply"; NewStatus: Option)
    begin
        CertificateOfSupply.Validate(Status, NewStatus);
        CertificateOfSupply.Modify(true)
    end;

    local procedure SetCertofSupplyRcptDate(var CertificateOfSupply: Record "Certificate of Supply"; NewDate: Date)
    begin
        CertificateOfSupply.Validate("Receipt Date", NewDate);
        CertificateOfSupply.Modify(true)
    end;

    local procedure SetCertofSupplyRequired(var VATPostingSetup: Record "VAT Posting Setup"; CertofSupplyRequired: Boolean)
    begin
        VATPostingSetup.Validate("Certificate of Supply Required", CertofSupplyRequired);
        VATPostingSetup.Modify(true);
    end;

    local procedure SetCertofSupplyVehicleRegNo(var CertificateOfSupply: Record "Certificate of Supply"; VehicleRegNo: Code[20])
    begin
        CertificateOfSupply.Validate("Vehicle Registration No.", VehicleRegNo);
        CertificateOfSupply.Modify(true);
        Commit();
    end;

    local procedure VerifyCertofSupplyProperties(CertificateOfSupply: Record "Certificate of Supply"; DocType: Enum "Supply Document Type"; DocNo: Code[20]; Status: Option; No: Code[20]; RcptDate: Date)
    begin
        CertificateOfSupply.TestField("Document Type", DocType);
        CertificateOfSupply.TestField("Document No.", DocNo);
        CertificateOfSupply.TestField(Status, Status);
        CertificateOfSupply.TestField("Receipt Date", RcptDate);
        CertificateOfSupply.TestField("No.", No);
    end;

    local procedure VerifyCertSalesShipmentProperties(CertificateOfSupply: Record "Certificate of Supply"; SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        CertificateOfSupply.TestField("Customer/Vendor Name", SalesShipmentHeader."Bill-to Name");
        CertificateOfSupply.TestField("Shipment Method Code", SalesShipmentHeader."Shipment Method Code");
        CertificateOfSupply.TestField("Shipment/Posting Date", SalesShipmentHeader."Shipment Date");
        CertificateOfSupply.TestField("Ship-to Country/Region Code", SalesShipmentHeader."Bill-to Country/Region Code");
        CertificateOfSupply.TestField("Customer/Vendor Name", SalesShipmentHeader."Bill-to Customer No.");
    end;

    local procedure VerifyCertServiceShipmentProperties(CertificateOfSupply: Record "Certificate of Supply"; ServiceShipmentHeader: Record "Service Shipment Header")
    begin
        CertificateOfSupply.TestField("Customer/Vendor Name", ServiceShipmentHeader."Bill-to Name");
        CertificateOfSupply.TestField("Shipment Method Code", '');
        CertificateOfSupply.TestField("Shipment/Posting Date", ServiceShipmentHeader."Posting Date");
        CertificateOfSupply.TestField("Ship-to Country/Region Code", ServiceShipmentHeader."Bill-to Country/Region Code");
        CertificateOfSupply.TestField("Customer/Vendor Name", ServiceShipmentHeader."Bill-to Customer No.");
    end;

    local procedure VerifyCertReturnShipmentProperties(CertificateOfSupply: Record "Certificate of Supply"; ReturnShipmentHeader: Record "Return Shipment Header")
    begin
        CertificateOfSupply.TestField("Customer/Vendor Name", ReturnShipmentHeader."Buy-from Vendor No.");
        CertificateOfSupply.TestField("Shipment Method Code", ReturnShipmentHeader."Shipment Method Code");
        CertificateOfSupply.TestField("Shipment/Posting Date", ReturnShipmentHeader."Posting Date");
        CertificateOfSupply.TestField("Ship-to Country/Region Code", ReturnShipmentHeader."Ship-to Country/Region Code");
        CertificateOfSupply.TestField("Customer/Vendor Name", ReturnShipmentHeader."Buy-from Vendor No.");
    end;

    [Normal]
    local procedure VerifyMultilineReportSalesDoc(CertificateOfSupply: Record "Certificate of Supply"; SalesShipmentHeader: Record "Sales Shipment Header")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        VerifyReportCommon(CertificateOfSupply);
        LibraryReportDataset.AssertElementWithValueExists('PrintLineDetails', true);
        SalesShipmentLine.SetFilter("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.FindSet();
        repeat
            VerifyReportLine(SalesShipmentLine."No.", SalesShipmentLine.Description, SalesShipmentLine.Quantity, SalesShipmentLine."Unit of Measure Code");
        until SalesShipmentLine.Next() = 0;
    end;

    local procedure VerifyMultilineReportServiceDoc(CertificateOfSupply: Record "Certificate of Supply"; ServiceShipmentHeader: Record "Service Shipment Header")
    var
        ServiceShipmentLine: Record "Service Shipment Line";
    begin
        VerifyReportCommon(CertificateOfSupply);
        LibraryReportDataset.AssertElementWithValueExists('PrintLineDetails', true);
        ServiceShipmentLine.SetFilter("Document No.", ServiceShipmentHeader."No.");
        ServiceShipmentLine.FindSet();
        repeat
            VerifyReportLine(ServiceShipmentLine."No.", ServiceShipmentLine.Description, ServiceShipmentLine.Quantity, ServiceShipmentLine."Unit of Measure Code");
        until ServiceShipmentLine.Next() = 0;
    end;

    local procedure VerifyMultilineReportReturnShipmentDoc(CertificateOfSupply: Record "Certificate of Supply"; ReturnShipmentHeader: Record "Return Shipment Header")
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        VerifyReportCommon(CertificateOfSupply);
        LibraryReportDataset.AssertElementWithValueExists('PrintLineDetails', true);
        ReturnShipmentLine.SetFilter("Document No.", ReturnShipmentHeader."No.");
        ReturnShipmentLine.FindSet();
        repeat
            VerifyReportLine(ReturnShipmentLine."No.", ReturnShipmentLine.Description, ReturnShipmentLine.Quantity, ReturnShipmentLine."Unit of Measure Code");
        until ReturnShipmentLine.Next() = 0;
    end;

    local procedure VerifyReportCommon(CertificateOfSupply: Record "Certificate of Supply")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No', CertificateOfSupply."Document No.");
        LibraryReportDataset.AssertElementWithValueExists('FORMAT_TODAY_0_4_', Format(Today, 0, 4));
        LibraryReportDataset.AssertElementWithValueExists('Shipment_Method_Code', CertificateOfSupply."Shipment Method Code");
        LibraryReportDataset.AssertElementWithValueExists('Vehicle_Registration_No', CertificateOfSupply."Vehicle Registration No.");
    end;

    local procedure VerifyReportLine(ItemNo: Code[20]; Description: Text[100]; Quantity: Decimal; UnitOfMeasureCode: Code[10])
    begin
        LibraryReportDataset.AssertElementWithValueExists('Item_No', ItemNo);
        LibraryReportDataset.AssertElementWithValueExists('Description', Description);
        LibraryReportDataset.AssertElementWithValueExists('Quantity', Quantity);
        LibraryReportDataset.AssertElementWithValueExists('Unit_of_Measure', UnitOfMeasureCode);
    end;

    local procedure VerifyReportSalesDoc(CertificateOfSupply: Record "Certificate of Supply"; SalesShipmentHeader: Record "Sales Shipment Header")
    begin
        VerifyReportCommon(CertificateOfSupply);
        LibraryReportDataset.AssertElementWithValueExists('PrintLineDetails', false);
        LibraryReportDataset.AssertElementWithValueExists('Bill_to_Name', SalesShipmentHeader."Bill-to Name");
        LibraryReportDataset.AssertElementWithValueExists('Bill_to_Address', SalesShipmentHeader."Bill-to Address");
        LibraryReportDataset.AssertElementWithValueExists('Bill_to_Address2', SalesShipmentHeader."Bill-to Address 2");
        LibraryReportDataset.AssertElementWithValueExists('Bill_to_City', SalesShipmentHeader."Bill-to City");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_Name', SalesShipmentHeader."Ship-to Name");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_Address', SalesShipmentHeader."Ship-to Address");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_Address2', SalesShipmentHeader."Ship-to Address 2");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_City', SalesShipmentHeader."Ship-to City");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_Country_Region_Code', SalesShipmentHeader."Ship-to Code");
    end;

    local procedure VerifyReportServiceDoc(CertificateOfSupply: Record "Certificate of Supply"; ServiceShipmentHeader: Record "Service Shipment Header")
    begin
        VerifyReportCommon(CertificateOfSupply);
        LibraryReportDataset.AssertElementWithValueExists('PrintLineDetails', false);
        LibraryReportDataset.AssertElementWithValueExists('Bill_to_Name', ServiceShipmentHeader."Bill-to Name");
        LibraryReportDataset.AssertElementWithValueExists('Bill_to_Address', ServiceShipmentHeader."Bill-to Address");
        LibraryReportDataset.AssertElementWithValueExists('Bill_to_Address2', ServiceShipmentHeader."Bill-to Address 2");
        LibraryReportDataset.AssertElementWithValueExists('Bill_to_City', ServiceShipmentHeader."Bill-to City");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_Name', ServiceShipmentHeader."Ship-to Name");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_Address', ServiceShipmentHeader."Ship-to Address");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_Address2', ServiceShipmentHeader."Ship-to Address 2");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_City', ServiceShipmentHeader."Ship-to City");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_Country_Region_Code', ServiceShipmentHeader."Ship-to Code");
    end;

    local procedure VerifyReportReturnShipmentDoc(CertificateOfSupply: Record "Certificate of Supply"; ReturnShipmentHeader: Record "Return Shipment Header")
    begin
        VerifyReportCommon(CertificateOfSupply);
        LibraryReportDataset.AssertElementWithValueExists('PrintLineDetails', false);
        LibraryReportDataset.AssertElementWithValueExists('Bill_to_Name', ReturnShipmentHeader."Pay-to Name");
        LibraryReportDataset.AssertElementWithValueExists('Bill_to_Address', ReturnShipmentHeader."Pay-to Address");
        LibraryReportDataset.AssertElementWithValueExists('Bill_to_Address2', ReturnShipmentHeader."Pay-to Address 2");
        LibraryReportDataset.AssertElementWithValueExists('Bill_to_City', ReturnShipmentHeader."Pay-to City");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_Name', ReturnShipmentHeader."Ship-to Name");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_Address', ReturnShipmentHeader."Ship-to Address");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_Address2', ReturnShipmentHeader."Ship-to Address 2");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_City', ReturnShipmentHeader."Ship-to City");
        LibraryReportDataset.AssertElementWithValueExists('Ship_to_Country_Region_Code', ReturnShipmentHeader."Ship-to Code");
    end;

    local procedure RunGetSalesOrders(var RequisitionLine: Record "Requisition Line"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        GetSalesOrders: Report "Get Sales Orders";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshName: Record "Requisition Wksh. Name";
        LibraryPlanning: Codeunit "Library - Planning";
        RetrieveDimensions: Option "Sales Line",Item;
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshName."Template Type"::"Req.");
        ReqWkshTemplate.FindFirst();

        LibraryPlanning.CreateRequisitionWkshName(ReqWkshName, ReqWkshTemplate.Name);
        RequisitionLine.Init();
        RequisitionLine.Validate("Worksheet Template Name", ReqWkshName."Worksheet Template Name");
        RequisitionLine.Validate("Journal Batch Name", ReqWkshName.Name);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        Clear(GetSalesOrders);
        GetSalesOrders.SetTableView(SalesLine);
        GetSalesOrders.InitializeRequest(RetrieveDimensions::"Sales Line");
        GetSalesOrders.SetReqWkshLine(RequisitionLine, 0);
        GetSalesOrders.UseRequestPage(false);
        GetSalesOrders.Run();

        RequisitionLine.SetRange("Journal Batch Name", ReqWkshName.Name);
        RequisitionLine.FindFirst();
    end;

    local procedure ReqWkshCarryOutActionMessage(var RequisitionLine: Record "Requisition Line")
    var
        CarryOutActionMessage: Report "Carry Out Action Msg. - Req.";
    begin
        Commit();
        CarryOutActionMessage.SetReqWkshLine(RequisitionLine);
        CarryOutActionMessage.SetHideDialog(true);

        CarryOutActionMessage.UseRequestPage(false);
        CarryOutActionMessage.RunModal();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CertofSupplyRequestPageHandler(var CertOfSupply: TestRequestPage "Certificate of Supply")
    var
        DocumentType: Variant;
        DocumentNo: Variant;
        PrintLineDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(PrintLineDetails);
        CertOfSupply.CertificateOfSupply.SetFilter("Document Type", Format(DocumentType));
        CertOfSupply.CertificateOfSupply.SetFilter("Document No.", DocumentNo);
        CertOfSupply.PrintLineDetails.SetValue(PrintLineDetails);
        CertOfSupply.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServCertofSupplyRequestPageHandler(var CertOfSupply: TestRequestPage "Service Certificate of Supply")
    var
        DocumentType: Variant;
        DocumentNo: Variant;
        PrintLineDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(PrintLineDetails);
        CertOfSupply.CertificateOfSupply.SetFilter("Document Type", Format(DocumentType));
        CertOfSupply.CertificateOfSupply.SetFilter("Document No.", DocumentNo);
        CertOfSupply.PrintLineDetails.SetValue(PrintLineDetails);
        CertOfSupply.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CertofSupplySaveAsPDFRequestPageHandler(var CertOfSupply: TestRequestPage "Certificate of Supply")
    var
        FileManagement: Codeunit "File Management";
        DocumentType: Variant;
        DocumentNo: Variant;
        PrintLineDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentType);
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(PrintLineDetails);
        CertOfSupply.CertificateOfSupply.SetFilter("Document Type", Format(DocumentType));
        CertOfSupply.CertificateOfSupply.SetFilter("Document No.", DocumentNo);
        CertOfSupply.PrintLineDetails.SetValue(PrintLineDetails);
        CertOfSupply.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('CertificatesOfSupplyPageHandler')]
    procedure CheckOpeningEmptyCertificateOfSupplyListWithDocumentTypeFilter()
    var
        CertificateOfSupply: Record "Certificate of Supply";
    begin
        // [SCENARIO 463274] Opening empty 'Certificates of Supply' page with saved filters should not cause a error 
        // [FEATURE] [Certificate of Supply] [Supply] [Shipment]
        Initialize();

        // [GIVEN] //there is no entries in "Certificate of Supply" table
        if not CertificateOfSupply.IsEmpty then
            CertificateOfSupply.DeleteAll();

        // [WHEN] // "Document Type" filter is set on record and assigned to a page
        CertificateOfSupply.SetRange("Document Type", LibraryRandom.RandInt(3) - 1);

        // [THEN] // opening page should not cause a error
        Page.Run(Page::"Certificates of Supply", CertificateOfSupply);
    end;

    [PageHandler]
    procedure CertificatesOfSupplyPageHandler(var CertificatesOfSupply: TestPage "Certificates of Supply")
    begin
    end;
}

