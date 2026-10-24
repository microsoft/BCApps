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
        LoginErrorWithDeclarationOutputTxt: Label '<?xml version="1.0" encoding="utf-8"?><ADCS><Header UseCaseCode="LOGIN" RunReturn="0" Custom="a&amp;b&lt;c&gt;d&quot;e''f"><Comment>No input Node found.</Comment></Header></ADCS>', Locked = true;
        HelloWithCustomAttributeInputTxt: Label '<?xml version="1.0" encoding="utf-8"?><ADCS><Header UseCaseCode="HELLO" Custom="a&amp;b&lt;c&gt;d&quot;e''f" /></ADCS>', Locked = true;
        LoginWithCustomAttributeOutputTxt: Label '<ADCS><Header UseCaseCode="LOGIN" Custom="a&amp;b&lt;c&gt;d&quot;e''f" StackCode="" RunReturn="0" FormTypeOpt="Card" NoOfLines="4" InputIsHidden="0"><Comment /><Functions><Function>ESC</Function></Functions></Header><Lines><Header><Field Type="Text" MaxLen="7">Welcome</Field></Header><Body><Field FieldID="1" Type="Input" MaxLen="20" Descrip="User ID" /><Field FieldID="2" Type="OutPut" MaxLen="30" Descrip="Password" /></Body></Lines></ADCS>', Locked = true;
        UnexpectedOutputErr: Label 'The ADCS web service response is not identical to the expected response.';

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

    [Test]
    [Scope('OnPrem')]
    procedure LoginMiniformErrorKeepsXmlDeclarationAndEscaping()
    var
        ADCSWS: Codeunit "ADCS WS";
        WideIn: Text;
    begin
        // [SCENARIO] The error response is returned to the handheld exactly as before: the XML declaration of the request is kept, indentation is dropped and special characters stay escaped
        WideIn := LoginErrorWithDeclarationIndentedInputText();

        ADCSWS.ProcessDocument(WideIn);

        Assert.AreEqual(LoginErrorWithDeclarationOutputTxt, WideIn, UnexpectedOutputErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoginMiniformErrorExactOutput()
    var
        ADCSWS: Codeunit "ADCS WS";
        WideIn: Text;
    begin
        // [SCENARIO] The error response is returned to the handheld exactly as before
        WideIn := LoginNoInputNodeErrorInputTxt;

        ADCSWS.ProcessDocument(WideIn);

        Assert.AreEqual(
          '<ADCS><Header UseCaseCode="LOGIN" RunReturn="0"><Comment>No input Node found.</Comment></Header></ADCS>', WideIn, UnexpectedOutputErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LoginMiniformExactOutput()
    var
        ADCSWS: Codeunit "ADCS WS";
        WideIn: Text;
        TempLanguage: Integer;
    begin
        // [SCENARIO] The encoded login miniform is returned to the handheld exactly as before: header attributes are copied in order, empty elements are self-closing and special characters stay escaped
        WideIn := HelloWithCustomAttributeInputTxt;
        TempLanguage := GlobalLanguage;
        GlobalLanguage(1033);

        ADCSWS.ProcessDocument(WideIn);

        GlobalLanguage(TempLanguage);
        Assert.AreEqual(LoginWithCustomAttributeOutputTxt, WideIn, UnexpectedOutputErr);
    end;

    local procedure VerifyXmlNodesAreEqual(Expected: XmlNode; Actual: XmlNode): Boolean
    var
        ExpectedChildren: XmlNodeList;
        ActualChildren: XmlNodeList;
        ExpectedChild: XmlNode;
        ActualChild: XmlNode;
        Index: Integer;
    begin
        if Expected.IsXmlElement() <> Actual.IsXmlElement() then
            exit(false);

        if not Expected.IsXmlElement() then
            exit(VerifyXmlValuesAreDefined(Expected, Actual));

        if Expected.AsXmlElement().Name() <> Actual.AsXmlElement().Name() then
            exit(false);

        if not VerifyXmlAttributesAreEqual(Expected.AsXmlElement(), Actual.AsXmlElement()) then
            exit(false);

        ExpectedChildren := Expected.AsXmlElement().GetChildNodes();
        ActualChildren := Actual.AsXmlElement().GetChildNodes();
        if ExpectedChildren.Count() <> ActualChildren.Count() then
            exit(false);

        for Index := 1 to ExpectedChildren.Count() do begin
            ExpectedChildren.Get(Index, ExpectedChild);
            ActualChildren.Get(Index, ActualChild);
            if not VerifyXmlNodesAreEqual(ExpectedChild, ActualChild) then
                exit(false);
        end;
        exit(true);
    end;

    local procedure VerifyXmlAttributesAreEqual(Expected: XmlElement; Actual: XmlElement): Boolean
    var
        ExpectedAttribute: XmlAttribute;
        ActualAttribute: XmlAttribute;
    begin
        if Expected.Attributes().Count() <> Actual.Attributes().Count() then
            exit(false);

        foreach ExpectedAttribute in Expected.Attributes() do begin
            if not Actual.Attributes().Get(ExpectedAttribute.Name(), ActualAttribute) then
                exit(false);

            // We don't validate the localized values
            if (ExpectedAttribute.Name() <> 'MaxLen') and (ExpectedAttribute.Name() <> 'Descrip') then
                if ExpectedAttribute.Value() <> ActualAttribute.Value() then
                    exit(false);
        end;
        exit(true);
    end;

    local procedure VerifyXmlValuesAreDefined(Expected: XmlNode; Actual: XmlNode): Boolean
    begin
        if Expected.IsXmlText() <> Actual.IsXmlText() then
            exit(false);

        if not Expected.IsXmlText() then
            exit(true);

        // Values are localized, we only verify that they are there
        exit((Expected.AsXmlText().Value() = '') = (Actual.AsXmlText().Value() = ''));
    end;

    local procedure LoginErrorWithDeclarationIndentedInputText(): Text
    var
        CRLF: Text[2];
    begin
        CRLF[1] := 13;
        CRLF[2] := 10;
        exit(
          '<?xml version=''1.0'' encoding="utf-8" ?>' + CRLF +
          '<ADCS>' + CRLF +
          '  <Header UseCaseCode="LOGIN" RunReturn="0" Custom="a&amp;b&lt;c&gt;d&quot;e''f">' + CRLF +
          '    <Comment>Old</Comment>' + CRLF +
          '  </Header>' + CRLF +
          '</ADCS>');
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
        InputXmlDocument: XmlDocument;
        OutputXmlDocument: XmlDocument;
        InputRootElement: XmlElement;
        OutputRootElement: XmlElement;
    begin
        XmlDocument.ReadFrom(InputXml, InputXmlDocument);
        XmlDocument.ReadFrom(OutputXml, OutputXmlDocument);
        InputXmlDocument.GetRoot(InputRootElement);
        OutputXmlDocument.GetRoot(OutputRootElement);

        Assert.IsTrue(
          VerifyXmlNodesAreEqual(OutputRootElement.AsXmlNode(), InputRootElement.AsXmlNode()),
          StrSubstNo('Expected<%1>, Actual<%2>', OutputXml, InputXml));
    end;
}

