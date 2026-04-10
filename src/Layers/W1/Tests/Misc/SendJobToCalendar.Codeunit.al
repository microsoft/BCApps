codeunit 136315 "Send Job To Calendar"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Jobs] [Planning Lines] [Send to Calendar]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDocumentApprovals: Codeunit "Library - Document Approvals";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        CouldNotFindValueErr: Label 'Could not find value in description. Expected %1.', Comment = '%1 = Expected value';
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure GenerateAppointmentThrowsErrorWhenAppointmentNotSet()
    var
        TempEmailItem: Record "Email Item" temporary;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
    begin
        // [SCENARIO 167920] Attempting to generate the appointment before setting the job planning line results in an error.
        Initialize();

        // [WHEN] GenerateAppointment is called without setting the job planning line
        // [THEN] Error is thrown
        asserterror JobPlanningLineCalendar.CreateRequest(TempEmailItem);
        asserterror JobPlanningLineCalendar.CreateCancellation(TempEmailItem);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRequestReturnsTrue()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        TempEmailItem: Record "Email Item" temporary;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        CanSend: Boolean;
    begin
        // [SCENARIO 167920] Creating the appointment request returns true if the email is ready to send.
        Initialize();

        // [GIVEN] Job planning line exists.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] The job planning line is set in the codeunit and the call to create the request is made.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        CanSend := JobPlanningLineCalendar.CreateRequest(TempEmailItem);

        // [THEN] Return value is true, implying that the request is ready to send.
        Assert.IsTrue(CanSend, 'The call to create the request should return true.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRequestReturnsFalseIfResourceHasNoAuthEmail()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        TempEmailItem: Record "Email Item" temporary;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        CanSend: Boolean;
    begin
        // [SCENARIO 167920] Creating the appointment request returns false if the resource has no authentication email.
        Initialize();

        // [GIVEN] A resource exists and is associated to a user with no authentication email set.
        CreateResource(Resource, '');

        // [GIVEN] A job planning line exists for the resource.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] The call to create the appointment request is made.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        CanSend := JobPlanningLineCalendar.CreateRequest(TempEmailItem);

        // [THEN] Return value is false, implying that the request cannot be sent.
        Assert.IsFalse(CanSend, 'The call to create the request should return false.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCancellationReturnsTrue()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        TempEmailItem: Record "Email Item" temporary;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        CanSend: Boolean;
    begin
        // [SCENARIO 167921] Creating the appointment cancellation returns true if the cancellation is ready to send.
        Initialize();

        // [GIVEN] A job planning line exists for a resource.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [GIVEN] An appointment request has already been sent out to the resource.
        CreateJobPlanningLineCalendar(JobPlanningLine);

        // [WHEN] The call to create the appointment cancellation is made.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        CanSend := JobPlanningLineCalendar.CreateCancellation(TempEmailItem);

        // [THEN] Return value is true, implying that the cancellation can be sent.
        Assert.IsTrue(CanSend, 'The call to create the cancellation should return true.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCancellationReturnsFalseIfResourceHasNoAuthEmail()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        TempEmailItem: Record "Email Item" temporary;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        CanSend: Boolean;
    begin
        // [SCENARIO 167921] Creating the appointment cancellation returns false if the resource has no auth email.
        Initialize();

        // [GIVEN] A resource exists with no authentication email set.
        CreateResource(Resource, '');

        // [GIVEN] A job planning line exists for the resource and a request has been sent.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);
        CreateJobPlanningLineCalendar(JobPlanningLine);

        // [WHEN] The call to create the appointment cancellation is made.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        CanSend := JobPlanningLineCalendar.CreateCancellation(TempEmailItem);

        // [THEN] Return value is false, implying that the cancellation cannot be sent.
        Assert.IsFalse(CanSend, 'The call to create the cancellation should return false.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateCancellationReturnsFalseIfNoRequestEverSent()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        TempEmailItem: Record "Email Item" temporary;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        CanSend: Boolean;
    begin
        // [SCENARIO 167921] Creating the appointment cancellation returns false if no request was ever sent in the first place.
        Initialize();

        // [GIVEN] A job planning line exists for a resource.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] The call to create the appointment cancellation is made.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        CanSend := JobPlanningLineCalendar.CreateCancellation(TempEmailItem);

        // [THEN] Return value is false, indicating that the cancellation should not be sent.
        Assert.IsFalse(CanSend, 'The call to create the cancellation should return false.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRequestWorksIfNoPrimaryContactForCustomer()
    var
        Customer: Record Customer;
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        TempEmailItem: Record "Email Item" temporary;
        DummyContact: Record Contact;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        Description: Text;
        ExpectedText: Text;
    begin
        // [SCENARIO 167920] Send to calendar generates email with the subject set to the job task description.

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);
        Job.Get(JobPlanningLine."Job No.");
        Customer.Init();
        Customer.Name := 'John';
        Customer."E-Mail" := 'john@contoso.com';
        Customer."Phone No." := 'hello';
        Customer.Insert(true);

        Job."Bill-to Customer No." := Customer."No.";
        Job.Modify(true);

        // [WHEN] Appointment is created for the planning line
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);
        Description := GetDescription(TempEmailItem);

        // [THEN] Description contains the details of the job.
        Job.Get(JobPlanningLine."Job No.");
        ExpectedText := StrSubstNo('%1: \n%2: hello', DummyContact.TableCaption(), DummyContact.FieldCaption("Phone No."));
        if StrPos(Description, ExpectedText) < 1 then
            Error(CouldNotFindValueErr, ExpectedText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySubjectIsJobTaskDescription()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        Resource: Record Resource;
        TempEmailItem: Record "Email Item" temporary;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
    begin
        // [SCENARIO 167920] Send to calendar generates email with the subject set to the job task description.

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] Appointment is created for the planning line
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);

        // [THEN] Appointment subject is the same as the job task description
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        Assert.AreEqual(JobTask.Description, TempEmailItem.Subject, 'Unexpected subject on the email item.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySendToIsJobResource()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        TempEmailItem: Record "Email Item" temporary;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        AuthEmail: Text[250];
    begin
        // [SCENARIO 167920] Send to calendar generates email sent to the authentication email of the resource.

        // [GIVEN] We have a job planning line assigned to a specific resource.
        AuthEmail := RandomEmail();
        CreateResource(Resource, AuthEmail);
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] Appointment is created for the planning line
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);

        // [THEN] Send to address is the same as the resource's authentication email
        Assert.AreEqual(AuthEmail, TempEmailItem."Send to", 'Unexpected send-to address.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyAttachmentNameIsJobTaskCaption()
    var
        JobPlanningLine: Record "Job Planning Line";
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        DummyJobTask: Record "Job Task";
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        Attachments: Codeunit "Temp Blob List";
        AttachmentNames: List of [Text];
    begin
        // [SCENARIO 167920] Send to calendar generates email with attachment name set to the correct value.

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] Appointment is created for the planning line
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);

        TempEmailItem.GetAttachments(Attachments, AttachmentNames);

        // [THEN] Name of attachment is set to "Job Task.ics"
        Assert.AreEqual(StrSubstNo('%1.ics', DummyJobTask.TableCaption()), AttachmentNames.Get(1), 'Unexpected file attachment name.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyStartAndEndDateWhenOneDayTask()
    var
        JobPlanningLine: Record "Job Planning Line";
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        Quantity: Decimal;
        ICSText: Text;
        ExpectedStart: Text;
        ExpectedEnd: Text;
    begin
        // [SCENARIO 167920] Send to calendar generates email with the correct start and end days for a task that lasts less than a day.
        Initialize();

        // [GIVEN] We have a job planning line with a random quantity.
        Quantity := LibraryRandom.RandIntInRange(2, 11);
        CreateJobPlanningLine(JobPlanningLine, Resource, Quantity);

        // [WHEN] Appointment is created for the planning line.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);
        ICSText := GetICSText(TempEmailItem);

        // [THEN] Start date is set to 8:00 on the planning date of the line
        ExpectedStart := Format(JobPlanningLine."Planning Date", 0, '<Year4><Month,2><Day,2>T080000');
        VerifyICSElement(ICSText, 'DTSTART', ExpectedStart);

        // [THEN] End date is set to 8:00 + Quantity on the planning date of the line
        ExpectedEnd := Format(JobPlanningLine."Planning Date", 0, '<Year4><Month,2><Day,2>T' + Format(8 + Quantity) + '0000');
        VerifyICSElement(ICSText, 'DTEND', ExpectedEnd);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyStartAndEndDateWhenMultipleDays()
    var
        JobPlanningLine: Record "Job Planning Line";
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        Quantity: Decimal;
        ICSText: Text;
        ExpectedStart: Text;
        ExpectedEnd: Text;
    begin
        // [SCENARIO 167920] Send to calendar generates email with the correct start and end days for a task that spans multiple days.
        Initialize();

        // [GIVEN] We have a job planning line with a random quantity of at least 13.
        Quantity := LibraryRandom.RandIntInRange(13, 240);
        CreateJobPlanningLine(JobPlanningLine, Resource, Quantity);

        // [WHEN] Appointment is created for the planning line.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);
        ICSText := GetICSText(TempEmailItem);

        // [THEN] Start date is set to 00:00 on the planning date of the line
        ExpectedStart := Format(JobPlanningLine."Planning Date", 0, '<Year4><Month,2><Day,2>T000000');
        VerifyICSElement(ICSText, 'DTSTART', ExpectedStart);

        // [THEN] End date is set to 00:00, x days after the planning date of the line, where x = ROUND(Quantity / 24,1,'>')
        ExpectedEnd := Format(JobPlanningLine."Planning Date" + Round(Quantity / 24, 1, '>'), 0, '<Year4><Month,2><Day,2>T000000');
        VerifyICSElement(ICSText, 'DTEND', ExpectedEnd);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyLocationSetToCustomerAddress()
    var
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        Customer: Record Customer;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        ICSText: Text;
        ExpectedLocation: Text;
    begin
        // [SCENARIO 167920] Send to calendar generates email with ICS file that contains customer's address.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] Appointment is created for the planning line.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);
        ICSText := GetICSText(TempEmailItem);

        // [THEN] Location in ICS file is set to the bill-to customer's address.
        Job.Get(JobPlanningLine."Job No.");
        Customer.Get(Job."Bill-to Customer No.");
        ExpectedLocation := StrSubstNo('%1, %2, %3', Customer.Address, Customer.City, Customer."Country/Region Code");
        VerifyICSElement(ICSText, 'LOCATION', ExpectedLocation);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySummarySetToJobNoAndJobTaskNo()
    var
        JobPlanningLine: Record "Job Planning Line";
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        ICSText: Text;
        ExpectedSummary: Text;
    begin
        // [SCENARIO 167920] Send to calendar generates ICS file with subject containing the job number and job task number.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] Appointment is created for the planning line.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);
        ICSText := GetICSText(TempEmailItem);

        // [THEN] Summary of appointment is formatted as M:N where M = Job No., N = Job Task No.
        ExpectedSummary := StrSubstNo('%1:%2:%3', JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
        VerifyICSElement(ICSText, 'SUMMARY', ExpectedSummary);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyICSDescriptionContainsJobDescription()
    var
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        Description: Text;
        ExpectedText: Text;
    begin
        // [SCENARIO 167920] Send to calendar generates ICS file with description containing the job details.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] Appointment is created for the planning line.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);
        Description := GetDescription(TempEmailItem);

        // [THEN] Description contains the details of the job.
        Job.Get(JobPlanningLine."Job No.");
        ExpectedText := StrSubstNo('%1: %2 - %3', Job.TableCaption(), Job."No.", Job.Description);
        if StrPos(Description, ExpectedText) < 1 then
            Error(CouldNotFindValueErr, ExpectedText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyICSDescriptionContainsJobTaskDescription()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobTask: Record "Job Task";
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        Description: Text;
        ExpectedText: Text;
    begin
        // [SCENARIO 167920] Send to calendar generates ICS file with description containing the job task details.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] Appointment is created for the planning line.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);
        Description := GetDescription(TempEmailItem);

        // [THEN] Description contains the details of the job task.
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        ExpectedText := StrSubstNo('%1: %2 - %3', JobTask.TableCaption(), JobTask."Job Task No.", JobTask.Description);
        if StrPos(Description, ExpectedText) < 1 then
            Error(CouldNotFindValueErr, ExpectedText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyICSDescriptionContainsCustomerName()
    var
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        Customer: Record Customer;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        Description: Text;
        ExpectedText: Text;
    begin
        // [SCENARIO 177132] Send to calendar generates email with ICS file that contains customer's name.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] Appointment is created for the planning line.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);
        Description := GetDescription(TempEmailItem);

        // [THEN] Description contains the customer name
        Job.Get(JobPlanningLine."Job No.");
        Customer.Get(Job."Bill-to Customer No.");
        ExpectedText := StrSubstNo('%1: %2', Customer.TableCaption(), Customer.Name);
        if StrPos(Description, ExpectedText) < 1 then
            Error(CouldNotFindValueErr, ExpectedText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyICSMethodWhenNew()
    var
        JobPlanningLine: Record "Job Planning Line";
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        ICSText: Text;
        Method: Text;
    begin
        // [SCENARIO 167921] Send to calendar generates ICS file with correct method for an appointment request.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] Appointment is created for the planning line.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);
        ICSText := GetICSText(TempEmailItem);
        Method := ExtractICSElement(ICSText, 'METHOD');

        // [THEN] Method of the ICS is set to 'REQUEST'.
        Assert.AreEqual('REQUEST', Method, 'Incorrect ICS method.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyICSStatusWhenNew()
    var
        JobPlanningLine: Record "Job Planning Line";
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        ICSText: Text;
        Status: Text;
    begin
        // [SCENARIO 167921] Send to calendar generates ICS file with correct status for an appointment request.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] Appointment is created for the planning line.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);
        ICSText := GetICSText(TempEmailItem);
        Status := ExtractICSElement(ICSText, 'STATUS');

        // [THEN] Status of the ICS is set to 'CONFIRMED'.
        Assert.AreEqual('CONFIRMED', Status, 'Incorrect ICS status.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyICSMethodWhenCancelled()
    var
        JobPlanningLine: Record "Job Planning Line";
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        ICSText: Text;
        Method: Text;
    begin
        // [SCENARIO 167921] Send to calendar generates ICS file with correct method for an appointment cancellation.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [GIVEN] An appointment request has already been sent out to the resource.
        CreateJobPlanningLineCalendar(JobPlanningLine);

        // [WHEN] Appointment is created for the planning line.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateCancellation(TempEmailItem);
        ICSText := GetICSText(TempEmailItem);
        Method := ExtractICSElement(ICSText, 'METHOD');

        // [THEN] Method of the ICS is set to 'CANCEL'.
        Assert.AreEqual('CANCEL', Method, 'Incorrect ICS method.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyICSStatusWhenCancelled()
    var
        JobPlanningLine: Record "Job Planning Line";
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
        ICSText: Text;
        Status: Text;
    begin
        // [SCENARIO 167921] Send to calendar generates ICS file with correct status for an appointment cancellation.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [GIVEN] An appointment request has already been sent out to the resource.
        CreateJobPlanningLineCalendar(JobPlanningLine);

        // [WHEN] Appointment is created for the planning line.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateCancellation(TempEmailItem);
        ICSText := GetICSText(TempEmailItem);
        Status := ExtractICSElement(ICSText, 'STATUS');

        // [THEN] Status of the ICS is set to 'CANCELLED'.
        Assert.AreEqual('CANCELLED', Status, 'Incorrect ICS method.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyICSAllowUnicodeCharacters()
    var
        JobPlanningLine: Record "Job Planning Line";
        TempEmailItem: Record "Email Item" temporary;
        Resource: Record Resource;
        JobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
    begin
        // [SCENARIO 230609] Send to calendar generates ICS file with Unicode characters.
        Initialize();

        // [GIVEN] Job Planning Line "JPL" with Unicode characters in Description.
        CreateJobPlanningLineWithUnicodeDescription(JobPlanningLine, Resource, LibraryRandom.RandIntInRange(5, 10));

        // [WHEN] Appointment is created for the planning line.
        JobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        JobPlanningLineCalendar.CreateRequest(TempEmailItem);

        // [THEN] Description from the ICS file is same with "JPL".Description
        VerifyICSJobPlanningLineDescription(JobPlanningLine, TempEmailItem);
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure JobPlanningLineSendToCalendar()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [SCENARIO 167920] Send to calendar generates an email with an ICS file and sends it to the resource.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);
        CreateUserSetupWithEmail();

        // [WHEN] Job Planning Lines page runs
        JobPlanningLines.Trap();
        Page.Run(Page::"Job Planning Lines", JobPlanningLine);

        // [WHEN] User clicks "Send to Calendar"
        JobPlanningLines.SendToCalendar.Invoke();

        // [THEN] Email is sent to the resource.
        // Handler confirms that the SMTP prompt is shown
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobPlanningLineSendToCalendarSkipsIfEmailEmpty()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        User: Record User;
        JobPlanningLines: TestPage "Job Planning Lines";
    begin
        // [SCENARIO 167920] Send to calendar skips planning lines if the resource doesn't have an email address.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);
        User.SetRange("User Name", Resource."Time Sheet Owner User ID");
        User.FindFirst();
        User."Authentication Email" := '';
        User.Modify();

        // [WHEN] Job Planning Lines page runs
        JobPlanningLines.Trap();
        PAGE.Run(PAGE::"Job Planning Lines", JobPlanningLine);

        // [WHEN] User clicks "Send to Calendar"
        JobPlanningLines.SendToCalendar.Invoke();

        // [THEN] Nothing happens for this line since there is no email.
        // No confirm dialog should be handled since the SMTP function isn't called.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertOrUpdateJobPlanningLineCalendar()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        JobPlanningLineCalendar: Record "Job Planning Line - Calendar";
    begin
        // [SCENARIO 167921] Developer can easily create JobPlanningLineCalendar record with wrapper function.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [WHEN] We call InsertOrUpdate on the JobPlanningLineCalendar record.
        JobPlanningLineCalendar.InsertOrUpdate(JobPlanningLine);

        // [THEN] The JobPlanningLineCalendar record contains the values from the planning line.
        Assert.AreEqual(JobPlanningLine."Job No.", JobPlanningLineCalendar."Job No.", 'Unexpected value for Job No.');
        Assert.AreEqual(JobPlanningLine."Job Task No.", JobPlanningLineCalendar."Job Task No.", 'Unexpected value for Job Task No.');
        Assert.AreEqual(JobPlanningLine."Line No.", JobPlanningLineCalendar."Planning Line No.", 'Unexpected value for Planning Line No.');
        Assert.AreEqual(Resource."No.", JobPlanningLineCalendar."Resource No.", 'Unexpected value for Resource No.');
        Assert.AreEqual(1, JobPlanningLineCalendar.Sequence, 'Unexpected value for Sequence.');
        Assert.IsFalse(IsNullGuid(JobPlanningLineCalendar.UID), 'UID should not be empty.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyJobPlanningLineCalendarIncrementsSequence()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineCalendar: Record "Job Planning Line - Calendar";
        Resource: Record Resource;
    begin
        // [SCENARIO 167921] Modifying a JobPlanningLineCalendar record increments the Sequence.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);

        // [GIVEN] A JobPlanningLineCalendar record already exists.
        JobPlanningLineCalendar.InsertOrUpdate(JobPlanningLine);

        // [WHEN] JobPlanningLine record is modified.
        JobPlanningLineCalendar.Modify(true);

        // [THEN] Sequence is incremented.
        Assert.AreEqual(2, JobPlanningLineCalendar.Sequence, 'Sequence was not incremented.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure DeleteJobPlanningLineSendsCancellation()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        JobPlanningLineCalendar: Record "Job Planning Line - Calendar";
    begin
        // [SCENARIO 167921] When a job planning line is deleted, a cancellation gets sent to the resource.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);
        CreateUserSetupWithEmail();

        // [GIVEN] An appointment request was sent to the resource.
        CreateJobPlanningLineCalendar(JobPlanningLine);

        // [WHEN] The job planning line is deleted.
        JobPlanningLine.Delete(true);

        // [THEN] A cancellation is sent and the JobPlanningLineCalendar record is deleted.
        // ConfirmHandler verifies that the SMTP dialog was called.
        Assert.IsFalse(JobPlanningLineCalendar.HasBeenSent(JobPlanningLine), 'JobPlanningLineCalendar record was not deleted.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure ModifyJobPlanningLineResourceNoSendsCancellation()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        AltResource: Record Resource;
        JobPlanningLineCalendar: Record "Job Planning Line - Calendar";
        CUJobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
    begin
        // [SCENARIO 167921] When the resource of a job planning line is changed, send a cancellation to the original resource.
        Initialize();

        // [GIVEN] We have a job planning line for a resource and an appointment request has been sent.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);
        CreateUserSetupWithEmail();
        CreateJobPlanningLineCalendar(JobPlanningLine);

        // [GIVEN] Another resource exists in the system.
        CreateResource(AltResource, RandomEmail());

        // [WHEN] The resource changes on the Job planning line.
        JobPlanningLine.Validate("No.", AltResource."No.");

        // [WHEN] The send to calendar action is invoked.
        CUJobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        CUJobPlanningLineCalendar.CreateAndSend();

        // [THEN] A cancellation is sent to the original resource.
        // ConfirmHandler verifies that the SMTP dialog was opened
        Assert.IsTrue(JobPlanningLineCalendar.HasBeenSent(JobPlanningLine), 'JobPlanningLineCalendar record was not deleted.');
        Assert.AreEqual(AltResource."No.", JobPlanningLineCalendar."Resource No.", 'Appointment to new resource was not sent.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure ModifyJobPlanningLineQuantitySendsUpdate()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        JobPlanningLineCalendar: Record "Job Planning Line - Calendar";
        CUJobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
    begin
        // [SCENARIO 167921] When the quantity is changed on a job planning line, an update is sent to the resource's calendar.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);
        CreateUserSetupWithEmail();

        // [GIVEN] A request has already been sent to the resource.
        JobPlanningLineCalendar.InsertOrUpdate(JobPlanningLine);

        // [WHEN] The quantity of the planning line is changed.
        JobPlanningLine.Validate(Quantity, 5);

        // [WHEN] The send to calendar action is invoked.
        CUJobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        CUJobPlanningLineCalendar.CreateAndSend();

        // [THEN] An updated appointment request is sent to the resource.
        JobPlanningLineCalendar.HasBeenSent(JobPlanningLine);
        Assert.AreEqual(2, JobPlanningLineCalendar.Sequence, 'Update did not get sent.');
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure ModifyJobPlanningLinePlanningDateSendsUpdate()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        JobPlanningLineCalendar: Record "Job Planning Line - Calendar";
        CUJobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
    begin
        // [SCENARIO 167921] When the planning date is changed on a job planning line, an update is sent to the resource's calendar.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 10);
        CreateUserSetupWithEmail();

        // [GIVEN] A request has already been sent to the resource.
        JobPlanningLineCalendar.InsertOrUpdate(JobPlanningLine);

        // [WHEN] The planning date of the line is changed.
        JobPlanningLine.Validate("Planning Date", JobPlanningLine."Planning Date" + 5);
        JobPlanningLine.Modify(true);

        // [WHEN] The send to calendar action is invoked.
        CUJobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        CUJobPlanningLineCalendar.CreateAndSend();

        // [THEN] An updated appointment request is sent to the resource.
        JobPlanningLineCalendar.HasBeenSent(JobPlanningLine);
        Assert.AreEqual(2, JobPlanningLineCalendar.Sequence, 'Update did not get sent.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoUpdateSentWhenNoChangesMade()
    var
        JobPlanningLine: Record "Job Planning Line";
        Resource: Record Resource;
        JobPlanningLineCalendar: Record "Job Planning Line - Calendar";
        CUJobPlanningLineCalendar: Codeunit "Job Planning Line - Calendar";
    begin
        // [SCENARIO 167921] When the send to calendar action is invoked, but the planning line hasn't changed, do not send an update.
        Initialize();

        // [GIVEN] We have a job planning line.
        CreateJobPlanningLine(JobPlanningLine, Resource, 5);

        // [GIVEN] A Request has already been sent to the resource.
        JobPlanningLineCalendar.InsertOrUpdate(JobPlanningLine);

        // [WHEN] The send to calendar action is invoked.
        CUJobPlanningLineCalendar.SetPlanningLine(JobPlanningLine);
        CUJobPlanningLineCalendar.CreateAndSend();

        // [THEN] Nothing happens since there is not an update.
        // Lack of handler codeunit verifies that nothing has happened.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure Initialize()
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineCalendar: Record "Job Planning Line - Calendar";
        Seed: Variant;
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Send Job To Calendar");
        BindActiveDirectoryMockEvents();
        Seed := Format(Time, 0, '<Seconds>');
        LibraryRandom.SetSeed(Seed);
        JobPlanningLine.DeleteAll(false);
        JobPlanningLineCalendar.DeleteAll(false);

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Send Job To Calendar");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Send Job To Calendar");
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; var Resource: Record Resource; Quantity: Decimal)
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Customer: Record Customer;
        Contact: Record Contact;
        LibraryJob: Codeunit "Library - Job";
        LibraryMarketing: Codeunit "Library - Marketing";
    begin
        if Resource."No." = '' then
            CreateResource(Resource, RandomEmail());

        LibraryJob.CreateJob(Job);
        Job.Validate(Description, CreateGuid());
        Job.Modify();

        LibraryJob.CreateJobTask(Job, JobTask);
        JobTask.Validate(Description, CreateGuid());
        JobTask.Modify();

        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Resource, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("Unit Price", JobPlanningLine."Unit Cost" * (1 + LibraryRandom.RandInt(100) / 100));
        JobPlanningLine.Quantity := Quantity;
        JobPlanningLine."No." := Resource."No.";
        JobPlanningLine.Modify();

        LibraryMarketing.CreateCompanyContact(Contact);
        Customer.Get(Job."Bill-to Customer No.");
        Customer."Primary Contact No." := Contact."No.";
        Customer.Address := CopyStr(CreateGuid(), 2, 13);
        Customer.City := CopyStr(CreateGuid(), 2, 5);
        Customer."Country/Region Code" := CopyStr(CreateGuid(), 2, 2);
        Customer.Modify();
    end;

    local procedure CreateJobPlanningLineWithUnicodeDescription(var JobPlanningLine: Record "Job Planning Line"; var Resource: Record Resource; Quantity: Decimal)
    begin
        CreateJobPlanningLine(JobPlanningLine, Resource, Quantity);
        JobPlanningLine.Validate(Description, LibraryUtility.GenerateRandomUnicodeText(LibraryRandom.RandIntInRange(10, 30)));
        JobPlanningLine.Modify(true);
    end;

    local procedure CreateJobPlanningLineCalendar(JobPlanningLine: Record "Job Planning Line")
    var
        JobPlanningLineCalendar: Record "Job Planning Line - Calendar";
    begin
        JobPlanningLineCalendar.InsertOrUpdate(JobPlanningLine);
    end;

    local procedure CreateResource(var Resource: Record Resource; AuthEmail: Text[250])
    var
        User: Record User;
        LibraryResource: Codeunit "Library - Resource";
    begin
        LibraryResource.CreateResource(Resource, '');
        User.Init();
        User.Validate("User Name", LibraryUtility.GenerateRandomCode(User.FieldNo("User Name"), DATABASE::User));
        User.Validate("User Security ID", CreateGuid());
        User.Validate("Authentication Email", AuthEmail);
        User.Insert(true);

        Resource."Time Sheet Owner User ID" := User."User Name";
        Resource.Modify();
    end;

    local procedure GetICSText(var TempEmailItem: Record "Email Item" temporary) ICSText: Text
    var
        Attachments: Codeunit "Temp Blob List";
        TempBlob: Codeunit "Temp Blob";
        Stream: InStream;
        AttachmentNames: List of [Text];
    begin
        TempEmailItem.GetAttachments(Attachments, AttachmentNames);
        Attachments.Get(1, TempBlob);
        TempBlob.CreateInStream(Stream, TextEncoding::UTF8);
        Stream.Read(ICSText);
    end;

    local procedure GetDescription(var TempEmailItem: Record "Email Item" temporary) Description: Text
    var
        ICSText: Text;
    begin
        ICSText := GetICSText(TempEmailItem);
        Description := ExtractICSElement(ICSText, 'DESCRIPTION');
    end;

    local procedure VerifyICSElement(ICSText: Text; Element: Text; ExpectedValue: Text)
    var
        Value: Text;
    begin
        Value := ExtractICSElement(ICSText, Element);
        Assert.AreEqual(ExpectedValue, Value, StrSubstNo('Unexpected value for %1', Element));
    end;

    local procedure ExtractICSElement(ICSText: Text; Element: Text) Value: Text
    var
        Regex: DotNet Regex;
        Match: DotNet Match;
    begin
        Regex := Regex.Regex(StrSubstNo('%1:(.*)\r\n', Element));
        Match := Regex.Match(ICSText);
        Assert.IsTrue(Match.Success, StrSubstNo('Element %1 could not be found in ICS', Element));
        Value := Match.Groups.Item(1).Value();
    end;

    local procedure VerifyICSJobPlanningLineDescription(JobPlanningLine: Record "Job Planning Line"; var TempEmailItem: Record "Email Item" temporary)
    var
        Description: Text;
    begin
        Description := GetDescription(TempEmailItem);
        Assert.IsTrue(
          StrPos(Description, JobPlanningLine.Description) > 0,
          StrSubstNo(CouldNotFindValueErr, JobPlanningLine.Description));
    end;

    local procedure RandomEmail(): Text[250]
    begin
        exit(StrSubstNo('%1@contoso.com', CreateGuid()));
    end;

    local procedure CreateUserSetupWithEmail()
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.SetRange("User ID", UserId);
        if not UserSetup.FindFirst() then
            LibraryDocumentApprovals.CreateUserSetup(UserSetup, UserId(), '');
        if UserSetup."E-Mail" = '' then begin
            UserSetup."E-Mail" := CopyStr(RandomEmail(), 1, MaxStrLen(UserSetup."E-Mail"));
            UserSetup.Modify();
        end;
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;
}

