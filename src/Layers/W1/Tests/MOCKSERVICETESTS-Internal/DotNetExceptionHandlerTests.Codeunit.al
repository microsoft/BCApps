codeunit 132582 "DotNet Exception Handler Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [DotNet] [UT] [Exception]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        DivideByZeroErr: Label 'Attempted to divide by zero.';
        LoadXmlErr: Label 'Data at the root level is invalid. Line 1, position 1.';
        RandomXmlErr: Label 'Random text was loaded as XML.';
        WebExceptionCollectedErr: Label 'WebException was collected.';
        WrongDivisionErr: Label 'It was possible to divide by zero.';
        XmlExceptionNotCollectedErr: Label 'XmlException was not collected.';

    [Test]
    [Scope('OnPrem')]
    procedure CollectDotNetException()
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
    begin
        // Setup
        Assert.IsFalse(LoadImproperXml(), RandomXmlErr);

        // Exercise
        DotNetExceptionHandler.Collect();

        // Verify
        Assert.ExpectedErrorCode('DotNetInvoke:Xml');
        Assert.ExpectedMessage(LoadXmlErr, DotNetExceptionHandler.GetMessage());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollectNavException()
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
    begin
        // Setup
        Assert.IsFalse(DivideByZero(), WrongDivisionErr);

        // Exercise
        DotNetExceptionHandler.Collect();

        // Verify
        Assert.ExpectedErrorCode('AL:DivideByZero');
        Assert.ExpectedMessage(DivideByZeroErr, DotNetExceptionHandler.GetMessage());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CastDotNetException()
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        XmlException: DotNet "System.Xml.XmlException";
    begin
        // Setup
        Assert.IsFalse(LoadImproperXml(), RandomXmlErr);

        // Exercise
        DotNetExceptionHandler.Collect();
        Assert.IsTrue(DotNetExceptionHandler.CastToType(XmlException, GetDotNetType(XmlException)), XmlExceptionNotCollectedErr);

        // Verify
        Assert.ExpectedErrorCode('DotNetInvoke:Xml');
        Assert.ExpectedMessage(LoadXmlErr, DotNetExceptionHandler.GetMessage());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CastWrongDotNetException()
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        WebException: DotNet WebException;
    begin
        // Setup
        Assert.IsFalse(LoadImproperXml(), RandomXmlErr);

        // Exercise
        DotNetExceptionHandler.Collect();
        Assert.IsFalse(
          DotNetExceptionHandler.CastToType(WebException, GetDotNetType(WebException)),
          WebExceptionCollectedErr);

        // Verify
        Assert.ExpectedErrorCode('DotNetInvoke:Xml');
        Assert.ExpectedMessage(LoadXmlErr, DotNetExceptionHandler.GetMessage());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TryCastDotNetException()
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        XmlException: DotNet "System.Xml.XmlException";
    begin
        // Setup
        Assert.IsFalse(LoadImproperXml(), RandomXmlErr);

        // Exercise
        DotNetExceptionHandler.Collect();
        Assert.IsTrue(DotNetExceptionHandler.TryCastToType(GetDotNetType(XmlException)), XmlExceptionNotCollectedErr);

        // Verify
        Assert.ExpectedErrorCode('DotNetInvoke:Xml');
        Assert.ExpectedMessage(LoadXmlErr, DotNetExceptionHandler.GetMessage());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TryCastWrongDotNetException()
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        WebException: DotNet WebException;
    begin
        // Setup
        Assert.IsFalse(LoadImproperXml(), RandomXmlErr);

        // Exercise
        DotNetExceptionHandler.Collect();
        Assert.IsFalse(DotNetExceptionHandler.TryCastToType(GetDotNetType(WebException)), WebExceptionCollectedErr);

        // Verify
        Assert.ExpectedErrorCode('DotNetInvoke:Xml');
        Assert.ExpectedMessage(LoadXmlErr, DotNetExceptionHandler.GetMessage());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RethrowDotNetException()
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        DotNetExceptionHandler2: Codeunit "DotNet Exception Handler";
        WebException: DotNet WebException;
    begin
        // Setup
        Assert.IsFalse(LoadImproperXml(), RandomXmlErr);

        DotNetExceptionHandler.Collect();
        Assert.IsFalse(DotNetExceptionHandler.TryCastToType(GetDotNetType(WebException)), WebExceptionCollectedErr);

        // Exercise
        asserterror DotNetExceptionHandler.Rethrow();
        DotNetExceptionHandler2.Collect();

        // Verify
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedMessage(LoadXmlErr, DotNetExceptionHandler2.GetMessage());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CatchDotNetException()
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        XmlException: DotNet "System.Xml.XmlException";
    begin
        // Setup
        Assert.IsFalse(LoadImproperXml(), RandomXmlErr);

        // Exercise
        DotNetExceptionHandler.Catch(XmlException, GetDotNetType(XmlException));

        // Verify
        Assert.ExpectedErrorCode('DotNetInvoke:Xml');
        Assert.ExpectedMessage(LoadXmlErr, DotNetExceptionHandler.GetMessage());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CatchWrongDotNetException()
    var
        DotNetExceptionHandler: Codeunit "DotNet Exception Handler";
        WebException: DotNet WebException;
    begin
        // Setup
        Assert.IsFalse(LoadImproperXml(), RandomXmlErr);

        // Exercise
        asserterror DotNetExceptionHandler.Catch(WebException, GetDotNetType(WebException));

        // Verify
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedMessage(LoadXmlErr, DotNetExceptionHandler.GetMessage());
    end;

    [TryFunction]
    local procedure DivideByZero()
    var
        Zero: Integer;
    begin
        // The ModernDev compiler prevents division by 0 at compile time.
        // We need to use a variable to trick the compiler into allowing it.
        Zero := 0;
        Message(Format(1 / Zero));
    end;

    [TryFunction]
    local procedure LoadImproperXml()
    var
        XMLDOMManagement: Codeunit "XML DOM Management";
        XmlDoc: DotNet XmlDocument;
    begin
        XMLDOMManagement.LoadXMLDocumentFromText(LibraryUtility.GenerateRandomXMLText(1024), XmlDoc);
    end;
}

