codeunit 119027 "Create Routing Lines"
{

    trigger OnRun()
    begin
        InsertData('1000', '', '10', '20', 0, '100', XWheelassembly, 110, 12, 0, 0, 0, 0, 0, 1, 0, '100', 0);
        InsertData('1000', '', '20', '30', 1, '120', XChainassembly, 15, 15, 0, 0, 0, 0, 0, 1, 0, '', 0);
        InsertData('1000', '', '30', '40', 1, '130', XFinalassembly, 10, 20, 0, 0, 0, 0, 0, 1, 0, '', 0);
        InsertData('1000', '', '40', '', 1, '110', XControl, 10, 8, 0, 0, 0, 0, 0, 1, 0, '300', 0);
        InsertData('1100', '', '10', '20', 0, '100', XRimassembly, 60, 5, 0, 0, 0, 0, 0, 1, 0, '100', 0);
        InsertData('1100', '', '20', '30', 1, '410', XDrilling, 60, 8, 0, 0, 0, 0, 0, 1, 0, '', 0);
        InsertData('1100', '', '30', '40', 1, '420', XDeburr, 20, 9, 0, 0, 0, 0, 0, 1, 0, '', 0);
        InsertData('1100', '', '40', '50', 1, '440', 'Machine Inspection', 10, 5, 0, 0, 0, 0, 0, 1, 0, '300', 0);
        InsertData('1100', '', '50', '', 1, '110', XWheelassembly, 30, 10, 0, 0, 0, 0, 0, 1, 0, '', 0);
        InsertData('1200', '', '10', '20', 0, '100', XRimassembly, 60, 5, 0, 0, 0, 0, 0, 1, 0, '100', 0);
        InsertData('1200', '', '20', '30', 1, '410', XDrilling, 60, 8, 0, 0, 0, 0, 0, 1, 0, '', 0);
        InsertData('1200', '', '30', '40', 1, '420', XDeburr, 20, 9, 0, 0, 0, 0, 0, 1, 0, '', 0);
        InsertData('1200', '', '40', '50', 1, '440', XMachineInspection, 10, 5, 0, 0, 0, 0, 0, 1, 0, '300', 0);
        InsertData('1200', '', '50', '', 1, '110', XWheelassembly, 30, 12, 0, 0, 0, 0, 0, 1, 0, '', 0);
        InsertData('1150', '', '5', '10|20', 1, '420', XCNCAxle, 120, 7, 0, 0, 0, 0, 0, 1, 0, '200', 0);
        InsertData('1150', '', '10', '30', 1, '420', XCNCAxle, 120, 7, 0, 0, 0, 0, 0, 1, 0, '', 0);
        InsertData('1150', '', '20', '40', 1, '420', XCNCSocket, 80, 5, 0, 0, 0, 0, 0, 1, 0, '', 0);
        InsertData('1150', '', '30', '50', 1, '430', XDeburrAxle, 20, 3, 0, 0, 0, 0, 0, 1, 0, '', 0);
        InsertData('1150', '', '40', '50', 1, '410', XDrillingSocket, 13, 5, 0, 0, 0, 0, 0, 1, 0, '', 0);
        InsertData('1150', '', '50', '60', 0, '100', XHubassembly, 30, 6, 0, 0, 0, 0, 0, 1, 0, '100', 0);
        InsertData('1150', '', '60', '', 1, '420', XInspectionofHub, 10, 5, 0, 0, 0, 0, 0, 1, 0, '300', 0);
        InsertData('2000', '', '10', '20', 0, '100', XAssembly, 0, 10, 0, 0, 0, 0, 0, 1, 0, '', 0);   //IT
        InsertData('2000', '', '20', '30', 0, '500', XDressing, 0, 5, 0, 0, 0, 0, 0, 1, 0, '', 0);    //IT
        InsertData('2000', '', '30', '', 0, '500', XPainting, 0, 10, 0, 0, 0, 0, 0, 1, 0, '100', 0);  //IT
    end;

    var
        RtngLine: Record "Routing Line";
        XWheelassembly: Label 'Wheel assembly';
        XChainassembly: Label 'Chain assembly';
        XFinalassembly: Label 'Final assembly';
        XControl: Label 'Control';
        XRimassembly: Label 'Rim assembly';
        XDrilling: Label 'Drilling';
        XDeburr: Label 'Deburr';
        XMachineInspection: Label 'Machine Inspection';
        XCNCAxle: Label 'CNC/Axle';
        XCNCSocket: Label 'CNC/Socket';
        XDeburrAxle: Label 'Deburr Axle';
        XDrillingSocket: Label 'Drilling Socket';
        XHubassembly: Label 'Hub assembly';
        XInspectionofHub: Label 'Inspection of Hub';
        XAssembly: Label 'Assembly';
        XDressing: Label 'Dressing';
        XPainting: Label 'Painting';

    procedure InsertData(RoutingNo: Code[20]; VersionCode: Code[10]; OperationNo: Code[10]; NextOperationNo: Code[10]; Type: Option "Work Center","Machine Center"; No: Code[20]; Description: Text[30]; SetupTime: Decimal; RunTime: Decimal; WaitTime: Decimal; MoveTime: Decimal; FixedScrapQty: Decimal; LotSize: Decimal; ScrapFactorPct: Decimal; ConcurrCapacity: Decimal; SendAheadQty: Decimal; RtngLinkCode: Code[10]; UnitCostPer: Decimal)
    begin
        RtngLine.Validate("Routing No.", RoutingNo);
        RtngLine.Validate("Version Code", VersionCode);
        RtngLine.Validate("Operation No.", OperationNo);
        RtngLine.Validate("Next Operation No.", NextOperationNo);
        RtngLine.Validate(Type, Type);
        RtngLine.Validate("No.", No);
        RtngLine.Validate(Description, Description);
        RtngLine.Validate("Setup Time", SetupTime);
        RtngLine.Validate("Run Time", RunTime);
        RtngLine.Validate("Wait Time", WaitTime);
        RtngLine.Validate("Move Time", MoveTime);
        RtngLine.Validate("Fixed Scrap Quantity", FixedScrapQty);
        RtngLine.Validate("Lot Size", LotSize);
        RtngLine.Validate("Scrap Factor %", ScrapFactorPct);
        RtngLine.Validate("Concurrent Capacities", ConcurrCapacity);
        RtngLine.Validate("Send-Ahead Quantity", SendAheadQty);
        RtngLine.Validate("Routing Link Code", RtngLinkCode);
        RtngLine.Validate("Unit Cost per", UnitCostPer);
        RtngLine.Insert();
#if not CLEAN27
#pragma warning disable AL0801
        //BEGIN IT
        if RoutingNo = '2000' then begin
            case OperationNo of
                '10':
                    RtngLine.Validate("WIP Item", false);
                '20':
                    begin
                        RtngLine.Validate("Standard Task Code", '1');
                        RtngLine.Validate("WIP Item", true);
                    end;
                '30':
                    begin
                        RtngLine.Validate("Standard Task Code", '2');
                        RtngLine.Validate("WIP Item", false);
                    end;
            end;
            RtngLine.Modify();
        end;
        //END IT
#pragma warning restore AL0801
#endif
    end;
}

