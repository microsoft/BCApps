page 130029 "Get Coverage"
{
    SaveValues = true;

    layout
    {
        area(content)
        {
            field(SnapQueueID; SnapQueueID)
            {
                ApplicationArea = All;
                Caption = 'Snap check-in id';

                trigger OnDrillDown()
                begin
                    HyperLink(CreteSnapCheckInFolderTxt)
                end;
            }
            field(CountryCode; CountryCode)
            {
                ApplicationArea = All;
                Caption = 'Country Code';

                trigger OnValidate()
                begin
                    SdAppPath := '';
                    SetPaths();
                end;
            }
            field(FromDateTime; FromDateTime)
            {
                ApplicationArea = All;
                Caption = 'From Date Time';
                Visible = GetChangelistVisibleExpr;
            }
            field(ToDateTime; ToDateTime)
            {
                ApplicationArea = All;
                Caption = 'To Date Time';
                Visible = GetChangelistVisibleExpr;
            }
            field(SdAppPath; SdAppPath)
            {
                ApplicationArea = All;
                Caption = 'Source Depot App Path';
                Visible = GetChangelistVisibleExpr;

                trigger OnValidate()
                begin
                    if SdAppPath <> '' then
                        SdAppPath := DelChr(SdAppPath, '>', '/');
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        GetChangelistVisibleExpr := true;
    end;

    trigger OnOpenPage()
    begin
        SetPaths();
    end;

    var
        FromDateTime: DateTime;
        ToDateTime: DateTime;
        SnapQueueID: Text[10];
        CountryCode: Option W1,AT,AU,BE,CA,CH,DE,DK,ES,FI,FR,GB,"IN",IS,IT,MX,NL,NO,NZ,RU,SE,US;
        SdAppPath: Text;
        CreteSnapCheckInFolderTxt: Label '\\navbr455\SnapBuildShare\Main\Binaries';
        GetChangelistVisibleExpr: Boolean;

    [Scope('OnPrem')]
    procedure GetFromDateTime(): DateTime
    begin
        exit(FromDateTime);
    end;

    [Scope('OnPrem')]
    procedure GetToDateTime(): DateTime
    begin
        exit(ToDateTime);
    end;

    [Scope('OnPrem')]
    procedure GetSnapQueueID(): Text[10]
    begin
        exit(SnapQueueID);
    end;

    [Scope('OnPrem')]
    procedure GetCountryCode(): Text
    begin
        exit(Format(CountryCode));
    end;

    [Scope('OnPrem')]
    procedure GetSdAppPath(): Text
    begin
        exit(SdAppPath);
    end;

    [Scope('OnPrem')]
    procedure SetPaths()
    var
        GetChangelistCode: Codeunit "Get Changelist Code";
    begin
        if SdAppPath = '' then
            if CountryCode = CountryCode::W1 then
                SdAppPath := GetChangelistCode.GetSdPath() + '/BaseApp/...'
            else
                SdAppPath := GetChangelistCode.GetSDRootPath() + 'GDL/' + Format(CountryCode) + '/DevBase/BaseApp/...';

        if ToDateTime = 0DT then
            ToDateTime := CreateDateTime(Today, 0T);
        if FromDateTime = 0DT then
            FromDateTime := ToDateTime;
    end;

    [Scope('OnPrem')]
    procedure Init(OnlyTestResults: Boolean)
    begin
        GetChangelistVisibleExpr := not OnlyTestResults;
    end;
}

