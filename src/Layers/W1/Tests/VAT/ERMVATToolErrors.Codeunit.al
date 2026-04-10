codeunit 134054 "ERM VAT Tool - Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT Rate Change] [Error Handling]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        ERMVATToolHelper: Codeunit "ERM VAT Tool - Helper";
        isInitialized: Boolean;
        VATSetupError: Label 'There must be an entry in the %1 table for the combination of';
        VATToolCompletedError: Label 'VAT Rate Change Tool Completed field was not set to TRUE by the tool.';

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        ERMVATToolHelper.ResetToolSetup();  // This resets the setup table for all test cases.

        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        ERMVATToolHelper.SetupItemNos();
        ERMVATToolHelper.ResetToolSetup();  // This resets setup table for the first test case after database is restored.

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolSetup()
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        // Run the tool with no records in VAT Change Tool Setup table. Expected: tool shows an error message.
        Initialize();

        // SETUP: Delete records in VAT Change Tool Setup.
        VATRateChangeSetup.Reset();
        VATRateChangeSetup.DeleteAll(true);

        // Excercise: Run VAT Rate Change Tool.
        asserterror CODEUNIT.Run(CODEUNIT::"VAT Rate Change Conversion");

        // Verify: Error message about missing setup.
        Assert.IsTrue(StrPos(GetLastErrorText, 'Define the conversion.') > 0, GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolVATPostingSetup1()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATRateChangeConv: Record "VAT Rate Change Conversion";
    begin
        // Run the tool with VAT Posting Setup missing for new group. Expected: tool will return an error.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Remove VAT Posting Setup for new group.
        VATRateChangeConv.SetRange(Type, VATRateChangeConv.Type::"VAT Prod. Posting Group");
        VATRateChangeConv.FindFirst();
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", VATRateChangeConv."To Code");
        VATPostingSetup.DeleteAll(true);

        // SETUP: Create Dummy Setup for VAT Rate Change Setup table.
        CreateDummySetup();

        // Excercise: Run VAT Rate Change Tool.
        asserterror ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Error message about missing VAT Posting Setup.
        Assert.IsTrue(StrPos(GetLastErrorText, StrSubstNo(VATSetupError, VATPostingSetup.TableCaption())) > 0, GetLastErrorText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolVATPostingSetup2()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATRateChangeConv: Record "VAT Rate Change Conversion";
    begin
        // Run the tool with VAT Posting Setup missing for old and new group. Expected: no errors.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Remove VAT Posting Setup for old and new group.
        VATRateChangeConv.SetRange(Type, VATRateChangeConv.Type::"VAT Prod. Posting Group");
        VATRateChangeConv.FindFirst();
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", VATRateChangeConv."From Code");
        VATPostingSetup.DeleteAll(true);
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", VATRateChangeConv."To Code");
        VATPostingSetup.DeleteAll(true);

        // SETUP: Create Dummy Setup for VAT Rate Change Setup table.
        CreateDummySetup();

        // Excercise: Run VAT Rate Change Tool.
        // Verify: Tool Executes Successfully, No Messages Raised.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolVATIdentifier1()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATRateChangeConv: Record "VAT Rate Change Conversion";
        ErrorText: Text[1000];
    begin
        // Run the tool with VAT Posting Setup missing VAT Identifier for new group. Expected: tool will return an error.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Remove VAT Identifier in VAT Posting Setup for new group.
        VATRateChangeConv.SetRange(Type, VATRateChangeConv.Type::"VAT Prod. Posting Group");
        VATRateChangeConv.FindFirst();
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", VATRateChangeConv."To Code");
        VATPostingSetup.FindSet();
        repeat
            VATPostingSetup."VAT Identifier" := '';
            VATPostingSetup.Modify(true);
        until VATPostingSetup.Next() = 0;
        Commit(); // This is Required for the ASSERTERROR to Work

        asserterror VATPostingSetup.TestField("VAT Identifier");
        ErrorText := GetLastErrorText;

        // SETUP: Create Dummy Setup for VAT Rate Change Setup table.
        CreateDummySetup();

        // Excercise: Run VAT Rate Change Tool.
        asserterror ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: Error message about missing VAT Identifier in VAT Posting Setup.
        Assert.IsTrue(StrPos(GetLastErrorText, ErrorText) > 0, GetLastErrorText);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolVATIdentifier2()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATRateChangeConv: Record "VAT Rate Change Conversion";
    begin
        // Run the tool with VAT Posting Setup missing VAT Identifier for old and new group. Expected: no errors.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Remove VAT Identifier in VAT Posting Setup for old and new group.
        VATRateChangeConv.SetRange(Type, VATRateChangeConv.Type::"VAT Prod. Posting Group");
        VATRateChangeConv.FindFirst();
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", VATRateChangeConv."To Code");
        VATPostingSetup.FindSet();
        repeat
            VATPostingSetup."VAT Identifier" := '';
            VATPostingSetup.Modify(true);
        until VATPostingSetup.Next() = 0;
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", VATRateChangeConv."From Code");
        VATPostingSetup.FindSet();
        repeat
            VATPostingSetup."VAT Identifier" := '';
            VATPostingSetup.Modify(true);
        until VATPostingSetup.Next() = 0;

        // SETUP: Create Dummy Setup for VAT Rate Change Setup table.
        CreateDummySetup();

        // Excercise: Run VAT Rate Change Tool.
        // Verify: Tool should execute successfully.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolGenPostingSetup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATRateChangeConv: Record "VAT Rate Change Conversion";
    begin
        // Run the tool with Gen. Posting Setup missing for new group. Expected: no errors.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Remove Gen. Posting Setup for New Group.
        VATRateChangeConv.SetRange(Type, VATRateChangeConv.Type::"Gen. Prod. Posting Group");
        VATRateChangeConv.FindFirst();
        GeneralPostingSetup.SetFilter("Gen. Prod. Posting Group", VATRateChangeConv."To Code");
        GeneralPostingSetup.DeleteAll(true);

        // SETUP: Create Dummy Setup for VAT Rate Change Setup table.
        CreateDummySetup();

        // Excercise: Run VAT Rate Change Tool.
        // Verify: Tool Should Execute successfully.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolCompleted()
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        // Run the tool and check if VAT Rate Change Tool Completed field is set to TRUE.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // SETUP: Set VAT Rate Change Tool Completed to FALSE
        VATRateChangeSetup.Get();
        VATRateChangeSetup.Validate("VAT Rate Change Tool Completed", false);
        VATRateChangeSetup.Validate("Perform Conversion", true);
        VATRateChangeSetup.Modify(true);

        // SETUP: Create Dummy Setup for VAT Rate Change Setup table.
        CreateDummySetup();

        // Excercise: Run VAT Rate Change Tool.
        ERMVATToolHelper.RunVATRateChangeTool();

        // Verify: VAT Rate Change Tool Completed should be set to TRUE.
        VATRateChangeSetup.Get();
        Assert.IsTrue(VATRateChangeSetup."VAT Rate Change Tool Completed", VATToolCompletedError);

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATToolConvCircularReference()
    var
        VATRateChangeConv: Record "VAT Rate Change Conversion";
        VATRateChangeConv2: Record "VAT Rate Change Conversion";
    begin
        // Run the tool with circular setup of groups to convert. Expected: trigger on table will return an error.
        Initialize();

        // SETUP: Create posting groups to update and save them in VAT Change Tool Conversion table.
        ERMVATToolHelper.CreatePostingGroups(false);

        // Exercise & Verify: Try to set circular reference for VAT Prod. Posting Group.
        VATRateChangeConv.SetRange(Type, VATRateChangeConv.Type::"VAT Prod. Posting Group");
        VATRateChangeConv.FindFirst();
        VATRateChangeConv2.Init();
        VATRateChangeConv2.Validate(Type, VATRateChangeConv2.Type::"VAT Prod. Posting Group");

        Commit(); // This is Required for the ASSERTERROR to Work

        asserterror VATRateChangeConv2.Validate("From Code", VATRateChangeConv."To Code");
        asserterror VATRateChangeConv2.Validate("To Code", VATRateChangeConv."From Code");

        // Exercise & Verify: Try to set circular reference for Gen. Prod. Posting Group.
        VATRateChangeConv.SetRange(Type, VATRateChangeConv.Type::"Gen. Prod. Posting Group");
        VATRateChangeConv.FindFirst();
        VATRateChangeConv2.Init();
        VATRateChangeConv2.Validate(Type, VATRateChangeConv2.Type::"Gen. Prod. Posting Group");

        Commit(); // This is Required for the ASSERTERROR to Work

        asserterror VATRateChangeConv2.Validate("From Code", VATRateChangeConv."To Code");
        asserterror VATRateChangeConv2.Validate("To Code", VATRateChangeConv."From Code");

        // Cleanup: Delete groups.
        ERMVATToolHelper.DeleteGroups();
    end;

    local procedure CreateDummySetup()
    var
        VATRateChangeSetup: Record "VAT Rate Change Setup";
    begin
        VATRateChangeSetup.Get();
        VATRateChangeSetup."Update G/L Accounts" := VATRateChangeSetup."Update G/L Accounts"::Both;
        VATRateChangeSetup."Perform Conversion" := true;
        VATRateChangeSetup.Modify(true);
    end;
}

