namespace System.IO;

report 8615 "Copy Package"
{
    Caption = 'Copy - Configuration Package';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Config. Package"; "Config. Package")
        {
            DataItemTableView = sorting(Code);

            trigger OnAfterGetRecord()
            begin
                ConfigPackage.Init();
                ConfigPackage.TransferFields(UseConfigPackage);
                ConfigPackage.Code := NewPackageCode;
                ConfigPackage.Insert();

                ConfigPackageTable.SetRange("Package Code", Code);
                if ConfigPackageTable.FindSet() then
                    repeat
                        ConfigPackageTable2.Init();
                        ConfigPackageTable2.TransferFields(ConfigPackageTable);
                        ConfigPackageTable2."Package Code" := ConfigPackage.Code;
                        ConfigPackageTable2.Insert();
                    until ConfigPackageTable.Next() = 0;

                ConfigPackageField.SetRange("Package Code", Code);
                if ConfigPackageField.FindSet() then
                    repeat
                        ConfigPackageField2.Init();
                        ConfigPackageField2.TransferFields(ConfigPackageField);
                        ConfigPackageField2."Package Code" := ConfigPackage.Code;
                        ConfigPackageField2.Insert();
                    until ConfigPackageField.Next() = 0;

                ConfigPackageFilter.SetRange("Package Code", Code);
                if ConfigPackageFilter.FindSet() then
                    repeat
                        ConfigPackageFilter2.Init();
                        ConfigPackageFilter2.TransferFields(ConfigPackageFilter);
                        ConfigPackageFilter2."Package Code" := ConfigPackage.Code;
                        ConfigPackageFilter2.Insert();
                    until ConfigPackageFilter.Next() = 0;

                if CopyData then begin
                    ConfigPackageRecord.SetRange("Package Code", Code);
                    if ConfigPackageRecord.FindSet() then
                        repeat
                            ConfigPackageRecord2.Init();
                            ConfigPackageRecord2.TransferFields(ConfigPackageRecord);
                            ConfigPackageRecord2."Package Code" := ConfigPackage.Code;
                            ConfigPackageRecord2.Invalid := false;
                            ConfigPackageRecord2.Insert();
                        until ConfigPackageRecord.Next() = 0;

                    ConfigPackageData.SetRange("Package Code", Code);
                    if ConfigPackageData.FindSet() then
                        repeat
                            ConfigPackageData2.Init();
                            ConfigPackageData2.TransferFields(ConfigPackageData);
                            ConfigPackageData2."Package Code" := ConfigPackage.Code;
                            ConfigPackageData2.Invalid := false;
                            ConfigPackageData2.Insert();
                        until ConfigPackageData.Next() = 0;
                end;
            end;

            trigger OnPreDataItem()
            begin
                SetRange(Code, UseConfigPackage.Code);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Package; NewPackageCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Package Code';
                        ToolTip = 'Specifies the code that the new configuration package gets after copying.';

                        trigger OnValidate()
                        begin
                            if ConfigPackage.Get(NewPackageCode) then
                                Error(PackageAlreadyExistsErr, NewPackageCode);
                        end;
                    }
                    field(CopyData; CopyData)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Copy Data';
                        ToolTip = 'Specifies if data in the configuration package is copied.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        UseConfigPackage: Record "Config. Package";
        ConfigPackage: Record "Config. Package";
        ConfigPackageTable: Record "Config. Package Table";
        ConfigPackageTable2: Record "Config. Package Table";
        ConfigPackageField: Record "Config. Package Field";
        ConfigPackageField2: Record "Config. Package Field";
        ConfigPackageData: Record "Config. Package Data";
        ConfigPackageData2: Record "Config. Package Data";
        ConfigPackageRecord: Record "Config. Package Record";
        ConfigPackageRecord2: Record "Config. Package Record";
        ConfigPackageFilter: Record "Config. Package Filter";
        ConfigPackageFilter2: Record "Config. Package Filter";
        NewPackageCode: Code[20];
        CopyData: Boolean;
#pragma warning disable AA0470
        PackageAlreadyExistsErr: Label 'Package %1 already exists.';
#pragma warning restore AA0470

    procedure Set(ConfigPackage2: Record "Config. Package")
    begin
        UseConfigPackage := ConfigPackage2;
    end;
}

