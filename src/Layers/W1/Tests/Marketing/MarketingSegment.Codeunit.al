codeunit 136213 "Marketing Segment"
{
    // // [FEATURE] [Segment] [Marketing]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Segment] [Marketing]
    end;

    var
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        NoOfCriteriaActions: Label 'No Of Criteria Actions Must be %1 in Segment %2.';
        SalesPersonCode2: Code[20];
        SegmentLineNotExist: Label 'Segment Line with Sales Person Code %1 must not exist.';
        SegmentLineExist: Label 'Segment Line with Sales Person Code %1 must exist.';
        ContactNo3: Code[20];

    [Test]
    [HandlerFunctions('AddContactHandler')]
    [Scope('OnPrem')]
    procedure SegmentAddContactWithReport()
    var
        Segment: TestPage Segment;
    begin
        // Create Segment by Page and add Segment Line through Add Contact Report.

        // Setup: Create Contact.
        Initialize();
        ContactNo3 := CreateContact();  // Global Variable used for Request Page Handler

        // Exercise : Create Segment and add Contact through Report.
        Segment.OpenNew();  // Open New Segment.
        Segment.Description.Activate();  // Used to generate the Segment No.
        Commit();  // Commit required to run the report.
        Segment.AddContacts.Invoke();

        // Verify : Verify Segment Line.
        VerifySegmentLine(Segment."No.".Value, ContactNo3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentAddContactManual()
    var
        Segment: TestPage Segment;
        ContactNo: Code[20];
    begin
        // Create Segment by Page and add Segment Line manually.

        // Setup: Create Contact.
        Initialize();
        ContactNo := CreateContact();

        // Exercise: Create Segment Line and add Contact Manually.
        Segment.OpenNew();  // Open New Segment.
        CreateSegmentLineByPage(Segment, ContactNo);

        // Verify: Verify Segment Line.
        VerifySegmentLine(Segment."No.".Value, ContactNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentLineNoOfCriteriaActions()
    var
        Segment: TestPage Segment;
        ContactNo: Code[20];
        NoOfCriteriaActionsAfterReduce: Integer;
    begin
        // Validate No. of Criteria Action on segment updates on adding segment line.

        // Setup: Create Contact and update Contact with Sales Person Code.
        Initialize();
        ContactNo := CreateContact();
        UpdateContactWithSalesPersonCode(ContactNo);

        // Exercise: Create Segment Line.
        Segment.OpenNew();  // Open New Segment.
        CreateSegmentLineByPage(Segment, ContactNo);
        NoOfCriteriaActionsAfterReduce := GetNoOfCriteriaActions(Segment."No.".Value);

        // Verify: Verify No. of Criteria Action on Segment is updated.
        Assert.AreEqual(1, NoOfCriteriaActionsAfterReduce, StrSubstNo(NoOfCriteriaActions, 1, Segment."No."));  // Test for one Transaction.
    end;

    [Test]
    [HandlerFunctions('ReduceContactHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ReduceSegmentLineWithConfirmation()
    var
        Segment: TestPage Segment;
        SalesPersonCode: Code[20];
        NoOfCriteriaActionsAfterReduce: Integer;
    begin
        // Reduce Contact on Segment Line with confirmation to Delete No. of Criteria Action Reduced to Zero.

        // Setup:  Create Contact and update Contact with Sales Person Code, Create Segment with line.
        Initialize();
        SalesPersonCode := CreateSegmentWithContact(Segment);

        // Exercise: Run Reduce Contact Report from page.
        Segment.ReduceContacts.Invoke();
        NoOfCriteriaActionsAfterReduce := GetNoOfCriteriaActions(Segment."No.".Value);

        // Verify: Verify Contact is reduced from the Segment and Verify No. of Criteria Action Reduced to Zero.
        Assert.IsFalse(
          FindSegmentLineSalesPersonCode(Segment."No.".Value, SalesPersonCode), StrSubstNo(SegmentLineNotExist, SalesPersonCode));
        Assert.AreEqual(0, NoOfCriteriaActionsAfterReduce, StrSubstNo(NoOfCriteriaActions, 0, Segment."No."));
    end;

    [Test]
    [HandlerFunctions('ReduceContactHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure ReduceSegmentLineWithWithOutConfirmation()
    var
        Segment: TestPage Segment;
        SalesPersonCode: Code[20];
        NoOfCriteriaActionsBeforeReduce: Integer;
        NoOfCriteriaActionsAfterReduce: Integer;
    begin
        // Reduce Contact on Segment Line without confirmation to Delete No. of Criteria Action.

        // Setup:  Create Contact and update Contact with Sales Person Code, Create Segment with line.
        Initialize();
        SalesPersonCode := CreateSegmentWithContact(Segment);
        NoOfCriteriaActionsBeforeReduce := GetNoOfCriteriaActions(Segment."No.".Value);

        // Exercise: Create Segment Line and add Contact Manually.
        Segment.ReduceContacts.Invoke();
        NoOfCriteriaActionsAfterReduce := GetNoOfCriteriaActions(Segment."No.".Value);

        // Verify: Verify Contact is reduced from the Segment and Verify No. of Criteria Action is not Reduced.
        Assert.IsFalse(
          FindSegmentLineSalesPersonCode(Segment."No.".Value, SalesPersonCode), StrSubstNo(SegmentLineNotExist, SalesPersonCode));
        Assert.AreEqual(
          NoOfCriteriaActionsAfterReduce, NoOfCriteriaActionsBeforeReduce + 1,
          StrSubstNo(NoOfCriteriaActions, NoOfCriteriaActionsAfterReduce, Segment."No."));
    end;

    [Test]
    [HandlerFunctions('RefineContactHandler')]
    [Scope('OnPrem')]
    procedure RefineSegmentLine()
    var
        Segment: TestPage Segment;
        SalesPersonCode: Code[20];
    begin
        // Refine Contact on Segment Line.

        // Setup:  Create Contact and update Contact with Sales Person Code, Create Segment with line.
        Initialize();
        SalesPersonCode := CreateSegmentWithContacts(Segment);

        // Exercise: Invoke Refine Contact Report.
        Segment.RefineContacts.Invoke();

        // Verify: Verify Segment Line is Refined.
        Assert.IsFalse(
          FindSegmentLineSalesPersonCode(Segment."No.".Value, SalesPersonCode), StrSubstNo(SegmentLineNotExist, SalesPersonCode));
    end;

    [Test]
    [HandlerFunctions('RefineContactHandler')]
    [Scope('OnPrem')]
    procedure ReRefineSegmentLine()
    var
        Segment: TestPage Segment;
        SalesPersonCode: Code[20];
        NoOfCriteriaActionsAfterRefine: Integer;
        NoOfCriteriaActionsAfterReRefine: Integer;
    begin
        // Re Refine Contact on Segment Line and verify No. of Criteria Action increases on Re Refine.

        // Setup:  Create Contact and update contact with Sales Person Code, Create Segment with line and Refine it.
        Initialize();
        SalesPersonCode := CreateSegmentWithContacts(Segment);
        Segment.RefineContacts.Invoke();
        NoOfCriteriaActionsAfterRefine := GetNoOfCriteriaActions(Segment."No.".Value);

        // Exercise: Re Refine Contact on Segment Line.
        Segment.RefineContacts.Invoke();
        NoOfCriteriaActionsAfterReRefine := GetNoOfCriteriaActions(Segment."No.".Value);

        // Verify: Verify Segment Line is Refined and No. of Criteria Action increases on Re Refine.
        Assert.IsFalse(
          FindSegmentLineSalesPersonCode(Segment."No.".Value, SalesPersonCode), StrSubstNo(SegmentLineNotExist, SalesPersonCode));
        Assert.AreEqual(
          NoOfCriteriaActionsAfterReRefine, NoOfCriteriaActionsAfterRefine + 1,
          StrSubstNo(NoOfCriteriaActions, NoOfCriteriaActionsAfterReRefine, Segment."No."));
    end;

    [Test]
    [HandlerFunctions('SaveSegmentCriteriaHandler')]
    [Scope('OnPrem')]
    procedure SaveSegmentCriteria()
    var
        SavedSegmentCriteria: Record "Saved Segment Criteria";
        Segment: TestPage Segment;
    begin
        // Create Contact and Save Criteria.

        // Setup:  Create Contact and update Contact with Sales Person Code, Create Segment with line.
        Initialize();
        CreateSegmentWithContacts(Segment);

        // Exercise: Save Segment Criteria.
        Segment.SaveCriteria.Invoke();

        // Verify: Verify Segment Criteria is saved.
        SavedSegmentCriteria.SetRange(Code, SalesPersonCode2);
        SavedSegmentCriteria.FindFirst();
    end;

    [Test]
    [HandlerFunctions('ReuseCriteriaSegmentHandler,SaveSegmentCriteriaHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ReuseSegmentCriteria()
    var
        Segment: TestPage Segment;
    begin
        // Delete Last Row in Segment, Reuse segment criteria and Validate the Segment.

        // Setup:  Create Contact and update Contact with Sales Person Code, Create Segment with line, Save Segment Criteria.
        Initialize();
        CreateSegmentWithContacts(Segment);
        Segment.SaveCriteria.Invoke();

        // Exercise: Delete Last Row in Segment, Reuse Segment Criteria and Validate the Segment.
        DeleteLastRecordSegmentLine(Segment."No.".Value);
        Segment.ReuseCriteria.Invoke();

        // Verify: Verify Segment Line.
        Assert.IsTrue(
          FindSegmentLineSalesPersonCode(Segment."No.".Value, SalesPersonCode2), StrSubstNo(SegmentLineExist, SalesPersonCode2));
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SegmentMultiLineCoverSheet()
    var
        SegmentHeader: Record "Segment Header";
        Contact1: Record Contact;
        Contact2: Record Contact;
        InteractionTemplateSetup: Record "Interaction Template Setup";
        InteractionLogEntry: Record "Interaction Log Entry";
        Segment: TestPage Segment;
    begin
        // [FEATURE] [Cover Sheet]
        // [SCENARIO 199759] Print Cover Sheet report for Segment with 2 Contacts and Log Interaction
        Initialize();

        // [GIVEN] Contacts "C1" and "C2" with addresses
        CreateContactWithAddress(Contact1);
        CreateContactWithAddress(Contact2);

        // [GIVEN] Segment "S" with Contacts "C1" and "C2"
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateSegmentLineForContact(SegmentHeader."No.", Contact1."No.");
        CreateSegmentLineForContact(SegmentHeader."No.", Contact2."No.");
        Segment.OpenEdit();
        Segment.GotoRecord(SegmentHeader);
        LibraryVariableStorage.Enqueue(true);
        Commit();

        // [WHEN] Cover Sheet report printed for Segment "S" with Log Interaction = TRUE
        Segment.CoverSheet.Invoke();

        // [THEN] Company Information is printed and Contact Information is printed on separate page per Contact
        LibraryReportDataset.LoadDataSetFile();
        VerifyContactCoverSheetCompanyInfoReport();
        VerifyContactCoverSheetContactInfoReport(Contact1);
        VerifyContactCoverSheetContactInfoReport(Contact2);

        // [THEN] Interaction Log Entry created for Contacts "C1" and "C2"
        InteractionTemplateSetup.Get();
        InteractionLogEntry.SetFilter("Contact No.", '%1|%2', Contact1."No.", Contact2."No.");
        InteractionLogEntry.SetRange("Interaction Template Code", InteractionTemplateSetup."Cover Sheets");
        Assert.RecordCount(InteractionLogEntry, 2);
    end;

    [Test]
    [HandlerFunctions('ContactCoverSheetReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SegmentCoverSheetNoLog()
    var
        SegmentHeader: Record "Segment Header";
        Contact: Record Contact;
        InteractionTemplateSetup: Record "Interaction Template Setup";
        InteractionLogEntry: Record "Interaction Log Entry";
        Segment: TestPage Segment;
    begin
        // [FEATURE] [Cover Sheet]
        // [SCENARIO 199759] Print Cover Sheet report for Segment with 1 Contact without Log Interaction
        Initialize();

        // [GIVEN] Contact "C"
        CreateContactWithAddress(Contact);

        // [GIVEN] Segment "S" with Contact "C"
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        CreateSegmentLineForContact(SegmentHeader."No.", Contact."No.");
        Segment.OpenEdit();
        Segment.GotoRecord(SegmentHeader);
        LibraryVariableStorage.Enqueue(false);
        Commit();

        // [WHEN] Cover Sheet report printed for Segment "S" with Log Interaction = FALSE
        Segment.CoverSheet.Invoke();

        LibraryReportDataset.LoadDataSetFile();
        // [THEN] Report is printed with Contact "C" Information
        VerifyContactCoverSheetContactInfoReport(Contact);

        // [THEN] No Interaction Log Entries created
        InteractionTemplateSetup.Get();
        InteractionLogEntry.SetFilter("Contact No.", Contact."No.");
        InteractionLogEntry.SetRange("Interaction Template Code", InteractionTemplateSetup."Cover Sheets");
        Assert.RecordIsEmpty(InteractionLogEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentPageExportContactsSaaS()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Segment: TestPage Segment;
        ContactNo: Code[20];
    begin
        // [FEATURE] [UI] [Contact]
        // [SCENARIO 280990] Export Segment contacts calls OData Fields Export in SaaS client

        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(true);
        ContactNo := CreateContact();

        Segment.OpenNew(); // Open New Segment.
        CreateSegmentLineByPage(Segment, ContactNo);

        Segment.ExportContacts.Invoke();

        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SegmentPageExportContactsOnPrem()
    var
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        Segment: TestPage Segment;
        ContactNo: Code[20];
    begin
        // [FEATURE] [UI] [Contact]
        // [SCENARIO 280990] Export Segment contacts calls XMLPORT in non-SaaS client

        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);
        ContactNo := CreateContact();

        Segment.OpenNew(); // Open New Segment.
        CreateSegmentLineByPage(Segment, ContactNo);

        Segment.ExportContacts.Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InteractionTemplateCodeValidateHdrWhenConfirmUpdateSegLines()
    var
        SegmentHeader: Record "Segment Header";
        LanguageCode1: Code[10];
        LanguageCode2: Code[10];
        InteractionTemplateCode: array[3] of Code[10];
        UniqueAttachmentNo: Integer;
        Line1No: Integer;
        Line2No: Integer;
    begin
        // [FEATURE] [Attachment]
        // [SCENARIO 295002] When validate Interaction Template Code in Segment Header then Segment Line inherits header Attachment
        // [SCENARIO 295002] if Attachment has not been set in the line
        Initialize();
        LanguageCode1 := 'ENU';
        LanguageCode2 := LibraryERM.GetAnyLanguageDifferentFromCurrent();

        // [GIVEN] Interaction Template Code 'ABSTRACT' with Language Code (Default) = 'ENU' and Attachment
        // [GIVEN] Interaction Template Code 'BUS' with other Language Code (Default) and other Attachment
        // [GIVEN] Interaction Template Code 'COVERSH' with <blank> Language Code and no Attachment
        InteractionTemplateCode[1] :=
          CreateInteractionTemplateWithLanguageAndAttachment(LanguageCode1, LibraryRandom.RandInt(10));
        InteractionTemplateCode[2] :=
          CreateInteractionTemplateWithLanguageAndAttachment(LanguageCode2, LibraryRandom.RandInt(10));
        InteractionTemplateCode[3] :=
          CreateInteractionTemplateWithLanguageAndAttachment('', 0);

        // [GIVEN] Segment with two Segment Lines:
        // [GIVEN] Line "L1" with Interaction Template Code = 'BUS'
        // [GIVEN] Line "L2" with Interaction Template Code = 'COVERSH'
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        Line1No := CreateSegmentLineWithInteractionTemplate(SegmentHeader."No.", InteractionTemplateCode[2], CreateContact());
        Line2No := CreateSegmentLineWithInteractionTemplate(SegmentHeader."No.", InteractionTemplateCode[3], CreateContact());
        UniqueAttachmentNo := GetAttachmentNoFromSegmentLine(SegmentHeader."No.", Line1No);

        // [WHEN] Validate Interaction Template Code = 'ABSTRACT' in Segment Header
        SegmentHeader.Validate("Interaction Template Code", InteractionTemplateCode[1]);

        // [THEN] Segment Header has Language Code (Default) = 'ENU' and Attachment
        SegmentHeader.TestField("Language Code (Default)", LanguageCode1);
        SegmentHeader.TestField("Attachment No.");

        // [THEN] Both Segment Lines have Interaction Template Code = 'ABSTRACT'
        // [THEN] Segment Line "L1" Attachment and Language Code are not changed
        // [THEN] Segment Line "L2" has same Attachment and Language Code as Segment Header
        VerifySegmentLineWithAttachment(SegmentHeader."No.", Line1No, InteractionTemplateCode[1], LanguageCode2, UniqueAttachmentNo);
        VerifySegmentLineWithAttachment(
          SegmentHeader."No.", Line2No, InteractionTemplateCode[1], LanguageCode1, SegmentHeader."Attachment No.");
    end;

    [Test]
    procedure PersonContactInfoInSegmentLine()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
    begin
        // [FEATURE] [UT] [Segment Line] [Contact]
        // [SCENARIO 408657] Segment Line contains contact information from Contact with type = Person
        Initialize();

        // [GIVEN] Contact "C1" with "Phone No." = "999-999-99-99"
        // [GIVEN] "Mobile Phone No." = "888-888-88-88"
        // [GIVEN] "E-Mail" = "user@contoso.com"
        LibraryMarketing.CreatePersonContact(Contact);
        Contact.Validate("Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        Contact.Validate("Mobile Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        Contact.Validate("E-Mail", StrSubstNo('%1@%1', LibraryUtility.GenerateGUID()));
        Contact.Modify(true);

        // [GIVEN] Segment Line with "Contact No." = "C1"
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentLine.Validate("Contact No.", Contact."No.");
        SegmentLine.Modify(true);

        // [WHEN] Calculate fields "Contact Phone No.", "Contact Mobile Phone No." and "Contact Email"
        SegmentLine.CalcFields(
            "Contact Phone No.", "Contact Mobile Phone No.", "Contact Email");

        // [THEN] "Segment Line"."Contact Phone No." = "999-999-99-99"
        SegmentLine.TestField("Contact Phone No.", Contact."Phone No.");

        // [THEN] "Segment Line"."Contact Mobile Phone No." = "888-888-88-88"
        SegmentLine.TestField("Contact Mobile Phone No.", Contact."Mobile Phone No.");

        // [THEN] "Segment Line"."Contact Email" = "user@contoso.com"
        SegmentLine.TestField("Contact Email", Contact."E-Mail");
    end;

    [Test]
    procedure CompanyContactInfoInSegmentLine()
    var
        SegmentHeader: Record "Segment Header";
        SegmentLine: Record "Segment Line";
        Contact: Record Contact;
    begin
        // [FEATURE] [UT] [Segment Line] [Contact]
        // [SCENARIO 408657] Segment Line contains contact information from Contact with type = Company
        Initialize();

        // [GIVEN] Contact "C1" with "Phone No." = "999-999-99-99"
        // [GIVEN] "Mobile Phone No." = "888-888-88-88"
        // [GIVEN] "E-Mail" = "user@contoso.com"
        LibraryMarketing.CreateCompanyContact(Contact);
        Contact.Validate("Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        Contact.Validate("Mobile Phone No.", LibraryUtility.GenerateRandomPhoneNo());
        Contact.Validate("E-Mail", StrSubstNo('%1@%1', LibraryUtility.GenerateGUID()));
        Contact.Modify(true);

        // [GIVEN] Segment Line with "Contact No." = "C1"
        LibraryMarketing.CreateSegmentHeader(SegmentHeader);
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeader."No.");
        SegmentLine.Validate("Contact No.", Contact."No.");
        SegmentLine.Modify(true);

        // [WHEN] Calculate fields "Contact Phone No.", "Contact Mobile Phone No." and "Contact Email"
        SegmentLine.CalcFields(
            "Contact Phone No.", "Contact Mobile Phone No.", "Contact Email");

        // [THEN] "Segment Line"."Contact Phone No." = "999-999-99-99"
        SegmentLine.TestField("Contact Phone No.", Contact."Phone No.");

        // [THEN] "Segment Line"."Contact Mobile Phone No." = "888-888-88-88"
        SegmentLine.TestField("Contact Mobile Phone No.", Contact."Mobile Phone No.");

        // [THEN] "Segment Line"."Contact Email" = "user@contoso.com"
        SegmentLine.TestField("Contact Email", Contact."E-Mail");
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Marketing Segment");
        LibraryVariableStorage.Clear();

        Clear(ContactNo3);  // Clear Global Variable for Add Contact Handler.
        Clear(SalesPersonCode2);  // Clear Global Variable for Handlers.
    end;

    local procedure CreateInteractionTemplateWithLanguageAndAttachment(LanguageCode: Code[10]; AttachmentNo: Integer): Code[10]
    var
        InteractionTemplate: Record "Interaction Template";
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        LibraryMarketing.CreateInteractionTemplate(InteractionTemplate);

        InteractionTmplLanguage.Init();
        InteractionTmplLanguage.Validate("Interaction Template Code", InteractionTemplate.Code);
        InteractionTmplLanguage.Validate("Language Code", LanguageCode);
        InteractionTmplLanguage.Validate("Attachment No.", AttachmentNo);
        InteractionTmplLanguage.Insert(true);

        InteractionTemplate.Validate("Language Code (Default)", InteractionTmplLanguage."Language Code");
        InteractionTemplate.Modify(true);

        exit(InteractionTemplate.Code);
    end;

    local procedure CreateSegmentLineWithInteractionTemplate(SegmentHeaderNo: Code[20]; InteractionTemplateCode: Code[10]; ContactNo: Code[20]): Integer
    var
        SegmentLine: Record "Segment Line";
    begin
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeaderNo);
        SegmentLine.Validate("Contact No.", ContactNo);
        SegmentLine.Validate("Interaction Template Code", InteractionTemplateCode);
        SegmentLine.Modify(true);
        exit(SegmentLine."Line No.");
    end;

    local procedure CreateContact(): Code[20]
    var
        Contact: Record Contact;
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        exit(Contact."No.");
    end;

    local procedure CreateContactWithAddress(var Contact: Record Contact)
    begin
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.UpdateContactAddress(Contact);
    end;

    local procedure CreateSegmentLineByPage(var Segment: TestPage Segment; ContactNo: Code[20])
    begin
        Segment.SegLines."Contact No.".SetValue(ContactNo);
        Commit();  // Commit required to run the reports.
    end;

    local procedure CreateSegmentLines(Segment: TestPage Segment; ContactNo: Code[20]; ContactNo2: Code[20])
    begin
        CreateSegmentLineByPage(Segment, ContactNo);
        Segment.SegLines.Next();
        CreateSegmentLineByPage(Segment, ContactNo2);
    end;

    local procedure CreateSegmentWithContact(var Segment: TestPage Segment) SalesPersonCode: Code[20]
    var
        ContactNo: Code[20];
    begin
        ContactNo := CreateContact();
        SalesPersonCode := UpdateContactWithSalesPersonCode(ContactNo);
        Segment.OpenNew();  // Open New Segment.
        CreateSegmentLineByPage(Segment, ContactNo);
    end;

    local procedure CreateSegmentLineForContact(SegmentHeaderNo: Code[20]; ContactNo: Code[20])
    var
        SegmentLine: Record "Segment Line";
    begin
        LibraryMarketing.CreateSegmentLine(SegmentLine, SegmentHeaderNo);
        SegmentLine.Validate("Contact No.", ContactNo);
        SegmentLine.Modify();
    end;

    local procedure CreateSegmentWithContacts(var Segment: TestPage Segment) SalesPersonCode: Code[20]
    var
        ContactNo: Code[20];
        ContactNo2: Code[20];
    begin
        ContactNo := CreateContact();
        SalesPersonCode := UpdateContactWithSalesPersonCode(ContactNo);
        ContactNo2 := CreateContact();
        SalesPersonCode2 := UpdateContactWithSalesPersonCode(ContactNo2);  // Global Variable used for Request Page Handler.

        Segment.OpenNew();  // Open New Segment.
        CreateSegmentLines(Segment, ContactNo, ContactNo2);
    end;

    local procedure DeleteLastRecordSegmentLine(SegmentNo: Code[20])
    var
        SegmentLine: Record "Segment Line";
    begin
        SegmentLine.SetRange("Segment No.", SegmentNo);
        SegmentLine.FindLast();
        SegmentLine.Delete(true);
    end;

    local procedure FindSegmentLineSalesPersonCode(SegmentNo: Code[20]; SalesPersonCode: Code[20]): Boolean
    var
        SegmentLine: Record "Segment Line";
    begin
        SegmentLine.SetRange("Segment No.", SegmentNo);
        SegmentLine.SetRange("Salesperson Code", SalesPersonCode);
        exit(SegmentLine.FindFirst())
    end;

    local procedure GetAttachmentNoFromSegmentLine(SegmentHeaderNo: Code[20]; SegmentLineNo: Integer): Integer
    var
        SegmentLine: Record "Segment Line";
    begin
        SegmentLine.Get(SegmentHeaderNo, SegmentLineNo);
        exit(SegmentLine."Attachment No.");
    end;

    local procedure GetNoOfCriteriaActions(SegmentNo: Code[20]): Integer
    var
        SegmentHeader: Record "Segment Header";
    begin
        SegmentHeader.Get(SegmentNo);
        SegmentHeader.CalcFields("No. of Criteria Actions");
        exit(SegmentHeader."No. of Criteria Actions");
    end;

    local procedure UpdateContactWithSalesPersonCode(ContactNo: Code[20]): Code[20]
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        Contact: Record Contact;
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Contact.Get(ContactNo);
        Contact.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Contact.Modify(true);
        exit(SalespersonPurchaser.Code)
    end;

    local procedure VerifySegmentLineWithAttachment(SegmentHeaderNo: Code[20]; SegmentLineNo: Integer; InteractionTemplateCode: Code[10]; LanguageCode: Code[10]; AttachmentNo: Integer)
    var
        SegmentLine: Record "Segment Line";
    begin
        SegmentLine.Get(SegmentHeaderNo, SegmentLineNo);
        SegmentLine.TestField("Interaction Template Code", InteractionTemplateCode);
        SegmentLine.TestField("Language Code", LanguageCode);
        SegmentLine.TestField("Attachment No.", AttachmentNo);
    end;

    local procedure VerifySegmentLine(SegmentHeaderNo: Code[20]; ContactNo: Code[20])
    var
        SegmentLine: Record "Segment Line";
    begin
        SegmentLine.SetRange("Segment No.", SegmentHeaderNo);
        SegmentLine.FindFirst();
        SegmentLine.TestField("Contact No.", ContactNo);
    end;

    local procedure VerifyContactCoverSheetCompanyInfoReport()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        LibraryReportDataset.AssertElementWithValueExists('CompanyAddress1', CompanyInformation.Name);
        LibraryReportDataset.AssertElementWithValueExists('CompanyAddress2', CompanyInformation.Address);
        LibraryReportDataset.AssertElementWithValueExists('CompanyInformationPhoneNo', CompanyInformation."Phone No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInformationGiroNo', CompanyInformation."Giro No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInformationVATRegNo', CompanyInformation."VAT Registration No.");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInformationBankName', CompanyInformation."Bank Name");
        LibraryReportDataset.AssertElementWithValueExists('CompanyInformationBankAccountNo', CompanyInformation."Bank Account No.");
        LibraryReportDataset.AssertElementWithValueExists('Document_Date', Format(WorkDate(), 0, 4));
    end;

    local procedure VerifyContactCoverSheetContactInfoReport(Contact: Record Contact)
    var
        CountryRegion: Record "Country/Region";
    begin
        CountryRegion.Get(Contact."Country/Region Code");
        LibraryReportDataset.AssertElementWithValueExists('ContactAddress1', Contact.Name);
        LibraryReportDataset.AssertElementWithValueExists('ContactAddress2', Contact.Address);
        LibraryReportDataset.AssertElementWithValueExists('ContactAddress3', Contact."Address 2");
        LibraryReportDataset.AssertElementWithValueExists('ContactAddress4', Contact.City + ', ' + Contact."Post Code");
        LibraryReportDataset.AssertElementWithValueExists('ContactAddress5', Contact.County);
        LibraryReportDataset.AssertElementWithValueExists('ContactAddress6', CountryRegion.Name);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AddContactHandler(var AddContacts: TestRequestPage "Add Contacts")
    begin
        AddContacts.Contact.SetFilter("No.", ContactNo3);
        AddContacts.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ContactCoverSheetReportRequestPageHandler(var CoverSheet: TestRequestPage "Contact Cover Sheet")
    begin
        CoverSheet.LogInteraction.SetValue(LibraryVariableStorage.DequeueBoolean());
        CoverSheet.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReduceContactHandler(var RemoveContactsReduce: TestRequestPage "Remove Contacts - Reduce")
    begin
        RemoveContactsReduce.Contact.SetFilter("Salesperson Code", SalesPersonCode2);
        RemoveContactsReduce.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RefineContactHandler(var RemoveContactsRefine: TestRequestPage "Remove Contacts - Refine")
    begin
        RemoveContactsRefine.Contact.SetFilter("Salesperson Code", SalesPersonCode2);
        RemoveContactsRefine.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ReuseCriteriaSegmentHandler(var SavedSegmentCriteriaList: TestPage "Saved Segment Criteria List")
    begin
        SavedSegmentCriteriaList.FILTER.SetFilter(Code, SalesPersonCode2);  // SalesPersonCode is saved as code.
        SavedSegmentCriteriaList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SaveSegmentCriteriaHandler(var SaveSegmentCriteria: TestPage "Save Segment Criteria")
    begin
        SaveSegmentCriteria.Code.SetValue(SalesPersonCode2);
        SaveSegmentCriteria.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}

