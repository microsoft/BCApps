// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;

codeunit 148333 "Expense Agent Setup API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryExpense: Codeunit "Library - Expense";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ServiceNameTok: Label 'expenseAgentSetup', Locked = true;
        EmailAddressTok: Label 'emailAddress', Locked = true;

    [Test]
    procedure EmailAddressFieldIsExposedThroughAPI()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        TargetURL: Text;
        ResponseText: Text;
        ExpectedEmailValue: Text;
    begin
        // [SCENARIO] Service-side flows (notably the welcome notification) need
        // the inbound receipts email address that admins configure on the
        // Expense Agent Setup. Page 6942 "Expense Agent Setup API" must surface
        // it as ``emailAddress`` so the connector can pull it.
        // Issue: https://microsoft.ghe.com/bic/BC-ExpenseAgent/issues/1677
        Initialize();

        // [GIVEN] an Email Address is configured on the singleton setup record
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup."Email Address" := 'receipts@contoso.com';
        ExpenseAgentSetup.Modify();
        Commit();

        // [WHEN] the setup is fetched through the API
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"Expense Agent Setup API", ServiceNameTok);
        LibraryGraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, TargetURL, 200);

        // [THEN] the response carries the ``emailAddress`` field with the
        //        configured value (rather than omitting it as before).
        Assert.AreNotEqual(0, StrPos(ResponseText, EmailAddressTok),
            'The Expense Agent Setup API response should include the emailAddress field.');
        ExpectedEmailValue := StrSubstNo('"%1":"%2"', EmailAddressTok, ExpenseAgentSetup."Email Address");
        Assert.AreNotEqual(0, StrPos(ResponseText, ExpectedEmailValue),
            'The emailAddress field should carry the value configured on the Expense Agent Setup record.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Expense Agent Setup API Test");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Expense Agent Setup API Test");
        LibraryExpense.SetupNumberSeriesInExpenseMgmt();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Expense Agent Setup API Test");
    end;
}
