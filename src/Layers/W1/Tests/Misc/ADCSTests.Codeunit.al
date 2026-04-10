codeunit 139010 "ADCS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ADCS] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LoginNoInputNodeErrorInputTxt: Label '<ADCS><Header UseCaseCode="LOGIN" RunReturn="0"/></ADCS>', Locked = true;
        LoginNoInputNodeErrorOutputTxt: Label '<ADCS><Header UseCaseCode="LOGIN" RunReturn="0"><Comment>No input Node found.</Comment></Header></ADCS>', Locked = true;
        IncorrectValueReturnedErr: Label 'Incorrect value returned.';

    [Test]
    [Scope('OnPrem')]
    procedure TestLoginMiniformWithMissingHeader()
    var
        ADCSWS: Codeunit "ADCS WS";
        WideIn: Text;
    begin
        WideIn := '<?xml version=''1.0'' encoding="utf-8" ?><ADCS></ADCS>';

        asserterror ADCSWS.ProcessDocument(WideIn);
        Assert.IsTrue(GetLastErrorText = 'The Node does not exist.', 'Unexpected error message: ' + GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLoginMiniformWithMissingUseCase()
    var
        ADCSWS: Codeunit "ADCS WS";
        WideIn: Text;
    begin
        WideIn := '<?xml version=''1.0'' encoding="utf-8" ?><ADCS><Header InvalidNode="HELLO" /></ADCS>';

        asserterror ADCSWS.ProcessDocument(WideIn);
        Assert.ExpectedErrorCannotFind(Database::"Miniform Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLoginMiniform()
    var
        ADCSWS: Codeunit "ADCS WS";
        WideIn: Text;
        WideOut: Text;
    begin
        WideIn := HelloInputText();
        WideOut := LoginOutputText();

        ADCSWS.ProcessDocument(WideIn);

        VerifyXmlInputOutput(WideIn, WideOut);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLoginMiniformGerman()
    var
        ADCSWS: Codeunit "ADCS WS";
        WideIn: Text;
        WideOut: Text;
        TempLanguage: Integer;
    begin
        WideIn := HelloInputText();
        WideOut := LoginOutputText();

        // Switch to German
        TempLanguage := GlobalLanguage;
        GlobalLanguage(1031);

        ADCSWS.ProcessDocument(WideIn);

        // Revert language
        GlobalLanguage(TempLanguage);

        VerifyXmlInputOutput(WideIn, WideOut);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestADCSUserCalculatePasswordOnSetPassword()
    var
        ADCSUser: Record "ADCS User";
        UserName: Text[50];
        ClearTextPassword: Text[250];
    begin
        ADCSUser.Init();
        ClearTextPassword := CopyStr(Format(CreateGuid()), 1, 30);
        UserName := CopyStr('USER.' + ClearTextPassword, 1, MaxStrLen(ADCSUser.Name));
        ADCSUser.Name := UserName;
        ADCSUser.Password := ClearTextPassword;
        ADCSUser.Validate(Password);
        ADCSUser.Insert(true);

        Assert.AreEqual(ADCSUser.CalculatePassword(CopyStr(ClearTextPassword, 1, 30)), ADCSUser.Password, 'Unexpected password value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestADCSUserCalculatePasswordOnChangePassword()
    var
        ADCSUser: Record "ADCS User";
        UserName: Text[50];
        ClearTextPassword: Text[250];
        FirstPassword: Text[250];
    begin
        ADCSUser.Init();
        ClearTextPassword := CopyStr(Format(CreateGuid()), 1, 27);
        UserName := CopyStr('USER.' + ClearTextPassword, 1, 50);
        ADCSUser.Name := UserName;
        ADCSUser.Password := CopyStr('ONE' + ClearTextPassword, 1, MaxStrLen(ADCSUser.Password));
        ADCSUser.Validate(Password);
        ADCSUser.Insert(true);

        FirstPassword := ADCSUser.Password;

        ClearTextPassword := 'TWO' + ClearTextPassword;
        ADCSUser.Password := CopyStr(ClearTextPassword, 1, MaxStrLen(ADCSUser.Password));
        ADCSUser.Validate(Password);
        ADCSUser.Modify(true);

        Assert.AreNotEqual(FirstPassword, ADCSUser.Password, 'Unexpected password value');
        Assert.AreEqual(ADCSUser.CalculatePassword(CopyStr(ClearTextPassword, 1, 30)), ADCSUser.Password, 'Unexpected password value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestADCSUserRenameFail()
    var
        ADCSUser: Record "ADCS User";
        UserNameSfx: Text[50];
    begin
        UserNameSfx := Format(CreateGuid());
        ADCSUser.Init();
        ADCSUser.Name := CopyStr('USER1.' + UserNameSfx, 1, MaxStrLen(ADCSUser.Name));
        ADCSUser.Password := 'MyPassword';
        ADCSUser.Insert();

        asserterror ADCSUser.Rename(CopyStr('USER2.' + UserNameSfx, 1, MaxStrLen(ADCSUser.Name)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoginMiniformError()
    var
        ADCSWS: Codeunit "ADCS WS";
        WideIn: Text;
    begin
        // [SCENARIO 375826] Send LOGIN header without details and get Error response. No error thrown
        WideIn := LoginNoInputNodeErrorInputTxt;

        ADCSWS.ProcessDocument(WideIn);

        VerifyXmlInputOutput(WideIn, LoginNoInputNodeErrorOutputTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFunctionKeyForLongInputValue()
    var
        ADCSCommunication: Codeunit "ADCS Communication";
        InputValue: Text[250];
    begin
        // [SCENARIO 381268] GetFunctionKey returns 0 when InputValue has max allowed length
        InputValue := PadStr('', MaxStrLen(InputValue), '0');
        Assert.AreEqual(0, ADCSCommunication.GetFunctionKey('', InputValue), IncorrectValueReturnedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFunctionKeyForExistingFunctionGroup()
    var
        MiniformFunctionGroup: Record "Miniform Function Group";
        MiniformFunction: Record "Miniform Function";
        ADCSCommunication: Codeunit "ADCS Communication";
    begin
        // [SCENARIO 381268] GetFunctionKey returns KeyDef of MiniformFunctionGroup when FunctionKey exists
        MiniformFunctionGroup.Init();
        MiniformFunctionGroup.Code := PadStr('', MaxStrLen(MiniformFunctionGroup.Code), '0');
        MiniformFunctionGroup.KeyDef := 2;
        MiniformFunctionGroup.Insert();
        MiniformFunction.Init();
        MiniformFunction."Miniform Code" := PadStr('', MaxStrLen(MiniformFunction."Miniform Code"), '0');
        MiniformFunction."Function Code" := MiniformFunctionGroup.Code;
        MiniformFunction.Insert();
        Assert.AreEqual(
          MiniformFunctionGroup.KeyDef,
          ADCSCommunication.GetFunctionKey(MiniformFunction."Miniform Code", MiniformFunctionGroup.Code),
          IncorrectValueReturnedErr);
    end;

    local procedure VerifyXmlNodesAreEqual(Expected: DotNet XmlNode; Actual: DotNet XmlNode): Boolean
    var
        ExpectedChild: DotNet XmlNode;
        ActualChild: DotNet XmlNode;
    begin
        while true do begin
            if IsNull(Expected) or IsNull(Actual) then
                exit(IsNull(Expected) and IsNull(Actual));

            if Expected.Name <> Actual.Name then
                exit(false);

            if not VerifyXmlAttributesAreEqual(Expected, Actual) then
                exit(false);

            if not VerifyXmlValuesAreDefined(Expected, Actual) then
                exit(false);

            ExpectedChild := Expected.FirstChild;
            ActualChild := Actual.FirstChild;
            while VerifyXmlNodesAreEqual(ExpectedChild, ActualChild) and not IsNull(ExpectedChild) do begin
                ExpectedChild := ExpectedChild.NextSibling;
                ActualChild := ActualChild.NextSibling;
            end;

            if not (IsNull(ExpectedChild) and IsNull(ActualChild)) then
                exit(false);

            Expected := Expected.NextSibling;
            Actual := Actual.NextSibling;
        end;
    end;

    local procedure VerifyXmlAttributesAreEqual(Expected: DotNet XmlNode; Actual: DotNet XmlNode): Boolean
    var
        ExpectedAttribute: DotNet XmlAttribute;
        ActualAttribute: DotNet XmlAttribute;
        Index: Integer;
    begin
        if IsNull(Expected.Attributes) or IsNull(Actual.Attributes) then
            exit(IsNull(Expected.Attributes) and IsNull(Actual.Attributes));

        if Expected.Attributes.Count <> Actual.Attributes.Count then
            exit(false);

        Index := 0;
        while Index < Expected.Attributes.Count - 1 do begin
            ExpectedAttribute := Expected.Attributes.ItemOf(Index);
            ActualAttribute := Actual.Attributes.ItemOf(ExpectedAttribute.Name);

            if IsNull(ActualAttribute) then
                exit(false);

            // We don't validate the localized values
            if (ExpectedAttribute.Name <> 'MaxLen') and (ExpectedAttribute.Name <> 'Descrip') then
                if ExpectedAttribute.Value <> ActualAttribute.Value then
                    exit(false);

            Index += 1;
        end;
        exit(true);
    end;

    local procedure VerifyXmlValuesAreDefined(Expected: DotNet XmlNode; Actual: DotNet XmlNode): Boolean
    begin
        // Values are localized, we only verify that they are there
        if (Expected.Value = '') or (Actual.Value = '') then
            exit((Expected.Value = '') and (Actual.Value = ''));

        exit((Expected.Value <> '') and (Actual.Value <> ''));
    end;

    local procedure HelloInputText(): Text
    begin
        exit('<?xml version=''1.0'' encoding="utf-8" ?><ADCS><Header UseCaseCode="HELLO" /></ADCS>');
    end;

    local procedure LoginOutputText(): Text
    var
        WideOut: Text;
    begin
        WideOut := '<ADCS>';
        WideOut :=
          WideOut + '<Header UseCaseCode="LOGIN" StackCode="" RunReturn="0" FormTypeOpt="Card" NoOfLines="4" InputIsHidden="0">';
        WideOut := WideOut + '<Comment/><Functions><Function>ESC</Function></Functions></Header>';
        WideOut := WideOut + '<Lines><Header><Field Type="Text" MaxLen="7">Welcome</Field></Header><Body>';
        WideOut := WideOut + '<Field FieldID="1" Type="Input" MaxLen="20" Descrip="User ID"/>';
        WideOut := WideOut + '<Field FieldID="2" Type="OutPut" MaxLen="30" Descrip="Password"/>';
        WideOut := WideOut + '</Body></Lines></ADCS>';
        exit(WideOut);
    end;

    local procedure VerifyXmlInputOutput(InputXml: Text; OutputXml: Text)
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        InputXmlDocument: DotNet XmlDocument;
        OutputXmlDocument: DotNet XmlDocument;
    begin
        XMLDOMManagement.LoadXMLDocumentFromText(InputXml, InputXmlDocument);
        XMLDOMManagement.LoadXMLDocumentFromText(OutputXml, OutputXmlDocument);

        Assert.IsTrue(
          VerifyXmlNodesAreEqual(OutputXmlDocument.DocumentElement, InputXmlDocument.DocumentElement),
          StrSubstNo('Expected<%1>, Actual<%2>', OutputXmlDocument.OuterXml, InputXmlDocument.OuterXml));
    end;
}

