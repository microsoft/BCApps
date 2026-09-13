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
}
