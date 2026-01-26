codeunit 117041 "Create Service Item"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();

        InsertData('1', '121000', XDESKTOP, XComputerIII533MHz, ServiceItem.Status::Installed, ServiceItem.Priority::High, '10000', '', '80001', XPCS, 19020630D, 8,
          16.2, XSMdashITEM, '', '');
        InsertData('2', '', XDESKTOP, XComputerIII600MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '10000', '', '80002', XPCS, 19020630D, 24, 19.2,
          XSMdashITEM, '', '');
        InsertData('3', '', XDESKTOP, XComputerIII600MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '10000', '', '80002', XPCS, 19020630D, 24, 19.2,
          XSMdashITEM, '', '');
        InsertData('4', '', XDESKTOP, XComputerIII600MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '10000', '', '80002', XPCS, 19020630D, 24, 19.2,
          XSMdashITEM, '', '');
        InsertData('5', '', XDESKTOP, XComputerIII600MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '10000', '', '80002', XPCS, 19020630D, 24, 19.2,
          XSMdashITEM, '', '');
        InsertData('6', '123456789', XZIPDRIVE, XDrive250MB, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '10000', '', '80213', XPCS, 19020101D, 24, 17.25,
          XSMdashITEM, '', '');
        InsertData('7', 'AS764789', XSERVER, XEnterpriseComputer667MHz, ServiceItem.Status::Installed, ServiceItem.Priority::High, '10000', '', '80007', XPCS,
          19021130D, 8, 317.85, XSMdashITEM, XKatherine, '');
        InsertData('8', 'SK986530', XDESKTOP, XComputerIII600MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '20000', '', '80002', XPCS, 19030106D, 24
          , 19.2, XSMdashITEM, '', '');
        InsertData('9', 'SP986543', XDESKTOP, XComputerIII733MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '30000', '', '80003', XPCS, 19030126D, 24
          , 20.7, XSMdashITEM, '', '');
        InsertData('10', 'M890000', XDESKTOP, XComputerIII800MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '30000', '', '80004', XPCS, 19020316D, 24
          , 22.2, XSMdashITEM, '', '');
        InsertData('11', '121001', XDESKTOP, XComputerIII533MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '40000', '', '80001', XPCS, 19020602D, 24,
          16.2, XSMdashITEM, '', '');
        InsertData('12', '121002', XDESKTOP, XComputerIII533MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '40000', '', '80001', XPCS, 19020702D, 24,
          16.2, XSMdashITEM, '', '');
        InsertData('13', 'SP9865303', XDESKTOP, XComputerIII733MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '40000', '', '80003', XPCS, 19020816D,
          24, 20.7, XSMdashITEM, '', '');
        InsertData('14', 'M890001', XDESKTOP, XComputerIII800MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '40000', '', '80004', XPCS, 19020413D, 24
          , 22.2, XSMdashITEM, '', '');
        InsertData('15', 'M890002', XDESKTOP, XComputerIII800MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '40000', '', '80004', XPCS, 19020816D, 24
          , 22.2, XSMdashITEM, '', '');
        InsertData('16', 'AT73938372-01', XSERVER, XTeamWorkComputer533MHz, ServiceItem.Status::Installed, ServiceItem.Priority::High, '40000', '', '80006', XPCS,
          19030106D, 8, 224.85, XSMdashITEM, '', '');
        InsertData('17', 'AT8363929-93', XSERVER, XTeamWorkComputer533MHz, ServiceItem.Status::Installed, ServiceItem.Priority::High, '50000', '', '80006', XPCS,
          19030126D, 8, 224.85, XSMdashITEM, '', '');
        InsertData('18', '121003', XDESKTOP, XComputerIII533MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '50000', '', '80001', XPCS, 19030116D, 16,
          16.2, XSMdashITEM, '', '');
        InsertData('19', 'HP739038762', XDESKTOP, XComputerIII866MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '50000', '', '80005', XPCS,
          19021126D, 16, 26.7, XSMdashITEM, '', '');
        InsertData('20', 'HP83738020', XDESKTOP, XComputerIII866MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '50000', '', '80005', XPCS, 19020802D
          , 16, 26.7, XSMdashITEM, '', '');
        InsertData('21', '1234567', XGRAPHICS, XGraphicProgram, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '40000', '', '80201', XPCS, 0D, 24, 55.4,
          XSMdashITEM, '', '');
        InsertData('22', '54321', XDESKTOP, XComputerIII866MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '40000', '', '80005', XPCS, 19020802D, 24,
          26.7, XSMdashITEM, '', '');
        InsertData('23', 'MCM-58746', XMONITOR, X17INCHM780Monitor, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '10000', '', '80102', XPCS, 19020630D, 24,
          44.25, XSMdashITEM, '', '');
        InsertData('24', 'MCM-652587', XMONITOR, X17INCHM780Monitor, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '10000', '', '80102', XPCS, 19020630D, 24,
          44.25, XSMdashITEM, '', '');
        InsertData('25', 'MCM-290767', XMONITOR, X17INCHM780Monitor, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '10000', '', '80102', XPCS, 19020630D, 24,
          44.25, XSMdashITEM, '', '');
        InsertData('26', 'MCM-220791', XMONITOR, X17INCHM780Monitor, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '10000', '', '80102', XPCS, 19020630D, 24,
          44.25, XSMdashITEM, '', '');
        InsertData('27', 'MCM-060267', XMONITOR, X17INCHM780Monitor, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '10000', '', '80102', XPCS, 19020630D, 24,
          44.25, XSMdashITEM, '', '');
        InsertData('28', 'SN 5TR78', XDESKTOP, XComputerIII866MHz, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '10000', XDUDLEY, '80005', XPCS,
          19030116D, 12, 26.7, XSMdashITEM, '', '');
        InsertData('29', 'SNM2453', XMONITOR, X24INCHUltrascan, ServiceItem.Status::Installed, ServiceItem.Priority::Low, '10000', XDUDLEY, '80105', XPCS, 19030116D, 24,
          70.35, XSMdashITEM, '', '');
        InsertData('2000-S-2', '', XDESKTOP, XComputerdashBasicPackage, ServiceItem.Status::Installed, ServiceItem.Priority::High, '30000', '', '8904-W', XPCS,
          19030102D, 16, 83.84, '', XKatherine, '');
    end;

    var
        ServiceItem: Record "Service Item";
        DemoDataSetup: Record "Demo Data Setup";
        XDESKTOP: Label 'DESKTOP';
        XComputerIII533MHz: Label 'Computer III 533 MHz';
        XComputerIII600MHz: Label 'Computer III 600 MHz';
        XZIPDRIVE: Label 'ZIPDRIVE';
        XSERVER: Label 'SERVER';
        XDrive250MB: Label 'Drive 250MB';
        XEnterpriseComputer667MHz: Label 'Enterprise Computer 667 MHz';
        XPCS: Label 'PCS';
        XSMdashITEM: Label 'SM-ITEM';
        XComputerIII733MHz: Label 'Computer III 733 MHz';
        XKatherine: Label 'Katherine';
        XComputerIII800MHz: Label 'Computer III 800 MHz';
        XTeamWorkComputer533MHz: Label 'Team Work Computer 533 MHz';
        XComputerIII866MHz: Label 'Computer III 866 MHz';
        XGRAPHICS: Label 'GRAPHICS';
        XGraphicProgram: Label 'Graphic Program';
        X17INCHM780Monitor: Label '17" M780 Monitor';
        XMONITOR: Label 'MONITOR';
        X24INCHUltrascan: Label '24" Ultrascan';
        XComputerdashBasicPackage: Label 'Computer - Basic Package';
        XDUDLEY: Label 'DUDLEY';
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData("No.": Text[250]; "Serial No.": Text[250]; "Service Item Group Code": Text[250]; Description: Text[250]; Status: Enum "Service Item Status"; Priority: Enum "Service Priority"; "Customer No.": Text[250]; "Ship-to Code": Text[250]; "Item No.": Text[250]; "Unit of Measure Code": Text[250]; "Warranty Starting Date (Parts)": Date; "Response Time (Hours)": Decimal; "Default Contract Value": Decimal; "No. Series": Text[250]; "Preferred Resource": Text[250]; "Service Price Group Code": Text[250])
    var
        ServiceItem: Record "Service Item";
        ResSkillMgt: Codeunit "Resource Skill Mgt.";
    begin
        ServiceItem.Init();
        ServiceItem.Validate("No.", "No.");
        ServiceItem.Insert(true);
        ServiceItem.Validate("Serial No.", "Serial No.");
        ServiceItem.OmitAssignResSkills(true);
        ServiceItem.Validate("Item No.", "Item No.");
        ServiceItem.Validate("Service Item Group Code", "Service Item Group Code");
        ServiceItem.OmitAssignResSkills(false);
        ServiceItem.Validate(Description, Description);
        ServiceItem.Validate(Status, Status);
        ServiceItem.Validate(Priority, Priority);
        ServiceItem.Validate("Customer No.", "Customer No.");
        ServiceItem.Validate("Ship-to Code", "Ship-to Code");
        ServiceItem.Validate("Unit of Measure Code", "Unit of Measure Code");
        ServiceItem.Validate("Warranty Starting Date (Parts)", MakeAdjustments.AdjustDate("Warranty Starting Date (Parts)"));
        ServiceItem.Validate("Response Time (Hours)", "Response Time (Hours)");
        ServiceItem.Validate(
          "Default Contract Value", Round(
            "Default Contract Value" * DemoDataSetup."Local Currency Factor",
            1 * DemoDataSetup."Local Precision Factor"));
        ServiceItem.Validate("No. Series", "No. Series");
        ServiceItem.Validate("Preferred Resource", "Preferred Resource");
        ServiceItem.Validate("Service Price Group Code", "Service Price Group Code");
        ServiceItem.Modify(true);
        ResSkillMgt.AssignServItemResSkills(ServiceItem);
    end;
}

