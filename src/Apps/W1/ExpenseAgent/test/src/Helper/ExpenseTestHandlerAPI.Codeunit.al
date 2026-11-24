// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.CRM.Team;
using Microsoft.ExpenseAgent;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.HumanResources.Employee;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.Customer;
using System.Agents;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.User;

codeunit 148307 "Expense Test Handler API"
{
    /// <summary>
    /// Resets expense transactional data so tests can start from a clean slate.
    /// Example: curl.exe -X POST "http://localhost:7047/Navision_NAV/ODataV4/ExpenseTestHandler_Initialize?company=4d77b30a-3dc5-f011-9c12-7ced8d9e45e7" -u username:password -H "Content-Type: application/json" -H "Accept: application/json" -d "{}"
    /// </summary>
    [ServiceEnabled]
    procedure Initialize(): Text[30]
    var
        LibraryExpense: Codeunit "Library - Expense";
        CorpCardTestLib: Codeunit EACorpCardTestLib;
    begin
        // Card transactions reference expenses, so they are removed first to avoid links to deleted expenses.
        CorpCardTestLib.DeleteCorpCardTransactionalData();
        LibraryExpense.CleanTransactionalData();
        exit('Initialize completed');
    end;

    /// <summary>
    /// Deletes corporate card transactions, statements, settlements and exceptions. Cards and providers are kept.
    /// Example: curl.exe -X POST ".../ExpenseTestHandler_CleanupCorporateCards?company=..." -d "{}"
    /// </summary>
    [ServiceEnabled]
    procedure CleanupCorporateCards(): Text[50]
    var
        CorpCardTestLib: Codeunit EACorpCardTestLib;
    begin
        CorpCardTestLib.DeleteCorpCardTransactionalData();
        exit('Corporate card cleanup completed');
    end;

    /// <summary>
    /// Prepares the corporate card setup (AutoDraft, date window, MCC mappings, card payment method) and the CSV provider.
    /// Does not delete any data, so it can run before every test.
    /// Example: curl.exe -X POST ".../ExpenseTestHandler_ConfigureCorporateCards?company=..." -d "{}"
    /// </summary>
    [ServiceEnabled]
    procedure ConfigureCorporateCards(): Text[50]
    var
        CorpCardTestLib: Codeunit EACorpCardTestLib;
    begin
        CorpCardTestLib.EnsureCorpCardSetupForE2E();
        exit('Corporate card configuration completed');
    end;

    /// <summary>
    /// Returns the corporate card of the expense user that ends in the given digits, creating it on the CSV provider when needed.
    /// When lastFourDigits is blank, a card with unused digits is created.
    /// Example: curl.exe -X POST ".../ExpenseTestHandler_EnsureCorporateCard?company=..." -d "{\"expenseUserId\": \"...\", \"lastFourDigits\": \"4321\"}"
    /// </summary>
    /// <returns>JSON with cardId, lastFourDigits and providerCode.</returns>
    [ServiceEnabled]
    procedure EnsureCorporateCard(expenseUserId: Guid; lastFourDigits: Text[4]): Text
    var
        CorpCard: Record "EA Corp Card";
    begin
        FindOrCreateCorporateCard(expenseUserId, lastFourDigits, CorpCard);
        exit(GetCorporateCardJson(CorpCard));
    end;

    /// <summary>
    /// Imports one corporate card transaction through the CSV provider for the expense user's card. Post-import processing
    /// then links a matching existing expense or creates a draft card expense, as in production.
    /// A blank currencyCode uses the local currency code; a blank providerTransactionId gets a unique one.
    /// Example: curl.exe -X POST ".../ExpenseTestHandler_CreateCorporateCardTransaction?company=..." -d "{\"expenseUserId\": \"...\", \"lastFourDigits\": \"4321\", \"transactionDate\": \"2026-06-02\", \"amount\": 42.5, \"currencyCode\": \"\", \"merchantName\": \"Contoso Coffee\", \"mcc\": \"5812\", \"providerTransactionId\": \"\"}"
    /// </summary>
    /// <returns>
    /// JSON with transactionEntryNo, providerTransactionId, status, matchType, cardId, expenseNo, expenseId (empty when no expense
    /// was linked or created) and exceptionMessage (the latest exception of the transaction, if any).
    /// </returns>
    [ServiceEnabled]
    procedure CreateCorporateCardTransaction(expenseUserId: Guid; lastFourDigits: Text[4]; transactionDate: Date; amount: Decimal; currencyCode: Code[10]; merchantName: Text[100]; mcc: Code[4]; providerTransactionId: Text[100]): Text
    var
        CorpCard: Record "EA Corp Card";
        CorpCardTrans: Record "EA Corp Card Trans";
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        ProviderTransId: Code[100];
    begin
        CorpCardTestLib.EnsureCorpCardSetupForE2E();
        FindOrCreateCorporateCard(expenseUserId, lastFourDigits, CorpCard);

        ProviderTransId := CopyStr(UpperCase(providerTransactionId), 1, MaxStrLen(ProviderTransId));
        if ProviderTransId = '' then
            ProviderTransId := CopyStr('E2E-' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(ProviderTransId));
        if transactionDate = 0D then
            transactionDate := WorkDate();
        if currencyCode = '' then
            currencyCode := GetLocalCurrencyCode();

        CorpCardTestLib.ImportCsvTransaction(
            ProviderTransId, CorpCard.GetLastFourDigits(), transactionDate, amount, currencyCode, merchantName, mcc);

        CorpCardTrans.SetRange("Provider Code", CorpCard."Provider Code");
        CorpCardTrans.SetRange("Provider Trans Id", ProviderTransId);
        if not CorpCardTrans.FindLast() then
            Error(CorporateCardTransactionNotImportedErr, ProviderTransId);
        exit(GetCorporateCardTransactionJson(CorpCardTrans));
    end;

    local procedure FindOrCreateCorporateCard(ExpenseUserId: Guid; LastFourDigits: Text[4]; var CorpCard: Record "EA Corp Card")
    var
        ExpenseUser: Record "Expense User";
        CorpCardTestLib: Codeunit EACorpCardTestLib;
        ProviderCode: Code[20];
    begin
        CorpCardTestLib.EnsureCorpCardSetupForE2E();
        ProviderCode := CorpCardTestLib.GetCsvProviderCode();
        if not ExpenseUser.GetBySystemId(ExpenseUserId) then
            Error(ExpenseUserNotFoundErr, ExpenseUserId);

        if LastFourDigits = '' then
            LastFourDigits := GetUnusedLastFourDigits(ProviderCode)
        else
            if (StrLen(LastFourDigits) <> 4) or (DelChr(LastFourDigits, '=', '0123456789') <> '') then
                Error(InvalidLastFourDigitsErr, LastFourDigits);

        CorpCard.SetRange("Provider Code", ProviderCode);
        CorpCard.SetFilter("Masked Card No.", '%1', '*' + LastFourDigits);
        if CorpCard.FindFirst() then begin
            if CorpCard."Expense User No." <> ExpenseUser."No." then
                Error(CardDigitsUsedByOtherUserErr, LastFourDigits, CorpCard."Expense User No.");
            if CorpCard.Blocked then begin
                CorpCard.Blocked := false;
                CorpCard.Modify(true);
            end;
            exit;
        end;

        CorpCard.Init();
        CorpCard."Card Id" := CopyStr('E2E-' + ExpenseUser."No." + '-' + LastFourDigits, 1, MaxStrLen(CorpCard."Card Id"));
        CorpCard."Provider Code" := ProviderCode;
        CorpCard."Expense User No." := ExpenseUser."No.";
        CorpCard."Masked Card No." := CopyStr('****' + LastFourDigits, 1, MaxStrLen(CorpCard."Masked Card No."));
        CorpCard.Insert(true);
    end;

    local procedure GetUnusedLastFourDigits(ProviderCode: Code[20]): Text[4]
    var
        CorpCard: Record "EA Corp Card";
        LastFourDigits: Text[4];
        Attempt: Integer;
    begin
        CorpCard.SetRange("Provider Code", ProviderCode);
        for Attempt := 1 to 100 do begin
            LastFourDigits := CopyStr(Format(1000 + Random(8999)), 1, 4);
            CorpCard.SetFilter("Masked Card No.", '%1', '*' + LastFourDigits);
            if CorpCard.IsEmpty() then
                exit(LastFourDigits);
        end;
        Error(NoUnusedCardDigitsErr);
    end;

    local procedure GetLocalCurrencyCode(): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."LCY Code");
    end;

    local procedure GetCorporateCardJson(CorpCard: Record "EA Corp Card") Result: Text
    var
        CardJson: JsonObject;
    begin
        CardJson.Add('cardId', CorpCard."Card Id");
        CardJson.Add('lastFourDigits', CorpCard.GetLastFourDigits());
        CardJson.Add('providerCode', CorpCard."Provider Code");
        CardJson.WriteTo(Result);
    end;

    local procedure GetCorporateCardTransactionJson(CorpCardTrans: Record "EA Corp Card Trans") Result: Text
    var
        Expense: Record Expense;
        CorpCardException: Record "EA Corp Card Exception";
        TransactionJson: JsonObject;
        ExpenseId: Text;
        ExceptionMessage: Text;
    begin
        if CorpCardTrans."Expense No." <> '' then
            if Expense.Get(CorpCardTrans."Expense No.") then
                ExpenseId := LowerCase(DelChr(Format(Expense.SystemId), '=', '{}'));

        CorpCardException.SetRange("Trans Entry No.", CorpCardTrans."Entry No.");
        if CorpCardException.FindLast() then
            ExceptionMessage := CorpCardException.Message;

        TransactionJson.Add('transactionEntryNo', CorpCardTrans."Entry No.");
        TransactionJson.Add('providerTransactionId', CorpCardTrans."Provider Trans Id");
        TransactionJson.Add('status', Format(CorpCardTrans.Status));
        TransactionJson.Add('matchType', Format(CorpCardTrans."Match Type"));
        TransactionJson.Add('cardId', CorpCardTrans."Card Id");
        TransactionJson.Add('expenseNo', CorpCardTrans."Expense No.");
        TransactionJson.Add('expenseId', ExpenseId);
        TransactionJson.Add('exceptionMessage', ExceptionMessage);
        TransactionJson.WriteTo(Result);
    end;

    /// <summary>
    /// Explicitly provisions and enables Expense Agent setup for E2E tests, and returns the identity
    /// that the Expense Agent service must use to call Business Central.
    /// Example: curl.exe -X POST "http://localhost:7047/Navision_NAV/ODataV4/ExpenseTestHandler_Configure?company=4d77b30a-3dc5-f011-9c12-7ced8d9e45e7" -u username:password -H "Content-Type: application/json" -H "Accept: application/json" -d "{}"
    /// </summary>
    /// <returns>
    /// A JSON object with the completion status and a serviceIdentity object. The serviceIdentity holds
    /// the user name and web service access key of the Expense Agent Microsoft Entra application user.
    /// </returns>
    [ServiceEnabled]
    procedure Configure(): Text
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        CreateExpenseAgentSetup: Codeunit "Create Expense Agent Setup";
        CreateExpenseGLAccount: Codeunit "Create Expense GL Account";
        LibraryExpense: Codeunit "Library - Expense";
        Response: JsonObject;
        ServiceIdentity: JsonObject;
        ResponseText: Text;
    begin
        if not ExpenseAgentSetupIsComplete() then begin
            CreateExpenseAgentSetup.Run();
            CreateExpenseGLAccount.Run();
            ExpenseAgentSetup.Get();
            ExpenseAgentSetup.CreateDefaultSettings();
            LibraryExpense.EnsureExpenseAgentEnabled();
        end;
        // Outside the setup block, so databases set up before the Entra application was enabled here get it too.
        EnableEntraApplication();

        GetServiceIdentity(ServiceIdentity);
        Response.Add('status', 'Configure completed');
        Response.Add('serviceIdentity', ServiceIdentity);
        Response.WriteTo(ResponseText);
        exit(ResponseText);
    end;

    /// <summary>
    /// Enables the Expense Agent Microsoft Entra application for the current company, as activating the agent in the
    /// setup wizard does. This creates its application user and grants it the Expense Agent permission set for the company.
    /// </summary>
    internal procedure EnableEntraApplication()
    var
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        EnsureAadApplicationUser();
        ExpenseAgentEntraApp.EnableAadApplicationForCurrentCompany();
        Commit();
    end;

    /// <summary>
    /// Returns a web service access key for the enabled Expense Agent Microsoft Entra application user. On-premises,
    /// the Expense Agent service uses this identity to call Business Central with the same least-privilege permissions
    /// it has as an S2S application in SaaS. The key does not expire and is reused, so services that already use it keep
    /// working when Configure is called again.
    /// </summary>
    /// <param name="ServiceIdentity">Receives the userName and webServicesKey properties.</param>
    internal procedure GetServiceIdentity(var ServiceIdentity: JsonObject)
    var
        User: Record User;
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
        ServiceUserId: Guid;
    begin
        ServiceUserId := ExpenseAgentEntraApp.GetEnabledExpenseAgentUserId();
        User.Get(ServiceUserId);

        Clear(ServiceIdentity);
        ServiceIdentity.Add('userName', User."User Name");
        ServiceIdentity.Add('webServicesKey', GetOrCreateWebServicesKey(ServiceUserId));
    end;

    local procedure EnsureAadApplicationUser()
    var
        AadApplication: Record "AAD Application";
        ExpenseAgentEntraApp: Codeunit "Expense Agent Entra App Mgt.";
    begin
        // Enabling the Entra app creates its user through the platform and then reads it in the same transaction,
        // which fails in multitenant containers. Create the user and commit first; UserExists also repairs a stale user ID.
        if not AadApplication.Get(ExpenseAgentEntraApp.GetAadAppId()) then
            exit;
        if AadApplication.UserExists() then
            exit;

        // An enabled app without its user must be disabled first, so enabling it again completes the setup.
        AadApplication.State := AadApplication.State::Disabled;
        AadApplication.CreateUserFromAADApplication();
        Commit();
    end;

    local procedure GetOrCreateWebServicesKey(ServiceUserId: Guid): Text
    var
        IdentityManagement: Codeunit "Identity Management";
        WebServicesKey: Text;
    begin
        // A key without expiry has expiry date 0DT. A failed lookup returns the error text as key and the current time
        // as expiry, so checking for 0DT ensures that only an existing key is reused; otherwise a key is created, which
        // reports any error.
        if IdentityManagement.GetWebServiceExpiryDate(ServiceUserId) = 0DT then begin
            WebServicesKey := IdentityManagement.GetWebServicesKey(ServiceUserId);
            if WebServicesKey <> '' then
                exit(WebServicesKey);
        end;

        exit(IdentityManagement.CreateWebServicesKeyNoExpiry(ServiceUserId));
    end;

    local procedure ExpenseAgentSetupIsComplete(): Boolean
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Agent: Record Agent;
        TempAgentSetupBuffer: Record "Agent Setup Buffer" temporary;
        AgentSetup: Codeunit "Agent Setup";
    begin
        if not ExpenseAgentSetup.Get() then
            exit(false);
        if not ExpenseAgentSetup."Enable Agent" then
            exit(false);
        if IsNullGuid(ExpenseAgentSetup."User Security ID") then
            exit(false);
        if not Agent.Get(ExpenseAgentSetup."User Security ID") then
            exit(false);
        AgentSetup.GetSetupRecord(
            TempAgentSetupBuffer,
            ExpenseAgentSetup."User Security ID",
            "Agent Metadata Provider"::"Expense Agent",
            '',
            '',
            '');
        if TempAgentSetupBuffer.State <> TempAgentSetupBuffer.State::Enabled then
            exit(false);

        exit(
            ExpenseAgentSetup."No. Series Applied" and
            ExpenseAgentSetup."Payment Methods Applied" and
            ExpenseAgentSetup."Posting Groups Applied" and
            ExpenseAgentSetup."Exp. Categories Applied" and
            ExpenseAgentSetup."Exp. Locations Applied" and
            ExpenseAgentSetup."Management Rules Applied" and
            ExpenseAgentSetup."VAT Rates Applied");
    end;

    /// <summary>
    /// Creates a test Expense User with the specified parameters.
    /// Example: curl.exe -X POST "http://localhost:7047/Navision_NAV/ODataV4/ExpenseTestHandler_CreateExpenseUser?company=4d77b30a-3dc5-f011-9c12-7ced8d9e45e7" -u username:password -H "Content-Type: application/json" -H "Accept: application/json" -d "{\"no\": \"EMP001\", \"name\": \"John Doe\", \"email\": \"john.doe@contoso.com\"}"
    /// </summary>
    /// <param name="no">The expense user no (optional - auto-generated based on No. Series)</param>
    /// <param name="name">The expense user name (optional)</param>
    /// <param name="email">The expense user email (optional)</param>
    /// <returns>The SystemId of the created expense user</returns>
    [ServiceEnabled]
    procedure CreateExpenseUser(No: Code[20]; name: Text[100]; email: Text[80]): Guid
    var
        ExpenseUser: Record "Expense User";
        LibraryExpense: Codeunit "Library - Expense";
        IsModified: Boolean;
    begin
        if No = '' then
            // Use library to create with auto-generated values
            LibraryExpense.CreateExpenseUser(ExpenseUser)
        else
            if not ExpenseUser.Get(No) then
                CreateExpenseUser(ExpenseUser, No);

        // Override with provided values if specified
        if ExpenseUser."Employee No." = '' then begin
            ExpenseUser.Validate("Employee No.", GetEmployeeNo(No));
            IsModified := true;
        end;

        if name <> '' then begin
            ExpenseUser.Validate(Name, name);
            IsModified := true;
        end;

        if email <> '' then begin
            ExpenseUser.Validate("E-mail", email);
            IsModified := true;
        end;

        if IsModified then
            ExpenseUser.Modify(true);

        exit(ExpenseUser.SystemId);
    end;

    /// <summary>
    /// Configures two existing Expense Users as a submitter and approver for integration tests.
    /// The approver uses the current BC service user's ID without exercising the email-based
    /// Expense User onboarding validation, which is outside the lifecycle test's scope.
    /// The approver gets unlimited approval so report submission is not blocked by approval limits.
    /// </summary>
    /// <remarks>
    /// This endpoint intentionally mutates approval master data in the dedicated integration-test company.
    /// The configured approver identity and disabled standard approval workflow remain until a later fixture run changes them.
    /// </remarks>
    /// <param name="submitterExpenseUserId">The SystemId of the Expense User that submits the expenses.</param>
    /// <param name="approverExpenseUserId">The SystemId of the Expense User that approves the expenses.</param>
    /// <returns>A completion message after the approval scenario is configured.</returns>
    [ServiceEnabled]
    procedure ConfigureApprovalScenario(submitterExpenseUserId: Guid; approverExpenseUserId: Guid): Text[50]
    var
        SubmitterExpenseUser: Record "Expense User";
        ApproverExpenseUser: Record "Expense User";
        ExistingApprovalExpenseUser: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        LibraryExpense: Codeunit "Library - Expense";
        CurrentApprovalUserId: Code[50];
    begin
        if submitterExpenseUserId = approverExpenseUserId then
            Error(SameExpenseUserErr);

        if not SubmitterExpenseUser.GetBySystemId(submitterExpenseUserId) then
            Error(SubmitterExpenseUserNotFoundErr, submitterExpenseUserId);
        if not ApproverExpenseUser.GetBySystemId(approverExpenseUserId) then
            Error(ApproverExpenseUserNotFoundErr, approverExpenseUserId);

        CurrentApprovalUserId := CopyStr(UserId(), 1, MaxStrLen(ApproverExpenseUser."User Id For Approvals"));
        ExistingApprovalExpenseUser.SetRange("User Id For Approvals", CurrentApprovalUserId);
        ExistingApprovalExpenseUser.ModifyAll("User Id For Approvals", '');

        ApproverExpenseUser.GetBySystemId(approverExpenseUserId);
        ApproverExpenseUser."User Id For Approvals" := CurrentApprovalUserId;
        ApproverExpenseUser.Validate("Can Approve", true);
        ApproverExpenseUser.Validate("Unlimited Approval", true);
        ApproverExpenseUser.Modify(true);

        if ExpenseApprovalSetup.Get(SubmitterExpenseUser."No.") then begin
            ExpenseApprovalSetup.Validate("Approver No.", ApproverExpenseUser."No.");
            ExpenseApprovalSetup.Modify(true);
        end else
            LibraryExpense.CreateExpenseApprovalSetup(
                ExpenseApprovalSetup, SubmitterExpenseUser."No.", ApproverExpenseUser."No.");

        LibraryExpense.UpdateEnableApprovalWorkflowInAgentSetup(false);

        exit('ConfigureApprovalScenario completed');
    end;

    /// <summary>
    /// Creates a submitter, independent primary/final, interim, and alternate approvers, and dated coverage
    /// of the primary approver. Requires an enabled agent with the standard approval workflow disabled.
    /// No reports are created and no company-wide settings are changed.
    /// </summary>
    /// <param name="coverageStartDate">The first day of coverage, inclusive.</param>
    /// <param name="coverageEndDate">The last day of coverage, inclusive; 0D means no end date.</param>
    /// <returns>
    /// JSON with companyName, workDate, coverageId, coverageStartDate, coverageEndDate, and submitter,
    /// primaryApprover, interimApprover, and alternateApprover objects. Each identity contains id, number,
    /// email, employeeId, userId, userSetupId, and salespersonId. Keep this JSON for cleanup.
    /// </returns>
    [ServiceEnabled]
    procedure CreateInterimAndAlternateApproverFixture(coverageStartDate: Date; coverageEndDate: Date): Text
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Submitter: Record "Expense User";
        PrimaryApprover: Record "Expense User";
        InterimApprover: Record "Expense User";
        AlternateApprover: Record "Expense User";
        ExpenseApprovalSetup: Record "Expense Approval Setup";
        LibraryExpense: Codeunit "Library - Expense";
        Fixture: JsonObject;
        FixtureText: Text;
    begin
        ExpenseAgentSetup.Get();
        ExpenseAgentSetup.TestField("Enable Agent", true);
        ExpenseAgentSetup.TestField("Enable Approval Workflow", false);

        LibraryExpense.CreateExpenseUserWithApprovalIdentity(Submitter, false);
        LibraryExpense.CreateExpenseUserWithApprovalIdentity(PrimaryApprover, true);
        LibraryExpense.CreateExpenseUserWithApprovalIdentity(InterimApprover, true);
        LibraryExpense.CreateExpenseUserWithApprovalIdentity(AlternateApprover, true);
        if ExpenseApprovalSetup.Get(Submitter."No.") then begin
            ExpenseApprovalSetup.Validate("Approver No.", PrimaryApprover."No.");
            ExpenseApprovalSetup.Modify(true);
        end else
            LibraryExpense.CreateExpenseApprovalSetup(ExpenseApprovalSetup, Submitter."No.", PrimaryApprover."No.");

        Fixture.Add('companyName', CompanyName());
        Fixture.Add('workDate', WorkDate());
        Fixture.Add('coverageId', LibraryExpense.CreateAlternateApproverCoverage(
            PrimaryApprover."No.", AlternateApprover."No.", coverageStartDate, coverageEndDate));
        Fixture.Add('coverageStartDate', coverageStartDate);
        Fixture.Add('coverageEndDate', coverageEndDate);
        Fixture.Add('submitter', GetApproverFixtureIdentity(Submitter));
        Fixture.Add('primaryApprover', GetApproverFixtureIdentity(PrimaryApprover));
        Fixture.Add('interimApprover', GetApproverFixtureIdentity(InterimApprover));
        Fixture.Add('alternateApprover', GetApproverFixtureIdentity(AlternateApprover));
        Fixture.WriteTo(FixtureText);
        exit(FixtureText);
    end;

    /// <summary>
    /// Deletes the fixture records identified by the JSON returned from CreateInterimAndAlternateApproverFixture.
    /// Remove the scenario's reports and expenses first; existing table validation reports any remaining dependencies.
    /// Repeating cleanup for the same fixture is supported. Unrelated records and company settings aren't changed.
    /// </summary>
    /// <param name="fixtureJson">The complete JSON returned by the create action, in the same company.</param>
    [ServiceEnabled]
    procedure DeleteInterimAndAlternateApproverFixture(fixtureJson: Text): Text[50]
    var
        ExpenseAlternateApprover: Record "Expense Alternate Approver";
        Fixture: JsonObject;
        PrimaryApprover: JsonObject;
        AlternateApprover: JsonObject;
    begin
        Fixture.ReadFrom(fixtureJson);
        if Fixture.GetText('companyName') <> CompanyName() then
            Error(FixtureCompanyMismatchErr);
        PrimaryApprover := Fixture.GetObject('primaryApprover');
        AlternateApprover := Fixture.GetObject('alternateApprover');
        if ExpenseAlternateApprover.GetBySystemId(GetFixtureGuid(Fixture, 'coverageId')) then begin
            ExpenseAlternateApprover.TestField("Primary Approver No.", PrimaryApprover.GetText('number'));
            ExpenseAlternateApprover.TestField("Alternate Approver No.", AlternateApprover.GetText('number'));
            ExpenseAlternateApprover.Delete(true);
        end;

        DeleteApproverFixtureIdentity(Fixture.GetObject('submitter'));
        DeleteApproverFixtureIdentity(PrimaryApprover);
        DeleteApproverFixtureIdentity(Fixture.GetObject('interimApprover'));
        DeleteApproverFixtureIdentity(AlternateApprover);
        exit('Approver fixture deleted');
    end;

    local procedure GetApproverFixtureIdentity(ExpenseUser: Record "Expense User") Identity: JsonObject
    var
        Employee: Record Employee;
        User: Record User;
        UserSetup: Record "User Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        Employee.Get(ExpenseUser."Employee No.");
        User.SetRange("Authentication Email", ExpenseUser."E-mail");
        User.FindFirst();
        UserSetup.Get(User."User Name");
        SalespersonPurchaser.Get(UserSetup."Salespers./Purch. Code");

        Identity.Add('id', ExpenseUser.SystemId);
        Identity.Add('number', ExpenseUser."No.");
        Identity.Add('email', ExpenseUser."E-mail");
        Identity.Add('employeeId', Employee.SystemId);
        Identity.Add('userId', User."User Security ID");
        Identity.Add('userSetupId', UserSetup.SystemId);
        Identity.Add('salespersonId', SalespersonPurchaser.SystemId);
    end;

    local procedure DeleteApproverFixtureIdentity(Identity: JsonObject)
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
        User: Record User;
        UserSetup: Record "User Setup";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        FixtureUserId: Guid;
    begin
        FixtureUserId := GetFixtureGuid(Identity, 'userId');
        if FixtureUserId = UserSecurityId() then
            Error(CannotDeleteFixtureCallerErr);
        if User.Get(FixtureUserId) then begin
            User.TestField("Authentication Email", Identity.GetText('email'));
            if UserSetup.GetBySystemId(GetFixtureGuid(Identity, 'userSetupId')) then
                UserSetup.TestField("User ID", User."User Name");
        end;
        if ExpenseUser.GetBySystemId(GetFixtureGuid(Identity, 'id')) then begin
            ExpenseUser.TestField("No.", Identity.GetText('number'));
            ExpenseUser.TestField("E-mail", Identity.GetText('email'));
            if Employee.GetBySystemId(GetFixtureGuid(Identity, 'employeeId')) then
                ExpenseUser.TestField("Employee No.", Employee."No.");
            ExpenseUser.Delete(true);
        end;
        if Employee.GetBySystemId(GetFixtureGuid(Identity, 'employeeId')) then
            Employee.Delete(true);
        if UserSetup.GetBySystemId(GetFixtureGuid(Identity, 'userSetupId')) then begin
            if SalespersonPurchaser.GetBySystemId(GetFixtureGuid(Identity, 'salespersonId')) then
                UserSetup.TestField("Salespers./Purch. Code", SalespersonPurchaser.Code);
            UserSetup.Delete(true);
        end;
        if SalespersonPurchaser.GetBySystemId(GetFixtureGuid(Identity, 'salespersonId')) then
            SalespersonPurchaser.Delete(true);
        if User.Get(FixtureUserId) then
            User.Delete(true);
    end;

    local procedure GetFixtureGuid(Fixture: JsonObject; PropertyName: Text) Value: Guid
    begin
        Evaluate(Value, Fixture.GetText(PropertyName));
        if IsNullGuid(Value) then
            Error(FixtureIdentifierRequiredErr, PropertyName);
    end;

    local procedure CreateExpenseUser(var ExpenseUser: Record "Expense User"; No: Code[20])
    begin
        ExpenseUser.Init();
        ExpenseUser.Validate("No.", No);
        ExpenseUser.Validate("Employee No.", GetEmployeeNo(No));
        ExpenseUser.Insert(true);
    end;

    local procedure GetEmployeeNo(EmployeeNo: Code[20]): Code[20]
    var
        ExpenseUser: Record "Expense User";
        LibraryExpense: Codeunit "Library - Expense";
    begin
        ExpenseUser.SetFilter("Employee No.", '%1', EmployeeNo);
        if ExpenseUser.FindFirst() then
            exit(ExpenseUser."Employee No.")
        else
            exit(LibraryExpense.CreateEmployee(EmployeeNo));
    end;

    /// <summary>
    /// Enables or disables the project/task fields and configures visibility scope on the Expense Agent Setup.
    /// Example: curl.exe -X POST ".../ExpenseTestHandler_SetProjectFields?company=..." -d "{\"enabled\": true, \"allProjects\": false}"
    /// </summary>
    /// <param name="enabled">Whether project fields are enabled for submitters.</param>
    /// <param name="allProjects">When true sets visibility to "All projects"; otherwise "Assigned projects".</param>
    [ServiceEnabled]
    procedure SetProjectFields(enabled: Boolean; allProjects: Boolean): Text[50]
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
    begin
        if not ExpenseAgentSetup.Get() then begin
            ExpenseAgentSetup.Init();
            ExpenseAgentSetup.Insert();
        end;
        ExpenseAgentSetup.Validate("Enable Project Fields", enabled);
        if allProjects then
            ExpenseAgentSetup.Validate("Project Visibility", ExpenseAgentSetup."Project Visibility"::"All projects")
        else
            ExpenseAgentSetup.Validate("Project Visibility", ExpenseAgentSetup."Project Visibility"::"Assigned projects");
        ExpenseAgentSetup.Modify(true);
        exit('SetProjectFields completed');
    end;

    /// <summary>
    /// Resolves the Expense User by SystemId and ensures a Resource is linked to its Employee.
    /// Returns the Resource No. so the caller can plan jobs against it without a follow-up lookup.
    /// </summary>
    [ServiceEnabled]
    procedure EnsureResourceForExpenseUser(expenseUserId: Guid; resourceNo: Code[20]): Code[20]
    var
        ExpenseUser: Record "Expense User";
    begin
        ExpenseUser.GetBySystemId(expenseUserId);
        exit(EnsureResourceForEmployee(ExpenseUser."Employee No.", resourceNo));
    end;

    /// <summary>
    /// Clears the Resource No. on the Employee linked to the given Expense User. Returns the
    /// affected Employee No. (or '' when the user has no employee link). Used by the
    /// empty-resource-join scenario where the user must appear with an empty Resource No.
    /// </summary>
    [ServiceEnabled]
    procedure ClearResourceForExpenseUser(expenseUserId: Guid): Code[20]
    var
        ExpenseUser: Record "Expense User";
        Employee: Record Employee;
    begin
        ExpenseUser.GetBySystemId(expenseUserId);
        if (ExpenseUser."Employee No." <> '') and Employee.Get(ExpenseUser."Employee No.") then begin
            Employee.Validate("Resource No.", '');
            Employee.Modify(true);
        end;
        exit(ExpenseUser."Employee No.");
    end;

    /// <summary>
    /// Ensures a Resource exists and is linked to the given Employee. Returns the Resource No.
    /// Example: -d "{\"employeeNo\": \"EMP001\", \"resourceNo\": \"RES001\"}"
    /// </summary>
    [ServiceEnabled]
    procedure EnsureResourceForEmployee(employeeNo: Code[20]; resourceNo: Code[20]): Code[20]
    var
        Resource: Record Resource;
        Employee: Record Employee;
        LibraryResource: Codeunit "Library - Resource";
        ResNo: Code[20];
    begin
        ResNo := resourceNo;
        if ResNo = '' then begin
            LibraryResource.CreateResourceNew(Resource);
            ResNo := Resource."No.";
        end else
            if not Resource.Get(ResNo) then begin
                Resource.Init();
                Resource.Validate("No.", ResNo);
                Resource.Insert(true);
            end;

        if (employeeNo <> '') and Employee.Get(employeeNo) then begin
            Employee.Validate("Resource No.", ResNo);
            Employee.Modify(true);
        end;
        exit(ResNo);
    end;

    /// <summary>
    /// Creates a Job (Project) with the requested fields. PersonResponsible must be a Resource No.
    /// Example: -d "{\"no\":\"PRJ001\",\"description\":\"Test\",\"personResponsibleResourceNo\":\"RES001\",\"status\":\"Open\"}"
    /// </summary>
    [ServiceEnabled]
    procedure CreateProject(no: Code[20]; description: Text[100]; personResponsibleResourceNo: Code[20]; status: Text[20]): Guid
    var
        Job: Record Job;
        BillToCustomerNo: Code[20];
    begin
        if Job.Get(no) then
            exit(Job.SystemId);

        Job.Init();
        Job.Validate("No.", no);
        Job.Insert(true);

        if description <> '' then
            Job.Validate(Description, description);
        if personResponsibleResourceNo <> '' then
            Job.Validate("Person Responsible", personResponsibleResourceNo);

        BillToCustomerNo := FindAnyCustomer();
        if BillToCustomerNo <> '' then
            Job.Validate("Bill-to Customer No.", BillToCustomerNo);

        case UpperCase(status) of
            'OPEN':
                Job.Validate(Status, Job.Status::Open);
            'PLANNING':
                Job.Validate(Status, Job.Status::Planning);
            'QUOTE':
                Job.Validate(Status, Job.Status::Quote);
            'COMPLETED':
                Job.Validate(Status, Job.Status::Completed);
            else
                Job.Validate(Status, Job.Status::Open);
        end;
        Job.Modify(true);
        exit(Job.SystemId);
    end;

    /// <summary>
    /// Creates a Job Task under a Job. Returns the SystemId of the task.
    /// </summary>
    [ServiceEnabled]
    procedure CreateProjectTask(jobNo: Code[20]; taskNo: Code[20]; description: Text[100]): Guid
    var
        JobTask: Record "Job Task";
    begin
        if JobTask.Get(jobNo, taskNo) then
            exit(JobTask.SystemId);

        JobTask.Init();
        JobTask.Validate("Job No.", jobNo);
        JobTask.Validate("Job Task No.", taskNo);
        JobTask.Insert(true);
        if description <> '' then begin
            JobTask.Validate(Description, description);
            JobTask.Modify(true);
        end;
        exit(JobTask.SystemId);
    end;

    /// <summary>
    /// Creates a Job Planning Line assigning a Resource (user) to a Job Task on a given date.
    /// Line Type defaults to "Both Budget and Billable" so the task surfaces in user-assigned queries.
    /// </summary>
    [ServiceEnabled]
    procedure CreatePlanningLineForUser(jobNo: Code[20]; taskNo: Code[20]; resourceNo: Code[20]; planningDateText: Text[30]): Guid
    var
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        PlanningDate: Date;
    begin
        JobTask.Get(jobNo, taskNo);

        if planningDateText <> '' then
            Evaluate(PlanningDate, planningDateText);
        if PlanningDate = 0D then
            PlanningDate := WorkDate();

        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", jobNo);
        JobPlanningLine.Validate("Job Task No.", taskNo);
        JobPlanningLine."Line No." := GetNextPlanningLineNo(jobNo, taskNo);
        JobPlanningLine.Insert(true);

        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::"Both Budget and Billable");
        JobPlanningLine.Validate("Planning Date", PlanningDate);
        JobPlanningLine.Validate(Type, JobPlanningLine.Type::Resource);
        JobPlanningLine.Validate("No.", resourceNo);
        JobPlanningLine.Validate(Quantity, 1);
        JobPlanningLine.Modify(true);
        exit(JobPlanningLine.SystemId);
    end;

    /// <summary>
    /// Assigns a Resource to a Project (blank taskNo -> whole-project assignment) or to a
    /// specific posting Project Task, via a Job Assigned Resource record. Returns the
    /// SystemId of the assignment.
    /// Example: -d "{\"jobNo\":\"PRJ001\",\"taskNo\":\"\",\"resourceNo\":\"RES001\"}"
    /// </summary>
    [ServiceEnabled]
    procedure CreateJobAssignedResource(jobNo: Code[20]; taskNo: Code[20]; resourceNo: Code[20]): Guid
    var
        JobAssignedResource: Record "Job Assigned Resource";
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJobAssignedResource(jobNo, taskNo, resourceNo, JobAssignedResource);
        exit(JobAssignedResource.SystemId);
    end;

    /// <summary>
    /// Deletes all Job Planning Lines, Job Assigned Resources, Job Tasks, and Jobs - cleans up project fixtures between tests.
    /// </summary>
    [ServiceEnabled]
    procedure CleanupProjects(): Text[30]
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobAssignedResource: Record "Job Assigned Resource";
    begin
        JobPlanningLine.DeleteAll(true);
        JobAssignedResource.DeleteAll(true);
        JobTask.DeleteAll(true);
        Job.DeleteAll(true);
        exit('CleanupProjects completed');
    end;

    local procedure GetNextPlanningLineNo(JobNo: Code[20]; JobTaskNo: Code[20]): Integer
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job No.", JobNo);
        JobPlanningLine.SetRange("Job Task No.", JobTaskNo);
        if JobPlanningLine.FindLast() then
            exit(JobPlanningLine."Line No." + 10000);
        exit(10000);
    end;

    local procedure FindAnyCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        if Customer.FindFirst() then
            exit(Customer."No.");
        exit('');
    end;

    var
        ApproverExpenseUserNotFoundErr: Label 'The approver Expense User with SystemId %1 does not exist.', Comment = '%1 = Expense User SystemId';
        SameExpenseUserErr: Label 'The submitter and approver must be different Expense Users.';
        SubmitterExpenseUserNotFoundErr: Label 'The submitter Expense User with SystemId %1 does not exist.', Comment = '%1 = Expense User SystemId';
        FixtureCompanyMismatchErr: Label 'Delete the approver fixture in the company where it was created.';
        CannotDeleteFixtureCallerErr: Label 'The current Business Central user cannot be deleted as part of an approver fixture.';
        FixtureIdentifierRequiredErr: Label 'The approver fixture must contain a non-empty %1 identifier.', Comment = '%1 = JSON property name';
        ExpenseUserNotFoundErr: Label 'The Expense User with SystemId %1 does not exist.', Comment = '%1 = Expense User SystemId';
        InvalidLastFourDigitsErr: Label 'The last four card digits must be exactly four digits, but %1 was specified.', Comment = '%1 = specified digits';
        CardDigitsUsedByOtherUserErr: Label 'A corporate card ending in %1 already belongs to Expense User %2.', Comment = '%1 = last four digits, %2 = Expense User No.';
        NoUnusedCardDigitsErr: Label 'No unused last four card digits were found for the corporate card provider.';
        CorporateCardTransactionNotImportedErr: Label 'The corporate card transaction %1 was not imported.', Comment = '%1 = provider transaction ID';
}