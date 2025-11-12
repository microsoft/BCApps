codeunit 133782 "Booking Service Sync Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Bookings] [Sync] [Services]
    end;

    var
        BookingSync: Record "Booking Sync";
        ExchangeSync: Record "Exchange Sync";

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure CreateBookingServiceFromNAV()
    var
        Item: Record Item;
        BookingService: Record "Booking Service";
        O365SyncManagement: Codeunit "O365 Sync. Management";
        ServiceName: Text[50];
        ServicePrice: Decimal;
    begin
        // [FEATURE] [Bookings] [Sync] [Services] [Create]
        // [SCENARIO 169985] New service items in NAV are created in Bookings when the sync process runs.

        // [GIVEN] Bookings sync has been setup
        Setup(BookingSync, ExchangeSync);
        SetValues(ServiceName, ServicePrice);

        // [GIVEN] Service item exists in NAV but not in Bookings
        CreateItem(Item, ServiceName, ServicePrice, true);

        // [WHEN] Synchronization process runs
        O365SyncManagement.SyncBookingServices(BookingSync);

        // [THEN] Service item gets created in Bookings
        FindBookingService(BookingService, ServiceName, ServicePrice);
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure CreateNAVItemFromBookingService()
    var
        Item: Record Item;
        BookingService: Record "Booking Service";
        O365SyncManagement: Codeunit "O365 Sync. Management";
        ServiceName: Text[50];
        ServicePrice: Decimal;
    begin
        // [FEATURE] [Bookings] [Sync] [Services] [Create]
        // [SCENARIO 169985] New services in Bookings are created in NAV when the sync process runs.

        // [GIVEN] Bookings sync has been set up
        Setup(BookingSync, ExchangeSync);
        SetValues(ServiceName, ServicePrice);

        // [GIVEN] Booking service exists that does not exist in NAV.
        CreateBookingService(BookingService, ServiceName, ServicePrice, '');

        // [WHEN] Synchronization process runs.
        O365SyncManagement.SyncBookingServices(BookingSync);

        // [THEN] NAV item gets created from the Booking service.
        FindItem(Item, ServiceName, ServicePrice);
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UpdateBookingServiceFromNAVItem()
    var
        Item: Record Item;
        BookingService: Record "Booking Service";
        O365SyncManagement: Codeunit "O365 Sync. Management";
        ServiceName: Text[50];
        ServicePrice: Decimal;
    begin
        // [FEATURE] [Bookings] [Sync] [Services] [Update]
        // [SCENARIO 169985] Updated service items in NAV are also updated in Bookings when the sync process runs.

        // [GIVEN] Bookings sync has been set up
        Setup(BookingSync, ExchangeSync);
        SetValues(ServiceName, ServicePrice);

        // [GIVEN] Service exists in both NAV and Bookings
        CreateItem(Item, ServiceName, ServicePrice, true);
        CreateBookingService(BookingService, ServiceName, ServicePrice, Item."No.");

        // [GIVEN] NAV Item has been modified since last sync
        UpdateItem(Item, ServicePrice);

        // [WHEN] Synchronization process runs
        O365SyncManagement.SyncBookingServices(BookingSync);

        // [THEN] Booking service gets updated
        FindBookingService(BookingService, ServiceName, ServicePrice);
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UpdateNAVItemFromBookingService()
    var
        Item: Record Item;
        BookingService: Record "Booking Service";
        O365SyncManagement: Codeunit "O365 Sync. Management";
        ServiceName: Text[50];
        ServicePrice: Decimal;
    begin
        // [FEATURE] [Bookings] [Sync] [Services] [Update]
        // [SCENARIO 169985] Updated services in Bookings are also updated in NAV when the sync process runs.

        // [GIVEN] Bookings sync has been set up.
        Setup(BookingSync, ExchangeSync);
        SetValues(ServiceName, ServicePrice);

        // [GIVEN] Service exists in both NAV and Bookings
        CreateItem(Item, ServiceName, ServicePrice, false);
        CreateBookingService(BookingService, ServiceName, ServicePrice, Item."No.");

        // [GIVEN] Service has been modified in Bookings since last sync
        UpdateBookingService(BookingService, ServicePrice);

        // [WHEN] Sync process runs
        O365SyncManagement.SyncBookingServices(BookingSync);

        // [THEN] Service item gets updated in NAV.
        FindItem(Item, ServiceName, ServicePrice);
    end;

    [Test]
    [HandlerFunctions('ConfirmationHandler')]
    [Scope('OnPrem')]
    procedure UpdateBookingServiceFromNAVItemAndNAVItemFromBookingService()
    var
        Item1: Record Item;
        Item2: Record Item;
        BookingService1: Record "Booking Service";
        BookingService2: Record "Booking Service";
        O365SyncManagement: Codeunit "O365 Sync. Management";
        ServiceName: array[2] of Text[50];
        ServicePrice: array[2] of Decimal;
    begin
        // [FEATURE] [Bookings] [Sync] [Services] [Update]
        // [SCENARIO 169985] Updates in both Bookings and NAV are reflected both ways when the sync process runs.

        // [GIVEN] Bookings sync has been set up.
        Setup(BookingSync, ExchangeSync);
        SetValues(ServiceName[1], ServicePrice[1]);
        SetValues(ServiceName[2], ServicePrice[2]);

        // [GIVEN] Two items exist in both NAV and Bookings.
        CreateItem(Item1, ServiceName[1], ServicePrice[1], true);
        CreateBookingService(BookingService1, ServiceName[1], ServicePrice[1], Item1."No.");
        CreateItem(Item2, ServiceName[2], ServicePrice[2], false);
        CreateBookingService(BookingService2, ServiceName[2], ServicePrice[2], Item2."No.");

        // [WHEN] A NAV item gets modified since last sync
        UpdateItem(Item1, ServicePrice[1]);

        // [WHEN] A different item gets modified  in Bookings since last sync
        UpdateBookingService(BookingService2, ServicePrice[2]);

        // [WHEN] Sync process runs
        O365SyncManagement.SyncBookingServices(BookingSync);

        // [THEN] The item that was modified in NAV gets updated in Bookings
        FindBookingService(BookingService1, ServiceName[1], ServicePrice[1]);

        // [THEN] The item that was modified in Bookings gets updated in NAV
        FindItem(Item2, ServiceName[2], ServicePrice[2]);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmationHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure Setup(var BookingSync: Record "Booking Sync"; var ExchangeSync: Record "Exchange Sync")
    var
        Item: Record Item;
        BookingService: Record "Booking Service";
        BookingServiceMapping: Record "Booking Service Mapping";
        LibraryO365Sync: Codeunit "Library - O365 Sync";
        ConnectionID: Guid;
    begin
        LibraryO365Sync.SetupNavUser();
        LibraryO365Sync.SetupBookingsSync(BookingSync);
        LibraryO365Sync.SetupExchangeSync(ExchangeSync);
        LibraryO365Sync.SetupBookingTableConnection(BookingSync, ConnectionID);
        BookingSync."Last Service Sync" := CreateDateTime(Today - 1, Time);
        BookingSync."Item Template Code" := '';
        BookingSync.Modify();
        Item.DeleteAll();
        BookingServiceMapping.DeleteAll();
        BookingService.DeleteAll();
    end;

    local procedure SetValues(var Description: Text[50]; var Price: Decimal)
    begin
        Description := CreateGuid();
        Price := Random(1000);
    end;

    local procedure CreateItem(var Item: Record Item; Description: Text[50]; Price: Decimal; New: Boolean)
    begin
        Item.Init();
        Item.Validate(Description, Description);
        Item.Validate(Type, Item.Type::Service);
        Item.Validate("Unit Price", Price);
        Item.Insert(true);

        if not New then begin
            Item."Last Date Modified" := Today - 10;
            Item.Modify();
        end;
    end;

    local procedure CreateBookingService(var BookingService: Record "Booking Service"; Description: Text[50]; Price: Decimal; ItemNo: Code[20])
    var
        BookingServiceMapping: Record "Booking Service Mapping";
    begin
        Clear(BookingService);
        BookingService.Init();
        BookingService.Validate("Display Name", Description);
        BookingService.Validate(Price, Price);
        BookingService.Insert();

        if ItemNo <> '' then begin
            BookingService.Get(Description);
            BookingServiceMapping.Map(ItemNo, BookingService."Service ID", BookingSync."Booking Mailbox Address");
        end;
    end;

    local procedure FindItem(var Item: Record Item; Description: Text; Price: Decimal)
    begin
        Clear(Item);
        Item.SetRange(Description, Description);
        Item.SetRange("Unit Price", Price);
        Item.SetRange(Type, Item.Type::Service);
        Item.FindFirst();
    end;

    local procedure FindBookingService(var BookingService: Record "Booking Service"; Description: Text; Price: Decimal)
    begin
        Clear(BookingService);
        BookingService.SetRange("Display Name", Description);
        BookingService.SetRange(Price, Price);
        BookingService.FindFirst();
    end;

    local procedure UpdateItem(var Item: Record Item; var Price: Decimal)
    begin
        Price += 0.75;
        Item."Unit Price" := Price;
        Item.Modify(true);
    end;

    local procedure UpdateBookingService(var BookingService: Record "Booking Service"; var Price: Decimal)
    begin
        Price += 0.75;
        BookingService.Price := Price;
        BookingService.Modify(true);
    end;
}

