codeunit 130030 "License Mgt. Limited User"
{

    trigger OnRun()
    begin
        ReduceDemoData();
    end;

    var
        SetupDataCreatedSuccessfullyMsg: Label 'The setup data for Limited-User license testing was created successfully.';
        LimitedUserCreatedSuccessfullyMsg: Label 'The current user %1 was created successfully with SUPER permission and Limited User type.', Comment = '%1=USERID';
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";

    [Scope('OnPrem')]
    procedure ReduceDemoData()
    begin
        CODEUNIT.Run(CODEUNIT::"License Management Starter");
        CreateSetupData();
        CreateLimitedLicenseUser();
    end;

    local procedure CreateSetupData()
    var
        CustomerDiscountGroup: Record "Customer Discount Group";
        CustomerPriceGroup: Record "Customer Price Group";
        Item: Record Item;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        if SalespersonPurchaser.IsEmpty() then
            LibrarySales.CreateSalesperson(SalespersonPurchaser);

        if CustomerPriceGroup.IsEmpty() then
            LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);

        if CustomerDiscountGroup.IsEmpty() then
            LibraryERM.CreateCustomerDiscountGroup(CustomerDiscountGroup);

        if Item.IsEmpty() then
            LibraryInventory.CreateItem(Item);

        Message(SetupDataCreatedSuccessfullyMsg);
    end;

    local procedure CreateLimitedLicenseUser()
    var
        User: Record User;
    begin
        CODEUNIT.Run(CODEUNIT::"Users - Create Super User");

        User.SetRange("User Name", UserId);
        User.SetRange("License Type", User."License Type"::"Full User");
        User.FindLast();
        User.Validate("License Type", User."License Type"::"Limited User");
        User.Modify(true);

        Message(LimitedUserCreatedSuccessfullyMsg, UserId);
    end;
}

