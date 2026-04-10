codeunit 134441 "Default Categories Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [G/L Account] [Account Category] [System Generated]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure AutoGenerateCategoriesIfEmptyTest()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategories: TestPage "G/L Account Categories";
    begin
        // Setup - Delete existing categories
        GLAccountCategory.DeleteAll();

        // Execute - Open G/L Categories page
        GLAccountCategories.OpenEdit();

        // Verify - Validate that Account categories are auto generated
        Assert.RecordIsNotEmpty(GLAccountCategory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoAutoGenerateCategoriesIfNotEmptyTest()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategories: TestPage "G/L Account Categories";
    begin
        // Setup - Delete existing categories and create one account category
        GLAccountCategory.DeleteAll();
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);

        // Execute - Open G/L Categories page
        Assert.RecordCount(GLAccountCategory, 1);
        GLAccountCategories.OpenEdit();

        // Verify - Validate that Account categories are auto generated
        Assert.RecordCount(GLAccountCategory, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AutoGenerateCategoriesIfEmptyOnCompanyInitTest()
    var
        GLAccount: Record "G/L Account";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // Setup - Delete existing categories and mapping
        GLAccount.ModifyAll("Account Subcategory Entry No.", 0);
        GLAccountCategory.DeleteAll();

        // Execute - Simulate Initialize Company
        GLAccountCategoryMgt.InitializeAccountCategories();

        // Verify - Validate that Account categories are auto generated
        Assert.RecordIsNotEmpty(GLAccountCategory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoAutoGenerateCategoriesIfNotEmptyOnCompanyInitTest()
    var
        GLAccount: Record "G/L Account";
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategoryMgt: Codeunit "G/L Account Category Mgt.";
    begin
        // Setup - Delete existing categories and create one account category and map it to an account
        GLAccountCategory.DeleteAll();
        LibraryERM.CreateGLAccountCategory(GLAccountCategory);
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount.Validate("Account Subcategory Entry No.", GLAccountCategory."Entry No.");
        GLAccount.Modify(true);

        // Execute - Simulate Initialize Company
        Assert.RecordCount(GLAccountCategory, 1);
        GLAccountCategoryMgt.InitializeAccountCategories();

        // Verify - Validate that Account categories are auto generated
        Assert.RecordCount(GLAccountCategory, 1);
        GLAccount.Get(GLAccount."No.");
        Assert.AreEqual(GLAccountCategory."Entry No.", GLAccount."Account Subcategory Entry No.", 'Account Category mapping was changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RootNodesAreMarkedOnGeneratedCategories()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategories: TestPage "G/L Account Categories";
    begin
        // Setup - Delete existing categories
        GLAccountCategory.DeleteAll();

        // Execute - Open G/L Categories page
        GLAccountCategories.OpenEdit();

        // Verify - Validate that Account categories are auto generated and root nodes are marked
        Assert.RecordIsNotEmpty(GLAccountCategory);
        GLAccountCategory.SetRange("Parent Entry No.", 0);
        if GLAccountCategory.FindSet(false) then
            repeat
                Assert.AreEqual(true, GLAccountCategory."System Generated", 'System Generated field is not marked as TRUE');
            until GLAccountCategory.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NonRootNodesAreUnmarkedOnGeneratedCategories()
    var
        GLAccountCategory: Record "G/L Account Category";
        GLAccountCategories: TestPage "G/L Account Categories";
    begin
        // Setup - Delete existing categories
        GLAccountCategory.DeleteAll();

        // Execute - Open G/L Categories page
        GLAccountCategories.OpenEdit();

        // Verify - Validate that Account categories are auto generated and non root nodes are not marked
        Assert.RecordIsNotEmpty(GLAccountCategory);
        GLAccountCategory.SetFilter("Parent Entry No.", '<> 0');
        if GLAccountCategory.FindSet(false) then
            repeat
                Assert.AreEqual(false, GLAccountCategory."System Generated", 'System Generated field is marked as TRUE');
            until GLAccountCategory.Next() = 0;
    end;
}

