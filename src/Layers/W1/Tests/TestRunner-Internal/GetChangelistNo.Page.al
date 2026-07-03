page 130027 "Get Changelist No."
{
    SaveValues = true;

    layout
    {
        area(content)
        {
            field(ChangelistNo; ChangelistNo)
            {
                ApplicationArea = All;
                Caption = 'Changelist No.';

                trigger OnValidate()
                begin
                    if ChangelistNo <> 0 then
                        FromDateTime := 0DT;
                end;
            }
            field(FromDateTime; FromDateTime)
            {
                ApplicationArea = All;
                Caption = 'From Date Time';

                trigger OnValidate()
                begin
                    IsCheckedInEnableExpr := FromDateTime = 0DT;
                    if FromDateTime <> 0DT then begin
                        ChangelistNo := 0;
                        IsCheckedIn := true;
                    end;
                end;
            }
            field(IsCheckedIn; IsCheckedIn)
            {
                ApplicationArea = All;
                Caption = 'Already Checked-in';
                Enabled = IsCheckedInEnableExpr;

                trigger OnValidate()
                begin
                    GetLatestObjectsEnableExpr := IsCheckedIn;
                end;
            }
            field(LatestObjects; LatestObjects)
            {
                ApplicationArea = All;
                Caption = 'Get Latest Objects';
                Enabled = GetLatestObjectsEnableExpr;
            }
            field(SdAppPath; SdAppPath)
            {
                ApplicationArea = All;
                Caption = 'Source Depot App Path';

                trigger OnValidate()
                begin
                    if SdAppPath <> '' then
                        SdAppPath := DelChr(SdAppPath, '>', '/');
                end;
            }
            field(ClientPath; ClientPath)
            {
                ApplicationArea = All;
                Caption = 'Client Path';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        GetLatestObjectsEnableExpr := IsCheckedIn;
    end;

    trigger OnOpenPage()
    begin
        if SdAppPath = '' then begin
            SdAppPath := GetChangelistCode.GetSdPath();
            LatestObjects := true;
        end;
        if ClientPath = '' then begin
            ClientPath := GetChangelistCode.GetSdClientPath();
            LatestObjects := true;
        end;
        GetLatestObjectsEnableExpr := IsCheckedIn;

        IsCheckedInEnableExpr := FromDateTime = 0DT;
        if FromDateTime <> 0DT then
            IsCheckedIn := true;
    end;

    var
        GetChangelistCode: Codeunit "Get Changelist Code";
        FromDateTime: DateTime;
        ChangelistNo: Integer;
        IsCheckedIn: Boolean;
        LatestObjects: Boolean;
        GetLatestObjectsEnableExpr: Boolean;
        IsCheckedInEnableExpr: Boolean;
        SdAppPath: Text;
        ClientPath: Text;

    [Scope('OnPrem')]
    procedure GetChangeListNo(): Integer
    begin
        exit(ChangelistNo);
    end;

    [Scope('OnPrem')]
    procedure GetIsCheckIn(): Boolean
    begin
        exit(IsCheckedIn);
    end;

    [Scope('OnPrem')]
    procedure GetSdAppPath(): Text
    begin
        exit(SdAppPath);
    end;

    [Scope('OnPrem')]
    procedure GetClientPath(): Text
    begin
        exit(ClientPath);
    end;

    [Scope('OnPrem')]
    procedure GetLatestObjects(): Boolean
    begin
        exit(LatestObjects);
    end;

    [Scope('OnPrem')]
    procedure GetFromDateTime(): DateTime
    begin
        exit(FromDateTime);
    end;
}

