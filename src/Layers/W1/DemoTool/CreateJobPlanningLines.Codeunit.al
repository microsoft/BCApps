codeunit 101215 "Create Job Planning Lines"
{

    trigger OnRun()
    begin
        InsertData(XDEERFIELD8WP, '1110', 10000, 0, 19030115D, 0, XLina, XMeetingwithCustomer, XHOUR, 2, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1120', 10000, 0, 19030116D, 0, XLina, XSelectingFurnishings, XHOUR, 2, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1130', 10000, 0, 19030119D, 0, XLina, XMeetingwiththeCustomer, XHOUR, 2, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 10000, 0, 19030125D, 0, XLIFT, XLiftforFurniture, XHOUR, 8, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 12500, 0, 19030125D, 0, XMarty, XDeliveringandAssembling, XHOUR, 20, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 15000, 0, 19030125D, 1, X1896S, XATHENSDesk, XPCS, 8, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 20000, 0, 19030125D, 1, X1906S, XATHENSMobilePedestal, XPCS, 8, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 25000, 0, 19030125D, 1, X1908S, XLONDONSwivelChairblue, XPCS, 8, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 30000, 0, 19030125D, 1, X1928W, XSTMORITZStorageUnitDrawers, XPCS, 4, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 35000, 0, 19030125D, 1, X1964S, XTOKYOGuestChairblue, XPCS, 3, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 40000, 0, 19030125D, 1, X1976W, XINNSBRUCKStorageUnitWDoor, XPCS, 4, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 45000, 0, 19030125D, 1, X1996S, XATLANTAWhiteboardbase, XPCS, 3, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1310', 10000, 0, 19030129D, 0, XLina, XMeetingwiththeCustomer, XHOUR, 2, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1130', 20000, 1, 19030119D, 3, '', XSettingupEightWorkAreas, '', 0, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1130', 30000, 1, 19030119D, 3, '', XAccordingtoYourorderno774, '', 0, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1130', 40000, 1, 19030119D, 0, XLina, XPreliminaryServices, XHOUR, 6, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 47500, 1, 19030125D, 3, '', XSettingupEightWorkAreas, '', 0, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 50000, 1, 19030125D, 3, '', XAccordingtoYourorderno774, '', 0, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 52500, 1, 19030125D, 0, XLIFT, XLiftforFurniture, XHOUR, 8, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 55000, 1, 19030125D, 0, XMarty, XDeliveringandAssembling, XHOUR, 20, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 60000, 1, 19030125D, 1, X1896S, XATHENSDesk, XPCS, 8, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 65000, 1, 19030125D, 1, X1906S, XATHENSMobilePedestal, XPCS, 8, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 70000, 1, 19030125D, 1, X1908S, XLONDONSwivelChairblue, XPCS, 8, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 75000, 1, 19030125D, 1, X1928W, XSTMORITZStorageUnitDrawers, XPCS, 4, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 80000, 1, 19030125D, 1, X1964S, XTOKYOGuestChairblue, XPCS, 3, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 85000, 1, 19030125D, 1, X1976W, XINNSBRUCKStorageUnitWDoor, XPCS, 4, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1210', 90000, 1, 19030125D, 1, X1996S, XATLANTAWhiteboardbase, XPCS, 3, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1310', 20000, 1, 19030131D, 3, '', XSettingupEightWorkAreas, '', 0, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1310', 30000, 1, 19030131D, 3, '', XAccordingtoYourorderno774, '', 0, 0, 0, 0);
        InsertData(XDEERFIELD8WP, '1310', 40000, 1, 19030131D, 0, XLina, XClosingtheJob, XHOUR, 2, 0, 0, 0);

        InsertData(XGUILDFORD10CR, '1110', 10000, 0, 19030103D, 0, XLina, XMeetingwiththeCustomer, XHOUR, 4, 0, 0, 0);
        InsertData(XGUILDFORD10CR, '1120', 10000, 0, 19030108D, 0, XLina, XSelectingFurnishings, XHOUR, 10, 0, 0, 0);
        InsertData(XGUILDFORD10CR, '1130', 10000, 0, 19030112D, 0, XLina, XMeetingwiththeCustomer, XHOUR, 3, 0, 0, 0);
        InsertData(XGUILDFORD10CR, '1130', 20000, 1, 19030116D, 0, XLina, XPreliminaryServices, XHOUR, 17, 0, 0, 0);
        InsertData(XGUILDFORD10CR, '1210', 10000, 2, 19030123D, 0, XLIFT, XLiftforFurniture, XHOUR, 8, 0, 0, 0);
        InsertData(XGUILDFORD10CR, '1210', 20000, 2, 19030123D, 0, XMarty, XMartyHorst, XHOUR, 40, 0, 0, 0);
        InsertData(XGUILDFORD10CR, '1210', 30000, 2, 19030123D, 1, X1920S, XANTWERPConferenceTable, XPCS, 10, 5, 0, 0);
        InsertData(XGUILDFORD10CR, '1210', 40000, 2, 19030123D, 1, X1928S, XAMSTERDAMLamp, XPCS, 10, 5, 0, 0);
        InsertData(XGUILDFORD10CR, '1210', 50000, 2, 19030123D, 1, X1964S, XTOKYOGuestChairblue, XPCS, 60, 5, 0, 0);
        InsertData(XGUILDFORD10CR, '1210', 60000, 2, 19030123D, 1, X1984W, XSARAJEVOWhiteboardblue, XPCS, 10, 5, 0, 0);
        InsertData(XGUILDFORD10CR, '1310', 10000, 2, 19030205D, 0, XLina, XMeetingwiththeCustomer, XHOUR, 3, 5, 0, 0);
    end;

    var
        JobPlanningLine: Record "Job Planning Line";
        CA: Codeunit "Make Adjustments";
        XDEERFIELD8WP: Label 'DEERFIELD, 8 WP';
        XGUILDFORD10CR: Label 'GUILDFORD, 10 CR';
        XMeetingwithCustomer: Label 'Meeting with Customer';
        XSelectingFurnishings: Label 'Selecting Furnishings';
        XMeetingwiththeCustomer: Label 'Meeting with the Customer';
        XLiftforFurniture: Label 'Lift for Furniture';
        XDeliveringandAssembling: Label 'Delivering and Assembling';
        XATHENSDesk: Label 'ATHENS Desk';
        XATHENSMobilePedestal: Label 'ATHENS Mobile Pedestal';
        XLONDONSwivelChairblue: Label 'LONDON Swivel Chair, blue';
        XSTMORITZStorageUnitDrawers: Label 'ST.MORITZ Storage Unit/Drawers';
        XTOKYOGuestChairblue: Label 'TOKYO Guest Chair, blue';
        XINNSBRUCKStorageUnitWDoor: Label 'INNSBRUCK Storage Unit/W.Door';
        XATLANTAWhiteboardbase: Label 'ATLANTA Whiteboard, base';
        XSettingupEightWorkAreas: Label 'Setting up Eight Work Areas';
        XAccordingtoYourorderno774: Label 'According to Your order no. 774:';
        XPreliminaryServices: Label 'Preliminary Services';
        XMartyHorst: Label 'Marty Horst';
        XANTWERPConferenceTable: Label 'ANTWERP Conference Table';
        XAMSTERDAMLamp: Label 'AMSTERDAM Lamp';
        XSARAJEVOWhiteboardblue: Label 'SARAJEVO Whiteboard, blue';
        XLina: Label 'Lina';
        XLIFT: Label 'LIFT';
        XMarty: Label 'Marty';
        X1896S: Label '1896-S';
        X1906S: Label '1906-S';
        X1908S: Label '1908-S';
        X1928W: Label '1928-W';
        X1964S: Label '1964-S';
        X1976W: Label '1976-W';
        X1996S: Label '1996-S';
        X1920S: Label '1920-S';
        X1928S: Label '1928-S';
        X1984W: Label '1984-W';
        XHOUR: Label 'HOUR';
        XPCS: Label 'PCS';
        XClosingtheJob: Label 'Closing the Job';

    procedure InsertData("Job No.": Code[20]; "Job Task No.": Code[20]; "Line No.": Integer; "Line Type": Option Budget,Billable,"Both Budget and Billable"; "Planning Date": Date; Type: Option Resource,Item,"G/L Account",Text; "No.": Code[20]; Description: Text[50]; "Unit of Measure Code": Code[20]; Quantity: Decimal; "Line Discount %": Decimal; "Unit Cost": Decimal; "Unit Price": Decimal)
    begin
        JobPlanningLine.Init();
        JobPlanningLine.Validate("Job No.", "Job No.");
        JobPlanningLine.Validate("Job Task No.", "Job Task No.");
        JobPlanningLine.Validate("Line No.", "Line No.");
        JobPlanningLine.Insert(true);
        JobPlanningLine.Validate("Line Type", "Line Type");
        JobPlanningLine.Validate("Planning Date", CA.AdjustDate("Planning Date"));
        JobPlanningLine.Type := "Job Planning Line Type".FromInteger(Type);
        if "No." <> '' then begin
            JobPlanningLine.Validate("No.", "No.");
            JobPlanningLine.Validate("Unit of Measure Code", "Unit of Measure Code");
            JobPlanningLine.Validate(Quantity, Quantity);
            JobPlanningLine.Validate("Line Discount %", "Line Discount %");
            if "Unit Cost" <> 0 then
                JobPlanningLine.Validate("Unit Cost (LCY)", "Unit Cost");
            if "Unit Price" <> 0 then
                JobPlanningLine.Validate("Unit Price", "Unit Price");
        end;
        JobPlanningLine.Validate(Description, Description);
        JobPlanningLine.Modify();
    end;
}

