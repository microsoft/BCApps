codeunit 136605 "ERM RS Role Center"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Config Line] [Rapid Start]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Text001: Label 'Incorrect config. line status weight.';
        Text002: Label 'Incorrect progress value.';
        Text003: Label 'Incorrect number of tables.';
        Text004: Label 'Incorrect number of tables with status "%1" in Rapid Start Cue.';
        Text005: Label 'The status %1 is not supported.';
        LibraryRapidStart: Codeunit "Library - Rapid Start";
        ConfigLineStatus: Option " ","In Progress",Completed,Ignored,Blocked;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStatusWeight_Empty()
    begin
        Assert.AreEqual(0, GetConfigLineWeight(ConfigLineStatus::" "), Text001);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStatusWeight_Completed()
    begin
        Assert.AreEqual(1, GetConfigLineWeight(ConfigLineStatus::Completed), Text001);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStatusWeight_Ignored()
    begin
        Assert.AreEqual(1, GetConfigLineWeight(ConfigLineStatus::Ignored), Text001);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStatusWeight_In_Progress()
    begin
        Assert.AreEqual(0.5, GetConfigLineWeight(ConfigLineStatus::"In Progress"), Text001);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStatusWeight_Blocked()
    begin
        Assert.AreEqual(0.5, GetConfigLineWeight(ConfigLineStatus::Blocked), Text001);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckStatusWeight_OutOfOptionRange()
    begin
        ConfigLineStatus := 6;
        asserterror GetConfigLineWeight(ConfigLineStatus);
        Assert.ExpectedError(StrSubstNo(Text005, ConfigLineStatus));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetProgress_Group()
    var
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        InitGetProgressScenario_Group();

        FindConfigLine(ConfigLine, ConfigLine."Line Type"::Group);

        Assert.AreEqual(60, ConfigLine.GetProgress(), Text002);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetProgress_Area()
    var
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        InitGetProgressScenario_Area();

        FindConfigLine(ConfigLine, ConfigLine."Line Type"::Area);

        Assert.AreEqual(60, ConfigLine.GetProgress(), Text002);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetProgress_Table()
    var
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        AddConfigLine(ConfigLine."Line Type"::Table, ConfigLine.Status::" ", true);
        FindConfigLine(ConfigLine, ConfigLine."Line Type"::Table);

        Assert.AreEqual(0, ConfigLine.GetProgress(), Text002);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetNoOfDirectChildrenTables_Group()
    var
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        InitGetProgressScenario_Area();

        FindConfigLine(ConfigLine, ConfigLine."Line Type"::Group);

        Assert.AreEqual(4, ConfigLine.GetNoTables(), Text003);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetNoOfDirectChildrenTables_Area()
    var
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        InitGetProgressScenario_Area();

        FindConfigLine(ConfigLine, ConfigLine."Line Type"::Area);

        Assert.AreEqual(10, ConfigLine.GetNoTables(), Text003);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyGetNoOfDirectChildrenTables_AreaWithoutGroup()
    var
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        InitGetProgressScenario_AreaWithoutGroup();

        FindConfigLine(ConfigLine, ConfigLine."Line Type"::Area);

        Assert.AreEqual(10, ConfigLine.GetNoTables(), Text003);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRapidStartCue()
    var
        RapidStartServicesCue: Record "RapidStart Services Cue";
        ConfigLine: Record "Config. Line";
    begin
        Initialize();
        InitVerifyCueScenario();

        GetRapidStartCue(RapidStartServicesCue);
        RapidStartServicesCue.CalcFields("Not Started", "In Progress", Completed, Ignored, Promoted);

        ConfigLine.SetRange("Line Type", ConfigLine."Line Type"::Table);
        ConfigLine.SetRange(Status, ConfigLine.Status::" ");
        Assert.AreEqual(ConfigLine.Count,
          RapidStartServicesCue."Not Started", StrSubstNo(Text004, RapidStartServicesCue.FieldCaption("Not Started")));
        ConfigLine.SetRange(Status, ConfigLine.Status::"In Progress");
        Assert.AreEqual(ConfigLine.Count,
          RapidStartServicesCue."In Progress", StrSubstNo(Text004, RapidStartServicesCue.FieldCaption("In Progress")));
        ConfigLine.SetRange(Status, ConfigLine.Status::Completed);
        Assert.AreEqual(ConfigLine.Count,
          RapidStartServicesCue.Completed, StrSubstNo(Text004, RapidStartServicesCue.FieldCaption(Completed)));
        ConfigLine.SetRange(Status, ConfigLine.Status::Ignored);
        Assert.AreEqual(ConfigLine.Count,
          RapidStartServicesCue.Ignored, StrSubstNo(Text004, RapidStartServicesCue.FieldCaption(Ignored)));
        ConfigLine.SetRange(Status);
        ConfigLine.SetRange("Promoted Table", true);
        Assert.AreEqual(ConfigLine.Count,
          RapidStartServicesCue.Promoted, StrSubstNo(Text004, RapidStartServicesCue.FieldCaption(Promoted)));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM RS Role Center");
        LibraryRapidStart.CleanUp('');
    end;

    local procedure AddConfigLine(LineType: Option "Area",Group,"Table"; Status: Option " ","In Progress",Completed,Ignored,Blocked; Promoted: Boolean)
    var
        ConfigLine: Record "Config. Line";
        LibraryRapidStart: Codeunit "Library - Rapid Start";
    begin
        LibraryRapidStart.CreateConfigLine(ConfigLine, LineType, 0, '', '', false);
        ConfigLine.Get(ConfigLine."Line No.");
        if LineType = LineType::Table then begin
            ConfigLine.Status := Status;
            ConfigLine."Promoted Table" := Promoted;
            ConfigLine.Modify();
        end;
    end;

    local procedure GetConfigLineWeight(ConfigLineStatus: Option " ","In Progress",Completed,Ignored,Blocked): Decimal
    var
        ConfigLine: Record "Config. Line";
    begin
        ConfigLine.Status := ConfigLineStatus;
        exit(ConfigLine.GetLineStatusWeight());
    end;

    local procedure InitGetProgressScenario_Area()
    var
        LineType: Option "Area",Group,"Table";
        Status: Option " ","In Progress",Completed,Ignored,Blocked;
    begin
        AddConfigLine(LineType::Area, Status::" ", false);
        AddConfigLine(LineType::Table, Status::" ", false);
        AddConfigLine(LineType::Table, Status::"In Progress", false);
        AddConfigLine(LineType::Table, Status::Completed, false);
        AddConfigLine(LineType::Group, Status::" ", false);
        AddConfigLine(LineType::Table, Status::"In Progress", false);
        AddConfigLine(LineType::Table, Status::" ", false);
        AddConfigLine(LineType::Table, Status::Completed, false);
        AddConfigLine(LineType::Group, Status::" ", false);
        AddConfigLine(LineType::Table, Status::Completed, false);
        AddConfigLine(LineType::Table, Status::Ignored, false);
        AddConfigLine(LineType::Table, Status::"In Progress", false);
        AddConfigLine(LineType::Table, Status::Blocked, false);
    end;

    local procedure InitGetProgressScenario_Group()
    var
        LineType: Option "Area",Group,"Table";
        Status: Option " ","In Progress",Completed,Ignored,Blocked;
    begin
        AddConfigLine(LineType::Group, Status::" ", false);
        AddConfigLine(LineType::Table, Status::" ", false);
        AddConfigLine(LineType::Table, Status::"In Progress", false);
        AddConfigLine(LineType::Table, Status::Completed, false);
        AddConfigLine(LineType::Table, Status::Ignored, false);
        AddConfigLine(LineType::Table, Status::Blocked, false);
    end;

    local procedure InitGetProgressScenario_AreaWithoutGroup()
    var
        LineType: Option "Area",Group,"Table";
        Status: Option " ","In Progress",Completed,Ignored,Blocked;
    begin
        AddConfigLine(LineType::Area, Status::" ", false);
        AddConfigLine(LineType::Table, Status::" ", false);
        AddConfigLine(LineType::Table, Status::"In Progress", false);
        AddConfigLine(LineType::Table, Status::Completed, false);
        AddConfigLine(LineType::Table, Status::"In Progress", false);
        AddConfigLine(LineType::Table, Status::" ", false);
        AddConfigLine(LineType::Table, Status::Completed, false);
        AddConfigLine(LineType::Table, Status::Completed, false);
        AddConfigLine(LineType::Table, Status::Ignored, false);
        AddConfigLine(LineType::Table, Status::"In Progress", false);
        AddConfigLine(LineType::Table, Status::Blocked, false);
    end;

    local procedure InitVerifyCueScenario()
    var
        LineType: Option "Area",Group,"Table";
        Status: Option " ","In Progress",Completed,Ignored,Blocked;
    begin
        AddConfigLine(LineType::Area, Status::" ", false);
        AddConfigLine(LineType::Table, Status::" ", true);
        AddConfigLine(LineType::Table, Status::"In Progress", false);
        AddConfigLine(LineType::Table, Status::Completed, false);
        AddConfigLine(LineType::Group, Status::" ", false);
        AddConfigLine(LineType::Table, Status::"In Progress", false);
        AddConfigLine(LineType::Table, Status::" ", true);
        AddConfigLine(LineType::Table, Status::Completed, true);
        AddConfigLine(LineType::Group, Status::" ", false);
        AddConfigLine(LineType::Table, Status::Completed, true);
        AddConfigLine(LineType::Table, Status::Ignored, false);
        AddConfigLine(LineType::Table, Status::"In Progress", false);
        AddConfigLine(LineType::Table, Status::Blocked, false);
    end;

    local procedure FindConfigLine(var ConfigLine: Record "Config. Line"; LineType: Option "Area",Group,"Table")
    begin
        ConfigLine.SetRange("Line Type", LineType);
        ConfigLine.FindLast();
    end;

    local procedure GetRapidStartCue(var RapidStartServicesCue: Record "RapidStart Services Cue")
    begin
        if not RapidStartServicesCue.Get() then begin
            RapidStartServicesCue.Init();
            RapidStartServicesCue.Insert();
        end;
    end;
}

