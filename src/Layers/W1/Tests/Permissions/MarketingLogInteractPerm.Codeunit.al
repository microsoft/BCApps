codeunit 136218 "Marketing Log Interact. Perm."
{
    Subtype = Test;
    TestPermissions = Restrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Marketing] [Interaction] [Permissions]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        InteractionTemplateErr: Label 'Wrong Interaction Template Code';

    [Test]
    [Scope('OnPrem')]
    procedure FindInteractionTemplateWithBasicISVPerm()
    var
        SegManagement: Codeunit SegManagement;
        InteractionTemplateCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Find Interaction Template Code under Basic ISV permission set
        Initialize();

        // [GIVEN] "Sales Invoices" Interaction Template Setup code is filled in
        UpdateSalesInvoicesInteractionTemplateSetupCode();
        // [GIVEN] Basic ISV permission set
        LibraryLowerPermissions.SetO365BasicISV();
        // [WHEN] Find Interaction Template Setup Code for "Sales Invoice" document
        InteractionTemplateCode := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Sales Inv.");
        // [THEN] Empty template code is returned
        Assert.AreEqual('', InteractionTemplateCode, InteractionTemplateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FindInteractionTemplateWithBasicPerm()
    var
        SegManagement: Codeunit SegManagement;
        InteractionTemplateCode: Code[10];
        SalesInvoicesInteractionTemplateCode: Code[10];
    begin
        // [FEATURE] [UT]
        // [SCENARIO] Find Interaction Template Code under Basic permission set
        Initialize();

        // [GIVEN] "Sales Invoices" Interaction Template Setup code is filled in
        SalesInvoicesInteractionTemplateCode := UpdateSalesInvoicesInteractionTemplateSetupCode();
        // [GIVEN] Basic permission set
        LibraryLowerPermissions.SetO365Basic();
        // [WHEN] Find Interaction Template Setup Code for "Sales Invoice" document
        InteractionTemplateCode := SegManagement.FindInteractionTemplateCode("Interaction Log Entry Document Type"::"Sales Inv.");
        // [THEN] SalesInvoicesInteractionTemplateCode is returned
        Assert.AreEqual(InteractionTemplateCode, SalesInvoicesInteractionTemplateCode, InteractionTemplateErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(codeunit::"Marketing Log Interact. Perm.");

        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(codeunit::"Marketing Log Interact. Perm.");

        LibrarySetupStorage.Save(DATABASE::"Interaction Template Setup");
        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(codeunit::"Marketing Log Interact. Perm.");
    end;

    local procedure UpdateSalesInvoicesInteractionTemplateSetupCode(): Code[10]
    var
        InteractionTemplateSetup: Record "Interaction Template Setup";
    begin
        InteractionTemplateSetup.Get();
        InteractionTemplateSetup."Sales Invoices" :=
          CopyStr(
            LibraryRandom.RandText(MaxStrLen(InteractionTemplateSetup."Sales Invoices")),
            1, MaxStrLen(InteractionTemplateSetup."Sales Invoices"));
        InteractionTemplateSetup.Modify();
        exit(InteractionTemplateSetup."Sales Invoices");
    end;
}

