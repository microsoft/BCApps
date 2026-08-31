// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148349 "Expense PerDiem Locations Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        LibraryGraphMgt.SetAuthenticationProvider(
            Enum::"API Test Authentication"::"Microsoft Test Environment");
        LibraryGraphMgt.SetLicenseSafeWorkDate();
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure PerDiemLocationsReturnsLinkedLocationViaAPI()
    var
        CategoryCode: Code[20];
        LinkedLocation: Code[20];
        UnlinkedLocation: Code[20];
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] The query must return an Expense Location that is linked, through an
        //            Expense Rule, to an Expense Category whose Expense Detail Required = Per Diem,
        //            and must not return a location that no rule references.
        Initialize();

        // [GIVEN] A Per Diem category, a location linked to it via a rule, and an unrelated location.
        CategoryCode := CreateExpenseCategory("Expense Detail Needed"::"Per Diem");
        LinkedLocation := CreateExpenseLocation();
        UnlinkedLocation := CreateExpenseLocation();
        CreatePerDiemRule(CategoryCode, LinkedLocation);
        Commit();

        // [WHEN] The expensePerDiemLocations collection is fetched through the API.
        TargetURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"Expense Per Diem Locations", '');
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] The linked location is present and the unlinked location is not.
        Assert.AreNotEqual(0, StrPos(ResponseText, LinkedLocation),
            'Location linked through a Per Diem rule must be returned by expensePerDiemLocations.');
        Assert.AreEqual(0, StrPos(ResponseText, UnlinkedLocation),
            'Location not referenced by any rule must NOT be returned by expensePerDiemLocations.');
    end;

    [Test]
    procedure PerDiemLocationsExcludesNonPerDiemCategoryViaAPI()
    var
        CategoryCode: Code[20];
        Location: Code[20];
        TargetURL: Text;
        ResponseText: Text;
    begin
        // [SCENARIO] A location whose rule points to a category with Expense Detail Required <> Per Diem
        //            must be filtered out by the InnerJoin on the Per Diem category filter.
        Initialize();

        // [GIVEN] A non-Per-Diem category and a location tied to it through a rule inserted directly
        //         (the rule's OnValidate would otherwise block a location on a non-Per-Diem category).
        CategoryCode := CreateExpenseCategory("Expense Detail Needed"::Itemize);
        Location := CreateExpenseLocation();
        InsertRuleWithoutValidation(CategoryCode, Location);
        Commit();

        // [WHEN] The expensePerDiemLocations collection is fetched through the API.
        TargetURL := LibraryGraphMgt.CreateQueryTargetURL(Query::"Expense Per Diem Locations", '');
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] The location is not returned because its category is not Per Diem.
        Assert.AreEqual(0, StrPos(ResponseText, Location),
            'Location whose category Expense Detail Required is not Per Diem must NOT be returned.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense PerDiem Locations Test");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense PerDiem Locations Test");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense PerDiem Locations Test");
    end;

    local procedure CreateExpenseCategory(DetailRequired: Enum "Expense Detail Needed"): Code[20]
    var
        ExpenseCategory: Record "Expense Category";
    begin
        ExpenseCategory.Init();
        ExpenseCategory.Validate("Code",
            LibraryUtility.GenerateRandomCode(ExpenseCategory.FieldNo("Code"), Database::"Expense Category"));
        ExpenseCategory."Expense Detail Required" := DetailRequired;
        ExpenseCategory.Insert(true);
        exit(ExpenseCategory."Code");
    end;

    local procedure CreateExpenseLocation(): Code[20]
    var
        ExpenseLocation: Record "Expense Location";
    begin
        ExpenseLocation.Init();
        ExpenseLocation.Validate("No.",
            LibraryUtility.GenerateRandomCode(ExpenseLocation.FieldNo("No."), Database::"Expense Location"));
        ExpenseLocation.Validate(Description, ExpenseLocation."No.");
        ExpenseLocation.Validate(City, CopyStr(ExpenseLocation."No.", 1, MaxStrLen(ExpenseLocation.City)));
        ExpenseLocation.Insert(true);
        exit(ExpenseLocation."No.");
    end;

    local procedure CreatePerDiemRule(CategoryCode: Code[20]; LocationCode: Code[20])
    var
        ExpenseRuleHeader: Record "Expense Rule Header";
    begin
        ExpenseRuleHeader.Init();
        ExpenseRuleHeader.Validate("Expense Category Code", CategoryCode);
        ExpenseRuleHeader.Validate("Expense Location", LocationCode);
        ExpenseRuleHeader."Effective Date" := WorkDate();
        ExpenseRuleHeader.Insert(true);
    end;

    local procedure InsertRuleWithoutValidation(CategoryCode: Code[20]; LocationCode: Code[20])
    var
        ExpenseRuleHeader: Record "Expense Rule Header";
    begin
        ExpenseRuleHeader.Init();
        ExpenseRuleHeader."Expense Category Code" := CategoryCode;
        ExpenseRuleHeader."Expense Location" := LocationCode;
        ExpenseRuleHeader."Effective Date" := WorkDate();
        ExpenseRuleHeader.Insert(false);
    end;
}
