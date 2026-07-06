codeunit 103029 CRPUtil
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    begin
    end;

    [Scope('OnPrem')]
    procedure InsertRtngHeader(RtngNo: Code[20];var RtngHeader: Record "Routing Header")
    begin
        Clear(RtngHeader);
        RtngHeader.Init();
        RtngHeader.Validate("No.",RtngNo);
        RtngHeader.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure InsertRtngVersion(RtngNo: Code[20];RtngVersionCode: Code[20];StartingDate: Date;var RtngVersion: Record "Routing Version")
    begin
        Clear(RtngVersion);
        RtngVersion.Init();
        RtngVersion.Validate("Routing No.",RtngNo);
        RtngVersion.Validate("Version Code",RtngVersionCode);
        RtngVersion.Insert(true);
        RtngVersion.Validate("Starting Date",StartingDate);
        RtngVersion.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure InsertRntgLine(RtngNo: Code[20];VersionCode: Code[10];OperationNo: Code[10];var RtngLine: Record "Routing Line")
    begin
        Clear(RtngLine);
        RtngLine.Init();
        RtngLine.Validate("Routing No.",RtngNo);
        RtngLine.Validate("Version Code",VersionCode);
        RtngLine.Validate("Operation No.",OperationNo);
        RtngLine.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CertifyRouting(RoutingNo: Code[20];VersionCode: Code[20])
    var
        RtngHeader: Record "Routing Header";
        RtngVersion: Record "Routing Version";
    begin
        if VersionCode = '' then begin
          RtngHeader.Get(RoutingNo);
          RtngHeader.Validate(Status,RtngHeader.Status::Certified);
          RtngHeader.Modify(true);
        end else begin
          RtngVersion.Get(RoutingNo,VersionCode);
          RtngVersion.Validate(Status,RtngHeader.Status::Certified);
          RtngVersion.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure UncertifyRouting(RoutingNo: Code[20];VersionCode: Code[20])
    var
        RtngHeader: Record "Routing Header";
        RtngVersion: Record "Routing Version";
    begin
        if VersionCode = '' then begin
          RtngHeader.Get(RoutingNo);
          RtngHeader.Validate(Status,RtngHeader.Status::New);
          RtngHeader.Modify(true);
        end else begin
          RtngVersion.Get(RoutingNo,VersionCode);
          RtngVersion.Validate(Status,RtngHeader.Status::New);
          RtngVersion.Modify(true);
        end;
    end;

    [Scope('OnPrem')]
    procedure CertifyRtngAndConnectToItem(var RtngHeader: Record "Routing Header";var Item: Record Item)
    begin
        RtngHeader.Validate(Status,RtngHeader.Status::Certified);
        RtngHeader.Modify(true);
        Item.Validate("Routing No.",RtngHeader."No.");
        Item.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CalcWrkCntrCal(StartDate: Date;EndDate: Date)
    var
        "Calculate Work Center Calendar": Report "Calculate Work Center Calendar";
    begin
        "Calculate Work Center Calendar".UseRequestPage(false);
        "Calculate Work Center Calendar".InitializeRequest(StartDate,EndDate);
        "Calculate Work Center Calendar".Run();
    end;

    [Scope('OnPrem')]
    procedure CalcMachCntrCal(StartDate: Date;EndDate: Date)
    var
        "Calc. Machine Center Calendar": Report "Calc. Machine Center Calendar";
    begin
        "Calc. Machine Center Calendar".UseRequestPage(false);
        "Calc. Machine Center Calendar".InitializeRequest(StartDate,EndDate);
        "Calc. Machine Center Calendar".Run();
    end;
}

