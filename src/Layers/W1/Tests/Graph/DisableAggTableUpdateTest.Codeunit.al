codeunit 138927 "Disable Agg. Table Update Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Disable]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        DisableAggTableUpdateTest: Codeunit "Disable Agg. Table Update Test";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SetDisableAllRecords()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        DisableAggregateTableUpdate: Codeunit "Disable Aggregate Table Update";
    begin
        // [SCENARIO] SetDisableAllRecords disables all aggregate table updates
        Initialize();

        // [GIVEN] Purchase Line for Order 'X with PurchaseOrderEntityBuffer, where "Completely Received" is 'No'
        CreatePurchLine(PurchaseLine, PurchaseOrderEntityBuffer);

        // [GIVEN] SetDisableAllRecords
        DisableAggregateTableUpdate.SetDisableAllRecords(true);
        BindSubscription(DisableAggregateTableUpdate);

        // [WHEN] Modify purchase line (to trigger DisableAggregateTableUpdate.OnGetAggregateTablesUpdateEnabled)
        PurchaseLine.Modify(true);

        // [THEN] buffer is not updated
        PurchaseOrderEntityBuffer.Find();
        PurchaseOrderEntityBuffer.TestField("Completely Received", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetAggregateTableIDDisabled()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        DisableAggregateTableUpdate: Codeunit "Disable Aggregate Table Update";
    begin
        // [SCENARIO] SetAggregateTableIDDisabled (without SetTableSystemIDDisabled) does not disable aggregate table updates
        Initialize();

        // [GIVEN] Purchase Line for Order 'X with PurchaseOrderEntityBuffer, where "Completely Received" is 'No'
        CreatePurchLine(PurchaseLine, PurchaseOrderEntityBuffer);

        // [GIVEN] SetAggregateTableIDDisabled for "Purchase Order Entity Buffer"
        DisableAggregateTableUpdate.SetAggregateTableIDDisabled(Database::"Purchase Order Entity Buffer");
        BindSubscription(DisableAggregateTableUpdate);

        // [WHEN] Modify purchase line (to trigger DisableAggregateTableUpdate.OnGetAggregateTablesUpdateEnabled)
        PurchaseLine.Modify(true);

        // [THEN] Buffer is updated (as SetTableSystemIDDisabled is not called)
        PurchaseOrderEntityBuffer.Find();
        PurchaseOrderEntityBuffer.TestField("Completely Received", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetTableSystemIDDisabled()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        DisableAggregateTableUpdate: Codeunit "Disable Aggregate Table Update";
    begin
        // [SCENARIO] SetTableSystemIDDisabled (without SetAggregateTableIDDisabled) does not disable aggregate table updates
        Initialize();

        // [GIVEN] Purchase Line for Order 'X with PurchaseOrderEntityBuffer, where "Completely Received" is 'No'
        CreatePurchLine(PurchaseLine, PurchaseOrderEntityBuffer);

        // [GIVEN] SetTableSystemIDDisabled for Purchase Line
        DisableAggregateTableUpdate.SetTableSystemIDDisabled(PurchaseLine.SystemId);
        BindSubscription(DisableAggregateTableUpdate);

        // [WHEN] Modify purchase line (to trigger DisableAggregateTableUpdate.OnGetAggregateTablesUpdateEnabled)
        PurchaseLine.Modify(true);

        // [THEN] Buffer is updated (as SetAggregateTableIDDisabled is not called)
        PurchaseOrderEntityBuffer.Find();
        PurchaseOrderEntityBuffer.TestField("Completely Received", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SetTableSystemIDDisabledWithSetAggregateTableIDDisabled()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer";
        DisableAggregateTableUpdate: Codeunit "Disable Aggregate Table Update";
    begin
        // [SCENARIO] SetTableSystemIDDisabled with SetAggregateTableIDDisabled disable one record update in aggregate table
        Initialize();

        // [GIVEN] Purchase Line for Order 'X with PurchaseOrderEntityBuffer, where "Completely Received" is 'No'
        CreatePurchLine(PurchaseLine, PurchaseOrderEntityBuffer);

        // [GIVEN] SetAggregateTableIDDisabled for "Purchase Order Entity Buffer"
        DisableAggregateTableUpdate.SetAggregateTableIDDisabled(Database::"Purchase Order Entity Buffer");
        // [GIVEN] SetTableSystemIDDisabled for Purchase Line
        DisableAggregateTableUpdate.SetTableSystemIDDisabled(PurchaseLine.SystemId);
        BindSubscription(DisableAggregateTableUpdate);

        // [WHEN] Modify purchase line (to trigger DisableAggregateTableUpdate.OnGetAggregateTablesUpdateEnabled)
        PurchaseLine.Modify(true);

        // [THEN] Buffer is not updated
        PurchaseOrderEntityBuffer.Find();
        PurchaseOrderEntityBuffer.TestField("Completely Received", false);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        BindSubscription(DisableAggTableUpdateTest); // to set IsAPIEnabled

        IsInitialized := true;
    end;

    local procedure CreatePurchLine(var PurchaseLine: Record "Purchase Line"; var PurchaseOrderEntityBuffer: Record "Purchase Order Entity Buffer")
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine."Document No." := LibraryUtility.GenerateGUID();
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Insert();

        PurchaseOrderEntityBuffer."No." := PurchaseLine."Document No.";
        PurchaseOrderEntityBuffer.Id := PurchaseLine.SystemId;
        PurchaseOrderEntityBuffer."Completely Received" := false;
        PurchaseOrderEntityBuffer.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'OnGetIsAPIEnabled', '', false, false)]
    local procedure HandleOnGetIsAPIEnabled(var Handled: Boolean; var IsAPIEnabled: Boolean)
    begin
        Handled := true;
        IsAPIEnabled := true;
    end;
}