codeunit 134894 "Batch. Processing UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Batch Processing]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTextParameter()
    var
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        TextParameter: Text;
        TextParameterTwo: Text;
    begin
        // [FEATURE] [Parameter]
        // [SCENARIO 322727] GetTextParameter

        // [GIVEN] Any Record
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [GIVEN] Text Parameter
        TextParameter := LibraryRandom.RandText(100);
        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Test Text Parameter", TextParameter);

        // [WHEN] Batch Processing Map for any RecRef
        RecRef.GetTable(SalesHeader);
        BatchProcessingMgt.FillBatchProcessingMap(RecRef);

        // [THEN] Text Parameter was set
        BatchProcessingMgt.GetTextParameter(RecRef.RecordId(), Enum::"Batch Posting Parameter Type"::"Test Text Parameter", TextParameterTwo);
        Assert.Equal(TextParameter, TextParameterTwo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTimeParameter()
    var
        SalesHeader: Record "Sales Header";
        RecRef: RecordRef;
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        TimeParameter: Time;
        TimeParameterTwo: Time;
    begin
        // [FEATURE] [Parameter]
        // [SCENARIO 322727] Get TimeParameter

        // [GIVEN] Any Record
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [GIVEN] Time Parameter
        TimeParameter := 115900T;
        BatchProcessingMgt.SetParameter(Enum::"Batch Posting Parameter Type"::"Test Time Parameter", TimeParameter);

        // [WHEN] Batch Processing Map for any RecRef
        RecRef.GetTable(SalesHeader);
        BatchProcessingMgt.FillBatchProcessingMap(RecRef);

        // [THEN] Time Parameter was set
        BatchProcessingMgt.GetTimeParameter(RecRef.RecordId(), Enum::"Batch Posting Parameter Type"::"Test Time Parameter", TimeParameterTwo);
        Assert.Equal(TimeParameter, TimeParameterTwo);
    end;
}