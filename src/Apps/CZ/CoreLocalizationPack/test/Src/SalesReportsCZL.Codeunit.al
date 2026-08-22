codeunit 148099 "Sales Reports CZL"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2=Field Value;';
        ReminderPostingDescriptionLbl: Label 'Reminder %1', Comment = '%1 = Reminder No.';
        CustomDescriptionTok: Label 'Custom description ', Locked = true;
        NoInteractionLogEntryErr: Label 'No interaction log entry has been created for the issued reminder.';
        DescriptionMustReferenceIssuedNoErr: Label 'The interaction log description must reference the issued reminder number.';
        DescriptionMustNotReferencePreAssignedNoErr: Label 'The interaction log description must not reference the pre-assigned reminder number.';
        CustomDescriptionMustBePreservedErr: Label 'The customized posting description must be preserved in the interaction log.';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Sales Reports CZL");

        LibraryRandom.SetSeed(1);  // Use Random Number Generator to generate the seed for RANDOM function.
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Sales Reports CZL");

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Sales Reports CZL");
    end;

    [Test]
    [HandlerFunctions('RequestPageSalesCrMemoHandler')]
    procedure PrintingInternalCorrectionDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
        ErrorMessage: Text;
    begin
        Initialize();

        // [GIVEN] The sales credit memo with internal correction type has been created.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.Validate("Credit Memo Type CZL", SalesHeader."Credit Memo Type CZL"::"Internal Correction");
        SalesHeader.Modify();

        // [GIVEN] The sales credit memo has been posted.
        PostedDocumentNo := PostSalesDocument(SalesHeader);

        // [WHEN] Post sales credit memo.
        PrintCreditMemo(PostedDocumentNo);

        // [THEN] The report will be correctly printed.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_SalesCrMemoHeader', PostedDocumentNo);
        if not LibraryReportDataset.GetNextRow() then begin
            ErrorMessage := StrSubstNo(RowNotFoundErr, 'No_SalesCrMemoHeader', PostedDocumentNo);
            Error(ErrorMessage);
        end;
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'CreditMemoType_SalesCrMemoHeader', Format(SalesHeader."Credit Memo Type CZL"::"Internal Correction", 0, '<Number>'));
    end;

    [Test]
    [HandlerFunctions('RequestPageReminderHandler')]
    procedure LogInteractionUsesIssuedReminderNoInDescription()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        InteractionLogEntry: Record "Interaction Log Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        PreAssignedNo: Code[20];
    begin
        // [SCENARIO 641874] Printing an issued reminder with "Log Interaction" enabled logs the issued reminder number, not the original (pre-assigned) reminder number.
        Initialize();

        // [GIVEN] The interaction template has been set up for the "Sales Rmdr." document type.
        SetupSalesRmdrInteractionTemplate();

        // [GIVEN] The customer linked to a contact has been created.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] The issued reminder whose posting description still holds the pre-assigned (unissued) reminder number has been created.
        PreAssignedNo :=
          LibraryUtility.GenerateRandomCode20(IssuedReminderHeader.FieldNo("Pre-Assigned No."), Database::"Issued Reminder Header");
        MockIssuedReminder(IssuedReminderHeader, Customer."No.", PreAssignedNo, StrSubstNo(ReminderPostingDescriptionLbl, PreAssignedNo));

        // [WHEN] Print the issued reminder with the "Log Interaction" option enabled.
        PrintReminder(IssuedReminderHeader);

        // [THEN] The interaction log entry will be created for the issued reminder and linked to the customer's contact.
        FindInteractionLogEntry(InteractionLogEntry, IssuedReminderHeader."No.");
        InteractionLogEntry.TestField("Contact No.", Contact."No.");

        // [THEN] The description will reference the issued reminder number and not the pre-assigned one.
        Assert.AreEqual(
          StrSubstNo(ReminderPostingDescriptionLbl, IssuedReminderHeader."No."), InteractionLogEntry.Description,
          DescriptionMustReferenceIssuedNoErr);
        Assert.AreNotEqual(
          StrSubstNo(ReminderPostingDescriptionLbl, PreAssignedNo), InteractionLogEntry.Description,
          DescriptionMustNotReferencePreAssignedNoErr);
    end;

    [Test]
    [HandlerFunctions('RequestPageReminderHandler')]
    procedure LogInteractionKeepsCustomizedPostingDescription()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        InteractionLogEntry: Record "Interaction Log Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        CustomPostingDescription: Text[100];
        PreAssignedNo: Code[20];
    begin
        // [SCENARIO 641874] The customized posting description is logged as-is and is not replaced by the default reminder text.
        Initialize();

        // [GIVEN] The interaction template has been set up for the "Sales Rmdr." document type.
        SetupSalesRmdrInteractionTemplate();

        // [GIVEN] The customer linked to a contact has been created.
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] The issued reminder with a customized posting description has been created.
        PreAssignedNo :=
          LibraryUtility.GenerateRandomCode20(IssuedReminderHeader.FieldNo("Pre-Assigned No."), Database::"Issued Reminder Header");
        CustomPostingDescription := CopyStr(CustomDescriptionTok + PreAssignedNo, 1, MaxStrLen(CustomPostingDescription));
        MockIssuedReminder(IssuedReminderHeader, Customer."No.", PreAssignedNo, CustomPostingDescription);

        // [WHEN] Print the issued reminder with the "Log Interaction" option enabled.
        PrintReminder(IssuedReminderHeader);

        // [THEN] The customized posting description will be preserved in the interaction log entry.
        FindInteractionLogEntry(InteractionLogEntry, IssuedReminderHeader."No.");
        Assert.AreEqual(CustomPostingDescription, InteractionLogEntry.Description, CustomDescriptionMustBePreservedErr);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10000, 2));
        SalesLine.Validate(Description, SalesHeader."No.");
        SalesLine.Modify(true);
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PrintCreditMemo(DocumentNo: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader.SetRecFilter();
        Report.Run(Report::"Sales Credit Memo CZL", true, false, SalesCrMemoHeader);
    end;

    local procedure SetupSalesRmdrInteractionTemplate()
    var
        InteractionGroup: Record "Interaction Group";
        InteractionTemplate: Record "Interaction Template";
        InteractionTemplateSetup: Record "Interaction Template Setup";
    begin
        if InteractionGroup.IsEmpty() then
            LibraryMarketing.CreateInteractionGroup(InteractionGroup);
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);

        if not InteractionTemplateSetup.Get() then begin
            InteractionTemplateSetup.Init();
            InteractionTemplateSetup.Insert();
        end;
        InteractionTemplateSetup.Validate("Sales Rmdr.", InteractionTemplate.Code);
        InteractionTemplateSetup.Modify(true);
    end;

    local procedure MockIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header"; CustomerNo: Code[20]; PreAssignedNo: Code[20]; PostingDescription: Text)
    begin
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." :=
          LibraryUtility.GenerateRandomCode20(IssuedReminderHeader.FieldNo("No."), Database::"Issued Reminder Header");
        IssuedReminderHeader."Customer No." := CustomerNo;
        IssuedReminderHeader."Pre-Assigned No." := PreAssignedNo;
        IssuedReminderHeader."Posting Description" :=
          CopyStr(PostingDescription, 1, MaxStrLen(IssuedReminderHeader."Posting Description"));
        IssuedReminderHeader."Posting Date" := WorkDate();
        IssuedReminderHeader."Document Date" := WorkDate();
        IssuedReminderHeader."Due Date" := WorkDate();
        IssuedReminderHeader.Insert();
    end;

    local procedure PrintReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        IssuedReminderHeader.SetRecFilter();
        Commit();
        Report.Run(Report::"Reminder CZL", true, false, IssuedReminderHeader);
    end;

    local procedure FindInteractionLogEntry(var InteractionLogEntry: Record "Interaction Log Entry"; IssuedReminderNo: Code[20])
    begin
        InteractionLogEntry.SetRange("Document Type", InteractionLogEntry."Document Type"::"Sales Rmdr.");
        InteractionLogEntry.SetRange("Document No.", IssuedReminderNo);
        Assert.IsTrue(InteractionLogEntry.FindLast(), NoInteractionLogEntryErr);
    end;

    [RequestPageHandler]
    procedure RequestPageSalesCrMemoHandler(var SalesCreditMemoCZL: TestRequestPage "Sales Credit Memo CZL")
    begin
        SalesCreditMemoCZL.SaveAsXml(
          LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure RequestPageReminderHandler(var ReminderCZL: TestRequestPage "Reminder CZL")
    begin
        ReminderCZL.LogInteractionCZL.SetValue(true);
        ReminderCZL.SaveAsXml(
          LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

