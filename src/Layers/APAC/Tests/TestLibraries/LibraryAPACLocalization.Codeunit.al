codeunit 140001 "Library - APAC Localization"
{

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";

    [Scope('OnPrem')]
    procedure CreateBASCalculationSheet(var BASCalculationSheet: Record "BAS Calculation Sheet")
    var
        RecRef: RecordRef;
    begin
        BASCalculationSheet.Init();
        RecRef.GetTable(BASCalculationSheet);
        BASCalculationSheet.Validate("BAS Version", LibraryUtility.GetNewLineNo(RecRef, BASCalculationSheet.FieldNo("BAS Version")));
        BASCalculationSheet.A1 :=
          LibraryUtility.GenerateRandomCode(BASCalculationSheet.FieldNo(A1), DATABASE::"BAS Calculation Sheet");
        BASCalculationSheet.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateBASSetup(var BASSetup: Record "BAS Setup"; SetupName: Code[20])
    var
        RecRef: RecordRef;
    begin
        BASSetup.Init();
        BASSetup.Validate("Setup Name", SetupName);
        RecRef.GetTable(BASSetup);
        BASSetup.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, BASSetup.FieldNo("Line No.")));
        BASSetup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateBASSetupName(var BASSetupName: Record "BAS Setup Name")
    begin
        BASSetupName.Init();
        BASSetupName.Validate(Name, LibraryUtility.GenerateRandomCode(BASSetupName.FieldNo(Name), DATABASE::"BAS Setup Name"));
        BASSetupName.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreatePostDatedCheckLine(var PostDatedCheckLine: Record "Post Dated Check Line"; AccountNo: Code[20]; AccountType: Option; BatchName: Code[10]; TemplateName: Code[10])
    var
        RecRef: RecordRef;
    begin
        PostDatedCheckLine.Init();
        PostDatedCheckLine.Validate("Account No.", AccountNo);
        PostDatedCheckLine.Validate("Account Type", AccountType);
        PostDatedCheckLine.Validate("Batch Name", BatchName);
        RecRef.GetTable(PostDatedCheckLine);
        PostDatedCheckLine.Validate("Line Number", LibraryUtility.GetNewLineNo(RecRef, PostDatedCheckLine.FieldNo("Line Number")));
        PostDatedCheckLine.Validate("Template Name", TemplateName);
        PostDatedCheckLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateWHTBusinessPostingGroup(var WHTBusinessPostingGroup: Record "WHT Business Posting Group")
    begin
        WHTBusinessPostingGroup.Init();
        WHTBusinessPostingGroup.Validate(
          Code, LibraryUtility.GenerateRandomCode(WHTBusinessPostingGroup.FieldNo(Code), DATABASE::"WHT Business Posting Group"));
        WHTBusinessPostingGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateWHTProductPostingGroup(var WHTProductPostingGroup: Record "WHT Product Posting Group")
    begin
        WHTProductPostingGroup.Init();
        WHTProductPostingGroup.Validate(
          Code, LibraryUtility.GenerateRandomCode(WHTProductPostingGroup.FieldNo(Code), DATABASE::"WHT Product Posting Group"));
        WHTProductPostingGroup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateWHTPostingSetup(var WHTPostingSetup: Record "WHT Posting Setup"; WHTBusinessPostingGroup: Code[20]; WHTProductPostingGroup: Code[20])
    begin
        WHTPostingSetup.Init();
        WHTPostingSetup.Validate("WHT Business Posting Group", WHTBusinessPostingGroup);
        WHTPostingSetup.Validate("WHT Product Posting Group", WHTProductPostingGroup);
        WHTPostingSetup.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateWHTRevenueTypes(var WHTRevenueTypes: Record "WHT Revenue Types")
    begin
        WHTRevenueTypes.Init();
        WHTRevenueTypes.Validate(
          Code, LibraryUtility.GenerateRandomCode(WHTRevenueTypes.FieldNo(Code), DATABASE::"WHT Revenue Types"));
        WHTRevenueTypes.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateWHTPostingSetupWithPayableGLAccounts(var WHTPostingSetup: Record "WHT Posting Setup")
    var
        WHTBusinessPostingGroup: Record "WHT Business Posting Group";
        WHTProductPostingGroup: Record "WHT Product Posting Group";
        WHTRevenueTypes: Record "WHT Revenue Types";
    begin
        CreateWHTBusinessPostingGroup(WHTBusinessPostingGroup);
        CreateWHTProductPostingGroup(WHTProductPostingGroup);
        CreateWHTPostingSetup(WHTPostingSetup, WHTBusinessPostingGroup.Code, WHTProductPostingGroup.Code);
        CreateWHTRevenueTypes(WHTRevenueTypes);

        WHTPostingSetup.Validate("WHT Calculation Rule", WHTPostingSetup."WHT Calculation Rule"::"Less than");
        WHTPostingSetup.Validate("WHT Minimum Invoice Amount", 0);
        WHTPostingSetup.Validate("WHT %", LibraryRandom.RandDec(100, 2));
        WHTPostingSetup.Validate("Realized WHT Type", WHTPostingSetup."Realized WHT Type"::Payment);
        WHTPostingSetup.Validate("Payable WHT Account Code", LibraryERM.CreateGLAccountNo());
        WHTPostingSetup.Validate("Bal. Payable Account Type", WHTPostingSetup."Bal. Payable Account Type"::"G/L Account");
        WHTPostingSetup.Validate("Bal. Payable Account No.", LibraryERM.CreateGLAccountNo());
        WHTPostingSetup.Validate("Purch. WHT Adj. Account No.", LibraryERM.CreateGLAccountNo());
        WHTPostingSetup.Validate("Revenue Type", WHTRevenueTypes.Code);
        WHTPostingSetup.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateVendorWithBusPostingGroups(GenBusPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20]; WHTBusPostingGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(LibraryPurchase.CreateVendorWithBusPostingGroups(GenBusPostingGroupCode, VATBusPostingGroupCode));
        Vendor."WHT Business Posting Group" := WHTBusPostingGroupCode;
        Vendor.Modify();
        exit(Vendor."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateItemNoWithPostingSetup(GenProdPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]; WHTProdPostingGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(LibraryInventory.CreateItemNoWithPostingSetup(GenProdPostingGroupCode, VATProdPostingGroupCode));
        Item."WHT Product Posting Group" := WHTProdPostingGroupCode;
        Item.Modify();
        exit(Item."No.");
    end;

    [Scope('OnPrem')]
    procedure UpdatePurchasesPayablesSetup(GSTProdPostingGroup: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("GST Prod. Posting Group", GSTProdPostingGroup);
        PurchasesPayablesSetup.Modify(true);
    end;
}

