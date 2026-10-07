codeunit 132217 "Library - Lower Permissions"
{
    // This library uses permission recorder until platform implements lowering permissions, for now this is the simplest approach to achieve the same

    Permissions = TableData "Gen. Journal Batch" = rimd;
    SingleInstance = true;

    var
        PermissionsMock: Codeunit "Permissions Mock";
        HasChangedPermissionsBelowO365Full: Boolean;
        XO365FULLTxt: Label 'D365 Full Access';
        XCUSTOMERVIEWTxt: Label 'D365 Customer, View';
        XCUSTOMEREDITTxt: Label 'D365 Customer, Edit';
        XITEMVIEWTxt: Label 'D365 Item, View';
        XITEMEDITTxt: Label 'D365 Item, Edit';
        XSALESDOCCREATETxt: Label 'D365 Sales Doc, Edit';
        XSALESDOCPOSTTxt: Label 'D365 Sales Doc, Post';
        XBASICTxt: Label 'D365 Basic';
        XSETUPTxt: Label 'D365 Setup';
        XACCOUNTSRECEIVABLETxt: Label 'D365 Acc. Receivable';
        XBANKINGTxt: Label 'D365 Banking';
        XFINANCIALREPORTSTxt: Label 'D365 Financial Rep.';
        XJOURNALSEDITTxt: Label 'D365 Journals, Edit';
        XJOURNALSPOSTTxt: Label 'D365 Journals, Post';
        XACCOUNTSPAYABLETxt: Label 'D365 Acc. Payable';
        XVENDORVIEWTxt: Label 'D365 Vendor, View';
        XVENDOREDITTxt: Label 'D365 Vendor, Edit';
        XSECURITYTxt: Label 'Security', Locked = true;
        XPURCHDOCCREATETxt: Label 'D365 Purch Doc, Edit';
        XPURCHDOCPOSTTxt: Label 'D365 Purch Doc, Post';
        XTestPermissionSetTxt: Label 'Test Tables';
        XLOCALTxt: Label 'LOCAL';
        XDYNCRMMGTTxt: Label 'D365 Dyn CRM Mgt';
        XRMCONTTxt: Label 'RM-CONT';
        XRMCONTEDITTxt: Label 'RM-CONT, EDIT';
        XRMTODOTxt: Label 'RM-TODO';
        XRMTODOEDITTxt: Label 'RM-TODO, EDIT';
        XFIXEDASSETSSETUPTxt: Label 'D365 FA, Setup';
        XFIXEDASSETSVIEWTxt: Label 'D365 FA, View';
        XFIXEDASSETSEDITTxt: Label 'D365 FA, Edit';
        XBASICHRSETUPTxt: Label 'D365 HR, Setup';
        XBASICHRVIEWTxt: Label 'D365 HR, View';
        XBASICHREDITTxt: Label 'D365 HR, Edit';
        XCASHFLOWTxt: Label 'D365 Cash Flow';
        XD365BUSFULLTxt: Label 'D365 Bus Full Access';
        XD365BusinessPremiumTxt: Label 'D365 BUS PREMIUM', Locked = true;
        XD365EXTENSIONMGTTxt: Label 'D365 Extension Mgt';
        XTEAMMEMBERTxt: Label 'D365 Team Member';
        XREADTxt: Label 'D365 Read';
        XOPPMGTTxt: Label 'D365 Opportunity MGT';
        XINVENTORYSETUPTxt: Label 'D365 Inv, Setup';
        XINVENTORYCREATETxt: Label 'D365 Inv Doc, Create';
        XINVENTORYPOSTTxt: Label 'D365 Inv Doc, Post';
        IntercompanyPostingsSetupTok: Label 'D365 IC, SETUP', Locked = true;
        IntercompanyPostingsViewTok: Label 'D365 IC, VIEW', Locked = true;
        IntercompanyPostingsEditTok: Label 'D365 IC, EDIT', Locked = true;
        CostAccountingSetupTok: Label 'D365 COSTACC, SETUP', Locked = true;
        CostAccountingEditTok: Label 'D365 COSTACC, EDIT', Locked = true;
        CostAccountingViewTok: Label 'D365 COSTACC, VIEW', Locked = true;
        GlobalDimMgtTok: Label 'D365 GLOBAL DIM MGT', Locked = true;
        JobsEditTok: Label 'D365 JOBS, EDIT', Locked = true;
        InvtPickPutawayMovementTxt: Label 'WM-R/PA/A/P/S, POST';
        WhseMgtActivitiesTxt: Label 'WM-PERIODIC';
        BasicISVTok: Label 'D365 BASIC ISV', Locked = true;
        XBackupRestoreTok: Label 'D365 BACKUP/RESTORE';
        D365ServiceMgtTxt: Label 'D365PREM SMG, VIEW';
        D365ServiceMgtEditTxt: Label 'D365PREM SMG, EDIT';
        D365WhseEditTok: Label 'D365 WHSE, EDIT';

    procedure StartLoggingNAVPermissions(PermissionSetRoleID: Code[20])
    begin
        StartLoggingNAVPermissions();
        PushPermissionSetInternal(PermissionSetRoleID, true);
    end;

    procedure StartLoggingNAVPermissions()
    begin
        PermissionsMock.Start();
        HasChangedPermissionsBelowO365Full := false;
    end;

    procedure StopLoggingNAVPermissions()
    begin
        PermissionsMock.Stop();
    end;

    procedure HasChangedPermissions(): Boolean
    begin
        exit(HasChangedPermissionsBelowO365Full);
    end;

    procedure SetO365Basic()
    begin
        PushPermissionSet(XBASICTxt);
    end;

    procedure SetO365Full()
    begin
        PushPermissionSet(XO365FULLTxt);
    end;

    procedure SetCustomerView()
    begin
        PushPermissionSet(XCUSTOMERVIEWTxt);
    end;

    procedure SetCustomerEdit()
    begin
        PushPermissionSet(XCUSTOMEREDITTxt);
    end;

    procedure SetItemView()
    begin
        PushPermissionSet(XITEMVIEWTxt);
    end;

    procedure SetItemEdit()
    begin
        PushPermissionSet(XITEMEDITTxt);
    end;

    procedure SetSalesDocsCreate()
    begin
        PushPermissionSet(XSALESDOCCREATETxt);
    end;

    procedure SetPurchDocsCreate()
    begin
        PushPermissionSet(XPURCHDOCCREATETxt);
    end;

    procedure SetSalesDocsPost()
    begin
        PushPermissionSet(XSALESDOCPOSTTxt);
    end;

    procedure SetPurchDocsPost()
    begin
        PushPermissionSet(XPURCHDOCPOSTTxt);
    end;

    procedure SetO365Setup()
    begin
        PushPermissionSet(XSETUPTxt);
    end;

    procedure SetAccountReceivables()
    begin
        PushPermissionSet(XACCOUNTSRECEIVABLETxt);
    end;

    procedure SetBanking()
    begin
        PushPermissionSet(XBANKINGTxt);
    end;

    procedure SetO365CashFlow()
    begin
        PushPermissionSet(XCASHFLOWTxt);
    end;

    procedure SetFinancialReporting()
    begin
        PushPermissionSet(XFINANCIALREPORTSTxt);
    end;

    procedure SetJournalsPost()
    begin
        PushPermissionSet(XJOURNALSPOSTTxt);
    end;

    procedure SetJournalsEdit()
    begin
        PushPermissionSet(XJOURNALSEDITTxt);
    end;

    procedure SetAccountPayables()
    begin
        PushPermissionSet(XACCOUNTSPAYABLETxt);
    end;

    procedure SetVendorView()
    begin
        PushPermissionSet(XVENDORVIEWTxt);
    end;

    procedure SetVendorEdit()
    begin
        PushPermissionSet(XVENDOREDITTxt);
    end;

    procedure SetSecurity()
    begin
        PushPermissionSet(XSECURITYTxt);
    end;

    procedure SetOutsideO365Scope()
    begin
        PushPermissionSet('SUPER');
    end;

    procedure SetLocal()
    begin
        PushPermissionSet(XLOCALTxt);
    end;

    procedure SetCRMManagement()
    begin
        PushPermissionSet(XDYNCRMMGTTxt);
    end;

    procedure AddO365Basic()
    begin
        AddPermissionSet(XBASICTxt);
    end;

    procedure AddO365Full()
    begin
        AddPermissionSet(XO365FULLTxt);
    end;

    procedure AddCustomerView()
    begin
        AddPermissionSet(XCUSTOMERVIEWTxt);
    end;

    procedure AddCustomerEdit()
    begin
        AddPermissionSet(XCUSTOMEREDITTxt);
    end;

    procedure AddItemView()
    begin
        AddPermissionSet(XITEMVIEWTxt);
    end;

    procedure AddItemCreate()
    begin
        AddPermissionSet(XITEMEDITTxt);
    end;

    procedure AddSalesDocsCreate()
    begin
        AddPermissionSet(XSALESDOCCREATETxt);
    end;

    procedure AddPurchDocsCreate()
    begin
        AddPermissionSet(XPURCHDOCCREATETxt);
    end;

    procedure AddPurchDocsPost()
    begin
        AddPermissionSet(XPURCHDOCPOSTTxt);
    end;

    procedure AddSalesDocsPost()
    begin
        AddPermissionSet(XSALESDOCPOSTTxt);
    end;

    procedure AddO365Setup()
    begin
        AddPermissionSet(XSETUPTxt);
    end;

    procedure AddAccountReceivables()
    begin
        AddPermissionSet(XACCOUNTSRECEIVABLETxt);
    end;

    procedure AddBanking()
    begin
        AddPermissionSet(XBANKINGTxt);
    end;

    procedure AddFinancialReporting()
    begin
        AddPermissionSet(XFINANCIALREPORTSTxt);
    end;

    procedure AddJournalsPost()
    begin
        AddPermissionSet(XJOURNALSPOSTTxt);
    end;

    procedure AddJournalsEdit()
    begin
        AddPermissionSet(XJOURNALSEDITTxt);
    end;

    procedure AddAccountPayables()
    begin
        AddPermissionSet(XACCOUNTSPAYABLETxt);
    end;

    procedure AddVendorView()
    begin
        AddPermissionSet(XVENDORVIEWTxt);
    end;

    procedure AddVendorEdit()
    begin
        AddPermissionSet(XVENDOREDITTxt);
    end;

    procedure AddSecurity()
    begin
        AddPermissionSet(XSECURITYTxt);
    end;

    procedure AddLocal()
    begin
        AddPermissionSet(XLOCALTxt);
    end;

    procedure AddCRMManagement()
    begin
        AddPermissionSet(XDYNCRMMGTTxt);
    end;

    procedure AddRMCont()
    begin
        AddPermissionSet(XRMCONTTxt);
    end;

    procedure SetRMCont()
    begin
        PushPermissionSet(XRMCONTTxt);
    end;

    procedure AddRMContEdit()
    begin
        AddPermissionSet(XRMCONTEDITTxt);
    end;

    procedure SetRMContEdit()
    begin
        PushPermissionSet(XRMCONTEDITTxt);
    end;

    procedure AddRMTodo()
    begin
        AddPermissionSet(XRMTODOTxt);
    end;

    procedure SetRMTodo()
    begin
        PushPermissionSet(XRMTODOTxt);
    end;

    procedure AddRMTodoEdit()
    begin
        AddPermissionSet(XRMTODOEDITTxt);
    end;

    procedure SetRMTodoEdit()
    begin
        PushPermissionSet(XRMTODOEDITTxt);
    end;

    procedure PushPermissionSet(PermissionSetRoleID: Code[20])
    begin
        PushPermissionSetInternal(PermissionSetRoleID, true);
        OnAfterPushPermissionSet(PermissionSetRoleID)
    end;

    procedure PushPermissionSetWithoutDefaults(PermissionSetRoleID: Code[20])
    begin
        PushPermissionSetInternal(PermissionSetRoleID, false);
        OnAfterPushPermissionSet(PermissionSetRoleID)
    end;

    /// <summary>
    /// Sets only the specified permission set, without All Objects, Local etc.
    /// </summary>
    procedure SetExactPermissionSet(PermissionSetRoleID: Code[20])
    begin
        if not PermissionsMock.IsStarted() then
            exit;

        if (UpperCase(PermissionSetRoleID) <> UpperCase(XO365FULLTxt)) and
           (UpperCase(PermissionSetRoleID) <> UpperCase('SUPER'))
        then
            HasChangedPermissionsBelowO365Full := true;

        PermissionsMock.ClearAssignments();
        PermissionsMock.Assign(PermissionSetRoleID);
    end;

    local procedure PushPermissionSetInternal(PermissionSetRoleID: Code[20]; AddDefaults: Boolean)
    var
        PermissionSet: Record "Permission Set";
    begin
        if not PermissionsMock.IsStarted() then
            exit;

        if (UpperCase(PermissionSetRoleID) <> UpperCase(XO365FULLTxt)) and
           (UpperCase(PermissionSetRoleID) <> UpperCase('SUPER'))
        then
            HasChangedPermissionsBelowO365Full := true;

        PermissionsMock.Set(PermissionSetRoleID);
        PermissionsMock.Assign(XTestPermissionSetTxt);

        if AddDefaults then begin
            PermissionsMock.Assign(XBASICTxt);
            if PermissionSet.Get(XLOCALTxt) then
                PermissionsMock.Assign(XLOCALTxt);
        end;
    end;

    procedure AddPermissionSet(PermissionSetRoleID: Code[20])
    begin
        if not PermissionsMock.IsStarted() then
            exit;

        PermissionsMock.Assign(PermissionSetRoleID);
        OnAfterAddPermissionSet(PermissionSetRoleID);
    end;

    procedure AddO365INVSetup()
    begin
        AddPermissionSet(XINVENTORYSETUPTxt);
    end;

    procedure AddO365INVCreate()
    begin
        AddPermissionSet(XINVENTORYCREATETxt);
    end;

    procedure AddO365INVPost()
    begin
        AddPermissionSet(XINVENTORYPOSTTxt);
    end;

    procedure SetO365INVSetup()
    begin
        PushPermissionSet(XINVENTORYSETUPTxt);
    end;

    procedure SetO365INVCreate()
    begin
        PushPermissionSet(XINVENTORYCREATETxt);
    end;

    procedure SetO365INVPost()
    begin
        PushPermissionSet(XINVENTORYPOSTTxt);
    end;

    procedure SetBackupRestore()
    begin
        PushPermissionSet(XBackupRestoreTok);
    end;

    procedure AddO365FASetup()
    begin
        AddPermissionSet(XFIXEDASSETSSETUPTxt);
    end;

    procedure AddO365FAView()
    begin
        AddPermissionSet(XFIXEDASSETSVIEWTxt);
    end;

    procedure AddO365FAEdit()
    begin
        AddPermissionSet(XFIXEDASSETSEDITTxt);
    end;

    procedure SetO365FASetup()
    begin
        PushPermissionSet(XFIXEDASSETSSETUPTxt);
    end;

    procedure SetO365FAView()
    begin
        PushPermissionSet(XFIXEDASSETSVIEWTxt);
    end;

    procedure SetO365FAEdit()
    begin
        PushPermissionSet(XFIXEDASSETSEDITTxt);
    end;

    procedure AddO365HRSetup()
    begin
        AddPermissionSet(XBASICHRSETUPTxt);
    end;

    procedure AddO365HRView()
    begin
        AddPermissionSet(XBASICHRVIEWTxt);
    end;

    procedure AddO365HREdit()
    begin
        AddPermissionSet(XBASICHREDITTxt);
    end;

    procedure SetO365HRSetup()
    begin
        PushPermissionSet(XBASICHRSETUPTxt);
    end;

    procedure SetO365HRView()
    begin
        PushPermissionSet(XBASICHRVIEWTxt);
    end;

    procedure SetO365HREdit()
    begin
        PushPermissionSet(XBASICHREDITTxt);
    end;

    procedure AddO365CashFlow()
    begin
        AddPermissionSet(XCASHFLOWTxt);
    end;

    procedure SetO365BusFull()
    begin
        PushPermissionSet(XD365BUSFULLTxt);
    end;

    procedure AddO365BusFull()
    begin
        AddPermissionSet(XD365BUSFULLTxt);
    end;

    procedure SetO365BusinessPremium()
    begin
        PushPermissionSet(XD365BusinessPremiumTxt);
    end;

    procedure AddO365BusinessPremium()
    begin
        AddPermissionSet(XD365BusinessPremiumTxt);
    end;

    procedure SetO365ExtensionMGT()
    begin
        PushPermissionSet(XD365EXTENSIONMGTTxt);
    end;

    procedure AddO365ExtensionMGT()
    begin
        AddPermissionSet(XD365EXTENSIONMGTTxt);
    end;

    procedure SetO365GlobalDimMgt()
    begin
        PushPermissionSet(GlobalDimMgtTok);
    end;

    procedure AddO365GlobalDimMgt()
    begin
        AddPermissionSet(GlobalDimMgtTok);
    end;

    procedure SetO365ServiceMgtRead()
    begin
        PushPermissionSet(D365ServiceMgtTxt);
    end;

    procedure AddO365ServiceMgtRead()
    begin
        AddPermissionSet(D365ServiceMgtTxt);
    end;

    procedure SetO365ServiceMgtEdit()
    begin
        PushPermissionSet(D365ServiceMgtEditTxt);
    end;

    procedure AddO365ServiceMgtEdit()
    begin
        AddPermissionSet(D365ServiceMgtEditTxt);
    end;

    procedure AddBackupRestore()
    begin
        AddPermissionSet(XBackupRestoreTok);
    end;

    procedure SetTeamMember()
    begin
        PushPermissionSet(XTEAMMEMBERTxt);
    end;

    procedure AddTeamMember()
    begin
        AddPermissionSet(XTEAMMEMBERTxt);
    end;

    procedure SetRead()
    begin
        PushPermissionSet(XREADTxt);
    end;

    procedure AddeRead()
    begin
        AddPermissionSet(XREADTxt);
    end;

    procedure SetOppMGT()
    begin
        PushPermissionSet(XOPPMGTTxt);
    end;

    procedure AddOppMGT()
    begin
        AddPermissionSet(XOPPMGTTxt);
    end;

    procedure SetIntercompanyPostingsEdit()
    begin
        PushPermissionSet(IntercompanyPostingsEditTok);
    end;

    procedure AddIntercompanyPostingsEdit()
    begin
        AddPermissionSet(IntercompanyPostingsEditTok);
    end;

    procedure SetIntercompanyPostingsView()
    begin
        PushPermissionSet(IntercompanyPostingsViewTok);
    end;

    procedure AddIntercompanyPostingsView()
    begin
        AddPermissionSet(IntercompanyPostingsViewTok);
    end;

    procedure SetIntercompanyPostingsSetup()
    begin
        PushPermissionSet(IntercompanyPostingsSetupTok);
    end;

    procedure AddIntercompanyPostingsSetup()
    begin
        AddPermissionSet(IntercompanyPostingsSetupTok);
    end;

    procedure SetCostAccountingEdit()
    begin
        PushPermissionSet(CostAccountingEditTok);
    end;

    procedure AddCostAccountingEdit()
    begin
        AddPermissionSet(CostAccountingEditTok);
    end;

    procedure SetCostAccountingView()
    begin
        PushPermissionSet(CostAccountingViewTok);
    end;

    procedure AddCostAccountingView()
    begin
        AddPermissionSet(CostAccountingViewTok);
    end;

    procedure SetCostAccountingSetup()
    begin
        PushPermissionSet(CostAccountingSetupTok);
    end;

    procedure AddCostAccountingSetup()
    begin
        AddPermissionSet(CostAccountingSetupTok);
    end;

    [Scope('OnPrem')]
    procedure SetJobs()
    begin
        PushPermissionSet(JobsEditTok);
    end;

    [Scope('OnPrem')]
    procedure AddJobs()
    begin
        AddPermissionSet(JobsEditTok);
    end;

    [Scope('OnPrem')]
    procedure AddInvtPickPutawayMovement()
    begin
        AddPermissionSet(InvtPickPutawayMovementTxt);
    end;

    [Scope('OnPrem')]
    procedure AddWhseMgtActivities()
    begin
        AddPermissionSet(WhseMgtActivitiesTxt);
    end;

    [Scope('OnPrem')]
    procedure SetO365BasicISV()
    begin
        PushPermissionSetInternal(BasicISVTok, false);
    end;

    [Scope('OnPrem')]
    procedure SetO365WhseEdit()
    begin
        PushPermissionSet(D365WhseEditTok);
    end;

    [Scope('OnPrem')]
    procedure AddO365WhseEdit()
    begin
        AddPermissionSet(D365WhseEditTok);
    end;

    [IntegrationEvent(false, false)]
    [Scope('OnPrem')]
    procedure OnGetDisableEnforcingPermissionChange(var Disable: Boolean)
    begin
    end;

    [Scope('OnPrem')]
    procedure CanLowerPermission(): Boolean
    begin
        exit(PermissionsMock.IsStarted());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPushPermissionSet(PermissionSetRoleID: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddPermissionSet(PermissionSetRoleID: Code[20])
    begin
    end;
}

