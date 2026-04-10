codeunit 132903 UserCardTest
{
    // Tests related to user authentication and permissions

    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [User] [UI]
        isInitialized := false;
    end;

    var
        UserAlReadyExist001Err: Label 'The account USER001 already exists.';
        User001Msg: Label 'USER001';
        User002Msg: Label 'USER002';
        ErrorStringCom001Err: Label 'Missing Expected error message: %1. \ Actual error recieved: %2.', Comment = '%1 = Expected exception error message, %2 = Actual exception error message';
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        ValidationError: Text;
        isInitialized: Boolean;
        PasswordsError001Err: Label 'The passwords that you entered do not match.';
        PasswordsError003Err: Label 'The password that you entered does not meet the minimum requirements. It must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number and one special character. It must not have a sequence of 3 or more ascending, descending or repeating characters.';
        LastError: Text;
        ErrorStringCom002Err: Label 'The validation errors are not as expected. Expected: %1 Actual: %2 AND %3.', Comment = '%1 = Expected validation error, %2 = Actual validation error, %3 = Actual validation error.';
        LastValidation: Text;
        PwToEnter: Text;
        RepPwToEnter: Text;
        PwErrorInMain: Boolean;
        PwErrorInRepeat: Boolean;
        WsNeverExpiresToenter: Boolean;
        WsExpirationDateToEnter: DateTime;
        AcsUserNameToEnter: Text;
        AcsAuthKeyToEnter: Text;
        AcsErrorExpected: Boolean;
        AcsGenerateKey: Boolean;
        WsInvokeCancelToEnter: Boolean;
        ErrorKeyNotSetErr: Label 'WebServiceKey has not been set.';
        ErrorStatusUnexpectedErr: Label 'Status is unexpected.';
        ErrorAcsKeyNotGeneratedErr: Label 'The ACS key was not generated.';
        ValidTestAuthenticationEmailTok: Label 'test@email.com';
        AuthenticationEmail001Err: Label 'You must specify a valid email address. (Select Refresh to discard errors)';
        AuthenticationEmail002Err: Label 'The specified authentication email address ''%1'' is already being used by another user. You must specify a unique email address. (Select Refresh to discard errors)';
        DisableUserMsg: Label 'To permanently disable a user, go to your Microsoft 365 admin center. Disabling the user in Business Central will only be effective until the next user synchronization with Microsoft 365.';

    local procedure Initialize()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
    begin
        LibraryVariableStorage.Clear();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        if isInitialized then
            exit;

        AddUserHelper(User001Msg);
        isInitialized := true;
        Commit();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo,SetPasswordHandler')]
    [Scope('OnPrem')]
    procedure AddGoodPassword()
    begin
        Initialize();
        PwErrorInMain := false;
        PwErrorInRepeat := false;
        PasswordComplexityHelper('Password1@', 'Password1@', '');
    end;

    [Test]
    [HandlerFunctions('ErrorHandler,SetPasswordHandler,ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AddSimplePassword()
    begin
        Initialize();
        PwErrorInMain := true;
        PwErrorInRepeat := false;
        PasswordComplexityHelper('password', 'password', PasswordsError003Err);
    end;

    [Test]
    [HandlerFunctions('ErrorHandler,SetPasswordHandler,ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AddShortPassword()
    begin
        Initialize();
        PwErrorInMain := true;
        PwErrorInRepeat := false;
        PasswordComplexityHelper('pass', 'pass', PasswordsError003Err);
    end;

    [Test]
    [HandlerFunctions('ErrorHandler,SetPasswordHandler,ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AddJustNumbersPassword()
    begin
        Initialize();
        PwErrorInMain := true;
        PwErrorInRepeat := false;
        PasswordComplexityHelper('12345678', '12345678', PasswordsError003Err);
    end;

    [Test]
    [HandlerFunctions('ErrorHandler,SetPasswordHandler,ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AddNoNumbersPassword()
    begin
        Initialize();
        PwErrorInMain := true;
        PwErrorInRepeat := false;
        PasswordComplexityHelper('passWORD', 'passWORD', PasswordsError003Err);
    end;

    [Test]
    [HandlerFunctions('ErrorHandler,SetPasswordHandler,ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AddJustUppercasePassword()
    begin
        Initialize();
        PwErrorInMain := true;
        PwErrorInRepeat := false;
        PasswordComplexityHelper('PASSWORD', 'PASSWORD', PasswordsError003Err);
    end;

    [Test]
    [HandlerFunctions('ErrorHandler,SetPasswordHandler,ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AddNoUppercasePassword()
    begin
        Initialize();
        PwErrorInMain := true;
        PwErrorInRepeat := false;
        PasswordComplexityHelper('passw0rd', 'passw0rd', PasswordsError003Err);
    end;

    [Test]
    [HandlerFunctions('ErrorHandler,SetPasswordHandler,ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AddNoLowercasePassword()
    begin
        Initialize();
        PwErrorInMain := true;
        PwErrorInRepeat := false;
        PasswordComplexityHelper('PASSW0RD', 'PASSW0RD', PasswordsError003Err);
    end;

    [Test]
    [HandlerFunctions('ErrorHandler,SetPasswordHandler,ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AddPasswordNotMatching()
    begin
        Initialize();
        PwErrorInMain := false;
        PwErrorInRepeat := true;
        PasswordComplexityHelper('Something1@', 'SomethingElse', PasswordsError001Err);
    end;

    [Test]
    [HandlerFunctions('SetAcsAuthenticationHandler,ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure GenerateAcsPin()
    var
        TestUserPermissionsSubs: Codeunit "Test User Permissions Subs.";
    begin
        Initialize();
        TestUserPermissionsSubs.SetCanManageUser(UserSecurityId());
        BindSubscription(TestUserPermissionsSubs);

        // Set valid ACS pin with auto generate. Ensure ACS state changed to Pending and ACS pin is persistent
        AcsAuthenticationHelper(User001Msg, '', 'Pending', false, true);
    end;

    [Test]
    [HandlerFunctions('SetWebServiceAccessHandler,ConfirmHandlerAnsYes')]
    [Scope('OnPrem')]
    procedure GenerateWebServiceKeyNoExpires()
    var
        TestUserPermissionsSubs: Codeunit "Test User Permissions Subs.";
        UserCardPage: TestPage "User Card";
        WsCompareKey: Text;
    begin
        Initialize();
        TestUserPermissionsSubs.SetCanManageUser(UserSecurityId());
        BindSubscription(TestUserPermissionsSubs);

        // Generate web key with no expires date. Validate key is generated and not date is not set
        WebServiceAccessHelper(CreateDateTime(Today, 0T), true, false, User001Msg);

        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", User001Msg);
        UserCardPage."User Name".AssertEquals(User001Msg);
        UserCardPage.WebServiceExpiryDate.AssertEquals('');
        WsCompareKey := UserCardPage.WebServiceID.Value();
        UserCardPage.Close();
        if WsCompareKey = '' then
            Error(ErrorKeyNotSetErr);
    end;

    [Test]
    [HandlerFunctions('SetWebServiceAccessHandler,ConfirmHandlerAnsYes')]
    [Scope('OnPrem')]
    procedure GenerateWebServiceKeyWithExpires()
    var
        TestUserPermissionsSubs: Codeunit "Test User Permissions Subs.";
        UserCardPage: TestPage "User Card";
        WsCompareKey: Text;
    begin
        Initialize();
        TestUserPermissionsSubs.SetCanManageUser(UserSecurityId());
        BindSubscription(TestUserPermissionsSubs);

        // Generate web key with expire date. Validate key is generated and date i set
        WebServiceAccessHelper(CreateDateTime(Today, 0T), false, false, User001Msg);
        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", User001Msg);
        UserCardPage."User Name".AssertEquals(User001Msg);

        UserCardPage.WebServiceExpiryDate.AssertEquals(CreateDateTime(Today, 0T));
        WsCompareKey := UserCardPage.WebServiceID.Value();
        UserCardPage.Close();
        if WsCompareKey = '' then
            Error(ErrorKeyNotSetErr);
    end;

    [Test]
    [HandlerFunctions('SetWebServiceAccessHandler,ConfirmHandlerAnsYes')]
    [Scope('OnPrem')]
    procedure CancelGenerateWebServiceKey()
    var
        TestUserPermissionsSubs: Codeunit "Test User Permissions Subs.";
        UserCardPage: TestPage "User Card";
        WsCompareKey: Text;
    begin
        Initialize();
        TestUserPermissionsSubs.SetCanManageUser(UserSecurityId());
        BindSubscription(TestUserPermissionsSubs);

        // Generate web key. Answer no if we should generate key. Ensure key and date is not changed
        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", User001Msg);
        UserCardPage."User Name".AssertEquals(User001Msg);
        WsCompareKey := UserCardPage.WebServiceID.Value();
        UserCardPage.Close();

        WebServiceAccessHelper(CreateDateTime(Today, 0T), true, true, User001Msg);

        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", User001Msg);
        UserCardPage."User Name".AssertEquals(User001Msg);
        UserCardPage.WebServiceID.AssertEquals(WsCompareKey);
        UserCardPage.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckUserAlreadyExists()
    var
        UserCardPage: TestPage "User Card";
    begin
        Initialize();
        UserCardPage.OpenNew();
        asserterror UserCardPage."User Name".Value := User001Msg;
        if UserCardPage.GetValidationError() <> UserAlReadyExist001Err then begin
            ValidationError := UserCardPage.GetValidationError();
            UserCardPage.Close();
            Error(ErrorStringCom001Err, UserAlReadyExist001Err, ValidationError);
        end;
        UserCardPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AuthenticationEmailDefaultsToEmpty()
    var
        UserCardPage: TestPage "User Card";
    begin
        Initialize();

        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", User001Msg);
        UserCardPage."User Name".AssertEquals(User001Msg);
        UserCardPage."Authentication Email".AssertEquals('');
        UserCardPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AuthenticationEmailCanBeCleared()
    begin
        Initialize();

        ValidAuthenticationEmailHelper(ValidTestAuthenticationEmailTok, ValidTestAuthenticationEmailTok);
        ValidAuthenticationEmailHelper('', '');
        ValidAuthenticationEmailHelper('   ', '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AuthenticationEmailIgnoresWhitespaces()
    begin
        Initialize();

        // Test leading spaces
        ValidAuthenticationEmailHelper('    ' + ValidTestAuthenticationEmailTok, ValidTestAuthenticationEmailTok);

        // Test trailing spaces
        ValidAuthenticationEmailHelper(ValidTestAuthenticationEmailTok + '   ', ValidTestAuthenticationEmailTok);

        // Test leading and trailing white chars
        ValidAuthenticationEmailHelper('    ' + ValidTestAuthenticationEmailTok + '    ', ValidTestAuthenticationEmailTok);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerAnsNo')]
    procedure AuthenticationEmailSizeLimit()
    var
        MaxLengthEmail: Text;
        Iterator: Integer;
        ValidationErrorMessage: Text;
    begin
        Initialize();

        // The total character limit of an email address, according to the RFC3696 (+ errata), is 256.
        // Unfortunately NAV supports fields no bigger than 250 chars.
        // 1. Check that a 250 char email is valid
        MaxLengthEmail := '';
        for Iterator := 1 to 60 do
            MaxLengthEmail := MaxLengthEmail + 'm';
        MaxLengthEmail := MaxLengthEmail + '@';
        for Iterator := 1 to 186 do
            MaxLengthEmail := MaxLengthEmail + 'm';
        MaxLengthEmail := MaxLengthEmail + '.dk';
        ValidAuthenticationEmailHelper(MaxLengthEmail, MaxLengthEmail);

        // 2. Check that a longer email is invalid
        MaxLengthEmail := 'overflow' + MaxLengthEmail;
        ValidationErrorMessage := 'The length of the string is 258, but it must be less than or equal to 250 characters.';
        InvalidAuthenticationEmailHelper(MaxLengthEmail, ValidationErrorMessage);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AuthenticationEmailAcceptsUnicode()
    begin
        Initialize();

        ValidAuthenticationEmailHelper('ÔÇáuthÔÇÿntÆcãÆtÆŽ«n@ÔÇÿmail.com', 'ÔÇáuthÔÇÿntÆcãÆtÆŽ«n@ÔÇÿmail.com');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AuthenticationEmailValid()
    begin
        Initialize();

        ValidAuthenticationEmailHelper('niceandsimple@example.com', 'niceandsimple@example.com');
        ValidAuthenticationEmailHelper('common.common@example.com', 'common.common@example.com');
        ValidAuthenticationEmailHelper('a.little.lengthy.but.fine@dept.example.com', 'a.little.lengthy.but.fine@dept.example.com');
        ValidAuthenticationEmailHelper(
          'disposable.style.email.with+symbol@example.com', 'disposable.style.email.with+symbol@example.com');
        ValidAuthenticationEmailHelper('user@[IPv6:2001:db8:1ff::a0b:dbd0]', 'user@[IPv6:2001:db8:1ff::a0b:dbd0]');
        ValidAuthenticationEmailHelper('"much.more unusual"@example.com', '"much.more unusual"@example.com');
        ValidAuthenticationEmailHelper('"very.unusual.@.unusual.com"@example.com', '"very.unusual.@.unusual.com"@example.com');
        ValidAuthenticationEmailHelper(
          '"very.(),:;<>[]\".VERY.\"very@\\ \"very\".unusual"@strange.example.com',
          '"very.(),:;<>[]\".VERY.\"very@\\ \"very\".unusual"@strange.example.com');
        ValidAuthenticationEmailHelper('postbox@com', 'postbox@com');
        ValidAuthenticationEmailHelper('admin@mailserver1', 'admin@mailserver1');
        ValidAuthenticationEmailHelper('!#$%&||''*+-/=?^_`{}|~@example.org', '!#$%&||''*+-/=?^_`{}|~@example.org');
        ValidAuthenticationEmailHelper('"()<>[]:,;@\\\"!#$%&''*+-/=?^_`{}| ~.a"@example.org',
          '"()<>[]:,;@\\\"!#$%&''*+-/=?^_`{}| ~.a"@example.org');
        ValidAuthenticationEmailHelper('" "@example.org', '" "@example.org');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AuthenticationEmailValidDisplayName()
    begin
        Initialize();

        ValidAuthenticationEmailHelper('Test <' + ValidTestAuthenticationEmailTok + '>', ValidTestAuthenticationEmailTok);
        ValidAuthenticationEmailHelper('"Test" <' + ValidTestAuthenticationEmailTok + '>', ValidTestAuthenticationEmailTok);
        ValidAuthenticationEmailHelper('"Test, Email" <' + ValidTestAuthenticationEmailTok + '>', ValidTestAuthenticationEmailTok);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AuthenticationEmailInvalid()
    begin
        Initialize();

        InvalidAuthenticationEmailHelper('Abc.example.com', AuthenticationEmail001Err);
        InvalidAuthenticationEmailHelper('a"b(c)d,e:f;g<h>i[j\k]l@example.com', AuthenticationEmail001Err);
        InvalidAuthenticationEmailHelper('just"not"right@example.com', AuthenticationEmail001Err);
        InvalidAuthenticationEmailHelper('this is"not\allowed@example.com', AuthenticationEmail001Err);
        InvalidAuthenticationEmailHelper('this\ still\"not\\allowed@example.com', AuthenticationEmail001Err);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AuthenticationEmailMultipleValidatesLast()
    begin
        Initialize();

        // The .NET MailAddress constructor validates the last email address in the string
        ValidAuthenticationEmailHelper('ab@mail.com, ac@mail.com', 'ac@mail.com');

        // If any of the email addresses in the string is not valid, the entire string is considered invalidInvalidAuthenticationEmailHelper('this\ still\"not\\allowed@example.com, ac@mail.com');
        InvalidAuthenticationEmailHelper('this is"not\allowed@example.com, user2@host', AuthenticationEmail001Err);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure AuthenticationEmailUnique()
    var
        UserCardPage: TestPage "User Card";
        ValidationError: Text;
    begin
        Initialize();

        ValidAuthenticationEmailHelper(ValidTestAuthenticationEmailTok, ValidTestAuthenticationEmailTok);
        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := User002Msg;

        asserterror UserCardPage."Authentication Email".Value := ValidTestAuthenticationEmailTok;
        ValidationError := UserCardPage.GetValidationError();

        if ValidationError <> StrSubstNo(AuthenticationEmail002Err, ValidTestAuthenticationEmailTok) then begin
            UserCardPage.Close();
            ValidationError := 'Unexpected validation error:\Expected:\' +
              StrSubstNo(AuthenticationEmail002Err, ValidTestAuthenticationEmailTok) + '\Actual:\' + ValidationError + '\';
            Error(ValidationError);
        end;
        UserCardPage.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure ExchangeIdentifierMappingExistsOnlyWhenFieldHasValue()
    var
        User: Record User;
        UserCard: TestPage "User Card";
        IsMapped: Boolean;
    begin
        Initialize();

        // [FEATURE] [Office Authentication]
        // [SCENARIO] Verify User card reflects if a User has Exchange Identifier.
        // [GIVEN] New uncommitted Blank User
        // [WHEN] Opening the User card
        UserCard.OpenNew();
        // [THEN] Mapped To Exchange Identifier is not checked
        Evaluate(IsMapped, Format(UserCard.MappedToExchangeIdentifier.Value));
        Assert.IsFalse(IsMapped, 'Did not expect Mapped to Exchange Identifier to be true for a new user.');
        UserCard.Close();

        // [GIVEN] Give an existing user
        // [GIVEN] The Exchange Identifier Field is not populated
        User.SetRange("User Name", User001Msg);
        User.FindFirst();
        if User."Exchange Identifier" <> '' then begin
            Clear(User."Exchange Identifier");
            User.Modify(true);
        end;
        // [WHEN] Opening the User card
        UserCard.OpenEdit();
        UserCard.FindFirstField("User Name", User001Msg);
        UserCard."User Name".AssertEquals(User001Msg);
        // [THEN] Mapped To Exchange Identifier is not checked
        Evaluate(IsMapped, Format(UserCard.MappedToExchangeIdentifier.Value));
        Assert.IsFalse(
          IsMapped, 'Did not expect Mapped to Exchange Identifier to be true for an existing user without Exchange Identifier set');
        UserCard.Close();

        // [GIVEN] Give an existing user
        // [GIVEN] The Exchange Identifier Field is populated
        User.SetRange("User Name", User001Msg);
        User.FindFirst();
        User."Exchange Identifier" := 'Something @ somewhere';
        User.Modify(true);
        // [WHEN] Opening the User card
        UserCard.OpenEdit();
        UserCard.FindFirstField("User Name", User001Msg);
        UserCard."User Name".AssertEquals(User001Msg);
        // [THEN] Mapped To Exchange Identifier is checked
        Evaluate(IsMapped, Format(UserCard.MappedToExchangeIdentifier.Value));
        Assert.IsTrue(IsMapped, 'Expected Mapped to Exchange Identifier to be true for an existing user with Exchange Identifier set');
        UserCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsYes')]
    [Scope('OnPrem')]
    procedure DeleteExchangeIdentifierMappingIsOnlyEnabledWhenPresent()
    var
        User: Record User;
        UserCard: TestPage "User Card";
    begin
        Initialize();
        // [FEATURE] [Office Authentication]
        // [SCENARIO] Verify Delete Exchange Identifier Mapping action can delete Exchange Identifier value

        // [GIVEN] A User without Exchange Identifier set
        User.SetRange("User Name", User001Msg);
        User.FindFirst();
        if User."Exchange Identifier" <> '' then begin
            User."Exchange Identifier" := '';
            User.Modify(true);
        end;

        // [WHEN] Opening the User card
        UserCard.OpenEdit();
        UserCard.FindFirstField("User Name", User001Msg);
        UserCard."User Name".AssertEquals(User001Msg);
        // [THEN] The Delete Exchange Identifier Mapping is not enabled
        Assert.IsFalse(
          UserCard.DeleteExchangeIdentifier.Enabled(), 'Did not expect the action to be enabled if Exchange Identifier is not set');
        UserCard.Close();

        // [GIVEN] A User with Exchange Identifier set
        User."Exchange Identifier" := 'blbla';
        User.Modify(true);
        // [WHEN] Opening the User card
        UserCard.OpenEdit();
        UserCard.FindFirstField("User Name", User001Msg);
        UserCard."User Name".AssertEquals(User001Msg);
        // [THEN] The Delete Exchange Identifier Mapping is enabled
        Assert.IsTrue(UserCard.DeleteExchangeIdentifier.Enabled(), 'Expected the action to be enabled when the Exchange Identifier is set');

        // [WHEN] Clicking the action
        UserCard.DeleteExchangeIdentifier.Invoke();
        // [THEN] The Exchange Identifier is deleted
        User.SetRange("User Name", User001Msg);
        User.FindFirst();
        Assert.AreEqual('', User."Exchange Identifier", 'Expected the Exchange Identifier to be cleared when invoking the action');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsYes')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnCreateFirstUserOnPremShowDialogIfCreateNewSuperForYourselfAnsYes()
    var
        User: Record User;
        EnvironmentInfo: Codeunit "Environment Information";
        UserCardPage: TestPage "User Card";
    begin
        // [GIVEN] An on prem version where no users exist
        if EnvironmentInfo.IsSaaS() then
            exit;

        EnsureNoUsers();

        // [WHEN] A new user card is opened, create new super user dialog
        // opens (for logged in user) and answered yes
        UserCardPage.OpenNew();
        UserCardPage.Close();

        // [THEN] a new user exists
        Assert.RecordCount(User, 1);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnCreateFirstUserOnPremShowDialogIfCreateNewSuperForYourselfAnsNo()
    var
        User: Record User;
        EnvironmentInfo: Codeunit "Environment Information";
        UserCardPage: TestPage "User Card";
    begin
        // [GIVEN] An on prem version where no users exist
        if EnvironmentInfo.IsSaaS() then
            exit;

        EnsureNoUsers();

        // [WHEN] A new user card is opened, create new super user dialog
        // opens (for logged in user) and answered no
        UserCardPage.OpenNew();
        UserCardPage.Close();

        // [THEN] The number of users remains zero
        Assert.RecordIsEmpty(User);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnCreateUserOnPremDoNotShowDialogWhenUsersExist()
    var
        User: Record User;
        EnvironmentInfo: Codeunit "Environment Information";
        UserCardPage: TestPage "User Card";
    begin
        // [GIVEN] On prem version and create a new user programmaticaly
        // to avoid opening a new user card when no users exist, therefore
        // raising an error
        if EnvironmentInfo.IsSaaS() then
            exit;
        EnsureNoUsers();
        Codeunit.Run(Codeunit::"Users - Create Super User");
        Assert.RecordIsNotEmpty(User);

        // [WHEN]  No dialog opens because users already exist
        UserCardPage.OpenNew();
        UserCardPage.Close();

        // [THEN] No dialog opens. If it does there is no confirm handler
        // so the will be a raised error
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo')]
    [Scope('OnPrem')]
    procedure CreateNewUserInSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UserCard: TestPage "User Card";
    begin
        // [GIVEN] A system setup as SaaS solution
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] The user tries to create a new user
        // [THEN] A confirmation dialog is shown (handler) and an error occurs
        asserterror UserCard.OpenNew();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure EnsureNoUsers()
    var
        User: Record User;
    begin
        User.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsNo,DisableUserMessageHandler')]
    [Scope('OnPrem')]
    procedure ChangeStateOfUserInSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        UserCard: TestPage "User Card";
        User: Record User;
    begin
        // [SCENARIO] A message is shown in SaaS, if user is disabled.
        Initialize();

        // [GIVEN] A system setup as SaaS solution
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [WHEN] The user tries to change the state of a user
        // [THEN] A message is shown
        UserCard.OpenEdit();
        UserCard.State.SetValue(User.State::Disabled);
        UserCard.OK().Invoke();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerAnsYes')]
    procedure PlansNotVisibleInUserCardWhenNotSuperTest()
    var
        User: Record User;
        AzureADPlanTestLibrary: Codeunit "Azure AD Plan Test Library";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        PlanIds: Codeunit "Plan Ids";
        UserCard: TestPage "User Card";
    begin
        // [SCENARIO] User plans and permission are not visible on user card when user does not have super
        Initialize();
        AddUserHelper(User002Msg);

        // [GIVEN] A system setup as SaaS solution
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);

        // [GIVEN] The User has assigned some plans
        User.SetRange("User Name", User002Msg);
        User.FindFirst();

        AzureADPlanTestLibrary.AssignUserToPlan(User."User Security ID", PlanIds.GetBasicPlanId());

        User.SetRange("User Name", User001Msg);
        User.FindFirst();

        AzureADPlanTestLibrary.AssignUserToPlan(User."User Security ID", PlanIds.GetEssentialPlanId());
        AzureADPlanTestLibrary.AssignUserToPlan(User."User Security ID", PlanIds.GetExternalAccountantPlanId());

        // [THEN] The Plans are visible
        UserCard.OpenView();
        UserCard.GoToRecord(User);

        Assert.IsTrue(UserCard.Plans.First(), 'There is no plans for the user.');
        Assert.IsFalse(UserCard.Plans.Name.Visible(), 'The plans in User card are visible.');

        UserCard.Close();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    local procedure AddUserHelper(UserName: Code[50])
    var
        UserCardPage: TestPage "User Card";
    begin
        UserCardPage.OpenNew();
        UserCardPage."User Name".Value := UserName;
        UserCardPage.Close();
    end;

    local procedure PasswordComplexityHelper(Password: Text; RepeatedPassword: Text; ExpectedError: Text)
    var
        UserCardPage: TestPage "User Card";
    begin
        LastError := '';
        PwToEnter := Password;
        RepPwToEnter := RepeatedPassword;
        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", User001Msg);
        UserCardPage."User Name".AssertEquals(User001Msg);
        Commit();
        UserCardPage.Password.AssistEdit();
        UserCardPage.Close();
        if LastError <> ExpectedError then
            Error(ErrorStringCom002Err, ExpectedError, LastError, LastValidation);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ErrorHandler(Msg: Text)
    begin
        LastError := Msg;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetPasswordHandler(var PasswordDialog: TestPage "Password Dialog")
    begin
        if PwErrorInMain then begin
            asserterror PasswordDialog.Password.Value := PwToEnter;
            LastValidation := GetLastErrorText;
            PasswordDialog.OK().Invoke();
            PasswordDialog.Cancel().Invoke();
            exit;
        end;
        PasswordDialog.Password.Value := PwToEnter;

        if PwErrorInRepeat then begin
            asserterror PasswordDialog.ConfirmPassword.Value := RepPwToEnter;
            LastValidation := GetLastErrorText;
            PasswordDialog.OK().Invoke();
            PasswordDialog.Cancel().Invoke();
            exit;
        end;
        PasswordDialog.ConfirmPassword.Value := RepPwToEnter;

        PasswordDialog.OK().Invoke();
    end;

    [Normal]
    local procedure WebServiceAccessHelper(KeyExpirationDate: DateTime; KeyNeverExpires: Boolean; InvokeCancel: Boolean; UserName: Text)
    var
        UserCardPage: TestPage "User Card";
    begin
        WsNeverExpiresToenter := KeyNeverExpires;
        WsExpirationDateToEnter := KeyExpirationDate;
        WsInvokeCancelToEnter := InvokeCancel;
        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", UserName);
        UserCardPage."User Name".AssertEquals(UserName);

        UserCardPage.WebServiceID.AssistEdit();

        UserCardPage.Close();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetWebServiceAccessHandler(var SetWebServiceAccess: TestPage "Set Web Service Access Key")
    begin
        if WsNeverExpiresToenter then
            SetWebServiceAccess.NeverExpires.SetValue(WsNeverExpiresToenter)
        else
            SetWebServiceAccess.ExpirationDate.SetValue(WsExpirationDateToEnter);

        if WsInvokeCancelToEnter then
            SetWebServiceAccess.Cancel().Invoke()
        else
            SetWebServiceAccess.OK().Invoke();
    end;

    [Normal]
    local procedure AcsAuthenticationHelper(AcsUserName: Text; AcsAuthKey: Text; AcsStatus: Text; ErrorExpected: Boolean; GenerateKey: Boolean)
    var
        UserCardPage: TestPage "User Card";
        WsCompareAcsStatus: Text;
    begin
        AcsUserNameToEnter := AcsUserName;
        AcsAuthKeyToEnter := AcsAuthKey;
        AcsErrorExpected := ErrorExpected;
        AcsGenerateKey := GenerateKey;
        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", AcsUserNameToEnter);
        UserCardPage."User Name".AssertEquals(AcsUserNameToEnter);

        UserCardPage.ACSStatus.AssistEdit();
        WsCompareAcsStatus := UserCardPage.ACSStatus.Value();
        UserCardPage.Close();
        if WsCompareAcsStatus <> AcsStatus then
            Error(ErrorStatusUnexpectedErr);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SetAcsAuthenticationHandler(var SetAcsAuthentication: TestPage "User ACS Setup")
    begin
        if AcsGenerateKey then begin
            SetAcsAuthentication.AuthenticationID.Value := '';
            SetAcsAuthentication."Generate Auth Key".Invoke();
            if SetAcsAuthentication.AuthenticationID.Value = '' then
                Error(ErrorAcsKeyNotGeneratedErr);
            SetAcsAuthentication.OK().Invoke();
            exit;
        end;

        if AcsErrorExpected then begin
            asserterror SetAcsAuthentication.AuthenticationID.Value := AcsAuthKeyToEnter;
            SetAcsAuthentication.OK().Invoke();
            exit;
        end;
        SetAcsAuthentication.AuthenticationID.Value := AcsAuthKeyToEnter;

        SetAcsAuthentication.OK().Invoke();
    end;

    [Normal]
    local procedure ValidAuthenticationEmailHelper(Email: Text; ExpectedEmail: Text)
    var
        UserCardPage: TestPage "User Card";
    begin
        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", User001Msg);
        UserCardPage."User Name".AssertEquals(User001Msg);

        UserCardPage."Authentication Email".Value := Email;
        // Validate field immediately after assigning.
        UserCardPage."Authentication Email".AssertEquals(ExpectedEmail);
        UserCardPage.Close();

        UserCardPage.OpenEdit();
        // Validate field after reopening card.
        UserCardPage.FindFirstField("User Name", User001Msg);
        UserCardPage."User Name".AssertEquals(User001Msg);
        UserCardPage."Authentication Email".AssertEquals(ExpectedEmail);
        UserCardPage.Close();
    end;

    [Normal]
    local procedure InvalidAuthenticationEmailHelper(Email: Text; ExpectedValidationError: Text)
    var
        UserCardPage: TestPage "User Card";
        ValidationError: Text;
    begin
        UserCardPage.OpenEdit();
        UserCardPage.FindFirstField("User Name", User001Msg);
        UserCardPage."User Name".AssertEquals(User001Msg);

        asserterror UserCardPage."Authentication Email".Value := Email;
        ValidationError := UserCardPage.GetValidationError();
        if (ValidationError <> ExpectedValidationError) and (StrPos(ValidationError, ExpectedValidationError) <= 0) then begin
            UserCardPage.Close();
            ValidationError := 'Unexpected validation error: ' + ValidationError + ' Email address: ' + Email;
            Error(ValidationError);
        end;

        UserCardPage.Close();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerAnsYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerAnsNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DisableUserMessageHandler(Message: Text[1024])
    begin
        Assert.ExpectedMessage(DisableUserMsg, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure UserLookupHandler(var UserLookup: TestPage "User Lookup")
    begin
        // Selects user and clicks OK
        UserLookup.FILTER.SetFilter("User Name", LibraryVariableStorage.DequeueText());
        UserLookup.OK().Invoke();
    end;
}
