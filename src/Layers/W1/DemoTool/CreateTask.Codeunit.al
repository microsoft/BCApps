codeunit 101580 "Create Task"
{

    trigger OnRun()
    begin
        InsertData(XTD100001, '', XBC, '', XCT100132, XOP100045, '', 0, 19021016D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021016D, XTASK, false, 46, XTD100001, 0);
        InsertData(XTD100002, '', XBC, '', XCT100132, XOP100045, '', 0, 19021023D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021023D, XTASK, false, 46, XTD100002, 0);
        InsertData(XTD100003, '', XHR, '', XCT000007, XOP100046, '', 0, 19021110D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021110D, XTASK, false, 47, XTD100003, 0);
        InsertData(XTD100004, '', XHR, '', XCT000007, XOP100046, '', 0, 19021117D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021117D, XTASK, false, 47, XTD100004, 0);
        InsertData(XTD100005, '', XOF, '', XCT100152, XOP100047, '', 0, 19021021D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021021D, XTASK, false, 48, XTD100005, 0);
        InsertData(XTD100006, '', XOF, '', XCT100152, XOP100047, '', 0, 19021028D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021028D, XTASK, false, 48, XTD100006, 0);
        InsertData(XTD100007, '', XOF, '', XCT100152, XOP100047, '', 0, 19021024D, "Task Status"::Completed, 1,
          XEstcustomerneeds, true, 19021024D, XTASK, false, 49, XTD100007, 0);
        InsertData(XTD100008, '', XOF, '', XCT100152, XOP100047, '', 0, 19021030D, "Task Status"::Completed, 1,
          XSendletterofintroduction, true, 19021030D, XTASK, false, 49, XTD100008, 0);
        InsertData(XTD100009, '', XOF, '', XCT100152, XOP100047, '', 2, 19021107D, "Task Status"::Completed, 2,
          XFollowuponintroductionletter, true, 19021107D, XTASK, false, 49, XTD100009, 0);
        InsertData(XTD100010, '', XOF, '', XCT100152, XOP100047, '', 0, 19021108D, "Task Status"::Completed, 2,
          XVerifychangecustomerneeds, true, 19021108D, XTASK, false, 49, XTD100010, 0);
        InsertData(XTD100011, '', XBC, '', XCT100152, XOP100048, '', 0, 19021114D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021114D, XTASK, false, 50, XTD100011, 0);
        InsertData(XTD100012, '', XBC, '', XCT100152, XOP100048, '', 0, 19021121D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021121D, XTASK, false, 50, XTD100012, 0);
        InsertData(XTD100013, '', XHR, '', XCT100226, XOP100049, '', 0, 19021208D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021208D, XTASK, false, 51, XTD100013, 0);
        InsertData(XTD100014, '', XHR, '', XCT100226, XOP100049, '', 0, 19021215D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021215D, XTASK, false, 51, XTD100014, 0);
        InsertData(XTD100015, '', XBC, '', XCT100148, XOP100028, '', 0, 19021026D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021026D, XTASK, false, 52, XTD100015, 0);
        InsertData(XTD100016, '', XBC, '', XCT100148, XOP100028, '', 0, 19021101D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021101D, XTASK, false, 52, XTD100016, 0);
        InsertData(XTD100017, '', XOF, '', XCT200116, XOP100001, '', 0, 19021223D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021223D, XTASK, false, 1, XTD100017, 0);
        InsertData(XTD100018, '', XOF, '', XCT200116, XOP100001, '', 0, 19021230D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021230D, XTASK, false, 1, XTD100018, 0);
        InsertData(XTD100019, '', XHR, '', XCT200097, XOP100022, '', 0, 19030116D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19030116D, XTASK, false, 41, XTD100019, 0);
        InsertData(XTD100020, '', XHR, '', XCT200097, XOP100022, '', 0, 19030123D, "Task Status"::"In Progress", 1,
          XIdentifykeypersons, false, 0D, XTASK, false, 41, XTD100020, 0);
        InsertData(XTD100021, '', XBC, '', XCT200094, XOP100023, '', 0, 19030106D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19030106D, XTASK, false, 42, XTD100021, 0);
        InsertData(XTD100022, '', XBC, '', XCT200094, XOP100023, '', 0, 19030113D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19030113D, XTASK, false, 42, XTD100022, 0);
        InsertData(XTD100023, '', XHR, '', XCT200091, XOP100024, '', 0, 19030116D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19030116D, XTASK, false, 43, XTD100023, 0);
        InsertData(XTD100024, '', XHR, '', XCT200091, XOP100024, '', 0, 19030123D, "Task Status"::"In Progress", 1,
          XIdentifykeypersons, false, 0D, XTASK, false, 43, XTD100024, 0);
        InsertData(XTD100025, '', XHR, '', XCT100002, XOP100025, '', 0, 19021116D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021116D, XTASK, false, 44, XTD100025, 0);
        InsertData(XTD100026, '', XHR, '', XCT100002, XOP100025, '', 0, 19021123D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021123D, XTASK, false, 44, XTD100026, 0);
        InsertData(XTD100027, '', XEH, '', XCT200107, XOP100026, '', 0, 19021121D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021121D, XTASK, false, 45, XTD100027, 0);
        InsertData(XTD100028, '', XEH, '', XCT200107, XOP100026, '', 0, 19021128D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021128D, XTASK, false, 45, XTD100028, 0);
        InsertData(XTD100029, '', XBC, '', XCT000011, XOP100029, '', 0, 19021011D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021011D, XTASK, false, 53, XTD100029, 0);
        InsertData(XTD100030, '', XBC, '', XCT000011, XOP100029, '', 0, 19021018D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021018D, XTASK, false, 53, XTD100030, 0);
        InsertData(XTD100031, '', XHR, '', XCT100215, XOP100030, '', 0, 19021115D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021115D, XTASK, false, 54, XTD100031, 0);
        InsertData(XTD100032, '', XHR, '', XCT100215, XOP100030, '', 0, 19021122D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021122D, XTASK, false, 54, XTD100032, 0);
        InsertData(XTD100033, '', XHR, '', XCT100215, XOP100030, '', 2, 19021116D, "Task Status"::Completed, 1,
          'Make appointment for product presentation/workshop', true, 19021116D, XTASK, false, 55, XTD100033, 0);
        InsertData(XTD100034, '', XHR, '', XCT100215, XOP100030, '', 0, 19021119D, "Task Status"::Completed, 0,
          'Confirm product presentation/workshop in writing', true, 19021119D, XTASK, false, 55, XTD100034, 0);
        InsertData(XTD100035, '', XHR, '', XCT100215, XOP100030, '', 0, 19021119D, "Task Status"::Completed, 0,
          'Book necessary equipment', true, 19021119D, XTASK, false, 55, XTD100035, 0);
        InsertData(XTD100036, '', XHR, '', XCT100215, XOP100030, '', 0, 19021119D, "Task Status"::Completed, 1,
          'Ensure availability of internal resources', true, 19021119D, XTASK, false, 55, XTD100036, 0);
        InsertData(XTD100037, '', XOF, '', XCT100215, XOP100031, '', 0, 19021119D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021119D, XTASK, false, 56, XTD100037, 0);
        InsertData(XTD100038, '', XOF, '', XCT100215, XOP100031, '', 0, 19021126D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021126D, XTASK, false, 56, XTD100038, 0);
        InsertData(XTD100039, '', XHR, '', XCT000013, XOP100032, '', 0, 19030114D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19030114D, XTASK, false, 57, XTD100039, 0);
        InsertData(XTD100040, '', XHR, '', XCT000013, XOP100032, '', 0, 19030121D, "Task Status"::"In Progress", 1,
          XIdentifykeypersons, false, 0D, XTASK, false, 57, XTD100040, 0);
        InsertData(XTD100041, '', XBC, '', XCT100163, XOP100033, '', 0, 19021017D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021017D, XTASK, false, 58, XTD100041, 0);
        InsertData(XTD100042, '', XBC, '', XCT100163, XOP100033, '', 0, 19021024D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021024D, XTASK, false, 58, XTD100042, 0);
        InsertData(XTD100043, '', XHR, '', XCT100230, XOP100034, '', 0, 19021215D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021215D, XTASK, false, 59, XTD100043, 0);
        InsertData(XTD100044, '', XHR, '', XCT100230, XOP100034, '', 0, 19021222D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021222D, XTASK, false, 59, XTD100044, 0);
        InsertData(XTD100045, '', XHR, '', XCT100230, XOP100035, '', 0, 19021229D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021229D, XTASK, false, 60, XTD100045, 0);
        InsertData(XTD100046, '', XHR, '', XCT100230, XOP100035, '', 0, 19030105D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19030105D, XTASK, false, 60, XTD100046, 0);
        InsertData(XTD100047, '', XOF, '', XCT000016, XOP100036, '', 0, 19021204D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19021204D, XTASK, false, 61, XTD100047, 0);
        InsertData(XTD100048, '', XOF, '', XCT000016, XOP100036, '', 0, 19021211D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021211D, XTASK, false, 61, XTD100048, 0);
        InsertData(XTD100049, '', XOF, '', XCT000007, XOP100037, '', 0, 19020928D, "Task Status"::Completed, 2,
          XVerifyqualityofopportunity, true, 19020928D, XTASK, false, 62, XTD100049, 0);
        InsertData(XTD100050, '', XOF, '', XCT000007, XOP100037, '', 0, 19021005D, "Task Status"::Completed, 1,
          XIdentifykeypersons, true, 19021005D, XTASK, false, 62, XTD100050, 0);
        InsertData(XTD100051, '', XJO, '', '', '', '', 1, 19030124D, "Task Status"::"Not Started", 1,
          XPresentorganizationalstrategy, false, 0D, XTASK, false, 0, XTD100051, 0);
        InsertData(XTD100052, '', XJO, '', XCT100140, '', '', 1, 19030124D, "Task Status"::"Not Started", 1,
          XPresentorganizationalstrategy, false, 0D, XTASK, false, 0, XTD100051, 2);
        InsertData(XTD100053, '', XJO, '', XCT100156, '', '', 1, 19030124D, "Task Status"::"Not Started", 1,
          XPresentorganizationalstrategy, false, 0D, XTASK, false, 0, XTD100051, 2);
        InsertData(XTD100054, XSALE, '', '', '', '', '', 1, 19030125D, "Task Status"::"Not Started", 1,
          XImprovesalesrevenue, false, 0D, XTASK, false, 0, XTD100054, 3);
        InsertData(XTD100055, XSALE, XRB, '', '', '', '', 1, 19030125D, "Task Status"::"Not Started", 1,
          XImprovesalesrevenue, false, 0D, XTASK, false, 0, XTD100054, 0);
        InsertData(XTD100056, XSALE, XJO, '', '', '', '', 1, 19030125D, "Task Status"::"Not Started", 1,
          XImprovesalesrevenue, false, 0D, XTASK, false, 0, XTD100054, 1);
        InsertData(XTD100057, XSALE, '', '', '', '', '', 0, 19030124D, "Task Status"::"Not Started", 1,
          XUpdateannualreports, false, 0D, XTASK, false, 0, XTD100057, 3);
        InsertData(XTD100058, XSALE, XJO, '', '', '', '', 0, 19030124D, "Task Status"::"Not Started", 1,
          XUpdateannualreports, false, 0D, XTASK, false, 0, XTD100057, 0);
        InsertData(XTD100059, XSALE, XRB, '', '', '', '', 0, 19030124D, "Task Status"::"Not Started", 1,
          XUpdateannualreports, false, 0D, XTASK, false, 0, XTD100057, 0);
    end;

    var
        Task: Record "To-do";
        XTD100001: Label 'TD100001';
        XTD100002: Label 'TD100002';
        XTD100003: Label 'TD100003';
        XTD100004: Label 'TD100004';
        XTD100005: Label 'TD100005';
        XTD100006: Label 'TD100006';
        XTD100007: Label 'TD100007';
        XTD100008: Label 'TD100008';
        XTD100009: Label 'TD100009';
        XTD100010: Label 'TD100010';
        XTD100011: Label 'TD100011';
        XTD100012: Label 'TD100012';
        XTD100013: Label 'TD100013';
        XTD100014: Label 'TD100014';
        XTD100015: Label 'TD100015';
        XTD100016: Label 'TD100016';
        XTD100017: Label 'TD100017';
        XTD100018: Label 'TD100018';
        XTD100019: Label 'TD100019';
        XTD100020: Label 'TD100020';
        XTD100021: Label 'TD100021';
        XTD100022: Label 'TD100022';
        XTD100023: Label 'TD100023';
        XTD100024: Label 'TD100024';
        XTD100025: Label 'TD100025';
        XTD100026: Label 'TD100026';
        XTD100027: Label 'TD100027';
        XTD100028: Label 'TD100028';
        XTD100029: Label 'TD100029';
        XTD100030: Label 'TD100030';
        XTD100031: Label 'TD100031';
        XTD100032: Label 'TD100032';
        XTD100033: Label 'TD100033';
        XTD100034: Label 'TD100034';
        XTD100035: Label 'TD100035';
        XTD100036: Label 'TD100036';
        XTD100037: Label 'TD100037';
        XTD100038: Label 'TD100038';
        XTD100039: Label 'TD100039';
        XTD100040: Label 'TD100040';
        XTD100041: Label 'TD100041';
        XTD100042: Label 'TD100042';
        XTD100043: Label 'TD100043';
        XTD100044: Label 'TD100044';
        XTD100045: Label 'TD100045';
        XTD100046: Label 'TD100046';
        XTD100047: Label 'TD100047';
        XTD100048: Label 'TD100048';
        XTD100049: Label 'TD100049';
        XTD100050: Label 'TD100050';
        XTD100051: Label 'TD100051';
        XTD100052: Label 'TD100052';
        XTD100053: Label 'TD100053';
        XTD100054: Label 'TD100054';
        XTD100055: Label 'TD100055';
        XTD100056: Label 'TD100056';
        XTD100057: Label 'TD100057';
        XTD100058: Label 'TD100058';
        XTD100059: Label 'TD100059';
        XBC: Label 'BC';
        XHR: Label 'HR';
        XOF: Label 'OF';
        XEH: Label 'EH';
        XJO: Label 'JO';
        XRB: Label 'RB';
        XSALE: Label 'SALE';
        XCT100132: Label 'CT100132';
        XCT000007: Label 'CT000007';
        XCT100152: Label 'CT100152';
        XCT100226: Label 'CT100226';
        XCT100148: Label 'CT100148';
        XCT200116: Label 'CT200116';
        XCT200097: Label 'CT200097';
        XCT200094: Label 'CT200094';
        XCT200091: Label 'CT200091';
        XCT100002: Label 'CT100002';
        XCT200107: Label 'CT200107';
        XCT000011: Label 'CT000011';
        XCT100215: Label 'CT100215';
        XCT000013: Label 'CT000013';
        XCT100163: Label 'CT100163';
        XCT100230: Label 'CT100230';
        XCT000016: Label 'CT000016';
        XCT100140: Label 'CT100140';
        XCT100156: Label 'CT100156';
        XOP100045: Label 'OP100045';
        XOP100046: Label 'OP100046';
        XOP100047: Label 'OP100047';
        XOP100048: Label 'OP100048';
        XOP100049: Label 'OP100049';
        XOP100028: Label 'OP100028';
        XOP100001: Label 'OP100001';
        XOP100022: Label 'OP100022';
        XOP100023: Label 'OP100023';
        XOP100024: Label 'OP100024';
        XOP100025: Label 'OP100025';
        XOP100026: Label 'OP100026';
        XOP100029: Label 'OP100029';
        XOP100030: Label 'OP100030';
        XOP100031: Label 'OP100031';
        XOP100032: Label 'OP100032';
        XOP100033: Label 'OP100033';
        XOP100034: Label 'OP100034';
        XOP100035: Label 'OP100035';
        XOP100036: Label 'OP100036';
        XOP100037: Label 'OP100037';
        XTASK: Label 'TASK', Comment = 'Translate as Task';
        XVerifyqualityofopportunity: Label 'Verify quality of opportunity';
        XIdentifykeypersons: Label 'Identify key persons';
        XEstcustomerneeds: Label 'Est. customer needs';
        XSendletterofintroduction: Label 'Send letter of introduction';
        XFollowuponintroductionletter: Label 'Follow-up on introduction letter';
        XVerifychangecustomerneeds: Label 'Verify/change customer needs';
        XPresentorganizationalstrategy: Label 'Present organizational strategy';
        XImprovesalesrevenue: Label 'Improve sales revenue';
        XUpdateannualreports: Label 'Update annual reports';
        XMEETINV: Label 'MEETINV';
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData("No.": Code[20]; "Team Code": Code[10]; "Salesperson Code": Code[20]; "Campaign No.": Code[20]; "Contact No.": Code[20]; "Opportunity No.": Code[20]; "Segment No.": Code[20]; Type: Option; Date: Date; Status: Enum "Task Status"; Priority: Option; Description: Text[50]; Closed: Boolean; "Date Closed": Date; "No. Series": Code[10]; Canceled: Boolean; "Opportunity Entry No.": Integer; "Organizer Task No.": Code[20]; "System Task Type": Option)
    begin
        Task.Init();
        Task."No." := '';
        Task.Validate("No.", "No.");
        Task."Organizer To-do No." := "Organizer Task No.";
        Task."System To-do Type" := "System Task Type";
        Task.Validate("Team Code", "Team Code");
        Task.Validate("Salesperson Code", "Salesperson Code");
        Task.Validate("Campaign No.", "Campaign No.");
        Task.Validate("Opportunity No.", "Opportunity No.");
        Task.Validate("Segment No.", "Segment No.");
        Task.Validate(Date, MakeAdjustments.AdjustDate(Date));
        Task.Type := "Task Type".FromInteger(Type);
        Task.Validate("No. Series", "No. Series");
        Task.Validate(Priority, Priority);
        Task.Validate(Description, Description);
        Task.Validate("Date Closed", MakeAdjustments.AdjustDate("Date Closed"));
        Task.Validate("Opportunity Entry No.", "Opportunity Entry No.");
        Task.Canceled := Canceled;
        Task.Closed := Closed;
        Task.Status := Status;
        Task.Duration := 1440 * 60 * 1000;
        if Task.Type = Task.Type::Meeting then begin
            Task."All Day Event" := true;
            Task.Validate(Location, 'Conference Room')
        end;
        Task.Validate("Contact No.", "Contact No.");
        Task.Insert();
        if Task.Type = Task.Type::Meeting then begin
            Task.Validate("Interaction Template Code", XMEETINV);
            Task.Modify();
        end
    end;
}

