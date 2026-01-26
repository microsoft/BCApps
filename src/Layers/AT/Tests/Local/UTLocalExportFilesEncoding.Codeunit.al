codeunit 144062 "UT Local Export Files Encoding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        StringContainsErr: Label 'The specified substring=''%2'' did not occur within this string=''%1''.';

    [Test]
    [HandlerFunctions('VATStmtATRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VATStatementFDFFileEncoding()
    var
        FdfFileName: Text;
    begin
        // [FEATURE] [UT] [VAT Statement]
        // [SCENARIO 166131] VAT Statement report exports country specific symbols with correct encoding to FDF file
        Initialize();

        // [GIVEN] Company information address contains country specific symbols
        SetCompanyInformationAddress('ÄäÜüöÖß');

        // [WHEN] VAT Statement AT report run
        RunVATStatementAT(FdfFileName);

        // [THEN] Created fdf file contains country specific symbols in correct encoding
        VerifyFDFLineValue(FdfFileName, 'Text05', GetCompanyInformationAddress());
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Company Information");
        IsInitialized := true;
        Commit();
    end;

    local procedure AssertStringContains(String: Text; SubString: Text)
    begin
        Assert.IsTrue(StrPos(String, SubString) > 0, StrSubstNo(StringContainsErr, String, SubString));
    end;

    local procedure GetCompanyInformationAddress(): Text[50]
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        exit(CompanyInformation.Address);
    end;

    local procedure PrepareVATStatementFiles(var FdfFileName: Text; var XmlFileName: Text)
    var
        FileMgt: Codeunit "File Management";
    begin
        FdfFileName := FileMgt.ServerTempFileName('fdf');
        XmlFileName := FileMgt.ServerTempFileName('xml');
    end;

    local procedure RunVATStatementAT(var FdfFileName: Text)
    var
        VATStatementAT: Report "VAT Statement AT";
        XmlFileName: Text;
    begin
        LibraryVariableStorage.Enqueue(WorkDate());
        PrepareVATStatementFiles(FdfFileName, XmlFileName);

        VATStatementAT.InitializeRequest(FdfFileName, XmlFileName);
        Commit();
        VATStatementAT.RunModal();
    end;

    local procedure SetCompanyInformationAddress(NewAddress: Text[50])
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.Address := NewAddress;
        CompanyInformation.Modify();
    end;

    local procedure VerifyFDFLineValue(FdfFileName: Text; Argument: Text; ExpectedValue: Text)
    var
        FDFFileHelper: Codeunit FDFFileHelper;
        ActualValue: Text;
    begin
        FDFFileHelper.ReadFdfFile(FdfFileName);
        ActualValue := FDFFileHelper.GetValue(Argument);
        AssertStringContains(ActualValue, ExpectedValue);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VATStmtATRequestPageHandler(var VATStatementAT: TestRequestPage "VAT Statement AT")
    var
        Variables: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variables);
        VATStatementAT.StartingDate.SetValue(Variables);
        VATStatementAT.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Msg: Text[1024])
    begin
    end;
}

