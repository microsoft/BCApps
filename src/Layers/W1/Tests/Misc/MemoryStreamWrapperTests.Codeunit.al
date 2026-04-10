codeunit 132591 "MemoryStream Wrapper Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [MemoryStream] [UT]
    end;

    var
        Assert: Codeunit Assert;

    [Test]
    [Scope('OnPrem')]
    procedure TestUninitialzed()
    var
        MemoryStreamWrapper: Codeunit "MemoryStream Wrapper";
    begin
        // Exercise and verify
        asserterror MemoryStreamWrapper.AddText('Test');
        Assert.ExpectedError('Cannot create an instance of the following .NET Framework');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPosition()
    var
        MemoryStreamWrapper: Codeunit "MemoryStream Wrapper";
    begin
        // Setup
        MemoryStreamWrapper.Create(20);
        MemoryStreamWrapper.AddText('TestGetPos');

        // Exercise and verify
        Assert.AreEqual(10, MemoryStreamWrapper.GetPosition(), 'GetPosition returned wrong value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestToText()
    var
        MemoryStreamWrapper: Codeunit "MemoryStream Wrapper";
    begin
        // Setup
        MemoryStreamWrapper.Create(10);
        MemoryStreamWrapper.AddText('TestToText');

        // Exercise and verify
        Assert.AreEqual('TestToText', MemoryStreamWrapper.ToText(), 'ToText returned wrong value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestLength()
    var
        MemoryStreamWrapper: Codeunit "MemoryStream Wrapper";
    begin
        // Setup
        MemoryStreamWrapper.Create(20);
        MemoryStreamWrapper.AddText('LengthTest');

        // Exercise and verify
        Assert.AreEqual(10, MemoryStreamWrapper.Length(), 'Length returend wrong value');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetInStream()
    var
        MemoryStreamWrapper: Codeunit "MemoryStream Wrapper";
        InStream: InStream;
        Txt: Text;
    begin
        // Setup
        MemoryStreamWrapper.Create(10);
        MemoryStreamWrapper.AddText('InStreamTest');

        // Exercise
        MemoryStreamWrapper.SetPosition(0);
        MemoryStreamWrapper.GetInStream(InStream);
        InStream.ReadText(Txt);

        // Verify
        Assert.AreEqual('InStreamTest', Txt, 'GetInStream did not return a usable InStream');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReadFrom()
    var
        CompanyInformation: Record "Company Information";
        MemoryStreamWrapper: Codeunit "MemoryStream Wrapper";
        InStream: InStream;
    begin
        // Setup
        CompanyInformation.Get();
        CompanyInformation.CalcFields(Picture);
        CompanyInformation.Picture.CreateInStream(InStream);
        MemoryStreamWrapper.Create(1000);

        // Exercise
        MemoryStreamWrapper.ReadFrom(InStream);

        // Verify
        Assert.AreNotEqual(0, MemoryStreamWrapper.Length(), 'ReadFrom resulted in empty MemoryStream');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCopyTo()
    var
        CompanyInformation: Record "Company Information";
        MemoryStreamWrapper: Codeunit "MemoryStream Wrapper";
        InStream: InStream;
        OutStream: OutStream;
    begin
        // [GIVEN] store picture in MemoryStream
        CompanyInformation.Get();
        CompanyInformation.CalcFields(Picture);
        CompanyInformation.Picture.CreateInStream(InStream);
        MemoryStreamWrapper.Create(1000);
        MemoryStreamWrapper.ReadFrom(InStream);

        // [GIVEN] delete picture
        Clear(CompanyInformation.Picture);
        CompanyInformation.Modify();
        CompanyInformation.CalcFields(Picture);
        Assert.IsFalse(CompanyInformation.Picture.HasValue, 'Precondition failed');

        // [WHEN] copy picture from memory stream
        CompanyInformation.Picture.CreateOutStream(OutStream);
        MemoryStreamWrapper.SetPosition(0);
        MemoryStreamWrapper.CopyTo(OutStream);
        CompanyInformation.Modify();
        CompanyInformation.CalcFields(Picture);

        // Verify
        Assert.IsTrue(CompanyInformation.Picture.HasValue, 'CopyTo failed');
    end;
}

