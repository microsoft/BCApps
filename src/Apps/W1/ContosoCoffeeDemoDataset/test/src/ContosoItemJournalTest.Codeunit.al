namespace Microsoft.Test.DemoTool;

using Microsoft.DemoData.Foundation;
using Microsoft.DemoData.Inventory;
using Microsoft.DemoTool.Helpers;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Journal;

codeunit 148451 "Contoso Item Journal Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CreateItemJournalTemplate: Codeunit "Create Item Journal Template";
        ContosoUtilities: Codeunit "Contoso Utilities";

    [Test]
    procedure ItemJournalSetupCreatesDefaultBatch()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        CreateNoSeries: Codeunit "Create No. Series";
    begin
        // [SCENARIO] Inventory setup creates its own default batch without other modules.
        Initialize();

        // [WHEN] The item journal template producer runs with no existing template or batch.
        Codeunit.Run(Codeunit::"Create Item Journal Template");

        // [THEN] The template and localized default batch exist, without copying template numbering to the batch.
        ItemJournalTemplate.Get(CreateItemJournalTemplate.ItemJournalTemplate());
        ItemJournalTemplate.TestField("No. Series", CreateNoSeries.ItemJournal());
        ItemJournalBatch.Get(CreateItemJournalTemplate.ItemJournalTemplate(), ContosoUtilities.GetDefaultBatchNameLbl());
        ItemJournalBatch.TestField(Description, '');
        ItemJournalBatch.TestField("No. Series", '');
        ItemJournalBatch.TestField("Posting No. Series", '');
    end;

    [Test]
    procedure ItemJournalSetupCreatesMissingBatchForExistingTemplate()
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        // [SCENARIO] An existing template does not prevent the producer from creating its missing batch.
        Initialize();
        ItemJournalTemplate.Validate(Name, CreateItemJournalTemplate.ItemJournalTemplate());
        ItemJournalTemplate.Validate(Description, 'Existing item journal');
        ItemJournalTemplate.Insert(true);

        // [WHEN] The item journal template producer runs.
        Codeunit.Run(Codeunit::"Create Item Journal Template");

        // [THEN] The batch exists and the existing template is unchanged.
        ItemJournalBatch.Get(CreateItemJournalTemplate.ItemJournalTemplate(), ContosoUtilities.GetDefaultBatchNameLbl());
        ItemJournalTemplate.Get(CreateItemJournalTemplate.ItemJournalTemplate());
        ItemJournalTemplate.TestField(Description, 'Existing item journal');
    end;

    [Test]
    procedure ItemJournalSetupPreservesExistingBatchOnRepeatedExecution()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ExistingItemJournalBatch: Record "Item Journal Batch";
        LibraryUtility: Codeunit "Library - Utility";
        CreateNoSeries: Codeunit "Create No. Series";
    begin
        // [SCENARIO] Repeated producer execution preserves a customized default batch.
        Initialize();
        Codeunit.Run(Codeunit::"Create Item Journal Template");
        ItemJournalBatch.Get(CreateItemJournalTemplate.ItemJournalTemplate(), ContosoUtilities.GetDefaultBatchNameLbl());
        ItemJournalBatch.Validate(Description, 'Keep existing batch settings');
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Validate("Posting No. Series", CreateNoSeries.ItemJournal());
        ItemJournalBatch.Validate("Item Tracking on Lines", true);
        ItemJournalBatch.Modify(true);
        ExistingItemJournalBatch := ItemJournalBatch;

        // [WHEN] The producer runs again, including a subsequent repeated execution.
        Codeunit.Run(Codeunit::"Create Item Journal Template");
        Codeunit.Run(Codeunit::"Create Item Journal Template");

        // [THEN] The same batch retains its description, numbering and tracking settings.
        ItemJournalBatch.Get(CreateItemJournalTemplate.ItemJournalTemplate(), ContosoUtilities.GetDefaultBatchNameLbl());
        Assert.AreEqual(ExistingItemJournalBatch.SystemId, ItemJournalBatch.SystemId, 'The existing batch must not be replaced.');
        ItemJournalBatch.TestField(Description, ExistingItemJournalBatch.Description);
        ItemJournalBatch.TestField("No. Series", ExistingItemJournalBatch."No. Series");
        ItemJournalBatch.TestField("Posting No. Series", ExistingItemJournalBatch."Posting No. Series");
        ItemJournalBatch.TestField("Item Tracking on Lines", ExistingItemJournalBatch."Item Tracking on Lines");
    end;

    [Test]
    procedure SerialNumberSeriesWithSNPrefixHasDistinctDescription()
    var
        NoSeries: Record "No. Series";
        CreateNoSeries: Codeunit "Create No. Series";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Newly generated serial series identifies its SN prefix in English.
        Initialize();

        // [GIVEN] Neither serial series nor its lines exist.
        DeleteSerialNumberSeries();

        // [WHEN] The real number series producer runs in English.
        RunNoSeriesProducerInEnglish();

        // [THEN] The SN series has the requested serial-number description.
        NoSeries.Get(CreateNoSeries.SNNumbering1());
        Assert.AreEqual('Serial Nos. - SN Prefix', NoSeries.Description, 'SN1 must identify the SN serial-number prefix.');
    end;

    [Test]
    procedure SerialNumberSeriesWithXYZPrefixHasDistinctDescription()
    var
        NoSeries: Record "No. Series";
        CreateNoSeries: Codeunit "Create No. Series";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Newly generated serial series identifies its XYZ prefix in English.
        Initialize();

        // [GIVEN] Neither serial series nor its lines exist.
        DeleteSerialNumberSeries();

        // [WHEN] The real number series producer runs in English.
        RunNoSeriesProducerInEnglish();

        // [THEN] The XYZ series has the requested serial-number description.
        NoSeries.Get(CreateNoSeries.SNNumbering2());
        Assert.AreEqual('Serial Nos. - XYZ Prefix', NoSeries.Description, 'SN2 must identify the XYZ serial-number prefix.');
    end;

    [Test]
    procedure SerialNumberSeriesWithSNPrefixRetainsNumbering()
    var
        CreateNoSeries: Codeunit "Create No. Series";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] The SN serial series retains its range, settings and generated numbers.
        Initialize();

        // [GIVEN] Neither serial series nor its lines exist.
        DeleteSerialNumberSeries();

        // [WHEN] The real number series producer creates fresh series and sequences.
        Codeunit.Run(Codeunit::"Create No. Series");

        // [THEN] SN numbering starts at one, increments by one and retains its setup.
        VerifySerialNumbering(CreateNoSeries.SNNumbering1(), 'SN1', 'SN00001', 'SN00002', 'SN99999');
    end;

    [Test]
    procedure SerialNumberSeriesWithXYZPrefixRetainsNumbering()
    var
        CreateNoSeries: Codeunit "Create No. Series";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] The XYZ serial series retains its range, settings and generated numbers.
        Initialize();

        // [GIVEN] Neither serial series nor its lines exist.
        DeleteSerialNumberSeries();

        // [WHEN] The real number series producer creates fresh series and sequences.
        Codeunit.Run(Codeunit::"Create No. Series");

        // [THEN] XYZ numbering starts at one, increments by one and retains its setup.
        VerifySerialNumbering(CreateNoSeries.SNNumbering2(), 'SN2', 'XYZ00001', 'XYZ00002', 'XYZ99999');
    end;

    [Test]
    procedure SerialNumberSeriesPreserveCustomizationsOnRepeatedExecution()
    var
        FirstNoSeries: Record "No. Series";
        SecondNoSeries: Record "No. Series";
        FirstNoSeriesLine: Record "No. Series Line";
        SecondNoSeriesLine: Record "No. Series Line";
        CreateNoSeries: Codeunit "Create No. Series";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Repeated producer execution preserves both customized serial series and lines.
        Initialize();

        // [GIVEN] Two serial series have custom descriptions, flags and numbering lines.
        DeleteSerialNumberSeries();
        Codeunit.Run(Codeunit::"Create No. Series");
        CustomizeSerialNumberSeries(CreateNoSeries.SNNumbering1(), 'Keep first serial series', false, true, FirstNoSeries, FirstNoSeriesLine);
        CustomizeSerialNumberSeries(CreateNoSeries.SNNumbering2(), 'Keep second serial series', true, false, SecondNoSeries, SecondNoSeriesLine);

        // [WHEN] The real producer runs twice more without overwriting existing data.
        Codeunit.Run(Codeunit::"Create No. Series");
        Codeunit.Run(Codeunit::"Create No. Series");

        // [THEN] Both original records and every customized numbering setting are retained.
        VerifySerialNumberSeriesPreserved(FirstNoSeries, FirstNoSeriesLine);
        VerifySerialNumberSeriesPreserved(SecondNoSeries, SecondNoSeriesLine);
    end;

    local procedure Initialize()
    var
        SourceCodeSetup: Record "Source Code Setup";
        NoSeries: Record "No. Series";
        ItemJournalTemplate: Record "Item Journal Template";
        CreateNoSeries: Codeunit "Create No. Series";
    begin
        if not SourceCodeSetup.Get() then
            SourceCodeSetup.Insert();

        if not NoSeries.Get(CreateNoSeries.ItemJournal()) then begin
            NoSeries.Validate(Code, CreateNoSeries.ItemJournal());
            NoSeries.Insert(true);
        end;

        if ItemJournalTemplate.Get(CreateItemJournalTemplate.ItemJournalTemplate()) then
            ItemJournalTemplate.Delete(true);
    end;

    local procedure DeleteSerialNumberSeries()
    var
        CreateNoSeries: Codeunit "Create No. Series";
    begin
        DeleteNoSeries(CreateNoSeries.SNNumbering1());
        DeleteNoSeries(CreateNoSeries.SNNumbering2());
    end;

    local procedure DeleteNoSeries(NoSeriesCode: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        NoSeriesLine.DeleteAll(true);
        if NoSeries.Get(NoSeriesCode) then
            NoSeries.Delete(true);
    end;

    local procedure RunNoSeriesProducerInEnglish()
    var
        PreviousLanguage: Integer;
    begin
        PreviousLanguage := GlobalLanguage();
        GlobalLanguage(1033);
        Codeunit.Run(Codeunit::"Create No. Series");
        GlobalLanguage(PreviousLanguage);
    end;

    local procedure VerifySerialNumbering(NoSeriesCode: Code[20]; ExpectedCode: Code[20]; FirstNo: Code[20]; SecondNo: Code[20]; EndingNo: Code[20])
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesManagement: Codeunit "No. Series";
    begin
        Assert.AreEqual(ExpectedCode, NoSeriesCode, 'The serial series code must remain unchanged.');
        NoSeries.Get(NoSeriesCode);
        Assert.AreEqual(true, NoSeries."Default Nos.", 'Default numbering must remain enabled.');
        Assert.AreEqual(true, NoSeries."Manual Nos.", 'Manual numbering must remain enabled.');
        NoSeriesLine.SetRange("Series Code", NoSeriesCode);
        Assert.AreEqual(1, NoSeriesLine.Count(), 'A fresh serial series must have exactly one line.');
        NoSeriesLine.Get(NoSeriesCode, 10000);
        Assert.AreEqual(FirstNo, NoSeriesLine."Starting No.", 'The starting number must remain unchanged.');
        Assert.AreEqual(EndingNo, NoSeriesLine."Ending No.", 'The ending number must remain unchanged.');
        Assert.AreEqual('', NoSeriesLine."Warning No.", 'The serial series must not introduce a warning number.');
        Assert.AreEqual(1, NoSeriesLine."Increment-by No.", 'The serial series must increment by one.');
        Assert.AreEqual(Enum::"No. Series Implementation"::Sequence, NoSeriesLine.Implementation, 'The serial series must use a sequence.');
        Assert.AreEqual(FirstNo, NoSeriesManagement.GetNextNo(NoSeriesCode), 'The first generated serial number must match the configured prefix and start.');
        Assert.AreEqual(SecondNo, NoSeriesManagement.GetNextNo(NoSeriesCode), 'The second generated serial number must increment the first.');
    end;

    local procedure CustomizeSerialNumberSeries(NoSeriesCode: Code[20]; Description: Text[100]; DefaultNos: Boolean; ManualNos: Boolean; var NoSeries: Record "No. Series"; var NoSeriesLine: Record "No. Series Line")
    begin
        NoSeries.Get(NoSeriesCode);
        NoSeries.Validate(Description, Description);
        NoSeries.Validate("Default Nos.", DefaultNos);
        NoSeries.Validate("Manual Nos.", ManualNos);
        NoSeries.Validate("Date Order", true);
        NoSeries.Modify(true);
        NoSeriesLine.Get(NoSeriesCode, 10000);
        NoSeriesLine.Validate(Implementation, Enum::"No. Series Implementation"::Normal);
        NoSeriesLine.Validate("Starting No.", 'CUSTOM00010');
        NoSeriesLine.Validate("Ending No.", 'CUSTOM00090');
        NoSeriesLine.Validate("Warning No.", 'CUSTOM00080');
        NoSeriesLine.Validate("Increment-by No.", 10);
        NoSeriesLine.Validate("Last No. Used", 'CUSTOM00020');
        NoSeriesLine.Validate("Starting Date", WorkDate());
        NoSeriesLine.Validate("Last Date Used", WorkDate());
        NoSeriesLine.Modify(true);
    end;

    local procedure VerifySerialNumberSeriesPreserved(ExpectedNoSeries: Record "No. Series"; ExpectedNoSeriesLine: Record "No. Series Line")
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        NoSeries.Get(ExpectedNoSeries.Code);
        Assert.AreEqual(ExpectedNoSeries.SystemId, NoSeries.SystemId, 'The customized series must not be replaced.');
        Assert.AreEqual(ExpectedNoSeries.Description, NoSeries.Description, 'The custom description must be preserved.');
        Assert.AreEqual(ExpectedNoSeries."Default Nos.", NoSeries."Default Nos.", 'The custom default numbering flag must be preserved.');
        Assert.AreEqual(ExpectedNoSeries."Manual Nos.", NoSeries."Manual Nos.", 'The custom manual numbering flag must be preserved.');
        Assert.AreEqual(ExpectedNoSeries."Date Order", NoSeries."Date Order", 'The custom date order flag must be preserved.');
        NoSeriesLine.Get(ExpectedNoSeriesLine."Series Code", ExpectedNoSeriesLine."Line No.");
        Assert.AreEqual(ExpectedNoSeriesLine.SystemId, NoSeriesLine.SystemId, 'The customized line must not be replaced.');
        Assert.AreEqual(ExpectedNoSeriesLine."Starting No.", NoSeriesLine."Starting No.", 'The custom starting number must be preserved.');
        Assert.AreEqual(ExpectedNoSeriesLine."Ending No.", NoSeriesLine."Ending No.", 'The custom ending number must be preserved.');
        Assert.AreEqual(ExpectedNoSeriesLine."Warning No.", NoSeriesLine."Warning No.", 'The custom warning number must be preserved.');
        Assert.AreEqual(ExpectedNoSeriesLine."Increment-by No.", NoSeriesLine."Increment-by No.", 'The custom increment must be preserved.');
        Assert.AreEqual(ExpectedNoSeriesLine.Implementation, NoSeriesLine.Implementation, 'The custom implementation must be preserved.');
        Assert.AreEqual(ExpectedNoSeriesLine."Last No. Used", NoSeriesLine."Last No. Used", 'The last used number must be preserved.');
        Assert.AreEqual(ExpectedNoSeriesLine."Starting Date", NoSeriesLine."Starting Date", 'The starting date must be preserved.');
        Assert.AreEqual(ExpectedNoSeriesLine."Last Date Used", NoSeriesLine."Last Date Used", 'The last used date must be preserved.');
    end;
}
