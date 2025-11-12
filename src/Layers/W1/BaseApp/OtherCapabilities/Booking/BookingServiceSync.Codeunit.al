namespace Microsoft.Booking;

using Microsoft.Inventory.Item;
using System.IO;

codeunit 6705 "Booking Service Sync."
{
    trigger OnRun()
    var
        LocalBookingSync: Record "Booking Sync";
    begin
        LocalBookingSync.SetRange("Sync Services", true);
        LocalBookingSync.SetRange(Enabled, true);
        if LocalBookingSync.FindFirst() then
            O365SyncManagement.SyncBookingServices(LocalBookingSync);
    end;

    var
        TempItem: Record Item temporary;
        TempBookingServiceMapping: Record "Booking Service Mapping" temporary;
        O365SyncManagement: Codeunit "O365 Sync. Management";

        ProcessNavServiceItemsMsg: Label 'Processing service items.';
        ProcessBookingServicesMsg: Label 'Processing Booking services from Exchange.';
        RetrieveBookingServicesMsg: Label 'Retrieving Booking services from Exchange.';
        CreateBookingServiceTxt: Label 'Create Booking service.';
        CreateNavItemTxt: Label 'Create service item.';
        BookingsCountTelemetryTxt: Label 'Retrieved %1 Bookings Services for synchronization.', Locked = true;
        LocalCountTelemetryTxt: Label 'Synchronizing %1 items to Bookings.', Locked = true;

    procedure SyncRecords(var BookingSync: Record "Booking Sync")
    begin
        O365SyncManagement.ShowProgress(RetrieveBookingServicesMsg);
        GetBookingServices(BookingSync);
        Session.LogMessage('0000ACJ', StrSubstNo(BookingsCountTelemetryTxt, TempItem.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());

        O365SyncManagement.ShowProgress(ProcessNavServiceItemsMsg);
        ProcessNavServices(BookingSync);

        O365SyncManagement.ShowProgress(ProcessBookingServicesMsg);
        ProcessBookingServices(BookingSync);

        O365SyncManagement.CloseProgress();

        BookingSync."Last Service Sync" := CreateDateTime(Today, Time);
        BookingSync.Modify(true);
    end;

    procedure GetRequestParameters(var BookingSync: Record "Booking Sync"): Text
    var
        LocalItem: Record Item;
        FilterPage: FilterPageBuilder;
        FilterText: Text;
        ItemTxt: Text;
    begin
        FilterText := BookingSync.GetItemFilter();

        ItemTxt := LocalItem.TableCaption();
        FilterPage.PageCaption := ItemTxt;
        FilterPage.AddTable(ItemTxt, DATABASE::Item);

        if FilterText <> '' then
            FilterPage.SetView(ItemTxt, FilterText);

        FilterPage.ADdField(ItemTxt, LocalItem."Base Unit of Measure");
        FilterPage.ADdField(ItemTxt, LocalItem."Gen. Prod. Posting Group");
        FilterPage.ADdField(ItemTxt, LocalItem."Tax Group Code");
        FilterPage.ADdField(ItemTxt, LocalItem."Inventory Posting Group");

        if FilterPage.RunModal() then
            FilterText := FilterPage.GetView(ItemTxt);

        if FilterText <> '' then begin
            BookingSync.SaveItemFilter(FilterText);
            BookingSync.Modify(true);
        end;

        exit(FilterText);
    end;

    local procedure GetBookingServices(BookingSync: Record "Booking Sync")
    var
        BookingService: Record "Booking Service";
        Counter: BigInteger;
    begin
        TempItem.Reset();
        TempItem.DeleteAll();
        TempBookingServiceMapping.Reset();
        TempBookingServiceMapping.DeleteAll();

        if BookingService.FindSet() then
            repeat
                Counter += 1;
                Clear(TempItem);
                TempItem.Init();
                TempItem."No." := Format(Counter);

                if not TransferBookingServiceToNavServiceNoValidate(BookingService, TempItem) then
                    O365SyncManagement.LogActivityFailed(BookingSync.RecordId, BookingSync."User ID",
                      CreateNavItemTxt, BookingService."Display Name")
                else begin
                    TempItem.Insert();
                    TempBookingServiceMapping.Map(TempItem."No.", BookingService."Service ID", BookingSync."Booking Mailbox Address");
                end;
            until BookingService.Next() = 0;

        Clear(BookingService);
    end;

    local procedure ProcessNavServices(var BookingSync: Record "Booking Sync")
    var
        Item: Record Item;
    begin
        BuildNavItemFilter(Item, BookingSync);
        Item.SetFilter("Last DateTime Modified", '>=%1', BookingSync."Last Service Sync");
        ProcessNavServiceRecordSet(Item, BookingSync);
    end;

    local procedure ProcessBookingServices(var BookingSync: Record "Booking Sync")
    begin
        TempItem.Reset();
        TempItem.SetFilter("Last DateTime Modified", '>=%1', BookingSync."Last Service Sync");
        ProcessBookingServiceRecordSet(TempItem, BookingSync);
    end;

    [TryFunction]
    local procedure TransferBookingServiceToNavServiceNoValidate(var BookingService: Record "Booking Service"; var NavServiceItem: Record Item)
    begin
        NavServiceItem.Type := NavServiceItem.Type::Service;
        NavServiceItem."Unit Price" := BookingService.Price;
        NavServiceItem.Description := BookingService."Display Name";

        NavServiceItem."Last DateTime Modified" := BookingService."Last Modified Time";
    end;

    local procedure BuildNavItemFilter(var Item: Record Item; var BookingSync: Record "Booking Sync")
    begin
        Item.SetView(BookingSync.GetItemFilter());
        Item.SetRange(Type, Item.Type::Service);
    end;

    local procedure ProcessNavServiceRecordSet(var Item: Record Item; var BookingSync: Record "Booking Sync")
    var
        BookingService: Record "Booking Service";
        LocalBookingService: Record "Booking Service";
        BookingServiceMapping: Record "Booking Service Mapping";
    begin
        if Item.FindSet() then
            repeat
                TempItem.Reset();

                if not TransferNavServiceToBookingService(Item, BookingService, BookingSync."Booking Mailbox Address") then
                    O365SyncManagement.LogActivityFailed(BookingSync.RecordId, BookingSync."User ID",
                      CreateBookingServiceTxt, BookingService."Display Name")
                else
                    if FindNavServiceInBookings(Item."No.", BookingSync."Booking Mailbox Address") then
                        BookingService.Modify(true)
                    else begin
                        Clear(LocalBookingService);
                        LocalBookingService.SetRange("Display Name", Item.Description);
                        if LocalBookingService.FindFirst() then
                            O365SyncManagement.LogActivityFailed(BookingSync.RecordId, BookingSync."User ID",
                              CreateBookingServiceTxt, BookingService."Display Name")
                        else begin
                            BookingService.Insert(true);
                            BookingService.Get(BookingService."Display Name");
                            BookingServiceMapping.Map(Item."No.", BookingService."Service ID", BookingSync."Booking Mailbox Address");
                        end;
                    end;
            until Item.Next() = 0;
    end;

    local procedure ProcessBookingServiceRecordSet(var LocalItem: Record Item; var BookingSync: Record "Booking Sync")
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        BookingServiceMapping: Record "Booking Service Mapping";
        Item: Record Item;
        ConfigTemplateManagement: Codeunit "Config. Template Management";
        ItemRecRef: RecordRef;
        Found: Boolean;
    begin
        if LocalItem.FindSet() then begin
            Session.LogMessage('0000ACK', StrSubstNo(LocalCountTelemetryTxt, LocalItem.Count()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', O365SyncManagement.TraceCategory());
            repeat
                Clear(Item);
                Found := FindBookingServiceInNav(LocalItem, Item);

                if not TransferBookingServiceToNavService(LocalItem, Item, TempBookingServiceMapping."Service ID", BookingSync) then
                    O365SyncManagement.LogActivityFailed(BookingSync.RecordId, BookingSync."User ID", CreateNavItemTxt, LocalItem.Description)
                else
                    if Found then
                        Item.Modify(true)
                    else begin
                        if BookingSync."Item Template Code" <> '' then begin
                            ItemRecRef.GetTable(Item);
                            ConfigTemplateHeader.Get(BookingSync."Item Template Code");
                            ConfigTemplateManagement.UpdateRecord(ConfigTemplateHeader, ItemRecRef);
                            ItemRecRef.SetTable(Item);
                        end else begin
                            Item.Type := Item.Type::Service;
                            Item.Insert(true);
                        end;
                        BookingServiceMapping.Map(Item."No.", TempBookingServiceMapping."Service ID", BookingSync."Booking Mailbox Address");
                    end;
            until (LocalItem.Next() = 0)
        end;
    end;

    local procedure FindNavServiceInBookings(ItemNo: Code[20]; BookingMailbox: Text[80]) Found: Boolean
    var
        BookingServiceMapping: Record "Booking Service Mapping";
    begin
        BookingServiceMapping.SetRange("Item No.", ItemNo);
        BookingServiceMapping.SetRange("Booking Mailbox", BookingMailbox);
        if BookingServiceMapping.FindFirst() then
            if TempBookingServiceMapping.Get(BookingServiceMapping."Service ID") then begin
                TempItem.Get(TempBookingServiceMapping."Item No.");
                TempItem.Delete();
                Found := true;
            end;
    end;

    local procedure FindBookingServiceInNav(LocalItem: Record Item; var Item: Record Item) Found: Boolean
    var
        BookingServiceMapping: Record "Booking Service Mapping";
    begin
        TempBookingServiceMapping.SetRange("Item No.", LocalItem."No.");
        if TempBookingServiceMapping.FindFirst() then
            if BookingServiceMapping.Get(TempBookingServiceMapping."Service ID") then
                Found := Item.Get(BookingServiceMapping."Item No.");
    end;

    [TryFunction]
    local procedure TransferNavServiceToBookingService(var NavItem: Record Item; var BookingService: Record "Booking Service"; BookingMailbox: Text[80])
    var
        BookingServiceMapping: Record "Booking Service Mapping";
    begin
        Clear(BookingService);
        BookingService.Init();
        BookingService.Validate(
          "Display Name", CopyStr(NavItem.Description, 1, MaxStrLen(BookingService."Display Name")));
        BookingService.Validate(Price, NavItem."Unit Price");
        BookingServiceMapping.SetRange("Item No.", NavItem."No.");
        BookingServiceMapping.SetRange("Booking Mailbox", BookingMailbox);
        if BookingServiceMapping.FindFirst() then
            BookingService.Validate("Service ID", BookingServiceMapping."Service ID");
    end;

    [TryFunction]
    local procedure TransferBookingServiceToNavService(var BookingServiceItem: Record Item; var NavServiceItem: Record Item; ServiceId: Text[50]; BookingSync: Record "Booking Sync")
    var
        LocalItem: Record Item;
    begin
        NavServiceItem."Unit Price" := BookingServiceItem."Unit Price";
        NavServiceItem."Base Unit of Measure" := BookingServiceItem."Base Unit of Measure";
        NavServiceItem.Description := BookingServiceItem.Description;
        NavServiceItem.Validate("Last Date Modified", BookingServiceItem."Last Date Modified");
        NavServiceItem.Validate("Last Time Modified", BookingServiceItem."Last Time Modified");

        // NAV is the master and should overwrite O365 properties if it has also been updated since the last sync.
        Clear(LocalItem);
        if OverrideUpdate(LocalItem, BookingSync, ServiceId) then
            NavServiceItem.TransferFields(LocalItem);
    end;

    local procedure OverrideUpdate(var Item: Record Item; BookingSync: Record "Booking Sync"; BookingServiceId: Text[50]): Boolean
    var
        BookingServiceMapping: Record "Booking Service Mapping";
    begin
        if BookingServiceMapping.Get(BookingServiceId) then begin
            Item.SetRange("No.", BookingServiceMapping."Item No.");
            Item.SetLastDateTimeFilter(BookingSync."Last Service Sync");
            exit(Item.FindFirst());
        end;
    end;
}

